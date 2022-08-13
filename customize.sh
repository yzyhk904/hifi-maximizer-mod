#!/system/bin/sh

# Replace r_submix audio policy configuration file (default)
REPLACE="
/system/vendor/etc/r_submix_audio_policy_configuration.xml
"
. "$MODPATH/functions.sh"

# Set the active configuration file name retrieved from the audio policy server
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

# Replace system property values for old Androids and some low performance SoC's

function loosenedMessage()
{
    local freq="96kHz"
    if [ $# -gt 0 ]; then
        freq="$1"
    fi
    
    ui_print ""
    ui_print "****************************************************************"
    ui_print " Loosened the USB jitter level for more than $freq USB outputs! "
    ui_print "   (\"USB Samplerate Unlocker\" was detected) "
    ui_print "****************************************************************"
    ui_print ""
}

function replaceSystemProps_Old()
{
    if [ -e "${MODPATH%/*/*}/modules/usb-samplerate-unlocker"  -o  -e "${MODPATH%/*/*}/modules_update/usb-samplerate-unlocker" ]; then
        sed -i \
            -e 's/ro\.audio\.usb\.period_us=.*$/ro\.audio\.usb\.period_us=3875/' \
                "$MODPATH/system.prop"
        sed -i \
            -e 's/ro\.audio\.usb\.period_us=.*$/ro\.audio\.usb\.period_us=3875/' \
                "$MODPATH/system.prop-workaround"
        
        loosenedMessage
        
    fi
    
    sed -i \
        -e 's/ro\.audio\.resampler\.psd\.enable_at_samplerate=.*$/ro\.audio\.resampler\.psd\.enable_at_samplerate=48000/' \
        -e 's/ro\.audio\.resampler\.psd\.stopband=.*$/ro\.audio\.resampler\.psd\.stopband=167/' \
        -e 's/ro\.audio\.resampler\.psd\.halflength=.*$/ro\.audio\.resampler\.psd\.halflength=368/' \
        -e 's/ro\.audio\.resampler\.psd\.tbwcheat=.*$/ro\.audio\.resampler\.psd\.tbwcheat=106/' \
            "$MODPATH/system.prop"
    sed -i \
        -e 's/ro\.audio\.resampler\.psd\.halflength=.*$/ro\.audio\.resampler\.psd\.halflength=320/' \
            "$MODPATH/system.prop-workaround"

}

function replaceSystemProps_S4()
{
    if [ -e "${MODPATH%/*/*}/modules/usb-samplerate-unlocker"  -o  -e "${MODPATH%/*/*}/modules_update/usb-samplerate-unlocker" ]; then
        sed -i \
            -e 's/ro\.audio\.usb\.period_us=.*$/ro\.audio\.usb\.period_us=3875/' \
                "$MODPATH/system.prop"
        sed -i \
            -e 's/ro\.audio\.usb\.period_us=.*$/ro\.audio\.usb\.period_us=3875/' \
                "$MODPATH/system.prop-workaround"
        
        loosenedMessage

    fi
    
    sed -i \
        -e 's/ro\.audio\.resampler\.psd\.stopband=.*$/ro\.audio\.resampler\.psd\.stopband=194/' \
        -e 's/ro\.audio\.resampler\.psd\.halflength=.*$/ro\.audio\.resampler\.psd\.halflength=520/' \
        -e 's/ro\.audio\.resampler\.psd\.tbwcheat=.*$/ro\.audio\.resampler\.psd\.cutoff_percent=100/' \
            "$MODPATH/system.prop"
    sed -i \
        -e 's/ro\.audio\.resampler\.psd\.halflength=.*$/ro\.audio\.resampler\.psd\.halflength=320/' \
            "$MODPATH/system.prop-workaround"
}

function replaceSystemProps_Kona()
{
    if [ -e "${MODPATH%/*/*}/modules/usb-samplerate-unlocker"  -o  -e "${MODPATH%/*/*}/modules_update/usb-samplerate-unlocker" ]; then
        sed -i \
            -e 's/ro\.audio\.usb\.period_us=.*$/ro\.audio\.usb\.period_us=20375/' \
                "$MODPATH/system.prop"
        sed -i \
            -e 's/ro\.audio\.usb\.period_us=.*$/ro\.audio\.usb\.period_us=20375/' \
                "$MODPATH/system.prop-workaround"
        
        loosenedMessage "192kHz"
        
    fi
}

function replaceSystemProps_MTK_Dimensity()
{
    if [ -e "${MODPATH%/*/*}/modules/usb-samplerate-unlocker"  -o  -e "${MODPATH%/*/*}/modules_update/usb-samplerate-unlocker" ]; then
        sed -i \
            -e '$avendor.audio.usb.out.period_us=3250\nvendor.audio.usb.out.period_count=2' \
                "$MODPATH/system.prop"
        sed -i \
            -e '$avendor.audio.usb.out.period_us=3250\nvendor.audio.usb.out.period_count=2' \
                "$MODPATH/system.prop-workaround"
        
        loosenedMessage
        
    else
        sed -i \
            -e '$avendor.audio.usb.out.period_us=2625\nvendor.audio.usb.out.period_count=2' \
                "$MODPATH/system.prop"
        sed -i \
            -e '$avendor.audio.usb.out.period_us=2625\nvendor.audio.usb.out.period_count=2' \
                "$MODPATH/system.prop-workaround"
        
    fi
}

function replaceSystemProps_Others()
{
    if [ -e "${MODPATH%/*/*}/modules/usb-samplerate-unlocker"  -o  -e "${MODPATH%/*/*}/modules_update/usb-samplerate-unlocker" ]; then
        loosenedMessage
        
        sed -i \
            -e 's/ro\.audio\.usb\.period_us=.*$/ro\.audio\.usb\.period_us=3250/' \
                "$MODPATH/system.prop"
        sed -i \
            -e 's/ro\.audio\.usb\.period_us=.*$/ro\.audio\.usb\.period_us=3250/' \
                "$MODPATH/system.prop-workaround"
        
    fi
    
}

if "$IS64BIT"; then
    local board="`getprop ro.board.platform`"
    case "$board" in
        "kona" )
            replaceSystemProps_Kona
            ;;
        mt68* )
            if [ -r "/vendor/lib64/hw/audio.usb.${board}.so" ]; then
                replaceSystemProps_MTK_Dimensity
            else
                replaceSystemProps_Others
            fi
            ;;
        mt67[56]? )
            replaceSystemProps_Others
            ;;
        * )
            replaceSystemProps_Others
            ;;
    esac

else
    if [ "`getprop ro.build.product`" = "jfltexx" ]; then
        replaceSystemProps_S4
    else
        replaceSystemProps_Old
    fi

fi

# AudioFlinger's resampler has a bug on an Android OS of which version is less than 12.
# This bug makes the resampler to distort audible audio output by wrong aliasing processing
#   when specifying a transition band around or higher than the Nyquist frequency

if [ "`getprop ro.system.build.version.release`" -lt "12"  -a  "`getprop ro.system.build.date.utc`" -lt "1648632000" ]; then
    mv -f "$MODPATH/system.prop-workaround" "$MODPATH/system.prop"
else
    rm -f "$MODPATH/system.prop-workaround"
fi
