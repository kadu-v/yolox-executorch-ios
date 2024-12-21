#!/bin/zsh
SCRIPT_DIR=$(cd $(dirname $0); pwd)


EXECUTORCH_VERSION=0.5.0a0+82763a9a
URL_PREBUILDT_EXECUTORCH=https://github.com/kadu-v/prebuilt-executorch/releases/download/0.5.0a0%2B82763a9a/release-0.5.0a0+82763a9a.zip

# Download prebuilt-executorch
wget $URL_PREBUILDT_EXECUTORCH -O $SCRIPT_DIR/../prebuilt-executorch.zip

# Unzip prebuilt-executorch and Rename output directory to executorch-prebuilt
unzip $SCRIPT_DIR/../prebuilt-executorch.zip -d $SCRIPT_DIR/../
mv -f $SCRIPT_DIR/../executorch-prebuilt-$EXECUTORCH_VERSION $SCRIPT_DIR/../engine/berry-executorch/executorch-prebuilt

# Clean up
rm $SCRIPT_DIR/../prebuilt-executorch.zip