#!/bin/bash
#
# This file is part of the OrangeFox Recovery Project
# Copyright (C) 2020-2025 The OrangeFox Recovery Project
#
# OrangeFox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# OrangeFox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# This software is released under GPL version 3 or any later version.
# See <http://www.gnu.org/licenses/>.
#
# Please maintain this if you use this script or any part of it.
#

device_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workspace_root="$(cd "${device_dir}/../../.." && pwd)"
patch_files=(
    "${device_dir}/patches/01-patch-vibration.patch"
    "${device_dir}/patches/02-patch-health-hal.patch"
    "${device_dir}/patches/04-patch-native-vendor-ramdisk.patch"
    "${device_dir}/patches/05-patch-enforcing-recovery.patch"
    "${device_dir}/patches/06-patch-fbe-auth-token.patch"
    "${device_dir}/patches/07-patch-sideload-install-once.patch"
    "${device_dir}/patches/08-patch-enforcing-runtime.patch"
)

export ALLOW_MISSING_DEPENDENCIES=true
export FOX_BUILD_DEVICE=X6885
export FOX_VIRTUAL_AB_DEVICE=1
export FOX_VENDOR_BOOT_RECOVERY=1
export FOX_INSTALLER_VENDOR_BOOT_RAMDISK_INSTALL=0
unset FOX_VENDOR_BOOT_POSTPROCESS_SCRIPT FOX_REFERENCE_VENDOR_BOOT_IMAGE
export FOX_USE_ZSTD_BINARY=1
export FOX_USE_DMSETUP=1

legacy_patch="${device_dir}/patches/03-patch-vendor-boot-postprocess.patch"
if (cd "${workspace_root}" && patch -p1 -R --dry-run --silent < "${legacy_patch}" >/dev/null 2>&1); then
    (cd "${workspace_root}" && patch -p1 -R --silent < "${legacy_patch}") || return 1
fi
unset legacy_patch

patches_ok=true
for patch_file in "${patch_files[@]}"; do
    if [[ ! -f "${patch_file}" ]] || ! command -v patch >/dev/null 2>&1; then
        echo "[X6885] Missing patch or patch command: ${patch_file}"
        patches_ok=false
        break
    fi
    if (cd "${workspace_root}" && patch -p1 -N --dry-run --silent < "${patch_file}" >/dev/null 2>&1); then
        if ! (cd "${workspace_root}" && patch -p1 -N --silent < "${patch_file}"); then
            patches_ok=false
            break
        fi
        echo "[X6885] Applied $(basename "${patch_file}")."
    elif (cd "${workspace_root}" && patch -p1 -R --dry-run --silent < "${patch_file}" >/dev/null 2>&1); then
        echo "[X6885] Already applied $(basename "${patch_file}")."
    else
        echo "[X6885] Patch does not apply: ${patch_file}"
        patches_ok=false
        break
    fi
done

if [[ "${patches_ok}" != true ]]; then
    unset device_dir workspace_root patch_files patch_file patches_ok
    return 1
fi
unset device_dir workspace_root patch_files patch_file patches_ok
