"""Light Fantasy v3 — clean 2-minute composition.

Key principles:
  - NO noise-based sounds (no shimmer cymbal, no shaker, no swell noise)
  - Only clean, pure instruments: pads, bells, harp, piano, strings, sine
  - Harp/bell arpeggio runs CONTINUOUSLY from start to end — never stops
  - Inspired by Space II: warm evolving pads, dreamy flowing textures
  - Smooth energy curve: gradual build, no dead spots, proper ending
"""

from __future__ import annotations

import numpy as np

from .light_fantasy_composer import (
    bell_sound,
    harp_sound,
    pad_sound,
    piano_sound,
    pluck_sound,
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
# Clean synth voices (no noise)
# ---------------------------------------------------------------------------


def space_pad(freq: float, duration: float, volume: float = 0.2) -> np.ndarray:
    """Warm, evolving space pad — layered detuned sines with slow LFO.

    Inspired by Space II: smooth, cosmic, organic movement.
    """
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    sig = np.zeros(n)
    # Main body: 7 detuned voices for richness
    for detune_cents in [-5, -3, -1, 0, 1, 3, 5]:
        f = freq * (2 ** (detune_cents / 1200))
        sig += np.sin(2 * np.pi * f * t)
    sig /= 7
    # Slow LFO modulation for organic movement
    lfo = 0.85 + 0.15 * np.sin(2 * np.pi * 0.3 * t)
    sig *= lfo
    # Smooth envelope
    att = min(int(SAMPLE_RATE * 1.0), n // 3)
    rel = min(int(SAMPLE_RATE * 1.2), n // 3)
    env = np.ones(n)
    env[:att] = np.linspace(0, 1, att)
    env[-rel:] = np.linspace(1, 0, rel)
    return volume * sig * env


def octave_pad(freq: float, duration: float, volume: float = 0.12) -> np.ndarray:
    """Octave-doubled ethereal pad — adds sparkle without noise."""
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    sig = np.sin(2 * np.pi * freq * t) * 0.4
    sig += np.sin(2 * np.pi * freq * 2 * t) * 0.3
    sig += np.sin(2 * np.pi * freq * 4 * t) * 0.15
    sig += np.sin(2 * np.pi * freq * 3 * t) * 0.1
    # Gentle tremolo
    trem = 0.9 + 0.1 * np.sin(2 * np.pi * 0.5 * t)
    sig *= trem
    att = min(int(SAMPLE_RATE * 0.8), n // 3)
    rel = min(int(SAMPLE_RATE * 1.0), n // 3)
    env = np.ones(n)
    env[:att] = np.linspace(0, 1, att)
    env[-rel:] = np.linspace(1, 0, rel)
    return volume * sig * env


def string_pad(freq: float, duration: float, volume: float = 0.15) -> np.ndarray:
    """Clean string pad with vibrato."""
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    vibrato = 3.0 * np.sin(2 * np.pi * 5.0 * t)
    sig = np.zeros(n)
    for h, amp in [(1, 1.0), (2, 0.45), (3, 0.15)]:
        sig += amp * np.sin(2 * np.pi * (freq * h + vibrato) * t)
    sig /= 1.6
    att = min(int(SAMPLE_RATE * 0.7), n // 3)
    rel = min(int(SAMPLE_RATE * 0.8), n // 3)
    env = np.ones(n)
    env[:att] = np.linspace(0, 1, att)
    env[-rel:] = np.linspace(1, 0, rel)
    return volume * sig * env


# ---------------------------------------------------------------------------
# Chord / melody data
# ---------------------------------------------------------------------------

CHORDS_A = [
    ["C3", "E3", "G3", "B3"],      # Cmaj7
    ["A2", "C3", "E3", "G3"],      # Am7
    ["F2", "A2", "C3", "E3"],      # Fmaj7
    ["G2", "B2", "D3", "F3"],      # G7
]

CHORDS_B = [
    ["F3", "A3", "C4", "E4"],      # Fmaj7
    ["C3", "E3", "G3", "B3"],      # Cmaj7
    ["D3", "F3", "A3", "C4"],      # Dm7
    ["G2", "B2", "D3", "G3"],      # G
]

CHORDS_C = [
    ["D3", "F3", "A3", "C4"],      # Dm7
    ["E3", "G3", "B3", "D4"],      # Em7
    ["F3", "A3", "C4", "E4"],      # Fmaj7
    ["C3", "E3", "G3", "B3"],      # Cmaj7
]

# Harp arpeggio notes (cycle through these continuously)
HARP_ARP = ["C5", "E5", "G5", "B5", "G5", "E5", "A4", "C5", "E5", "G5", "E5", "C5",
            "F4", "A4", "C5", "E5", "C5", "A4", "G4", "B4", "D5", "G5", "D5", "B4"]

# Bell arpeggio notes
BELL_ARP = ["E5", "G5", "B5", "E6", "B5", "G5"]

# Melodies
MEL_MAIN = ["E5", "G5", "B5", "A5", "G5", "E5", "D5", "C5",
            "D5", "E5", "G5", "A5", "B5", "A5", "G5", "E5"]

MEL_VAR = ["C5", "E5", "G5", "B5", "A5", "G5", "E5", "G5",
           "A5", "B5", "C6", "B5", "A5", "G5", "E5", "C5"]

MEL_HIGH = ["G5", "B5", "C6", "E6", "C6", "B5", "A5", "G5",
            "A5", "B5", "C6", "E6", "D6", "C6", "B5", "G5"]

MEL_COUNTER = ["G4", "A4", "B4", "C5", "B4", "A4", "G4", "E4",
               "F4", "G4", "A4", "C5", "B4", "G4", "E4", "D4"]

MEL_DESCEND = ["B5", "A5", "G5", "E5", "D5", "C5", "B4", "A4",
               "G4", "E4", "D4", "C4"]

PIANO_PHRASE = [
    ("E4", 1.0), ("G4", 0.5), ("A4", 0.5), ("B4", 1.0), ("A4", 0.5), ("G4", 0.5),
    ("E4", 1.0), ("D4", 1.0), ("C4", 1.5), ("E4", 0.5),
]


# ---------------------------------------------------------------------------
# Layer builders
# ---------------------------------------------------------------------------

def _mix(layers: list[np.ndarray], n: int) -> np.ndarray:
    m = np.zeros(n)
    for layer in layers:
        end = min(len(layer), n)
        m[:end] += layer[:end]
    return m


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


def _continuous_harp(n: int, dur: float, vol: float = 0.15) -> np.ndarray:
    """Harp arpeggio that plays CONTINUOUSLY for the entire duration."""
    layer = np.zeros(n)
    step = HALF
    for i in range(int(dur / step) + 1):
        t = i * step
        if t >= dur:
            break
        note = HARP_ARP[i % len(HARP_ARP)]
        v = vol if i % 2 == 0 else vol * 0.7
        snd = harp_sound(note_freq(note), step * 1.8, volume=v)
        _place_sound(layer, snd, int(t * SAMPLE_RATE))
    return layer


def _continuous_bells(n: int, dur: float, vol: float = 0.12) -> np.ndarray:
    """Bell arpeggio that plays CONTINUOUSLY for the entire duration."""
    layer = np.zeros(n)
    step = HALF
    for i in range(int(dur / step) + 1):
        t = i * step
        if t >= dur:
            break
        note = BELL_ARP[i % len(BELL_ARP)]
        snd = bell_sound(note_freq(note), step * 2.0, volume=vol)
        _place_sound(layer, snd, int(t * SAMPLE_RATE))
    return layer


def _pad_bed(n: int, dur: float, chords: list[list[str]], vol: float = 0.1) -> np.ndarray:
    layer = np.zeros(n)
    chord_dur = dur / max(len(chords), 1)
    for i, chord in enumerate(chords):
        for note in chord:
            snd = pad_sound(note_freq(note), chord_dur * 1.3, volume=vol)
            _place_sound(layer, snd, int(i * chord_dur * SAMPLE_RATE))
    return layer


def _space_pad_bed(n: int, dur: float, chords: list[list[str]], vol: float = 0.08) -> np.ndarray:
    layer = np.zeros(n)
    chord_dur = dur / max(len(chords), 1)
    for i, chord in enumerate(chords):
        for note in chord:
            snd = space_pad(note_freq(note), chord_dur * 1.2, volume=vol)
            _place_sound(layer, snd, int(i * chord_dur * SAMPLE_RATE))
    return layer


def _octave_shimmer(n: int, dur: float, vol: float = 0.06) -> np.ndarray:
    """Clean octave pad shimmer — replaces noisy shimmer_cymbal."""
    layer = np.zeros(n)
    notes = ["C4", "E4", "G4"]
    seg = dur / max(len(notes), 1)
    for i, note in enumerate(notes):
        snd = octave_pad(note_freq(note), seg * 1.5, volume=vol)
        _place_sound(layer, snd, int(i * seg * SAMPLE_RATE))
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
                  vol: float = 0.18) -> np.ndarray:
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


def _string_layer(n: int, dur: float, chords: list[list[str]], vol: float = 0.1) -> np.ndarray:
    layer = np.zeros(n)
    chord_dur = dur / max(len(chords), 1)
    for i, chord in enumerate(chords):
        for note in chord:
            snd = string_pad(note_freq(note), chord_dur * 1.2, volume=vol)
            _place_sound(layer, snd, int(i * chord_dur * SAMPLE_RATE))
    return layer


def _soft_beat(n: int, dur: float, vol: float = 0.15) -> np.ndarray:
    layer = np.zeros(n)
    for bar in range(int(dur / BAR) + 1):
        for beat_off in [0, 2]:
            t = bar * BAR + beat_off * BEAT
            if t >= dur:
                break
            v = vol if beat_off == 0 else vol * 0.5
            _place_sound(layer, soft_kick() * v, int(t * SAMPLE_RATE))
    return layer


# ---------------------------------------------------------------------------
# Volume automation — smooth energy curve over entire track
# ---------------------------------------------------------------------------

def _volume_curve(n: int, points: list[tuple[float, float]]) -> np.ndarray:
    """Create a smooth volume envelope from (time_fraction, volume) points.

    Interpolates linearly between points. Used to shape overall energy.
    """
    env = np.ones(n)
    for i in range(len(points) - 1):
        t0, v0 = points[i]
        t1, v1 = points[i + 1]
        s0 = int(t0 * n)
        s1 = int(t1 * n)
        s0 = max(0, min(s0, n))
        s1 = max(0, min(s1, n))
        if s1 > s0:
            env[s0:s1] = np.linspace(v0, v1, s1 - s0)
    if len(points) > 0:
        env[:max(1, int(points[0][0] * n))] = points[0][1]
        env[int(points[-1][0] * n):] = points[-1][1]
    return env


# ---------------------------------------------------------------------------
# Main composition
# ---------------------------------------------------------------------------

def compose_light_fantasy_v3(duration: float = 120.0) -> np.ndarray:
    """Clean 2-minute Light Fantasy — Space II inspired.

    Structure:
      0:00-0:12  Intro: space pad fades in, harp+bells start (and NEVER stop)
      0:12-0:30  Verse: melody enters over continuous arpeggios
      0:30-0:50  Chorus: fuller pads, piano joins, energy peak 1
      0:50-1:00  Bridge: thinner (but harp/bells CONTINUE), just less layers
      1:00-1:18  Verse 2: melody variation + counter-melody
      1:18-1:40  Chorus 2: max energy, strings, piano, high melody
      1:40-1:52  Wind down: layers reduce one by one (harp stays)
      1:52-2:00  Outro: melody descends, pad + harp fade to silence
    """
    n = int(duration * SAMPLE_RATE)

    # ===== CONTINUOUS LAYERS (play from start to end) =====
    # These NEVER stop — they are the backbone
    harp_continuous = _continuous_harp(n, duration, vol=0.14)
    bells_continuous = _continuous_bells(n, duration, vol=0.10)

    # ===== SECTION LAYERS (added on top at specific times) =====

    # -- Intro 0:00-0:12 --
    intro_start, intro_end = 0.0, 14.0
    intro_n = int((intro_end - intro_start) * SAMPLE_RATE)
    intro_pad = _space_pad_bed(intro_n, intro_end - intro_start, CHORDS_A, vol=0.08)
    intro_oct = _octave_shimmer(intro_n, intro_end - intro_start, vol=0.05)
    intro = _mix([intro_pad, intro_oct], intro_n)
    intro = _fade(intro, fade_in=int(SAMPLE_RATE * 3.0), fade_out=0)

    # -- Verse 1 0:12-0:30 --
    v1_dur = 20.0
    v1_n = int(v1_dur * SAMPLE_RATE)
    v1 = _mix([
        _pad_bed(v1_n, v1_dur, CHORDS_A, vol=0.1),
        _space_pad_bed(v1_n, v1_dur, CHORDS_A, vol=0.06),
        _melody(v1_n, v1_dur, MEL_MAIN, sine_wave, vol=0.18),
        _soft_beat(v1_n, v1_dur, vol=0.12),
    ], v1_n)

    # -- Chorus 1 0:30-0:50 --
    c1_dur = 22.0
    c1_n = int(c1_dur * SAMPLE_RATE)
    c1 = _mix([
        _pad_bed(c1_n, c1_dur, CHORDS_B, vol=0.12),
        _space_pad_bed(c1_n, c1_dur, CHORDS_B, vol=0.07),
        _octave_shimmer(c1_n, c1_dur, vol=0.06),
        _melody(c1_n, c1_dur, MEL_VAR, sine_wave, vol=0.2),
        _melody(c1_n, c1_dur, MEL_COUNTER, pluck_sound, vol=0.1),
        _piano_melody(c1_n, c1_dur, list(PIANO_PHRASE), vol=0.14),
        _soft_beat(c1_n, c1_dur, vol=0.18),
    ], c1_n)

    # -- Bridge 0:50-1:00 (harp/bells CONTINUE, just fewer layers) --
    br_dur = 12.0
    br_n = int(br_dur * SAMPLE_RATE)
    br = _mix([
        _space_pad_bed(br_n, br_dur, [CHORDS_A[0], CHORDS_A[2]], vol=0.07),
    ], br_n)

    # -- Verse 2 1:00-1:18 --
    v2_dur = 20.0
    v2_n = int(v2_dur * SAMPLE_RATE)
    v2 = _mix([
        _pad_bed(v2_n, v2_dur, CHORDS_C, vol=0.1),
        _space_pad_bed(v2_n, v2_dur, CHORDS_C, vol=0.06),
        _melody(v2_n, v2_dur, MEL_MAIN, sine_wave, vol=0.18),
        _melody(v2_n, v2_dur, MEL_COUNTER, pluck_sound, vol=0.12),
        _soft_beat(v2_n, v2_dur, vol=0.15),
    ], v2_n)

    # -- Chorus 2 1:18-1:40 (emotional peak) --
    c2_dur = 24.0
    c2_n = int(c2_dur * SAMPLE_RATE)
    c2 = _mix([
        _pad_bed(c2_n, c2_dur, CHORDS_B, vol=0.12),
        _space_pad_bed(c2_n, c2_dur, CHORDS_B, vol=0.08),
        _string_layer(c2_n, c2_dur, CHORDS_B, vol=0.1),
        _octave_shimmer(c2_n, c2_dur, vol=0.07),
        _melody(c2_n, c2_dur, MEL_HIGH, sine_wave, vol=0.2),
        _melody(c2_n, c2_dur, MEL_COUNTER, pluck_sound, vol=0.12),
        _piano_melody(c2_n, c2_dur, list(PIANO_PHRASE), vol=0.16),
        _soft_beat(c2_n, c2_dur, vol=0.2),
    ], c2_n)

    # -- Wind down 1:40-1:52 --
    wd_dur = 14.0
    wd_n = int(wd_dur * SAMPLE_RATE)
    wd_mel = _melody(wd_n, wd_dur, MEL_MAIN, sine_wave, vol=0.15)
    wd_mel = _fade(wd_mel, fade_in=0, fade_out=int(SAMPLE_RATE * 8.0))
    wd_beat = _soft_beat(wd_n, wd_dur, vol=0.12)
    wd_beat = _fade(wd_beat, fade_in=0, fade_out=int(SAMPLE_RATE * 6.0))
    wd = _mix([
        _pad_bed(wd_n, wd_dur, CHORDS_A, vol=0.08),
        _space_pad_bed(wd_n, wd_dur, CHORDS_A, vol=0.06),
        wd_mel,
        wd_beat,
    ], wd_n)

    # -- Outro 1:52-2:00 (melody descends, pad dissolves) --
    out_dur = 10.0
    out_n = int(out_dur * SAMPLE_RATE)
    out_mel = _melody(out_n, out_dur, MEL_DESCEND, sine_wave, vol=0.12)
    out_mel = _fade(out_mel, fade_in=0, fade_out=int(SAMPLE_RATE * 6.0))
    outro = _mix([
        _space_pad_bed(out_n, out_dur, [CHORDS_A[0]], vol=0.06),
        out_mel,
    ], out_n)
    outro = _fade(outro, fade_in=0, fade_out=int(SAMPLE_RATE * 7.0))

    # ===== ASSEMBLE SECTIONS with crossfades =====
    xf = int(SAMPLE_RATE * 2.5)
    sections = intro
    for seg in [v1, c1, br, v2, c2, wd, outro]:
        sections = _crossfade(sections, seg, xf)

    # Trim/pad sections to match duration
    if len(sections) > n:
        sections = sections[:n]
    elif len(sections) < n:
        sections = np.concatenate([sections, np.zeros(n - len(sections))])

    # ===== COMBINE: continuous layers + section layers =====
    track = np.zeros(n)
    track += harp_continuous
    track += bells_continuous
    track += sections

    # Volume curve for continuous harp/bells: gentle in bridge, full elsewhere
    # But they NEVER fully disappear
    harp_vol = _volume_curve(n, [
        (0.0, 0.3),        # start quiet
        (0.05, 0.8),       # quickly reach good level
        (0.1, 1.0),        # full by verse
        (0.38, 1.0),       # full through chorus
        (0.42, 0.7),       # slightly softer in bridge
        (0.48, 0.7),       # bridge level
        (0.52, 1.0),       # back up for verse 2
        (0.75, 1.0),       # full through chorus 2
        (0.85, 0.8),       # start winding down
        (0.92, 0.5),       # fading
        (1.0, 0.0),        # end
    ])
    # Apply curve only to the continuous layers (already mixed in)
    # We need to reshape: track = harp*curve + bells*curve + sections
    track = harp_continuous * harp_vol + bells_continuous * harp_vol + sections

    # Global reverb for space
    track = reverb(track, decay=0.2, delay_ms=30)

    # Overall fade in/out
    track = _fade(track, fade_in=int(SAMPLE_RATE * 2.0), fade_out=int(SAMPLE_RATE * 4.0))

    return _normalize(track)
