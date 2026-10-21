#
# Copyright (C) 2022 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Alias: `lunch twrp_X6885-*` tetap jalan. Isi lengkap ada di fox_X6885.mk.
$(call inherit-product, device/infinix/X6885/fox_X6885.mk)

# Product Specifics
PRODUCT_NAME := twrp_X6885
PRODUCT_DEVICE := X6885
PRODUCT_BRAND := Infinix
PRODUCT_MODEL := Infinix X6885
PRODUCT_MANUFACTURER := INFINIX

PRODUCT_GMS_CLIENTID_BASE := android-transsion
