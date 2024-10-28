#!/system/bin/sh

# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script and module is placed.
# This will make sure your module will still work if Magisk change its mount point in the future
  MODDIR=${0%/*}

# This script will be executed in post-fs-data mode

if [ \( -e "${MODDIR%/*/*}/modules/usb-samplerate-unlocker"  -a  ! -e "${MODDIR%/*/*}/modules/usb-samplerate-unlocker/disable" \) \
        -o  -e "${MODDIR%/*/*}/modules_update/usb-samplerate-unlocker" ] || \
    [ \( -e "${MODDIR%/*/*}/modules/audio-samplerate-changer"  -a  ! -e "${MODDIR%/*/*}/modules/audio-samplerate-changer/disable" \) \
        -o  -e "${MODDIR%/*/*}/modules_update/audio-samplerate-changer" ]; then
        
    # If usb-samplerate-unlock or audio-samplerate-changer exists, save related libraries and file(s) elsewhere
    # becausethey will do the same thing in themselves.
    for d in "lib" "lib64"; do
        for lname in "libalsautils.so" "libalsautilsv2.so"; do
            if [ -r "${MODDIR}/system/vendor/${d}/${lname}" ]; then
                mkdir -p "${MODDIR}/save/vendor/${d}"
                mv "${MODDIR}/system/vendor/${d}/${lname}" "${MODDIR}/save/vendor/${d}/${lname}"
            fi
        done        
    done
    
    for fname in "audio_platform_configuration.xml"; do
        if [ -r "${MODDIR}/system/vendor/etc/${fname}" ]; then
            mkdir -p "${MODDIR}/save/vendor/etc"
            mv "${MODDIR}/system/vendor/etc/${fname}" "${MODDIR}/save/vendor/etc/${fname}"
        fi
    done
    
else

    # If usb-samplerate-unlock doesn't exist, restore related libraries and file(s) from their saved folders.
    for d in "lib" "lib64"; do
        for lname in "libalsautils.so" "libalsautilsv2.so"; do
            if [ -r "${MODDIR}/save/vendor/${d}/${lname}"  -a  -e "${MODDIR}/system/vendor/${d}" ]; then
                mv "${MODDIR}/save/vendor/${d}/${lname}" "${MODDIR}/system/vendor/${d}/${lname}"
                chmod 644 "${MODDIR}/system/vendor/${d}/${lname}"
            fi
        done        
    done

    for fname in "audio_platform_configuration.xml"; do
        if [ -r "${MODDIR}/save/vendor/etc/${fname}"  -a  -e "${MODDIR}/system/vendor/etc" ]; then
            mv "${MODDIR}/save/vendor/etc/${fname}" "${MODDIR}/system/vendor/etc/${fname}"
            chmod 644 "${MODDIR}/system/vendor/etc/${fname}"
        fi
    done

fi
