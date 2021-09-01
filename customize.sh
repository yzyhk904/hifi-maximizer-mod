#!/system/bin/sh

# Replace audio policy configuration files (default)
  REPLACE="
/system/vendor/etc/audio_effects.xml
/system/vendor/etc/r_submix_audio_policy_configuration.xml
/system/vendor/etc/usb_audio_policy_configuration.xml
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

# In case of phh GSI, overlay "/system/etc/usb_audio_policy_configuration.xml"
  if [ -e "/system/etc/usb_audio_policy_configuration.xml" ]; then
      if [ ! -e "$MODPATH/system/etc" ]; then
        mkdir "$MODPATH/system/etc"
        cp "$MODPATH/system/vendor/etc/usb_audio_policy_configuration.xml" "$MODPATH/system/etc/usb_audio_policy_configuration.xml"
        chmod a+rx "$MODPATH/system/etc"
        chmod 644 "$MODPATH/system/etc/usb_audio_policy_configuration.xml"
      fi
      REPLACE="$REPLACE /system/etc/usb_audio_policy_configuration.xml"
  fi
