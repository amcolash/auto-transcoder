#!/bin/bash

# Enable for logging + testing
if [ -z "$DEBUG" ]; then
    DEBUG=false
fi

# Helper logging function
function debug_echo()
{
    if [ $DEBUG = true ]; then
        echo "$@"
    fi
}

# Cleanup skipped files - give them another chance
rm -f /videos/skipped_files.txt
touch /videos/skipped_files.txt

# This is going to run indefinitely (waiting for new files)
while true; do

    # Clean up variables
    unset FULL_PATH
    unset FILE
    unset FILE_WITHOUT_EXT
    unset PARENT_PATH

    # Find all files (this is a do-while loop, look below)
    while read FULL_PATH; do
        # Ignore empty lines
        if [ ${#FULL_PATH} -eq 0 ]; then
            continue
        fi

        # Get parts of the file name
        FILE=`basename "$FULL_PATH"`
        FILE_WITHOUT_EXT=`basename "$FILE" ".${FILE##*.}"`
        PARENT_PATH=`dirname "$FULL_PATH"`

        # Check if the file is locked, if it is ignore (for now), else contine on to convert
        if [ -f "$FULL_PATH.lock" ]; then
            echo Found a locked file: $FULL_PATH

            # Clean up variables
            unset FULL_PATH
            unset FILE
            unset FILE_WITHOUT_EXT
            unset PARENT_PATH
        else
            echo Found a non-locked file: $FULL_PATH
            break
        fi

    # Some bash magic that makes this all run in the same process, the found files are piped in a different way to the loop
    done < <(find "/videos" -name '*.mpg' -o -name '*.ts' | sort | grep -vaFf "/videos/skipped_files.txt")

    # If we found a file
    if [ ${#FILE} -gt 0 ]; then
        debug_echo full: $FULL_PATH
        debug_echo file: $FILE
        debug_echo file without ext: $FILE_WITHOUT_EXT
        debug_echo parent path: $PARENT_PATH

        # Double check the file still exists
        if [ ! -f $FULL_PATH ]; then
            echo Error, missing file: $FILE
        else
            echo Beginning transcode of $FILE

            # Change working dir
            pushd "$PARENT_PATH" > /dev/null

            # Clean things up if there is an existing file there
            rm -f "$PARENT_PATH/$FILE_WITHOUT_EXT.mkv"

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
                echo "$FULL_PATH" >> /videos/skipped_files.txt
            fi

            # Back to working dir
            popd > /dev/null

            sleep 1
        fi
    else
        # Nothing
        echo No files found, waiting to check again...

        # Exit if we are debugging here
        if [ $DEBUG = true ]; then
            exit 0
        fi

        # Wait for new files
        sleep 60
    fi

done
