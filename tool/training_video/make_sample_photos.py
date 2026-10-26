#!/usr/bin/env python3
"""Draws the sample "photos" used in the training video (no stock images,
so there's nothing to license). Writes JPEGs to tool/training_video/photos/.

  python3 tool/training_video/make_sample_photos.py
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parent / 'photos'
W, H = 1200, 900
random.seed(7)


def noise(img, amount=10):
    px = img.load()
    for _ in range(W * H // 6):
        x, y = random.randrange(W), random.randrange(H)
        r, g, b = px[x, y]
        d = random.randint(-amount, amount)
        px[x, y] = (max(0, min(255, r + d)), max(0, min(255, g + d)), max(0, min(255, b + d)))
    return img


def sky(draw, top=(150, 190, 230), bottom=(215, 230, 245), h=360):
    for y in range(h):
        t = y / h
        draw.line([(0, y), (W, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)))


def pothole():
    img = Image.new('RGB', (W, H), (90, 92, 96))
    d = ImageDraw.Draw(img)
    sky(d, h=250)
    d.polygon([(0, 250), (W, 250), (W, H), (0, H)], fill=(78, 80, 84))
    for x in range(0, W, 160):  # Lane dashes in perspective.
        d.polygon([(560 + (x - 600) * 0.05, 260), (600 + (x - 600) * 0.05, 260), (650, H), (550, H)], fill=(78, 80, 84))
    d.polygon([(585, 300), (605, 300), (630, 420), (575, 420)], fill=(235, 220, 120))
    d.polygon([(568, 520), (612, 520), (660, H), (540, H)], fill=(235, 220, 120))
    d.ellipse([260, 520, 760, 760], fill=(40, 40, 42))
    d.ellipse([300, 560, 720, 730], fill=(55, 50, 45))
    d.ellipse([360, 600, 640, 700], fill=(70, 85, 95))  # A puddle in it.
    for _ in range(40):
        a = random.uniform(0, 2 * math.pi)
        r = random.uniform(240, 330)
        x, y = 510 + r * math.cos(a), 640 + 0.48 * r * math.sin(a)
        d.line([(510 + 230 * math.cos(a), 640 + 110 * math.sin(a)), (x, y)], fill=(50, 50, 52), width=3)
    d.rectangle([0, 250, W, 262], fill=(150, 150, 150))
    return noise(img.filter(ImageFilter.GaussianBlur(1.2)))


def streetlight():
    img = Image.new('RGB', (W, H))
    d = ImageDraw.Draw(img)
    sky(d, top=(30, 40, 70), bottom=(70, 80, 110), h=H)
    d.rectangle([0, 700, W, H], fill=(60, 60, 64))
    d.rectangle([560, 160, 590, 720], fill=(110, 115, 120))
    d.rectangle([590, 160, 820, 180], fill=(110, 115, 120))
    d.polygon([(760, 180), (860, 180), (840, 215), (780, 215)], fill=(140, 145, 150))
    d.ellipse([785, 205, 835, 230], fill=(70, 70, 70))  # Dark: the bulb is out.
    for i, x in enumerate([150, 980]):
        d.rectangle([x, 300, x + 18, 720], fill=(100, 105, 110))
        d.ellipse([x - 40, 270, x + 58, 330], fill=(255, 220, 140))
    return noise(img.filter(ImageFilter.GaussianBlur(1.5)), 6)


def leaking_tap():
    img = Image.new('RGB', (W, H), (232, 228, 220))
    d = ImageDraw.Draw(img)
    for x in range(0, W, 120):  # Tiles.
        for y in range(0, 520, 120):
            d.rectangle([x + 4, y + 4, x + 116, y + 116], fill=(244, 242, 238))
    d.rectangle([0, 520, W, H], fill=(180, 165, 140))  # Counter.
    d.rectangle([250, 560, 950, 860], fill=(200, 205, 210))
    d.rectangle([280, 580, 920, 840], fill=(170, 178, 186))  # Sink.
    d.rectangle([560, 380, 640, 560], fill=(185, 190, 196))
    d.rounded_rectangle([560, 360, 820, 410], 20, fill=(195, 200, 206))
    d.rectangle([790, 400, 820, 450], fill=(185, 190, 196))
    for i, y in enumerate([470, 540, 620, 700]):
        d.ellipse([796 - i, y, 814 + i, y + 26 + i * 3], fill=(120, 170, 220))
    d.ellipse([700, 760, 900, 800], fill=(140, 175, 205))  # Water pooling.
    d.rounded_rectangle([450, 330, 520, 370], 12, fill=(150, 155, 160))
    return noise(img.filter(ImageFilter.GaussianBlur(1)), 6)


def snowy_lot():
    img = Image.new('RGB', (W, H))
    d = ImageDraw.Draw(img)
    sky(d, top=(190, 200, 215), bottom=(225, 230, 238), h=320)
    d.rectangle([0, 320, W, H], fill=(245, 247, 250))
    for i, x in enumerate([120, 420, 720, 1000]):
        c = [(170, 40, 40), (40, 70, 140), (60, 60, 60), (200, 200, 205)][i]
        d.rounded_rectangle([x, 470, x + 230, 600], 30, fill=c)
        d.rounded_rectangle([x + 30, 420, x + 190, 490], 25, fill=c)
        d.rounded_rectangle([x + 10, 450, x + 220, 480], 15, fill=(250, 250, 252))  # Snow on top.
        d.ellipse([x + 20, 580, x + 70, 630], fill=(30, 30, 30))
        d.ellipse([x + 160, 580, x + 210, 630], fill=(30, 30, 30))
    for _ in range(500):
        x, y = random.randrange(W), random.randrange(H)
        d.ellipse([x, y, x + 5, y + 5], fill=(255, 255, 255))
    return noise(img.filter(ImageFilter.GaussianBlur(1)), 5)


def keys():
    img = Image.new('RGB', (W, H), (120, 95, 70))
    d = ImageDraw.Draw(img)
    for y in range(0, H, 60):  # Wood grain.
        d.line([(0, y + random.randint(0, 20)), (W, y + random.randint(0, 20))], fill=(105, 82, 60), width=4)
    d.ellipse([420, 330, 560, 470], outline=(205, 205, 210), width=14)
    for i, (x, y, a) in enumerate([(560, 400, -10), (540, 450, 30), (500, 470, 70)]):
        r = math.radians(a)
        x2, y2 = x + 300 * math.cos(r), y + 300 * math.sin(r)
        d.line([(x, y), (x2, y2)], fill=(215, 190, 90) if i == 1 else (200, 200, 205), width=34)
        d.ellipse([x - 40, y - 40, x + 40, y + 40], fill=(215, 190, 90) if i == 1 else (200, 200, 205))
    d.rounded_rectangle([640, 560, 820, 640], 30, fill=(30, 90, 160))  # A fob.
    return noise(img.filter(ImageFilter.GaussianBlur(1)), 8)


def main():
    OUT.mkdir(exist_ok=True)
    for name, fn in [('pothole', pothole), ('streetlight', streetlight), ('leaking-tap', leaking_tap),
                     ('snowy-lot', snowy_lot), ('keys', keys)]:
        fn().save(OUT / f'{name}.jpg', quality=85)
    print(f'Wrote photos to {OUT}')


if __name__ == '__main__':
    main()
