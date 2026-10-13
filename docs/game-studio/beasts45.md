# Bestiary 0.45 — articulated wildlife and readable attacks

The original eight species and their progression IDs, health, damage, drops, capture Gu, respawn times and quest references remain intact. This feature replaces the flat rotated illustrations with native, antialiased ink geometry and adds a two-ability repertoire per species.

## Artwork and rig

`BeastMotion` constructs animals in a local forward/side/height coordinate system. Turning changes the ground axes while height stays upright. The head is rendered behind the torso when facing away, far limbs precede the body, and near limbs follow it. Every family has its own shape and anatomy: the wolf's chest ruff and long muzzle; the boar's raised bristle ridge, hooves and tusks; the spider's eight hinged legs and fangs; the hornet's striped abdomen, antennae and translucent veined wings; the toad's folded hind legs, eye domes and expanding throat; the beetle's split carapace and mandibles. The elite wolf adds lightning markings; the guardian has raised stone plates and a crest.

Each leg uses two fixed-length bones solved toward a grounded or lifting foot. Gait uses 62% planted stance and 38% smooth return. The presentation stride length is 10.4 / 0.62 pixels times gait weight and the elite body scale. This prevents the old mismatch between foot motion and travel. Breathing, loaded posture, jaw opening, contact recoil, recovery, hit coloration and a 0.65-second folded collapse are separate parts of the pose. Bone lengths do not change during facing or animation. Motion reduction keeps anatomy and ground warnings readable while suppressing gait, wing vibration, breathing and attack bounce.

`BeastArt` preserves its original call contract and accepts optional `death_age`. Missing species and new timers fall back to wolf/idle for the original starter enemies. `ActorView` integrates the stride conversion, the longer defeat presentation and the legacy wolf warning footprint; gameplay progression stays owned by authority.

## Abilities and authority

| Species | First ability | Second ability |
|---|---|---|
| Sói rừng | Lang nha, bite sector | Trảo phong, frontal claw sector |
| Hắc mao trư | Hắc mao xung, charge lane | Dậm địa, close ground slam |
| Độc ti nhện | Độc ti, locked poison spot | Tam độc ti, three spaced spots |
| Kim châm phong | Kim châm, narrow sting cone | Phong thích, close sting |
| Đầm độc thiềm | Độc đàm, locked poison spot | Thiềm tức, poison fan |
| Thạch giáp trùng | Thạch giáp xung, charge lane | Liệt địa, close ground slam |
| Điện lang | Lôi lang xung, charge lane | Lôi trảo, wide frontal claw |
| Thủ vệ truyền thừa | Tam ấn địa mạch, three rune spots | Chấn địa, broad ground slam |

`Bestiary.attack(mob)` reads the current ability while retaining the base creature's stats. Aim and `attack_geometry` lock at windup. `WildlifeAI` resolves damage once at windup completion, then commits the creature to its authored recovery period without chasing or repeating the hit. The next ability becomes available afterward. Charge relocation retains the existing immediate authoritative contact contract; rendering interpolates the travel. This is a local game authority, not networked combat prediction.

`BeastAttackGeometry` owns the exact world-space footprint. It supplies both analytic containment and the tessellated ground polygons: sector for melee/cone, capsule for charge, circles for spit/slam/three-spot burst. `beast_strike` includes this same geometry, the species, origin, endpoint, ability name and radius for impact VFX. Effects never apply damage. Area skills hit once; they do not leave an untelegraphed damage-over-time hazard.

Safe-zone checks and line-of-sight reject damage. Charges sweep collision and stop before safe zones. Starting or continuing windup is cancelled when either participant enters safety. Distant animals at their home camp use an early sleep path after timers so the expanded map does not run safe-zone scans/pathfinding for every remote creature each tick.

## Verification

**170/170 checks passed.** `tests/beast45_tests.gd` exercises all 16 abilities through the real authority: no pre-contact damage, one contact hit, committed recovery, aim lock and dodge, event geometry, wall obstruction and safe-zone rejection. It compares 51,984 points against rendered warning polygons with a maximum permitted tessellation difference of 0.192 screen pixels, then checks 10,752 leg chains over all eight headings. Planted-foot checks include elite scale and fixed support during anticipation, strike and hit recoil. Results are recorded in `artifacts/beast45_tests.json`.

`tests/beast45_review.gd` captures native Godot artwork for eight species × eight headings × six states, plus 24 walk and 24 attack motion boards. These plates isolate anatomy; the live-game captures and the Gu-effects review show actual ground warnings and impacts. Runtime images are saved under `artifacts/beast45_*` and enumerated in `artifacts/beast45_native.json`. A visual review widened the toad stance (20-pixel hind support, 15-pixel fore support), gave its front and rear legs different lengths, added webbed feet, and hid the boar nostril marks from rear views. `tests/beast45_toad_review.gd` records all 54 updated toad strips plus a refreshed complete idle plate; `artifacts/beast45_toad_native.json` lists those images. The browser inspector uses the final toad strips for every toad clip. Both native runs finished without script or triangulation errors.
