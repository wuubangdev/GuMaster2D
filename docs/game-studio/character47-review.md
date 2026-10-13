# Character art review 0.47

This review compares the frozen 0.46 character atlas and shader with the current
0.47 artwork, using the production `GuIllustratedCharacterView` renderer.

## Evidence layout

- Eight directions, male and female appearances.
- Nine still poses per direction: idle, sword preparation/contact/recovery,
  defense, gathering contact, mining contact, walking, and running.
- Six motion clips per direction: attack, defend, gather, mine, walk, and run.
  Each clip contains 24 native frames with four simulation substeps per frame.
  Motion is produced by `present_smooth`, including transition history and
  secondary motion.
- Every image includes the old and new versions at display heights 200 and 48.
  The latter is the character's real game configuration, on a neutral review
  background; it is not an in-world gameplay screenshot.
- Native framebuffer size is 960 × 760. The male and female rows are exported
  as exact 960 × 380 pixel crops. Neither the exporter nor the browser enlarges
  the native image.

Both versions share an identical rig and sampled pose. The harness asserts that
source geometry, asset bounds, atlas coordinates, bone ownership, anchors, and
rest chains match the baseline. Before every capture it also checks exact pose
equality and verifies that the old shader and atlas remain attached after
`_publish` updates eye and blink parameters.

The baseline SVG receives `Image.fix_alpha_edges()` to match the production
import's `process/fix_alpha_border=true`. Otherwise raw transparent SVG texels
would give the baseline a different edge treatment before shader comparison.

## Commands

After generating artwork and importing the final assets, freeze source edits
while capturing:

```bash
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy \
  --script res://tests/character47_art_review.gd -- --test-mode
python3 tools/build_character47_art_review.py
/mnt/c/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe \
  tools/verify_character47_art_review.cjs
```

For an initial native inspection, pass `--directions=0,4,6 --poses-only`.
The final page builder rejects these incomplete reports until all eight
directions have the full motion evidence.

## Provenance and output

Each direction report records SHA-256 hashes of the shader, renderer, rig,
motion helpers, generator, manifest, atlases, texture import settings, source
PNGs and ownership masks, frozen baseline, and capture harness. A changed hash
aborts capture. The builder refuses stale or mixed-source direction reports
and verifies every PNG's native dimensions.

The browser presents the native rows, or a 480 × 380 crop of one version. It
does not animate body parts or interpolate source images. The browser verifier
checks the displayed canvas against the exact native crop, all directions,
bodies, poses and clips, playback controls, responsive sizes, source hashes,
and missing resources or JavaScript errors.

Artifacts:

- `artifacts/concept47_character_review.html`: interactive local review.
- `artifacts/concept47_review.json`: aggregate manifest and source hashes.
- `artifacts/concept47_d0_native.json` through `concept47_d7_native.json`:
  capture reports.
- `artifacts/concept47/d{direction}/{body}/`: native PNG rows.
- `artifacts/concept47_browser.json`: browser verification results.
- `artifacts/concept47_browser.png` and `concept47_browser_mobile.png`:
  browser screenshots.

These checks establish that the comparison is faithful and interactive. They
do not assign an automatic artistic quality score or replace visual review of
the poses and movement.

## Verified result

- Native Godot run completed successfully for all eight directions: 1,224
  framebuffer captures, exported as 2,448 body PNG rows. This includes 72
  still framebuffers and 1,152 motion framebuffers.
- All 4,896 old/new pose comparisons matched exactly. The baseline material
  remained attached throughout playback; geometry and anchor contracts matched.
- All 31 tracked source hashes remained unchanged during capture and matched
  when the page was built. Every exported PNG had the expected dimensions.
- Windows Chrome verification passed **621 / 621 checks**, with no JavaScript
  errors or missing resources. Coverage includes all 144 body/pose states,
  all 96 body/action clips, frame selection and playback, exact A/B crop pixels,
  true 1:1 desktop display, and 1440/960/390-pixel responsive layouts.
- The “Xem trong game” link resolves to the actual native
  `concept47_world_front.png` captured by the separate in-game test.
- Desktop and mobile review screenshots were visually inspected after the
  browser checks. Representative still or moving frames were inspected across
  all eight directions; no comparison-column clipping was observed.

Review: <http://localhost:8879/concept47_character_review.html>.
