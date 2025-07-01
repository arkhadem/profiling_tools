

## Install Intel Pin

1- Download Intel Pin (.tar.gz file) [from here](https://www.intel.com/content/www/us/en/developer/articles/tool/pin-a-binary-instrumentation-tool-downloads.html).

2- Extract the file using ``. Replace `/path/to/pin/` with your desired Intel Pin path.

3- Copy the MICA directory from here to the PIN path:

```bash
# Step 2
export PIN_HOME=/path/to/pin/
export PIN_FILE=/path/to/pin/file.tar.gz
tar -xvzf $PIN_FILE -C $PIN_HOME --strip-components=1

# Step 3
cp -r ./MICA $PIN_HOME

# Step 4
cd $PIN_HOME

tar -xvzf your_file.tar.gz -C

```