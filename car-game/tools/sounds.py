import json
import os
import sys

import numpy as np
import soundfile
from scipy import signal

RATE = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sounds")
CONFIG = os.path.join(ROOT, "src", "shared", "Config", "SoundSprite.luau")
rng = np.random.default_rng(20260928)


def timeline(seconds):
    return np.arange(int(seconds * RATE)) / RATE


def fade(x, attack=0.004, release=0.02):
    a = max(1, int(attack * RATE))
    r = max(1, int(release * RATE))
    env = np.ones(len(x))
    env[:a] = 0.5 - 0.5 * np.cos(np.linspace(0, np.pi, a))
    env[-r:] *= 0.5 + 0.5 * np.cos(np.linspace(0, np.pi, r))
    return x * env


def decay(t, tau, attack=0.002):
    env = np.exp(-t / tau)
    a = max(1, int(attack * RATE))
    env[:a] *= 0.5 - 0.5 * np.cos(np.linspace(0, np.pi, a))
    return env


def sweep(t, f0, f1, duration):
    k = np.clip(t / duration, 0, 1)
    freq = f0 * (f1 / f0) ** k
    return 2 * np.pi * np.cumsum(freq) / RATE


def butter(x, kind, cutoff, order=4):
    sos = signal.butter(order, cutoff, btype=kind, fs=RATE, output="sos")
    return signal.sosfilt(sos, x)


