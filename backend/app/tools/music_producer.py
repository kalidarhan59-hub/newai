"""Music production tool — generates beats and melodies as WAV files.

Uses pure numpy for sound synthesis: kick drums, snares, hi-hats,
bass lines, lead synths, pads, and arpeggios.  No external audio
libraries required beyond numpy and the stdlib ``wave`` module.
"""

from __future__ import annotations

import io
import wave
from pathlib import Path
from typing import Any

import numpy as np

from .base import BaseTool

# ---------------------------------------------------------------------------
# Audio helpers
# ---------------------------------------------------------------------------

SAMPLE_RATE = 44100


def _normalize(signal: np.ndarray) -> np.ndarray:
    peak = np.max(np.abs(signal))
    if peak == 0:
        return signal
    return signal / peak


def _fade(signal: np.ndarray, fade_in: int = 0, fade_out: int = 0) -> np.ndarray:
    if fade_in > 0:
        signal[:fade_in] *= np.linspace(0, 1, fade_in)
    if fade_out > 0:
        signal[-fade_out:] *= np.linspace(1, 0, fade_out)
    return signal


def _to_int16(signal: np.ndarray) -> np.ndarray:
    return (np.clip(signal, -1, 1) * 32767).astype(np.int16)


# ---------------------------------------------------------------------------
# Sound generators
# ---------------------------------------------------------------------------

def note_freq(note: str) -> float:
    """Return frequency for a note like 'C4', 'F#3', 'Bb5'."""
    note_map = {
        "C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3,
        "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7, "G#": 8,
        "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11,
    }
    if note[-1].isdigit():
        octave = int(note[-1])
        name = note[:-1]
    else:
        octave = 4
        name = note
    semitone = note_map.get(name, 0)
    return 440.0 * (2 ** ((semitone - 9 + (octave - 4) * 12) / 12))


def sine_wave(freq: float, duration: float, volume: float = 0.5) -> np.ndarray:
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), endpoint=False)
    return volume * np.sin(2 * np.pi * freq * t)


def saw_wave(freq: float, duration: float, volume: float = 0.4) -> np.ndarray:
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), endpoint=False)
    return volume * (2 * (t * freq - np.floor(0.5 + t * freq)))


def square_wave(freq: float, duration: float, volume: float = 0.3) -> np.ndarray:
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), endpoint=False)
    return volume * np.sign(np.sin(2 * np.pi * freq * t))


def triangle_wave(freq: float, duration: float, volume: float = 0.4) -> np.ndarray:
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), endpoint=False)
    return volume * (2 * np.abs(2 * (t * freq - np.floor(t * freq + 0.5))) - 1)


def noise(duration: float, volume: float = 0.3) -> np.ndarray:
    rng = np.random.default_rng(42)
    n = int(SAMPLE_RATE * duration)
    return volume * rng.uniform(-1, 1, n)


# ---------------------------------------------------------------------------
# Drum sounds
# ---------------------------------------------------------------------------

def kick(duration: float = 0.35) -> np.ndarray:
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    freq_sweep = 150 * np.exp(-t * 20) + 40
    phase = 2 * np.pi * np.cumsum(freq_sweep) / SAMPLE_RATE
    sig = 0.9 * np.sin(phase) * np.exp(-t * 7)
    return _fade(sig, fade_out=int(n * 0.1))


def snare(duration: float = 0.2) -> np.ndarray:
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    body = 0.5 * np.sin(2 * np.pi * 200 * t) * np.exp(-t * 30)
    rng = np.random.default_rng(7)
    nse = 0.4 * rng.uniform(-1, 1, n) * np.exp(-t * 15)
    return _fade(body + nse, fade_out=int(n * 0.05))


def hihat(duration: float = 0.08, open_hat: bool = False) -> np.ndarray:
    dur = duration * (3.0 if open_hat else 1.0)
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, endpoint=False)
    rng = np.random.default_rng(21)
    sig = 0.3 * rng.uniform(-1, 1, n)
    decay = 8 if open_hat else 30
    sig *= np.exp(-t * decay)
    return _fade(sig, fade_out=int(n * 0.1))


