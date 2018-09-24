#!/bin/bash

# Where your video files live
VIDEO_DIR="./videos with space/"

# Enable for logging + testing
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
if [ $DEBUG = true ]; then
    rm -rf "$VIDEO_DIR"
    mkdir -p "$VIDEO_DIR/test/test/"
    cp samples/* "$VIDEO_DIR/test/test/"
fi

if [ ! -d "$VIDEO_DIR" ]; then
    echo Video directory does not exist! Please choose valid path
    exit 1
fi

# This is going to run indefinitely (waiting for new files)
while true; do
    # Try to find a file to transcode
    FULL_PATH=`find "$VIDEO_DIR" -name '*.mpg' -o -name '*.ts' | grep -vFf skipped_files.txt | head -n 1`
    FILE=`basename "$FULL_PATH"`
    FILE_WITHOUT_EXT=`basename "$FILE" ".${FILE##*.}"`
    PARENT_PATH=`dirname "$FULL_PATH"`
    RELATIVE_PATH=`dirname "${FULL_PATH#"$VIDEO_DIR"}"`

    debug_echo full: $FULL_PATH
    debug_echo file: $FILE
    debug_echo file without ext: $FILE_WITHOUT_EXT
    debug_echo parent path: $PARENT_PATH
    debug_echo path: $RELATIVE_PATH

    # If we found a file
    if [ ${#FILE} -gt 0 ]; then
        debug_echo Beginning transcode of $FILE

        # Clear old env file
        if [ -f .env ]; then
            rm .env
        fi
        # Push in some env vars for docker
        echo VIDEO_DIR="$VIDEO_DIR" >> .env
        echo WORKING_DIR="$RELATIVE_PATH" >> .env
        echo FILE=\"/videos/"$RELATIVE_PATH"/"$FILE"\" >> .env

        # Run the transcode container
        docker-compose up

        # Wait for container and get exit code
        RET=$(docker wait auto-transcoder_transcoder_1)

        debug_echo Finished transcoding of $FILE with an exit code of $RET

        # Check if things went ok, if they did remove source and only keep final version
        if [ $RET -eq "0" ]; then
            debug_echo Cleaning up

            # Clean things up
            rm -f "$PARENT_PATH/$FILE_WITHOUT_EXT.mkv.log"
            rm -f "$FULL_PATH"
        else
            # Something went wrong, keep logs and add file to skip list
            debug_echo Something went wrong, cleaning temp files
            rm -f "$PARENT_PATH/$FILE_WITHOUT_EXT.mkv"
            echo "$FULL_PATH" >> skipped_files.txt
        fi

        sleep 1
    else
        # Nothing
        debug_echo NOOP
        sleep 60
    fi

done