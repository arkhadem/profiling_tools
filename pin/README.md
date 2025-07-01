

## Install Intel Pin

1- Download Intel Pin (.tar.gz file) [from here](https://www.intel.com/content/www/us/en/developer/articles/tool/pin-a-binary-instrumentation-tool-downloads.html) and extract it.

2- Copy the MICA directory from this repository and directory to the Pin root.

4- Build MICA. After this step, a directory named `obj-intel64` will be created under `$PIN_ROOT/MICA`. It will contain `mica.so` and `mica_itypes.o`.

```bash
# Setup
export PIN_ROOT=/path/to/pin/
export PIN_FILE=/path/to/pin/file.tar.gz
export GIT_REPO=/path/to/repo/profiling_tools/

# Step 1
tar -xvzf $PIN_FILE -C $PIN_ROOT --strip-components=1

# Step 2
cp -r $GIT_REPO/pin/MICA $PIN_ROOT

# Step 4
cd $PIN_ROOT/MICA
make -j
```

## Inject MICA APIs

To start/end MICA instrumentation before/after your Region of Interest (ROI), copy the content of `API.h` to your ROI file. Use `BEGIN_PIN_ROI` and `END_PIN_ROI` before and after your ROI, and compile your application. Two example files are located in this directory.

## Direct Instrumentation

You can use the following command to run the Pin and application together:

