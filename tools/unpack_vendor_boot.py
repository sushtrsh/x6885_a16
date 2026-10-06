#!/usr/bin/env python3
"""
unpack_vendor_boot.py - dependency-free vendor_boot (header v3/v4) unpacker.

Used to refresh this device tree from a new stock vendor_boot.img:
    python3 tools/unpack_vendor_boot.py vendor_boot.img out_dir

Produces in out_dir:
    header.txt            parsed header (offsets, cmdline, sizes)
    dtb.img               DTB section, byte-exact (DT table or raw DTB)
    bootconfig.txt        bootconfig section (v4)
    ramdisk_<i>_<name>/   each vendor ramdisk fragment, extracted
Supports LZ4-legacy, gzip and uncompressed fragments (newc cpio).
"""
import gzip, os, stat, struct, sys

LZ4_LEGACY = bytes.fromhex("02214c18")

def lz4_block(src):
    out = bytearray(); i = 0; n = len(src)
    while i < n:
        t = src[i]; i += 1
        ll = t >> 4
        if ll == 15:
            while True:
                b = src[i]; i += 1; ll += b
                if b != 255: break
        out += src[i:i + ll]; i += ll
        if i >= n: break
        off = src[i] | (src[i + 1] << 8); i += 2
        ml = t & 15
        if ml == 15:
            while True:
                b = src[i]; i += 1; ml += b
                if b != 255: break
        ml += 4
        s = len(out) - off
        if off >= ml: out += out[s:s + ml]
        else:
            for k in range(ml): out.append(out[s + k])
    return bytes(out)

def decompress(d):
    if d[:4] == LZ4_LEGACY:
        i = 4; out = []
        while i < len(d):
            if d[i:i + 4] == LZ4_LEGACY: i += 4; continue
            sz, = struct.unpack_from("<I", d, i); i += 4
            out.append(lz4_block(d[i:i + sz])); i += sz
        return b"".join(out)
    if d[:2] == b"\x1f\x8b": return gzip.decompress(d)
    if d[:6] == b"070701": return d
    raise ValueError("unknown ramdisk compression: " + d[:4].hex())

def cpio_extract(d, dest):
    i = 0; n = 0
    while True:
        assert d[i:i + 6] == b"070701", "bad cpio magic at %d" % i
        f = [int(d[i + 6 + 8 * k:i + 14 + 8 * k], 16) for k in range(13)]
        mode, fs, nsz = f[1], f[6], f[11]
        name = d[i + 110:i + 110 + nsz - 1].decode()
        i = (i + 110 + nsz + 3) & ~3
        data = d[i:i + fs]; i = (i + fs + 3) & ~3
        if name == "TRAILER!!!": break
        p = os.path.join(dest, name)
        if stat.S_ISDIR(mode): os.makedirs(p, exist_ok=True)
        elif stat.S_ISLNK(mode):
            os.makedirs(os.path.dirname(p) or ".", exist_ok=True)
            if os.path.lexists(p): os.remove(p)
            os.symlink(data.decode(), p)
        elif stat.S_ISREG(mode):
            os.makedirs(os.path.dirname(p) or ".", exist_ok=True)
            open(p, "wb").write(data); os.chmod(p, (mode & 0o7777) | 0o200)
        n += 1
    return n

def main(img, out):
    d = open(img, "rb").read()
    assert d[:8] == b"VNDRBOOT", "not a vendor_boot image"
    hv, ps, ka, ra, vrs = struct.unpack_from("<5I", d, 8)
    cmd = d[28:28 + 2048].split(b"\0")[0].decode()
    o = 28 + 2048
    tags, = struct.unpack_from("<I", d, o); o += 4
    name = d[o:o + 16].split(b"\0")[0].decode(); o += 16
    hs, dtbs = struct.unpack_from("<2I", d, o); o += 8
    dtba, = struct.unpack_from("<Q", d, o); o += 8
    al = lambda x: (x + ps - 1) // ps * ps
    os.makedirs(out, exist_ok=True)
    hdr = ["header_version=%d" % hv, "page_size=%d" % ps, "kernel_addr=0x%08x" % ka,
           "ramdisk_addr=0x%08x" % ra, "tags_addr=0x%08x" % tags, "dtb_addr=0x%08x" % dtba,
           "vendor_ramdisk_size=%d" % vrs, "dtb_size=%d" % dtbs, "header_size=%d" % hs,
           "board_name=%r" % name, "vendor_cmdline=%r" % cmd]
    rd_off = al(hs); dtb_off = rd_off + al(vrs)
    frags = [(0, vrs, 1, "")]
    if hv >= 4:
        vrts, vrn, vre, bcs = struct.unpack_from("<4I", d, o)
        vrt_off = dtb_off + al(dtbs); bc_off = vrt_off + al(vrts)
        frags = []
        for i in range(vrn):
            e = d[vrt_off + i * vre: vrt_off + (i + 1) * vre]
            sz, off, typ = struct.unpack_from("<3I", e, 0)
            frags.append((off, sz, typ, e[12:44].split(b"\0")[0].decode()))
        open(os.path.join(out, "bootconfig.txt"), "wb").write(d[bc_off:bc_off + bcs])
        hdr.append("bootconfig_size=%d" % bcs)
    open(os.path.join(out, "dtb.img"), "wb").write(d[dtb_off:dtb_off + dtbs])
    for i, (off, sz, typ, nm) in enumerate(frags):
        raw = d[rd_off + off: rd_off + off + sz]
        dest = os.path.join(out, "ramdisk_%d_%s" % (i, nm or "platform"))
        cnt = cpio_extract(decompress(raw), dest)
        hdr.append("fragment[%d]: type=%d name=%r compressed=%d files=%d" % (i, typ, nm, sz, cnt))
    open(os.path.join(out, "header.txt"), "w").write("\n".join(hdr) + "\n")
    print("\n".join(hdr))

if __name__ == "__main__":
    if len(sys.argv) != 3: sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
