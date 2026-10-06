#!/bin/bash
# OrangeFox build variables for Infinix X6885 (fox_12.1 naming).
# They must be exported: orangefox.mk / the packaging scripts read the environment.
# Obsolete in fox_12.1 (do NOT use): OF_AB_DEVICE, OF_VIRTUAL_AB_DEVICE, OF_VENDOR_BOOT_RECOVERY,
# OF_PATCH_VBMETA_FLAG, OF_VANILLA_BUILD, OF_TARGET_DEVICES.

export LC_ALL="C"
export ALLOW_MISSING_DEPENDENCIES=true

export OF_MAINTAINER="CHANGE_ME"

# Device identity (ROM/OTA zips may assert either name)
export FOX_TARGET_DEVICES="X6885,Infinix-X6885"
export TARGET_DEVICE_ALT="Infinix-X6885"

# A/B + Virtual A/B, recovery lives in vendor_boot
export FOX_VIRTUAL_AB_DEVICE=1
export FOX_AB_DEVICE=1
export FOX_VENDOR_BOOT_RECOVERY=1

# Display: 1080x2400 punch-hole
export OF_SCREEN_H=2400
export OF_HIDE_NOTCH=1
export OF_ALLOW_DISABLE_NAVBAR=1
export OF_USE_GREEN_LED=0
export OF_NO_SPLASH_CHANGE=1

# Encrypted /data (FBEv2 + metadata encryption)
export OF_DONT_PATCH_ENCRYPTED_DEVICE=1
export OF_FIX_DECRYPTION_ON_DATA_MEDIA=1
