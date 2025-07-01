
NUM_RANKS=1
NUM_LEVELS=3
MESH_XYZ=128
BLOCK_XYZ=32
TIME_STEPS=250
DV=2

# FLOP="sm__sass_thread_inst_executed_op_dadd_pred_on,sm__sass_thread_inst_executed_op_dfma_pred_on,sm__sass_thread_inst_executed_op_dmul_pred_on,sm__sass_thread_inst_executed_op_fadd_pred_on,sm__sass_thread_inst_executed_op_ffma_pred_on,sm__sass_thread_inst_executed_op_fmul_pred_on,sm__sass_thread_inst_executed_op_fp16_pred_on,sm__sass_thread_inst_executed_op_fp32_pred_on,sm__sass_thread_inst_executed_op_fp64_pred_on,sm__sass_thread_inst_executed_op_fp8_pred_on,sm__sass_thread_inst_executed_op_hadd_pred_on,sm__sass_thread_inst_executed_op_hfma_pred_on,sm__sass_thread_inst_executed_op_hmul_pred_on"
FLOP="sm__sass_thread_inst_executed_op_fp16_pred_on,sm__sass_thread_inst_executed_op_fp32_pred_on,sm__sass_thread_inst_executed_op_fp64_pred_on,sm__sass_thread_inst_executed_op_fp8_pred_on"
# TIME="gpu__time_active,gpu__time_duration,gpu__time_duration_measured_user,gpu__time_duration_measured_wallclock"
# SM_THROUGHPUT_UTILIZATION_E2E="breakdown:sm__throughput.avg.pct_of_peak_sustained_elapsed"
SM_THROUGHPUT_UTILIZATION_ACT="sm__throughput.avg.pct_of_peak_sustained_active"
# SM_OCCUPANCY_E2E="sm__warps_active.avg.pct_of_peak_sustained_elapsed"
SM_OCCUPANCY_ACT="sm__warps_active.avg.pct_of_peak_sustained_active"
# DRAM_BW_E2E="gpu__dram_throughput.avg.pct_of_peak_sustained_elapsed"
# DRAM_BW_ACT="gpu__dram_throughput.avg.pct_of_peak_sustained_active"
DRAM_BW_ACT="dram__bytes" # ,dram__bytes_read,dram__bytes_write"
CONTROL_DIV="smsp__thread_inst_executed_per_inst_executed.ratio" #"warp_execution_efficiency"

COMMAND="mpirun -n $NUM_RANKS --map-by ppr:$NUM_RANKS:node:pe=1 ./build_gpu_release_instrument/benchmarks/burgers/burgers-benchmark -i benchmarks/burgers/burgers.pin parthenon/mesh/nx1=$MESH_XYZ parthenon/mesh/nx2=$MESH_XYZ parthenon/mesh/nx3=$MESH_XYZ parthenon/meshblock/nx1=$BLOCK_XYZ parthenon/meshblock/nx2=$BLOCK_XYZ parthenon/meshblock/nx3=$BLOCK_XYZ parthenon/time/nlim=$TIME_STEPS parthenon/mesh/numlevel=$NUM_LEVELS"

# METRICS="$SM_THROUGHPUT_UTILIZATION_ACT,$SM_OCCUPANCY_ACT,$DRAM_BW_ACT,$CONTROL_DIV"
METRICS="$FLOP"
# METRICS="$DRAM_BW_ACT"
# METRICS="$SM_THROUGHPUT_UTILIZATION_E2E,$SM_THROUGHPUT_UTILIZATION_ACT,$SM_OCCUPANCY_E2E,$SM_OCCUPANCY_ACT,$DRAM_BW_E2E,$DRAM_BW_ACT,$CONTROL_DIV"

PROF_NAME="/scratch/kdur_root/kdur/arkhadem/ncu/ncu_profile_b${BLOCK_XYZ}_FLOP_release"

echo $COMMAND

# Turn on MPS
# nvidia-cuda-mps-control -d

# Turn off MPS
# echo quit | nvidia-cuda-mps-control

#total
CUDA_VISIBLE_DEVICES=$DV \
    /sw/pkgs/arc/cuda/12.8.1/bin/ncu \
    -o "${PROF_NAME}" \
    --metrics $METRICS \
    --target-processes all \
    --replay-mode application \
    --profile-from-start off \
    --csv \
    $COMMAND

# CUDA_VISIBLE_DEVICES=$DV \
#     /sw/pkgs/arc/cuda/12.8.1/bin/nsys profile \
#     --output="${PROF_NAME}" \
#     --capture-range=cudaProfilerApi \
#     $COMMAND

# CUDA_VISIBLE_DEVICES=$DV \
#     /sw/pkgs/arc/cuda/12.8.1/bin/ncu \
#     -o "${PROF_NAME}_new" \
#     --page=details \
#     --set detailed \
#     --target-processes all \
#     --replay-mode application \
#     --profile-from-start off \
#     --import-source yes \
#     $COMMAND

# ncu --page=details --nvtx --nvtx-include Inference/Convolution/ --import-source yes --export $ncu_profile --force-overwrite --set detailed

# # per kernel
# CUDA_VISIBLE_DEVICES=$DV \
#     /sw/pkgs/arc/cuda/12.8.1/bin/ncu \
#     -o "${PROF_NAME}_perkernel" \
#     --metrics $METRICS \
#     --target-processes all \
#     --replay-mode application \
#     --print-summary per-kernel \
#     --profile-from-start off \
#     --csv \
#     $COMMAND

    # --launch-skip 1 \
    # --launch-count 1  \


# ncu -o ncu_profile --page=details --target-processes application-only --metrics breakdown:sm__throughput.avg.pct_of_peak_sustained_elapsed,sm__throughput.avg.pct_of_peak_sustained_elapsed --replay-mode app-range $command