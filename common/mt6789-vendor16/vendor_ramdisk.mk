# Device inputs: kernel-matched modules with their original load metadata,
# and stock first-stage fstabs. Recovery-only touch modules remain separate.
ifeq ($(strip $(MTK_VENDOR16_RAMDISK_MODULES_DIR)),)
$(error MTK_VENDOR16_RAMDISK_MODULES_DIR must name this device's module directory)
endif
ifeq ($(strip $(MTK_VENDOR16_RAMDISK_FSTABS)),)
$(error MTK_VENDOR16_RAMDISK_FSTABS must name this device's first-stage fstab files)
endif

PRODUCT_PACKAGES += init_first_stage

MTK_VENDOR16_RAMDISK_MODULE_FILES := \
    $(wildcard $(MTK_VENDOR16_RAMDISK_MODULES_DIR)/*.ko) \
    $(wildcard $(MTK_VENDOR16_RAMDISK_MODULES_DIR)/modules.*)
PRODUCT_COPY_FILES += $(foreach file,$(MTK_VENDOR16_RAMDISK_MODULE_FILES), \
    $(file):$(TARGET_COPY_OUT_VENDOR_RAMDISK)/lib/modules/$(notdir $(file)))
PRODUCT_COPY_FILES += $(foreach file,$(MTK_VENDOR16_RAMDISK_FSTABS), \
    $(file):$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/$(notdir $(file)))
