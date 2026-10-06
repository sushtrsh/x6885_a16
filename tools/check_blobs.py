#!/usr/bin/env python3
"""
check_blobs.py - verify every ELF in recovery/root/vendor/bin has all its DT_NEEDED
libraries available (in the tree, or in the small set the recovery base provides).
    python3 tools/check_blobs.py
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from elf_needed import needed

ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "recovery/root")
# libraries the Android 12.1 recovery build is expected to provide itself
BASE = {"libc.so", "libm.so", "libdl.so", "libc++.so", "liblog.so", "libbase.so", "libcutils.so",
        "libutils.so", "libbinder.so", "libbinder_ndk.so", "libhidlbase.so", "libselinux.so", "libcrypto.so"}
LIBDIRS = ["vendor/lib64", "system/lib64"]

def find(n):
    for d in LIBDIRS:
        p = os.path.join(ROOT, d, n)
        if os.path.exists(p): return p

bad = {}; queue = []
for d in ("vendor/bin", "vendor/bin/hw"):
    full = os.path.join(ROOT, d)
    if os.path.isdir(full):
        queue += [os.path.join(full, f) for f in os.listdir(full) if os.path.isfile(os.path.join(full, f))]
seen = set()
while queue:
    p = queue.pop()
    if p in seen: continue
    seen.add(p)
    try: deps = needed(p)
    except Exception as e: print("skip (not ELF):", p); continue
    for n in deps:
        q = find(n)
        if q: queue.append(q)
        elif n not in BASE: bad.setdefault(n, set()).add(os.path.basename(p))
if bad:
    print("UNRESOLVED libraries:")
    for n, who in sorted(bad.items()): print("  %-48s needed by %s" % (n, ", ".join(sorted(who))))
    sys.exit(1)
print("OK: all %d binaries/libs resolve (base libs assumed from the recovery build: %s)" % (len(seen), ", ".join(sorted(BASE))))
