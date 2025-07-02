
# get input arguments such as input tsv file, output file with argparse
import argparse
import os
import sys
parser = argparse.ArgumentParser(description='Process CUDA memory allocation and deallocation events.')
parser.add_argument('-i', type=str, help='Input TSV directory with CUDA memory allocation and deallocation events.', required=True)
parser.add_argument('-o', type=str, help='Output file to save the processed CUDA memory events.', required=True)
parser.add_argument('-a', type=str, help='type of analysis to perform', choices=['watermark', 'usage', 'leakage'], default='watermark', required=False)
parser.add_argument('--no-header', action='store_true', help='If set, the output file will have a header line.')
args = parser.parse_args()

VALID_TYPE = 0
INVALID_TYPE = 1
DRIVER_TYPE = 2

INVALID_ANALYSIS = True
DRIVER_ANALYSIS = True

def extract_info(filehandle, tracetype):
    """Extracts information from a line of the input file."""
    line = filehandle.readline()
    if not line:
        return None
    parts = line.strip().split('\t')
    if len(parts) != 8:
        raise ValueError(f"Line does not contain enough parts: {line}")
    return {
        'pid': parts[0],
        'address': parts[1],
        'start_time': int(parts[2]),
        'bytes': int(parts[3]),
        'memkind': parts[4],
        'mem_op_type': parts[5],
        'var_name': parts[6],
        'stack': parts[7],
        'tracetype': tracetype
    }

curr_traces = []

infile_valid = open(f"{args.i}_valid.tsv", 'r')
## Skipping header line
infile_valid.readline()
curr_traces.append(extract_info(infile_valid, VALID_TYPE))

infile_invalid = None
if INVALID_ANALYSIS:
    infile_invalid = open(f"{args.i}_invalid.tsv", 'r')
    infile_invalid.readline()
    curr_traces.append(extract_info(infile_invalid, INVALID_TYPE))
else:
    curr_traces.append(None)

infile_driver = None
if DRIVER_ANALYSIS:
    infile_driver = open(f"{args.i}_driver.tsv", 'r')
    infile_driver.readline()
    curr_traces.append(extract_info(infile_driver, DRIVER_TYPE))
else:
    curr_traces.append(None)

outfile = open(args.o, 'w')

total = [0, 0, 0]
memory = {}

max_total = [0, 0, 0]
max_time = -1
max_memory = {}

prev_start_time = -1
first_start_time = -1

MANAGED_MEM_FOUND = False
MANAGED_STATIC_MEM_FOUND = False
UNKNOWN_MEM_FOUND = False

if args.a == "usage" and not args.no_header:
    outfile.write("time(ns)\ttotal (B)\tvalid (B)\tinvalid (B)\tdriver (B)\n")


# read the file line by line
while curr_traces[0] is not None or curr_traces[1] is not None or curr_traces[2] is not None:
    trace = None

    min_start = min(
        trace['start_time'] if trace is not None else float('inf') for trace in curr_traces
    )

    if curr_traces[0] is not None and min_start == curr_traces[0]['start_time']:
        trace = curr_traces[0]
        curr_traces[0] = extract_info(infile_valid, VALID_TYPE)
    elif curr_traces[1] is not None and min_start == curr_traces[1]['start_time']:
        trace = curr_traces[1]
        curr_traces[1] = extract_info(infile_invalid, INVALID_TYPE)
    elif curr_traces[2] is not None and min_start == curr_traces[2]['start_time']:
        trace = curr_traces[2]
        curr_traces[2] = extract_info(infile_driver, DRIVER_TYPE)
    else:
        raise ValueError("No valid trace found")

    if trace['memkind'] in ["CUDA_MEMOPR_MEMORY_KIND_PINNED", "CUDA_MEMOPR_MEMORY_KIND_PAGEABLE"]:
        continue
    elif trace['memkind'] == "CUDA_MEMOPR_MEMORY_KIND_MANAGED":
        MANAGED_MEM_FOUND = True
    elif trace['memkind'] == "CUDA_MEMOPR_MEMORY_KIND_MANAGED_STATIC":
        MANAGED_STATIC_MEM_FOUND = True
    elif trace['memkind'] == "CUDA_MEMOPR_MEMORY_KIND_UNKNOWN":
        UNKNOWN_MEM_FOUND = True

    if first_start_time == -1:
        first_start_time = trace['start_time']

    assert prev_start_time <= trace['start_time'], f"Memory operation out of order: {prev_start_time} > {trace['start_time']}"

    if args.a == "usage" and prev_start_time != trace['start_time'] and prev_start_time != -1:
        outfile.write(f"{prev_start_time-first_start_time}\t{sum(total)}\t{total[0]}\t{total[1]}\t{total[2]}\n")

    prev_start_time = trace['start_time']

    if args.a == "usage":
        if trace['mem_op_type'] == "CUDA_DEV_MEM_EVENT_OPR_ALLOCATION":
            total[trace['tracetype']] += trace['bytes']
        elif trace['mem_op_type'] == "CUDA_DEV_MEM_EVENT_OPR_DEALLOCATION":
            total[trace['tracetype']] -= trace['bytes']
        else:
            raise ValueError(f"Unknown memory operation type: {trace['mem_op_type']}")
    elif args.a == "watermark" or args.a == "leakage":
        key = f"{trace['pid']}_{trace['address']}_{trace['memkind']}"
        if trace['mem_op_type'] == "CUDA_DEV_MEM_EVENT_OPR_ALLOCATION":
            total[trace['tracetype']] += trace['bytes']
            assert key not in memory, f"Error: {key} already allocated"
            memory[key] = trace.copy()
            if args.a == "watermark" and sum(total) > sum(max_total):
                max_time = trace['start_time']
                max_total = total.copy()
                max_memory = memory.copy()
        elif trace['mem_op_type'] == "CUDA_DEV_MEM_EVENT_OPR_DEALLOCATION":
            total[trace['tracetype']] -= trace['bytes']
            assert key in memory, f"Error: {key} not allocated"
            assert trace['bytes'] == memory[key]['bytes'], f"Error: {key} deallocated with different size {trace['bytes']} != {memory[key]['bytes']}"
            del memory[key]
        else:
            raise ValueError(f"Unknown memory operation type: {trace['mem_op_type']}")

