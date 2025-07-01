# Instruction Opcode Distribution using Intel Pin

This repository contains tools, scripts, and example code for analyzing the instruction opcode distribution of applications using [Intel Pin](https://www.intel.com/content/www/us/en/developer/articles/tool/pin-a-dynamic-binary-instrumentation-tool.html) with the [MICA tool](https://github.com/boegel/MICA/). The original source for this tool can be found [here](https://github.com/kaplannp/OneStopProfileShop/).

---

## Installation Instructions

### 1. Install Intel Pin

1. Download the Intel Pin `.tar.gz` archive [from here](https://www.intel.com/content/www/us/en/developer/articles/tool/pin-a-binary-instrumentation-tool-downloads.html) and extract it.
2. Copy the `MICA` directory from this repository into the Pin root directory.
3. Build MICA. This will create an `obj-intel64` directory under `$PIN_ROOT/MICA` containing `mica.so` and `mica_itypes.o`.
4. Copy the MICA configuration file `mica.conf` to the application's working directory.

```bash
# Setup
export PIN_ROOT=/path/to/pin
export PIN_FILE=/path/to/pin/file.tar.gz
export GIT_REPO=/path/to/repo/profiling_tools
export APP_ROOT=/path/to/application

# Step 1: Extract Pin
tar -xvzf $PIN_FILE -C $PIN_ROOT --strip-components=1

# Step 2: Copy MICA
cp -r $GIT_REPO/pin/MICA $PIN_ROOT

# Step 3: Build MICA
cd $PIN_ROOT/MICA
make -j

# Step 4: Copy configuration
cp $GIT_REPO/pin/mica.conf $APP_ROOT
```

## Injecting MICA APIs

To profile only a specific Region of Interest (ROI), copy the contents of `API.h` in your source file. Use the `BEGIN_PIN_ROI` and `END_PIN_ROI` macros to mark the start and end of the ROI, then compile your application as usual.

## Example Applications

Two example applications are provided in this directory. Compile them using:

```bash
cd $GIT_REPO/pin
g++ -march=native -O3 ./example.cpp -o example
mpic++ -march=native -O3 ./example_mpi.cpp -o example_mpi
```


## Instrumentation Options

### Option 1: Instrument from the Beginning

Use this method to launch the application with Pin instrumentation from the beginning. This approach is only suggested for small applications and for when majority of time goes to your ROI.

```bash
cd $APP_ROOT                # e.g., export APP_ROOT=$GIT_REPO/pin; cd $APP_ROOT;
COMMAND="./app [arguments]" # e.g., COMMAND="./example"
$PIN_ROOT/pin -t $PIN_ROOT/MICA/obj-intel64/mica.so -- $COMMAND
```

> **Note:** Running Pin from the beginning adds significant instrumentation overhead (5-10× your application time). To reduce this overhead, attach Pin just before entering the ROI using the following option.

### Option 2: Attach to Process Before ROI

To attach Pin to a running application just before the ROI:

1. Retrieve the process ID (PID) from within your application or via `htop`. You can use the following C++ snippet:

```cpp
int my_rank;
MPI_Comm_rank(MPI_COMM_WORLD, &my_rank);

if (my_rank == 0) {
    std::cout << "PID: " << getpid() << std::endl;
}
```

2. Open two terminals:

**Terminal 1: Run the Application**

```bash
cd $APP_ROOT            # e.g., export APP_ROOT=$GIT_REPO/pin; cd $APP_ROOT;
./app [arguments]       # e.g., mpirun -n 2 ./example_mpi
```

**Terminal 2: Attach Pin (just before ROI)**

```bash
$PIN_ROOT/pin -pid [PID] -t $PIN_ROOT/MICA/obj-intel64/mica.so
```

## Output Reports

After instrumentation, two output files will be generated in the `$APP_ROOT` directory:

- **`itypes_full_int_pin.out`**: Contains instruction counts across the following categories:
  - `Total`, `NOP`, `VLD/VST`, `LD/ST`, `FP`, `VEC`, `CTRL`, `REG`, `SCALAR`, `OTHER`

- **`itypes_other_group_categories.txt`**: Provides a detailed breakdown of instruction types classified under the `OTHER` category in the file above.