#!/system/bin/sh

# MODDIR=${0%/*} will be inherited from the parent sh module

# This script functions will be used in services mode

. "$MODDIR/jitter-reducer-functions.shlib"

function disableAdaptiveFeatures()
{
    # Reducing jitter by battery draining and charging manager, and 5G data manager
    settings put global adaptive_battery_management_enabled 0
    settings put secure adaptive_charging_enabled 0
    settings put secure adaptive_connectivity_enabled 0
    # Reducing wifi jitter by suspend wifi optimizations
    settings put global wifi_suspend_optimizations_enabled 0
}

function setVolumeMediaSteps()
{
    # Volume medial steps to be 100 if a volume steps facility is used
    settings put system volume_steps_music 100
}

function forceIgnoreAudioEffects()
{
    local force_restart_server=0

    if [ "`getprop persist.sys.phh.disable_audio_effects`" = "0" ]; then
        # Workaround for recent Pixel Firmwares (not to reboot when resetprop'ing)
        resetprop --delete ro.audio.ignore_effects 1>"/dev/null" 2>&1
        # End of workaround
        resetprop ro.audio.ignore_effects true
        force_restart_server=1
    fi
    
    # Stop Tensor device's AOC daemon for reducing significant jitter
    if [ "`getprop init.svc.aocd`" = "running" ]; then
        setprop ctl.stop aocd
        force_restart_server=1
    fi
    
    # Nullifying the volume listener for no compressing audio (maybe a peak limiter)
    if [ "`getprop persist.sys.phh.disable_soundvolume_effect`" = "0" ]; then
        if [ -r "/system/phh/empty"  -a  -r "/vendor/lib/soundfx/libvolumelistener.so" ]; then
            mount -o bind "/system/phh/empty" "/vendor/lib/soundfx/libvolumelistener.so"
            force_restart_server=1
        fi
        if [ -r "/system/phh/empty"  -a  -r "/vendor/lib64/soundfx/libvolumelistener.so" ]; then
            mount -o bind "/system/phh/empty" "/vendor/lib64/soundfx/libvolumelistener.so"
            force_restart_server=1
        fi
        
    elif [ "`getprop persist.sys.phh.disable_soundvolume_effect`" != "1" ]; then
        # for non- phh GSI's (Qcomm devices only?)
        if [ -r "/vendor/lib/soundfx/libvolumelistener.so" ]; then
            mount -o bind "/dev/null" "/vendor/lib/soundfx/libvolumelistener.so"
            force_restart_server=1
        fi
        if [ -r "/vendor/lib64/soundfx/libvolumelistener.so" ]; then
            mount -o bind "/dev/null" "/vendor/lib64/soundfx/libvolumelistener.so"
            force_restart_server=1
        fi
        
    fi
     
    if [ "$force_restart_server" = "1"  -o  "`getprop ro.system.build.version.release`" -ge "12" ]; then
        reloadAudioServer       
    fi
}

# This function has six arguments:
# 1. Enable $1:thermal core control, $2:Camera service (interfering in jitters on audio outputs), $3:Selinux enforcing, $4:Doze (battery optimizations)
#     and $5:Logd service or not, respectively ("yes" or "no")
# 2. Disable $6:clearest tone ("yes" or "no"), perhaps for sensitive Bluetooth earphones.

function optimizeOS()
{  
    if [ $# -neq 6 ]; then
        exit 1
    fi

    if [ "$1" = "no" ]; then
        reduceThermalJitter 1 0
    fi
    if [ "$2" = "no" ]; then
        reduceCameraJitter 1 0
    fi
    if [ "$3" = "no" ]; then
        reduceSelinuxJitter 1 0
    fi
    if [ "$4" = "no" ]; then
        reduceDozeJitter 1 0
    fi
    if [ "$5" = "no" ]; then
        reduceLogdJitter 1 0
    fi
    reduceGovernorJitter 1 0
    if [ "$6" = "no" ]; then
        reduceIoJitter 1 '*' 'boost' 0
    else
        reduceIoJitter 1 '*' 'medium' 0
    fi
    reduceVmJitter 1 0
    forceIgnoreAudioEffects
    disableAdaptiveFeatures
    setVolumeMediaSteps
}
