# OrangeFox_Infinix X6885_a16

Unofficial device tree, Android 16 / MT6789

| Item | Value |
| --- | --- |
| Device | `X6885` |
| Platform | MT6789 / arm64 |
| Firmware | Android 16 / SDK 36 |
| Vendor security patch | `2026-08-01` |
| Kernel module ABI | `6.12.38-android16-5-gcc51d883045d-4k` |
| PLATFORM modules | 234 modules + 5 stock metadata files (dari vendor_boot stock) |
| Touch (recovery) | adaptive-ts (patched) + focaltech_ft3683g + chipsemi_chsc5xxx_old |

## Struktur tree

| Folder / file | Fungsi |
| --- | --- |
| `bootctrl/` | Boot control HAL MTK (`android.hardware.boot@1.2-mtkimpl`), akses UFS boot region lewat ioctl. Dipakai lewat `bootctrl.mt6789` di `device.mk`. |
| `create_pl_dev/` | Binary `create_pl_dev` + rc: bikin device `preloader_raw_a/b` di `/dev/block/mapper` dan symlink-nya. |
| `common/mt6789-vendor16/` | Config bersama keluarga MT6789 Android 16: `BoardConfig.mk`, `vendor_ramdisk.mk` (nyalin modul + fstab ke vendor ramdisk), dan sepolicy recovery. |
| `prebuilt/` | `dtb` dan 234 modul kernel stock + metadata modul. |
| `recovery/root/` | File yang masuk ramdisk recovery: fstab, rc, firmware, modul touch, binary vendor. |
| `patches/` | Patch ke source OrangeFox, di-apply otomatis oleh `vendorsetup.sh`. |
| `BoardConfig.mk`, `device.mk`, `twrp.mk`, `fox.mk`, `twrp_X6885.mk` | Config utama board, product, TWRP, dan OrangeFox. |

Tiga folder `bootctrl/`, `create_pl_dev/`, dan `common/` wajib ikut di-push ke repo,
karena `BoardConfig.mk` dan `device.mk` mereferensikannya.

