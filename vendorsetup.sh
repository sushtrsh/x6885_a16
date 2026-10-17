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

# X6885_ALLOW_MK: izinkan Android.mk magisk-prebuilt (diblok denylist soong di A16)
_deny="${workspace_root}/build/soong/ui/build/androidmk_denylist.go"
if [[ -f "${_deny}" ]] && ! grep -q 'X6885_ALLOW_MK' "${_deny}"; then
    sed -i '/for _, mkFile := range androidMks {/a if strings.HasPrefix(mkFile, "external/magisk-prebuilt/") { continue } // X6885_ALLOW_MK' "${_deny}"
    grep -q 'X6885_ALLOW_MK' "${_deny}" && echo "[X6885] denylist: magisk-prebuilt diizinkan." \
        || echo "[X6885] WARNING: pola denylist tidak ketemu, cek ${_deny}"
fi
unset _deny
patch_files=(
    "${device_dir}/patches/01-patch-vibration.patch"
    "${device_dir}/patches/02-patch-health-hal.patch"
    "${device_dir}/patches/04-patch-native-vendor-ramdisk.patch"
    "${device_dir}/patches/04b-patch-vendor-script-recovery-cpio.patch"
    "${device_dir}/patches/05-patch-enforcing-recovery.patch"
    "${device_dir}/patches/06-patch-fbe-auth-token.patch"
    "${device_dir}/patches/07-patch-sideload-install-once.patch"
    "${device_dir}/patches/08-patch-enforcing-runtime.patch"
)

# X6885_PATCHES: all (default) | none | daftar nomor, mis. "01 02 07"
sel="${X6885_PATCHES:-all}"
if [[ "$sel" != "all" ]]; then
    filtered=()
    for p in "${patch_files[@]}"; do
        n="$(basename "$p")"; n="${n%%-*}"
        for w in $sel; do [[ "$sel" != "none" && "$n" == "$w" ]] && filtered+=("$p"); done
    done
    patch_files=("${filtered[@]}")
    unset filtered p n w
fi
unset sel
# X6885_NO_UE: 1 (default) = jangan build update_engine*, 0 = build (lihat device.mk)
export X6885_NO_UE="${X6885_NO_UE:-1}"
echo "[X6885] PATCHES=${X6885_PATCHES:-all} NO_UE=${X6885_NO_UE}"
echo "[X6885] rev update_engine: $(git -C "${workspace_root}/system/update_engine" log -1 --format='%h %cs' 2>/dev/null)"
echo "[X6885] rev system/core:   $(git -C "${workspace_root}/system/core" log -1 --format='%h %cs' 2>/dev/null)"
echo "[X6885] UpdateUsesSnapuserd di header libsnapshot: $(grep -rl UpdateUsesSnapuserd "${workspace_root}/system/core/fs_mgr/libsnapshot/include" 2>/dev/null | wc -l) file"
echo "[X6885] isi vendor/recovery: $(ls "${workspace_root}/vendor/recovery" 2>/dev/null | head -40 | tr '\n' ' ')"

export ALLOW_MISSING_DEPENDENCIES=true
export FOX_BUILD_DEVICE=X6885
export FOX_VIRTUAL_AB_DEVICE=1
export FOX_VENDOR_BOOT_RECOVERY=1
export FOX_INSTALLER_VENDOR_BOOT_RAMDISK_INSTALL=0
export FOX_BRANCH="16.0"
unset FOX_VENDOR_BOOT_POSTPROCESS_SCRIPT FOX_REFERENCE_VENDOR_BOOT_IMAGE
export FOX_USE_ZSTD_BINARY=1
export FOX_USE_NANO_EDITOR=1
export FOX_ENABLE_KERNELSU_SUPPORT=1

export FOX_USE_DMSETUP=1

legacy_patch="${device_dir}/patches/03-patch-vendor-boot-postprocess.patch"
if (cd "${workspace_root}" && patch -p1 -R --dry-run --silent < "${legacy_patch}" >/dev/null 2>&1); then
    (cd "${workspace_root}" && patch -p1 -R --silent < "${legacy_patch}") || return 1
fi
unset legacy_patch

failed_patches=()
patches_ok=true
for patch_file in "${patch_files[@]}"; do
    if [[ ! -f "${patch_file}" ]] || ! command -v patch >/dev/null 2>&1; then
        echo "[X6885] Missing patch or patch command: ${patch_file}"
        patches_ok=false
        failed_patches+=("$(basename "${patch_file}")")
        continue
    fi
    if [[ "$(basename "${patch_file}")" == "06-patch-fbe-auth-token.patch" ]] && \
       grep -q "Gatekeeper auth token accepted by keystore" "${workspace_root}/system/vold/Decrypt.cpp" 2>/dev/null; then
        echo "[X6885] Already applied $(basename "${patch_file}") (verified by signature)."
        continue
    fi
    if (cd "${workspace_root}" && patch -p1 -N --dry-run --silent < "${patch_file}" >/dev/null 2>&1); then
        if ! (cd "${workspace_root}" && patch -p1 -N --silent < "${patch_file}"); then
            patches_ok=false
            failed_patches+=("$(basename "${patch_file}")")
            continue
        fi
        echo "[X6885] Applied $(basename "${patch_file}")."
    elif (cd "${workspace_root}" && patch -p1 -R --dry-run --silent < "${patch_file}" >/dev/null 2>&1); then
        echo "[X6885] Already applied $(basename "${patch_file}")."
    else
        echo "[X6885] Patch does not apply: ${patch_file}"
        # X6885_DIAG: tampilkan hunk yang ditolak biar kelihatan di log
        (cd "${workspace_root}" && patch -p1 -N --dry-run < "${patch_file}") 2>&1 | head -80 | sed 's/^/[X6885]   /'
        patches_ok=false
        failed_patches+=("$(basename "${patch_file}")")
        continue
    fi
done

echo " patch gagal: ${failed_patches[*]:-tidak ada}"
if [[ "${patches_ok}" != true ]]; then
    unset device_dir workspace_root patch_files patch_file patches_ok
    return 1
fi
unset device_dir workspace_root patch_files patch_file patches_ok
