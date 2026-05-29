#!/usr/bin/env python3
"""Procedural chiptune generator for Morphomon.

Generates short, seamlessly looping WAV tracks (one per game theme) using
classic 8-bit waveforms: pulse/square lead, triangle bass, and a noise
percussion channel. Output is written to ``assets/music/`` as 16-bit mono
WAV files that Godot imports natively.

Run from the repository root:

    python3 tools/generate_music.py

This script is deterministic, so regenerating produces identical files.
Requires only ``numpy`` (already used by the project tooling).
"""

import os
import struct
import wave

import numpy as np

SAMPLE_RATE = 22050
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "music")

# Note name -> frequency (Hz). Equal temperament, A4 = 440.
_NOTE_SEMITONES = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}


def note_freq(name):
    """Convert a note like ``A4`` or ``Cs5`` (s = sharp) to a frequency."""
    if name == "R":  # rest
        return 0.0
    letter = name[0]
    idx = 1
    semis = _NOTE_SEMITONES[letter]
    if len(name) > 1 and name[1] == "s":
        semis += 1
        idx = 2
    octave = int(name[idx:])
    semis += (octave - 4) * 12
    return 440.0 * (2.0 ** (semis / 12.0))


def square(freq, n, duty=0.5):
    if freq <= 0:
        return np.zeros(n)
    t = np.arange(n) / SAMPLE_RATE
    phase = (t * freq) % 1.0
    return np.where(phase < duty, 1.0, -1.0)


def triangle(freq, n):
    if freq <= 0:
        return np.zeros(n)
    t = np.arange(n) / SAMPLE_RATE
    phase = (t * freq) % 1.0
    return 2.0 * np.abs(2.0 * phase - 1.0) - 1.0


def env(n, attack=0.005, release=0.04):
    """Simple AD envelope to avoid clicks and give notes a plucky feel."""
    e = np.ones(n)
    a = max(1, int(attack * SAMPLE_RATE))
    r = max(1, int(release * SAMPLE_RATE))
    a = min(a, n)
    r = min(r, n)
    e[:a] = np.linspace(0.0, 1.0, a)
    e[n - r:] = np.linspace(1.0, 0.0, r)
    return e


def render_channel(notes, bpm, wave_fn, gain, duty=None):
    """notes: list of (note_name, beats). Returns float array."""
    spb = 60.0 / bpm
    chunks = []
    for name, beats in notes:
        n = int(beats * spb * SAMPLE_RATE)
        if n <= 0:
            continue
        f = note_freq(name)
        if duty is not None:
            wave = wave_fn(f, n, duty)
        else:
            wave = wave_fn(f, n)
        if f > 0:
            wave = wave * env(n)
        chunks.append(wave * gain)
    if not chunks:
        return np.zeros(0)
    return np.concatenate(chunks)


def noise_track(pattern, bpm, gain):
    """pattern: list of (hit, beats) where hit in {'K','S','H','-'}."""
    spb = 60.0 / bpm
    chunks = []
    for hit, beats in pattern:
        n = int(beats * spb * SAMPLE_RATE)
        if n <= 0:
            continue
        if hit == "-":
            chunks.append(np.zeros(n))
            continue
        noise = np.random.uniform(-1.0, 1.0, n)
        if hit == "K":  # kick: short low thump
            decay = np.exp(-np.linspace(0, 12, n))
            tone = np.sin(2 * np.pi * 80 * np.arange(n) / SAMPLE_RATE)
            chunks.append((tone * 0.8 + noise * 0.2) * decay * gain)
        elif hit == "S":  # snare
            decay = np.exp(-np.linspace(0, 18, n))
            chunks.append(noise * decay * gain)
        else:  # hat
            decay = np.exp(-np.linspace(0, 60, n))
            chunks.append(noise * decay * gain * 0.6)
    if not chunks:
        return np.zeros(0)
    return np.concatenate(chunks)


def mix(channels):
    length = max((len(c) for c in channels), default=0)
    out = np.zeros(length)
    for c in channels:
        if len(c) < length:
            c = np.pad(c, (0, length - len(c)))
        out += c
    peak = np.max(np.abs(out)) or 1.0
    return out / peak * 0.85


def write_wav(name, samples):
    path = os.path.join(OUT_DIR, name + ".wav")
    data = np.clip(samples, -1.0, 1.0)
    data16 = (data * 32767).astype(np.int16)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(b"".join(struct.pack("<h", s) for s in data16))
    print("wrote", path, "(%.1f KB)" % (os.path.getsize(path) / 1024))


