#!/system/bin/sh
# Do NOT assume where your module will be located. ALWAYS use $MODDIR if you need to know where this script and module is placed.
# This will make sure your module will still work if Magisk change its mount point in the future
# no longer assume "$MAGISKTMP=/sbin/.magisk" if Android 11 or later
#

MODDIR=${0%/*}
# MAGISKPATH=$(magisk --path)
# MAGISKTMP=$MAGISKPATH/.magisk

function enableAdaptiveFeatures()
{
    # Enable adaptive fearure for battery savers
    settings delete global adaptive_battery_management_enabled
    settings delete secure adaptive_charging_enabled
    settings delete secure adaptive_connectivity_enabled
    settings delete global wifi_suspend_optimizations_enabled
}

function unsetVolumeMediaSteps()
{
    # Delete volume media steps key
    settings delete system volume_steps_music
}

#

# sleep 20 secs needed for settings commans to be effective in an orphan process

(((sleep 20; enableAdaptiveFeatures; unsetVolumeMediaSteps) 0<&- &>"/dev/null" &) &)
