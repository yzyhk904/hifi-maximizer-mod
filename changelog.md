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

# v2.3
* Restructured source codes to be sharable with the jitter-reducer.sh in USB_SampleRate_Changer

# v2.4
* Fixed some SELinux related bugs for Magisk v26.0's new magic mount feature
* Diabled pre-installed Moto Dolby features for reducing large jitter caused by them

##
