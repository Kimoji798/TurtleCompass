# -*- coding: utf-8 -*-
"""指南龟 App 图标生成器：生成 1024 / 180 / 32 三种尺寸 PNG"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

BASE = os.path.dirname(os.path.abspath(__file__))
WWW = os.path.join(BASE, "www")

SIZE = 1024
SS = 4
W = SIZE * SS
CX = W / 2.0
CY = W / 2.0

def load_font(size):
    for name in ["arialbd.ttf", "arial.ttf", "segoeuib.ttf", "segoeui.ttf"]:
        p = os.path.join(r"C:\Windows\Fonts", name)
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()

def hex_points(cx, cy, r):
    pts = []
    for i in range(6):
        a = math.radians(60 * i + 30)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts

def draw():
    img = Image.new("RGB", (W, W), (0, 0, 0))
    d = ImageDraw.Draw(img)

    top = (40, 52, 48)
    bottom = (3, 7, 6)
    for y in range(W):
        t = y / float(W - 1)
        d.line([(0, y), (W, y)], fill=(
            int(top[0] + (bottom[0] - top[0]) * t),
            int(top[1] + (bottom[1] - top[1]) * t),
            int(top[2] + (bottom[2] - top[2]) * t)))

    glow = Image.new("RGB", (W, W), (0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([CX - W * 0.36, CY - W * 0.36, CX + W * 0.36, CY + W * 0.36], fill=(26, 82, 68))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=W * 0.16))
    img = Image.blend(img, glow, 0.5)

    d = ImageDraw.Draw(img)
    outer = W * 0.420
    d.ellipse([CX - outer - 6, CY - outer - 6, CX + outer + 6, CY + outer + 6], outline=(232, 232, 237), width=12)

    for deg in range(0, 360, 3):
        major = deg % 30 == 0
        r1 = outer - (W * 0.036 if major else W * 0.018)
        a = math.radians(deg)
        x1 = CX + r1 * math.sin(a)
        y1 = CY - r1 * math.cos(a)
        x2 = CX + outer * math.sin(a)
        y2 = CY - outer * math.cos(a)
        d.line([x1, y1, x2, y2], fill=(240, 240, 245) if major else (118, 120, 124), width=(10 if major else 5))

    letters = {"N": 0, "E": 90, "S": 180, "W": 270}
    font = load_font(int(W * 0.105))
    lr = W * 0.315
    for letter, deg in letters.items():
        a = math.radians(deg)
        x = CX + lr * math.sin(a)
        y = CY - lr * math.cos(a)
        bbox = d.textbbox((0, 0), letter, font=font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        d.text((x - tw / 2 - bbox[0], y - th / 2 - bbox[1]), letter, font=font, fill=(245, 245, 248))

    hex_r = W * 0.058
    shell = [
        (0, 0), (1.732, 0), (-1.732, 0),
        (0.866, 1.5), (-0.866, 1.5), (0.866, -1.5), (-0.866, -1.5)
    ]
    for i, (hx, hy) in enumerate(shell):
        fill = (62, 138, 106) if i == 0 else (48, 112, 88)
        d.polygon(hex_points(CX + hx * hex_r, CY + hy * hex_r, hex_r), fill=fill, outline=(18, 42, 33), width=int(W * 0.004))

    L = W * 0.400
    hw = W * 0.030
    d.polygon([(CX, CY - L), (CX - hw, CY), (CX + hw, CY)], fill=(255, 69, 58))
    d.polygon([(CX, CY + L), (CX - hw, CY), (CX + hw, CY)], fill=(232, 232, 237))

    cap_r = W * 0.052
    d.ellipse([CX - cap_r, CY - cap_r, CX + cap_r, CY + cap_r], fill=(12, 13, 14), outline=(255, 255, 255), width=int(W * 0.008))
    dot_r = W * 0.012
    d.ellipse([CX - dot_r, CY - dot_r, CX + dot_r, CY + dot_r], fill=(255, 214, 10))

    mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, W - 1, W - 1], radius=int(W * 0.2237), fill=255)
    out = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out.resize((SIZE, SIZE), Image.LANCZOS)

def main():
    master = draw()
    p1024 = os.path.join(WWW, "icon-1024.png")
    p180 = os.path.join(WWW, "icon-180.png")
    p32 = os.path.join(WWW, "favicon-32.png")
    master.save(p1024, "PNG")
    master.resize((180, 180), Image.LANCZOS).save(p180, "PNG")
    master.resize((32, 32), Image.LANCZOS).save(p32, "PNG")
    master.save(os.path.join(BASE, "icon-1024.png"), "PNG")
    for p in (p1024, p180, p32):
        print(p, os.path.getsize(p))

if __name__ == "__main__":
    main()
