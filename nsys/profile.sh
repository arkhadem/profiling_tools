################## Initial Setup -- set the following based on your config ##################

export APP_ROOT=/path/to/app/exe/dir

# Master GPU used for finding cerain metrics
export METRIC_DV=0

# Certain GPUs used for running the application
# Examples:
#     0 (GPU 0)
#     0,1,2,3 (GPUs 0, 1, 2, and 3)
export CUDA_VISIBLE_DEVICES=0

# Where to store the nsys-report and sql files
export PROF_DIR=/path/to/storage

# Name of the nsys profile file
export PROF_FILE=nsys_prof

#############################################################################################





# ################### If your application needs MPI, use this section ###################

# # Set PATH to where mpirun is located
# export PATH="$(dirname $(which mpirun)):$PATH"

# # Set the number of MPI Ranks
# export NUM_RANKS=4

# # Set the command to run your application
# COMMAND="mpirun -n $NUM_RANKS --map-by ppr:$NUM_RANKS:node:pe=1 $APP_ROOT/app [arguments]"

# # If you need to run multiple ranks per GPU (NUM_RANKS != Num GPUs)
# #    you should use MPS (uncomment next line) -- Make sure no other GPU process is running
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

nsys profile \
    -o $PROF_DIR/$PROF_FILE \
    -t cuda,nvtx,mpi \
    --cuda-memory-usage=true \
    --gpu-metrics-device=$METRIC_DV \
    --stats=true \
    --cudabacktrace=true \
    $COMMAND

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

sqlite3 $PROF_DIR/$PROF_FILE.sqlite < $SCRIPT_DIR/process_valid.sql &> $PROF_DIR/${PROF_FILE}_valid.tsv
sqlite3 $PROF_DIR/$PROF_FILE.sqlite < $SCRIPT_DIR/process_driver.sql &> $PROF_DIR/${PROF_FILE}_driver.tsv
sqlite3 $PROF_DIR/$PROF_FILE.sqlite < $SCRIPT_DIR/process_invalid.sql &> $PROF_DIR/${PROF_FILE}_invalid.tsv

#############################################################################################