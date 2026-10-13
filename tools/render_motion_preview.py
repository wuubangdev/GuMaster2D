"""Create a review GIF from actual Godot frames; requires Pillow, not used by the game."""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
samples = json.loads((ROOT / "artifacts/motion_samples.json").read_text())
frames = sorted((ROOT / "artifacts/motion").glob("frame_*.png"))
assert len(frames) == samples["frames"] == 80
images = []
for frame in frames:
    with Image.open(frame) as source:
        images.append(source.convert("RGB").resize((800, 500), Image.Resampling.LANCZOS))
# GIF delays use centiseconds. Rounded frame boundaries preserve the 24 Hz timeline.
# A shared palette keeps flat jade tones stable rather than flickering between frames.
palette_source = Image.new("RGB", (800, 2000))
for index, frame in enumerate((0, 29, 40, 52)):
    palette_source.paste(images[frame], (0, index * 500))
palette = palette_source.quantize(colors=160)
indexed = [image.quantize(palette=palette, dither=Image.Dither.NONE) for image in images]
destination = ROOT / "artifacts/windows_motion.gif"
indexed[0].save(destination, save_all=True, append_images=indexed[1:], duration=[(round((i + 1) * 100 / 24) - round(i * 100 / 24)) * 10 for i in range(len(indexed))], loop=0, optimize=True, disposal=1)
print(json.dumps({"gif": str(destination), "frames": len(images), "bytes": destination.stat().st_size}))

# Separate real-render comparison of the three weapon families on both bodies.
weapon = json.loads((ROOT / "artifacts/weapon_motion_capture.json").read_text())
frames = sorted((ROOT / "artifacts/weapon_frames").glob("frame_*.png"))
assert len(frames) == weapon["frames"] == 96
images = []
for frame in frames:
    with Image.open(frame) as source:
        images.append(source.convert("RGB").resize((1008, 672), Image.Resampling.LANCZOS))
palette_source = Image.new("RGB", (1008, 672 * 4))
for index, frame in enumerate((0, 30, 57, 80)):
    palette_source.paste(images[frame], (0, index * 672))
palette = palette_source.quantize(colors=200)
indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in images]
destination = ROOT / "artifacts/wardrobe_weapon_motion.gif"
indexed[0].save(destination, save_all=True, append_images=indexed[1:], duration=[(round((i + 1) * 100 / 24) - round(i * 100 / 24)) * 10 for i in range(len(indexed))], loop=0, optimize=True, disposal=1)
print(json.dumps({"gif": str(destination), "frames": len(images), "bytes": destination.stat().st_size}))

# Character review is a separate native-rendered scene, not a composited sprite sheet.
review = json.loads((ROOT / "artifacts/character_samples.json").read_text())
character_frames = sorted((ROOT / "artifacts/character_motion").glob("frame_*.png"))
assert len(character_frames) == review["frames"] == 72
characters = []
for frame in character_frames:
    with Image.open(frame) as source:
        characters.append(source.convert("RGB"))
width, height = characters[0].size
palette_source = Image.new("RGB", (width, height * 4))
for index, frame in enumerate((0, 3, 10, 16)):
    palette_source.paste(characters[frame], (0, index * height))
palette = palette_source.quantize(colors=160)
indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in characters]
destination = ROOT / "artifacts/windows_character_motion.gif"
indexed[0].save(destination, save_all=True, append_images=indexed[1:], duration=[(round((i + 1) * 100 / 24) - round(i * 100 / 24)) * 10 for i in range(len(indexed))], loop=0, optimize=True, disposal=1)
print(json.dumps({"gif": str(destination), "frames": len(characters), "bytes": destination.stat().st_size}))

# Workshop animation review: all eleven skeletal clips, no simulated gameplay side effects.
studio = json.loads((ROOT / "artifacts/studio_motion_capture.json").read_text())
frames = sorted((ROOT / "artifacts/studio_frames").glob("frame_*.png"))
assert len(frames) == studio["frames"] == 99
images = []
for frame in frames:
    with Image.open(frame) as source:
        images.append(source.convert("RGB").resize((960, 600), Image.Resampling.LANCZOS))
palette_source = Image.new("RGB", (960, 600 * 5))
for index, frame in enumerate((0, 20, 35, 62, 90)):
    palette_source.paste(images[frame], (0, index * 600))
palette = palette_source.quantize(colors=200)
indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in images]
destination = ROOT / "artifacts/character_studio_motion.gif"
indexed[0].save(destination, save_all=True, append_images=indexed[1:], duration=[(round((i + 1) * 100 / 24) - round(i * 100 / 24)) * 10 for i in range(len(indexed))], loop=0, optimize=True, disposal=1)
print(json.dumps({"gif": str(destination), "frames": len(images), "bytes": destination.stat().st_size}))
