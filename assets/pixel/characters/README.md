# Original 2D pixel character cast

These sprites are authored by `tools/generate_pixel_characters.py` with integer
pixel polygons and lines. No copied game sprites, downloaded character art,
AI image edits, or 3D renders are used. Avatar and classic KPAH inform the broad
visual direction: compact proportions, stepped outlines, warm faces, readable
cloth clusters and eight top-down compass views.

The second art pass places visible eye catchlights below the fringe, with
rounded skulls, curved hair highlights and distinct profile/rear silhouettes.
Crossed tunic collars, a leather sash, split embroidered hems and layered
boots use connected color clusters. Walk/run frames separate the planted
stance from the lifted swing; hair and hems trail the body. Sword, spear and
fist attacks have authored coil, contact and recovery poses. Cast raises the
free hand in the aim direction, while defend lowers the body into a guard.

The 36 cosmetic identities combine two bodies, three outfits, two hairstyles
and three weapon families. Each PNG has 512 transparent 80×80 cells in 16
columns. `manifest.json` supplies cell IDs and exact hand anchors for every
state, direction and frame. The fixed foot pivot is (40,68); nominal native
body height is 48 pixels. Integer enlargement and nearest texture filtering
are required. The view has no independent animation clock or render target.

| Clip | Frames per direction | Playback |
| --- | ---: | --- |
| idle | 4 | loop |
| walk | 8 | loop |
| run | 8 | loop |
| attack | 8 | once; sword slash, spear thrust or fist strike |
| defend | 4 | loop; weapon-specific guard |
| cast | 6 | once |
| channel | 6 | loop |
| dash | 4 | once |
| hit | 4 | once |
| death | 6 | once, final fallen pose |
| respawn | 6 | once |

Directions are down, down-left, left, up-left, up, up-right, right, down-right.
Playback durations share the existing `GuCharacterAnimations.duration()`
contract so gameplay action timing remains authoritative.

Rebuild with Python and Pillow:

```sh
python tools/generate_pixel_characters.py
python tools/validate_pixel_character_assets.py
```

The generator rejects clipped frames. The validation tool checks all 18,432
frame margins, binary alpha, 36 distinct atlas hashes, 36,864 opaque hand
attachment positions, distinct locomotion samples and visible eyes/catchlights
on each front idle pose. `showcase.png` is an actual atlas contact sheet
enlarged with nearest sampling.
