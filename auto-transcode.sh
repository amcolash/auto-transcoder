#!/bin/bash

# Where your video files live
VIDEO_DIR=./videos/

# Enable for logging
DEBUG=false

# Helper logging function
function debug_echo()
{
    if [ $DEBUG = true ]; then
        echo "$@"
    fi
}

# Cleanup skipped files - give them another chance
if [ -f skipped_files.txt ]; then
    rm skipped_files.txt
fi
touch skipped_files.txt

# TESTING
rm -rf videos/
mkdir videos/
cp samples/* videos

# This is going to run indefinitely (waiting for new files)
while true; do
    # Try to find a file to transcode
    FILE=`find videos/ -name '*.mpg' -o -name '*.ts' | grep -vFf skipped_files.txt | head -n 1`

    # If we found a file
    if [ ${#FILE} -gt 0 ]; then
        debug_echo Beginning transcode of $FILE

        # Push the file into an env var that docker picks up
        rm .env
        echo VIDEO_DIR="$VIDEO_DIR" >> .env
        echo FILE=\""$FILE"\" >> .env

        # Run the transcode container
        docker-compose up

        # Get the exit code of the container
        RET=$(docker wait auto-transcoder_transcoder_1)
        debug_echo Finished transcoding of $FILE with an exit code of $RET

        if [ $RET -eq "0" ]; then
            debug_echo Cleaning up

            # Clean things up
            rm -f videos/*.log
            rm -f $FILE
        else
            debug_echo Something went wrong, no cleanup
            echo $FILE >> skipped_files.txt
        fi

        sleep 1
    else
        # Nothing
        debug_echo NOOP
        sleep 60
    fi

done