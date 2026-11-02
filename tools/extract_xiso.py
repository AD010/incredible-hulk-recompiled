"""Copies every file from an Xbox 360 disc image (XDVDFS) into a folder.

Handles plain XISO images and full XGD2/XGD3 "redump" images.
Usage: python tools/extract_xiso.py <image.iso> <out folder>
"""
import os
import struct
import sys

SECTOR = 2048
MAGIC = b"MICROSOFT*XBOX*MEDIA"
# Where the game partition starts in a full image: plain XISO, XGD2, XGD1, XGD3.
PARTITIONS = (0, 0xFD90000, 0x18300000, 0x2080000)


def find_partition(f):
    for base in PARTITIONS:
        f.seek(base + 32 * SECTOR)
        if f.read(len(MAGIC)) == MAGIC:
            return base
    raise SystemExit("not an Xbox 360 disc image")


def walk(f, base, sector, size, out, files):
    f.seek(base + sector * SECTOR)
    table = f.read(size)
    pending = [0]
    seen = set()
    while pending:
        off = pending.pop()
        if off in seen or off + 14 > len(table):
            continue
        seen.add(off)
        left, right, start, length, attr, name_len = struct.unpack_from("<HHIIBB", table, off)
        if left == 0xFFFF:  # padding at the end of a sector
            continue
        name = table[off + 14:off + 14 + name_len].decode("latin-1")
        if left:
            pending.append(left * 4)
        if right:
            pending.append(right * 4)
        path = os.path.join(out, name)
        if attr & 0x10:
            os.makedirs(path, exist_ok=True)
            if length:
                walk(f, base, start, length, path, files)
        else:
            files.append((path, base + start * SECTOR, length))


def main():
    image, out = sys.argv[1], sys.argv[2]
    with open(image, "rb") as f:
        base = find_partition(f)
        f.seek(base + 32 * SECTOR + len(MAGIC))
        root_sector, root_size = struct.unpack("<II", f.read(8))
        os.makedirs(out, exist_ok=True)
        files = []
        walk(f, base, root_sector, root_size, out, files)
        total = sum(n for _, _, n in files)
        done = 0
        for path, at, length in files:
            f.seek(at)
            with open(path, "wb") as o:
                left = length
                while left:
                    chunk = f.read(min(left, 16 << 20))
                    if not chunk:
                        raise SystemExit(f"image ends early in {path}")
                    o.write(chunk)
                    left -= len(chunk)
            done += length
        print(f"{len(files)} files, {total / 2**30:.2f} GB, partition at 0x{base:X}")


if __name__ == "__main__":
    main()
