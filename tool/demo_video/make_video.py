#!/usr/bin/env python3
"""Builds the Burghood demo video from tool/demo_video/scenes.json.

Each scene is a phone screen (or a title card) beside its caption, voiced
with macOS text to speech and timed to the voice. Writes, under
Images/demo-video/:
  burghood-demo.mp4   1920x1080, H.264 + AAC, with soft English subtitles
  burghood-demo.srt   the subtitles on their own
and docs/marketing/demo-video-script.md, the script to read or re-record.

Run from the repo root after `flutter test tool/demo_video --update-goldens`:
  python3 tool/demo_video/make_video.py [--voice Samantha] [--rate 175]
Needs ffmpeg, Pillow and the macOS `say` command.
"""
import argparse
import json
import shutil
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'Images' / 'demo-video'
W, H = 1920, 1080
NAVY = (27, 79, 134)
ORANGE = (244, 123, 32)
INK = (26, 32, 44)
MUTED = (74, 85, 104)
BG_TOP = (247, 249, 253)
BG_BOTTOM = (220, 230, 245)
PAD_AFTER_VOICE = 0.9  # Seconds of quiet after each line.
FADE = 0.35


def font(size, bold=False):
    for path, index in [
        ('/System/Library/Fonts/HelveticaNeue.ttc', 1 if bold else 0),
        ('/System/Library/Fonts/Helvetica.ttc', 1 if bold else 0),
    ]:
        try:
            return ImageFont.truetype(path, size, index=index)
        except OSError:
            continue
    return ImageFont.load_default()