def clap(duration: float = 0.15) -> np.ndarray:
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    rng = np.random.default_rng(99)
    sig = 0.45 * rng.uniform(-1, 1, n) * np.exp(-t * 20)
    bursts = np.ones(n)
    for i in range(4):
        start = int(n * i * 0.04)
        end = min(start + int(n * 0.02), n)
        bursts[start:end] *= 1.5
    return _fade(sig * bursts, fade_out=int(n * 0.05))


def rim(duration: float = 0.05) -> np.ndarray:
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    sig = 0.5 * np.sin(2 * np.pi * 800 * t) * np.exp(-t * 60)
    return sig


# ---------------------------------------------------------------------------
# FX
# ---------------------------------------------------------------------------

def low_pass(signal: np.ndarray, cutoff: float = 2000.0) -> np.ndarray:
    rc = 1.0 / (2 * np.pi * cutoff)
    dt = 1.0 / SAMPLE_RATE
    alpha = dt / (rc + dt)
    out = np.zeros_like(signal)
    out[0] = alpha * signal[0]
    for i in range(1, len(signal)):
        out[i] = out[i - 1] + alpha * (signal[i] - out[i - 1])
    return out


def reverb(signal: np.ndarray, decay: float = 0.3, delay_ms: float = 40) -> np.ndarray:
    delay_samples = int(SAMPLE_RATE * delay_ms / 1000)
    out = signal.copy()
    for tap in range(1, 5):
        offset = delay_samples * tap
        strength = decay ** tap
        if offset < len(out):
            end = min(len(signal), len(out) - offset)
            out[offset : offset + end] += signal[:end] * strength
    return out


def delay_effect(signal: np.ndarray, time_ms: float = 250, feedback: float = 0.35) -> np.ndarray:
    delay_samples = int(SAMPLE_RATE * time_ms / 1000)
    out = signal.copy()
    for i in range(1, 4):
        offset = delay_samples * i
        strength = feedback ** i
        if offset < len(out):
            end = min(len(signal), len(out) - offset)
            out[offset : offset + end] += signal[:end] * strength
    return out


# ---------------------------------------------------------------------------
# Pattern & sequencer
# ---------------------------------------------------------------------------

def _place_sound(target: np.ndarray, sound: np.ndarray, position: int) -> None:
    end = min(position + len(sound), len(target))
    length = end - position
    if length > 0:
        target[position:end] += sound[:length]


class BeatPattern:
    """Simple step-sequencer: 16 steps per bar."""

    def __init__(self, bpm: float = 120, bars: int = 4, steps_per_bar: int = 16) -> None:
        self.bpm = bpm
        self.bars = bars
        self.steps_per_bar = steps_per_bar
        self.total_steps = bars * steps_per_bar
        self.step_dur = 60.0 / bpm / (steps_per_bar / 4)
        self.total_dur = self.total_steps * self.step_dur
        self.total_samples = int(self.total_dur * SAMPLE_RATE)
        self.tracks: dict[str, np.ndarray] = {}

    def add_drum_track(
        self,
        name: str,
        pattern: list[int],
        sound_fn: Any,
        velocity_pattern: list[float] | None = None,
    ) -> None:
        track = np.zeros(self.total_samples)
        for step_idx in range(self.total_steps):
            pat_idx = step_idx % len(pattern)
            if pattern[pat_idx]:
                pos = int(step_idx * self.step_dur * SAMPLE_RATE)
                vel = 1.0
                if velocity_pattern:
                    vel = velocity_pattern[pat_idx % len(velocity_pattern)]
                snd = sound_fn() * vel
                _place_sound(track, snd, pos)
        self.tracks[name] = track

    def add_note_track(
        self,
        name: str,
        notes: list[tuple[int, str, float]],
        wave_fn: Any = sine_wave,
        volume: float = 0.4,
    ) -> None:
        """notes = [(step, note_name, duration_in_steps), ...]"""
        track = np.zeros(self.total_samples)
        for step, note_name, dur_steps in notes:
            if note_name == "-":
                continue
            freq = note_freq(note_name)
            dur_sec = dur_steps * self.step_dur
            snd = wave_fn(freq, dur_sec, volume)
            snd = _fade(snd, fade_in=int(len(snd) * 0.01), fade_out=int(len(snd) * 0.05))
            pos = int(step * self.step_dur * SAMPLE_RATE)
            _place_sound(track, snd, pos)
        self.tracks[name] = track

    def add_arpeggio_track(
        self,
        name: str,
        chord_notes: list[str],
        pattern_steps: list[int],
        note_dur: float = 0.5,
        wave_fn: Any = triangle_wave,
        volume: float = 0.25,
    ) -> None:
        track = np.zeros(self.total_samples)
        note_idx = 0
        for step_idx in range(self.total_steps):
            pat_idx = step_idx % len(pattern_steps)
            if pattern_steps[pat_idx]:
                note_name = chord_notes[note_idx % len(chord_notes)]
                freq = note_freq(note_name)
                dur_sec = note_dur * self.step_dur
                snd = wave_fn(freq, dur_sec, volume)
                snd = _fade(snd, fade_in=int(len(snd) * 0.02), fade_out=int(len(snd) * 0.1))
                pos = int(step_idx * self.step_dur * SAMPLE_RATE)
                _place_sound(track, snd, pos)
                note_idx += 1
        self.tracks[name] = track

    def mix(self, levels: dict[str, float] | None = None) -> np.ndarray:
        mixed = np.zeros(self.total_samples)
        for name, track in self.tracks.items():
            lvl = 1.0
            if levels:
                lvl = levels.get(name, 1.0)
            mixed += track * lvl
        return _normalize(mixed)


