#!/usr/bin/env python3
"""Generate Light Fantasy compositions — 3 variants.

Usage
-----
    python scripts/generate_light_fantasy.py
    python scripts/generate_light_fantasy.py --duration 90
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

_backend = Path(__file__).resolve().parent.parent
if str(_backend) not in sys.path:
    sys.path.insert(0, str(_backend))

from app.tools.light_fantasy_composer import (  # noqa: E402
    compose_light_fantasy_piano_accents,
    compose_light_fantasy_piano_bg,
    compose_light_fantasy_pure,
)
from app.tools.music_producer import save_wav  # noqa: E402

VARIANTS = [
    ("light_fantasy_no_piano.wav", "без пианино", compose_light_fantasy_pure),
    ("light_fantasy_piano_accents.wav", "пианино в некоторых местах", compose_light_fantasy_piano_accents),
    ("light_fantasy_piano_bg.wav", "пианино в фоне", compose_light_fantasy_piano_bg),
]


def main() -> None:
    parser = argparse.ArgumentParser(description="Light Fantasy Composer — 3 variants")
    parser.add_argument(
        "--duration", type=float, default=60.0, help="Duration in seconds (default: 60)",
    )
    parser.add_argument("--bpm", type=float, default=92, help="BPM (default: 92)")
    args = parser.parse_args()

    for filename, label, fn in VARIANTS:
        print(f"🌟 Generating: {label} …")
        signal = fn(duration=args.duration, bpm=args.bpm)
        path = save_wav(signal, filename)
        dur = len(signal) / 44100
        print(f"   ✔ {path}  ({dur:.1f}s, {path.stat().st_size / 1024:.0f} KB)")

    print("\nDone! 🎧")


if __name__ == "__main__":
    main()
