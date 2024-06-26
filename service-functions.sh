#!/system/bin/sh

function reloadAudioServer()
{
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
}

# Sleep some secs needed for Audioserver's preparation
function waitAudioServer()
{
    # wait for system boot completion and audiosever boot up
    sleep 11
    local i
    for i in `seq 1 10` ; do
        if [ "`getprop sys.boot_completed`" = "1"  -a  -n "`getprop init.svc.audioserver`" ]; then
            break
        fi
        sleep $i
    done
}

# A rewritten version because some ROM's fail to execute "dumpsys media.audio_policy" on the service phase
#  arg1 : Magisk's module folder path, typically "/data/adb/modules/<module name>"
function remountFiles()
{
    local modPath flist x deletePat forceReload=0
    
    if [ $# -eq 1  -a  -e "$1" ]; then
        modPath="$1"
    else
        return
    fi
    
    deletePat=$(echo "${modPath}/system" | sed -e 's/\//\\\//g')
    
    # Get absolute paths for Magisk's magic mount, then remount by itself
    flist="`find \"${modPath}/system\" -type f | sed -e \"s/$deletePat//\"`"

    # Check if the audio policy XML file and others mounted by Magisk is still unmounted.
    # Some Qcomm devices from Xiaomi, OnePlus, etc. overlays another on it in a boot process
    # and phh GSI's on Qcomm devices unmount it for the phh settings of the GSI's.

    for x in $flist; do
        if [ -e "${modPath}/skip_mount"  -a  "${x##*/}" = ".replace" ]; then
            # Mount a directory instead of ".replace" file if skipping Magisk's magic mount
            mount -o bind "${modPath}/system${x%/.replace}" "${x%/.replace}"
            forceReload=1
        elif [ -r "$x"  -a  -r "${modPath}/system${x}" ]; then
            cmp "$x" "${modPath}/system${x}" >"/dev/null" 2>&1
            if [ "$?" -ne 0 ]; then
                umount "$x" >"/dev/null" 2>&1
                umount "$x" >"/dev/null" 2>&1
                mount -o bind "${modPath}/system${x}" "$x"
                forceReload=1
            fi
        fi
    done
    
    if [ "$forceReload" -gt 0 ]; then
        # Since this library file may be shared multiple modules, it is needed to disperse the timing of each module not to collide
        sleep $(expr $RANDOM % 20)
        reloadAudioServer
    fi
}
