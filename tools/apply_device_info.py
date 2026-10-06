#!/usr/bin/env python3
"""
apply_device_info.py - feed the result of collect_device_info.sh into the tree.
    python3 tools/apply_device_info.py x6885_info.tar.gz   (or the extracted dir)
Applies: TW_MAX_BRIGHTNESS, super size, CPU temp path, touch modules
(+ deps, load order, modules.dep) and keymint/gatekeeper blobs. Idempotent.
"""
import os, re, shutil, sys, tarfile, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MOD = os.path.join(ROOT, "recovery/root/lib/modules")
BC = os.path.join(ROOT, "BoardConfig.mk")

def setvar(text, var, val):
    pat = re.compile(r"^(%s\s*:=).*$" % re.escape(var), re.M)
    if pat.search(text): return pat.sub(lambda m: "%s %s" % (m.group(1), val), text)
    return text.rstrip("\n") + "\n%s := %s\n" % (var, val)

def rd(p):
    return open(p, errors="ignore").read() if os.path.exists(p) else ""

def main(src, only_touch=None, skip_crypto=False):
    tmp = None
    if os.path.isfile(src):
        tmp = tempfile.mkdtemp(); tarfile.open(src).extractall(tmp)
        src = os.path.join(tmp, "x6885_info")
    log = []; bc = rd(BC)

    m = re.search(r"max_brightness=(\d+)", rd(src + "/sys/brightness.txt"))
    if m:
        mx = int(m.group(1)); bc = setvar(bc, "TW_MAX_BRIGHTNESS", mx)
        bc = setvar(bc, "TW_DEFAULT_BRIGHTNESS", max(1, mx // 2)); log.append("brightness max=%d" % mx)
    else: log.append("brightness: not found (kept 255)")

    m = re.search(r"(\d{9,})", rd(src + "/sys/super_size.txt"))
    if m:
        sz = int(m.group(1)); bc = setvar(bc, "BOARD_SUPER_PARTITION_SIZE", sz)
        bc = setvar(bc, "BOARD_MAIN_SIZE", sz - 4 * 1024 * 1024); log.append("super=%d" % sz)
    else: log.append("super size: not found (needs root; placeholder kept)")

    zones = [re.match(r"(thermal_zone\d+) type=(\S*)", l) for l in rd(src + "/sys/thermal.txt").splitlines()]
    zones = [z.groups() for z in zones if z]
    pick = next((z for z in zones if re.match(r"cpu", z[1], re.I)), None) or \
           next((z for z in zones if re.search(r"soc|mtktscpu", z[1], re.I)), None)
    if pick:
        bc = setvar(bc, "TW_CUSTOM_CPU_TEMP_PATH", "/sys/class/thermal/%s/temp" % pick[0])
        log.append("cpu temp=%s (%s)" % pick)
    open(BC, "w").write(bc)

    # ---- touch modules
    td = src + "/touch_modules"
    if os.path.isdir(td):
        have = set(os.listdir(MOD)); new = []
        for f in sorted(os.listdir(td)):
            if f.endswith(".ko") and f not in have and os.path.getsize(os.path.join(td, f)) > 0 \
                    and (only_touch is None or f in only_touch):
                shutil.copy(os.path.join(td, f), os.path.join(MOD, f)); new.append(f)
        if new:
            order = [os.path.basename(x.strip()) for x in rd(td + "/modules.load").splitlines() if x.strip()]
            # modules absent from the dlkm load list are dependency-only: load them first
            ordered = [x for x in new if x not in order] + [x for x in order if x in new]
            lr = os.path.join(MOD, "modules.load.recovery"); cur = rd(lr).split()
            with open(lr, "a") as fh:
                for x in ordered:
                    if x not in cur: fh.write(x + "\n")
            dep = os.path.join(MOD, "modules.dep"); dcur = rd(dep)
            with open(dep, "a") as fh:
                for line in rd(td + "/modules.dep").splitlines():
                    k, _, v = line.partition(":")
                    if os.path.basename(k.strip()) in new:
                        fh.write("/lib/modules/%s:%s\n" % (os.path.basename(k.strip()),
                                 "".join(" /lib/modules/" + os.path.basename(d) for d in v.split())))
            log.append("touch modules added: " + ", ".join(ordered))
        else: log.append("touch modules: nothing new")
    else: log.append("touch modules: none collected")

    # ---- crypto blobs
    cd = src + "/crypto"; n = 0
    if skip_crypto: cd = "/nonexistent"; log.append("crypto: skipped (--skip-crypto)")
    for sub, dst in [("bin_hw", "vendor/bin/hw"), ("lib64", "vendor/lib64"), ("init", "system/etc/init")]:
        d = os.path.join(cd, sub)
        if not os.path.isdir(d): continue
        for f in os.listdir(d):
            out = os.path.join(ROOT, "recovery/root", dst); os.makedirs(out, exist_ok=True)
            shutil.copy(os.path.join(d, f), os.path.join(out, f))
            os.chmod(os.path.join(out, f), 0o755 if sub == "bin_hw" else 0o644); n += 1
    if not skip_crypto: log.append("crypto blobs copied: %d" % n)
    print("\n".join("* " + x for x in log))
    if tmp: shutil.rmtree(tmp)

if __name__ == "__main__":
    import argparse
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[1])
    ap.add_argument("src"); ap.add_argument("--skip-crypto", action="store_true")
    ap.add_argument("--touch", help="comma list of .ko files to add (default: all collected)")
    a = ap.parse_args()
    main(a.src, set(a.touch.split(",")) if a.touch else None, a.skip_crypto)
