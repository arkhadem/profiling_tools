# GPU Microarchitecture Analysis

This directory contains scripts and details for analyzing SM throughput utilization, SM occupancy, control divergence, memory bandwidth utilization, and arithmetic intensity of individual kernels and end-to-end.

## Requirements

These scripts have been tested with Nvidia Nsight Compute (`ncu`) Version `2025.1.1.0` on Nvidia H100 SXM GPUs.

> **Note:** Other versions of `ncu` or other GPUs might not support metrics used in this script or might support them under other names. You can check which metrics your software and hardware configuration supports via:

```bash
ncu --list-metrics
```

> **Note:** Ensure your application is compiled with debugging symbols (e.g., using the `-g` flag).

## Inject ROI APIs

This profiling might take many application repetitions and a very long time. It is highly recommented to use the following APIs before and after your Regions of Interest (ROI) to only profile certain functions or cycles of the execution time. After adding these APIs to your code, compile it as before, and set `ROI_PROFILE=1` in `profile.sh`.

```cpp
    // Include the following header files
    #include <cuda_profiler_api.h>
    #include <cuda_runtime.h>

    // Add this before ROI
    cudaError_t st = cudaProfilerStart();
    if (st != cudaSuccess) {
        fprintf(stderr, "cudaProfilerStart() failed: %s\n", cudaGetErrorString(st));
        exit(-1);
    }

    // Region of Interest (ROI)

    // Add this after ROI
    cudaError_t st = cudaProfilerStop();
    if (st != cudaSuccess) {
        fprintf(stderr, "cudaProfilerStop() failed: %s\n", cudaGetErrorString(st));
        exit(-1);
    }
```

## Run Profiler

To begin profiling:

1. Open the `profile.sh` script.
2. Update the configuration to match your application's setup.
3. Run the script to start profiling and extract the metrics:

```bash
bash profile.sh
```

## Interpreting Results

### Profiled Metrics

**SM Throughput Utilization**  
`sm__throughput.avg.pct_of_peak_sustained_active` reports the SM throughput utilization as a percentage of active cycles (%)\*. This metric is calculated as the *maximum* of several sub-metrics, such as the percentage of active cycles\* during which the issue, ALU, or FMA modules are active. To view the values of individual sub-metrics, profile `breakdown:sm__throughput.avg.pct_of_peak_sustained_active`.

**SM Occupancy**  
`sm__warps_active.avg.pct_of_peak_sustained_active` represents the ratio of active warps on SMs to the maximum number of warps supported on all SMs during active cycles\*.

**Control Divergence**  
`smsp__thread_inst_executed_per_inst_executed.ratio` indicates the average number of threads active (not predicated off) per warp instruction. The value ranges from 1 to 32, with lower values indicating higher control divergence.

**Floating-Point Operations (FLOPs)**  
The following metrics count the number of FP operations executed by threads that are not predicated off:
- `sm__sass_thread_inst_executed_op_fp8_pred_on`
- `sm__sass_thread_inst_executed_op_fp16_pred_on`
- `sm__sass_thread_inst_executed_op_fp32_pred_on`
- `sm__sass_thread_inst_executed_op_fp64_pred_on`  
The total FLOPs is the sum of these metrics.

**Device Memory Access**  
`dram__bytes` measures the total number of bytes read from or written to device memory. Use `dram__bytes.sum` from the output CSV to obtain total memory access across all SMs. For separate read and write bytes, profile `dram__bytes_read` and `dram__bytes_write`.

**Kernel Duration**  
`gpu__time_duration.sum` shows the execution time of each kernel in milliseconds. This metric is always included, regardless of the metrics specified in the bash script.

\* An active cycle is one where at least one warp is scheduled on the SM and it is not idle.

### Output CSV Result

The provided bash script generates a CSV file (`PROF_DIR/PROF_FILE.csv` as specified in `profile.sh`). Each row corresponds to a single kernel invocation. Since a kernel can be launched multiple times, you may find multiple entries with the same `Kernel Name`.

### Other Metrics

You can compute the following additional metrics using the profiled data:

- **Memory Bandwidth Utilization (TB/s)** Calculated as `Device Memory Access (GB)` / `Kernel Duration (ms)`.

- **Arithmetic Intensity (FLOPs/Byte)** Calculated as `FLOPs` / (`Device Memory Access (GB)` << 30).
  This value can be compared against the device's operational density (compute throughput / memory bandwidth) to determine whether kernels are bound by memory bandwidth or compute throughput.
