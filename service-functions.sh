#!/system/bin/sh

# MODDIR=${0%/*} will be nherited from the parent sh module

# This script functions will be used in services mode

. "$MODDIR/jitter-reducer-functions.shlib"

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
        reloadAudioServer       
    fi
}

# This function has six arguments:
# 1. Disable $1:thermal core control, $2:Camera service (interfering in jitters on audio outputs), $3:Selinux enforcing, $4:Doze (battery optimizations)
#     and $5:Logd service or not, respectively ("yes" or "no")
# 2. Disable $6:clearest tone ("yes" or "no"), perhaps for sensitive Bluetooth earphones.

function optimizeOS()
{  
    if [ $# -neq 6 ]; then
        exit 1
    fi

    # wait for system boot completion and audiosever boot up
    local i
    for i in `seq 1 30` ; do
        if [ "`getprop sys.boot_completed`" = "1"  -a  -n "`getprop init.svc.audioserver`" ]; then
            break
        fi
        sleep 0.9
    done

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

# Get the active audio policy configuration fille from the audioserever

function getActivePolicyFile()
{
    dumpsys media.audio_policy | awk ' 
        /^ Config source: / {
            print $3
        }' 
}

function remountFile()
{
    local configXML
    
    # Set the active configuration file name retrieved from the audio policy server
    configXML="`getActivePolicyFile`"

    # Check if the audio policy XML file mounted by Magisk is still unmounted.
    # Some Qcomm devices from Xiaomi, OnePlus, etc. overlays another on it in a boot process
    # and phh GSI on Qcomm devices unmount it
    
    if [ -r "$configXML"  -a  -r "${MODDIR}/system${configXML}" ]; then
        cmp "$configXML" "${MODDIR}/system${configXML}" >"/dev/null" 2>&1
        if [ "$?" -ne 0 ]; then
            umount "$configXML" >"/dev/null" 2>&1
            umount "$configXML" >"/dev/null" 2>&1
            mount -o bind "${MODDIR}/system${configXML}" "$configXML"
            reloadAudioServer
        fi
    fi
}
