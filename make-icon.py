# -*- coding: utf-8 -*-
"""指南龟 App 图标生成器（简约版）：黑底 + 白环 + 四向刻度 + 红针 + 绿色六边形中心"""
import math
import os
from PIL import Image, ImageDraw

BASE = os.path.dirname(os.path.abspath(__file__))
WWW = os.path.join(BASE, "www")

SIZE = 1024
SS = 4
W = SIZE * SS
CX = W / 2.0
CY = W / 2.0

RING_R = W * 0.40
NEEDLE_LEN = W * 0.32
HUB_R = W * 0.075

def draw():
    img = Image.new("RGB", (W, W), (13, 13, 15))
    d = ImageDraw.Draw(img)

    d.ellipse([CX - RING_R - 10, CY - RING_R - 10, CX + RING_R + 10, CY + RING_R + 10],
              outline=(232, 232, 237), width=10)

    for deg, major in ((0, True), (90, False), (180, False), (270, False)):
        a = math.radians(deg)
        r1 = RING_R - (W * 0.035 if major else W * 0.018)
        x1 = CX + r1 * math.sin(a)
        y1 = CY - r1 * math.cos(a)
        x2 = CX + RING_R * math.sin(a)
        y2 = CY - RING_R * math.cos(a)
        d.line([x1, y1, x2, y2],
               fill=(240, 240, 245) if major else (140, 142, 146),
               width=(12 if major else 8))

    hw = W * 0.026
    d.polygon([(CX, CY - NEEDLE_LEN), (CX - hw, CY), (CX + hw, CY)], fill=(255, 69, 58))

    pts = []
    for i in range(6):
        a = math.radians(60 * i + 30)
        pts.append((CX + HUB_R * math.cos(a), CY + HUB_R * math.sin(a)))
    d.polygon(pts, fill=(46, 158, 99), outline=(20, 80, 50), width=6)

    mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, W - 1, W - 1], radius=int(W * 0.2237), fill=255)
    out = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out.resize((SIZE, SIZE), Image.LANCZOS)

def main():
    master = draw()
    paths = [
        os.path.join(WWW, "icon-1024.png"),
        os.path.join(WWW, "icon-180.png"),
        os.path.join(WWW, "favicon-32.png"),
        os.path.join(BASE, "icon-1024.png"),
    ]
    master.save(paths[0], "PNG")
    master.resize((180, 180), Image.LANCZOS).save(paths[1], "PNG")
    master.resize((32, 32), Image.LANCZOS).save(paths[2], "PNG")
    master.save(paths[3], "PNG")
    for p in paths:
        print(p, os.path.getsize(p))

if __name__ == "__main__":
    main()