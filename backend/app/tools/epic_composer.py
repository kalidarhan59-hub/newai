"""Epic cinematic composer — 1-minute multi-section compositions.

Builds long-form tracks by layering pads, arpeggios, percussion,
bass, and melodies across distinct mood sections (light fantasy,
dark fantasy, adventure, romantic, everyday).

All synthesis is pure numpy — no external audio libraries needed.
"""

from __future__ import annotations

import numpy as np

from .music_producer import (
    SAMPLE_RATE,
    _fade,
    _normalize,
    _place_sound,
    clap,
    hihat,
    kick,
    note_freq,
    reverb,
    sine_wave,
    snare,
)

# ---------------------------------------------------------------------------
# Extended synth voices
# ---------------------------------------------------------------------------


def pad_sound(freq: float, duration: float, volume: float = 0.3) -> np.ndarray:
    """Lush pad — layered detuned sines with slow attack/release."""
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    sig = np.zeros(n)
    for detune in [-2, -1, 0, 1, 2]:
        f = freq * (2 ** (detune / 1200))
        sig += np.sin(2 * np.pi * f * t)
    sig /= 5
    # slow attack & release envelope
    attack = min(int(SAMPLE_RATE * 0.4), n // 3)
    release = min(int(SAMPLE_RATE * 0.5), n // 3)
    env = np.ones(n)
    env[:attack] = np.linspace(0, 1, attack)
    env[-release:] = np.linspace(1, 0, release)
    return volume * sig * env


def bell_sound(freq: float, duration: float, volume: float = 0.25) -> np.ndarray:
    """Bell / glockenspiel — sine with harmonics and fast decay."""
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    sig = np.sin(2 * np.pi * freq * t) * 0.5
    sig += np.sin(2 * np.pi * freq * 2.0 * t) * 0.3
    sig += np.sin(2 * np.pi * freq * 3.0 * t) * 0.15
    sig += np.sin(2 * np.pi * freq * 5.2 * t) * 0.05
    env = np.exp(-t * (3.0 / duration))
    return volume * sig * env


def choir_pad(freq: float, duration: float, volume: float = 0.2) -> np.ndarray:
    """Choir-like pad with vibrato — evokes epic / Norse atmosphere."""
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    vibrato = 5 * np.sin(2 * np.pi * 5.5 * t)
    sig = np.zeros(n)
    for harmonic, amp in [(1, 1.0), (2, 0.4), (3, 0.15)]:
        f = freq * harmonic
        sig += amp * np.sin(2 * np.pi * (f + vibrato) * t)
    sig /= 1.55
    attack = min(int(SAMPLE_RATE * 0.6), n // 3)
    release = min(int(SAMPLE_RATE * 0.8), n // 3)
    env = np.ones(n)
    env[:attack] = np.linspace(0, 1, attack)
    env[-release:] = np.linspace(1, 0, release)
    return volume * sig * env


def pluck_sound(freq: float, duration: float, volume: float = 0.35) -> np.ndarray:
    """Plucked string — Karplus-Strong inspired."""
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    sig = np.sin(2 * np.pi * freq * t)
    sig += 0.5 * np.sin(2 * np.pi * freq * 2 * t)
    sig += 0.25 * np.sin(2 * np.pi * freq * 3 * t)
    env = np.exp(-t * (5.0 / duration))
    return volume * sig * env


def warm_bass(freq: float, duration: float, volume: float = 0.5) -> np.ndarray:
    """Warm sub bass with slight overtone."""
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    sig = 0.7 * np.sin(2 * np.pi * freq * t)
    sig += 0.3 * np.sin(2 * np.pi * freq * 2 * t)
    attack = min(int(SAMPLE_RATE * 0.02), n // 4)
    release = min(int(SAMPLE_RATE * 0.05), n // 4)
    env = np.ones(n)
    env[:attack] = np.linspace(0, 1, attack)
    env[-release:] = np.linspace(1, 0, release)
    return volume * sig * env


def epic_drum(duration: float = 0.5) -> np.ndarray:
    """Deep taiko-like drum hit."""
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    freq_sweep = 80 * np.exp(-t * 8) + 30
    phase = 2 * np.pi * np.cumsum(freq_sweep) / SAMPLE_RATE
    body = 0.8 * np.sin(phase) * np.exp(-t * 4)
    rng = np.random.default_rng(55)
    nse = 0.15 * rng.uniform(-1, 1, n) * np.exp(-t * 10)
    return body + nse


def cymbal_swell(duration: float = 2.0) -> np.ndarray:
    """Rising cymbal swell for transitions."""
    n = int(SAMPLE_RATE * duration)
    rng = np.random.default_rng(88)
    sig = rng.uniform(-1, 1, n)
    env = np.linspace(0, 0.35, n)
    return sig * env


def string_tremolo(freq: float, duration: float, volume: float = 0.2) -> np.ndarray:
    """Tremolo strings for tension."""
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    tremolo = 0.5 + 0.5 * np.sin(2 * np.pi * 8 * t)
    sig = np.sin(2 * np.pi * freq * t) + 0.3 * np.sin(2 * np.pi * freq * 2 * t)
    attack = min(int(SAMPLE_RATE * 0.3), n // 3)
    release = min(int(SAMPLE_RATE * 0.3), n // 3)
    env = np.ones(n)
    env[:attack] = np.linspace(0, 1, attack)
    env[-release:] = np.linspace(1, 0, release)
    return volume * sig * tremolo * env


# ---------------------------------------------------------------------------
# Crossfade utility
# ---------------------------------------------------------------------------


def crossfade(a: np.ndarray, b: np.ndarray, overlap_samples: int) -> np.ndarray:
    """Crossfade the end of *a* with the start of *b*."""
    if overlap_samples <= 0 or len(a) == 0 or len(b) == 0:
        return np.concatenate([a, b])
    overlap_samples = min(overlap_samples, len(a), len(b))
    fade_out = np.linspace(1, 0, overlap_samples)
    fade_in = np.linspace(0, 1, overlap_samples)
    result = np.zeros(len(a) + len(b) - overlap_samples)
    result[: len(a)] += a
    start = len(a) - overlap_samples
    result[start : start + overlap_samples] -= a[-overlap_samples:]
    result[start : start + overlap_samples] += a[-overlap_samples:] * fade_out
    result[start : start + overlap_samples] += b[:overlap_samples] * fade_in
    result[len(a) :] += b[overlap_samples:]
    return result


# ---------------------------------------------------------------------------
# Section builders
# ---------------------------------------------------------------------------


def _mix_layers(layers: list[np.ndarray], target_len: int) -> np.ndarray:
    mixed = np.zeros(target_len)
    for layer in layers:
        end = min(len(layer), target_len)
        mixed[:end] += layer[:end]
    return mixed


def section_light_fantasy(duration: float, bpm: float = 100) -> np.ndarray:
    """Ethereal, magical — bells, soft pad, gentle arpeggios."""
    n = int(SAMPLE_RATE * duration)
    layers: list[np.ndarray] = []

    # Pad: C major 7 (C E G B)
    pad_layer = np.zeros(n)
    for note in ["C3", "E3", "G3", "B3"]:
        pad_layer += pad_sound(note_freq(note), duration, volume=0.12)
    layers.append(pad_layer)

    # Bell arpeggios
    bell_layer = np.zeros(n)
    arp_notes = ["C5", "E5", "G5", "B5", "G5", "E5"]
    step_dur = 60.0 / bpm / 2
    for i in range(int(duration / step_dur)):
        note = arp_notes[i % len(arp_notes)]
        snd = bell_sound(note_freq(note), step_dur * 1.5, volume=0.18)
        pos = int(i * step_dur * SAMPLE_RATE)
        _place_sound(bell_layer, snd, pos)
    layers.append(bell_layer)

    # Gentle melody
    melody_layer = np.zeros(n)
    melody_notes = [
        "E5", "G5", "B5", "A5", "G5", "E5", "D5", "C5",
        "D5", "E5", "G5", "A5", "B5", "A5", "G5", "E5",
    ]
    mel_step = 60.0 / bpm
    for i, note in enumerate(melody_notes):
        if i * mel_step >= duration:
            break
        snd = sine_wave(note_freq(note), mel_step * 0.9, volume=0.2)
        snd = _fade(snd, fade_in=int(len(snd) * 0.05), fade_out=int(len(snd) * 0.15))
        pos = int(i * mel_step * SAMPLE_RATE)
        _place_sound(melody_layer, snd, pos)
    layers.append(melody_layer)

    return _mix_layers(layers, n)


def section_adventure(duration: float, bpm: float = 130) -> np.ndarray:
    """Energetic, driving — strong drums, brass-like lead, power chords."""
    n = int(SAMPLE_RATE * duration)
    layers: list[np.ndarray] = []
    step16 = 60.0 / bpm / 4

    # Drums — kick on 1,3; snare on 2,4; hi-hats 8ths
    drum_layer = np.zeros(n)
    kick_pat = [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]
    snare_pat = [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0]
    hh_pat = [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]
    total_steps = int(duration / step16)
    for step_i in range(total_steps):
        pos = int(step_i * step16 * SAMPLE_RATE)
        pi = step_i % 16
        if kick_pat[pi]:
            _place_sound(drum_layer, kick() * 0.9, pos)
        if snare_pat[pi]:
            _place_sound(drum_layer, snare() * 0.7, pos)
        if hh_pat[pi]:
            _place_sound(drum_layer, hihat() * 0.4, pos)
    layers.append(drum_layer)

    # Epic taiko accents on 1
    taiko_layer = np.zeros(n)
    bar_dur = 60.0 / bpm * 4
    for bar in range(int(duration / bar_dur)):
        pos = int(bar * bar_dur * SAMPLE_RATE)
        _place_sound(taiko_layer, epic_drum() * 0.5, pos)
    layers.append(taiko_layer)

    # Power bass — D minor
    bass_layer = np.zeros(n)
    bass_notes = ["D2", "D2", "F2", "A2", "G2", "F2", "D2", "D2"]
    bass_step = 60.0 / bpm
    for i, note in enumerate(bass_notes):
        if i * bass_step >= duration:
            break
        pos = int(i * bass_step * SAMPLE_RATE)
        _place_sound(bass_layer, warm_bass(note_freq(note), bass_step * 0.9, 0.4), pos)
    # Repeat
    pattern_dur = len(bass_notes) * bass_step
    reps = int(duration / pattern_dur) + 1
    full_bass = np.zeros(n)
    for r in range(reps):
        offset = int(r * pattern_dur * SAMPLE_RATE)
        end = min(offset + len(bass_layer), n)
        length = end - offset
        if length > 0:
            full_bass[offset:end] += bass_layer[:length]
    layers.append(full_bass)

    # Brass-like lead — saw wave melody (D minor scale)
    lead_layer = np.zeros(n)
    lead_notes = ["D5", "F5", "A5", "G5", "F5", "E5", "D5", "C5",
                  "D5", "E5", "F5", "G5", "A5", "G5", "F5", "D5"]
    lead_step = 60.0 / bpm * 0.5
    for i, note in enumerate(lead_notes):
        t_start = i * lead_step
        if t_start >= duration:
            break
        from .music_producer import saw_wave
        dur = min(lead_step * 0.85, duration - t_start)
        snd = saw_wave(note_freq(note), dur, volume=0.15)
        snd = _fade(snd, fade_in=int(len(snd) * 0.05), fade_out=int(len(snd) * 0.1))
        pos = int(t_start * SAMPLE_RATE)
        _place_sound(lead_layer, snd, pos)
    layers.append(lead_layer)

    return _mix_layers(layers, n)


def section_dark_fantasy(duration: float, bpm: float = 110) -> np.ndarray:
    """Dark, epic Norse — choir pads, tremolo strings, heavy drums."""
    n = int(SAMPLE_RATE * duration)
    layers: list[np.ndarray] = []
    step16 = 60.0 / bpm / 4

    # Choir pad — D minor (D F A)
    choir_layer = np.zeros(n)
    for note in ["D2", "A2", "D3", "F3"]:
        choir_layer += choir_pad(note_freq(note), duration, volume=0.12)
    layers.append(choir_layer)

    # Tremolo strings — tension
    string_layer = np.zeros(n)
    string_notes_seq = ["A3", "D4", "F4", "E4"]
    seg_dur = duration / len(string_notes_seq)
    for i, note in enumerate(string_notes_seq):
        snd = string_tremolo(note_freq(note), seg_dur, volume=0.15)
        pos = int(i * seg_dur * SAMPLE_RATE)
        _place_sound(string_layer, snd, pos)
    layers.append(string_layer)

    # Heavy drums — epic taiko + kick pattern
    drum_layer = np.zeros(n)
    kick_pat = [1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0]
    total_steps = int(duration / step16)
    for step_i in range(total_steps):
        pos = int(step_i * step16 * SAMPLE_RATE)
        pi = step_i % 16
        if kick_pat[pi]:
            _place_sound(drum_layer, kick() * 0.8, pos)
    layers.append(drum_layer)

    # Taiko on each beat
    taiko_layer = np.zeros(n)
    beat_dur = 60.0 / bpm
    for i in range(int(duration / beat_dur)):
        vel = 0.7 if i % 4 == 0 else 0.35
        pos = int(i * beat_dur * SAMPLE_RATE)
        _place_sound(taiko_layer, epic_drum() * vel, pos)
    layers.append(taiko_layer)

    # Dark bass
    bass_layer = np.zeros(n)
    bass_notes = ["D2", "D2", "C2", "D2"]
    bass_step = 60.0 / bpm * 2
    idx = 0
    t = 0.0
    while t < duration:
        note = bass_notes[idx % len(bass_notes)]
        dur = min(bass_step * 0.9, duration - t)
        snd = warm_bass(note_freq(note), dur, volume=0.45)
        pos = int(t * SAMPLE_RATE)
        _place_sound(bass_layer, snd, pos)
        t += bass_step
        idx += 1
    layers.append(bass_layer)

    # Clap accents
    clap_layer = np.zeros(n)
    clap_pat = [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0]
    for step_i in range(total_steps):
        pos = int(step_i * step16 * SAMPLE_RATE)
        pi = step_i % 16
        if clap_pat[pi]:
            _place_sound(clap_layer, clap() * 0.5, pos)
    layers.append(clap_layer)

    return _mix_layers(layers, n)


def section_vinland_peak(duration: float, bpm: float = 120) -> np.ndarray:
    """Vinland Saga peak — maximum intensity, Norse epic feel."""
    n = int(SAMPLE_RATE * duration)
    layers: list[np.ndarray] = []
    step16 = 60.0 / bpm / 4

    # Full choir — D minor power
    choir_layer = np.zeros(n)
    for note in ["D2", "A2", "D3", "F3", "A3"]:
        choir_layer += choir_pad(note_freq(note), duration, volume=0.1)
    layers.append(choir_layer)

    # All drums blazing
    drum_layer = np.zeros(n)
    total_steps = int(duration / step16)
    kick_pat = [1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0]
    snare_pat = [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0]
    hh_pat = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
    for step_i in range(total_steps):
        pos = int(step_i * step16 * SAMPLE_RATE)
        pi = step_i % 16
        if kick_pat[pi]:
            _place_sound(drum_layer, kick() * 0.9, pos)
        if snare_pat[pi]:
            _place_sound(drum_layer, snare() * 0.7, pos)
        if hh_pat[pi]:
            vel = 0.3 if step_i % 2 == 0 else 0.15
            _place_sound(drum_layer, hihat() * vel, pos)
    layers.append(drum_layer)

    # Taiko every beat, accented on 1
    taiko_layer = np.zeros(n)
    beat_dur = 60.0 / bpm
    for i in range(int(duration / beat_dur)):
        vel = 0.8 if i % 4 == 0 else 0.4
        pos = int(i * beat_dur * SAMPLE_RATE)
        _place_sound(taiko_layer, epic_drum() * vel, pos)
    layers.append(taiko_layer)

    # Aggressive bass
    bass_layer = np.zeros(n)
    bass_notes = ["D2", "F2", "C2", "D2", "A1", "D2", "G2", "D2"]
    bass_step = 60.0 / bpm
    idx = 0
    t = 0.0
    while t < duration:
        note = bass_notes[idx % len(bass_notes)]
        dur = min(bass_step * 0.9, duration - t)
        snd = warm_bass(note_freq(note), dur, volume=0.5)
        pos = int(t * SAMPLE_RATE)
        _place_sound(bass_layer, snd, pos)
        t += bass_step
        idx += 1
    layers.append(bass_layer)

    # Epic melody — powerful and heroic
    melody_layer = np.zeros(n)
    from .music_producer import saw_wave
    mel_notes = ["D5", "F5", "A5", "A5", "G5", "F5", "E5", "D5",
                 "D5", "C5", "D5", "F5", "G5", "A5", "G5", "F5"]
    mel_step = 60.0 / bpm * 0.5
    for i, note in enumerate(mel_notes):
        t_start = i * mel_step
        if t_start >= duration:
            break
        dur = min(mel_step * 0.85, duration - t_start)
        snd = saw_wave(note_freq(note), dur, volume=0.18)
        snd = _fade(snd, fade_in=int(len(snd) * 0.03), fade_out=int(len(snd) * 0.1))
        pos = int(t_start * SAMPLE_RATE)
        _place_sound(melody_layer, snd, pos)
    layers.append(melody_layer)

    return _mix_layers(layers, n)


def section_romantic(duration: float, bpm: float = 80) -> np.ndarray:
    """Soft, emotional — warm pad, gentle plucked melody, no drums."""
    n = int(SAMPLE_RATE * duration)
    layers: list[np.ndarray] = []

    # Warm pad — F major 7 (F A C E)
    pad_layer = np.zeros(n)
    for note in ["F3", "A3", "C4", "E4"]:
        pad_layer += pad_sound(note_freq(note), duration, volume=0.12)
    layers.append(pad_layer)

    # Plucked melody
    pluck_layer = np.zeros(n)
    pluck_notes = ["A4", "C5", "F5", "E5", "C5", "A4", "G4", "F4",
                   "G4", "A4", "C5", "E5", "F5", "E5", "C5", "A4"]
    pluck_step = 60.0 / bpm * 0.5
    for i, note in enumerate(pluck_notes):
        t_start = i * pluck_step
        if t_start >= duration:
            break
        dur = min(pluck_step * 1.5, duration - t_start)
        snd = pluck_sound(note_freq(note), dur, volume=0.25)
        pos = int(t_start * SAMPLE_RATE)
        _place_sound(pluck_layer, snd, pos)
    layers.append(pluck_layer)

    # High bell accents
    bell_layer = np.zeros(n)
    bell_notes = ["F6", "E6", "C6", "A5"]
    bell_step = 60.0 / bpm * 2
    for i, note in enumerate(bell_notes):
        t_start = i * bell_step
        if t_start >= duration:
            break
        snd = bell_sound(note_freq(note), bell_step * 1.5, volume=0.1)
        pos = int(t_start * SAMPLE_RATE)
        _place_sound(bell_layer, snd, pos)
    layers.append(bell_layer)

    # Gentle sine melody (high)
    sine_mel_layer = np.zeros(n)
    sine_notes = ["F5", "A5", "C6", "A5", "F5", "E5", "F5", "G5"]
    sine_step = 60.0 / bpm
    for i, note in enumerate(sine_notes):
        t_start = i * sine_step
        if t_start >= duration:
            break
        dur = min(sine_step * 0.8, duration - t_start)
        snd = sine_wave(note_freq(note), dur, volume=0.15)
        snd = _fade(snd, fade_in=int(len(snd) * 0.1), fade_out=int(len(snd) * 0.2))
        pos = int(t_start * SAMPLE_RATE)
        _place_sound(sine_mel_layer, snd, pos)
    layers.append(sine_mel_layer)

    return _mix_layers(layers, n)


def section_everyday(duration: float, bpm: float = 95) -> np.ndarray:
    """Calm, peaceful slice-of-life — light guitar-style plucks, soft beat."""
    n = int(SAMPLE_RATE * duration)
    layers: list[np.ndarray] = []
    step16 = 60.0 / bpm / 4

    # Soft pad — C major
    pad_layer = np.zeros(n)
    for note in ["C3", "E3", "G3"]:
        pad_layer += pad_sound(note_freq(note), duration, volume=0.08)
    layers.append(pad_layer)

    # Very soft drums
    drum_layer = np.zeros(n)
    kick_pat = [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]
    total_steps = int(duration / step16)
    for step_i in range(total_steps):
        pos = int(step_i * step16 * SAMPLE_RATE)
        pi = step_i % 16
        if kick_pat[pi]:
            _place_sound(drum_layer, kick() * 0.3, pos)
    layers.append(drum_layer)

    # Plucked arpeggios — C Am F G
    pluck_layer = np.zeros(n)
    arp_chords = [
        ["C4", "E4", "G4"],
        ["A3", "C4", "E4"],
        ["F3", "A3", "C4"],
        ["G3", "B3", "D4"],
    ]
    chord_dur = 60.0 / bpm * 4
    note_step = 60.0 / bpm * 0.5
    t = 0.0
    chord_idx = 0
    while t < duration:
        chord = arp_chords[chord_idx % len(arp_chords)]
        for j, note in enumerate(chord * 2):
            nt = t + j * note_step
            if nt >= duration:
                break
            dur = min(note_step * 1.5, duration - nt)
            snd = pluck_sound(note_freq(note), dur, volume=0.2)
            pos = int(nt * SAMPLE_RATE)
            _place_sound(pluck_layer, snd, pos)
        t += chord_dur
        chord_idx += 1
    layers.append(pluck_layer)

    # Simple melody
    mel_layer = np.zeros(n)
    mel_notes = ["E5", "D5", "C5", "D5", "E5", "G5", "A5", "G5",
                 "E5", "C5", "D5", "E5"]
    mel_step = 60.0 / bpm * 0.75
    for i, note in enumerate(mel_notes):
        t_start = i * mel_step
        if t_start >= duration:
            break
        dur = min(mel_step * 0.8, duration - t_start)
        snd = sine_wave(note_freq(note), dur, volume=0.18)
        snd = _fade(snd, fade_in=int(len(snd) * 0.05), fade_out=int(len(snd) * 0.15))
        pos = int(t_start * SAMPLE_RATE)
        _place_sound(mel_layer, snd, pos)
    layers.append(mel_layer)

    return _mix_layers(layers, n)


# ---------------------------------------------------------------------------
# Full composition
# ---------------------------------------------------------------------------


def compose_fantasy_saga(total_duration: float = 60.0) -> np.ndarray:
    """Build a ~1 minute cinematic piece flowing through multiple moods.

    Structure (approximate):
      0-10s   Light Fantasy — ethereal intro
     10-22s   Adventure — energy builds
     22-36s   Dark Fantasy — Norse darkness
     36-46s   Vinland Saga Peak — maximum epic
     46-54s   Romantic — emotional cool-down
     54-60s   Everyday — calm resolution
    """
    xfade = int(SAMPLE_RATE * 1.0)

    seg1 = section_light_fantasy(12.0, bpm=100)
    seg2 = section_adventure(14.0, bpm=130)
    seg3 = section_dark_fantasy(14.0, bpm=110)
    seg4 = section_vinland_peak(12.0, bpm=120)
    seg5 = section_romantic(10.0, bpm=80)
    seg6 = section_everyday(10.0, bpm=95)

    # Transition effects
    swell1 = cymbal_swell(1.5)

    # Assemble with crossfades
    composed = seg1
    # Add cymbal swell before adventure
    _place_sound(composed, swell1, max(len(composed) - len(swell1), 0))
    composed = crossfade(composed, seg2, xfade)
    composed = crossfade(composed, seg3, xfade)
    composed = crossfade(composed, seg4, xfade)
    composed = crossfade(composed, seg5, int(xfade * 1.5))
    composed = crossfade(composed, seg6, xfade)

    # Global reverb for cohesion
    composed = reverb(composed, decay=0.2, delay_ms=30)

    # Fade in/out
    composed = _fade(
        composed,
        fade_in=int(SAMPLE_RATE * 0.5),
        fade_out=int(SAMPLE_RATE * 2.0),
    )

    # Trim or pad to exact duration
    target_n = int(total_duration * SAMPLE_RATE)
    if len(composed) > target_n:
        composed = composed[:target_n]
        composed = _fade(composed, fade_out=int(SAMPLE_RATE * 1.0))
    elif len(composed) < target_n:
        composed = np.concatenate([composed, np.zeros(target_n - len(composed))])

    return _normalize(composed)
