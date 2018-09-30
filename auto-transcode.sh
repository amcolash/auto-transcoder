#!/bin/bash

VIDEO_DIR=/videos

# Enable for logging + testing
DEBUG=true

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

# This is going to run indefinitely (waiting for new files)
while true; do
    # Try to find a file to transcode
    FULL_PATH=`find "$VIDEO_DIR" -name '*.mpg' -o -name '*.ts' | grep -vFf skipped_files.txt | head -n 1`
    FILE=`basename "$FULL_PATH"`
    FILE_WITHOUT_EXT=`basename "$FILE" ".${FILE##*.}"`
    PARENT_PATH=`dirname "$FULL_PATH"`

    debug_echo full: $FULL_PATH
    debug_echo file: $FILE
    debug_echo file without ext: $FILE_WITHOUT_EXT
    debug_echo parent path: $PARENT_PATH

    # If we found a file
    if [ ${#FILE} -gt 0 ]; then
        debug_echo Beginning transcode of $FILE

        # Change working dir
        pushd "$PARENT_PATH"

        # Clean things up if there is an existing file there
        if [ -f "$PARENT_PATH/$FILE_WITHOUT_EXT.mkv" ]; then
            rm -f "$PARENT_PATH/$FILE_WITHOUT_EXT.mkv"
        fi

        # Wait for container and get exit code
        transcode-video --add-audio eng --quick "$FILE"
        RET_VAL=$?

        debug_echo "Finished transcoding of $FILE with an exit code of $RET_VAL"

        # Check if things went ok, if they did remove source and only keep final version
        if [ $RET_VAL -eq 0 ]; then
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

        # Back to working dir
        popd

        sleep 1
    else
        # Nothing
        debug_echo NOOP

        # Exit if we are debugging here
        if [ $DEBUG = true ]; then
            exit 0
        fi

        # Wait for new files
        sleep 60
    fi

done