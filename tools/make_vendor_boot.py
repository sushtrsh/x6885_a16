#!/usr/bin/env python3
"""
make_vendor_boot.py - build a flashable vendor_boot.img by swapping ONLY the "recovery"
ramdisk fragment of the STOCK vendor_boot.img. Everything else stays byte-identical:
header, platform fragment (normal Android boot), DTB, bootconfig, partition size and the
stock AVB footer/vbmeta blob (relocated if the content grew).

    python3 tools/make_vendor_boot.py STOCK_vendor_boot.img NEW_RAMDISK OUT.img

NEW_RAMDISK is either
  * a raw compressed ramdisk (e.g. ramdisk-recovery.img from the OrangeFox build), or
  * a vendor_boot.img produced by the build (its recovery fragment, or its only fragment, is used).
It is NOT re-signed: this tool never touches vbmeta, and nothing here disables verification.
"""
import struct, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from unpack_vendor_boot import decompress

PART = 67108864          # stock vendor_boot partition size (64 MiB)
al = lambda x, p: (x + p - 1) // p * p

def parse(d):
    assert d[:8] == b"VNDRBOOT", "not a vendor_boot image"
    hv, ps = struct.unpack_from("<II", d, 8)
    assert hv == 4, "need header v4, got %d" % hv
    vrs, = struct.unpack_from("<I", d, 24)
    hs, dtbs = struct.unpack_from("<2I", d, 2096)
    vrts, vrn, vre, bcs = struct.unpack_from("<4I", d, 2112)
    rd, dtb = al(hs, ps), None
    dtb = rd + al(vrs, ps); tbl = dtb + al(dtbs, ps); bc = tbl + al(vrts, ps)
    frags = []
    for i in range(vrn):
        e = d[tbl + i * vre: tbl + (i + 1) * vre]
        sz, off, typ = struct.unpack_from("<3I", e, 0)
        frags.append(dict(entry=bytearray(e), type=typ, name=e[12:44].split(b"\0")[0].decode(),
                          data=d[rd + off: rd + off + sz]))
    return dict(ps=ps, hdr=bytearray(d[:ps]), dtb=d[dtb:dtb + dtbs], bc=d[bc:bc + bcs], frags=frags,
                vre=vre, end=bc + al(bcs, ps))

def avb_footer(d):
    f = d[-64:]
    if f[:4] != b"AVBf": return None
    _, _, orig, vbo, vbs = struct.unpack(">IIQQQ", f[4:36])
    return dict(orig=orig, off=vbo, size=vbs, blob=d[vbo:vbo + vbs], raw=bytearray(f))

def load_new(path):
    d = open(path, "rb").read()
    if d[:8] == b"VNDRBOOT":
        fr = parse(d)["frags"]
        pick = next((f for f in fr if f["type"] == 2 or f["name"] == "recovery"), None) or \
               (fr[0] if len(fr) == 1 else max(fr, key=lambda f: len(f["data"])))
        print("[*] using fragment name=%r type=%d from build image (%d bytes)" % (pick["name"], pick["type"], len(pick["data"])))
        return pick["data"]
    return d

def main(stock_p, new_p, out_p):
    stock = open(stock_p, "rb").read()
    s = parse(stock); foot = avb_footer(stock); new = load_new(new_p)
    # sanity: the new ramdisk must unpack to something that looks like a recovery
    raw = decompress(new)
    assert raw[:6] == b"070701", "ramdisk is not a newc cpio"
    for need in (b"system/bin/recovery", b"init"):
        assert need in raw[:len(raw)], "ramdisk lacks %r - is this really the recovery ramdisk?" % need
    tgt = [i for i, f in enumerate(s["frags"]) if f["type"] == 2 or f["name"] == "recovery"]
    assert len(tgt) == 1, "stock image must have exactly one recovery fragment"
    ramdisk = bytearray(); table = bytearray()
    for i, f in enumerate(s["frags"]):
        data = new if i == tgt[0] else f["data"]
        e = bytearray(f["entry"]); struct.pack_into("<II", e, 0, len(data), len(ramdisk))
        table += e; ramdisk += data
        print("  fragment %d %-9r type=%d %9d bytes%s" % (i, f["name"], f["type"], len(data), "  <- REPLACED" if i == tgt[0] else ""))
    ps = s["ps"]; hdr = s["hdr"]; struct.pack_into("<I", hdr, 24, len(ramdisk))
    out = bytearray(hdr)
    for blob in (bytes(ramdisk), s["dtb"], bytes(table), s["bc"]):
        out += blob + b"\0" * (al(len(blob), ps) - len(blob))
    n = len(out)
    if foot:
        need = n + al(foot["size"], 4096) + 64
        assert need <= PART, "too big: %d + vbmeta + footer > %d" % (n, PART)
        vb = bytearray(out); vb += b"\0" * (n - len(vb))
        res = bytearray(out) + b"\0" * (PART - len(out))
        res[n:n + foot["size"]] = foot["blob"]
        f = bytearray(foot["raw"]); struct.pack_into(">QQ", f, 12, n, n)   # original_image_size, vbmeta_offset
        res[-64:] = f
        print("[*] stock AVB footer kept (vbmeta blob moved %d -> %d)" % (foot["off"], n))
    else:
        assert n <= PART, "image exceeds partition"
        res = bytearray(out) + b"\0" * (PART - n)
        print("[!] stock image had no AVB footer; none added")
    open(out_p, "wb").write(res)
    print("[OK] wrote %s: %d bytes (content %d, free %d)" % (out_p, len(res), n, PART - n - (al(foot['size'],4096)+64 if foot else 0)))

if __name__ == "__main__":
    if len(sys.argv) != 4: sys.exit(__doc__)
    try: main(*sys.argv[1:])
    except AssertionError as e: sys.exit("ERROR: %s" % e)