# ---------------------------------------------------------------------------
# Preset beats
# ---------------------------------------------------------------------------

def trap_beat(bpm: float = 140, bars: int = 4) -> BeatPattern:
    bp = BeatPattern(bpm=bpm, bars=bars)

    # Kick: heavy on 1 and 3 with some syncopation
    bp.add_drum_track("kick", [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0], kick)

    # Snare / clap on 2 and 4
    bp.add_drum_track("snare", [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0], clap)

    # Hi-hat rolls
    bp.add_drum_track(
        "hihat",
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
        hihat,
        velocity_pattern=[0.8, 0.4, 0.6, 0.4, 0.8, 0.4, 0.6, 0.4,
                          0.8, 0.4, 0.9, 0.5, 1.0, 0.6, 0.9, 0.5],
    )

    # 808 bass
    bass_notes: list[tuple[int, str, float]] = [
        (0, "C2", 4), (4, "C2", 2), (6, "Eb2", 2),
        (8, "F2", 4), (12, "Eb2", 2), (14, "D2", 2),
    ]
    full_bass: list[tuple[int, str, float]] = []
    for bar in range(bars):
        offset = bar * 16
        for step, note, dur in bass_notes:
            full_bass.append((step + offset, note, dur))
    bp.add_note_track("bass", full_bass, sine_wave, volume=0.6)

    # Dark melody
    melody_notes: list[tuple[int, str, float]] = [
        (0, "C4", 2), (2, "Eb4", 2), (4, "G4", 1), (5, "F4", 1),
        (6, "Eb4", 2), (8, "D4", 2), (10, "C4", 2),
        (12, "Bb3", 2), (14, "C4", 2),
    ]
    full_melody: list[tuple[int, str, float]] = []
    for bar in range(bars):
        offset = bar * 16
        for step, note, dur in melody_notes:
            full_melody.append((step + offset, note, dur))
    bp.add_note_track("melody", full_melody, saw_wave, volume=0.2)

    return bp


