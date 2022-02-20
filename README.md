## A Magisk module for maximizing the digital audio fidelity by reducing jitters on audio outputs (USB DACs, Bluetooth a2dp, DLNA, etc.)

This module reduces jitters on audio outputs by optimizing kenel tunables (CPU & GPU  governors, thermal control, CPU hotplug, I/O scheduler, Virtual memory), Selinux mode, WIFI parameters, etc. as follows,

* For Reducing Jitters
  1. CPU & GPU governor<br>
  	change their governors to "performance" (additionally fixed at the max frequency).
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
  	force ignoring `/vendor/etc/audio_effects.xml` to disable equalizers, virtulizers, reverb's, visualizer, etc.
  11. Disable camera service<br>
  	disable "camera server" interfering jitter on audio outputs.
  12. Disable MediaTek EAS+ scheduler<br>
  	`echo '1' > "/proc/cpufreq/cpufreq_sched_disable"`

* For Convinience and Audio Quality
  1. Disable DRC (Dynamic Range Control, i.e. compression)<br>
  	modify `/vendor/etc/audio_policy_configuration.xml` to disable DRC if DRC has been enabled in a stock firmware.
  2. Volume steps<br>
  	change the number of steps in media volume to 100 steps (0.4~0.7dB per step).
  3. Resampling quality<br>
  	change AudioFlinger's resampling quality from the AOSP standard one (stop band attenuation 90dB & cut off 100% of Nyquist frequency) to a mastering quality (160db & 91%, i.e. no resampling distortion in a real sense even though the 160dB targeted attenuation is not accomplished in the AOSP implementation).

<br/><br/>

* This module has been tested on LineageOS and ArrowOS ROM's, and phh GSI's (Android 10 & 11 & 12, Qualcomm & MediaTek SoC, and Arm32 & Arm64 combinations). 
  
* Please disable "Manage apps automatically" in "Battery manager" (or "Adaptive battery" of "Adaptive preferences") in the battery section (needless to say, don't enable battery savers and the like), and change "Battery optimization" from "Optimize" to "Don't optimize" (or change "Battery usage" from "Optimized" to "Unrestricted") for following app's manually through the settings UI of Android OS (to lower less than 10Hz jitter making extremely short reverb or foggy sound like distortion). music (streaming) player apps, their licensing apps (if exist), "AirMusic" (if exists), "AirMusic  Recording Service" (system app; if exists), equalizer apps (if exist), "Bluetooth" (system app), "Bluetooth MIDI Service" (system app), "MTP Host" (system app), "NFC Service" (system app; if exists), "Magisk" (if exists), System WebView apps (system app), Browser apps, "PhhTrebleApp" (system app; if exists), "Android Services Library" (system app), "Android Shared Library" (system app), "Android System" (system app), "System UI" (system app), "Input Devices" (system app), Navigation Bar app (system app; if exists), "crDroid System" (system app; if exists), "LineageOS System" (system app; if exists), launcher app, "Google Play Store" (system app), "Google Play services" (system app), "Styles & wallpaper" or the like (system app), {Lineage, crDroid, Arrow, etc.} themes app (system app; if exists),  "AOSP panel" (system app; if exists), "OmniJaws" (system app; if exists), "OmniStyle" (system app; if exists), "Active Edge Service" (system app; if exists), "Android Device Security Module" (system app; if exists), "Call Management" (system app; if exists), "Phone" (system app; if exists), "Phone Calls" (system app; if exists), "Phone Services" (system app; if exists), "Phone and Messaging Storage" (system app; if exists), "Storage Manager" (system app), "Default" (system app; if exists), "Default StatusBar" (system app; if exists), keyboard app, kernel adiutors (if exist), etc. And also Disable "Digital Wellbeing" (system app; if it exists) itself or change "Battery usage" from "Optimized" to "Unrestricted" (this is very harmfull for audio like camera servers).


* See also my companion script ["USB_SampleRate_Changer"](https://github.com/yzyhk904/USB_SampleRate_Changer) to change the sample rate of the USB (HAL) audio class driver and a 3.5mm jack on the fly like Bluetooth LDAC or Windows mixer to reduce resampling distortions.

* Tips: If you use "AirMusic" to transmit audio data, I recommend to set around 4399 msec additional delay to reduce jitter distortion on the AirMusic panel to display target device(s).

* Note: Please remember that this module will stop the thermal "core control" and the "camera server" (interfering jitter on audio outputs), and disable SELinux enforcing mode on your device. If you like to disable these fatures, modify variables in "service.sh", respectively.

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
# v2.1
* The GPU frequency became to be fixed really at the max frequency for Qualcomm Soc and MediaTek SoC
##
