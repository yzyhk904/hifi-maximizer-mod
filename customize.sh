#!/system/bin/sh

[ -z "$(magisk --path)" ] && alias magisk='ksu-magisk'

. "$MODPATH/customize-functions.sh"

if ! isMagiskMountCompatible; then
    abort '  ***
  Aborted by no Magisk-mirrors:
    try again either
      a.) with official Magisk (mounting mirrors), or
      b.) after installing "Compatible Magisk-mirroring" Magisk module and rebooting
  ***'
fi

MAGISKTMP="$(magisk --path)/.magisk"

# Note: Don't use "${MAGISKTMP}/mirror/system/vendor/*" instaed of "${MAGISKTMP}/mirror/vendor/*".
# In some cases, the former may link to overlaied "/system/vendor" by Magisk itself (not mirrored original one).

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

# Check if on a Tensor device or not
case "`getprop ro.board.platform`" in
    gs* )
        tensorFlag=1
        ;;
    * )
        tensorFlag=0
        ;;
esac

if [ "$tensorFlag" -eq 1 ]; then
    # Unlocks the limiter of Tensor device's USB offload driver from 96kHz to 192kHz
    fname="/system/vendor/etc/audio_platform_configuration.xml"
    if [ -r "$fname" ]; then
        mkdir -p "${MODPATH}${fname%/*}"
        sed -e 's/min_rate="[1-9][0-9]*"/min_rate="44100"/g' \
            -e 's/"MaxSamplingRate=[1-9][0-9]*,/"MaxSamplingRate=192000,/' \
                <"${MAGISKTMP}/mirror${fname#/system}" >"${MODPATH}${fname}"
        touch "${MODPATH}${fname}"
        chmod 644 "${MODPATH}${fname}"
        chcon u:object_r:vendor_configs_file:s0 "${MODPATH}${fname}"
        chown root:root "${MODPATH}${fname}"
        chmod -R a+rX "${MODPATH}${fname%/*}"
        if [ -z "${REPLACE}" ]; then
            REPLACE="${fname}"
        else
            REPLACE="${REPLACE} ${fname}"
        fi
    fi
    
fi

# If detecting DRC-enabled or Tensor SoC, then make a DRC-less or Tensor specifically tuned config file and overlay
#
# Set the active configuration file name retrieved from the audio policy server
configXML="`getActivePolicyFile`"

# configXML is usually placed under "/vendor/etc" (or "/vendor/etc/audio"), but
# "/my_product/etc" and "/odm/etc" are used on ColorOS (RealmeUI) and OxygenOS(?)
case "$configXML" in
    /vendor/etc/* | /my_product/etc/* | /odm/etc/* | /system/etc/* | /product/etc/* )
        if [ -n "$MAGISKTMP"  -a  -r "${MAGISKTMP}/mirror${configXML}" ]; then
            mirrorConfigXML="${MAGISKTMP}/mirror${configXML}"
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
        
        if [ "$drcFlag" -eq 1  -o  "$tensorFlag" -eq 1 ]; then
            mkdir -p "${modConfigXML%/*}"
            touch "$modConfigXML"
            if [ "$drcFlag" -eq 1 ]; then
                stopDRC "$mirrorConfigXML" "$modConfigXML"
            else
                DRC_enabled="false"
                USB_module="usbv2"
                BT_module="bluetooth"
                sRate="192000"
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
            
            # If "${configXML}" isn't symbolically linked to "$/system/{configXML}", 
            #   disable Magisk's "magic mount" and mount "${configXML}" by this module itself in "service.sh"
            if [ ! -e "/system${configXML}" ]; then
                touch "$MODPATH/skip_mount"
            fi
        fi
        ;;
    * )
        ;;
esac

# Make patched ALSA utility libraries for "ro.audio.usb.period_us"
makeLibraries

# Remove post-A13 (especially Tensor's) spatial audio flags in an audio configuration file for avoiding errors
deSpatializeAudioPolicyConfig "/vendor/etc/bluetooth_audio_policy_configuration_7_0.xml"

# Disabe pre-installed Moto Dolby faetures and Wellbeing for reducing very large jitter caused by them
#   Excluded "MotorolaSettingsProvider" on Motorala devices for avoiding bootloop
if [ "`getprop ro.product.manufacturer`" = "Motorola" ]; then
    disablePrivApps "
/system_ext/priv-app/MotoDolbyDax3
/system_ext/priv-app/daxService
/system_ext/priv-app/DaxUI
/system_ext/app/MotoSignatureApp
/product/priv-app/WellbeingPrebuilt
/product/priv-app/Wellbeing
/system_ext/priv-app/WellbeingPrebuilt
/system_ext/priv-app/Wellbeing
"
else
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
fi

if "$IS64BIT"; then
    board="`getprop ro.board.platform`"
    case "$board" in
        "kona" | "kalama" | "shima" | "yupik" )
            replaceSystemProps_Kona
            ;;
        "sdm845" )
            replaceSystemProps_SDM845
            ;;
        gs* | "zuma" )
            replaceSystemProps_Tensor
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

# Warning unneeded magisk modules

if [ -e "${MODPATH%/*/*}/modules/audio-misc-settings" ]; then
    ui_print ""
    ui_print "****************************************************************"
    ui_print " Uninstall \"Audio misc. settings\" manually later; this module includes all its features"
    ui_print "****************************************************************"
    ui_print ""
fi
if [ -e "${MODPATH%/*/*}/modules/drc-remover" ]; then
    ui_print ""
    ui_print "****************************************************************"
    ui_print " Uninstall \"DRC remover\" manually later; this module includes all its features"
    ui_print "****************************************************************"
    ui_print ""
fi
if [ "$tensorFlag" -eq 1  -a  -e "${MODPATH%/*/*}/modules/usb-samplerate-unlocker" ]; then
    ui_print ""
    ui_print "****************************************************************"
    ui_print " Uninstall \"USB Samplerate Unlocker\" manually later; this module includes all its features"
    ui_print "****************************************************************"
    ui_print ""
fi
 
rm -f "$MODPATH/customize-functions.sh" "$MODPATH/LICENSE" "$MODPATH/README.md" "$MODPATH/changelog.md"
rm -rf "$MODPATH/templates"