def lofi_beat(bpm: float = 85, bars: int = 4) -> BeatPattern:
    bp = BeatPattern(bpm=bpm, bars=bars)

    bp.add_drum_track("kick", [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0], kick)
    bp.add_drum_track("snare", [0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0], snare)
    bp.add_drum_track(
        "hihat",
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0],
        hihat,
        velocity_pattern=[0.7, 0.3, 0.5, 0.3, 0.7, 0.3, 0.5, 0.3,
                          0.7, 0.3, 0.5, 0.3, 0.7, 0.3, 0.5, 0.3],
    )

    # Jazzy chords with triangle wave
    chord_prog: list[tuple[int, str, float]] = [
        (0, "C4", 4), (0, "E4", 4), (0, "G4", 4), (0, "B4", 4),
        (4, "A3", 4), (4, "C4", 4), (4, "E4", 4), (4, "G4", 4),
        (8, "F3", 4), (8, "A3", 4), (8, "C4", 4), (8, "E4", 4),
        (12, "G3", 4), (12, "B3", 4), (12, "D4", 4), (12, "F4", 4),
    ]
    full_chords: list[tuple[int, str, float]] = []
    for bar in range(bars):
        offset = bar * 16
        for step, note, dur in chord_prog:
            full_chords.append((step + offset, note, dur))
    bp.add_note_track("chords", full_chords, triangle_wave, volume=0.15)

    # Melody
    mel: list[tuple[int, str, float]] = [
        (0, "E5", 2), (2, "D5", 1), (3, "C5", 1),
        (4, "B4", 2), (6, "A4", 2),
        (8, "G4", 2), (10, "A4", 1), (11, "B4", 1),
        (12, "C5", 3), (15, "B4", 1),
    ]
    full_mel: list[tuple[int, str, float]] = []
    for bar in range(bars):
        offset = bar * 16
        for step, note, dur in mel:
            full_mel.append((step + offset, note, dur))
    bp.add_note_track("melody", full_mel, sine_wave, volume=0.25)

    return bp


def edm_beat(bpm: float = 128, bars: int = 4) -> BeatPattern:
    bp = BeatPattern(bpm=bpm, bars=bars)

    # Four-on-the-floor kick
    bp.add_drum_track("kick", [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0], kick)
    bp.add_drum_track("clap", [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0], clap)
    bp.add_drum_track(
        "hihat",
        [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0],
        lambda: hihat(open_hat=False),
    )
    bp.add_drum_track(
        "open_hat",
        [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
        lambda: hihat(open_hat=True),
    )

    # Driving bass
    bass_notes: list[tuple[int, str, float]] = [
        (0, "E2", 2), (2, "E2", 2), (4, "E2", 2), (6, "G2", 2),
        (8, "A2", 2), (10, "A2", 2), (12, "G2", 2), (14, "E2", 2),
    ]
    full_bass: list[tuple[int, str, float]] = []
    for bar in range(bars):
        offset = bar * 16
        for step, note, dur in bass_notes:
            full_bass.append((step + offset, note, dur))
    bp.add_note_track("bass", full_bass, square_wave, volume=0.35)

    # Arpeggio
    bp.add_arpeggio_track(
        "arp",
        ["E4", "G4", "B4", "E5", "B4", "G4"],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
        note_dur=0.8,
        wave_fn=saw_wave,
        volume=0.15,
    )

    # Lead
    lead: list[tuple[int, str, float]] = [
        (0, "E5", 4), (4, "D5", 4), (8, "C5", 4), (12, "B4", 4),
    ]
    full_lead: list[tuple[int, str, float]] = []
    for bar in range(bars):
        offset = bar * 16
        for step, note, dur in lead:
            full_lead.append((step + offset, note, dur))
    bp.add_note_track("lead", full_lead, saw_wave, volume=0.2)

    return bp


def hiphop_beat(bpm: float = 90, bars: int = 4) -> BeatPattern:
    bp = BeatPattern(bpm=bpm, bars=bars)

    bp.add_drum_track("kick", [1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0], kick)
    bp.add_drum_track("snare", [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0], snare)
    bp.add_drum_track("rim", [0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0], rim)
    bp.add_drum_track(
        "hihat",
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1],
        hihat,
        velocity_pattern=[0.9, 0.4, 0.6, 0.4, 0.9, 0.4, 0.6, 0.4,
                          0.9, 0.4, 0.6, 0.4, 0.9, 0.4, 0.6, 0.8],
    )

    # Boom-bap bass
    bass: list[tuple[int, str, float]] = [
        (0, "G2", 4), (4, "G2", 2), (6, "Bb2", 2),
        (8, "C3", 4), (12, "Bb2", 2), (14, "A2", 2),
    ]
    full_bass: list[tuple[int, str, float]] = []
    for bar in range(bars):
        offset = bar * 16
        for step, note, dur in bass:
            full_bass.append((step + offset, note, dur))
    bp.add_note_track("bass", full_bass, sine_wave, volume=0.55)

    # Piano-style chords
    chords: list[tuple[int, str, float]] = [
        (0, "G3", 4), (0, "Bb3", 4), (0, "D4", 4),
        (8, "C3", 4), (8, "Eb3", 4), (8, "G3", 4),
    ]
    full_ch: list[tuple[int, str, float]] = []
    for bar in range(bars):
        offset = bar * 16
        for step, note, dur in chords:
            full_ch.append((step + offset, note, dur))
    bp.add_note_track("chords", full_ch, triangle_wave, volume=0.18)

    return bp


