#!/usr/bin/env bash
# Run on a PC with adb, phone booted into Android with USB debugging on.
#   ./tools/collect_device_info.sh
# Works without root, but more is collected with root (Magisk/KernelSU su).
# Result: x6885_info.tar.gz  -> send it back / run tools/apply_device_info.py on it.
set -u
OUT=x6885_info
rm -rf "$OUT"; mkdir -p "$OUT"/{touch_modules,crypto/bin_hw,crypto/lib64,crypto/init,sys}
adb get-state >/dev/null 2>&1 || { echo "no adb device"; exit 1; }

if adb shell 'su -c id' 2>/dev/null | grep -q uid=0; then SU="su -c"; echo "[root: yes]"; else SU=""; echo "[root: no - partial info]"; fi
sh_() { adb shell "$SU \"$*\"" 2>/dev/null | tr -d '\r'; }
sh0() { adb shell "$*" 2>/dev/null | tr -d '\r'; }

sh0 getprop                                  > "$OUT/props.txt"
sh0 lsmod                                    > "$OUT/lsmod.txt"
sh0 cat /proc/partitions                     > "$OUT/proc_partitions.txt"
sh0 'ls -l /dev/block/by-name'               > "$OUT/by_name.txt"
sh0 'ls /dev/block'                          > "$OUT/dev_block.txt"
sh0 'ls /sys/class/leds'                     > "$OUT/sys/leds.txt"
sh0 'ls /sys/class/input'                    > "$OUT/sys/input.txt"
for f in /sys/class/leds/lcd-backlight/max_brightness /sys/class/leds/lcd-backlight/brightness; do
  echo "$f=$(sh_ cat $f)"; done                > "$OUT/sys/brightness.txt"
for z in $(sh0 'ls /sys/class/thermal' | grep thermal_zone); do
  echo "$z type=$(sh0 cat /sys/class/thermal/$z/type) temp=$(sh0 cat /sys/class/thermal/$z/temp)"
done                                         > "$OUT/sys/thermal.txt"
sh_ 'blockdev --getsize64 /dev/block/by-name/super' > "$OUT/sys/super_size.txt"
sh0 'ls /vendor_dlkm/lib/modules'            > "$OUT/vendor_dlkm_modules.txt"
sh_ 'ls /vendor/bin/hw'                      > "$OUT/vendor_bin_hw.txt"
sh_ 'ls /vendor/etc/init'                    > "$OUT/vendor_etc_init.txt"
sh_ 'ls /vendor/lib64'                       > "$OUT/vendor_lib64.txt"
sh_ 'ls /vendor/lib64/hw'                    > "$OUT/vendor_lib64_hw.txt"

# ---- touch modules: pull candidates + their load/dep lists
TP='goodix|gt9|gtx|touch|tp_|_tp|tpd|fts|nvt|novatek|ilitek|focaltech|chipone|himax|synaptics|tcm'
grep -i -E "$TP" "$OUT/vendor_dlkm_modules.txt" | grep '\.ko$' > "$OUT/touch_candidates.txt"
for m in $(cat "$OUT/touch_candidates.txt"); do
  adb pull "/vendor_dlkm/lib/modules/$m" "$OUT/touch_modules/" >/dev/null 2>&1 || {
    sh_ "cat /vendor_dlkm/lib/modules/$m" > "$OUT/touch_modules/$m"; }
done
for f in modules.load modules.dep; do
  adb pull "/vendor_dlkm/lib/modules/$f" "$OUT/touch_modules/" >/dev/null 2>&1; done
# pull missing dependencies (3 passes) using the dlkm modules.dep
for pass in 1 2 3; do
  for f in "$OUT"/touch_modules/*.ko; do
    [ -f "$f" ] || continue
    b=$(basename "$f")
    line=$(grep -E "(^|/)$b:" "$OUT/touch_modules/modules.dep" 2>/dev/null | head -1)
    for d in ${line#*:}; do
      db=$(basename "$d")
      [ -f "$OUT/touch_modules/$db" ] || adb pull "/vendor_dlkm/lib/modules/$db" "$OUT/touch_modules/" >/dev/null 2>&1
    done
  done
done
# which touch modules are actually loaded right now
grep -i -E "$TP" "$OUT/lsmod.txt" > "$OUT/touch_loaded.txt"

# ---- crypto (keymint / gatekeeper) - root needed to read most of /vendor
KM='keymint|keymaster|gatekeeper|kmsetkey|trustonic|isee|teei|tee|mc|km_|keystore'
grep -i -E 'keymint|keymaster|gatekeeper' "$OUT/vendor_bin_hw.txt" > "$OUT/crypto/services.txt"
for s in $(cat "$OUT/crypto/services.txt"); do
  sh_ "cat /vendor/bin/hw/$s" > "$OUT/crypto/bin_hw/$s"; done
for r in $(grep -i -E 'keymint|keymaster|gatekeeper' "$OUT/vendor_etc_init.txt"); do
  sh_ "cat /vendor/etc/init/$r" > "$OUT/crypto/init/$r"; done
for l in $(grep -i -E "$KM" "$OUT/vendor_lib64.txt" | grep '\.so$'); do
  sh_ "cat /vendor/lib64/$l" > "$OUT/crypto/lib64/$l"; done
find "$OUT/crypto" -type f -size 0 -delete   # drop unreadable (no-root) files

tar czf "$OUT.tar.gz" "$OUT" && echo "done -> $OUT.tar.gz ($(du -h $OUT.tar.gz | cut -f1))"
echo "touch candidates: $(wc -l < $OUT/touch_candidates.txt)  crypto services: $(wc -l < $OUT/crypto/services.txt)"
