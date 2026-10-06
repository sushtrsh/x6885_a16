#
# Copyright (C) 2026 The OrangeFox Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/infinix/X6885

# Base (64-bit only: stock abilist is arm64-v8a, no 32-bit ABI)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)

# Recovery vendor configuration. The sync used by the builder provides one of
# these; inherit whichever exists so the same tree works on 12.1 and 11.0.
ifneq ($(wildcard vendor/twrp/config/common.mk),)
$(call inherit-product, vendor/twrp/config/common.mk)
else ifneq ($(wildcard vendor/omni/config/common.mk),)
$(call inherit-product, vendor/omni/config/common.mk)
endif

# Device
$(call inherit-product, $(LOCAL_PATH)/device.mk)

PRODUCT_DEVICE := X6885
PRODUCT_NAME := omni_X6885
PRODUCT_BRAND := Infinix
PRODUCT_MODEL := Infinix X6885
PRODUCT_MANUFACTURER := INFINIX
PRODUCT_RELEASE_NAME := X6885
