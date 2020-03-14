#!/bin/bash

ScriptHome=$(echo $HOME)
ScriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
sys_language=$( defaults read -g AppleLocale )

if [[ $sys_language != de_* ]]; then
  syslang="en"
else
  syslang="de"
fi

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

    if [[ "$syslang" != "de" ]]; then
      echo "Please select ..." > "$temp_path"/drives_pulldown
    else
      echo "Bitte selektieren ..." > "$temp_path"/drives_pulldown
    fi

    diskutil list | grep "(external" | grep "):" | sed 's/(.*//g' >> "$temp_path"/drives_pulldown
    perl -e 'truncate $ARGV[0], ((-s $ARGV[0]) - 1)' "$temp_path"/drives_pulldown  2> /dev/null
    check=$( cat "$temp_path"/drives_pulldown )
    if [[ $check != *dev* ]]; then
      if [[ "$syslang" != "de" ]]; then
        echo "No suitable destination found. Make sure that you connect any USB Device to your computer."
      else
        echo "Kein geeignetes Ziel gefunden. Bitte stelle sicher, das ein USB Gerät mit Deinem Computer verbunden ist."
      fi
    fi
}

function _refresh()
{

    if [[ "$syslang" != "de" ]]; then
      echo "Please select ..." > "$temp_path"/drives_pulldown
    else
      echo "Bitte selektieren ..." > "$temp_path"/drives_pulldown
    fi
    diskutil list external
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
      if [[ "$syslang" != "de" ]]; then
        echo "Error. Please select destination device first!"
        exit
      else
        echo "Fehler. Bitte wähle erst ein Zielgerät aus!"
        exit
      fi
    fi

    if [[ $dest = "Please select ..." ]]; then
      echo "Error. Please select destination device first!"
      exit
    fi
 
    if [[ $dest = "Bitte selektieren ..." ]]; then
      echo "Fehler. Bitte wähle erst ein Zielgerät aus!"
      exit
    fi
 
    if [[ $isopath = "" ]]; then
      if [[ "$syslang" != "de" ]]; then
        echo "Error. Please select a Lenovo .iso first!"
      else
        echo "Fehler. Bitte wähle zuerst eine Lenovo ISO Datei aus!"
      fi
      exit
    fi

    strings "$isopath" |grep LenovoSecureFlash > /dev/null
    
    if [[ $? != "0" ]]; then
      if [[ "$syslang" != "de" ]]; then
        echo "Error. That seems to be no or a damaged Leneovo ISO File!"
      else
        echo "Fehler. Das scheint kein oder ein beschädigtes Lenovo ISO Image zu sein!"
      fi
      exit
    fi
    
    which perl > /dev/null
    if [[ $? != "0" ]]; then
      _helpDefaultWrite "Perl" "No"
      unzip -qo "$ScriptPath"/../Perl/perl.zip -d "$temp_path"
        if [ ! -d /usr/local/Cellar ]; then
          _helpDefaultWrite "Cellar" "No"
          cd "$ScriptPath"
        fi
      osascript -e 'do shell script "mkdir /usr/local/Cellar; cd /usr/local/Cellar; ln -s '$temp_path'/perl perl" with administrator privileges'
    fi
    
    if [[ "$syslang" != "de" ]]; then
      echo -e "Converting $isoname ..."
    else
      echo -e "Konvertiere $isoname ..."
    fi

    perl_pre=$( _helpDefaultRead "Perl" )
    if [[ "$perl_pre" = "No" ]]; then
      /usr/local/Cellar/perl/5.30.0/bin/perl "$ScriptPath"/geteltorito.pl -o "$temp_path"/patched.iso "$isopath"
    else
      perl_bin=$( which perl )
      "$perl_bin" "$ScriptPath"/geteltorito.pl -o "$temp_path"/patched.iso "$isopath"
    fi

    if [[ $? != "0" ]]; then
      if [[ "$syslang" != "de" ]]; then
        echo -e "An Error has occured. Try again.\n"
      else
        echo -e "Ein Fehler ist aufgetreten. Versuche es noch einmal.\n"
      fi
      exit
    else
      if [[ "$syslang" != "de" ]]; then
        echo -e "Done.\n"
      else
        echo -e "Fertig.\n"
      fi
    fi

    if [[ "$syslang" != "de" ]]; then
      echo -e "Writing $isoname to $dest ..."
    else
      echo -e "Schreibe $isoname auf $dest ..."
    fi

    diskutil unmountDisk "$dest" > /dev/null

    osascript -e 'do shell script "dd if='$temp_path'/patched.iso of='$dest' bs=2m > /dev/null; hdiutil attach '$dest's1 > /dev/null" with administrator privileges'
    
    if [[ $? != "0" ]]; then
      if [[ "$syslang" != "de" ]]; then
        echo -e "An Error has occured. Try again.\n"
      else
        echo -e "Ein Fehler ist aufgetreten. Versuche es noch einmal.\n"
      fi
      exit
    else
      if [[ "$syslang" != "de" ]]; then
        echo -e "Done.\n"
      else
        echo -e "Fertig.\n"
      fi
    fi
    
}

function _quit_app()
{
  cellar_preinstalled=$( _helpDefaultRead "Cellar" )
  if [[ "$cellar_preinstalled" = "No" ]]; then
    osascript -e 'do shell script "rm -rf /usr/local/Cellar" with administrator privileges'
  else
    perl_preinstalled=$( _helpDefaultRead "Perl" )
    if [[ "$perl_preinstalled" = "No" ]]; then
      if [ -d /usr/local/Cellar/perl ]; then
        osascript -e 'do shell script "rm -rf /usr/local/Cellar/perl" with administrator privileges'
        cd "$ScriptPath"
      fi
    fi
  fi
  rm -rf "$temp_path"
}

$1
