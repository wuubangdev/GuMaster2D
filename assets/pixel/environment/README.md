# Original pixel environment

The village and grove use square 32 × 32 terrain tiles and native pixel sprites. These graphics were drawn for GuMaster2D by `tools/generate_pixel_environment.py`; no image from Avatar, Khí Phách Anh Hùng, or another game is included. Reference influence is limited to bright classic mobile-game proportions, compact roof silhouettes, and clear top-down paths.

Run `python3 tools/generate_pixel_environment.py` from the project root to regenerate all files. The generator uses the Python standard library and writes exact integer pixels with binary alpha. Runtime images use nearest sampling at 1:1 world scale and an integer camera zoom.

- `terrain.png`: 48 tiles, 8 columns, 32 × 32 pixels per tile. Grass, dirt shoulders, hand-cut paving, six shallow-water frames, flowers, and planted crop beds.
- `props.png`: 31 frames, 8 columns, 96 × 96 pixels per frame. A fixed ground pivot at (48,88) keeps trees, rock formations, roof sections, shrines, lanterns, village wells, fences, and compact houses grounded.
- `manifest.json`: named frame regions and actual alpha bounds relative to the ground pivot. Tree/hut occlusion uses these bounds.
- `props_preview.png`: an integer 2× contact sheet for artwork review; it is not used by the game.

Map presentation preserves the existing navigation cells. Six blocked shrine walls form two joined house fronts. The blocked rock at (9,18) is shown as a well; the rock at (21,21) as stacked crates. Tree blockers at (6,21) and (16,22) use small houses with one-cell ground footprints and roof overhangs. The existing blocked perimeter is shown as a wooden fence. Crop beds, flowers, and shallow puddles are walkable ground decoration. Doors are closed scenery, with no interior interaction implied by the runtime.

`GroundView` owns the terrain TileMapLayer and five-frame-per-second water. `PropView` owns native sprite selection and the small four-frame lantern/altar animation. Reduced motion freezes the water, lanterns, and candle frames at their first frame.
