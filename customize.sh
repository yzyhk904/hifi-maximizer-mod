#!/system/bin/sh

# Replace rsumbix audio policy configuration file (default)
REPLACE="
/system/vendor/etc/r_submix_audio_policy_configuration.xml
"
. "$MODPATH/functions.sh"

# Set the active configuration file name
configXML="`getActivePolicyFile`"

case "$configXML" in
    /vendor/etc/* )
        # If DRC enabled, modify audio policy configuration to stopt DRC
        MAGISKPATH="$(magisk --path)"
        if [ -n "$MAGISKPATH"  -a  -r "$MAGISKPATH/.magisk/mirror/system${configXML}" ]; then
            mirrorConfigXML="$MAGISKPATH/.magisk/mirror/system${configXML}"
        else
            mirrorConfigXML="$configXML"
        fi
        grep -e "speaker_drc_enabled[[:space:]]*=[[:space:]]*\"true\"" $mirrorConfigXML >"/dev/null" 2>&1
        if [ "$?" -eq 0 ]; then
            modConfigXML="$MODPATH/system${configXML}"
            mkdir -p "${modConfigXML%/*}"
            touch "$modConfigXML"
            stopDRC "$mirrorConfigXML" "$modConfigXML"
            chmod 644 "$modConfigXML"
            chmod -R a+rX "$MODPATH/system/vendor/etc"
            REPLACE="/system${configXML} $REPLACE"
        fi
        ;;
    * )
        ;;
esac

# Replace the value of "ro.audio.usb.period_us"

if "$IS64BIT"; then
 :
else
  sed -i 's/ro\.audio\.usb\.period_us=.*$/ro\.audio\.usb\.period_us=5600/' "$MODPATH/system.prop"
fi
