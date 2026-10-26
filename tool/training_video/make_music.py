#!/usr/bin/env python3
"""Generates a soft, light background track for the training video: slow
warm chords with a gentle bell melody, made from scratch (no samples, no
licence questions).

  python3 tool/training_video/make_music.py <seconds> <out.wav>
"""
import sys
import wave

import numpy as np

RATE = 44100
BPM = 72
BEAT = 60 / BPM

# C, Am, F, G (I, vi, IV, V): each chord lasts two bars of four beats.
CHORDS = [
    [261.63, 329.63, 392.00, 130.81],
    [220.00, 261.63, 329.63, 110.00],
    [174.61, 220.00, 261.63, 87.31],
    [196.00, 246.94, 293.66, 98.00],
]
# A simple bell line over each chord (scale degrees in Hz), one per beat.
MELODY = [
    [523.25, 659.25, 783.99, 659.25, 587.33, 523.25, 587.33, 659.25],
    [440.00, 523.25, 659.25, 523.25, 493.88, 440.00, 493.88, 523.25],
    [349.23, 440.00, 523.25, 440.00, 392.00, 349.23, 392.00, 440.00],
    [392.00, 493.88, 587.33, 493.88, 440.00, 392.00, 440.00, 493.88],
]


def pad(freqs, seconds):
    t = np.arange(int(seconds * RATE)) / RATE
    out = np.zeros_like(t)
    for i, f in enumerate(freqs):
        # Two slightly detuned sines per note, for warmth.
        for detune in (-0.6, 0.6):
            out += np.sin(2 * np.pi * (f + detune) * t + i) * (0.5 if f < 150 else 0.35)
    # Slow swell in and out.
    env = np.minimum(1, t / 1.6) * np.minimum(1, (seconds - t) / 1.6)
    return out * env


def bell(f, seconds):
    t = np.arange(int(seconds * RATE)) / RATE
    tone = np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * 2 * f * t) + 0.1 * np.sin(2 * np.pi * 3 * f * t)
    return tone * np.exp(-t * 3.2) * np.minimum(1, t / 0.01)


def main():
    seconds, out = float(sys.argv[1]), sys.argv[2]
    total = int(seconds * RATE)
    music = np.zeros(total + RATE * 8)
    bar = BEAT * 4
    pos = 0.0
    i = 0
    while pos < seconds:
        chord_len = bar * 2
        start = int(pos * RATE)
        p = pad(CHORDS[i % 4], chord_len + 1.5)  # Overlap into the next chord.
        music[start:start + len(p)] += p * 0.09
        for k, f in enumerate(MELODY[i % 4]):
            b = bell(f, 2.5)
            s = start + int(k * BEAT * RATE)
            music[s:s + len(b)] += b * 0.05
        pos += chord_len
        i += 1
    music = music[:total]
    # A gentle low-pass (moving average) to keep it soft.
    k = np.ones(9) / 9
    music = np.convolve(music, k, mode='same')
    # Fade in and out.
    fade = int(3 * RATE)
    music[:fade] *= np.linspace(0, 1, fade)
    music[-fade:] *= np.linspace(1, 0, fade)
    music /= max(1e-9, np.abs(music).max())
    music *= 0.7
    stereo = np.repeat((music * 32767).astype(np.int16)[:, None], 2, axis=1)
    with wave.open(out, 'wb') as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(stereo.tobytes())
    print(f'Wrote {out} ({seconds:.0f} s)')


if __name__ == '__main__':
    main()
