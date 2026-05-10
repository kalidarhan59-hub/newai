"""Light Fantasy v2 — 2-minute compositions with proper song structure.

Fixes from feedback:
  - No energy dips / dead spots — continuous layering ensures presence
  - Smooth crossfades (2-3s) between every section
  - Crescendos before energy peaks
  - High frequencies preserved throughout (shimmer never fully drops)
  - Proper outro: full texture → melody+pad → pad alone → silence
  - Dynamic variation in second half (not a repeat of first half)

Two variants:
  V1 (Devin's approach): Continuous energy flow, gradual evolution
  V2 (Other AI plan):    Intro→Verse1→Chorus1→Bridge→Verse2→Chorus2→Outro
"""

from __future__ import annotations

import numpy as np

from .light_fantasy_composer import (
    bell_sound,
    harp_sound,
    pad_sound,
    piano_sound,
    pluck_sound,
    shimmer_pad,
    soft_kick,
)
from .music_producer import (
    SAMPLE_RATE,
    _fade,
    _normalize,
    _place_sound,
    note_freq,
    reverb,
    sine_wave,
)

BPM = 92
BEAT = 60.0 / BPM
HALF = BEAT / 2
BAR = BEAT * 4

# ---------------------------------------------------------------------------
# Extra synth voices for v2
# ---------------------------------------------------------------------------


