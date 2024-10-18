## A Magisk module for maximizing the digital audio fidelity by reducing jitters on audio outputs (USB DACs, Bluetooth a2dp, DLNA, etc.)

So many music lovers abandon audio quality on smart phones and DAP's by believing its causes are delivered from analog components. However, the most crucial cuase of it is actually shorter than 50 Hz jitter (i.e., the standard deviation of actual audio data rate with a low-pass filter; usually converting into time-domain) on digital audio outputs that generates very short reverb or foggy sound like distortion on analog audio outputs. Although more than 50 Hz (shorter than 20 msec. interval) jitter can be easily reduced under the hearable level by a PLL (Phase Locked Loop) in DAC's, the other (especially less than 10 Hz or longer than 100 msec. interval) modulates and distorts audio outputs by fluctuating the master clock in a DAC through the PLL. For further explanation, see my another magisk module ["Audio jitter silencer"](https://github.com/Magisk-Modules-Alt-Repo/audio-jitter-silencer).

For maximizing the audio fidelity, this module reduces less than 50 Hz (longer than 20 msec interval) jitters on digital audio outputs by optimizing kenel tunables (CPU & GPU  governors, thermal control, CPU hotplug, I/O scheduler, Virtual memory), Selinux mode, WIFI parameters, etc. as follows,

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
        ```echo '1' > "/proc/cpufreq/cpufreq_sched_disable"```</li>
    <li>Doze<br>
        stop the Android doze server.</li>
    <li>Selinux mode<br>
        change the mode to "permissive".</li>
    <li>Adaptive battery saving features<br>
        disable wifi suspend optimizations, the adaptive battery management, the adaptive charging management and the adaptive connectivity management.</li>
    <li>Kill effect chains<br>
        force ignoring ```/vendor/etc/audio_effects.xml``` to disable equalizers, virtualizers, reverb's, visualizer, echo cancelers, automatic gain controls, etc. (very few vulnerable equalizers may crash by this killing, but please ignore it)</li>
    <li>Disable the android built-in spatial audio feature (A13 or higher; especially Tensor devices)<br/>
         bypass an otiose audio pass.</li>
    <li>Disable aocd service<br/>
        disable "aocd server" generating significant jitter on audio outputs, esp. on USB.</li>
    <li>Disable pre-installed Moto Dolby and Digital Wellbeing features<br/>
        hide their apps (no modifications); please manually uninstall Digital Wellbeing app if remaining as a usual app.</li>
    <li>Disable Logd service<br/>
        disable "logd server", "traced server" and "traced_probes server" interfering jitter on audio outputs.</li>
    <li>Disable camera service<br/>
        disable "camera server" interfering jitter on audio outputs.</li>
    </ol>
<br/>

* For Convenience and Audio Quality:
    <ol type="1">
    <li> Disable DRC (Dynamic Range Control, i.e., a kind of compression)<br/>
        modify ```/vendor/etc/*/audio_policy_configuration*.xml``` to disable DRC if DRC has been enabled on a stock firmware.</li>
    <li>Volume steps<br/>
        change the number of steps in media volume to 100 steps (0.4~0.7dB per step).</li>
    <li>Resampling quality<br/>
        change AudioFlinger's resampling quality from the AOSP standard one (stop band attenuation 90dB & cut off 100% of the Nyquist frequency & half filter length 32) to a very mastering quality (179dB & 99% & 408, 167dB & 106% & 368 or 160db & 91% & 480 (or 320 for low performance devices), i.e., no resampling distortion in a real sense even though the 160dB targeted attenuation is not accomplished in the AOSP implementation). However, install <a href="https://github.com/Magisk-Modules-Alt-Repo/resampling-for-cheapies">"Resampling for cheapies" module</a> together to override these resampling settings if you intend to use LDAC bluetooth earphones or DAC's under $30.</li>
    <li>Adjust a USB transfer period of the USB HAL driver (not the Qcomm hardware offload USB driver, but including ones of Tensor and MTK devices)<br/>
        for directly reducing the jitter of a PLL in a DAC (even in an asynchronous mode); Use <a href="https://github.com/yzyhk904/USB_SampleRate_Changer">"USB_SampleRate_Changer"</a> to switch from the usual hardware offload USB driver to the USB HAL one.</li>
    <li>Set a higher bitrate limit of bluetooth codec SBC (dual channel mode)<br/>
        for EDR 2Mbps entry class earphones (not for EDR 3Mbps performance ones, but including AV amplifiers and BT speakers).</li>
    <li>Set an audio scheduling tunable "vendor.audio.adm.buffering.ms" "2"<br/>
         to reduce jitter on all audio outputs.</li>
    <li>Nullify volume listener libraries in "soundfx" folders  for disabling slight compression (maybe a peak limiter only on Qcomm devices).</li>
    <li>Set 192kHz & 32bit mode (max., but automatic for lower capability DAC's) for all the USB audio outputs (including non- Hi-Res audio tracks) of Tensor devices exceptionally<br/>
         because Tensor devices lower audio quality extremely for lower sample rates and bit depths, though the quality of in-DAC over-sampling filters is much worse than that of the re-sampling filter used by this module and the filters lower the quality particularly for input of lower sample rates as usual.
</li>
    </ol>
<br/><br/>

* Don't forget to install ["Audio jitter silencer"](https://github.com/Magisk-Modules-Alt-Repo/audio-jitter-silencer) together and uninstall "Digital Wellbeing" app (for reducing very large jitters which this module cannot reduce as itself)! And uninstall ["Audio misc. settings"](https://github.com/Magisk-Modules-Alt-Repo/audio-misc-settings) and ["DRC remover"](https://github.com/Magisk-Modules-Alt-Repo/drc-remover) if they have already been installed, because all their functions are included in this module. Additionally if your device uses a Tensor SoC, uninstall ["USB Samplerate Unlocker"](https://github.com/Magisk-Modules-Alt-Repo/usb-samplerate-unlocker) for the same reason.

* Don't use Am@zon music using a much worse internal re-sampler which bypasses the mastering quality re-sampling in the OS mixer (audioFlinger). Other music streaming services don't use such an internal re-sampler, as far as I know.

* This module has been tested on LineageOS and crDroid ROM's, and phh GSI's (Android 10 ~ 14, Qualcomm & MediaTek SoC, and Arm32 & Arm64 combinations). 

* Note: Entry class USB DAC's usually adopt an interface chip communicating with the adaptive mode or the synchronous one defined in the USB audio standard. As in these modes an Android host controller sends audio sampling rate clock signals to the DAC, jitter generated at the host side affects the audio quality of the DAC tremendously. Higher class DAC's communicate with the asynchronous mode (also defined in the standard) to a host controller, but they actually use a PLL to reduce jitter from the host not to stutter even in heavy jitter situations. As this result, they behave as the adaptive mode with a feedback loop to dynamically adjust the host side sampling clock signals while referring a DAC side clock in a real sense, so even with asynchronous mode they are more or less affected by host side jitter. You can see the mode of your USB DAC by opening "/proc/asound/card1/stream0" on your phone while playing music. Please see a word in parentheses at "Endpoint:" lines; "SYNC", "ADAPTIVE" or "ASYNC" means that your DAC uses "synchronous", "adaptive" or "asynchronous" mode to communicate to your phone, respectively. Moreover, almost all audio peripherals, e.g., bluetooth earphones, internal DAC's, network audio devices have a PLL in themselves and are affected by host side jitter for the same reason.

* I recommend expert users not to install ["Audio jitter silencer"](https://github.com/Magisk-Modules-Alt-Repo/audio-jitter-silencer), but manually to disable "Manage apps automatically" in "Battery manager" (or "Adaptive battery" of "Adaptive preferences") in the battery section (needless to say, don't enable battery savers, performance limiters and the like), turn off "Adaptive connectivity" in the Network & internet section (if exists), and changing "Battery optimization" from "Optimize" to "Don't optimize" (or change "Battery usage" from "Optimized" to "Unrestricted") for following app's manually through the settings UI of Android OS (to lower less than 10Hz jitter making extremely short reverb or foggy sound like distortion) even though disabling the Android doze itself: music (streaming) player apps, their licensing apps (if exist), "AirMusic" (if exists), "AirMusic  Recording Service" (system app; if exists), equalizer apps (if exist), "Bluetooth" (system app), "Bluetooth MIDI Service" (system app), "MTP Host" (system app), "NFC Service" (system app; if exists), "Magisk" (if exists), System WebView apps (system app), Browser apps, "PhhTrebleApp" (system app; if exists), "Android Services Library" (system app), "Android Shared Library" (system app), "Android System" (system app), "System UI" (system app), "Input Devices" (system app), {Gesture, 3 Button, 2  Button} Navigation Bar apps (which you are using only; system app), "crDroid System" (system app; if exists), "LineageOS System" (system app; if exists), launcher app, "Google Play Store" (system app), "Google Play services" (system app), "Styles & wallpaper" or the like (system app), {Lineage, crDroid, Arrow, etc.} themes app (system app; if exists),  "AOSP panel" (system app; if exists), "OmniJaws" (system app; if exists), "OmniStyle" (system app; if exists), "Active Edge Service" (system app; if exists), "Android Device Security Module" (system app; if exists), "Call Management" (system app; if exists), "Phone" (system app; if exists), "Phone Calls" (system app; if exists), "Phone Services" (system app; if exists), "Phone and Messaging Storage" (system app; if exists), "Storage Manager" (system app), "Default" (system app; if exists), "Default StatusBar" (system app; if exists), "Wfd Service" (system app; if exists), "Wallpaper" or the like (system app), "Adreno Graphics Drivers" (system app; if exists), "com.android.providers.media" (system app), "Files by Google" (system app; if exists), "Google Play Services for AR" (system app; if exists), "Google Services Framework" (system app), "Waterfall cutout" (system app), "Punch Hole cutout" (system app), "Network Manager" (system app), "Companion Device Manager" (system app), "Intent Filter Verification Service" (system app), "Calendar", camera apps, keyboard app, kernel adiutors (if exist), etc. And uninstall "Digital Wellbeing" (system app; if it exists) itself or change "Battery usage" from "Optimized" to "Restricted" (this is very harmful for audio like camera servers). Because "Audio jitter silencer" isn't complete and needs some maintenance after its installation.

* See also my companion script ["USB_SampleRate_Changer"](https://github.com/yzyhk904/USB_SampleRate_Changer) to change the sample rate of the USB (HAL) audio class driver and a 3.5mm jack on the fly like Bluetooth LDAC or Windows mixer to enjoy high resolution sound or to reduce resampling distortion (actually pre-echo, ringing and intermodulation) ultimately.

* Tips: If you use "AirMusic" to transmit audio data, I recommend setting around 4599 msec additional delay to reduce jitter distortion on the AirMusic panel to display target device(s).

* Note1: Please remember that this module will stop the thermal control (including CPU core controls, CPU hotplugs and thermal services), the "logd server" and the "camera server" (interfering jitter on audio outputs), disable SELinux enforcing mode and doze (battery saver while idling) on your device. If you like to enable these features, modify variables in "service.sh", respectively. Especially, note that the "Youtube" app became recetly to need the camera server for launching for some unexplained reason.

* Note2: If you prefer (too sensitive?) Bluetooth earphones to wired headphones and DLNA renderers, set "DisableClearestTone" variable to be "yes" in "service.sh".

* Appendix A. Examples of Re-sampling Parameters:
    
    
    | Stop band attenuation (dB) | Half filter length | Cut-off (%) | Stop band (%) | Memo |
    | ---: | ---: | ---: | ---: | ---- |
    | 90 | 32 | 100 | | AOSP default |
    | This mod. parameters: | - | - | - | - |
    | 159 | 320 | 92 | | Low Performance devices under A12 |
    | 159 | 480 | 92 | | High Performance devices under A12 |
    | 165 | 360 | | 104 | Low Performance devices for A12 and later |
    | 179 | 408 | | 99 | High Performance devices for A12 and later, and Galaxy S4 |
    | External examples: | - | - | - | - |
    | 100 | 29 | (91) | 109 | AK4493 (Sharp roll-off N-fold over-sampling) |
    | 150 | 42 | (91) | 109 | AK4191EQ (Sharp roll-off N-fold over-sampling) |
    | 120 | 35 | (97) | 110 | ES9038PRO (Fast roll-off N-fold over-sampling) |
    | vary 50 ~ 118 | 34 | 96 | (398) | ES9039PRO (Fast roll-off N-fold over-sampling) |
    | 110 | 40 | (96) | 109 | CS43131 (Fast roll-off N-fold over-sampling) |
    | 98 | 130 | 98.5 | | MacOS Leopard (guess) |
    | 159 | 240 | | 99 | iZotope, No-Alias (guess) |
    | 100 | 64 | | 99 | SoX HQ linear phase (guess) |
    | 170 | 520 | | 99 | SoX VHQ linear phase (guess) |

<br/>
<br/>

## DISCLAIMER

* I am not responsible for any damage that may occur to your device, so it is your own choice whether to attempt this module or not.

##
