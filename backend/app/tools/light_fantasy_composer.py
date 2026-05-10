"""Light Fantasy composer — 1-minute ethereal compositions.

Three variants:
  1. Pure (no piano)
  2. Piano accents in select passages with smooth transitions
  3. Piano as continuous background layer

Keeps a single consistent tempo throughout; no abrupt beat switches.
"""

from __future__ import annotations

import numpy as np

from .music_producer import (
    SAMPLE_RATE,
    _fade,
    _normalize,
    _place_sound,
    note_freq,
    reverb,
    sine_wave,
)

# ---------------------------------------------------------------------------
# Synth voices
# ---------------------------------------------------------------------------


def pad_sound(freq: float, duration: float, volume: float = 0.3) -> np.ndarray:
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    sig = np.zeros(n)
    for detune in [-3, -1.5, 0, 1.5, 3]:
        f = freq * (2 ** (detune / 1200))
        sig += np.sin(2 * np.pi * f * t)
    sig /= 5
    attack = min(int(SAMPLE_RATE * 0.6), n // 3)
    release = min(int(SAMPLE_RATE * 0.8), n // 3)
    env = np.ones(n)
    env[:attack] = np.linspace(0, 1, attack)
    env[-release:] = np.linspace(1, 0, release)
    return volume * sig * env


def bell_sound(freq: float, duration: float, volume: float = 0.22) -> np.ndarray:
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    sig = np.sin(2 * np.pi * freq * t) * 0.5
    sig += np.sin(2 * np.pi * freq * 2.0 * t) * 0.3
    sig += np.sin(2 * np.pi * freq * 3.0 * t) * 0.12
    sig += np.sin(2 * np.pi * freq * 5.2 * t) * 0.04
    env = np.exp(-t * (2.5 / max(duration, 0.01)))
    return volume * sig * env


def shimmer_pad(freq: float, duration: float, volume: float = 0.15) -> np.ndarray:
    """High shimmering texture — octave-doubled pad with chorus."""
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    sig = np.zeros(n)
    for oct_mult in [1.0, 2.0, 4.0]:
        for detune_cents in [-4, 0, 4]:
            f = freq * oct_mult * (2 ** (detune_cents / 1200))
            sig += np.sin(2 * np.pi * f * t) / (oct_mult * 3)
    attack = min(int(SAMPLE_RATE * 1.0), n // 3)
    release = min(int(SAMPLE_RATE * 1.5), n // 3)
    env = np.ones(n)
    env[:attack] = np.linspace(0, 1, attack)
    env[-release:] = np.linspace(1, 0, release)
    return volume * sig * env


def pluck_sound(freq: float, duration: float, volume: float = 0.3) -> np.ndarray:
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    sig = np.sin(2 * np.pi * freq * t)
    sig += 0.4 * np.sin(2 * np.pi * freq * 2 * t)
    sig += 0.15 * np.sin(2 * np.pi * freq * 3 * t)
    env = np.exp(-t * (4.0 / max(duration, 0.01)))
    return volume * sig * env


def harp_sound(freq: float, duration: float, volume: float = 0.28) -> np.ndarray:
    """Harp-like — bright attack, slow decay, slight detuning."""
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    sig = np.sin(2 * np.pi * freq * t) * 0.6
    sig += np.sin(2 * np.pi * freq * 2.003 * t) * 0.25
    sig += np.sin(2 * np.pi * freq * 3.01 * t) * 0.1
    sig += np.sin(2 * np.pi * freq * 4.98 * t) * 0.05
    env = np.exp(-t * (3.0 / max(duration, 0.01)))
    attack_n = min(int(SAMPLE_RATE * 0.005), n // 4)
    if attack_n > 0:
        env[:attack_n] *= np.linspace(0, 1, attack_n)
    return volume * sig * env


def piano_sound(freq: float, duration: float, volume: float = 0.3) -> np.ndarray:
    """Piano-like tone — hammer attack, harmonic series, sustain + release."""
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    harmonics = [
        (1.0, 1.0),
        (2.0, 0.45),
        (3.0, 0.2),
        (4.0, 0.12),
        (5.0, 0.06),
        (6.0, 0.03),
        (7.0, 0.015),
    ]
    sig = np.zeros(n)
    for h_mult, h_amp in harmonics:
        decay_rate = 2.0 + h_mult * 0.8
        sig += h_amp * np.sin(2 * np.pi * freq * h_mult * t) * np.exp(-t * decay_rate / max(duration, 0.01))
    # Hammer click
    click_dur = min(int(SAMPLE_RATE * 0.003), n)
    if click_dur > 0:
        rng = np.random.default_rng(int(freq * 100) % 1000)
        click = 0.15 * rng.uniform(-1, 1, click_dur) * np.exp(-np.linspace(0, 8, click_dur))
        sig[:click_dur] += click
    # Envelope
    attack_n = min(int(SAMPLE_RATE * 0.008), n // 4)
    release_n = min(int(SAMPLE_RATE * 0.3), n // 3)
    env = np.ones(n)
    if attack_n > 0:
        env[:attack_n] = np.linspace(0, 1, attack_n)
    if release_n > 0:
        env[-release_n:] *= np.linspace(1, 0, release_n)
    return volume * sig * env


def soft_kick(duration: float = 0.3) -> np.ndarray:
    """Very soft, round kick — felt more than heard."""
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    freq_sweep = 80 * np.exp(-t * 25) + 35
    phase = 2 * np.pi * np.cumsum(freq_sweep) / SAMPLE_RATE
    sig = 0.25 * np.sin(phase) * np.exp(-t * 10)
    return sig


# ---------------------------------------------------------------------------
# Chord progressions (Light Fantasy palette)
# ---------------------------------------------------------------------------

# Ethereal progressions in C major / A minor with extensions
CHORD_PROG_A = [
    ["C3", "E3", "G3", "B3"],      # Cmaj7
    ["A2", "C3", "E3", "G3"],      # Am7
    ["F2", "A2", "C3", "E3"],      # Fmaj7
    ["G2", "B2", "D3", "F3"],      # G7
]

CHORD_PROG_B = [
    ["D3", "F3", "A3", "C4"],      # Dm7
    ["E3", "G3", "B3", "D4"],      # Em7
    ["F3", "A3", "C4", "E4"],      # Fmaj7
    ["C3", "E3", "G3", "B3"],      # Cmaj7
]

CHORD_PROG_C = [
    ["A2", "C3", "E3", "G3"],      # Am7
    ["F2", "A2", "C3", "E3"],      # Fmaj7
    ["D3", "F3", "A3", "C4"],      # Dm7
    ["G2", "B2", "D3", "G3"],      # Gmaj
]

# Melody phrases
MELODY_A = ["E5", "G5", "B5", "A5", "G5", "E5", "D5", "C5",
            "D5", "E5", "G5", "A5", "B5", "A5", "G5", "E5"]

MELODY_B = ["C5", "D5", "E5", "G5", "A5", "G5", "E5", "D5",
            "C5", "B4", "A4", "B4", "C5", "E5", "D5", "C5"]

MELODY_C = ["A4", "C5", "E5", "G5", "F5", "E5", "D5", "C5",
            "B4", "C5", "D5", "E5", "G5", "A5", "G5", "E5"]

# Arpeggio patterns for bell layer
ARP_NOTES_A = ["C5", "E5", "G5", "B5", "G5", "E5"]
ARP_NOTES_B = ["A4", "C5", "E5", "G5", "E5", "C5"]
ARP_NOTES_C = ["F4", "A4", "C5", "E5", "C5", "A4"]

# Piano melody phrases
PIANO_MELODY_A = [
    ("E4", 1.0), ("G4", 0.5), ("A4", 0.5), ("B4", 1.0), ("A4", 0.5), ("G4", 0.5),
    ("E4", 1.0), ("D4", 1.0), ("C4", 2.0),
]

PIANO_MELODY_B = [
    ("C5", 0.75), ("B4", 0.25), ("A4", 0.5), ("G4", 0.5), ("A4", 1.0),
    ("E4", 0.5), ("G4", 0.5), ("A4", 0.75), ("B4", 0.25), ("C5", 1.0),
    ("B4", 0.5), ("A4", 0.5), ("G4", 1.0),
]

PIANO_CHORDS = [
    ["C4", "E4", "G4"],
    ["A3", "C4", "E4"],
    ["F3", "A3", "C4"],
    ["G3", "B3", "D4"],
]


# ---------------------------------------------------------------------------
# Layer builders
# ---------------------------------------------------------------------------


def _mix_layers(layers: list[np.ndarray], target_len: int) -> np.ndarray:
    mixed = np.zeros(target_len)
    for layer in layers:
        end = min(len(layer), target_len)
        mixed[:end] += layer[:end]
    return mixed


def _build_pad_layer(
    n: int,
    duration: float,
    chord_progs: list[list[list[str]]],
    volume: float = 0.1,
) -> np.ndarray:
    """Build seamless pad from multiple chord progressions."""
    layer = np.zeros(n)
    total_chords = sum(len(cp) for cp in chord_progs)
    chord_dur = duration / total_chords
    t_pos = 0.0
    for prog in chord_progs:
        for chord in prog:
            actual_dur = min(chord_dur * 1.3, duration - t_pos)
            if actual_dur <= 0:
                break
            for note in chord:
                snd = pad_sound(note_freq(note), actual_dur, volume=volume)
                pos = int(t_pos * SAMPLE_RATE)
                _place_sound(layer, snd, pos)
            t_pos += chord_dur
    return layer


def _build_shimmer_layer(n: int, duration: float) -> np.ndarray:
    layer = np.zeros(n)
    shimmer_notes = ["C4", "E4", "G4"]
    seg_dur = duration / 3
    for i, note in enumerate(shimmer_notes):
        snd = shimmer_pad(note_freq(note), seg_dur * 1.5, volume=0.08)
        pos = int(i * seg_dur * SAMPLE_RATE)
        _place_sound(layer, snd, pos)
    return layer


def _build_bell_arp_layer(
    n: int,
    duration: float,
    bpm: float,
    arp_sets: list[list[str]],
) -> np.ndarray:
    layer = np.zeros(n)
    step_dur = 60.0 / bpm / 2
    set_dur = duration / len(arp_sets)
    for set_idx, arp_notes in enumerate(arp_sets):
        set_start = set_idx * set_dur
        steps_in_set = int(set_dur / step_dur)
        for i in range(steps_in_set):
            t_abs = set_start + i * step_dur
            if t_abs >= duration:
                break
            note = arp_notes[i % len(arp_notes)]
            snd = bell_sound(note_freq(note), step_dur * 2.0, volume=0.15)
            pos = int(t_abs * SAMPLE_RATE)
            _place_sound(layer, snd, pos)
    return layer


def _build_harp_arp_layer(
    n: int,
    duration: float,
    bpm: float,
    arp_sets: list[list[str]],
) -> np.ndarray:
    layer = np.zeros(n)
    step_dur = 60.0 / bpm / 2
    set_dur = duration / len(arp_sets)
    for set_idx, arp_notes in enumerate(arp_sets):
        set_start = set_idx * set_dur
        steps_in_set = int(set_dur / step_dur)
        for i in range(steps_in_set):
            t_abs = set_start + i * step_dur
            if t_abs >= duration:
                break
            note = arp_notes[i % len(arp_notes)]
            vel = 0.2 if i % 2 == 0 else 0.12
            snd = harp_sound(note_freq(note), step_dur * 1.8, volume=vel)
            pos = int(t_abs * SAMPLE_RATE)
            _place_sound(layer, snd, pos)
    return layer


def _build_melody_layer(
    n: int,
    duration: float,
    bpm: float,
    melodies: list[list[str]],
    wave_fn: object = sine_wave,
    volume: float = 0.18,
) -> np.ndarray:
    layer = np.zeros(n)
    mel_step = 60.0 / bpm
    seg_dur = duration / len(melodies)
    for seg_idx, melody in enumerate(melodies):
        seg_start = seg_idx * seg_dur
        for i, note in enumerate(melody):
            t_abs = seg_start + i * mel_step
            if t_abs >= duration:
                break
            dur = min(mel_step * 0.9, duration - t_abs)
            snd = wave_fn(note_freq(note), dur, volume=volume)  # type: ignore[operator]
            snd = _fade(snd, fade_in=int(len(snd) * 0.08), fade_out=int(len(snd) * 0.2))
            pos = int(t_abs * SAMPLE_RATE)
            _place_sound(layer, snd, pos)
    return layer


def _build_soft_beat_layer(n: int, duration: float, bpm: float) -> np.ndarray:
    """Very gentle rhythmic pulse — soft kicks on beats 1 and 3."""
    layer = np.zeros(n)
    beat_dur = 60.0 / bpm
    bar_dur = beat_dur * 4
    bars = int(duration / bar_dur) + 1
    for bar in range(bars):
        for beat in [0, 2]:
            t = bar * bar_dur + beat * beat_dur
            if t >= duration:
                break
            vel = 0.8 if beat == 0 else 0.5
            pos = int(t * SAMPLE_RATE)
            _place_sound(layer, soft_kick() * vel, pos)
    return layer


# ---------------------------------------------------------------------------
# Piano layers
# ---------------------------------------------------------------------------


def _build_piano_melody_layer(
    n: int,
    duration: float,
    bpm: float,
    phrases: list[list[tuple[str, float]]],
    volume: float = 0.22,
) -> np.ndarray:
    """Piano melody placed at specific phrases with smooth fade in/out."""
    layer = np.zeros(n)
    beat_dur = 60.0 / bpm
    phrase_dur = duration / len(phrases)
    for p_idx, phrase in enumerate(phrases):
        t_pos = p_idx * phrase_dur
        for note_name, beats in phrase:
            if t_pos >= duration:
                break
            dur = beats * beat_dur
            dur = min(dur, duration - t_pos)
            snd = piano_sound(note_freq(note_name), dur, volume=volume)
            pos = int(t_pos * SAMPLE_RATE)
            _place_sound(layer, snd, pos)
            t_pos += dur
    return layer


def _build_piano_chord_bg_layer(
    n: int,
    duration: float,
    bpm: float,
    volume: float = 0.1,
) -> np.ndarray:
    """Continuous piano chords as gentle background — arpeggiated softly."""
    layer = np.zeros(n)
    beat_dur = 60.0 / bpm
    chord_dur = beat_dur * 4
    t = 0.0
    chord_idx = 0
    while t < duration:
        chord = PIANO_CHORDS[chord_idx % len(PIANO_CHORDS)]
        # Arpeggiate within the chord
        note_gap = beat_dur * 0.5
        for j, note in enumerate(chord):
            nt = t + j * note_gap
            if nt >= duration:
                break
            dur = min(chord_dur * 0.8, duration - nt)
            snd = piano_sound(note_freq(note), dur, volume=volume)
            pos = int(nt * SAMPLE_RATE)
            _place_sound(layer, snd, pos)
        t += chord_dur
        chord_idx += 1
    return layer


def _build_piano_accent_layer(
    n: int,
    duration: float,
    bpm: float,
    volume: float = 0.2,
) -> np.ndarray:
    """Piano appearing in specific sections with smooth volume envelope.

    Appears in ~20-40s and ~50-58s with gradual fade-in and fade-out.
    """
    layer = np.zeros(n)

    # Section 1: 18-38s — piano melody
    s1_start = 18.0
    s1_end = min(38.0, duration)
    if s1_start < duration:
        s1_dur = s1_end - s1_start
        piano_seg = _build_piano_melody_layer(
            int(s1_dur * SAMPLE_RATE), s1_dur, bpm,
            [list(PIANO_MELODY_A), list(PIANO_MELODY_B)],
            volume=volume,
        )
        # Fade in over 2s, fade out over 2s
        fade_in_n = min(int(SAMPLE_RATE * 2.0), len(piano_seg) // 3)
        fade_out_n = min(int(SAMPLE_RATE * 2.0), len(piano_seg) // 3)
        piano_seg = _fade(piano_seg, fade_in=fade_in_n, fade_out=fade_out_n)
        pos = int(s1_start * SAMPLE_RATE)
        _place_sound(layer, piano_seg, pos)

    # Section 2: 48-58s — piano melody reprise
    s2_start = 48.0
    s2_end = min(58.0, duration)
    if s2_start < duration:
        s2_dur = s2_end - s2_start
        piano_seg2 = _build_piano_melody_layer(
            int(s2_dur * SAMPLE_RATE), s2_dur, bpm,
            [list(PIANO_MELODY_A)],
            volume=volume * 0.8,
        )
        fade_in_n2 = min(int(SAMPLE_RATE * 1.5), len(piano_seg2) // 3)
        fade_out_n2 = min(int(SAMPLE_RATE * 2.0), len(piano_seg2) // 3)
        piano_seg2 = _fade(piano_seg2, fade_in=fade_in_n2, fade_out=fade_out_n2)
        pos2 = int(s2_start * SAMPLE_RATE)
        _place_sound(layer, piano_seg2, pos2)

    return layer


# ---------------------------------------------------------------------------
# Full compositions
# ---------------------------------------------------------------------------


def _base_light_fantasy(duration: float = 60.0, bpm: float = 92) -> tuple[np.ndarray, int]:
    """Build the core Light Fantasy layers (without piano). Returns (signal, n)."""
    n = int(SAMPLE_RATE * duration)

    layers: list[np.ndarray] = []

    # 1) Pad bed — 3 chord progressions flowing continuously
    layers.append(_build_pad_layer(n, duration, [CHORD_PROG_A, CHORD_PROG_B, CHORD_PROG_C], volume=0.1))

    # 2) Shimmer texture
    layers.append(_build_shimmer_layer(n, duration))

    # 3) Bell arpeggios
    layers.append(_build_bell_arp_layer(n, duration, bpm, [ARP_NOTES_A, ARP_NOTES_B, ARP_NOTES_C]))

    # 4) Harp arpeggios (complement bells)
    layers.append(_build_harp_arp_layer(n, duration, bpm, [ARP_NOTES_C, ARP_NOTES_A, ARP_NOTES_B]))

    # 5) Main melody — sine, high and dreamy
    layers.append(_build_melody_layer(n, duration, bpm, [MELODY_A, MELODY_B, MELODY_C], sine_wave, 0.18))

    # 6) Counter-melody — pluck
    counter_mel = ["G4", "A4", "B4", "C5", "B4", "A4", "G4", "E4",
                   "F4", "G4", "A4", "C5", "B4", "G4", "E4", "D4"]
    layers.append(_build_melody_layer(n, duration, bpm * 0.5, [counter_mel], pluck_sound, 0.12))

    # 7) Very soft beat
    layers.append(_build_soft_beat_layer(n, duration, bpm))

    mixed = _mix_layers(layers, n)
    return mixed, n


def compose_light_fantasy_pure(duration: float = 60.0, bpm: float = 92) -> np.ndarray:
    """Variant 1: Pure Light Fantasy — no piano."""
    mixed, _ = _base_light_fantasy(duration, bpm)

    mixed = reverb(mixed, decay=0.25, delay_ms=35)
    mixed = _fade(mixed, fade_in=int(SAMPLE_RATE * 1.0), fade_out=int(SAMPLE_RATE * 3.0))
    return _normalize(mixed)


def compose_light_fantasy_piano_accents(duration: float = 60.0, bpm: float = 92) -> np.ndarray:
    """Variant 2: Light Fantasy with piano in select passages (smooth transitions)."""
    mixed, n = _base_light_fantasy(duration, bpm)

    piano_layer = _build_piano_accent_layer(n, duration, bpm, volume=0.22)
    mixed += piano_layer

    mixed = reverb(mixed, decay=0.25, delay_ms=35)
    mixed = _fade(mixed, fade_in=int(SAMPLE_RATE * 1.0), fade_out=int(SAMPLE_RATE * 3.0))
    return _normalize(mixed)


def compose_light_fantasy_piano_bg(duration: float = 60.0, bpm: float = 92) -> np.ndarray:
    """Variant 3: Light Fantasy with piano as continuous background."""
    mixed, n = _base_light_fantasy(duration, bpm)

    piano_bg = _build_piano_chord_bg_layer(n, duration, bpm, volume=0.09)
    # Gentle fade in so piano enters smoothly
    piano_bg = _fade(piano_bg, fade_in=int(SAMPLE_RATE * 3.0), fade_out=int(SAMPLE_RATE * 2.0))
    mixed += piano_bg

    mixed = reverb(mixed, decay=0.25, delay_ms=35)
    mixed = _fade(mixed, fade_in=int(SAMPLE_RATE * 1.0), fade_out=int(SAMPLE_RATE * 3.0))
    return _normalize(mixed)
