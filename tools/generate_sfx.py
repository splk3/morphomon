#!/usr/bin/env python3
"""Procedural 8-bit sound-effect generator for Morphomon.

Generates short WAV sound effects into ``assets/sfx/``. Deterministic.
Run from the repo root: ``python3 tools/generate_sfx.py``. Requires numpy.
"""

import os
import struct
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sfx")


def write(name, samples):
    data = np.clip(samples, -1, 1)
    d16 = (data * 32767).astype(np.int16)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", s) for s in d16))
    print("wrote", path)


def square_sweep(f0, f1, dur, duty=0.5):
    n = int(dur * SR)
    t = np.linspace(0, dur, n)
    freq = np.linspace(f0, f1, n)
    phase = np.cumsum(freq) / SR
    wave_ = np.where((phase % 1.0) < duty, 1.0, -1.0)
    decay = np.exp(-t * (3.0 / dur))
    return wave_ * decay


def noise_burst(dur, decay_rate=20):
    n = int(dur * SR)
    t = np.linspace(0, dur, n)
    return np.random.uniform(-1, 1, n) * np.exp(-t * decay_rate)


def main():
    os.makedirs(OUT, exist_ok=True)
    np.random.seed(7)
    write("jump", square_sweep(300, 760, 0.18))
    write("shoot", square_sweep(700, 200, 0.16, duty=0.25))
    write("laser", square_sweep(1200, 400, 0.22, duty=0.125))
    write("hit", noise_burst(0.18, 16) * 0.8 + square_sweep(200, 60, 0.18) * 0.4)
    write("explosion", noise_burst(0.5, 7))
    write("pickup", square_sweep(500, 1000, 0.12) * 0.6 + square_sweep(1000, 1500, 0.12) * 0.4)
    write("transform", square_sweep(200, 1400, 0.6, duty=0.5))
    write("select", square_sweep(600, 600, 0.06))
    write("confirm", square_sweep(600, 900, 0.14))
    write("rescue", square_sweep(400, 800, 0.25) * 0.5 + square_sweep(800, 1200, 0.25) * 0.5)


if __name__ == "__main__":
    main()
