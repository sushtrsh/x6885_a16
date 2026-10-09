# Native bootstrap for the audited MT6789 Android 16 firmware family.
BOARD_VENDOR_RAMDISK_BOOTSTRAP := true
BOARD_RAMDISK_USE_ZSTD := true

# Compile the shared enforcing recovery policy into the native ramdisk.
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(DEVICE_PATH)/common/mt6789-vendor16/sepolicy/private
