#!/system/bin/sh

# This script functions will be used in customize.sh, post-fs-data mode, services mode and uninstall mode
#

# Get the active audio policy configuration fille from the audioserever
function getActivePolicyFile()
{
    dumpsys media.audio_policy | awk ' 
        /^ Config source: / {
            print $3
        }' 
}

function stopDRC()
{
    # stopDRC has two args specifying a main audio policy configuration XML file (eg. audio_policy_configuration.xml) and its dummy one to be overridden

     if [ $# -eq 2  -a  -r "$1"  -a  -w "$2" ]; then
        # Copy and override an original audio_policy_configuration.xml to its dummy file
        cp -f "$1" "$2"
        # Change audio_policy_configuration.xml file to remove DRC
        sed -i 's/speaker_drc_enabled[:space:]*=[:space:]*"true"/speaker_drc_enabled="false"/' "$2"
    fi
}

function unsetHifiNetwork()
{
    # Delete wifi optimizations
    settings delete global wifi_suspend_optimizations_enabled
}

function unsetVolumeMediaSteps()
{
    # Delete volume media steps key
    settings delete system volume_steps_music
}

function stopEnforcing()
{
    # Change SELinux enforcing mode to permissive mode
    setenforce 0
}

function stopDoze()
{
    # Disabl Doze of a device at all
    dumpsys deviceidle disable all 1>"/dev/null" 2>&1
}

function stopThermalControl()
{
    # Stop thermal core control
    if [ -w "/sys/module/msm_thermal/core_control/enabled" ]; then
        echo '0' > "/sys/module/msm_thermal/core_control/enabled"
    fi
    if [ -r "/sys/devices/system/cpu/cpu0/core_ctl/enable" ]; then
        local i st en
        IFS="-" read st en <"/sys/devices/system/cpu/present"
        if [ -n "$st"  -a  -n "$en"  -a "$st" -ge 0  -a  "$en" -ge 0 ]; then
            if [ -w "/sys/devices/system/cpu/cpu7/core_ctl/enable" ]; then
                # SD850 or higher type core control
                echo '1'  > "/sys/devices/system/cpu/cpu7/core_ctl/enable"
                echo '1'  > "/sys/devices/system/cpu/cpu7/core_ctl/min_cpus"
                echo '0'  > "/sys/devices/system/cpu/cpu7/core_ctl/enable"
                if [ -w "/sys/devices/system/cpu/cpu4/core_ctl/enable" ]; then
                    echo '1'  > "/sys/devices/system/cpu/cpu4/core_ctl/enable"
                    echo '3'  > "/sys/devices/system/cpu/cpu4/core_ctl/min_cpus"
                    echo '0'  > "/sys/devices/system/cpu/cpu4/core_ctl/enable"
                fi
                if [ -w "/sys/devices/system/cpu/cpu0/core_ctl/enable" ]; then
                    echo '1'  > "/sys/devices/system/cpu/cpu0/core_ctl/enable"
                    echo '4'  > "/sys/devices/system/cpu/cpu0/core_ctl/min_cpus"
                    echo '0'  > "/sys/devices/system/cpu/cpu0/core_ctl/enable"
                fi
            elif [ -w "/sys/devices/system/cpu/cpu4/core_ctl/enable" ]; then
                # SD840 or lower type core control
                echo '1'  > "/sys/devices/system/cpu/cpu4/core_ctl/enable"
                echo '4'  > "/sys/devices/system/cpu/cpu4/core_ctl/min_cpus"
                echo '0'  > "/sys/devices/system/cpu/cpu4/core_ctl/enable"
                if [ -w "/sys/devices/system/cpu/cpu0/core_ctl/enable" ]; then
                    echo '1'  > "/sys/devices/system/cpu/cpu0/core_ctl/enable"
                    echo '4'  > "/sys/devices/system/cpu/cpu0/core_ctl/min_cpus"
                    echo '0'  > "/sys/devices/system/cpu/cpu0/core_ctl/enable"
                fi
            elif [ -w "/sys/devices/system/cpu/cpu0/core_ctl/enable" ]; then
                # unknown type core control
                echo '1'  > "/sys/devices/system/cpu/cpu0/core_ctl/enable"
                echo '4'  > "/sys/devices/system/cpu/cpu0/core_ctl/min_cpus"
                echo '0'  > "/sys/devices/system/cpu/cpu0/core_ctl/enable"
            fi
        fi
    fi
    # Stop the MPDecision (CPU hotplug)
    if [ "`getprop init.svc.mpdecision`" = "running" ]; then
        setprop ctl.stop mpdecision
        forceOnlineCPUs
    elif [ "`getprop init.svc.vendor.mpdecision`" = "running" ]; then
        setprop ctl.stop vendor.mpdecision
        forceOnlineCPUs
    fi
    # Stop the thermal server
    if [ "`getprop init.svc.thermal`" = "running" ]; then
        setprop ctl.stop thermal
    elif [ "`getprop init.svc.vendor.thermal`" = "running" ]; then
        setprop ctl.stop vendor.thermal
    fi
    # Stop the mi_thermald server
    if [ "`getprop init.svc.mi_thermald`" = "running" ]; then
        setprop ctl.stop mi_thermald
    elif [ "`getprop init.svc.vendor.mi_thermald`" = "running" ]; then
        setprop ctl.stop vendor.mi_thermald
    fi
    # Stop the thermal-engine server
    if [ "`getprop init.svc.thermal-engine`" = "running" ]; then
        setprop ctl.stop thermal-engine
    elif [ "`getprop init.svc.vendor.thermal-engine`" = "running" ]; then
        setprop ctl.stop vendor.thermal-engine
    fi
    # For MediaTek CPU's
    if [ -w "/proc/cpufreq/cpufreq_sched_disable" ]; then
        echo '1' > "/proc/cpufreq/cpufreq_sched_disable"
        forceOnlineCPUs
    fi
}

function stopCameraService()
{
    # Stop the camera servers
    if [ "`getprop init.svc.qcamerasvr`" = "running" ]; then
        setprop ctl.stop qcamerasvr
    fi
    if [ "`getprop init.svc.vendor.qcamerasvr`" = "running" ]; then
        setprop ctl.stop vendor.qcamerasvr
    fi
    if [ "`getprop init.svc.cameraserver`" = "running" ]; then
        setprop ctl.stop cameraserver
    fi
    if [ "`getprop init.svc.camerasloganserver`" = "running" ]; then
        setprop ctl.stop camerasloganserver
    fi
    if [ "`getprop init.svc.camerahalserver`" = "running" ]; then
        setprop ctl.stop camerahalserver
    fi
}

function setHifiNetwork()
{
    # Reducing wifi jitter by suspend wifi optimizations
    settings put global wifi_suspend_optimizations_enabled 0
}

function setVolumeMediaSteps()
{
    # Volume medial steps to be 100 if a volume steps facility is used
    settings put system volume_steps_music 100
}

function which_resetprop_command()
{
    type resetprop 1>"/dev/null" 2>&1
    if [ $? -eq 0 ]; then
        echo "resetprop"
    else
        type resetprop_phh 1>"/dev/null" 2>&1
        if [ $? -eq 0 ]; then
            echo "resetprop_phh"
        else
            return 1
        fi
    fi
    return 0
}

function forceIgnoreAudioEffects()
{
    if [ "`getprop persist.sys.phh.disable_audio_effects`" = "0" ]; then
        local resetprop_command="`which_resetprop_command`"
        if [ -n "$resetprop_command" ]; then
            "$resetprop_command" ro.audio.ignore_effects true
        else
            return 1
        fi
        
        if [ -n "`getprop init.svc.audioserver`" ]; then
            setprop ctl.restart audioserver
            sleep 1.2
            if [ "`getprop init.svc.audioserver`" != "running" ]; then
                # workaround for Android 12 old devices hanging up the audioserver after "setprop ctl.restart audioserver" is executed
                local pid="`getprop init.svc_debug_pid.audioserver`"
                if [ -n "$pid" ]; then
                    kill -HUP $pid 1>&2
                fi
            fi
        fi
        
    elif [ "`getprop ro.system.build.version.release`" -ge "12" ]; then
        
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

# choose the best I/O scheduler for very Hifi audio outputs, and output it into the standard output
function chooseBestIOScheduler() 
{
    if [ $# -eq 1  -a  -r "$1" ]; then
        local  x  scheds  ret_val=""
  
        scheds="`tr -d '[]' <\"$1\"`"
        for x in $scheds; do
            case "$x" in
                "deadline" ) ret_val="deadline"; break ;;
                "cfq" ) ret_val="cfq" ;;
                "noop" ) if [ "$ret_val" != "cfq" ]; then ret_val="noop"; fi ;;
                * ) ;;
            esac
        done
        echo "$ret_val"
        return 0
    else
        return 1
    fi
}

