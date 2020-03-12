#!/bin/bash

ScriptHome=$(echo $HOME)
ScriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

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

function _initial()
{

    diskutil list external

}
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
    diskutil list | grep "(disk" | grep "):" | sed 's/(.*//g' | xargs > "$temp_path"/drives_pulldown
    perl -e 'truncate $ARGV[0], ((-s $ARGV[0]) - 1)' "$temp_path"/drives_pulldown  2> /dev/null

}

function _get_isoname()
{

    get_name=$( _helpDefaultRead "Isopath" )
    isoname=$( echo "$get_name" |sed 's/.*\///' )
    _helpDefaultWrite "Isoname" "$isoname"
    
}

function _write_device()
{

    dest=$( _helpDefaultRead "Destination" |xargs )
    isopath=$( _helpDefaultRead "Isopath" )
    isoname=$( _helpDefaultRead "Isoname" )
    
    if [[ $dest = "" ]]; then
      echo "Error. Please select destination device first!"
      exit
    fi
    
    if [[ $isopath = "" ]]; then
      echo "Error. Please select a Lenovo .iso first!"
      exit
    fi

    strings "$isopath" |grep LenovoSecureFlash > /dev/null
    
    if [[ $? != "0" ]]; then
      echo "Error. That seems to be a wrong or damaged ISO File!"
      exit
    fi
    
    echo -e "Converting $isoname"

    /usr/local/Cellar/perl/5.30.0/bin/perl "$ScriptPath"/geteltorito.pl -o "$temp_path"/patched.iso "$isopath"

    if [[ $? != "0" ]]; then
      echo -e "An Error has occured. Try again.\n"
      exit
    else
      echo -e "Done.\n"
    fi

    echo -e "Writing $isoname to $dest"

    diskutil unmountDisk "$dest" > /dev/null

    dd if="$temp_path"/patched.iso of="$dest"
    
    if [[ $? != "0" ]]; then
      echo -e "An Error has occured. Try again.\n"
      exit
    else
      echo -e "Done.\n"
    fi
    
    hdiutil attach "$dest"s1 > /dev/null
    
}

#function _check_perl()
#{
#
#    which perl
#    if [[ $? != "0" ]]; then
#      unzip -qo "$ScriptPath"/../Perl/perl.zip -d "$temp_path"/
#        if [ ! -d /usr/local/Cellar/perl ]; then
#          mkdir /usr/local/Cellar
#          cd /usr/local/Cellar
#          ln -s "$temp_path"/perl perl
#          cd "$ScriptPath"
#    fi
#}

$1
