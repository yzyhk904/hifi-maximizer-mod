#!/system/bin/sh
# Do NOT assume where your module will be located. ALWAYS use $MODDIR if you need to know where this script and module is placed.
# This will make sure your module will still work if Magisk change its mount point in the future
# no longer assume "$MAGISKTMP=/sbin/.magisk" if Android 11 or later
#
# This script will be executed in service mode
#

MODDIR=${0%/*}
# MAGISKPATH=$(magisk --path)
# MAGISKTMP=$MAGISKPATH/.magisk

. "$MODDIR/service-functions.sh"
. "$MODDIR/service-optimizer.sh"

#

# 1. Enable thermal control, Camera service (interfering in jitters on audio outputs), Selinux enforcing, Doze (battery optimizations)
#     and Logd service or not, respectively ("yes" or "no").
# 2. Disable clearest tone ("yes" or "no"), perhaps for sensitive Bluetooth earphones.

EnableThermalControl="no"
EnableCameraService="no"
EnableSelinuxEnforcing="no"
EnableDoze="no"
EnableLogdService="no"

DisableClearestTone="no"

# sleep more than 30 secs (waitAudioServer) needed for "settings" commans 
#   to become effective and another kernel tunables setting process completion in an orphan process

(((waitAudioServer; remountFile "$MODDIR"; optimizeOS $EnableThermalControl $EnableCameraService $EnableSelinuxEnforcing \
                        $EnableDoze $EnableLogdService $DisableClearestTone)  0<&- &>"/dev/null" &) &)
