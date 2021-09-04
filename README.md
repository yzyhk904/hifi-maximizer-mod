## A Magisk module for maximizing the digital audio fidelity by reducing jitters on audio outputs (USB DACs, Bluetooth a2dp, DLNA, etc.)

Tested on LineageOS and ArrowOS ROM's, and phh GSI's (Android 10 & 11, Qualcomm & MediaTek SoC, and Arm32 & arm64 combinations). This module reduces jitters on audio outputs by optimizing kenel tunables (in CPU & GPU  governors, thermal control, CPU hotplug, I/O scheduler, Virtual memory), Selinux mode, WIFI parameters, etc. as follows,

* For Reducing Jitters
  1. CPU & GPU governor<br>
  	change their governors to "performance".
  2. I/O scheduler<br>
  	scheduler preference: "deadline" ("cfq" if "deadline" doesn't exist); optimize its tunables.
  3. Virtual memory<br>
  	change "swappiness" to 0%, "laptop mode" to 1, etc.
  4. Thermal Control (if it exists)<br>
  	disable "core control".
  5. CPU hotplug<br>
  	disable "MPDecision".
  6. Selinux mode<br>
  	change the mode to "permissive".
  7. WIFI suspension<br>
  	disable wifi suspend optimizations.
  9. Kill effect chains<br>
  	modify `/vendor/etc/audio_effects.xml` to disable equalizers, virtulizers, reverb's, etc.
  11. Disable camera service<br>
  	disable "camera server" interfering jitter on audio outputs.
  12. Disable MediaTek EAS+ scheduler<br>
  	`echo '1' > "/proc/cpufreq/cpufreq_sched_disable"`

* For Convinience and Audio Quality
  1. Disable DRC (Dynamic Range Control, or simply compression)<br>
  	modify `/vendor/etc/audio_policy_configuration.xml` to disable DRC.
  2. Volume steps<br>
  	change the number of steps in media volume to 100 steps (0.4~0.7dB per step).
  
* Please disable battery optimizations manually for app's through settings UI of Android OS as follows (to lower less than 10Hz jitter making vibrato like distortions)
music players, licensing apps, "bluetooth" (system app), "Android Services Library", "Android Shared Library", "Android System", launcher app, "Google Play Services", "Magisk", "PhhTrebleApp", keyboard app, kernel adiutor, etc.

* See also my companion script ["USB_SampleRate_Changer"](https://github.com/yzyhk904/USB_SampleRate_Changer) to change the sample rate of the USB (HAL) audio class driver on the fly like Bluetooth LDAC or Windows mixer to reduce resampling distortions.

* Note: Please remember that this module will stop the thermal "core control" and the "camera server" (interfering jitter on audio outputs) on your device. If you like to disable these fatures, modify variables in "service.sh", respectively.

## DISCLAIMER

* I am not responsible for any damage that may occur to your device, so it is your own choice to attempt this module.

## Change logs

# v1.0
* Initial Release
# v1.1
* Stopped the EAS+ scheduling feature for MediaTek CPUs
# v1.2
* Stopped camera servers interfering in jitters on audio outputs, and reformatted source codes
# v1.3
* Realme support (/proc/sys/vm/direct_swappiness)
# v1.4
* Moved scattered functions into "functions.sh" together, and treated IO Schedulers more rigorously
# v2.0
* Supported audio policy configuration XML files for "disable a2dp offload", "force-disable a2dp offload", and so on

##
