"""Tests for the music producer tool."""

from __future__ import annotations

import wave
from pathlib import Path

import numpy as np
import pytest

from app.tools.music_producer import (
    PRESETS,
    BeatPattern,
    MusicProducerTool,
    generate_beat,
    hihat,
    kick,
    noise,
    note_freq,
    save_wav,
    saw_wave,
    sine_wave,
    snare,
    square_wave,
    triangle_wave,
    wav_bytes,
)


class TestNoteFreq:
    def test_a4(self):
        assert abs(note_freq("A4") - 440.0) < 0.01

    def test_c4(self):
        assert abs(note_freq("C4") - 261.63) < 0.1

    def test_sharp(self):
        assert note_freq("C#4") > note_freq("C4")

    def test_flat(self):
        assert abs(note_freq("Db4") - note_freq("C#4")) < 0.01

    def test_octave_up(self):
        assert abs(note_freq("A5") - 880.0) < 0.01


class TestWaveforms:
    def test_sine_length(self):
        sig = sine_wave(440, 1.0)
        assert len(sig) == 44100

    def test_saw_length(self):
        sig = saw_wave(440, 0.5)
        assert len(sig) == 22050

    def test_square_range(self):
        sig = square_wave(440, 0.1, volume=1.0)
        assert np.all(np.abs(sig) <= 1.0 + 1e-9)

    def test_triangle_range(self):
        sig = triangle_wave(440, 0.1, volume=1.0)
        assert np.all(np.abs(sig) <= 1.0 + 1e-9)

    def test_noise_length(self):
        sig = noise(0.5)
        assert len(sig) == 22050


class TestDrums:
    def test_kick_shape(self):
        k = kick()
        assert len(k) > 0
        assert k.dtype == np.float64

    def test_snare_shape(self):
        s = snare()
        assert len(s) > 0

    def test_hihat_shapes(self):
        hh_closed = hihat(open_hat=False)
        hh_open = hihat(open_hat=True)
        assert len(hh_open) > len(hh_closed)


class TestBeatPattern:
    def test_create(self):
        bp = BeatPattern(bpm=120, bars=2)
        assert bp.total_steps == 32

    def test_add_drum_track(self):
        bp = BeatPattern(bpm=120, bars=1)
        bp.add_drum_track("kick", [1, 0, 0, 0] * 4, kick)
        assert "kick" in bp.tracks
        assert len(bp.tracks["kick"]) == bp.total_samples

    def test_mix(self):
        bp = BeatPattern(bpm=120, bars=1)
        bp.add_drum_track("kick", [1, 0, 0, 0] * 4, kick)
        mixed = bp.mix()
        assert len(mixed) == bp.total_samples
        assert np.max(np.abs(mixed)) <= 1.0 + 1e-9


class TestPresets:
    @pytest.mark.parametrize("style", list(PRESETS.keys()))
    def test_preset_generates(self, style: str):
        signal = generate_beat(style=style, bars=1)
        assert len(signal) > 0
        assert np.max(np.abs(signal)) <= 1.0 + 1e-9


class TestExport:
    def test_save_wav(self, tmp_path: Path):
        sig = sine_wave(440, 0.5)
        path = save_wav(sig, tmp_path / "test.wav")
        assert path.exists()
        with wave.open(str(path), "r") as wf:
            assert wf.getnchannels() == 1
            assert wf.getsampwidth() == 2
            assert wf.getframerate() == 44100

    def test_wav_bytes(self):
        sig = sine_wave(440, 0.1)
        data = wav_bytes(sig)
        assert isinstance(data, bytes)
        assert len(data) > 0


class TestMusicProducerTool:
    @pytest.mark.asyncio
    async def test_call(self, tmp_path: Path):
        tool = MusicProducerTool()
        result = await tool.call({
            "style": "trap",
            "bars": 1,
            "output_path": str(tmp_path / "beat.wav"),
        })
        assert result["style"] == "trap"
        assert Path(result["file"]).exists()
