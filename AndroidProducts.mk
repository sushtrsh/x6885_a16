#
# Copyright (C) 2026 The OrangeFox Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#

# twrp_X6885  -> used by the builder for MANIFEST_BRANCH=12.1
# omni_X6885  -> used by the builder for the older (omni-based) branches
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/twrp_X6885.mk \
    $(LOCAL_DIR)/omni_X6885.mk

COMMON_LUNCH_CHOICES := \
    twrp_X6885-eng \
    twrp_X6885-userdebug \
    omni_X6885-eng \
    omni_X6885-userdebug