def string_pad(freq: float, duration: float, volume: float = 0.18) -> np.ndarray:
    """Warm string-like pad with vibrato for emotional depth."""
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    vibrato = 3.5 * np.sin(2 * np.pi * 5.0 * t)
    sig = np.zeros(n)
    for h, amp in [(1, 1.0), (2, 0.5), (3, 0.2), (4, 0.08)]:
        sig += amp * np.sin(2 * np.pi * (freq * h + vibrato) * t)
    sig /= 1.78
    att = min(int(SAMPLE_RATE * 0.8), n // 3)
    rel = min(int(SAMPLE_RATE * 1.0), n // 3)
    env = np.ones(n)
    env[:att] = np.linspace(0, 1, att)
    env[-rel:] = np.linspace(1, 0, rel)
    return volume * sig * env


def shimmer_cymbal(duration: float, volume: float = 0.06) -> np.ndarray:
    """Light shimmer cymbal wash — keeps high frequencies alive."""
    n = int(SAMPLE_RATE * duration)
    rng = np.random.default_rng(77)
    sig = rng.uniform(-1, 1, n)
    # High-pass: subtract smoothed version
    smooth = np.convolve(sig, np.ones(80) / 80, mode="same")
    sig = sig - smooth
    att = min(int(SAMPLE_RATE * 1.5), n // 3)
    rel = min(int(SAMPLE_RATE * 2.0), n // 3)
    env = np.ones(n) * volume
    env[:att] *= np.linspace(0, 1, att)
    env[-rel:] *= np.linspace(1, 0, rel)
    return sig * env


def crescendo_swell(duration: float, volume: float = 0.2) -> np.ndarray:
    """Rising energy swell — noise + sine cluster growing."""
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    rng = np.random.default_rng(42)
    nse = rng.uniform(-1, 1, n) * 0.3
    # subtract low freq
    smooth = np.convolve(nse, np.ones(50) / 50, mode="same")
    nse = nse - smooth
    tone = np.sin(2 * np.pi * 800 * t) * 0.15
    tone += np.sin(2 * np.pi * 1200 * t) * 0.08
    sig = nse + tone
    env = np.linspace(0, volume, n)
    return sig * env


def perc_shaker(duration: float, bpm: float = 92, volume: float = 0.05) -> np.ndarray:
    """Very light shaker — 16th notes, almost subliminal."""
    n = int(SAMPLE_RATE * duration)
    layer = np.zeros(n)
    step = 60.0 / bpm / 4
    rng = np.random.default_rng(33)
    hit_n = int(SAMPLE_RATE * 0.03)
    for i in range(int(duration / step)):
        pos = int(i * step * SAMPLE_RATE)
        hit = rng.uniform(-1, 1, hit_n) * np.exp(-np.linspace(0, 8, hit_n))
        vel = volume * (0.7 if i % 4 == 0 else 0.4)
        end = min(pos + hit_n, n)
        length = end - pos
        if length > 0:
            layer[pos:end] += hit[:length] * vel
    return layer


# ---------------------------------------------------------------------------
# Chord / melody data
# ---------------------------------------------------------------------------

CHORDS_VERSE = [
    ["C3", "E3", "G3", "B3"],      # Cmaj7
    ["A2", "C3", "E3", "G3"],      # Am7
    ["F2", "A2", "C3", "E3"],      # Fmaj7
    ["G2", "B2", "D3", "F3"],      # G7
]

CHORDS_CHORUS = [
    ["F3", "A3", "C4", "E4"],      # Fmaj7
    ["C3", "E3", "G3", "B3"],      # Cmaj7
    ["D3", "F3", "A3", "C4"],      # Dm7
    ["G2", "B2", "D3", "G3"],      # G
]

CHORDS_BRIDGE = [
    ["A2", "C3", "E3"],            # Am
    ["E2", "G2", "B2"],            # Em
]

MEL_VERSE = ["E5", "G5", "B5", "A5", "G5", "E5", "D5", "C5",
             "D5", "E5", "G5", "A5", "B5", "A5", "G5", "E5"]

MEL_CHORUS = ["C5", "E5", "G5", "B5", "A5", "G5", "E5", "G5",
              "A5", "B5", "C6", "B5", "A5", "G5", "E5", "C5"]

MEL_CHORUS_HIGH = ["G5", "B5", "C6", "E6", "C6", "B5", "A5", "G5",
                   "A5", "B5", "C6", "E6", "D6", "C6", "B5", "G5"]

MEL_BRIDGE = ["A4", "C5", "E5", "C5", "A4", "G4", "A4", "E4"]

MEL_COUNTER = ["G4", "A4", "B4", "C5", "B4", "A4", "G4", "E4",
               "F4", "G4", "A4", "C5", "B4", "G4", "E4", "D4"]

PIANO_MEL = [
    ("E4", 1.0), ("G4", 0.5), ("A4", 0.5), ("B4", 1.0), ("A4", 0.5), ("G4", 0.5),
    ("E4", 1.0), ("D4", 1.0), ("C4", 1.5), ("E4", 0.5),
]

ARP_A = ["C5", "E5", "G5", "B5", "G5", "E5"]
ARP_B = ["A4", "C5", "E5", "G5", "E5", "C5"]
ARP_C = ["F4", "A4", "C5", "E5", "C5", "A4"]


# ---------------------------------------------------------------------------
# Section builders (each returns a fixed-length numpy array)
# ---------------------------------------------------------------------------

def _mix(layers: list[np.ndarray], n: int) -> np.ndarray:
    m = np.zeros(n)
    for layer in layers:
        end = min(len(layer), n)
        m[:end] += layer[:end]
    return m


def _pad_layer(n: int, dur: float, chords: list[list[str]], vol: float = 0.1) -> np.ndarray:
    layer = np.zeros(n)
    chord_dur = dur / len(chords)
    for i, chord in enumerate(chords):
        for note in chord:
            snd = pad_sound(note_freq(note), chord_dur * 1.3, volume=vol)
            pos = int(i * chord_dur * SAMPLE_RATE)
            _place_sound(layer, snd, pos)
    return layer


def _shimmer_layer(n: int, dur: float, vol: float = 0.07) -> np.ndarray:
    layer = np.zeros(n)
    notes = ["C4", "E4", "G4"]
    seg = dur / max(len(notes), 1)
    for i, note in enumerate(notes):
        snd = shimmer_pad(note_freq(note), seg * 1.5, volume=vol)
        _place_sound(layer, snd, int(i * seg * SAMPLE_RATE))
    return layer


def _bell_arp(n: int, dur: float, arp: list[str], vol: float = 0.13) -> np.ndarray:
    layer = np.zeros(n)
    step = HALF
    for i in range(int(dur / step)):
        note = arp[i % len(arp)]
        snd = bell_sound(note_freq(note), step * 2.0, volume=vol)
        _place_sound(layer, snd, int(i * step * SAMPLE_RATE))
    return layer


def _harp_arp(n: int, dur: float, arp: list[str], vol: float = 0.15) -> np.ndarray:
    layer = np.zeros(n)
    step = HALF
    for i in range(int(dur / step)):
        note = arp[i % len(arp)]
        v = vol if i % 2 == 0 else vol * 0.6
        snd = harp_sound(note_freq(note), step * 1.8, volume=v)
        _place_sound(layer, snd, int(i * step * SAMPLE_RATE))
    return layer


def _melody(n: int, dur: float, notes: list[str], wave_fn: object = sine_wave,
            vol: float = 0.18) -> np.ndarray:
    layer = np.zeros(n)
    step = BEAT
    for i, note in enumerate(notes):
        t = i * step
        if t >= dur:
            break
        d = min(step * 0.9, dur - t)
        snd = wave_fn(note_freq(note), d, volume=vol)  # type: ignore[operator]
        snd = _fade(snd, fade_in=int(len(snd) * 0.08), fade_out=int(len(snd) * 0.2))
        _place_sound(layer, snd, int(t * SAMPLE_RATE))
    return layer


def _piano_melody(n: int, dur: float, phrases: list[tuple[str, float]],
                  vol: float = 0.2) -> np.ndarray:
    layer = np.zeros(n)
    t = 0.0
    for note_name, beats in phrases:
        if t >= dur:
            break
        d = min(beats * BEAT, dur - t)
        snd = piano_sound(note_freq(note_name), d, volume=vol)
        _place_sound(layer, snd, int(t * SAMPLE_RATE))
        t += beats * BEAT
    return layer


def _piano_bg(n: int, dur: float, vol: float = 0.09) -> np.ndarray:
    layer = np.zeros(n)
    t = 0.0
    idx = 0
    chords = [["C4", "E4", "G4"], ["A3", "C4", "E4"], ["F3", "A3", "C4"], ["G3", "B3", "D4"]]
    while t < dur:
        chord = chords[idx % len(chords)]
        for j, note in enumerate(chord):
            nt = t + j * HALF
            if nt >= dur:
                break
            d = min(BAR * 0.8, dur - nt)
            snd = piano_sound(note_freq(note), d, volume=vol)
            _place_sound(layer, snd, int(nt * SAMPLE_RATE))
        t += BAR
        idx += 1
    return layer


def _soft_beat(n: int, dur: float, vol: float = 0.2) -> np.ndarray:
    layer = np.zeros(n)
    for bar in range(int(dur / BAR) + 1):
        for beat_off in [0, 2]:
            t = bar * BAR + beat_off * BEAT
            if t >= dur:
                break
            v = vol if beat_off == 0 else vol * 0.6
            _place_sound(layer, soft_kick() * v, int(t * SAMPLE_RATE))
    return layer


def _string_layer(n: int, dur: float, chords: list[list[str]], vol: float = 0.12) -> np.ndarray:
    layer = np.zeros(n)
    chord_dur = dur / max(len(chords), 1)
    for i, chord in enumerate(chords):
        for note in chord:
            snd = string_pad(note_freq(note), chord_dur * 1.2, volume=vol)
            _place_sound(layer, snd, int(i * chord_dur * SAMPLE_RATE))
    return layer


# ---------------------------------------------------------------------------
# Crossfade utility
# ---------------------------------------------------------------------------

def _crossfade(a: np.ndarray, b: np.ndarray, overlap: int) -> np.ndarray:
    if overlap <= 0 or len(a) == 0 or len(b) == 0:
        return np.concatenate([a, b])
    overlap = min(overlap, len(a), len(b))
    out = np.zeros(len(a) + len(b) - overlap)
    out[:len(a)] = a
    fo = np.linspace(1, 0, overlap)
    fi = np.linspace(0, 1, overlap)
    start = len(a) - overlap
    out[start:start + overlap] = a[-overlap:] * fo + b[:overlap] * fi
    out[len(a):] = b[overlap:]
    return out


# ---------------------------------------------------------------------------
# Variant 1 — Devin's approach: continuous evolution, smooth energy
# ---------------------------------------------------------------------------

def compose_v1_devin(duration: float = 120.0) -> np.ndarray:
    """Continuous flowing Light Fantasy — no dead spots, gradual evolution.

    Structure (smooth energy curve):
      0-12s    Intro: pad + shimmer fade in, bell arp enters gradually
     12-30s    Build A: melody enters, harp joins, soft beat, crescendo at end
     30-50s    Peak A: full texture, piano accents, energy peak
     50-60s    Breath: thin out gracefully (one instrument stays), shimmer+reverb tail
     60-75s    Build B: new melodic variation, strings added, growing energy
     75-100s   Peak B: maximum layers, counter-melody, piano, shimmer cymbals
    100-115s   Wind down: layers drop one by one (not abrupt)
    115-120s   Final: solo pad → silence (proper ending, no cut)
    """
    xf = int(SAMPLE_RATE * 2.5)  # 2.5s crossfade

    # --- Intro (0-12s): ethereal, gentle ---
    d1 = 14.0
    n1 = int(d1 * SAMPLE_RATE)
    intro = _mix([
        _pad_layer(n1, d1, CHORDS_VERSE, vol=0.08),
        _shimmer_layer(n1, d1, vol=0.06),
        _bell_arp(n1, d1, ARP_A, vol=0.07),
    ], n1)
    intro = _fade(intro, fade_in=int(SAMPLE_RATE * 2.0), fade_out=0)

    # --- Build A (12-30s): melody, harp, soft beat, crescendo at end ---
    d2 = 20.0
    n2 = int(d2 * SAMPLE_RATE)
    build_a = _mix([
        _pad_layer(n2, d2, CHORDS_VERSE, vol=0.1),
        _shimmer_layer(n2, d2, vol=0.07),
        _bell_arp(n2, d2, ARP_A, vol=0.12),
        _harp_arp(n2, d2, ARP_C, vol=0.1),
        _melody(n2, d2, MEL_VERSE, sine_wave, vol=0.16),
        _soft_beat(n2, d2, vol=0.15),
    ], n2)
    # 3s crescendo swell at the end
    swell = crescendo_swell(3.0, volume=0.12)
    _place_sound(build_a, swell, n2 - len(swell))

    # --- Peak A (30-50s): full texture, piano ---
    d3 = 22.0
    n3 = int(d3 * SAMPLE_RATE)
    peak_a = _mix([
        _pad_layer(n3, d3, CHORDS_CHORUS, vol=0.12),
        _shimmer_layer(n3, d3, vol=0.08),
        _bell_arp(n3, d3, ARP_B, vol=0.14),
        _harp_arp(n3, d3, ARP_A, vol=0.12),
        _melody(n3, d3, MEL_CHORUS, sine_wave, vol=0.2),
        _melody(n3, d3, MEL_COUNTER, pluck_sound, vol=0.1),
        _soft_beat(n3, d3, vol=0.2),
        _piano_melody(n3, d3, list(PIANO_MEL), vol=0.15),
        shimmer_cymbal(d3, volume=0.04),
    ], n3)

    # --- Breath (50-60s): thin texture, space ---
    d4 = 12.0
    n4 = int(d4 * SAMPLE_RATE)
    breath = _mix([
        _pad_layer(n4, d4, CHORDS_BRIDGE, vol=0.08),
        _shimmer_layer(n4, d4, vol=0.06),
        _harp_arp(n4, d4, ARP_C, vol=0.08),
    ], n4)

    # --- Build B (60-75s): new variation, strings, growing ---
    d5 = 17.0
    n5 = int(d5 * SAMPLE_RATE)
    build_b = _mix([
        _pad_layer(n5, d5, CHORDS_VERSE, vol=0.1),
        _string_layer(n5, d5, CHORDS_VERSE, vol=0.1),
        _shimmer_layer(n5, d5, vol=0.07),
        _bell_arp(n5, d5, ARP_B, vol=0.13),
        _harp_arp(n5, d5, ARP_A, vol=0.12),
        _melody(n5, d5, MEL_CHORUS, sine_wave, vol=0.17),
        _melody(n5, d5, MEL_BRIDGE, pluck_sound, vol=0.09),
        _soft_beat(n5, d5, vol=0.18),
        perc_shaker(d5, volume=0.04),
    ], n5)
    swell2 = crescendo_swell(3.0, volume=0.1)
    _place_sound(build_b, swell2, n5 - len(swell2))

    # --- Peak B (75-100s): max layers, emotional peak ---
    d6 = 27.0
    n6 = int(d6 * SAMPLE_RATE)
    peak_b = _mix([
        _pad_layer(n6, d6, CHORDS_CHORUS, vol=0.12),
        _string_layer(n6, d6, CHORDS_CHORUS, vol=0.12),
        _shimmer_layer(n6, d6, vol=0.09),
        _bell_arp(n6, d6, ARP_A, vol=0.15),
        _harp_arp(n6, d6, ARP_B, vol=0.13),
        _melody(n6, d6, MEL_CHORUS_HIGH, sine_wave, vol=0.2),
        _melody(n6, d6, MEL_COUNTER, pluck_sound, vol=0.12),
        _soft_beat(n6, d6, vol=0.22),
        _piano_melody(n6, d6, list(PIANO_MEL), vol=0.18),
        _piano_bg(n6, d6, vol=0.06),
        shimmer_cymbal(d6, volume=0.05),
        perc_shaker(d6, volume=0.04),
    ], n6)

    # --- Wind down (100-115s): layers drop gradually ---
    d7 = 17.0
    n7 = int(d7 * SAMPLE_RATE)
    # Start full, strip layers over time
    wd_pad = _pad_layer(n7, d7, CHORDS_VERSE, vol=0.1)
    wd_shimmer = _shimmer_layer(n7, d7, vol=0.06)
    wd_melody = _melody(n7, d7, MEL_VERSE, sine_wave, vol=0.15)
    wd_melody = _fade(wd_melody, fade_in=0, fade_out=int(SAMPLE_RATE * 8.0))
    wd_harp = _harp_arp(n7, d7, ARP_C, vol=0.1)
    wd_harp = _fade(wd_harp, fade_in=0, fade_out=int(SAMPLE_RATE * 6.0))
    wd_beat = _soft_beat(n7, d7, vol=0.15)
    wd_beat = _fade(wd_beat, fade_in=0, fade_out=int(SAMPLE_RATE * 5.0))
    wind_down = _mix([wd_pad, wd_shimmer, wd_melody, wd_harp, wd_beat], n7)

    # --- Final (115-120s): solo pad dissolves ---
    d8 = 7.0
    n8 = int(d8 * SAMPLE_RATE)
    final_pad = _pad_layer(n8, d8, [["C3", "E3", "G3", "B3"]], vol=0.08)
    final_shimmer = _shimmer_layer(n8, d8, vol=0.03)
    final = _mix([final_pad, final_shimmer], n8)
    final = _fade(final, fade_in=0, fade_out=int(SAMPLE_RATE * 5.0))

    # Assemble with crossfades
    track = intro
    for seg in [build_a, peak_a, breath, build_b, peak_b, wind_down, final]:
        track = _crossfade(track, seg, xf)

    track = reverb(track, decay=0.22, delay_ms=32)
    track = _fade(track, fade_in=int(SAMPLE_RATE * 1.5), fade_out=int(SAMPLE_RATE * 0.5))

    target = int(duration * SAMPLE_RATE)
    if len(track) > target:
        track = track[:target]
        track = _fade(track, fade_in=0, fade_out=int(SAMPLE_RATE * 2.0))
    elif len(track) < target:
        track = np.concatenate([track, np.zeros(target - len(track))])

    return _normalize(track)


# ---------------------------------------------------------------------------
# Variant 2 — Other AI plan: structured sections
# ---------------------------------------------------------------------------

def compose_v2_structured(duration: float = 120.0) -> np.ndarray:
    """Structured Light Fantasy per the other AI's plan.

    Intro      0:00-0:10  (10s)
    Verse 1    0:10-0:23  (13s)
    Chorus 1   0:23-0:40  (17s)
    Bridge     0:40-0:55  (15s)  — "breath moment", single instrument
    Verse 2    0:55-1:10  (15s)  — same melody + counter-melody
    Chorus 2   1:10-1:35  (25s)  — original + new layers (strings, perc)
    Outro      1:35-2:00  (25s)  — full → melody+pad → pad → silence
    """
    xf = int(SAMPLE_RATE * 2.5)

    # --- Intro 0:00-0:10 ---
    d = 12.0
    n = int(d * SAMPLE_RATE)
    intro = _mix([
        _pad_layer(n, d, CHORDS_VERSE, vol=0.08),
        _shimmer_layer(n, d, vol=0.06),
        _bell_arp(n, d, ARP_A, vol=0.06),
    ], n)
    intro = _fade(intro, fade_in=int(SAMPLE_RATE * 2.5), fade_out=0)
    # 2s crescendo into verse
    swell = crescendo_swell(2.5, volume=0.08)
    _place_sound(intro, swell, n - len(swell))

    # --- Verse 1 0:10-0:23 ---
    d = 15.0
    n = int(d * SAMPLE_RATE)
    verse1 = _mix([
        _pad_layer(n, d, CHORDS_VERSE, vol=0.1),
        _shimmer_layer(n, d, vol=0.07),
        _bell_arp(n, d, ARP_A, vol=0.12),
        _harp_arp(n, d, ARP_C, vol=0.1),
        _melody(n, d, MEL_VERSE, sine_wave, vol=0.18),
        _soft_beat(n, d, vol=0.15),
    ], n)
    # Crescendo before chorus
    swell = crescendo_swell(3.0, volume=0.1)
    _place_sound(verse1, swell, n - len(swell))

    # --- Chorus 1 0:23-0:40 ---
    d = 19.0
    n = int(d * SAMPLE_RATE)
    chorus1 = _mix([
        _pad_layer(n, d, CHORDS_CHORUS, vol=0.12),
        _shimmer_layer(n, d, vol=0.08),
        _bell_arp(n, d, ARP_B, vol=0.14),
        _harp_arp(n, d, ARP_A, vol=0.12),
        _melody(n, d, MEL_CHORUS, sine_wave, vol=0.2),
        _melody(n, d, MEL_COUNTER, pluck_sound, vol=0.1),
        _soft_beat(n, d, vol=0.2),
        _piano_melody(n, d, list(PIANO_MEL), vol=0.13),
        shimmer_cymbal(d, volume=0.04),
    ], n)

    # --- Bridge 0:40-0:55 — "breath moment" ---
    d = 17.0
    n = int(d * SAMPLE_RATE)
    # Only one main element (harp arpeggio) + light pad underneath
    bridge = _mix([
        _pad_layer(n, d, CHORDS_BRIDGE, vol=0.06),
        _harp_arp(n, d, ARP_C, vol=0.12),
        _shimmer_layer(n, d, vol=0.04),
    ], n)
    # Crescendo in last 3s to prepare for verse 2
    swell = crescendo_swell(3.0, volume=0.1)
    _place_sound(bridge, swell, n - len(swell))

    # --- Verse 2 0:55-1:10 — same melody + counter-melody ---
    d = 17.0
    n = int(d * SAMPLE_RATE)
    verse2 = _mix([
        _pad_layer(n, d, CHORDS_VERSE, vol=0.1),
        _shimmer_layer(n, d, vol=0.07),
        _bell_arp(n, d, ARP_B, vol=0.13),
        _harp_arp(n, d, ARP_A, vol=0.11),
        _melody(n, d, MEL_VERSE, sine_wave, vol=0.18),
        _melody(n, d, MEL_COUNTER, pluck_sound, vol=0.12),
        _soft_beat(n, d, vol=0.18),
        perc_shaker(d, volume=0.03),
    ], n)
    swell = crescendo_swell(3.0, volume=0.12)
    _place_sound(verse2, swell, n - len(swell))

    # --- Chorus 2 1:10-1:35 — emotional peak, new layers ---
    d = 27.0
    n = int(d * SAMPLE_RATE)
    chorus2 = _mix([
        _pad_layer(n, d, CHORDS_CHORUS, vol=0.12),
        _string_layer(n, d, CHORDS_CHORUS, vol=0.12),
        _shimmer_layer(n, d, vol=0.09),
        _bell_arp(n, d, ARP_A, vol=0.15),
        _harp_arp(n, d, ARP_B, vol=0.13),
        _melody(n, d, MEL_CHORUS_HIGH, sine_wave, vol=0.2),
        _melody(n, d, MEL_COUNTER, pluck_sound, vol=0.12),
        _soft_beat(n, d, vol=0.22),
        _piano_melody(n, d, list(PIANO_MEL), vol=0.18),
        _piano_bg(n, d, vol=0.06),
        shimmer_cymbal(d, volume=0.05),
        perc_shaker(d, volume=0.04),
    ], n)

    # --- Outro 1:35-2:00 — proper 3-stage ending ---
    # Stage 1 (8s): still fairly full
    d_o1 = 10.0
    n_o1 = int(d_o1 * SAMPLE_RATE)
    outro1 = _mix([
        _pad_layer(n_o1, d_o1, CHORDS_VERSE, vol=0.1),
        _shimmer_layer(n_o1, d_o1, vol=0.06),
        _bell_arp(n_o1, d_o1, ARP_A, vol=0.1),
        _melody(n_o1, d_o1, MEL_VERSE, sine_wave, vol=0.15),
        _harp_arp(n_o1, d_o1, ARP_C, vol=0.08),
    ], n_o1)
    # Fade out melody + bells over this section
    outro1_mel_fade = np.ones(n_o1)
    outro1_mel_fade[n_o1 // 2:] = np.linspace(1, 0.3, n_o1 - n_o1 // 2)
    outro1 *= outro1_mel_fade

    # Stage 2 (8s): melody + pad only
    d_o2 = 10.0
    n_o2 = int(d_o2 * SAMPLE_RATE)
    outro2_mel = _melody(n_o2, d_o2, ["E5", "D5", "C5", "B4", "A4", "G4", "E4", "C4"],
                         sine_wave, vol=0.12)
    outro2_mel = _fade(outro2_mel, fade_in=0, fade_out=int(SAMPLE_RATE * 5.0))
    outro2 = _mix([
        _pad_layer(n_o2, d_o2, [["C3", "E3", "G3", "B3"]], vol=0.08),
        _shimmer_layer(n_o2, d_o2, vol=0.04),
        outro2_mel,
    ], n_o2)

    # Stage 3 (7s): pad alone → silence
    d_o3 = 9.0
    n_o3 = int(d_o3 * SAMPLE_RATE)
    outro3 = _mix([
        _pad_layer(n_o3, d_o3, [["C3", "E3", "G3"]], vol=0.06),
        _shimmer_layer(n_o3, d_o3, vol=0.02),
    ], n_o3)
    outro3 = _fade(outro3, fade_in=0, fade_out=int(SAMPLE_RATE * 7.0))

    # Combine outro stages with crossfades
    outro = _crossfade(outro1, outro2, int(SAMPLE_RATE * 2.0))
    outro = _crossfade(outro, outro3, int(SAMPLE_RATE * 2.0))

    # Assemble all sections
    track = intro
    for seg in [verse1, chorus1, bridge, verse2, chorus2, outro]:
        track = _crossfade(track, seg, xf)

    track = reverb(track, decay=0.22, delay_ms=32)
    track = _fade(track, fade_in=int(SAMPLE_RATE * 1.0), fade_out=int(SAMPLE_RATE * 0.3))

    target = int(duration * SAMPLE_RATE)
    if len(track) > target:
        track = track[:target]
        track = _fade(track, fade_in=0, fade_out=int(SAMPLE_RATE * 3.0))
    elif len(track) < target:
        track = np.concatenate([track, np.zeros(target - len(track))])

    return _normalize(track)