PRESETS: dict[str, Any] = {
    "trap": trap_beat,
    "lofi": lofi_beat,
    "edm": edm_beat,
    "hiphop": hiphop_beat,
}


# ---------------------------------------------------------------------------
# WAV export
# ---------------------------------------------------------------------------

def save_wav(signal: np.ndarray, path: str | Path) -> Path:
    filepath = Path(path)
    filepath.parent.mkdir(parents=True, exist_ok=True)
    data = _to_int16(signal)
    with wave.open(str(filepath), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(data.tobytes())
    return filepath


def wav_bytes(signal: np.ndarray) -> bytes:
    buf = io.BytesIO()
    data = _to_int16(signal)
    with wave.open(buf, "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(data.tobytes())
    return buf.getvalue()


# ---------------------------------------------------------------------------
# Generate a full beat from preset
# ---------------------------------------------------------------------------

def generate_beat(
    style: str = "trap",
    bpm: float | None = None,
    bars: int = 4,
    apply_reverb: bool = True,
    apply_delay: bool = False,
) -> np.ndarray:
    factory = PRESETS.get(style, trap_beat)
    kwargs: dict[str, Any] = {"bars": bars}
    if bpm is not None:
        kwargs["bpm"] = bpm
    bp = factory(**kwargs)
    levels: dict[str, float] = {
        "kick": 1.0, "snare": 0.9, "clap": 0.9, "hihat": 0.7,
        "open_hat": 0.6, "rim": 0.5, "bass": 0.85,
        "chords": 0.6, "melody": 0.7, "lead": 0.65, "arp": 0.5,
    }
    mixed = bp.mix(levels)
    if apply_reverb:
        mixed = reverb(mixed, decay=0.25, delay_ms=35)
    if apply_delay:
        mixed = delay_effect(mixed, time_ms=200, feedback=0.3)
    return _normalize(mixed)


# ---------------------------------------------------------------------------
# Tool integration
# ---------------------------------------------------------------------------

class MusicProducerTool(BaseTool):
    name: str = "music_producer"
    description: str = (
        "Generate music beats and export as WAV. "
        "Styles: trap, lofi, edm, hiphop. "
        "Returns the file path of the generated WAV."
    )
    schema: dict[str, Any] = {
        "type": "object",
        "properties": {
            "style": {
                "type": "string",
                "enum": ["trap", "lofi", "edm", "hiphop"],
                "description": "Beat style preset",
            },
            "bpm": {
                "type": "number",
                "description": "Beats per minute (optional, uses preset default)",
            },
            "bars": {
                "type": "integer",
                "description": "Number of bars to generate (default 4)",
            },
            "output_path": {
                "type": "string",
                "description": "Output WAV file path",
            },
            "reverb": {
                "type": "boolean",
                "description": "Apply reverb effect (default true)",
            },
            "delay": {
                "type": "boolean",
                "description": "Apply delay effect (default false)",
            },
        },
        "required": ["style"],
    }

    async def call(self, arguments: dict[str, Any]) -> Any:
        style = arguments.get("style", "trap")
        bpm_val = arguments.get("bpm")
        bars = arguments.get("bars", 4)
        output = arguments.get("output_path", f"output_{style}_beat.wav")
        use_reverb = arguments.get("reverb", True)
        use_delay = arguments.get("delay", False)

        signal = generate_beat(
            style=style,
            bpm=bpm_val,
            bars=bars,
            apply_reverb=use_reverb,
            apply_delay=use_delay,
        )
        path = save_wav(signal, output)
        return {"file": str(path), "style": style, "bars": bars, "samples": len(signal)}
