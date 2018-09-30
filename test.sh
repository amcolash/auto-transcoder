#!/bin/bash

# Cleanup / Remake tests
rm -rf "test spaces/"
mkdir "test spaces/"

# Get files if needed
if [ ! -d samples/ ]; then
    rm -rf "samples/"
    mkdir -p "samples/nested spaces"

    # Get videos
    pushd samples > /dev/null
    wget http://hubblesource.stsci.edu/sources/video/clips/details/images/centaur_2.mpg

    touch "not a video.ts"

    pushd "nested spaces" > /dev/null
    wget http://hubblesource.stsci.edu/sources/video/clips/details/images/hale_bopp_2.mpg
    mv hale_bopp_2.mpg "hale_bopp_2 and spaces.mpg"

    popd > /dev/null
    popd > /dev/null
fi

# Copy files
cp -R samples/* "test spaces/"

# Put the container into debug mode
echo DEBUG=true > .env

# Build docker container
docker-compose build

# Test it
docker-compose up

# Remove the debug mode
rm .env

# Check things
echo "All Done! Here is what we got... (Should not have logs, should only have one bad file)"
echo
echo Files:
find "test spaces"
echo
echo skipped_files.txt
cat "test spaces/skipped_files.txt"