def moving_filter(x, low, high, steps=48):
    out = np.zeros(len(x))
    size = len(x) // steps + 1
    window = np.hanning(size * 2)
    for step in range(steps):
        center = low * (high / low) ** (step / max(1, steps - 1))
        band = butter(x, "bandpass", [center * 0.6, min(center * 1.6, RATE / 2 - 100)], 2)
        start = max(0, step * size - size // 2)
        piece = band[start : start + size * 2]
        out[start : start + len(piece)] += piece * window[: len(piece)]
    return out


def bell(t, freq, length, partials=((1, 1, 1), (2.0, 0.35, 0.55), (3.0, 0.18, 0.35), (4.2, 0.08, 0.2))):
    out = np.zeros(len(t))
    for ratio, amp, life in partials:
        out += amp * np.sin(2 * np.pi * freq * ratio * t) * decay(t, length * life, 0.003)
    return out


def place(total, sound, at):
    start = int(at * RATE)
    end = min(len(total), start + len(sound))
    total[start:end] += fade(sound[: end - start], 0.0005, 0.03)


def reverb(x, amount=0.18, length=1.1, tone=4500):
    t = timeline(length)
    ir = rng.standard_normal(len(t)) * np.exp(-t / (length / 5))
    ir = butter(ir, "lowpass", tone, 2)
    ir /= np.sqrt(np.sum(ir**2))
    dry = np.concatenate([x, np.zeros(len(t))])
    wet = np.zeros(len(dry))
    convolved = signal.fftconvolve(x, ir)
    wet[: min(len(dry), len(convolved))] = convolved[: len(dry)]
    return dry + amount * wet


def periodic_noise(seconds, shape):
    n = int(seconds * RATE)
    freqs = np.fft.rfftfreq(n, 1 / RATE)
    spectrum = np.exp(2j * np.pi * rng.random(len(freqs))) * shape(freqs)
    spectrum[0] = 0
    x = np.fft.irfft(spectrum, n)
    return x / np.max(np.abs(x))


def normalize(x, rms_target=-17.0, peak_limit=-1.0):
    x = x - np.mean(x)
    rms = np.sqrt(np.mean(x**2)) + 1e-12
    x = x * (10 ** (rms_target / 20) / rms)
    peak = np.max(np.abs(x))
    limit = 10 ** (peak_limit / 20)
    if peak > limit:
        x = np.tanh(x / peak * 1.4) / np.tanh(1.4) * limit
    return x


def click():
    t = timeline(0.09)
    tone = np.sin(sweep(t, 1500, 720, 0.03)) + 0.25 * np.sin(2 * sweep(t, 1500, 720, 0.03))
    x = tone * decay(t, 0.016, 0.001)
    return fade(butter(x, "lowpass", 6000), 0.001, 0.01)


def open_panel():
    t = timeline(0.24)
    noise = rng.standard_normal(len(t))
    air = moving_filter(noise, 500, 2600) * np.sin(np.pi * np.clip(t / 0.16, 0, 1)) ** 2
    blip_t = timeline(0.08)
    blip = np.sin(sweep(blip_t, 700, 1050, 0.05)) * decay(blip_t, 0.03)
    x = 0.5 * air
    place(x, 0.8 * blip, 0.12)
    return fade(reverb(x, 0.12, 0.5), 0.002, 0.04)


def purchase():
    t = timeline(1.2)
    x = np.zeros(len(t))
    place(x, bell(t, 784, 0.35), 0.0)
    place(x, bell(t, 1175, 0.45), 0.075)
    sparkle = butter(rng.standard_normal(len(t)), "highpass", 7000) * decay(t, 0.06)
    place(x, 0.05 * sparkle, 0.075)
    return fade(reverb(x, 0.2, 0.9), 0.002, 0.08)


def cash():
    t = timeline(1.1)
    x = np.zeros(len(t))
    cha = butter(rng.standard_normal(int(0.05 * RATE)), "bandpass", [2500, 7000]) * decay(timeline(0.05), 0.012)
    place(x, 0.6 * cha, 0.0)
    ching = bell(t, 2637, 0.3, ((1, 1, 1), (1.34, 0.6, 0.8), (2.0, 0.3, 0.5), (2.76, 0.15, 0.3)))
    place(x, 0.8 * ching, 0.055)
    place(x, 0.45 * bell(t, 3520, 0.22), 0.11)
    return fade(reverb(x, 0.16, 0.8), 0.001, 0.08)


def perfect():
    t = timeline(1.6)
    x = bell(t, 1760, 0.55, ((1, 1, 1), (2.0, 0.3, 0.6), (3.0, 0.12, 0.35), (5.4, 0.05, 0.15)))
    for index, freq in enumerate([2093, 2637, 3136, 4186]):
        place(x, 0.28 * bell(t, freq, 0.18), 0.05 + index * 0.035)
    return fade(reverb(fade(x, 0.001, 0.4), 0.28, 1.2), 0.002, 0.1)


def launch():
    t = timeline(1.9)
    f0 = 52 * (150 / 52) ** np.clip(t / 1.4, 0, 1)
    f0 *= 1 + 0.015 * np.sin(2 * np.pi * 7 * t)
    phase = 2 * np.pi * np.cumsum(f0) / RATE
    engine = sum(np.sin(n * phase) / n for n in range(1, 12))
    engine = moving_filter(engine, 350, 2600, 64)
    engine = np.tanh(2.2 * engine / np.max(np.abs(engine)))
    env = np.clip(t / 0.06, 0, 1) * np.clip((1.9 - t) / 0.35, 0, 1)
    whoosh = moving_filter(rng.standard_normal(len(t)), 300, 1800) * np.clip(t / 1.2, 0, 1) ** 2
    x = engine * env + 0.35 * whoosh / np.max(np.abs(whoosh)) * env
    return fade(x, 0.005, 0.2)


def boost_loop():
    seconds = 2.0
    t = timeline(seconds)

    def shape(f):
        body = np.exp(-((np.log(np.maximum(f, 1)) - np.log(700)) ** 2) / 1.1)
        rumble = 1.6 * np.exp(-((np.log(np.maximum(f, 1)) - np.log(90)) ** 2) / 0.5)
        return (body + rumble) * (f > 25) * (f < 9000)

    roar = periodic_noise(seconds, shape)
    flutter = 1 + 0.18 * np.sin(2 * np.pi * 18 * t)
    hum = 0.25 * np.sin(2 * np.pi * 55 * t) + 0.12 * np.sin(2 * np.pi * 110 * t)
    return np.tanh(1.5 * (roar * flutter + hum))


def wind_loop():
    seconds = 4.0
    t = timeline(seconds)

    def shape(f):
        return np.exp(-((np.log(np.maximum(f, 1)) - np.log(420)) ** 2) / 1.6) * (f > 40) * (f < 5000)

    air = periodic_noise(seconds, shape)
    swell = 1 + 0.3 * np.sin(2 * np.pi * 0.5 * t)
    return air * swell


def land():
    t = timeline(0.7)
    thump = np.sin(sweep(t, 120, 42, 0.14)) * decay(t, 0.16, 0.001)
    crunch = butter(rng.standard_normal(len(t)), "lowpass", 1200) * decay(t, 0.07, 0.001)
    clank = (np.sin(2 * np.pi * 330 * t) + 0.6 * np.sin(2 * np.pi * 495 * t)) * decay(t, 0.06)
    x = np.tanh(1.8 * (thump + 0.55 * crunch + 0.2 * clank))
    return fade(reverb(x, 0.1, 0.6, 2500), 0.001, 0.1)


def zone():
    t = timeline(2.2)
    x = np.zeros(len(t))
    for index, freq in enumerate([523.25, 659.25, 783.99, 1046.5]):
        place(x, bell(t, freq, 0.6 if index == 3 else 0.35), index * 0.075)
    sparkle = butter(rng.standard_normal(len(t)), "highpass", 6000) * decay(t, 0.25)
    place(x, 0.04 * sparkle, 0.22)
    return fade(reverb(x, 0.3, 1.4), 0.002, 0.15)


def error():
    t = timeline(0.13)
    x = np.zeros(int(0.36 * RATE))
    for index, freq in enumerate([330, 262]):
        tone = np.sin(2 * np.pi * freq * t) + 0.18 * np.sin(2 * np.pi * freq * 3 * t)
        place(x, fade(tone * decay(t, 0.07, 0.005), 0.005, 0.03), index * 0.12)
    return fade(butter(x, "lowpass", 1800), 0.002, 0.04)


def rebirth():
    t = timeline(3.2)
    rise_t = timeline(0.9)
    rise = sum(np.sin(n * sweep(rise_t, 180, 1100, 0.85)) / n for n in range(1, 6))
    rise *= np.clip(rise_t / 0.85, 0, 1) ** 2 * np.clip((0.9 - rise_t) / 0.08, 0, 1)
    x = np.zeros(len(t))
    place(x, 0.35 * butter(rise, "lowpass", 5000), 0.0)
    for freq in [523.25, 659.25, 783.99, 1046.5, 1318.5]:
        place(x, 0.45 * bell(t, freq, 0.9), 0.85)
    pad = sum(np.sin(2 * np.pi * f * t) for f in [261.6, 392.0, 523.25]) * np.exp(-np.maximum(t - 0.85, 0) / 0.6)
    pad *= np.clip((t - 0.8) / 0.1, 0, 1)
    x += 0.12 * pad
    return fade(reverb(x, 0.32, 1.6), 0.005, 0.25)


def swoosh():
    t = timeline(0.5)
    air = moving_filter(rng.standard_normal(len(t)), 2600, 380)
    env = np.sin(np.pi * np.clip(t / 0.42, 0, 1)) ** 2
    return fade(reverb(air * env, 0.1, 0.5), 0.004, 0.06)


SOUNDS = [
    ("Click", click, False, 0.5),
    ("Open", open_panel, False, 0.45),
    ("Purchase", purchase, False, 0.6),
    ("Cash", cash, False, 0.6),
    ("Perfect", perfect, False, 0.65),
    ("Launch", launch, False, 0.7),
    ("Land", land, False, 0.7),
    ("Zone", zone, False, 0.6),
    ("Error", error, False, 0.45),
    ("Rebirth", rebirth, False, 0.7),
    ("Swoosh", swoosh, False, 0.45),
    ("Boost", boost_loop, True, 0.5),
    ("Wind", wind_loop, True, 0.35),
]


def trim(x, floor_db=-58.0):
    threshold = 10 ** (floor_db / 20) * np.max(np.abs(x))
    loud = np.nonzero(np.abs(x) > threshold)[0]
    if len(loud) == 0:
        return x
    end = min(len(x), loud[-1] + int(0.02 * RATE))
    return fade(x[:end], 0.0005, 0.015)


def luau_config(layout):
    lines = ["--!strict", "", "return table.freeze({"]
    for name, start, length, looped in layout:
        lines.append(f"\t{name} = table.freeze({{ Start = {start:.3f}, Length = {length:.3f}, Looped = {'true' if looped else 'false'} }}),")
    lines.append("})")
    return "\n".join(lines) + "\n"


def main():
    os.makedirs(OUT, exist_ok=True)
    gap = 0.5
    cursor = 0.2
    parts = []
    layout = []
    for name, make, looped, _volume in SOUNDS:
        audio = make()
        audio = normalize(audio, -20.0 if looped else -17.0)
        if not looped:
            audio = trim(audio)
        audio = audio.astype(np.float32)
        soundfile.write(os.path.join(OUT, f"{name}.ogg"), audio, RATE, format="OGG", subtype="VORBIS")
        start = round(cursor, 3)
        length = len(audio) / RATE
        parts.append((start, audio))
        layout.append((name, start, length, looped))
        cursor = np.ceil((start + length + gap) * 10) / 10
    total = np.zeros(int((cursor + 0.2) * RATE), dtype=np.float32)
    for start, audio in parts:
        index = int(round(start * RATE))
        total[index : index + len(audio)] += audio
    soundfile.write(os.path.join(OUT, "SoundSprite.ogg"), total, RATE, format="OGG", subtype="VORBIS")
    with open(CONFIG, "w") as handle:
        handle.write(luau_config(layout))
    report = {name: {"start": start, "length": round(length, 3)} for name, start, length, _ in layout}
    print(json.dumps({"sprite_seconds": round(len(total) / RATE, 2), "sounds": report}, indent=1))


if __name__ == "__main__":
    sys.exit(main())
