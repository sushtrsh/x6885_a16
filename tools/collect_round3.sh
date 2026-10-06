#!/system/bin/sh
# ROUND 3 (small) - run ON the phone as root:  su -c "sh /sdcard/Download/collect_round3.sh"
# Finds 5 missing libraries by name, copies them. Output: /sdcard/x6885_round3.tar.gz
[ "$(id -u)" = "0" ] || { echo "Harus root: su -c \"sh $0\""; exit 1; }
DEST=/sdcard; [ -d "$DEST" ] || DEST=$PWD
W=$DEST/x6885_round3
rm -rf "$W"; mkdir -p "$W/lib64"; : > "$W/found.txt"
for n in android.hardware.common-V2-ndk.so android.hardware.security.rkp-V1-ndk.so \
         android.hardware.security.secureclock-V1-ndk.so android.hardware.security.sharedsecret-V1-ndk.so \
         libtneclient.so; do
  find /system /system_ext /vendor /odm /product /apex -name "$n" 2>/dev/null | while read p; do echo "$n $p" >> "$W/found.txt"; done
  p=$(find /system/lib64 /system_ext/lib64 /vendor/lib64 /odm/lib64 /product/lib64 -name "$n" 2>/dev/null | head -1)
  [ -z "$p" ] && p=$(find /apex -path '*lib64*' -name "$n" 2>/dev/null | head -1)
  [ -n "$p" ] && cp "$p" "$W/lib64/"
done
ls -l "$W/lib64" > "$W/copied.txt"
cd "$DEST" && { tar czf x6885_round3.tar.gz x6885_round3 2>/dev/null || tar cf x6885_round3.tar x6885_round3; }
cat "$W/copied.txt"; rm -rf "$W"
ls -l "$DEST"/x6885_round3.tar* && echo "SELESAI. Upload file di atas ke chat."
