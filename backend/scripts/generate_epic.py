#!/usr/bin/env python3
"""Generate a 1-minute epic fantasy composition.

Usage
-----
    python scripts/generate_epic.py
    python scripts/generate_epic.py --duration 90 -o my_saga.wav
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

_backend = Path(__file__).resolve().parent.parent
if str(_backend) not in sys.path:
    sys.path.insert(0, str(_backend))

from app.tools.epic_composer import compose_fantasy_saga  # noqa: E402
from app.tools.music_producer import save_wav  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser(description="Epic Fantasy Saga Composer")
    parser.add_argument(
        "--duration", type=float, default=60.0, help="Total duration in seconds (default: 60)",
    )
    parser.add_argument("-o", "--output", type=str, default="fantasy_saga.wav", help="Output WAV path")
    args = parser.parse_args()

    print(f"🎼 Composing {args.duration:.0f}s epic fantasy saga …")
    print("   Sections: Light Fantasy → Adventure → Dark Fantasy → Vinland Saga → Romance → Everyday")

    signal = compose_fantasy_saga(total_duration=args.duration)
    path = save_wav(signal, args.output)
    dur = len(signal) / 44100

    print(f"   ✔ Saved to {path}  ({dur:.1f}s, {path.stat().st_size / 1024:.0f} KB)")
    print("\nDone! 🎧 Enjoy your saga!")


if __name__ == "__main__":
    main()
