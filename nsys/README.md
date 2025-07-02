# GPU Device Memory Usage Analysis and Tracing Scripts

This directory contains scripts for tracing GPU device memory allocations and deallocations. It includes tools to generate and analyze memory traces, identify maximum and total memory usage during execution, and detect potential memory leaks at the end of the run.

## Requirements

These scripts have been tested with the following software versions:

- **Nvidia Nsight Systems (`nsys`)**: Version `2023.1.2.43`
- **SQLite (`sqlite3`)**: Version `3.26.0`

> **Note:** Other versions of `nsys` may lack required tables or use different table names. If you encounter issues with other versions, please feel free to email me.

Ensure your application is compiled with debugging symbols (e.g., using the `-g` flag).

## Run Profiler and Generate Trace

To begin profiling:

1. Open the `profile.sh` script.
2. Update the configuration to match your application's setup.
3. Run the script to start profiling and trace generation:

```bash
bash profile.sh
```

This bash script runs both `nsys` and `sqlite3`:

1. **`nsys`** generates two output files:
   - `.nsys-rep` (raw profile)
   - `.sqlite` (SQLite trace database)

2. **`sqlite3`** processes the `.sqlite` file using SQL scripts in this directory and produces three `.tsv` files:
   - `valid.tsv`: Contains CUDA (de)allocation traces with valid call stacks.
   - `invalid.tsv`: Contains (de)allocations without valid call stacks.
   - `driver.tsv`: Contains memory allocations managed through the driver interface.

### TSV File Descriptions

Each `.tsv` file contains rows with the following format:

`[PID] [address] [start_time] [bytes] [mem_kind] [mem_op_type] [var_name] [call_stack]`

- **PID**: Process ID that performed the memory operation.
- **address**: Virtual memory address of the (de)allocation.
- **start_time**: Timestamp of the memory event.
- **bytes**: Size in bytes of the memory operation.
- **mem_kind**: Type of memory involved. Possible values include:
  - `CUDA_MEMOPR_MEMORY_KIND_DEVICE`: Device memory allocated via `cudaMalloc`, `cudaMallocAsync`, etc.
  - `CUDA_MEMOPR_MEMORY_KIND_DEVICE_STATIC`: Statically allocated device memory (e.g., `__device__`, `__constant__`).
  - `CUDA_MEMOPR_MEMORY_KIND_ARRAY`: Likely represents multi-dimensional arrays or texture/surface objects\*.
  - `CUDA_MEMOPR_MEMORY_KIND_PAGEABLE`: Host memory allocated with standard `malloc`\**.
  - `CUDA_MEMOPR_MEMORY_KIND_PINNED`: Pinned host memory (`cudaMallocHost`, `cudaHostAlloc`). Pinned memory cannot be paged out by OS, accelerating host-device transfers.
  - `CUDA_MEMOPR_MEMORY_KIND_MANAGED`: Managed memory is allocated using `cudaMallocManaged`. The content of this memory could be on host or device memory based on the demand\***.
  - `CUDA_MEMOPR_MEMORY_KIND_MANAGED_STATIC`: Statically allocated unified memory via `__managed__`\***.
  - `CUDA_MEMOPR_MEMORY_KIND_UNKNOWN`: Miscellaneous or unidentified memory types\***.
- **mem_op_type**: Either `CUDA_DEV_MEM_EVENT_OPR_ALLOCATION` or `CUDA_DEV_MEM_EVENT_OPR_DEALLOCATION`.
- **var_name**: Variable name in the source code (if available).
- **call_stack**: Call stack trace for the memory event. Each entry follows `[function_name] (module_name)` format, with the first entry being the innermost function.

> \* Definition may not be accurate, please feel free to email me with better definitions.
> \** Host memory types are ignored in the analysis explained in the next section.
> \*** These memory types may reside in either host or device memory; accuracy is not guaranteed.

## Processing Trace Files

Use `process.py` to analyze the generated `.tsv` files. Run the script as follows:

```bash
python process.py -i [PROF_DIR/PROF_FILE] -o [/path/to/output/file.txt] -a [watermark,usage,leakage]
```

Where:
- `PROF_DIR` and `PROF_FILE` must match the values set in `profile.sh`.
- `/path/to/output/file.txt` is the output file. As it can be large, store it on a storage disk.
- `watermark`, `usage`, or `leakage` specify the type of analysis, explained as follows:

### 1. High Memory Watermark Analysis

Identifies the peak memory usage during program execution. The output file lists all memory allocations that were active (not yet freed) at the point of highest memory usage.

### 2. Memory Usage Analysis

Reports the total memory usage throughout the execution. The output can be used to generate a memory usage timeline with the following Python script.

```bash
python plot.py -u [/path/to/output/file.txt] -o [/path/to/chart.png]
```

You can compare the analyzed memory usage with the memory usage reported by `nvidia-smi`.  
To do this, open a separate terminal and start `nvidia-smi` before running your application.  
Then, execute your application as usual, and once it completes, terminate the `nvidia-smi` process:

```bash
nvidia-smi -i [GPU Device ID] --query-gpu=timestamp,memory.used --format=csv,noheader,nounits --loop-ms=10 &> [/path/to/smi/report.txt]
```

Then, create the plot using the following command:

```bash
python plot.py -u [/path/to/output/file.txt] -s [/path/to/smi/report.txt] -o [/path/to/chart.png]
```

### 3. Memory Leakage Analysis

This analysis identifies memory leaks at the end of execution. The output file lists all memory traces that were not freed by the end of the run.

## More Resources

The SQL queries rely on the following tables:

- **`CUDA_GPU_MEMORY_USAGE_EVENTS`**: Contains all memory allocation and deallocation records.  
  We use the following columns: `globalPid`, `address`, `start`, `bytes`, `memkind`, `memoryOperationType`, `name`, and `correlationId` (to link to the next table).

- **`CUPTI_ACTIVITY_KIND_RUNTIME`**: Used to map runtime events to memory traces.  
  Relevant columns: `correlationId`, `globalTid`, `start`, `end`, and `eventClass`.  
  - Entries with `eventClass` = 67 have valid call stacks. We use their `callchainId` to fetch the call stack.
  - Entries with `eventClass` = 1 represent driver allocations with no call stack.
  - All other values or unmatched entries are marked as allocations with invalid call stacks.

- **`CUDA_CALLCHAINS`**: Stores call stacks for memory events.  
  The `callchainId` links to multiple entries ordered by `stackDepth`. Each entry includes a `symbol` ID and `module` ID for the function.

- **`ENUM_CUDA_MEM_KIND`** and **`ENUM_CUDA_DEV_MEM_EVENT_OPER`**: Map `memkind` and `memoryOperationType` values to their corresponding string names.

- **`StringIds`**: Maps `symbol` and `module` IDs to their string representations.

For more details on these tables, refer to the [SQLite Export Schema Reference](https://docs.nvidia.com/nsight-systems/2022.1/nsys-exporter/exported_data.html).