#!/system/bin/sh

# MODDIR=${0%/*} will be nherited from the parent sh module

# This script functions will be used in services mode

. "$MODDIR/jitter-reducer-functions.shlib"

# Disable thermal core control, Camera service (interfering in jitters on audio outputs), Selinux enforcing and Doze (battery optimizations) 
#   or not, respectively ("yes" or "no")

# Set default values for safety reasons
DefaultDisableThermalControl="no"
DefaultDisableCameraService="no"
DefaultDisableSelinuxEnforcing="no"
DefaultDisableDoze="no"
DefaultDisableLogdService="no"

function disableAdaptiveFeatures()
{
    # Reducing jitter by battery draining manager and 5G data manager
    settings put global adaptive_battery_management_enabled 0
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
        resetprop ro.audio.ignore_effects true
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
        
        if [ -n "`getprop init.svc.audioserver`" ]; then
            setprop ctl.restart audioserver
            sleep 1.2
            if [ "`getprop init.svc.audioserver`" != "running" ]; then
                # workaround for Android 12 old devices hanging up the audioserver after "setprop ctl.restart audioserver" is executed
                local pid="`getprop init.svc_debug_pid.audioserver`"
                if [ -n "$pid" ]; then
                    kill -HUP $pid 1>"/dev/null" 2>&1
                fi
            fi
        fi
    fi
}

# This function has usually four arguments
function optimizeOS()
{
    local a1=$DefaultDisableThermalControl
    local a2=$DefaultDisableCameraService
    local a3=$DefaultDisableSelinuxEnforcing
    local a4=$DefaultDisableDoze
    local a5=$DefaultDisableLogdService
  
    case $# in
        0 )
            ;;
        1 )
            a1=$1
            ;;
        2 )
            a1=$1
            a2=$2
            ;;
        3 )
            a1=$1
            a2=$2
            a3=$3
            ;;
        4 )
            a1=$1
            a2=$2
            a3=$3
            a4=$4
            ;;
        5 )
            a1=$1
            a2=$2
            a3=$3
            a4=$4
            a5=$5
            ;;
        * )
            exit 1
            ;;
    esac

    # wait for system boot completion and audiosever boot up
    local i
    for i in `seq 1 30` ; do
        if [ "`getprop sys.boot_completed`" = "1"  -a  -n "`getprop init.svc.audioserver`" ]; then
            break
        fi
        sleep 0.9
    done

    if [ "$a1" = "yes" ]; then
        reduceThermalJitter 1 0
    fi
    if [ "$a2" = "yes" ]; then
        reduceCameraJitter 1 0
    fi
    if [ "$a3" = "yes" ]; then
        reduceSelinuxJitter 1 0
    fi
    if [ "$a4" = "yes" ]; then
        reduceDozeJitter 1 0
    fi
    if [ "$a5" = "yes" ]; then
        reduceLogdJitter 1 0
    fi
    reduceGovernorJitter 1 0
    reduceIoJitter 1 '*' 'boost' 0
    reduceVmJitter 1 0
    forceIgnoreAudioEffects
    disableAdaptiveFeatures
    setVolumeMediaSteps
}
