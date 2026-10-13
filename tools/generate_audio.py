"""Bake small original PCM effects. Python stdlib only; no runtime synthesis."""
import math
from pathlib import Path
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
PARAMS = {"cast": (660, 990, .16), "shield": (330, 550, .30), "dash": (550, 170, .18),
          "frost": (1400, 850, .23), "hit": (160, 60, .10), "loot": (740, 1480, .24),
          "capture": (440, 880, .45), "denied": (180, 150, .12), "death": (220, 65, .45)}

def main():
    output = ROOT / "assets" / "audio"
    output.mkdir(parents=True, exist_ok=True)
    rng = random.Random(74021)
    for name, (start, end, duration) in PARAMS.items():
        samples = bytearray()
        phase = 0.0
        for i in range(int(22050 * duration)):
            t = i / 22050
            p = t / duration
            phase += math.tau * (start + (end-start)*p) / 22050
            signal = math.sin(phase) * .7 + math.sin(phase*2.003) * .2
            if name in ("dash", "hit", "frost"):
                signal = signal * .45 + rng.uniform(-.4, .4)
            envelope = min(1, t/.008) * (1-p)**2
            samples.extend(struct.pack("<h", int(signal * envelope * 22000)))
        with wave.open(str(output / f"{name}.wav"), "wb") as f:
            f.setnchannels(1)
            f.setsampwidth(2)
            f.setframerate(22050)
            f.writeframes(samples)

if __name__ == "__main__":
    main()
