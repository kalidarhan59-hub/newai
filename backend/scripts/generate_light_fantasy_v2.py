#!/usr/bin/env python3
"""Generate Light Fantasy v2 — two 2-minute variants.

Usage
-----
    python scripts/generate_light_fantasy_v2.py
"""

from __future__ import annotations

import sys
from pathlib import Path

_backend = Path(__file__).resolve().parent.parent
if str(_backend) not in sys.path:
    sys.path.insert(0, str(_backend))

from app.tools.light_fantasy_v2 import compose_v1_devin, compose_v2_structured  # noqa: E402
from app.tools.music_producer import save_wav  # noqa: E402

VARIANTS = [
    (
        "light_fantasy_v2_devin.wav",
        "Вариант 1 (Devin): плавная эволюция, без провалов",
        compose_v1_devin,
    ),
    (
        "light_fantasy_v2_structured.wav",
        "Вариант 2 (Структурный): Интро→Куплет→Припев→Бридж→Куплет2→Припев2→Аутро",
        compose_v2_structured,
    ),
]


def main() -> None:
    for filename, label, fn in VARIANTS:
        print(f"🌟 {label} …")
        signal = fn(duration=120.0)
        path = save_wav(signal, filename)
        dur = len(signal) / 44100
        print(f"   ✔ {path}  ({dur:.1f}s, {path.stat().st_size / 1024:.0f} KB)")

    print("\nDone! 🎧")


if __name__ == "__main__":
    main()
