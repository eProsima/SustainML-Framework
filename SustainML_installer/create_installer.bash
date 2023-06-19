#!/bin/bash

default_version="0.0.0"

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

# clean installer env
rm -rf packages/com.eProsima.SustainML/data/*

# copy the required files
cp -r ../build*/SustainML packages/com.eProsima.SustainML/data/SustainML

# set the given version in the configuration files, and the current date
sed -i "/<Version>/c<Version>$default_version</Version>" config/config.xml
sed -i "/<Version>/c<Version>$default_version</Version>" packages/com.eProsima.SustainML/meta/package.xml
sed -i "/<ReleaseDate>/c<ReleaseDate>$date</ReleaseDate>" packages/com.eProsima.SustainML/meta/package.xml

# create installer
~/Qt/Tools/QtInstallerFramework/4.5/bin/binarycreator -c config/config.xml -p packages $installer_name
