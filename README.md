# OrangeFox device tree - Infinix X6885 (MT6789)

Recovery-in-`vendor_boot` tree generated from the stock `vendor_boot.img`
(Android 16, build `BP2A.250605.031.A3`, `X6885-16.3.0.145`).

| | |
|---|---|
| Device | Infinix X6885 (`Infinix-X6885`, board `x6885_h8923`) |
| SoC | MediaTek MT6789 (Helio G99 family), arm64 only |
| Kernel | GKI 6.12.38-android16, 4K pages (lives in `boot`, not touched) |
| Layout | A/B + Virtual A/B, dynamic partitions (`super`), no `recovery` partition |
| vendor_boot | header v4, 64 MiB, platform + "recovery" ramdisk fragments, DT table, bootconfig |
| Display | 1080x2400, density 420, `BGRA_8888` |
| Encryption | FBE `aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized` + metadata encryption |

## Build with carlodandan/OrangeFox-Action-Builder

Push the **contents of this folder** to the root of your own GitHub repo, then run
the *OrangeFox - Build* workflow with:

| Input | Value |
|---|---|
| MANIFEST_BRANCH | `12.1` (**not** 11.0: boot header v4 needs 12.1) |
| DEVICE_TREE | URL of your repo |
| DEVICE_TREE_BRANCH | your branch (e.g. `main`) |
| DEVICE_PATH | `device/infinix/X6885` (must match `DEVICE_PATH` in BoardConfig.mk) |
| DEVICE_NAME | `X6885` |
| BUILD_TARGET | `vendorboot` |

The builder runs `lunch twrp_X6885-eng && mka adbd vendorbootimage`.
Output: `out/target/product/X6885/OrangeFox*.img`.

Before the first build set `OF_MAINTAINER` in `vendorsetup.sh` (OrangeFox variables are exported there, using fox_12.1 names).

## Flash (read all of it first)

**Do NOT patch/flash vbmeta with `--disable-verity --disable-verification` and do NOT flash the raw
image produced by the build.** Another X6885 tree (sushtrshhh/twrp_x6885) reports that this Transsion
firmware ("P7 anti-crack") answers unsigned full images / patched vbmeta with a red "Unauthorized Repair"
screen and a deliberate soft-brick. This is a single-source report and not verified here, but the downside
is a soft-brick, so the safe path below only replaces the *recovery* ramdisk fragment of the STOCK image.

The stock `vendor_boot` has two ramdisk fragments: *platform* (used for normal Android boot, ~29.7 MB) and
*recovery*. `tools/make_vendor_boot.py` keeps everything of the stock image (header, platform fragment, DTB,
bootconfig, 64 MiB size, AVB footer + vbmeta blob) and swaps only the recovery fragment:

```
python3 tools/make_vendor_boot.py stock_vendor_boot.img ramdisk-recovery.img vendor_boot_fox.img
fastboot flash vendor_boot vendor_boot_fox.img
fastboot reboot recovery
```
`ramdisk-recovery.img` is the OrangeFox ramdisk from the build (`out/target/product/X6885/`). The tool also
accepts the build's `vendor_boot.img` as input and uses its recovery fragment.
It refuses ramdisks that do not look like a recovery or that do not fit (partition is 64 MiB; the recovery
fragment can be at most about 37 MB).

Always keep the stock `vendor_boot.img` and `boot.img`. If anything goes wrong, flash the stock `vendor_boot.img` back.
The tool does not re-sign anything. Whether the bootloader accepts the swapped image is NOT verified.

## What is verified vs. not

Verified from the stock image (see comments `[stock]` in BoardConfig.mk): boot header
addresses/offsets, page size, vendor cmdline, bootconfig, partition size, DTB (byte-exact),
kernel module lists (`modules.load.recovery`, `modules.dep`; the modules themselves stay in the stock
platform fragment), both stock first-stage fstabs, pixel format, screen size/density, encryption flags, USB init.

**Status:** the tree compiles on fox_12.1 (GitHub Actions run, vendorbootimage target). It has *not* been booted
on a device. Open items:

* **Touch** - the DTB has a Goodix touch node but the driver is not in `vendor_boot`
  (it is in `vendor_dlkm` or built in). Find it in Android with
  `ls /vendor_dlkm/lib/modules | grep -i -E "goodix|gt9|touch"`, copy the `.ko` (and its
  dependencies) into `recovery/root/lib/modules/` and append them to `modules.load.recovery`.
  Until then use volume keys / adb.
* **Decryption of /data** - flags are set, but keymint/gatekeeper services and their
  libraries from `/vendor` must be added; the stock Android 16 stack (AIDL keymint 7.0) is
  much newer than the Android 12.1 recovery base, so this is the hardest item.
