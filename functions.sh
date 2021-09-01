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

  # Stop higher bitrate (approx. 600kbps) for bluetooth SBC HD codec when conneted to bluetooth EDR 2Mbps devices
#  resetprop -p --delete persist.bluetooth.sbc_hd_higher_bitrate
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

function stopMPDecision()
{
  # Stop the MPDecision (CPU hotplug)
  if [ "`getprop init.svc.mpdecision`" = "running" ]; then
    setprop ctl.stop mpdecision
    stop mpdecision
  elif [ "`getprop init.svc.vendor.mpdecision`" = "running" ]; then
    setprop ctl.stop vendor.mpdecision
    stop vendor.mpdecision
  fi
}

function stopThermalCoreControl()
{
  # Stop the thermal core control
  if [ -w "/sys/module/msm_thermal/core_control/enabled" ]; then
    echo '0' >"/sys/module/msm_thermal/core_control/enabled"
  fi
}

function stopCameraService()
{
  # Stop the camera servers
  if [ "`getprop init.svc.qcamerasvr`" = "running" ]; then
    setprop ctl.stop qcamerasvr}
    stop qcamerasvr
  fi
  if [ "`getprop init.svc.vendor.qcamerasvr`" = "running" ]; then
    setprop ctl.stop vendor.qcamerasvr}
    stop vendor.qcamerasvr
  fi
  if [ "`getprop init.svc.cameraserver`" = "running" ]; then
    setprop ctl.stop cameraserver
    stop cameraserver
  fi
  if [ "`getprop init.svc.camerasloganserver`" = "running" ]; then
    setprop ctl.stop camerasloganserver
    stop camerasloganserver
  fi
  if [ "`getprop init.svc.camerahalserver`" = "running" ]; then
    setprop ctl.stop camerahalserver
    stop camerahalserver
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

# choose the best I/O scheduler for very Hifi audio outputs, and output it into the standard output
function chooseBestIOScheduler() {
  local devno="$1"
  local OldIFS="$IFS"
  local x
  local ret_val=""
  
  IFS=' []'
  local scheds="`cat /sys/block/$devno/queue/scheduler`"
  set $scheds >/dev/null
  for x in $@; do
      case "$x" in
        "deadline" ) ret_val="deadline"; break ;;
                "cfq" ) ret_val="cfq" ;;
             "noop" ) if [ "$ret_val" != "cfq" ]; then ret_val="noop"; fi ;;
                     * ) ;;
      esac
  done
  IFS="$OldIFS"
  echo "$ret_val"
}

function setKernelTunables()
{
  local i
  local sched

# Set kernel tuables for CPU&GPU govenors, I/O scheduler, and Virtual memory
  
  # CPU governor
  # prevent CPU offline stuck by forcing online between double  governor writing 
  for i in `seq 0 9`; do
    if [ -e "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor" ]; then
      chmod 644 "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor"
      echo 'performance' >"/sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor"
      echo '1' >"/sys/devices/system/cpu/cpu$i/online"
      echo 'performance' >"/sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor"
    fi
  done
  # GPU governor
  if [ -w "/sys/class/kgsl/kgsl-3d0/pwrscale/trustzone/governor" ]; then
    echo 'performance' >"/sys/class/kgsl/kgsl-3d0/pwrscale/trustzone/governor"
  elif [ -w "/sys/class/kgsl/kgsl-3d0/devfreq/governor" ]; then
    echo 'performance' >"/sys/class/kgsl/kgsl-3d0/devfreq/governor"
  fi
  # I/O scheduler
  for i in sda sdb mmcblk0 mmcblk1; do
    if [ -d "/sys/block/$i/queue" ]; then
      echo '8192' >"/sys/block/$i/queue/read_ahead_kb"
      echo '0' >"/sys/block/$i/queue/iostats"
      echo '0' >"/sys/block/$i/queue/add_random"
      echo '2' >"/sys/block/$i/queue/rq_affinity"
      echo '2' >"/sys/block/$i/queue/nomerges"
      echo '9405' >"/sys/block/$i/queue/nr_requests"
    
     # Optimized for bluetooth audio and so on.
      sched="`chooseBestIOScheduler $i`"
      case "$sched" in
       "deadline" )
          echo 'deadline' >"/sys/block/$i/queue/scheduler"
          echo '0' >"/sys/block/$i/queue/iosched/front_merges"
          echo '0' >"/sys/block/$i/queue/iosched/writes_starved"
          case "`getprop ro.board.platform`" in
             sdm* | msm* | sd* | exynos* )
                echo '25' >"/sys/block/$i/queue/iosched/fifo_batch"
                echo '16' >"/sys/block/$i/queue/iosched/read_expire"
                echo '473' >"/sys/block/$i/queue/iosched/write_expire"
      	 echo '9410' >"/sys/block/$i/queue/nr_requests"
                ;;
             mt* | * )
                echo '24' >"/sys/block/$i/queue/iosched/fifo_batch"
                echo '16' >"/sys/block/$i/queue/iosched/read_expire"
                echo '472' >"/sys/block/$i/queue/iosched/write_expire"
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
          echo '20' >"/sys/block/$i/queue/iosched/slice_async_rq"
          echo '0' >"/sys/block/$i/queue/iosched/slice_idle"
          echo '3' >"/sys/block/$i/queue/iosched/slice_sync"
          echo '3' >"/sys/block/$i/queue/iosched/target_latency"
          ;;
        "noop" )
          echo 'noop' >"/sys/block/$i/queue/scheduler"
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
  echo '50' >"/proc/sys/vm/dirty_ratio"
  echo '25' >"/proc/sys/vm/dirty_background_ratio"
  echo '60000' >"/proc/sys/vm/dirty_expire_centisecs"
  echo '11100' >"/proc/sys/vm/dirty_writeback_centisecs"
  echo '1' >"/proc/sys/vm/laptop_mode"

  # For MediaTek CPUs, stop EAS+ scheduling to reduce jitters
  if [ -w "/proc/cpufreq/cpufreq_sched_disable" ]; then
    echo '1' >"/proc/cpufreq/cpufreq_sched_disable"
  fi
}

# Disable thermal core control, Camera service (interfering in jitters on audio outputs) and Selinux enforcing or not, respectively ("yes" or "no")
# Set default values for safety reasons
DefaultDisableThermalCoreControl="no"
DefaultDisableCameraService="no"
DefaultDisableSelinuxEnforcing="no"

# This function has usually two arguments
function optimizeOS()
{
  local a1=$DefaultDisableThermalCoreControl
  local a2=$DefaultDisableCameraService
  local a3=$DefaultDisableSelinuxEnforcing
  
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
    * )
      exit 1
      ;;
  esac

  if [ "$a1" = "yes" ]; then
    stopThermalCoreControl
  fi
  if [ "$a2" = "yes" ]; then
    stopCameraService
  fi
  if [ "$a3" = "yes" ]; then
    stopEnforcing
  fi
  stopMPDecision
  setKernelTunables
  setHifiNetwork
  setVolumeMediaSteps
}
