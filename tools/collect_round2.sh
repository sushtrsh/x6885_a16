#!/system/bin/sh
# ROUND 2 - run ON the phone as root:  su -c "sh /sdcard/Download/collect_round2.sh"
# Output: /sdcard/x6885_round2.tar.gz  -> upload to the chat.
# Read-only: it only copies files and writes logs.
[ "$(id -u)" = "0" ] || { echo "Harus root: su -c \"sh $0\""; exit 1; }
DEST=/sdcard; [ -d "$DEST" ] || DEST=$PWD
W=$DEST/x6885_round2
rm -rf "$W"; mkdir -p "$W/rc" "$W/bin" "$W/lib64" "$W/app" "$W/touch" "$W/logs"

# ---- 1. init rc files for Trustonic / TEE / touch / keymint
for f in /vendor/etc/init/*; do
  case "$(basename $f)" in
    tee.rc|trustonic*.rc|vendor.trustonic*.rc|init.touch.rc|touch_boost.rc|*keymint*|*gatekeeper*|*secretkeeper*|*kmsetkey*) cp "$f" "$W/rc/";;
  esac
done

# ---- 2. every binary started by those rc files (service <name> <path> ...)
cat "$W"/rc/*.rc 2>/dev/null | grep -E '^service ' | while read a n p rest; do echo "$p"; done | sort -u > "$W/service_paths.txt"
for p in $(cat "$W/service_paths.txt"); do [ -f "$p" ] && cp "$p" "$W/bin/"; done
# scripts started via 'exec' / insmod helpers
for s in $(cat "$W"/rc/*.rc 2>/dev/null | grep -o -E '/vendor/[A-Za-z0-9_./-]+\.sh' | sort -u); do [ -f "$s" ] && cp "$s" "$W/touch/"; done
find /vendor /odm -name 'insmod_touch*' -type f -exec cp {} "$W/touch/" \; 2>/dev/null

# ---- 3. where do all kernel modules live? + touch modules wherever they are
find /vendor /odm /system /system_ext /vendor_dlkm /odm_dlkm /system_dlkm -name '*.ko' 2>/dev/null > "$W/ko_locations.txt"
for f in $(grep -i -E 'focaltech|adaptive|chsc|chipsemi|gt9|goodix|tui' "$W/ko_locations.txt"); do cp "$f" "$W/touch/"; done

# ---- 4. Trustonic trustlets / TAs / drivers (any path)
find /vendor /odm /system /system_ext -type f \( -name '*.tlbin' -o -name '*.tabin' -o -name '*.drbin' -o -name '*.tlcbin' -o -name '*.suid' \) 2>/dev/null > "$W/trustlets.txt"
find /vendor /odm -type d \( -iname 'mcRegistry' -o -iname 't-base*' -o -iname 'tbase*' -o -iname 'trustonic*' \) 2>/dev/null > "$W/trustonic_dirs.txt"
for f in $(cat "$W/trustlets.txt"); do d="$W/app$(dirname $f)"; mkdir -p "$d"; cp "$f" "$d/"; done

# ---- 5. library closure: names found as strings inside the binaries, resolved in /vendor/lib64
for pass in 1 2 3 4 5 6; do
  new=0
  for f in "$W"/bin/* "$W"/lib64/*; do
    [ -f "$f" ] || continue
    for so in $(grep -a -o -E '[A-Za-z0-9_.+-]+\.so' "$f" | sort -u); do
      if [ -f "/vendor/lib64/$so" ] && [ ! -f "$W/lib64/$so" ]; then cp "/vendor/lib64/$so" "$W/lib64/"; new=1; fi
    done
  done
  [ "$new" = "0" ] && break
done
# libs from /vendor/lib64/hw referenced by name patterns (keymint/gatekeeper impl)
for f in /vendor/lib64/hw/*keymint* /vendor/lib64/hw/*gatekeeper* /vendor/lib64/hw/*keymaster*; do [ -f "$f" ] && cp "$f" "$W/lib64/"; done

# ---- 6. runtime info: devices, SELinux contexts, input/touch bus, kernel log
getenforce > "$W/logs/selinux.txt" 2>&1
ls -lZ /dev 2>/dev/null | grep -i -E 'mobicore|mcd|trustonic|tee|tui|tui' > "$W/logs/dev_nodes.txt"
ls -lZ /vendor/bin/hw/*trustonic* /vendor/bin/hw/*keymint* /vendor/bin/*mobicore* /vendor/bin/*mcDriver* /vendor/bin/*tee* > "$W/logs/bin_contexts.txt" 2>&1
cat /proc/bus/input/devices > "$W/logs/input_devices.txt" 2>&1
{ for d in /sys/bus/spi/devices /sys/bus/spi/drivers /sys/bus/i2c/devices /sys/bus/i2c/drivers; do echo "## $d"; ls "$d" 2>&1; done; } > "$W/logs/buses.txt"
ps -A -o PID,NAME,LABEL 2>/dev/null | grep -i -E 'mobicore|tee|trustonic|keymint|gatekeeper|keystore' > "$W/logs/ps.txt"
dmesg 2>/dev/null | grep -i -E 'gt9896s|focaltech|ft3683|chsc|goodix|touch|mobicore|trustonic|mcDrv|tee' | tail -200 > "$W/logs/dmesg_filtered.txt"
getprop | grep -i -E 'trustonic|tee|mobicore|keymint|gatekeeper|touch|tp' > "$W/logs/props_filtered.txt"

cd "$DEST" && { tar czf x6885_round2.tar.gz x6885_round2 2>/dev/null || tar cf x6885_round2.tar x6885_round2; }
rm -rf "$W"
ls -l "$DEST"/x6885_round2.tar* && echo "SELESAI. Upload file di atas ke chat."