def background():
    bg = Image.new('RGB', (W, H), BG_TOP)
    draw = ImageDraw.Draw(bg)
    for y in range(H):
        t = y / H
        draw.line([(0, y), (W, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(BG_TOP, BG_BOTTOM)))
    return bg


def wrap(draw, text, fnt, width):
    lines, line = [], ''
    for word in text.split():
        trial = f'{line} {word}'.strip()
        if draw.textlength(trial, font=fnt) <= width:
            line = trial
        else:
            lines.append(line)
            line = word
    if line:
        lines.append(line)
    return lines


def phone(image_path, height=960):
    """The screenshot in a rounded phone frame with a soft shadow."""
    shot = Image.open(image_path).convert('RGB')
    w = round(shot.width * height / shot.height)
    shot = shot.resize((w, height), Image.LANCZOS)
    radius, border = 44, 14
    frame = Image.new('RGBA', (w + 2 * border, height + 2 * border), (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle(
        [0, 0, frame.width - 1, frame.height - 1], radius + border, fill=(20, 24, 32, 255))
    mask = Image.new('L', shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w - 1, height - 1], radius, fill=255)
    frame.paste(shot, (border, border), mask)
    shadow = Image.new('RGBA', (frame.width + 80, frame.height + 80), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [40, 50, frame.width + 40, frame.height + 40], radius + border, fill=(0, 0, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(24))
    shadow.paste(frame, (40, 40), frame)
    return shadow


def slide(scene, index, total, path):
    img = background()
    draw = ImageDraw.Draw(img)
    # Progress dots along the bottom.
    for i in range(total):
        x = W // 2 - (total * 22) // 2 + i * 22
        draw.ellipse([x, H - 44, x + 10, H - 34], fill=NAVY if i <= index else (190, 200, 215))
    if scene.get('card'):
        title = font(120, bold=True)
        tw = draw.textlength(scene['title'], font=title)
        y = 300 if scene.get('bullets') else 380
        draw.text(((W - tw) / 2, y), scene['title'], font=title, fill=NAVY)
        draw.rectangle([W / 2 - 60, y + 160, W / 2 + 60, y + 168], fill=ORANGE)
        body = font(46)
        y += 210
        if scene.get('subtitle'):
            for line in wrap(draw, scene['subtitle'], body, 1300):
                lw = draw.textlength(line, font=body)
                draw.text(((W - lw) / 2, y), line, font=body, fill=MUTED)
                y += 62
        for b in scene.get('bullets', []):
            line = f'•  {b}'
            draw.text((W / 2 - 380, y), line, font=body, fill=INK)
            y += 70
    else:
        ph = phone(ROOT / scene['image'])
        img.paste(ph, (150, (H - ph.height) // 2 + 10), ph)
        x = 150 + ph.width + 90
        width = W - x - 140
        step = font(30, bold=True)
        draw.text((x, 300), f'{index:02d}', font=step, fill=ORANGE)
        title = font(76, bold=True)
        y = 350
        for line in wrap(draw, scene['title'], title, width):
            draw.text((x, y), line, font=title, fill=NAVY)
            y += 92
        draw.rectangle([x, y + 16, x + 110, y + 24], fill=ORANGE)
        y += 60
        sub = font(44)
        for line in wrap(draw, scene.get('subtitle', ''), sub, width):
            draw.text((x, y), line, font=sub, fill=MUTED)
            y += 60
    img.save(path)


def run(cmd):
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)


def duration(path):
    out = subprocess.run(
        ['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', str(path)],
        check=True, capture_output=True, text=True)
    return float(out.stdout.strip())


def stamp(t):
    ms = round(t * 1000)
    return f'{ms // 3600000:02d}:{ms // 60000 % 60:02d}:{ms // 1000 % 60:02d},{ms % 1000:03d}'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--voice', default='Samantha')
    ap.add_argument('--rate', type=int, default=175, help='Words per minute.')
    args = ap.parse_args()
    for tool in ['ffmpeg', 'ffprobe', 'say']:
        if not shutil.which(tool):
            raise SystemExit(f'{tool} is needed.')
    scenes = json.loads((ROOT / 'tool' / 'demo_video' / 'scenes.json').read_text())
    OUT.mkdir(parents=True, exist_ok=True)
    tmp = Path(tempfile.mkdtemp(prefix='burghood-video-'))
    parts, srt, script = [], [], []
    t = 0.0
    for i, scene in enumerate(scenes):
        png, aiff, wav, mp4 = (tmp / f'{i:02d}.{ext}' for ext in ['png', 'aiff', 'wav', 'mp4'])
        slide(scene, i, len(scenes), png)
        run(['say', '-v', args.voice, '-r', str(args.rate), '-o', str(aiff), scene['voice']])
        # A short lead-in, the line, then a pause.
        run(['ffmpeg', '-y', '-i', str(aiff), '-af', f'adelay=350:all=1,apad=pad_dur={PAD_AFTER_VOICE}',
             '-ar', '48000', '-ac', '2', str(wav)])
        d = duration(wav)
        run(['ffmpeg', '-y', '-loop', '1', '-framerate', '30', '-i', str(png), '-i', str(wav),
             '-vf', f'fade=t=in:st=0:d={FADE},fade=t=out:st={d - FADE:.3f}:d={FADE},format=yuv420p',
             '-c:v', 'libx264', '-preset', 'medium', '-crf', '20', '-tune', 'stillimage',
             '-c:a', 'aac', '-b:a', '160k', '-t', f'{d:.3f}', '-shortest', str(mp4)])
        parts.append(mp4)
        srt.append(f'{i + 1}\n{stamp(t + 0.35)} --> {stamp(t + d - PAD_AFTER_VOICE + 0.2)}\n{scene["voice"]}\n')
        script.append((t, d, scene))
        t += d
    listing = tmp / 'parts.txt'
    listing.write_text(''.join(f"file '{p}'\n" for p in parts))
    joined = tmp / 'joined.mp4'
    run(['ffmpeg', '-y', '-f', 'concat', '-safe', '0', '-i', str(listing), '-c', 'copy', str(joined)])
    (OUT / 'burghood-demo.srt').write_text('\n'.join(srt))
    run(['ffmpeg', '-y', '-i', str(joined), '-i', str(OUT / 'burghood-demo.srt'),
         '-c:v', 'copy', '-c:a', 'copy', '-c:s', 'mov_text', '-metadata:s:s:0', 'language=eng',
         '-movflags', '+faststart', str(OUT / 'burghood-demo.mp4')])

    # The script, for reading aloud or re-recording with a human voice.
    md = [
        '# Burghood demo video: script',
        '',
        f'About {round(t)} seconds ({int(t // 60)}:{int(t % 60):02d}) at an easy pace. Each scene shows the '
        'screen on the left and its caption on the right. The voice-over is what to say; timings are '
        'from the generated video (`Images/demo-video/burghood-demo.mp4`, built by '
        '`tool/demo_video/make_video.py` from `tool/demo_video/scenes.json`).',
        '',
        '| # | Time | On screen | Caption |',
        '| --- | --- | --- | --- |',
    ]
    for i, (start, d, s) in enumerate(script):
        shown = 'Title card' if s.get('card') else f'`{s["image"].split("/")[-1]}`'
        md.append(f'| {i + 1} | {int(start // 60)}:{int(start % 60):02d} | {shown} | {s["title"]} |')
    md += ['', '## Voice-over', '']
    for i, (start, d, s) in enumerate(script):
        md += [f'**{i + 1}. {s["title"]}** ({int(start // 60)}:{int(start % 60):02d}, about {round(d)} s)', '',
               f'> {s["voice"]}', '']
    md += ['## Notes for recording', '',
           '- The video uses the Mac\'s built-in voice. For the launch version, record a person reading the '
           'voice-over above, then run `make_video.py` again with that audio, or replace the soundtrack in an editor.',
           '- Screens use sample data (Maple Court HOA, Steel City Plumbing); no real people or businesses.',
           '- The Google results scene shows the in-app list, which needs the `feature_google_places` switch. '
           'With it off, residents see only the "Search Google Maps" button under "No providers found yet".',
           '']
    (ROOT / 'docs' / 'marketing').mkdir(parents=True, exist_ok=True)
    (ROOT / 'docs' / 'marketing' / 'demo-video-script.md').write_text('\n'.join(md))
    shutil.rmtree(tmp)
    print(f'Wrote {OUT / "burghood-demo.mp4"} ({t:.0f} s)')


if __name__ == '__main__':
    main()