def lead(seq):
    return [(n, b) for n, b in seq]


# --- Song definitions ---------------------------------------------------
# Each song: bpm, lead melody, bass line, drum pattern, lead duty cycle.

def song_menu():
    bpm = 150
    melody = lead([
        ("E5", .5), ("G5", .5), ("A5", .5), ("B5", .5), ("A5", .5), ("G5", .5), ("E5", 1),
        ("D5", .5), ("E5", .5), ("G5", .5), ("A5", .5), ("G5", .5), ("E5", .5), ("D5", 1),
        ("C5", .5), ("E5", .5), ("G5", .5), ("C6", .5), ("B5", .5), ("G5", .5), ("E5", 1),
        ("D5", .5), ("Fs5", .5), ("A5", .5), ("D6", .5), ("A5", .5), ("Fs5", .5), ("D5", 1),
    ])
    bass = lead([
        ("E2", 1), ("E3", 1), ("C2", 1), ("C3", 1),
        ("C2", 1), ("C3", 1), ("G2", 1), ("G3", 1),
        ("C2", 1), ("C3", 1), ("A2", 1), ("A3", 1),
        ("D2", 1), ("D3", 1), ("D2", 1), ("A2", 1),
    ])
    drums = [("K", .5), ("H", .5)] * 16
    return bpm, melody, bass, drums, 0.5


def song_cruise():
    bpm = 124
    melody = lead([
        ("G4", .5), ("A4", .5), ("B4", 1), ("D5", .5), ("B4", .5), ("A4", 1),
        ("G4", .5), ("A4", .5), ("B4", 1), ("E5", .5), ("D5", .5), ("B4", 1),
        ("C5", .5), ("B4", .5), ("A4", 1), ("Fs4", .5), ("A4", .5), ("D5", 1),
        ("E5", .5), ("D5", .5), ("B4", 1), ("G4", 2),
    ])
    bass = lead([("G2", 1), ("D3", 1)] * 8)
    drums = [("K", .5), ("H", .5), ("S", .5), ("H", .5)] * 8
    return bpm, melody, bass, drums, 0.5


def song_ice():
    bpm = 132
    melody = lead([
        ("A5", .5), ("E5", .5), ("A5", .5), ("B5", .5), ("C6", 1), ("B5", .5), ("A5", .5),
        ("E5", .5), ("Gs5", .5), ("B5", .5), ("E6", .5), ("D6", 1), ("B5", 1),
        ("A5", .5), ("E5", .5), ("A5", .5), ("C6", .5), ("E6", 1), ("D6", .5), ("C6", .5),
        ("B5", .5), ("A5", .5), ("Gs5", .5), ("B5", .5), ("A5", 2),
    ])
    bass = lead([("A2", 1), ("A3", 1), ("E2", 1), ("E3", 1)] * 4)
    drums = [("K", .5), ("H", .25), ("H", .25)] * 16
    return bpm, melody, bass, drums, 0.25


def song_lava():
    bpm = 168
    melody = lead([
        ("E5", .25), ("E5", .25), ("F5", .5), ("E5", .25), ("D5", .25), ("C5", .5),
        ("D5", .25), ("E5", .25), ("G5", .5), ("A5", 1),
        ("As5", .5), ("A5", .5), ("G5", .5), ("F5", .5), ("E5", 1), ("C5", 1),
        ("E5", .5), ("G5", .5), ("As5", .5), ("A5", .5), ("G5", .5), ("E5", .5), ("C5", 1),
    ])
    bass = lead([("C2", .5), ("C2", .5), ("As1", .5), ("As1", .5)] * 8)
    drums = [("K", .25), ("K", .25), ("S", .5), ("H", .25), ("K", .25), ("S", .5)] * 6
    return bpm, melody, bass, drums, 0.5


def song_island():
    bpm = 140
    melody = lead([
        ("D5", .5), ("Fs5", .5), ("A5", .5), ("B5", .5), ("A5", .5), ("Fs5", 1), ("D5", .5),
        ("E5", .5), ("G5", .5), ("B5", .5), ("A5", .5), ("G5", .5), ("E5", 1), ("D5", .5),
        ("Fs5", .5), ("A5", .5), ("D6", .5), ("Cs6", .5), ("A5", .5), ("Fs5", 1), ("E5", .5),
        ("D5", .5), ("E5", .5), ("Fs5", .5), ("A5", .5), ("D5", 1.5),
    ])
    bass = lead([("D2", 1), ("A2", 1), ("G2", 1), ("A2", 1)] * 4)
    drums = [("K", .5), ("H", .5), ("S", .5), ("H", .5)] * 8
    return bpm, melody, bass, drums, 0.5


