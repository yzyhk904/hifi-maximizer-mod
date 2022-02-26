#!/system/bin/sh

# Replace r_submix audio policy configuration file (default)
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
        if [ -n "$MAGISKPATH"  -a  -r "$MAGISKPATH/.magisk/mirror${configXML}" ]; then
            
            # Don't use "$MAGISKPATH/.magisk/mirror/system${configXML}" instead of "$MAGISKPATH/.magisk/mirror${configXML}".
            # In some cases, the former may link to overlaied "${configXML}" by Magisk itself (not original mirrored "${configXML}".
            mirrorConfigXML="$MAGISKPATH/.magisk/mirror${configXML}"
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

# Replace system property values for some low performance SoC's

function replaceSystemProps()
{
    sed -i \
        -e 's/ro\.audio\.usb\.period_us=.*$/ro\.audio\.usb\.period_us=5600/' \
        -e 's/ro\.audio\.resampler\.psd\.halflength=.*$/ro\.audio\.resampler\.psd\.halflength=320/' \
            "$MODPATH/system.prop"
}

if "$IS64BIT"; then
    case "`getprop ro.board.platform`" in
        mt67[56]? )
            replaceSystemProps
            ;;
    esac
else
    replaceSystemProps
fi
