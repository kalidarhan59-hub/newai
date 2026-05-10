#!/usr/bin/env python3
"""Generate Light Fantasy v3 — clean 2-minute composition.

Usage
-----
    python scripts/generate_light_fantasy_v3.py
    python scripts/generate_light_fantasy_v3.py --duration 120 -o my_track.wav
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

_backend = Path(__file__).resolve().parent.parent
if str(_backend) not in sys.path:
    sys.path.insert(0, str(_backend))

from app.tools.light_fantasy_v3 import compose_light_fantasy_v3  # noqa: E402
from app.tools.music_producer import save_wav  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser(description="Light Fantasy v3 — Clean Composition")
    parser.add_argument(
        "--duration", type=float, default=120.0,
        help="Duration in seconds (default: 120)",
    )
    parser.add_argument("-o", "--output", default="light_fantasy_v3.wav", help="Output path")
    args = parser.parse_args()

    print(f"🌟 Generating clean Light Fantasy ({args.duration:.0f}s) …")
    print("   No noise/rain/wind — pure instruments only")
    print("   Harp + bells: continuous from start to end")

    signal = compose_light_fantasy_v3(duration=args.duration)
    path = save_wav(signal, args.output)
    dur = len(signal) / 44100
    print(f"   ✔ {path}  ({dur:.1f}s, {path.stat().st_size / 1024:.0f} KB)")
    print("\nDone! 🎧")


if __name__ == "__main__":
    main()
