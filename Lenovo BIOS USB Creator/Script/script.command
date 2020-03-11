#!/bin/bash

if [ ! -d /private/tmp/lenovobios ]; then
    mkdir /private/tmp/lenovobios
fi

temp_path="/private/tmp/lenovobios"

diskutil list external #> "$temp_path"/drives_pulldown

function _get_drives()
{

    if [ -f "$temp_path"/volumes ]; then
        rm "$temp_path"/volumes*
    fi

    diskutil list | grep "(disk" | grep "):" | sed 's/(.*//g' > "$temp_path"/drives_pulldown
    perl -e 'truncate $ARGV[0], ((-s $ARGV[0]) - 1)' "$temp_path"/drives_pulldown  2> /dev/null
    
}

function _refresh()
{

    diskutil list external
    diskutil list | grep "(disk" | grep "):" | sed 's/(.*//g' > "$temp_path"/drives_pulldown
    perl -e 'truncate $ARGV[0], ((-s $ARGV[0]) - 1)' "$temp_path"/drives_pulldown  2> /dev/null

}

$1
