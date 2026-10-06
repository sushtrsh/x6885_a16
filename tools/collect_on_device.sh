#!/system/bin/sh
# Run ON the phone as root (Termux: su -c "sh /sdcard/Download/collect_on_device.sh").
# Output: /sdcard/x6885_info.tar.gz  (same layout as collect_device_info.sh)
[ "$(id -u)" = "0" ] || { echo "Harus root: su -c \"sh $0\""; exit 1; }
DEST=/sdcard; [ -d "$DEST" ] || DEST=$PWD
W=$DEST/x6885_info
rm -rf "$W"; mkdir -p "$W/touch_modules" "$W/sys" "$W/crypto/bin_hw" "$W/crypto/lib64" "$W/crypto/init"

getprop > "$W/props.txt"
lsmod > "$W/lsmod.txt" 2>&1
cat /proc/partitions > "$W/proc_partitions.txt"
ls -l /dev/block/by-name > "$W/by_name.txt" 2>&1
ls /dev/block > "$W/dev_block.txt"
ls /sys/class/leds > "$W/sys/leds.txt" 2>&1
ls /sys/class/input > "$W/sys/input.txt" 2>&1
{ for f in max_brightness brightness; do
    echo "/sys/class/leds/lcd-backlight/$f=$(cat /sys/class/leds/lcd-backlight/$f 2>/dev/null)"; done; } > "$W/sys/brightness.txt"
for z in /sys/class/thermal/thermal_zone*; do
  echo "$(basename $z) type=$(cat $z/type 2>/dev/null) temp=$(cat $z/temp 2>/dev/null)"
done > "$W/sys/thermal.txt"
blockdev --getsize64 /dev/block/by-name/super > "$W/sys/super_size.txt" 2>&1
ls /vendor_dlkm/lib/modules > "$W/vendor_dlkm_modules.txt" 2>&1
ls /vendor/bin/hw > "$W/vendor_bin_hw.txt" 2>&1
ls /vendor/etc/init > "$W/vendor_etc_init.txt" 2>&1
ls /vendor/lib64 > "$W/vendor_lib64.txt" 2>&1
ls /vendor/lib64/hw > "$W/vendor_lib64_hw.txt" 2>&1

# ---- touch modules + dependencies
TP='goodix|gt9|gtx|touch|tp_|_tp|tpd|fts|nvt|novatek|ilitek|focaltech|chipone|himax|synaptics|tcm'
M=/vendor_dlkm/lib/modules
grep -i -E "$TP" "$W/vendor_dlkm_modules.txt" | grep '\.ko$' > "$W/touch_candidates.txt"
for m in $(cat "$W/touch_candidates.txt"); do cp "$M/$m" "$W/touch_modules/" 2>/dev/null; done
cp "$M/modules.load" "$M/modules.dep" "$W/touch_modules/" 2>/dev/null
for pass in 1 2 3; do
  for f in "$W"/touch_modules/*.ko; do
    [ -f "$f" ] || continue
    b=$(basename "$f")
    line=$(grep -E "(^|/)$b:" "$W/touch_modules/modules.dep" 2>/dev/null | head -1)
    for d in ${line#*:}; do
      db=$(basename "$d"); [ -f "$W/touch_modules/$db" ] || cp "$M/$db" "$W/touch_modules/" 2>/dev/null
    done
  done
done
grep -i -E "$TP" "$W/lsmod.txt" > "$W/touch_loaded.txt"

# ---- crypto blobs
KM='keymint|keymaster|gatekeeper|kmsetkey|trustonic|isee|teei|tee|mc|km_|keystore'
grep -i -E 'keymint|keymaster|gatekeeper' "$W/vendor_bin_hw.txt" > "$W/crypto/services.txt"
for s in $(cat "$W/crypto/services.txt"); do cp /vendor/bin/hw/$s "$W/crypto/bin_hw/"; done
for r in $(grep -i -E 'keymint|keymaster|gatekeeper' "$W/vendor_etc_init.txt"); do cp /vendor/etc/init/$r "$W/crypto/init/"; done
for l in $(grep -i -E "$KM" "$W/vendor_lib64.txt" | grep '\.so$'); do cp /vendor/lib64/$l "$W/crypto/lib64/"; done

cd "$DEST" && { tar czf x6885_info.tar.gz x6885_info 2>/dev/null || tar cf x6885_info.tar x6885_info; }
rm -rf "$W"
ls -l "$DEST"/x6885_info.tar* && echo "SELESAI. Upload file di atas ke chat."
