#!/bin/bash

ScriptHome=$(echo $HOME)

function _helpDefaultWrite()
{
    VAL=$1
    local VAL1=$2

    if [ ! -z "$VAL" ] || [ ! -z "$VAL1" ]; then
    defaults write "${ScriptHome}/Library/Preferences/lenovobiosusbcreator.slsoft.de.plist" "$VAL" "$VAL1"
    fi
}

function _helpDefaultRead()
{
    VAL=$1

    if [ ! -z "$VAL" ]; then
    defaults read "${ScriptHome}/Library/Preferences/lenovobiosusbcreator.slsoft.de.plist" "$VAL"
    fi
}


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

function _get_isoname()
{

    get_name=$( _helpDefaultRead "Isopath" )
    isoname=$( echo "$get_name" |sed 's/.*\///' )
    _helpDefaultWrite "Isoname" "$isoname"
    
}

$1
