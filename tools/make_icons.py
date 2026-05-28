#!/usr/bin/env python3
"""Génère les icônes PNG de l'app (fond teal + ticket blanc) sans dépendance externe."""
import struct
import zlib
import os

TEAL = (15, 118, 110)      # fond
PAPER = (245, 247, 248)    # ticket
INK = (120, 132, 138)      # lignes du ticket
ACCENT = (15, 118, 110)


def rounded(x, y, w, h, r):
    """Retourne True si (x,y) est dans le rectangle (0..w,0..h) à coins arrondis r."""
    if r <= 0:
        return 0 <= x < w and 0 <= y < h
    cx = min(max(x, r), w - r)
    cy = min(max(y, r), h - r)
    dx = x - cx
    dy = y - cy
    return dx * dx + dy * dy <= r * r


def make(size):
    px = bytearray()
    pad = size // 10
    pw = size - 2 * pad          # largeur ticket
    px0, py0 = pad, pad
    # lignes horizontales du ticket
    for y in range(size):
        px.append(0)  # filtre PNG (None) par scanline
        for x in range(size):
            # fond arrondi
            if not rounded(x, y, size, size, size // 6):
                px += bytes((TEAL[0], TEAL[1], TEAL[2], 0))
                continue
            r, g, b = TEAL
            # ticket
            lx, ly = x - px0, y - py0
            if 0 <= lx < pw and 0 <= ly < (size - 2 * pad):
                th = size - 2 * pad
                if rounded(lx, ly, pw, th, size // 22):
                    r, g, b = PAPER
                    # bandes de texte simulées
                    rows = 7
                    band = th // (rows + 2)
                    idx = (ly - band) // band
                    iny = (ly - band) % band
                    if 0 <= idx < rows and iny < band * 0.45:
                        margin = pw // 8
                        # première bande = titre (centré, large), autres = lignes
                        if idx == 0:
                            if margin * 1.5 <= lx <= pw - margin * 1.5:
                                r, g, b = ACCENT
                        else:
                            ll = margin
                            rr = pw - margin if idx % 2 else pw - margin * 3
                            if ll <= lx <= rr:
                                r, g, b = INK
            px += bytes((r, g, b, 255))
    raw = bytes(px)
    comp = zlib.compress(raw, 9)

    def chunk(tag, data):
        c = tag + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)

    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", comp) + chunk(b"IEND", b"")


def main():
    out = os.path.join(os.path.dirname(__file__), "..", "icons")
    os.makedirs(out, exist_ok=True)
    for size, name in [(512, "icon-512.png"), (192, "icon-192.png"), (180, "apple-touch-icon.png")]:
        with open(os.path.join(out, name), "wb") as f:
            f.write(make(size))
        print("écrit", name)


if __name__ == "__main__":
    main()
