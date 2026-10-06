import struct,sys
def needed(path):
    d=open(path,"rb").read()
    assert d[:4]==b"\x7fELF" and d[4]==2
    shoff,=struct.unpack_from("<Q",d,0x28); shentsize,shnum,shstrndx=struct.unpack_from("<HHH",d,0x3a)
    secs=[struct.unpack_from("<IIQQQQIIQQ",d,shoff+i*shentsize) for i in range(shnum)]
    dyn=[s for s in secs if s[1]==6]
    out=[]
    for s in dyn:
        strtab=secs[s[6]]; so=strtab[4]
        for i in range(s[5]//16):
            tag,val=struct.unpack_from("<qQ",d,s[4]+i*16)
            if tag==1:
                e=d.index(b"\0",so+val); out.append(d[so+val:e].decode())
    return out
if __name__=="__main__":
    for p in sys.argv[1:]: print(p,needed(p))
