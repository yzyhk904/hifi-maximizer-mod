## A Magisk module for maximizing the digital audio fidelity by reducing jitters on audio outputs (USB DACs, Bluetooth a2dp, DLNA, etc.)

This module reduces jitters on audio outputs by optimizing kenel tunables (CPU & GPU  governors, thermal control, CPU hotplug, I/O scheduler, Virtual memory), Selinux mode, WIFI parameters, etc. as follows,

* For Reducing Jitters:
    <ol type="1">
    <li>CPU & GPU governor<br>
        change their governors to "performance" (additionally fixed at the max frequency).</li>
    <li>I/O scheduler<br>
        scheduler preference: "deadline" ("cfq" if "deadline" doesn't exist); optimize its tunables.</li>
    <li>Virtual memory<br>
        change "swappiness" to 0%, "laptop mode" to 1, etc.</li>
    <li>Thermal Control<br>
        disable Qcomm "core control" and stop thermal servers (e.g., "thermald", "thermal-engine", "thermal", "mi_thermald", etc.).</li>
    <li>CPU hotplug<br>
        stop "MPDecision" server (if exists).</li>
    <li>Disable MediaTek EAS+ scheduler<br>
        `echo '1' > "/proc/cpufreq/cpufreq_sched_disable"`</li>
    <li>Dose<br>
        stop the Android doze server.</li>
    <li>Selinux mode<br>
        change the mode to "permissive".</li>
    <li>Adaptive battery saving features<br>
        disable wifi suspend optimizations, the adaptive battery management and the adaptive connectivity management.</li>
    <li>Kill effect chains<br>
        force ignoring `/vendor/etc/audio_effects.xml` to disable equalizers, virtualizers, reverb's, visualizer, echo cancelers, automatic gain controls, etc.</li>
    <li>Disable Logd service<br>
        disable "logd server", "traced server" and "traced_probes server" interfering jitter on audio outputs.</li>
    <li>Disable camera service<br>
        disable "camera server" interfering jitter on audio outputs.</li>
    </ol>
<br/>

* For Convenience and Audio Quality:
    <ol type="1">
    <li> Disable DRC (Dynamic Range Control, i.e., a kind of compression)<br/>
        modify `/vendor/etc/*/audio_policy_configuration*.xml` to disable DRC if DRC has been enabled on a stock firmware.</li>
    <li>Volume steps<br/>
        change the number of steps in media volume to 100 steps (0.4~0.7dB per step).</li>
    <li>Resampling quality<br/>
        change AudioFlinger's resampling quality from the AOSP standard one (stop band attenuation 90dB & cut off 100% of the Nyquist frequency & half filter length 32) to a very mastering quality (179dB & 99% & 408, 167dB & 106% & 368 or 160db & 91% & 480 (or 320 for low performance devices), i.e., no resampling distortion in a real sense even though the 160dB targeted attenuation is not accomplished in the AOSP implementation).</li>
    <li>Adjust a USB transfer period of the USB HAL driver (not the recently common hardware offloading USB (tunneling) driver)<br/>
        for directly reducing the jitter of a PLL in a DAC (even in an asynchronous mode); Use <a href="https://github.com/yzyhk904/USB_SampleRate_Changer">"USB_SampleRate_Changer"</a> to switch from the usual hardware offloading USB (tunneling) driver to the USB HAL one.</li>
    <li>Set a higher bitrate limit of bluetooth codec SBC (dual channel mode)<br/>
        for EDR 2Mbps entry class earphones (not for EDR 3Mbps performance ones, but including AV amplifiers and BT speakers).</li>
    <li>Set an audio scheduling tunable "vendor.audio.adm.buffering.ms" "2"<br/>
         to reduce jitter on all audio outputs.</li>
    </ol>
<br/><br/>

* This module has been tested on LineageOS and ArrowOS ROM's, and phh GSI's (Android 10 & 11 & 12, Qualcomm & MediaTek SoC, and Arm32 & Arm64 combinations). 

* Note: Entry class USB DAC's usually adopt an interface chip communicating with the adaptive mode or the synchronous one defined in the USB audio standard. As in these modes an Android host controller sends audio sampling rate clock signals to the DAC, jitter generated at the host side affects the audio quality of the DAC tremendously. Higher class DAC's communicate with the asynchronous mode (also defined in the standard) to a host controller, but they actually use a PLL to reduce jitter from the host not to stutter even in heavy jitter situations. As this result, they behave as the adaptive mode with a feedback loop to dynamically adjust the host side sampling clock signals while referring a DAC side clock in a real sense, so even with asynchronous mode they are more or less affected by host side jitter. You can see the mode of your USB DAC by opening "/proc/asound/card1/stream0" on your phone while playing music. Please see a word in parentheses at "Endpoint:" lines; "SYNC", "ADAPTIVE" or "ASYNC" means that your DAC uses "synchronous", "adaptive" or "asynchronous" mode to communicate to your phone, respectively. Moreover, almost all audio peripherals, e.g., bluetooth earphones, internal DAC's, network audio devices have a PLL in themselves and are affected by host side jitter for the same reason.

* Please use another magisk module of mine ["Audio jitter silencer"](https://github.com/Magisk-Modules-Alt-Repo/audio-jitter-silencer) with this module. I don't recommend this, but for your convenience. This module works automatically (but not completely) as following my recommendation.

* Or I recommend disabling "Manage apps automatically" in "Battery manager" (or "Adaptive battery" of "Adaptive preferences") in the battery section (needless to say, don't enable battery savers, performance limiters and the like), turn off "Adaptive connectivity" in the Network & internet section (if exists), and changing "Battery optimization" from "Optimize" to "Don't optimize" (or change "Battery usage" from "Optimized" to "Unrestricted") for following app's manually through the settings UI of Android OS (to lower less than 10Hz jitter making extremely short reverb or foggy sound like distortion) even though disabling the Android doze itself: music (streaming) player apps, their licensing apps (if exist), "AirMusic" (if exists), "AirMusic  Recording Service" (system app; if exists), equalizer apps (if exist), "Bluetooth" (system app), "Bluetooth MIDI Service" (system app), "MTP Host" (system app), "NFC Service" (system app; if exists), "sManager" or the like (if exists), "Magisk" (if exists), System WebView apps (system app), Browser apps, "PhhTrebleApp" (system app; if exists), "Android Services Library" (system app), "Android Shared Library" (system app), "Android System" (system app), "System UI" (system app), "Input Devices" (system app), {Gesture, 3 Button, 2  Button} Navigation Bar apps (which you are using only; system app), "crDroid System" (system app; if exists), "LineageOS System" (system app; if exists), launcher app, "Google Play Store" (system app), "Google Play services" (system app), "Styles & wallpaper" or the like (system app), {Lineage, crDroid, Arrow, etc.} themes app (system app; if exists),  "AOSP panel" (system app; if exists), "OmniJaws" (system app; if exists), "OmniStyle" (system app; if exists), "Active Edge Service" (system app; if exists), "Android Device Security Module" (system app; if exists), "Call Management" (system app; if exists), "Phone" (system app; if exists), "Phone Calls" (system app; if exists), "Phone Services" (system app; if exists), "Phone and Messaging Storage" (system app; if exists), "Storage Manager" (system app), "Default" (system app; if exists), "Default StatusBar" (system app; if exists), "Wfd Service" (system app; if exists), "Wallpaper" or the like (system app), "Adreno Graphics Drivers" (system app; if exists), "com.android.providers.media" (system app), "Files by Google" (system app; if exists), "Google Play Services for AR" (system app; if exists), "Google Services Framework" (system app), "Waterfall cutout" (system app), "Network Manager" (system app), "Companion Device Manager" (system app), "Intent Filter Verification Service" (system app), "Calendar", camera apps, keyboard app, kernel adiutors (if exist), etc. And Disable "Digital Wellbeing" (system app; if it exists) itself or change "Battery usage" from "Optimized" to "Unrestricted" (this is very harmful for audio like camera servers).

* See also my companion script ["USB_SampleRate_Changer"](https://github.com/yzyhk904/USB_SampleRate_Changer) to change the sample rate of the USB (HAL) audio class driver and a 3.5mm jack on the fly like Bluetooth LDAC or Windows mixer to enjoy high resolution sound or to reduce resampling distortion (actually pre-echo, ringing and intermodulation) ultimately.

* Tips: If you use "AirMusic" to transmit audio data, I recommend to set around 4573 msec additional delay to reduce jitter distortion on the AirMusic panel to display target device(s).

* Note: Please remember that this module will stop the thermal control (including CPU core controls, CPU hotplugs and thermal services), the "logd server" and the "camera server" (interfering jitter on audio outputs), disable SELinux enforcing mode and doze (battery saver while idling) on your device. If you like to disable these features, modify variables in "service.sh", respectively.
<br/>

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

# v2.2
* Set new properties related to an audio scheduling

##
