#!/bin/bash

# Start where the script lives
pushd $(dirname "$0") > /dev/null

# Cleanup / Remake tests
rm -rf "test spaces/"
mkdir "test spaces/"
mkdir "test spaces/multilevel 'quotes/"

# Get files if needed
if [ ! -d samples/ ]; then
    rm -rf "samples/"
    mkdir -p "samples/nested spaces"

    # Get videos
    pushd samples > /dev/null
    wget https://github.com/Matroska-Org/matroska-test-files/raw/master/test_files/test5.mkv
    mv test5.mkv test5.mpg
    wget http://hubblesource.stsci.edu/sources/video/clips/details/images/centaur_2.mpg

    touch "not a video.ts"
    touch "test locking.mpg"
    touch "test locking.mpg.lock"

    pushd "nested spaces" > /dev/null
    wget http://hubblesource.stsci.edu/sources/video/clips/details/images/hale_bopp_2.mpg
    mv hale_bopp_2.mpg "hale_bopp_2 and spaces.mpg"

    popd > /dev/null
    popd > /dev/null
fi

# Copy files
cp -R samples/* "test spaces/"

# Test quotes too
cp samples/centaur_2.mpg "test spaces/'test' quotes\"def \"hij.mpg"
cp samples/centaur_2.mpg "test spaces/multilevel 'quotes/'test' 'quotes\"def \"hij.mpg"
mkdir "test spaces/with 'some quotes 'too'/"
cp samples/centaur_2.mpg "test spaces/with 'some quotes 'too'/test \"'a 'b \"c'.mpg"

# Put the container into debug mode, add video path
rm -f .env
echo DEBUG=true > .env
echo VIDEO_DIR="./test spaces/" >> .env

# Build docker container
docker-compose build

# Test it
docker-compose up

# Stop things since it is set to auto-restart
docker-compose down

# Remove the debug mode
rm -f .env

# Check things
echo "All Done! Here is what we got... (For now need to manually check things out)"
echo
echo Files:
find "test spaces" -type f | sort
echo
echo skipped_files.txt:
cat "test spaces/skipped_files.txt"

# Back to the start
popd > /dev/null
