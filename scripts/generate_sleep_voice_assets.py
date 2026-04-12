#!/usr/bin/env python3
"""Generate short bedtime voice assets with ElevenLabs for Android notifications.

Usage:
  ELEVENLABS_API_KEY=xxx python3 scripts/generate_sleep_voice_assets.py

Optional args:
  --voice Bella
  --model eleven_multilingual_v2
  --out-dir android/app/src/main/res/raw

Notes:
- This script generates sleep_1.wav ... sleep_5.wav
- It also creates soft_bedtime_voice.wav from line 1 for current app wiring.
- Android raw resource names must be lowercase letters, numbers, and underscores.
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

try:
    from elevenlabs import save
    from elevenlabs.client import ElevenLabs
except Exception as exc:  # pragma: no cover
    print("Missing dependency: elevenlabs")
    print("Install with: pip install elevenlabs")
    raise SystemExit(1) from exc


LINES = [
    "Hey... it's time to go to bed.",
    "Your day is done... let's rest.",
    "It's getting late... your body needs sleep.",
    "You've done enough for today... time to sleep.",
    "Let's put the phone down... and rest.",
]


def _convert_mp3_to_wav(src_mp3: Path, dst_wav: Path) -> None:
    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg:
        cmd = [
            ffmpeg,
            "-y",
            "-i",
            str(src_mp3),
            "-ac",
            "1",
            "-ar",
            "22050",
            str(dst_wav),
        ]
        subprocess.run(cmd, check=True)
        return

    afconvert = shutil.which("afconvert")
    if afconvert:
        cmd = [
            afconvert,
            "-f",
            "WAVE",
            "-d",
            "LEI16@22050",
            str(src_mp3),
            str(dst_wav),
        ]
        subprocess.run(cmd, check=True)
        return

    raise RuntimeError(
        "No audio converter found. Install ffmpeg or use macOS afconvert."
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--voice", default="Bella")
    parser.add_argument("--model", default="eleven_multilingual_v2")
    parser.add_argument(
        "--out-dir",
        default="android/app/src/main/res/raw",
        help="Android raw resources directory",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    api_key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not api_key:
        print("ELEVENLABS_API_KEY is missing.")
        print("Example: ELEVENLABS_API_KEY=xxx python3 scripts/generate_sleep_voice_assets.py")
        return 2

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    client = ElevenLabs(api_key=api_key)

    with tempfile.TemporaryDirectory(prefix="elevenlabs_sleep_") as tmp:
        tmp_dir = Path(tmp)

        for idx, text in enumerate(LINES, start=1):
            mp3_path = tmp_dir / f"sleep_{idx}.mp3"
            wav_path = out_dir / f"sleep_{idx}.wav"

            audio = client.generate(text=text, voice=args.voice, model=args.model)
            save(audio, str(mp3_path))
            _convert_mp3_to_wav(mp3_path, wav_path)
            print(f"Generated {wav_path}")

        # Keep compatibility with current app sound resource name.
        alias_path = out_dir / "soft_bedtime_voice.wav"
        shutil.copyfile(out_dir / "sleep_1.wav", alias_path)
        print(f"Updated {alias_path} (alias of sleep_1.wav)")

    print("Done. Rebuild the app so Android resources are refreshed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
