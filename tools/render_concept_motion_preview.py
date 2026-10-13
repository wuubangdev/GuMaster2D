"""Encode complete native frames; no new art, cropping or interpolated frames."""
from pathlib import Path
from PIL import Image
import sys

ROOT=Path(__file__).resolve().parents[1]
prefix=sys.argv[1] if len(sys.argv)>1 else 'concept24'
kind=sys.argv[2] if len(sys.argv)>2 else 'motion'
assert kind in ('motion','gameplay','turn','vertical')
frames=[Image.open(p).convert('RGB') for p in sorted((ROOT/'artifacts'/f'{prefix}_{kind}').glob('frame*.png'))]
assert len(frames)==(96 if kind=='vertical' else 64 if kind=='gameplay' else 48) and all(frame.size==(1280,800) for frame in frames)
frames[0].save(ROOT/'artifacts'/f'{prefix}_{kind}.webp',save_all=True,append_images=frames[1:],duration=42,loop=0,lossless=True,method=6)
print(f'Encoded {len(frames)} full native frames into artifacts/{prefix}_{kind}.webp')
