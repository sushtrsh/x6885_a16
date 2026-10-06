#
# Copyright (C) 2026 The OrangeFox Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#
# Infinix X6885 (MT6789, board x6885_h8923) - recovery lives in vendor_boot
#
# Every value marked [stock] was read from the stock vendor_boot.img
# (header v4, 64 MiB, 2 ramdisk fragments, DT table, bootconfig).
# Values marked [device] were measured on a real X6885 (adb/root collection).
#
# BUILD WITH:  MANIFEST_BRANCH=12.1  BUILD_TARGET=vendorboot
# (boot header v4 is not supported by the 11.0 manifest)

DEVICE_PATH := device/infinix/X6885

# Build quirks
ALLOW_MISSING_DEPENDENCIES := true
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# Architecture [stock: ro.product.cpu.abilist=arm64-v8a, cpu_variant=cortex-a55]
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := cortex-a55
TARGET_CPU_VARIANT_RUNTIME := cortex-a55

# Platform [stock: ro.board.platform=mt6789, ro.product.board=x6885_h8923]
TARGET_BOARD_PLATFORM := mt6789
TARGET_BOOTLOADER_BOARD_NAME := x6885_h8923
TARGET_NO_BOOTLOADER := true

# Kernel: the kernel lives in boot.img (GKI 6.12.38, android16). Nothing to
# build here - vendor_boot only carries ramdisk + DTB + bootconfig.
TARGET_NO_KERNEL := true
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
BOARD_RAMDISK_USE_LZ4 := true

# vendor_boot header [stock]
BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_BASE := 0x40000000
BOARD_KERNEL_OFFSET := 0x00000000
BOARD_RAMDISK_OFFSET := 0x26f00000
BOARD_KERNEL_TAGS_OFFSET := 0x07c80000
BOARD_DTB_OFFSET := 0x07c80000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_VENDOR_CMDLINE := bootopt=64S3,32N2,64N2 bootconfig
BOARD_KERNEL_CMDLINE := $(BOARD_VENDOR_CMDLINE)

# Stock bootconfig section (94 bytes) [stock]
BOARD_BOOTCONFIG := \
    kernel.rcu_nocbs=all \
    kernel.rcutree.enable_rcu_lazy=1 \
    kernel.rcupdate.rcu_cpu_stall_cputime=1

# DTB: byte-exact copy of the stock DT table (extracted with tools/unpack_vendor_boot.py)
TARGET_PREBUILT_DTB := $(DEVICE_PATH)/prebuilt/dtb.img
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --base $(BOARD_KERNEL_BASE)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)
BOARD_MKBOOTIMG_ARGS += --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)
BOARD_MKBOOTIMG_ARGS += --dtb $(TARGET_PREBUILT_DTB)

# Partitions
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_FLASH_BLOCK_SIZE := 262144
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_USES_METADATA_PARTITION := true
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_USES_MKE2FS := true
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs

# 12.1 only knows: system vendor product system_ext odm vendor_dlkm odm_dlkm (no system_dlkm).
# Dynamic partitions. [device: blockdev --getsize64 /dev/block/by-name/super = 12934782976]
# Only used by the build system, not by the recovery at runtime.
BOARD_SUPER_PARTITION_SIZE := 12934782976
BOARD_SUPER_PARTITION_GROUPS := main
BOARD_MAIN_SIZE := 12930588672
BOARD_MAIN_PARTITION_LIST := system system_ext vendor product odm vendor_dlkm odm_dlkm
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_ODM := odm
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
TARGET_COPY_OUT_ODM_DLKM := odm_dlkm
# build/make/core/board_config.mk (12.1) requires a filesystem type for every partition whose
# TARGET_COPY_OUT_* is a root-level directory. Only the build system reads these values here;
# the real filesystems are described in recovery.fstab (stock images are erofs).
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_ODM_DLKMIMAGE_FILE_SYSTEM_TYPE := ext4

# A/B (OrangeFox checks for this in BoardConfig.mk)
AB_OTA_UPDATER := true

# Recovery in vendor_boot (no recovery partition on this device)
TARGET_NO_RECOVERY := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
# Put the recovery ramdisk in its own 'recovery' fragment, like the stock vendor_boot does
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888
# ^ [stock: ro.minui.pixel_format=BGRA_8888]

# Kernel modules: the stock PLATFORM fragment already holds the ~230 modules (display, UFS, USB,
# PMIC...). The recovery fragment only adds the touch driver (gt9896s + tui-common) and the
# updated modules.load.recovery / modules.dep; the stock fragment is kept by tools/make_vendor_boot.py.
TW_LOAD_VENDOR_BOOT_MODULES := true

# Security patch / version: match the stock firmware so keymint accepts the
# recovery for key unwrapping [stock: Android 16, patch 2026-08-01]
PLATFORM_VERSION := 16
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
PLATFORM_SECURITY_PATCH := 2026-08-01
VENDOR_SECURITY_PATCH := 2026-08-01
BOOT_SECURITY_PATCH := 2026-08-01

# Encryption [stock: fileencryption=aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized,
# keydirectory=/metadata/vold/metadata_encryption]
# NOTE: needs keymint/gatekeeper blobs from /vendor to actually decrypt (see README)
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
TW_USE_FSCRYPT_POLICY := 2

# TWRP / recovery core
TW_THEME := portrait_hdpi
TARGET_SCREEN_WIDTH := 1080
TARGET_SCREEN_HEIGHT := 2400
TARGET_SCREEN_DENSITY := 420
# ^ [stock: panels are fhdp (1080x2400), ro.sf.lcd_density=420]
TW_BRIGHTNESS_PATH := /sys/class/leds/lcd-backlight/brightness
TW_MAX_BRIGHTNESS := 5119
TW_DEFAULT_BRIGHTNESS := 2559
# ^ [device: max_brightness=5119 read from /sys/class/leds/lcd-backlight]
TW_EXTRA_LANGUAGES := true
TW_USE_TOOLBOX := true
TW_INCLUDE_FASTBOOTD := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_LPTOOLS := true
TW_HAS_MTP := true
TW_EXTERNAL_STORAGE_PATH := /external_sd
TW_EXTERNAL_STORAGE_MOUNT_POINT := external_sd
TW_OVERRIDE_SYSTEM_PROPS := \
    "ro.build.product;ro.build.fingerprint=ro.system.build.fingerprint;ro.build.version.incremental;ro.product.device=ro.product.system.device;ro.product.model=ro.product.system.model;ro.product.name=ro.product.system.name"

# Device names accepted by OTA/ROM zips
TARGET_OTA_ASSERT_DEVICE := X6885,Infinix-X6885
TARGET_DEVICE_ALT := Infinix-X6885

TW_CUSTOM_CPU_TEMP_PATH := /sys/class/thermal/thermal_zone1/temp
