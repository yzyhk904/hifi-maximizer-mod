#!/system/bin/sh

. "$MODPATH/customize-functions.sh"

# Replace r_submix audio policy configuration file (default)
REPLACE="
/system/vendor/etc/r_submix_audio_policy_configuration.xml
"

for i in $REPLACE; do
    if [ -r "$i" ]; then
        chmod 644 "${MODPATH}${i}"
        chcon u:object_r:vendor_configs_file:s0 "${MODPATH}${i}"
        chown root:root "${MODPATH}${i}"
    fi
done

# If detecting DRC-enabled or Tensor SoC, then make a DRC-less or Tensor specifically tuned config file and overlay
#
# Set the active configuration file name retrieved from the audio policy server
configXML="`getActivePolicyFile`"

# configXML is usually placed under "/vendor/etc" (or "/vendor/etc/audio"), but
# "/my_product/etc" and "/odm/etc" are used on ColorOS (RealmeUI) and OxygenOS(?)
case "$configXML" in
    /vendor/etc/* | /my_product/etc/* | /odm/etc/* | /system/etc/* | /product/etc/* )
        MAGISKPATH="$(magisk --path)"
        if [ -n "$MAGISKPATH"  -a  -r "$MAGISKPATH/.magisk/mirror${configXML}" ]; then
            # Don't use "$MAGISKPATH/.magisk/mirror/system${configXML}" instead of "$MAGISKPATH/.magisk/mirror${configXML}".
            # In some cases, the former may link to overlaied "${configXML}" by Magisk itself (not original mirrored "${configXML}".
            mirrorConfigXML="$MAGISKPATH/.magisk/mirror${configXML}"
        else
            mirrorConfigXML="$configXML"
        fi
        mirrorConfigXML="`getActualConfigXML \"${mirrorConfigXML}\"`"
        case "${configXML}" in
            /system/* )
                configXML="${configXML#/system}"
            ;;
        esac
        modConfigXML="$MODPATH/system${configXML}"
        
        # If DRC enabled, modify audio policy configuration to stopt DRC
        grep -e "speaker_drc_enabled[[:space:]]*=[[:space:]]*\"true\"" $mirrorConfigXML >"/dev/null" 2>&1
        if [ "$?" -eq 0 ]; then
            drcFlag=1
        else
            drcFlag=0
        fi
        case "`getprop ro.board.platform`" in
            gs* )
                tensorFlag=1
                ;;
            * )
                tensorFlag=0
                ;;
        esac
        
        if [ "$drcFlag" -eq 1  -o  "$tensorFlag" -eq 1 ]; then
            mkdir -p "${modConfigXML%/*}"
            touch "$modConfigXML"
            if [ "$drcFlag" -eq 1 ]; then
                stopDRC "$mirrorConfigXML" "$modConfigXML"
            else
                DRC_enabled="false"
                USB_module="usbv2"
                BT_module="bluetooth"
                sRate="96000"
                aFormat="AUDIO_FORMAT_PCM_32_BIT"
                sed -e "s/%DRC_ENABLED%/$DRC_enabled/" -e "s/%USB_MODULE%/$USB_module/" -e "s/%BT_MODULE%/$BT_module/" \
                    -e "s/%SAMPLING_RATE%/$sRate/" -e "s/%AUDIO_FORMAT%/$aFormat/" \
                        "$MODPATH/templates/bypass_offload_safer_tensor_template.xml" >"$modConfigXML"
            fi
            chmod 644 "$modConfigXML"
            chcon u:object_r:vendor_configs_file:s0 "$modConfigXML"
            chown root:root "$modConfigXML"
            chmod -R a+rX "${modConfigXML%/*}"
            REPLACE="/system${configXML} $REPLACE"
        fi
        ;;
    * )
        ;;
esac

# making patched ALSA utility libraries for "ro.audio.usb.period_us"
makeLibraries

# removing post-A13 (especially Tensor's) spatial audio flags in an audio configuration file for avoiding errors
deSpatializeAudioPolicyConfig "/vendor/etc/bluetooth_audio_policy_configuration_7_0.xml"

# disabling pre-installed Moto Dolby faetures and Wellbeing for reducing very large jitter caused by them
disablePrivApps "
/system_ext/priv-app/MotoDolbyDax3
/system_ext/priv-app/MotorolaSettingsProvider
/system_ext/priv-app/daxService
/system_ext/priv-app/DaxUI
/system_ext/app/MotoSignatureApp
/product/priv-app/WellbeingPrebuilt
/product/priv-app/Wellbeing
/system_ext/priv-app/WellbeingPrebuilt
/system_ext/priv-app/Wellbeing
"

if "$IS64BIT"; then
    board="`getprop ro.board.platform`"
    case "$board" in
        "kona" | "kalama" | "shima" | "yupik" )
            replaceSystemProps_Kona
            ;;
        "sdm845" | gs* )
            replaceSystemProps_SDM845
            ;;
        "sdm660" | "bengal" | "holi" )
            replaceSystemProps_SDM
            ;;
        mt68* )
            replaceSystemProps_MTK_Dimensity
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

rm -f "$MODPATH/customize-functions.sh"