def song_jungle():
    bpm = 128
    melody = lead([
        ("E5", .5), ("G5", .25), ("A5", .25), ("G5", .5), ("E5", .5), ("D5", 1),
        ("E5", .5), ("A5", .25), ("B5", .25), ("A5", .5), ("G5", .5), ("E5", 1),
        ("C5", .5), ("E5", .25), ("G5", .25), ("E5", .5), ("C5", .5), ("D5", 1),
        ("D5", .5), ("Fs5", .25), ("A5", .25), ("Fs5", .5), ("D5", .5), ("E5", 1),
    ])
    bass = lead([("E2", .5), ("E2", .5), ("C2", .5), ("D2", .5)] * 8)
    drums = [("K", .5), ("S", .25), ("H", .25), ("K", .25), ("K", .25), ("S", .5)] * 6
    return bpm, melody, bass, drums, 0.75


def song_pirate():
    bpm = 144
    melody = lead([
        ("D5", .5), ("E5", .5), ("F5", .5), ("E5", .5), ("D5", .5), ("A4", 1), ("R", .5),
        ("D5", .5), ("F5", .5), ("A5", .5), ("G5", .5), ("F5", .5), ("E5", 1), ("R", .5),
        ("C5", .5), ("E5", .5), ("G5", .5), ("F5", .5), ("E5", .5), ("D5", 1), ("R", .5),
        ("A4", .5), ("D5", .5), ("F5", .5), ("E5", .5), ("D5", 1.5),
    ])
    bass = lead([("D2", 1), ("A2", 1), ("As2", 1), ("A2", 1)] * 4)
    drums = [("K", .5), ("H", .5), ("S", .5), ("H", .5)] * 8
    return bpm, melody, bass, drums, 0.5


def song_boss():
    bpm = 176
    melody = lead([
        ("C5", .25), ("C5", .25), ("Ds5", .5), ("C5", .25), ("As4", .25), ("C5", .5),
        ("D5", .25), ("Ds5", .25), ("G5", .5), ("F5", .25), ("Ds5", .25), ("D5", .5),
        ("C5", .25), ("Ds5", .25), ("G5", .5), ("C6", .5), ("As5", .5), ("G5", 1),
        ("F5", .25), ("Ds5", .25), ("D5", .5), ("C5", 1),
    ])
    bass = lead([("C2", .25), ("C2", .25)] * 32)
    drums = [("K", .25), ("S", .25)] * 24
    return bpm, melody, bass, drums, 0.25


def song_credits():
    bpm = 138
    melody = lead([
        ("C5", .5), ("E5", .5), ("G5", .5), ("E5", .5), ("F5", .5), ("A5", 1), ("G5", .5),
        ("E5", .5), ("G5", .5), ("C6", .5), ("B5", .5), ("G5", .5), ("E5", 1), ("D5", .5),
        ("F5", .5), ("A5", .5), ("C6", .5), ("B5", .5), ("A5", .5), ("F5", 1), ("E5", .5),
        ("D5", .5), ("E5", .5), ("F5", .5), ("G5", .5), ("C5", 1.5),
    ])
    bass = lead([("C2", 1), ("G2", 1), ("A2", 1), ("F2", 1)] * 4)
    drums = [("K", .5), ("H", .5), ("S", .5), ("H", .5)] * 8
    return bpm, melody, bass, drums, 0.5


SONGS = {
    "menu_theme": song_menu,
    "cruise_theme": song_cruise,
    "ice_theme": song_ice,
    "lava_theme": song_lava,
    "island_theme": song_island,
    "jungle_theme": song_jungle,
    "pirate_theme": song_pirate,
    "boss_theme": song_boss,
    "credits_theme": song_credits,
}


def build(name, fn):
    np.random.seed(abs(hash(name)) % (2 ** 32))
    bpm, melody, bass, drums, duty = fn()
    lead_ch = render_channel(melody, bpm, square, 0.35, duty=duty)
    # Double the bassline length-wise to span the melody if needed via mix padding.
    bass_ch = render_channel(bass, bpm, triangle, 0.5)
    drum_ch = noise_track(drums, bpm, 0.5)
    out = mix([lead_ch, bass_ch, drum_ch])
    write_wav(name, out)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, fn in SONGS.items():
        build(name, fn)


if __name__ == "__main__":
    main()
