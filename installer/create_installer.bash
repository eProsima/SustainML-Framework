#!/bin/bash

default_version="0.2.0"

if [ -z $1 ]; then
    echo "Using the default version: " $default_version
else
    default_version=$1
fi

# set the final installer name with the version
installer_name="SustainML_"
installer_name+=$default_version
installer_name+="_installer"

# put current date as yyyy-mm-dd
date=$(date '+%Y-%m-%d')

# The GUI binary, from a build in this repository (build*/) or in a colcon workspace (build/sustainml/)
binary=$(ls ../build*/sustainml ../../../build/sustainml/sustainml 2>/dev/null | head -n 1)
if [ -z "$binary" ]; then
    echo "SustainML binary not found: build the framework first"
    exit 1
fi

# clean installer env
mkdir -p packages/com.eProsima.SustainML/data
rm -rf packages/com.eProsima.SustainML/data/*

# copy the required files
cp "$binary" packages/com.eProsima.SustainML/data/sustainml
cp ../LICENSE packages/com.eProsima.SustainML/meta/LICENSE

# set the given version in the configuration files, and the current date
sed -i "/<Version>/c<Version>$default_version</Version>" config/config.xml
sed -i "/<Version>/c<Version>$default_version</Version>" packages/com.eProsima.SustainML/meta/package.xml
sed -i "/<ReleaseDate>/c<ReleaseDate>$date</ReleaseDate>" packages/com.eProsima.SustainML/meta/package.xml

# create installer (QTIFW_DIR: the Qt Installer Framework installation to use)
qtifw_dir=${QTIFW_DIR:-~/Qt/Tools/QtInstallerFramework/4.5}
"$qtifw_dir"/bin/binarycreator -c config/config.xml -p packages $installer_name