function getSocModelName()
{
    local modelName="`getprop ro.board.platform`"
    case "$modelName" in
            sd* | msm* | exynos* | mt* )
                echo "$modelName"
                return 0
                ;;
            * )
                case "`getprop ro.boot.hardware`" in
                    qcom )
                        # High performance Qcomm SoC devices tend to have code names
                        case "$modelName" in
                            "kona" )
                                echo "sdm870"
                                ;;
                            * )
                                 if [ -r "/sys/devices/system/cpu/cpu7/core_ctl/enable" ]; then
                                    echo "sdm855"
                                 else
                                    echo "sdm845"
                                 fi
                                ;;
                        esac
                        return 0
                        ;;
                    * )
                        echo "unknown"
                        return 0
                        ;;
                esac
                ;;
    esac
    
    return 1
}

function getMtkGpuFreqKhz()
{
    local isMax="0"
    
    if [ $# -eq 1  -a  "$1" = "max" ]; then
        isMax="1"
    fi
    
    if [ -r "/proc/gpufreq/gpufreq_opp_dump" ]; then
        local x1 x2 x3 x4 x5 freq="" IFS=" ,"
        
        if [ "$isMax" -eq 1 ]; then
            read x1 x2 x3 x4 x5 <"/proc/gpufreq/gpufreq_opp_dump"
            freq="$x4"
        else
            while read x1 x2 x3 x4 x5; do
                freq="$x4"
            done <"/proc/gpufreq/gpufreq_opp_dump"
        fi
        
        if [ -n "$freq" ]; then
            echo "$freq"
            return 0
        else
            return 1
        fi
        
    else
        return 1
    fi
}

function setKernelTunables()
{
    local  i  sched

    # Set kernel tuables for CPU&GPU govenors, I/O scheduler, and Virtual memory
  
    # CPU governor
    # prevent CPU offline stuck by forcing online between double  governor writing 
    for i in `seq 0 9`; do
        if [ -e "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor" ]; then
            chmod 644 "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor"
            echo 'performance' >"/sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor"
            chmod 644 "/sys/devices/system/cpu/cpu$i/online"
            echo '1' >"/sys/devices/system/cpu/cpu$i/online"
            echo 'performance' >"/sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor"
        fi
    done
    
    # GPU governor
    if [ -w "/sys/class/kgsl/kgsl-3d0/pwrscale/trustzone/governor" ]; then
        # For old Qcomm GPU's
        echo 'performance' >"/sys/class/kgsl/kgsl-3d0/pwrscale/trustzone/governor"
        if [ -w "/sys/class/kgsl/kgsl-3d0/min_pwrlevel" ]; then
            # Set the min power level to be maximum
            echo "0" >"/sys/class/kgsl/kgsl-3d0/min_pwrlevel"
        fi
    elif [ -w "/sys/class/kgsl/kgsl-3d0/devfreq/governor" ]; then
        # For Qcomm GPU's
        echo 'performance' >"/sys/class/kgsl/kgsl-3d0/devfreq/governor"
        if [ -w "/sys/class/kgsl/kgsl-3d0/min_pwrlevel" ]; then
            # Set the min power level to be maximum
            echo "0" >"/sys/class/kgsl/kgsl-3d0/min_pwrlevel"
        fi
        # For some Qcomm GPU's, because they revert the governor after setting min_pwrlevel
        echo 'performance' >"/sys/class/kgsl/kgsl-3d0/devfreq/governor"
    elif [ -w "/proc/gpufreq/gpufreq_opp_freq"  -a  -r "/proc/gpufreq/gpufreq_opp_dump" ]; then
        # Maximum fixed frequency setting for MediaTek GPU's
        local freq="`getMtkGpuFreqKhz \"max\"`"
        if [ -n "$freq" ]; then
            echo "$freq" >"/proc/gpufreq/gpufreq_opp_freq"
        fi
    fi
    
    # I/O scheduler
    for i in sda mmcblk0 mmcblk1; do
        if [ -d "/sys/block/$i/queue" ]; then
            echo '16384' >"/sys/block/$i/queue/read_ahead_kb"
            echo '0' >"/sys/block/$i/queue/iostats"
            echo '0' >"/sys/block/$i/queue/add_random"
            echo '2' >"/sys/block/$i/queue/rq_affinity"
            echo '2' >"/sys/block/$i/queue/nomerges"
    
            # Optimized for bluetooth audio and so on.
            sched="`chooseBestIOScheduler \"/sys/block/$i/queue/scheduler\"`"
            case "$sched" in
                "deadline" )
                    echo 'deadline' >"/sys/block/$i/queue/scheduler"
                    echo '0' >"/sys/block/$i/queue/iosched/front_merges"
                    echo '0' >"/sys/block/$i/queue/iosched/writes_starved"
                    case "`getSocModelName`" in
                        sdm8[5-9]* | sdm9* )
                            echo '58' >"/sys/block/$i/queue/iosched/fifo_batch"
                            echo '28' >"/sys/block/$i/queue/iosched/read_expire"
                            echo '512' >"/sys/block/$i/queue/iosched/write_expire"
                            echo '84578' >"/sys/block/$i/queue/nr_requests"
                            ;;
                        sdm8* )
                            echo '59' >"/sys/block/$i/queue/iosched/fifo_batch"
                            echo '26' >"/sys/block/$i/queue/iosched/read_expire"
                            echo '510' >"/sys/block/$i/queue/iosched/write_expire"
                            echo '84876' >"/sys/block/$i/queue/nr_requests"
                            ;;
                        sdm* | msm* | sd* | exynos* )
                            echo '58' >"/sys/block/$i/queue/iosched/fifo_batch"
                            echo '26' >"/sys/block/$i/queue/iosched/read_expire"
                            echo '513' >"/sys/block/$i/queue/iosched/write_expire"
                            echo '84875' >"/sys/block/$i/queue/nr_requests"
                            ;;
                        mt68* )
                            echo '57' >"/sys/block/$i/queue/iosched/fifo_batch"
                            echo '28' >"/sys/block/$i/queue/iosched/read_expire"
                            echo '508' >"/sys/block/$i/queue/iosched/write_expire"
                            echo '85838' >"/sys/block/$i/queue/nr_requests"
                            ;;
                        mt67[6-9]? )
                            echo '57' >"/sys/block/$i/queue/iosched/fifo_batch"
                            echo '28' >"/sys/block/$i/queue/iosched/read_expire"
                            echo '508' >"/sys/block/$i/queue/iosched/write_expire"
                            echo '84456' >"/sys/block/$i/queue/nr_requests"
                            ;;
                        mt* | * )
                            echo '57' >"/sys/block/$i/queue/iosched/fifo_batch"
                            echo '28' >"/sys/block/$i/queue/iosched/read_expire"
                            echo '508' >"/sys/block/$i/queue/iosched/write_expire"
                            echo '84456' >"/sys/block/$i/queue/nr_requests"
                            ;;
                    esac
                    ;;
                "cfq" )
                    echo 'cfq' >"/sys/block/$i/queue/scheduler"
                    echo '1' >"/sys/block/$i/queue/iosched/back_seek_penalty"
                    echo '3' >"/sys/block/$i/queue/iosched/fifo_expire_async"
                    echo '3' >"/sys/block/$i/queue/iosched/fifo_expire_sync"
                    echo '0' >"/sys/block/$i/queue/iosched/group_idle"
                    echo '1' >"/sys/block/$i/queue/iosched/low_latency"
                    echo '1' >"/sys/block/$i/queue/iosched/quantum"
                    echo '3' >"/sys/block/$i/queue/iosched/slice_async"
                    echo '34' >"/sys/block/$i/queue/iosched/slice_async_rq"
                    echo '0' >"/sys/block/$i/queue/iosched/slice_idle"
                    echo '3' >"/sys/block/$i/queue/iosched/slice_sync"
                    echo '3' >"/sys/block/$i/queue/iosched/target_latency"
                    case "`getSocModelName`" in
                        sdm* | msm* | sd* | exynos* )
                            echo '83587' >"/sys/block/$i/queue/nr_requests"
                            ;;
                        * )
                            echo '83587' >"/sys/block/$i/queue/nr_requests"
                            ;;
                    esac
                    ;;
                "noop" )
                    echo 'noop' >"/sys/block/$i/queue/scheduler"
                    case "`getSocModelName`" in
                        sdm* | msm* | sd* | exynos* )
                            echo '61675' >"/sys/block/$i/queue/nr_requests"
                            ;;
                        * )
                            echo '60915' >"/sys/block/$i/queue/nr_requests"
                            ;;
                    esac
                    ;;
                * )
                    #  an empty string or unknown I/O schedulers
                    ;;
            esac
        fi
    done
    
    # Virtual memory
    echo '0' >"/proc/sys/vm/swappiness"
    if [ -w "/proc/sys/vm/direct_swappiness" ]; then
        echo '0' >"/proc/sys/vm/direct_swappiness"
    fi
    echo '84' >"/proc/sys/vm/dirty_ratio"
    echo '97' >"/proc/sys/vm/dirty_background_ratio"
    echo '1201001' >"/proc/sys/vm/dirty_expire_centisecs"
    echo '221001' >"/proc/sys/vm/dirty_writeback_centisecs"
    echo '1' >"/proc/sys/vm/laptop_mode"
    if [ -w "/proc/sys/vm/swap_ratio" ]; then
        echo '0' >"/proc/sys/vm/swap_ratio"
    fi
    if [ -w "/proc/sys/vm/swap_ratio_enable" ]; then
        echo '1' >"/proc/sys/vm/swap_ratio_enable"
    fi

}

# Disable thermal core control, Camera service (interfering in jitters on audio outputs), Selinux enforcing and Doze (battery optimizations) 
#   or not, respectively ("yes" or "no")

# Set default values for safety reasons
DefaultDisableThermalControl="no"
DefaultDisableCameraService="no"
DefaultDisableSelinuxEnforcing="no"
DefaultDisableDoze="no"

# This function has usually four arguments
function optimizeOS()
{
    local a1=$DefaultDisableThermalControl
    local a2=$DefaultDisableCameraService
    local a3=$DefaultDisableSelinuxEnforcing
    local a4=$DefaultDisableDoze
  
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
        * )
            exit 1
            ;;
    esac

    if [ "$a1" = "yes" ]; then
        stopThermalControl
    fi
    if [ "$a2" = "yes" ]; then
        stopCameraService
    fi
    if [ "$a3" = "yes" ]; then
        stopEnforcing
    fi
    if [ "$a4" = "yes" ]; then
        stopDoze
    fi
    setKernelTunables
    setHifiNetwork
    setVolumeMediaSteps
    forceIgnoreAudioEffects
}
