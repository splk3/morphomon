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


def layer(*arrs):
    """Sum layers of differing lengths by zero-padding to the longest."""
    n = max(len(a) for a in arrs)
    out = np.zeros(n)
    for a in arrs:
        out[:len(a)] += a
    return out


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
    # --- New UI / movement SFX (same chiptune voice as above) -------------
    # ui_nav: short, subtle blip for moving the menu cursor.
    write("ui_nav", square_sweep(880, 880, 0.045, duty=0.5) * 0.5)
    # ui_select: brighter rising confirm for activating a menu item.
    write("ui_select", layer(square_sweep(720, 1180, 0.10, duty=0.5) * 0.7,
                             square_sweep(1180, 1320, 0.06) * 0.3))
    # ui_back: downward cancel tone for backing out / closing menus.
    write("ui_back", square_sweep(700, 320, 0.12, duty=0.5) * 0.7)
    # land: soft low thud when the player touches down.
    write("land", layer(noise_burst(0.10, 22) * 0.35, square_sweep(150, 60, 0.12) * 0.6))
    # dash: airy jet whoosh for the dash move.
    write("dash", layer(noise_burst(0.22, 7) * 0.55,
                        square_sweep(220, 900, 0.20, duty=0.25) * 0.35))
    # laser_charge: rising charge swell for the eagle laser winding up.
    write("laser_charge", laser_charge(0.55))
    # New stage enemy/event SFX:
    # puffer_pop: quick bubbly pop for abyss pufferfish bots.
    write("puffer_pop", layer(noise_burst(0.09, 28) * 0.25,
                              square_sweep(280, 110, 0.11, duty=0.2) * 0.45))
    # ufo_blast: bright sci-fi burst for space drones.
    write("ufo_blast", layer(square_sweep(1500, 520, 0.14, duty=0.125) * 0.55,
                             square_sweep(900, 1400, 0.08, duty=0.5) * 0.3,
                             noise_burst(0.08, 20) * 0.2))
    # gear_break: metallic clank-snap for factory hoppers.
    write("gear_break", layer(square_sweep(420, 180, 0.16, duty=0.35) * 0.45,
                              square_sweep(820, 260, 0.13, duty=0.25) * 0.35,
                              noise_burst(0.12, 16) * 0.25))


def laser_charge(dur, f0=260, f1=1500, duty=0.125):
    """Rising-pitch tone that *swells* in volume (a charge-up, not a decay)."""
    n = int(dur * SR)
    t = np.linspace(0, dur, n)
    freq = np.linspace(f0, f1, n)
    phase = np.cumsum(freq) / SR
    wave_ = np.where((phase % 1.0) < duty, 1.0, -1.0)
    swell = np.linspace(0.0, 1.0, n) ** 1.6  # amplitude grows as it charges.
    vibrato = 1.0 + 0.04 * np.sin(2 * np.pi * 18 * t)  # subtle shimmer
    return wave_ * swell * vibrato


if __name__ == "__main__":
    main()