* **A/B slot control** - stock uses an AIDL boot HAL; the 12.1 recovery talks HIDL. Slot
  switching inside the recovery may not work.
* `TW_MAX_BRIGHTNESS`, `BOARD_SUPER_PARTITION_SIZE` (placeholder, build-time only),
  SD card node and OTG storage: please verify on the device.
* Flashlight / vibrator / thermal paths are intentionally not set (not derivable from the image).

## Finishing the open items (touch, decryption, brightness, super size)

With the phone booted in Android (USB debugging on, root optional but recommended):

```
./tools/collect_device_info.sh                    # -> x6885_info.tar.gz
python3 tools/apply_device_info.py x6885_info.tar.gz
```
The second step sets `TW_MAX_BRIGHTNESS`, the super size and CPU temp path, adds the touch
modules (with dependencies, load order and `modules.dep`), and copies keymint/gatekeeper
blobs into `recovery/root`. Commit, rebuild. Crypto blobs and rc files are copied as-is:
review them if decryption still fails (SELinux labels and missing libraries are the usual cause).

**No PC?** On a rooted phone run `su -c "sh /sdcard/Download/collect_on_device.sh"`
(Termux or any root terminal). It writes `/sdcard/x6885_info.tar.gz`, same format as above.

### Status of the data collected from a real X6885 (round 1)

* Applied: `TW_MAX_BRIGHTNESS=5119`, super size `12934782976`, CPU temp `thermal_zone1`, touch `gt9896s.ko` + `tui-common.ko`
  (Goodix SPI; the driver Android has loaded; all its dependencies are already in vendor_boot, vermagic matches).
* Touch caveat: the phone also loads `focaltech_ft3683g` and `chipsemi_chsc5xxx_old` (`ro.tran.tp_switch.support=1`,
  i.e. second-source touch panels). Which IC your unit uses is checked in round 2 (`logs/input_devices.txt`).
* NOT applied yet: crypto blobs. The keymint/gatekeeper services only start after the **Trustonic** daemon (`mobicore`)
  sets `ro.vendor.trustonic.ready`, so the daemon, `tee-service`, trustlets and their libraries are needed too:
  run `tools/collect_round2.sh` (on-device, root) and send `x6885_round2.tar.gz`.

### Round 2 results (applied)

* Touch IC confirmed: **GT9896S** (SPI `spi1.0`, driver `GT9896S`). Only `gt9896s.ko` + `tui-common.ko` are loaded in recovery.
* Decryption stack is **Trustonic TEE**. Installed in `recovery/root`: `mcDriverDaemon`, `vendor.trustonic.tee-service`,
  keymint 3.0 + gatekeeper services, their vendor libraries, a minimal `/vendor/app/mcRegistry` (14 files, 0.8 MB: the drivers the
  daemon loads + keymint/gatekeeper/keybox trustlets) and `system/etc/init/trustonic_recovery.rc` (mount persist at
  `/mnt/vendor/persist`, start `mobicore`, then keymint/gatekeeper when `ro.vendor.trustonic.ready=true`).
  The full 66 MB registry is deliberately NOT included (vendor_boot partition is 64 MiB).
* Round 3 delivered the last 5 libraries (`android.hardware.common-V2-ndk`, `rkp-V1-ndk`, `secureclock-V1-ndk`,
  `sharedsecret-V1-ndk`, `libtneclient`); `python3 tools/check_blobs.py` now reports every binary as resolved
  (libc/libc++/liblog/libbase/libcutils/libutils/libbinder(_ndk)/libhidlbase/libselinux/libcrypto are expected from the recovery build).
* Not replicated: `mtk_storageproxyd` (RPMB proxy) and SELinux labels. Services use `seclabel u:r:recovery:s0` and
  run as root. If decryption fails, the first things to read are `logcat`/`dmesg | grep -i -E "mobicore|trustonic|keymint"` from the recovery.

## Refreshing from new firmware

```
python3 tools/unpack_vendor_boot.py vendor_boot.img out/
cp out/dtb.img prebuilt/dtb.img
# modules: the stock platform fragment already has them; the tree only ships modules.load.recovery,
# modules.dep and the touch modules (gt9896s.ko, tui-common.ko). Re-check that every entry of the new
# modules.load.recovery exists in out/ramdisk_0_platform/lib/modules or in recovery/root/lib/modules.
cp out/ramdisk_0_platform/first_stage_ramdisk/fstab.mt6789 recovery/root/first_stage_ramdisk/
cp out/ramdisk_1_recovery/first_stage_ramdisk/fstab.emmc  recovery/root/first_stage_ramdisk/
```
Kernel modules in the stock fragment must match the kernel in `boot` exactly (vermagic
`6.12.38-android16-5-gcc51d883045d-4k`) - always refresh them together with `boot`.
