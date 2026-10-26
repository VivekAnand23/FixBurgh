#!/usr/bin/env python3
"""Builds the Burghood training video from the recorded chapters.

Inputs (from run_chapter.sh and voice.py):
  build/training_video/clips/<chapter>.mov   simulator recordings
  build/training_video/logs/<chapter>.log    when each step started and ended
  build/training_video/voice/<step>.wav      narration
  tool/training_video/script.json            titles and narration (captions)

Writes to Images/training-video/:
  burghood-training-portrait.mp4   1080 x 1920, for phones
  burghood-training-landscape.mp4  1920 x 1080, phone in the middle
  burghood-training.srt            captions
  chapters.txt                     chapter start times

  python3 tool/training_video/assemble.py
"""
import json
import shutil
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
B = ROOT / 'build' / 'training_video'
OUT = ROOT / 'Images' / 'training-video'
NAVY = (27, 79, 134)
ORANGE = (244, 123, 32)
INK = (26, 32, 44)
MUTED = (74, 85, 104)
CARD = 1.8  # Seconds of each chapter title card.
REC_LEAD = 2.0  # The recorder starts this long before the log's RECSTART.
LAYOUTS = {
    'portrait': {'size': (1080, 1920), 'phone_h': 1480, 'phone_xy': None, 'phone_y': 150},
    'landscape': {'size': (1920, 1080), 'phone_h': 980, 'phone_xy': (300, 50)},
}


def font(size, bold=False):
    for path in ['/System/Library/Fonts/HelveticaNeue.ttc', '/System/Library/Fonts/Helvetica.ttc']:
        try:
            return ImageFont.truetype(path, size, index=1 if bold else 0)
        except OSError:
            continue
    return ImageFont.load_default()


def wrap(draw, text, fnt, width):
    lines, line = [], ''
    for word in text.split():
        trial = f'{line} {word}'.strip()
        if draw.textlength(trial, font=fnt) <= width:
            line = trial
        else:
            lines.append(line)
            line = word
    return lines + ([line] if line else [])


def gradient(size):
    w, h = size
    img = Image.new('RGB', size)
    d = ImageDraw.Draw(img)
    top, bottom = (247, 249, 253), (214, 226, 243)
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)))
    return img


def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(f'Failed: {" ".join(map(str, cmd))[:300]}\n{r.stderr[-2000:]}')


def duration(path):
    out = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', str(path)],
                         check=True, capture_output=True, text=True)
    return float(out.stdout.strip())


def phone_box(layout):
    w, h = layout['size']
    ph = layout['phone_h']
    pw = round(ph * 1206 / 2622 / 2) * 2
    x, y = layout['phone_xy'] or ((w - pw) // 2, layout['phone_y'])
    return x, y, pw, ph


def background(layout, chapter, index, total):
    w, h = layout['size']
    img = gradient(layout['size'])
    d = ImageDraw.Draw(img)
    x, y, pw, ph = phone_box(layout)
    # Phone body behind the screen recording.
    d.rounded_rectangle([x - 14, y - 14, x + pw + 14, y + ph + 14], 70, fill=(20, 24, 32))
    label = f'{index}/{total}  {chapter["title"]}'
    if w > h:
        d.text((x + pw + 90, 120), f'Chapter {index} of {total}', font=font(30, True), fill=ORANGE)
        ty = 165
        for line in wrap(d, chapter['title'], font(64, True), w - (x + pw + 90) - 80):
            d.text((x + pw + 90, ty), line, font=font(64, True), fill=NAVY)
            ty += 78
        d.rectangle([x + pw + 90, ty + 14, x + pw + 190, ty + 22], fill=ORANGE)
    else:
        f = font(34, True)
        d.text(((w - d.textlength(label, font=f)) / 2, 70), label, font=f, fill=NAVY)
    return img


def screen_mask(layout):
    _, _, pw, ph = phone_box(layout)
    m = Image.new('L', (pw, ph), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, pw - 1, ph - 1], 58, fill=255)
    return m


