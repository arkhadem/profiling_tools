
NUM_RANKS=6
NUM_LEVELS=3
MESH_XYZ=128
BLOCK_XYZ=32
TIME_STEPS=250
DV=5

COMMAND="/sw/pkgs/arc/stacks/gcc/10.3.0/openmpi/4.1.6-cuda/bin/mpirun -n $NUM_RANKS --map-by ppr:$NUM_RANKS:node:pe=1 /home/arkhadem/pp/parthenon/build_GPU_debug_instrument/benchmarks/burgers/burgers-benchmark -i benchmarks/burgers/burgers.pin parthenon/mesh/nx1=$MESH_XYZ parthenon/mesh/nx2=$MESH_XYZ parthenon/mesh/nx3=$MESH_XYZ parthenon/meshblock/nx1=$BLOCK_XYZ parthenon/meshblock/nx2=$BLOCK_XYZ parthenon/meshblock/nx3=$BLOCK_XYZ parthenon/time/nlim=$TIME_STEPS parthenon/mesh/numlevel=$NUM_LEVELS"

PROF_NAME="nsys_profile_250_b${BLOCK_XYZ}_n$NUM_RANKS"

echo $COMMAND

# Turn on MPS
# nvidia-cuda-mps-control -d

# Turn off MPS
# echo quit | nvidia-cuda-mps-control

export PATH=/sw/pkgs/arc/stacks/gcc/10.3.0/openmpi/4.1.6-cuda/bin:/$PATH

NSYS_COMMAND="CUDA_VISIBLE_DEVICES=$DV \
    nsys profile \
    -o "/scratch/kdur_root/kdur/arkhadem/nsys/${PROF_NAME}" \
    -t cuda,nvtx,mpi \
    --cuda-memory-usage=true \
    --gpu-metrics-device=$DV \
    --stats=true \
    --cudabacktrace=true \
    $COMMAND"

echo $NSYS_COMMAND

CUDA_VISIBLE_DEVICES=5 /sw/pkgs/arc/stacks/gcc/10.3.0/openmpi/4.1.6-cuda/bin/mpirun -n 6 --map-by ppr:6:node:pe=1 /home/arkhadem/pp/parthenon/build_GPU_debug_instrument/benchmarks/burgers/burgers-benchmark -i benchmarks/burgers/burgers.pin parthenon/mesh/nx1=128 parthenon/mesh/nx2=128 parthenon/mesh/nx3=128 parthenon/meshblock/nx1=32 parthenon/meshblock/nx2=32 parthenon/meshblock/nx3=32 parthenon/time/nlim=250 parthenon/mesh/numlevel=3
CUDA_VISIBLE_DEVICES=5 nsys profile -o /scratch/kdur_root/kdur/arkhadem/nsys/nsys_profile_250_b32_n6 -t cuda,nvtx,mpi --cuda-memory-usage=true --gpu-metrics-device=5 --stats=true --cudabacktrace=true /sw/pkgs/arc/stacks/gcc/10.3.0/openmpi/4.1.6-cuda/bin/mpirun -n 6 --map-by ppr:6:node:pe=1 /home/arkhadem/pp/parthenon/build_GPU_debug_instrument/benchmarks/burgers/burgers-benchmark -i benchmarks/burgers/burgers.pin parthenon/mesh/nx1=128 parthenon/mesh/nx2=128 parthenon/mesh/nx3=128 parthenon/meshblock/nx1=32 parthenon/meshblock/nx2=32 parthenon/meshblock/nx3=32 parthenon/time/nlim=250 parthenon/mesh/numlevel=3