#!/usr/bin/env python3
"""CLI for the Manus Core music producer.

Examples
--------
    # Generate a trap beat (default):
    python scripts/generate_beat.py

    # Lo-fi beat at 80 BPM, 8 bars, with delay:
    python scripts/generate_beat.py --style lofi --bpm 80 --bars 8 --delay

    # EDM beat saved to a custom path:
    python scripts/generate_beat.py --style edm -o my_edm.wav

    # Generate all four styles at once:
    python scripts/generate_beat.py --all
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Allow running from the repo root or the backend/ directory.
_backend = Path(__file__).resolve().parent.parent
if str(_backend) not in sys.path:
    sys.path.insert(0, str(_backend))

from app.tools.music_producer import PRESETS, generate_beat, save_wav  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Manus Core Beat Generator — create beats from the command line."
    )
    parser.add_argument(
        "--style",
        choices=list(PRESETS.keys()),
        default="trap",
        help="Beat style preset (default: trap)",
    )
    parser.add_argument("--bpm", type=float, default=None, help="BPM override")
    parser.add_argument("--bars", type=int, default=4, help="Number of bars (default: 4)")
    parser.add_argument("--reverb", action="store_true", default=True, help="Enable reverb (default)")
    parser.add_argument("--no-reverb", dest="reverb", action="store_false", help="Disable reverb")
    parser.add_argument("--delay", action="store_true", default=False, help="Enable delay effect")
    parser.add_argument("-o", "--output", type=str, default=None, help="Output WAV path")
    parser.add_argument("--all", action="store_true", help="Generate all styles")

    args = parser.parse_args()

    styles = list(PRESETS.keys()) if args.all else [args.style]

    for style in styles:
        output_path = args.output if (args.output and not args.all) else f"output_{style}_beat.wav"
        print(f"🎵 Generating {style} beat ({args.bars} bars) ...")

        signal = generate_beat(
            style=style,
            bpm=args.bpm,
            bars=args.bars,
            apply_reverb=args.reverb,
            apply_delay=args.delay,
        )
        path = save_wav(signal, output_path)
        dur = len(signal) / 44100
        print(f"   ✔ Saved to {path}  ({dur:.1f}s, {path.stat().st_size / 1024:.0f} KB)")

    print("\nDone! 🎧")


if __name__ == "__main__":
    main()
