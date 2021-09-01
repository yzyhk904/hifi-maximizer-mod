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

. "$MODDIR/functions.sh"

#

# Disable thermal core control, Camera service (interfering in jitters on audio outputs) and Selinux enforcing or not, respectively ("yes" or "no")
DisableThermalCoreControl="yes"
DisableCameraService="yes"
DisableSelinuxEnforcing="yes"

# sleep 30 secs needed for "settings" commans to become effective and another kernel tunables setting process completion in an orphan process

(((sleep 30; optimizeOS $DisableThermalCoreControl $DisableCameraService $DisableSelinuxEnforcing)  0<&- &>"/dev/null" &) &)