def caption(layout, text):
    w, h = layout['size']
    img = Image.new('RGBA', layout['size'], (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if w > h:
        x0 = phone_box(layout)[0] + phone_box(layout)[2] + 90
        f = font(40)
        y = 420
        for line in wrap(d, text, f, w - x0 - 90):
            d.text((x0, y), line, font=f, fill=INK)
            y += 56
    else:
        f = font(36)
        lines = wrap(d, text, f, w - 140)
        box_h = 36 + 48 * len(lines)
        top = h - box_h - 40
        d.rounded_rectangle([40, top, w - 40, h - 40], 28, fill=(255, 255, 255, 235))
        y = top + 18
        for line in lines:
            d.text(((w - d.textlength(line, font=f)) / 2, y), line, font=f, fill=INK)
            y += 48
    return img


def title_card(layout, chapter, index, total):
    w, h = layout['size']
    img = gradient(layout['size'])
    d = ImageDraw.Draw(img)
    small, big = font(40, True), font(92 if w > h else 84, True)
    s = f'Chapter {index} of {total}'
    d.text(((w - d.textlength(s, font=small)) / 2, h / 2 - 120), s, font=small, fill=ORANGE)
    y = h / 2 - 50
    for line in wrap(d, chapter['title'], big, w - 160):
        d.text(((w - d.textlength(line, font=big)) / 2, y), line, font=big, fill=NAVY)
        y += 104
    d.rectangle([w / 2 - 60, y + 20, w / 2 + 60, y + 28], fill=ORANGE)
    return img


def read_log(ch):
    t0, starts, ends = None, {}, {}
    for line in (B / 'logs' / f'{ch}.log').read_text().splitlines():
        parts = line.split()
        if parts[0] == 'RECSTART':
            t0 = float(parts[1])
        elif parts[0] == 'START':
            starts[parts[1]] = float(parts[2])
        elif parts[0] == 'END':
            ends[parts[1]] = float(parts[2])
    return t0, starts, ends


MAX_SPEED = 5.0  # Fastest an action-heavy step is played.


def narration_len(sid):
    return duration(B / 'voice' / f'{sid}.wav')


def retime(ch, ci, tmp):
    """The chapter's screen recording, with each step sped up where its
    taps and typing outlast the narration. Returns the clip and where each
    step now starts."""
    cid = ch['id']
    steps = [s for s, _ in ch['steps']]
    t0, starts, ends = read_log(cid)
    v = lambda t: t - t0 + REC_LEAD  # Host time to video time.
    pieces = []  # (start, end, speed) in the recording.
    lead = 2.5 if ci == 1 else 0.5
    pieces.append((v(starts[steps[0]]) - lead, v(starts[steps[0]]), 1.0))
    for i, sid in enumerate(steps):
        a = v(starts[sid])
        b = v(starts[steps[i + 1]]) if i + 1 < len(steps) else v(ends[sid]) + 0.4
        want = narration_len(sid) + 0.6
        speed = min(MAX_SPEED, max(1.0, (b - a) / want))
        pieces.append((a, b, speed))
    filters, labels, new_starts, clock = [], [], {}, 0.0
    for k, (a, b, speed) in enumerate(pieces):
        filters.append(f'[0:v]trim={a:.3f}:{b:.3f},setpts=(PTS-STARTPTS)/{speed:.4f},fps=30[p{k}]')
        labels.append(f'[p{k}]')
        if k >= 1:
            new_starts[steps[k - 1]] = clock
        clock += (b - a) / speed
    filters.append(''.join(labels) + f'concat=n={len(labels)}:v=1:a=0[v]')
    out = tmp / f'screen-{cid}.mp4'
    run(['ffmpeg', '-y', '-i', B / 'clips' / f'{cid}.mov', '-filter_complex', ';'.join(filters), '-map', '[v]',
         '-c:v', 'libx264', '-preset', 'medium', '-crf', '18', '-r', '30', out])
    return out, new_starts, clock


def stamp(t):
    ms = round(t * 1000)
    return f'{ms // 3600000:02d}:{ms // 60000 % 60:02d}:{ms // 1000 % 60:02d},{ms % 1000:03d}'


retimed = {}


def build(orient, script, tmp):
    layout = LAYOUTS[orient]
    w, h = layout['size']
    x, y, pw, ph = phone_box(layout)
    mask = tmp / f'mask-{orient}.png'
    screen_mask(layout).save(mask)
    parts, srt, chapters_txt = [], [], []
    clock = 0.0
    total = len(script['chapters'])
    for ci, ch in enumerate(script['chapters'], start=1):
        cid = ch['id']
        steps = [s for s, _ in ch['steps']]
        screen = tmp / f'screen-{cid}.mp4'
        if not screen.exists():
            retimed[cid] = retime(ch, ci, tmp)
        screen, step_at, seg_len = retimed[cid]
        # The title card.
        card_png = tmp / f'card-{orient}-{cid}.png'
        title_card(layout, ch, ci, total).save(card_png)
        card_mp4 = tmp / f'card-{orient}-{cid}.mp4'
        run(['ffmpeg', '-y', '-loop', '1', '-framerate', '30', '-t', str(CARD), '-i', card_png,
             '-f', 'lavfi', '-t', str(CARD), '-i', 'anullsrc=r=48000:cl=stereo',
             '-vf', f'fade=t=in:st=0:d=0.3,fade=t=out:st={CARD - 0.3}:d=0.3,format=yuv420p',
             '-c:v', 'libx264', '-preset', 'medium', '-crf', '20', '-c:a', 'aac', '-shortest', card_mp4])
        parts.append(card_mp4)
        chapters_txt.append((clock, ch['title']))
        clock += CARD
        # The chapter: background, the phone recording, captions per step.
        bg = tmp / f'bg-{orient}-{cid}.png'
        background(layout, ch, ci, total).save(bg)
        inputs = ['-loop', '1', '-framerate', '30', '-i', bg,
                  '-i', screen,
                  '-loop', '1', '-framerate', '30', '-i', mask]
        filters = [f'[1:v]fps=30,scale={pw}:{ph},format=rgba[ph]', '[2:v]format=gray[m]',
                   '[ph][m]alphamerge[scr]', f'[0:v][scr]overlay={x}:{y}:shortest=1[base]']
        last = 'base'
        audio_inputs, delays = [], []
        for si, (sid, text) in enumerate(ch['steps']):
            st = step_at[sid]
            nd = step_at[steps[si + 1]] if si + 1 < len(steps) else seg_len
            cap = tmp / f'cap-{orient}-{sid}.png'
            caption(layout, text).save(cap)
            inputs += ['-loop', '1', '-framerate', '30', '-i', cap]
            idx = 3 + si
            filters.append(f'[{last}][{idx}:v]overlay=0:0:enable=\'between(t,{st:.2f},{nd:.2f})\'[o{si}]')
            last = f'o{si}'
            audio_inputs.append(B / 'voice' / f'{sid}.wav')
            delays.append(st + 0.25)
            srt.append((clock + st + 0.25, clock + min(nd, st + 0.25 + duration(B / 'voice' / f'{sid}.wav')), text))
        base_audio = 3 + len(steps)
        for a in audio_inputs:
            inputs += ['-i', a]
        for k, d in enumerate(delays):
            ms = int(d * 1000)
            filters.append(f'[{base_audio + k}:a]aresample=48000,adelay={ms}|{ms},apad[a{k}]')
        filters.append(''.join(f'[a{k}]' for k in range(len(delays)))
                       + f'amix=inputs={len(delays)}:normalize=0,atrim=0:{seg_len:.3f},aformat=channel_layouts=stereo[aout]')
        filters.append(f'[{last}]trim=0:{seg_len:.3f},fade=t=in:st=0:d=0.3,fade=t=out:st={seg_len - 0.3:.3f}:d=0.3,format=yuv420p[vout]')
        seg_mp4 = tmp / f'seg-{orient}-{cid}.mp4'
        run(['ffmpeg', '-y', *map(str, inputs), '-filter_complex', ';'.join(filters),
             '-map', '[vout]', '-map', '[aout]', '-t', f'{seg_len:.3f}',
             '-c:v', 'libx264', '-preset', 'medium', '-crf', '20', '-r', '30', '-c:a', 'aac', '-ar', '48000', seg_mp4])
        parts.append(seg_mp4)
        clock += seg_len
    # Join, then lay the music underneath, ducked while the voice speaks.
    listing = tmp / f'parts-{orient}.txt'
    listing.write_text(''.join(f"file '{p}'\n" for p in parts))
    joined = tmp / f'joined-{orient}.mp4'
    run(['ffmpeg', '-y', '-f', 'concat', '-safe', '0', '-i', listing, '-c', 'copy', joined])
    length = duration(joined)
    music = tmp / 'music.wav'
    if not music.exists():
        run(['python3', ROOT / 'tool' / 'training_video' / 'make_music.py', f'{length + 1:.1f}', music])
    final = OUT / f'burghood-training-{orient}.mp4'
    run(['ffmpeg', '-y', '-i', joined, '-i', music, '-filter_complex',
         '[0:a]asplit=2[voice][key];'
         '[1:a]aecho=0.8:0.7:120|240:0.25|0.15,volume=0.16[bed];'
         '[bed][key]sidechaincompress=threshold=0.02:ratio=8:attack=40:release=600[ducked];'
         '[voice][ducked]amix=inputs=2:normalize=0,loudnorm=I=-16:TP=-1.5:LRA=11[a]',
         '-map', '0:v', '-map', '[a]', '-c:v', 'copy', '-c:a', 'aac', '-b:a', '160k', '-movflags', '+faststart', final])
    return length, srt, chapters_txt


def main():
    for tool in ['ffmpeg', 'ffprobe']:
        if not shutil.which(tool):
            raise SystemExit(f'{tool} is needed.')
    script = json.loads((ROOT / 'tool' / 'training_video' / 'script.json').read_text())
    OUT.mkdir(parents=True, exist_ok=True)
    tmp = Path(tempfile.mkdtemp(prefix='burghood-training-'))
    for orient in ['portrait', 'landscape']:
        length, srt, chapters = build(orient, script, tmp)
    (OUT / 'burghood-training.srt').write_text(
        '\n'.join(f'{i + 1}\n{stamp(a)} --> {stamp(b)}\n{t}\n' for i, (a, b, t) in enumerate(srt)))
    (OUT / 'chapters.txt').write_text(
        ''.join(f'{int(t // 60)}:{int(t % 60):02d}  {title}\n' for t, title in chapters))
    shutil.rmtree(tmp)
    print(f'{length:.1f} s ({int(length // 60)}:{int(length % 60):02d})')
    print((OUT / 'chapters.txt').read_text())


if __name__ == '__main__':
    main()
