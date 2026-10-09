# Fork notes (X6850 -> X6885)

## Diubah
- Semua identifier `X6850` -> `X6885` (BoardConfig, device.mk, twrp.mk, vendorsetup.sh, product makefile).
- `prebuilt/modules`: diganti 234 .ko + 5 file metadata dari vendor_boot stock dump
  (tree lama: 233 .ko dari varian lain). Beda utama: stock punya `nfc_i2c`,
  `tc_sc8548_charger`, `tc_sgm41516d`, `tc_water_detect`, `tran_soft_restart`;
  tree lama punya `st21nfc`, `tc_mt5728`, `tran_wireless_manager`, `tran_wireless_ta`.
- Touch recovery: `gt9916_common.ko` (Goodix) dibuang, `chipsemi_chsc5xxx_old.ko`
  ditambah (dari odm_dlkm stock; dtbo X6885 pakai focaltech ft3682g + chipsemi chct5560).
  Urutan insmod di `init.recovery.mt6789.rc`: adaptive-ts, focaltech, chipsemi.
- Firmware touch ditambah: `chipsemi_ts_fw.bin`, `focaltech_ts_fw_00.bin` (dari /odm/firmware stock).

## Sudah dicek cocok dengan dump
- `prebuilt/dtb` identik (SHA256) dengan dtb vendor_boot stock.
- vendor cmdline + bootconfig, header v4, `first_stage_ramdisk/fstab.mt6789` identik.
- `adaptive-ts.ko` di tree = modul stock yang sudah dipatch (recovery boot-mode mask di offset 0x5e80, 1 byte); hash sama.
- `focaltech_ft3683g.ko` identik dengan stock.

## Belum bisa dicek / belum teruji
- Dump tidak berisi partisi `vendor`: binary keymint/gatekeeper trustonic, mcDriverDaemon,
  libMcClient, mcRegistry (drbin/tlbin/tabin), firmware WiFi/BT di `recovery/root/vendor`
  masih bawaan tree X6850 dan tidak bisa diverifikasi ke X6885. Perlu dump `vendor`.
- `android.hardware.boot-service.mtk` dan `libverbose_abort_shim.so` juga tidak ada di dump.
- Patch `patches/*.patch` menyentuh source OrangeFox 14.1 (build/, bootable/recovery, system/vold, dll);
  belum dicoba apply karena source OrangeFox tidak ikut di sini.
- Driver chipsemi belum diuji di recovery (butuh tes di HP).
- `OF_MAINTAINER` di `fox.mk` masih bawaan tree asal, ganti sesuai nama kamu.
- Dua TA di `/odm/app/mcRegistry` (`03020000...tabin`, `511ead0a...tabin`) tidak ada di tree;
  rc `init.tee.rc` cuma menunjuk drbin di /vendor/app/mcRegistry, jadi belum dimasukkan.
