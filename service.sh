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

# Disable thermal control, Camera service (interfering in jitters on audio outputs), Selinux enforcing, Doze (battery optimizations)
# and Logd service or not, respectively ("yes" or "no").
# If DisableSelinuxEnforcing="yes", the USB HAL driver (not hardware offloading driver) only on Android 12 and later except MTK SoC devices
# cannot set the best USB transfer period specified by "ro.audio.usb.period_us" property because of its SELinux rule.

DisableThermalControl="yes"
DisableCameraService="yes"
DisableSelinuxEnforcing="yes"
DisableDoze="yes"
DisableLogdService="yes"

# sleep 30 secs needed for "settings" commans to become effective and another kernel tunables setting process completion in an orphan process

(((sleep 30; optimizeOS $DisableThermalControl $DisableCameraService $DisableSelinuxEnforcing $DisableDoze $DisableLogdService)  0<&- &>"/dev/null" &) &)