if args.a == "usage":
    print (f"total leakage: {total} bytes")
elif args.a == "watermark":
    total = [0, 0, 0]
    mpi = [0, 0, 0]
    if not args.no_header:
        outfile.write("address\tstart_time\tbytes\tmemkind\tmem_op_type\tvar_name\ttrace_type\tstack\n")
    for item in max_memory.values():
        if "openmpi" in item['stack'] or "libToolsInjectionOpenMPI64" in item['stack']:
            mpi[item['tracetype']] += item['bytes']
        elif "mpi" in item['stack'].lower():
            print(f"Warning: {item['stack']} contains 'mpi' but not 'openmpi' or 'libToolsInjectionOpenMPI64'")
        total[item['tracetype']] += item['bytes']
        outfile.write(f"{item['address']}\t{item['start_time']}\t{item['bytes']}\t{item['memkind']}\t{item['mem_op_type']}\t{item['var_name']}\t{item['tracetype']}\t{item['stack']}\n")
    print (f"high water mark:\n\ttotal: {sum(max_total)} bytes\n\tvalid: {max_total[0]} bytes\n\tinvalid: {max_total[1]} bytes\n\tdriver: {max_total[2]} bytes")
    print (f"high water mark time: {max_time} ms")
    print (f"mpi allocated memory:\n\ttotal: {sum(mpi)} bytes\n\tvalid: {mpi[0]} bytes\n\tinvalid: {mpi[1]} bytes\n\tdriver: {mpi[2]} bytes")
    print (f"aggregated itemized high water mark:\n\ttotal: {sum(total)} bytes\n\tvalid: {total[0]} bytes\n\tinvalid: {total[1]} bytes\n\tdriver: {total[2]} bytes")
elif args.a == "leakage":
    print (f"leakage:\n\ttotal: {sum(total)} bytes\n\tvalid: {total[0]} bytes\n\tinvalid: {total[1]} bytes\n\tdriver: {total[2]} bytes")
    itemized_leakage = [0, 0, 0]
    if not args.no_header:
        outfile.write("address\tstart_time\tbytes\tmemkind\tmem_op_type\tvar_name\ttrace_type\tstack\n")
    for item in memory.values():
        itemized_leakage[item['tracetype']] += item['bytes']
        outfile.write(f"{item['address']}\t{item['start_time']}\t{item['bytes']}\t{item['memkind']}\t{item['mem_op_type']}\t{item['var_name']}\t{item['tracetype']}\t{item['stack']}\n")
    print (f"aggregated itemized leakage:\n\ttotal: {sum(itemized_leakage)} bytes\n\tvalid: {itemized_leakage[0]} bytes\n\tinvalid: {itemized_leakage[1]} bytes\n\tdriver: {itemized_leakage[2]} bytes")

if MANAGED_MEM_FOUND:
    print("Warning: managed memory found in traces. Managed memory could be allocated on host or device. Report might not be accurate.")
if MANAGED_STATIC_MEM_FOUND:
    print("Warning: managed static memory found in traces. Managed static memory is allocated on host and can be used by device. Report might not be accurate.")
if UNKNOWN_MEM_FOUND:
    print("Warning: unknown memory kind found in traces. Report might not be accurate.")

infile_valid.close()
if infile_invalid is not None:
    infile_invalid.close()
if infile_driver is not None:
    infile_driver.close()
outfile.close()