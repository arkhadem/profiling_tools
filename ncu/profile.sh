################## Initial Setup -- set the following based on your config ##################

export APP_ROOT=/path/to/app/exe/dir

# Certain GPUs used for running the application
# Examples:
#     0 (GPU 0)
#     0,1,2,3 (GPUs 0, 1, 2, and 3)
export CUDA_VISIBLE_DEVICES=0

# Where to store the ncu-report and sql files
export PROF_DIR=/path/to/storage

# Name of the ncu profile file
export PROF_FILE=ncu_prof

# Set to 1 if you want to profile only ROIs (see README for details)
ROI_PROFILE=0

#############################################################################################





####################### Metrics -- ONLY TOUCH IF NEEDED, SEE README ########################

FLOP="sm__sass_thread_inst_executed_op_fp16_pred_on,sm__sass_thread_inst_executed_op_fp32_pred_on,sm__sass_thread_inst_executed_op_fp64_pred_on,sm__sass_thread_inst_executed_op_fp8_pred_on"
SM_THROUGHPUT_UTILIZATION="sm__throughput.avg.pct_of_peak_sustained_active"
SM_OCCUPANCY="sm__warps_active.avg.pct_of_peak_sustained_active"
DRAM_DATA_ACCESS="dram__bytes"
CONTROL_DIV="smsp__thread_inst_executed_per_inst_executed.ratio"

#############################################################################################





# ################### If your application needs MPI, use this section ###################

# # Set PATH to where mpirun is located
# export PATH="$(dirname $(which mpirun)):$PATH"

# # Set the number of MPI Ranks
# export NUM_RANKS=4

# # Set the command to run your application
# COMMAND="mpirun -n $NUM_RANKS --map-by ppr:$NUM_RANKS:node:pe=1 $APP_ROOT/app [arguments]"

# # # If you need to run multiple ranks per GPU (NUM_RANKS != Num GPUs)
# # #    you should use MPS (uncomment next line) -- Make sure no other GPU process is running
# # # NOTE: MPS support is added to NCU version 2025.2 or later: https://docs.nvidia.com/nsight-compute/ReleaseNotes/index.html#updates-in-2025-2
# # #       If you use older versions of NCU, you may not be able to use MPS.
# # nvidia-cuda-mps-control -d

# # If you have one ranks per GPU (NUM_RANKS == Num GPUs)
# #    you should turn off MPS (uncomment next line) -- Make sure no other GPU process is running
# echo quit | nvidia-cuda-mps-control

# #############################################################################################





################## If your application does not need MPI, use this section ##################

# Set the command to run your application
COMMAND="$APP_ROOT/app [arguments]"

#############################################################################################





################################# DO NOT TOUCH THE FOLLOWING ################################

PROFILE_FROM_START="on"
if [ "$ROI_PROFILE" -eq 1 ]; then
    PROFILE_FROM_START="off"
fi

METRICS="$FLOP,$SM_THROUGHPUT_UTILIZATION,$SM_OCCUPANCY,$DRAM_DATA_ACCESS,$CONTROL_DIV"

ncu -o $PROF_DIR/$PROF_FILE \
    --metrics $METRICS \
    --target-processes all \
    --replay-mode application \
    --profile-from-start $PROFILE_FROM_START \
    --csv \
    $COMMAND

ncu --page raw \
    --import $PROF_DIR/$PROF_FILE.ncu-rep \
    --csv &> $PROF_DIR/$PROF_FILE.csv

#############################################################################################