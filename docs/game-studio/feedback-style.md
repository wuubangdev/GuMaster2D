# Feedback grammar

Dark jade forest, worn stone, ivory labels, bronze UI edging, vermilion health, blue mana, aqua moon, gold protection/reward, ice-blue frost, amber-red warnings. Glyphs, labels and actual values accompany color.

## Character art and movement — 0.6

An original tall martial-arts silhouette replaces the short placeholder: navy outer robe, ivory sleeves and underlayer, jade lapel/sash, bronze trim, leather pouch, jade pendant and a tied topknot. The contrast of light sleeves and dark cloth preserves the figure on the green terrain. Front, rear, diagonal and profile views use directional proportions, hair/face and arm ordering; no borrowed character art is shipped.

`GuHumanoidRig.sample` produces a pure pose in screen-space ground coordinates. `GuHumanoidArt` renders the layered costume from that pose. World actors, the frozen F3 paper doll and HUD portrait share these recipes. Feet remain attached to the ground point used for Y sorting; body breathing, elbows/knees, cloth and hair are independent secondary motion. A 38-screen-unit gait cycle has a linear stance and lifted return; the planted foot cancels body translation at full movement blend. Turning and acceleration blend are still stylized, not a physics/IK locomotion system.

Accepted skill 1 projects one arm, 2 raises both hands, 3 leans with trailing sleeves/ribbon, 4 spreads the arms. Capture holds a seal between the hands and visually faces the target without writing simulation facing. Damage adds a short torso recoil; death interrupts casts/channel and rotates the same clothed body to the ground. Respawn clears the old action. Spell origins and dash silhouettes use the rig; player damage text is raised above the taller head. Death remains a five-second gameplay state, and the action visuals never delay damage, cooldowns, movement authorization or loot.

Reduced motion removes breathing, gait, cloth drift, recoil and rising ghost motion, retains clear skill poses and shield/channel symbols, and snaps the death pose. Paper dolls do not process, dash afterimage poses and spell origins are sampled once per event, and world idle redraw remains capped at 30 Hz. These bounds are not a measured FPS improvement.

Review: `tests/character_smoke.gd` renders an eight-direction/eight-pose sheet and 72 native frames; `tests/motion_smoke.gd` exercises real local movement, 1/2/3/4 and wolf feedback over 80 frames. Both use the game actor code. Synthetic gallery poses are kept distinct from actual gameplay evidence. Regression checks cover finite/bounded joints across directions/actions, planted feet, reduced motion, visual-only facing, VFX origin, interruption and respawn.

## Keyboard controls — 0.8

W/A/S/D hold movement follows screen up/left/down/right, converted through the isometric inverse projection. The authority normalizes direction, keeps speed at 3 world units/second, sweeps each movement segment and slides along one clear grid axis when blocked. Opposite keys cancel; diagonals do not gain world speed. Keyboard intent clears an old click route; a successful new ground click clears held-key ownership and resumes A* movement. Release stops only manual intent, preserving a route created by a later click. Manual movement emits no repeating destination/VFX markers.

Skill slots use 1–9/0 and the corresponding numpad keys through `GameBindings`, also used by hotbar/socket/inspector labels. Four Gu are currently equipped at 1–4; empty 5–0 slots consume no resources or show fake skills. Former Q/E/R keys do not cast; W moves. Held number repeats do not recast. C/F/F3/F4/F11/Tab/Esc/M retain their actions. Shift+WASD runs; Alt previews dash; F6 opens the character studio.

Opening a gameplay window immediately disarms held movement through a HUD signal. Pause, focus loss, death and profile loading also clear movement; closing/resuming does not reactivate a stale key. Movement cancels capture once. A held direction can resume on the next simulation tick after an accepted skill, so moving and using a Gu work together. Actor cast/dash direction is sampled from the accepted event and retained until pose recovery; the authority can face movement without visually turning the spell away from its target.

Runtime coverage includes actual InputEvent press/release, all screen directions, opposite keys, diagonal speed, mouse/keyboard takeover, top-row/numpad casts, empty keys and repeat handling, modal/pause/focus/death disarming, collision/slide budgets and capture cancellation. The 80-frame native motion harness now drives S and 2/3/1/4 through input rather than issuing movement/cast calls directly.

## Classic PC UI direction — 0.5

Worn bronze frames, dark stone surfaces and warm readable text establish the classic martial-arts PC interface. The playfield remains the main canvas. The upper-left portrait opens the character sheet; red health and blue mana gauges retain actual numerical values while their fills ease. Four Gu skills and XP sit on the bottom belt, with persistent character/inventory/quest/settings controls at the right.

Reference: [VNG's interface guide](https://volam.vnggames.com/cam-nang-chi-tiet/tan-thu/giao-dien-game.html) and [official keyboard shortcuts](https://volam.vnggames.com/cam-nang-chi-tiet/tan-thu/he-thong-phim-tat.html). F3, F4 and F11 are adopted for character, inventory and quest windows; existing Tab/1–4/C controls remain available. Art is created in this project; no screenshots or UI images from the reference game are shipped.

The character sheet shows current HP, mana, shield/duration, level/XP, currency and movement speed. Its paper doll uses the same avatar drawing as the game with processing disabled; four clickable sockets inspect the actual equipped Gu. No unimplemented armor or stat-allocation controls are shown.

Inventory exposes 30 reusable item buttons. Unique Gu occupy one cell, material stacks each contain at most 99. Filters and A–Z sorting affect presentation only, preserve a valid selected key and never mutate the inventory. The selected Gu detail reuses its feed row by instance ID; only that row is visible. New captured Gu appear on inventory version updates; empty filters have an explicit empty state. Material details display both the stack count and total quantity.

The quest journal shows the current three-objective survey, authoritative progress, gameplay instructions and the automatic reward status. Tracking can be hidden/restored without changing progress. The feed shortcut opens inventory. Journal visual updates are gated by a progress/tracking signature.

Character and inventory can coexist at opposite edges. The central journal replaces them. Esc/outside click closes the most recently opened window before pause. Window navigation stays above the backdrop; pause disables those shortcuts. Every open gameplay window suppresses world movement/casts/targeting; simulation still runs. Closing-bag feed guards remain in place. No duplicate reward claim action is introduced.

Frames use fixed 16px nine-slice corners. SVG material icons and shaded resource gauges are reproduced with the same standard-library generator. Belt decoration is static except on resize, item cells redraw on entry/selection change, and the bag keeps its 0.18s slide/fade. Ready pulses and reduced-motion behavior are retained. Opening a window dismisses onboarding; action receipts remain readable above the backdrop.

| Event | Visual | Sound / timing |
|---|---|---|
| Move | WASD body/gait or click ground ring and route dots | Held intent on next fixed simulation step; click marker1s |
| Hover / select | Walkable/blocked ground marker; enemy hover ring/caption; selected brackets and overhead arrow | Selection expansion0.28s; static when reduced motion is enabled |
| Skill inspection | Left-column skill details, isometric range ring, target line and endpoint; amber dashed remainder on a clipped dash | Hover a hotbar skill or hold Alt for dash; no cast or resource change |
| Gait / idle | Distance-driven alternating feet, robe/arm blend, directional face/hair; breathing at rest | Exponential movement blend; stride stops at rest |
| Cast accepted | Arm/orb gesture, crescent/frost projectile, shield envelope, dash afterimages | Pose0.34s; dash eases over0.16s; projectile/trail0.28s |
| Denied / ready | Named cooldown ring/count; hunger, mana and death captions; amber denial border; ready pulse | Low denial tone; immediate error toast; pulse0.35s |
| Wolf windup | Crouch, ground warning ellipse, direction marker; brief lunge on strike | Warning0.65s; strike pose0.2s |
| Hit | Actor flash, small player camera reaction, outlined floating damage in separate victim lanes | Player hit cue; flash0.18s, number1s with late fade |
| Capture | Thread/orbiting seals, progress/text | Start cue, success ring, failure text |
| Reward/level/quest | Toast and burst/ring | Ascending cue; reward once |
| Death/recovery | Ghost, countdown, respawn ring | Descending cue; recovery5s |
| Feed | Receipt-driven toast and hunger change | No repeated progress/toast on replay |

Nine PCM WAV effects are generated once by Python, not synthesized at runtime. Eight AudioStreamPlayers, default -20dB; M mutes/stops voices. Listener evaluation remains pending. Pause stops simulation and the entire world presentation subtree; the menu remains responsive. Opening the inventory does not pause simulation.

UI consumes clicks. Inventory rows are reconciled by Gu instance ID, preserving buttons/selected Gu across inventory version changes. Glyphs, hunger bars and explicit disabled reasons show feeding requirements. The bag slides/fades in0.18s; backdrop clicks close it without moving the player, and delayed feed signals from closing panels are rejected. Rapid toggles cancel the previous tween.

HP/mana bars ease briefly while numerical readouts always show authoritative values. XP follows cumulative level thresholds; shield amount/duration is visible. The target panel explains HP, range, LOS, seals and bag capacity for capture. Receipts queue (max4, duplicate suppression); errors appear immediately. Foreground canopy fades more strongly and over a wider region to preserve actor visibility.

`LocalAuthority.preview_cast` is a pure query shared by inspection and actual casts. Both use identical rounded-up mana cost, denial priority, range/LOS and swept dash endpoint; resource-blocked previews retain geometry for planning. The inspector occupies the left column below the quest, preserving visibility of the player, target and dash endpoint. Previewing never cancels capture or spends resources.

Input keeps the live viewport cursor separate from the last world aim. Over world geometry, cast aim is resolved against the current camera; entering UI freezes the last world cell so clicking the dash button preserves the intended direction. With no prior world aim, dash uses facing. Alt previews while held; F cycles living on-screen enemies within8cells, sorted by distance with a stable ID tie-break. Character, inventory, journal, pause and death suppress inspection overlays. Focus loss clears held-preview/pointer state.

Reduced motion (Esc) disables camera shake, walking bob/swing, dash ghosts, moving ambient motes, radial particles and menu sliding; state glyphs, windup warnings and cooldown information remain. Audio/motion preferences persist separately from gameplay in settings.cfg; test mode skips both preference reads and writes.

Static minimap terrain retains its draw commands, markers refresh at20Hz. Static props do not process; animated props and idle actors redraw at most30Hz. Circle geometry is cached; filled polygons exclude the duplicate endpoint. VFX storage is capped at48 and releases expired entries. These are code-level bounds, not a performance benchmark. Presentation never writes authoritative combat/inventory state.

## Modular character — 0.8

The original skinned3D model has22 bones and11skeletal clips plusRESET; it renders into a transparent orthographic SubViewport. ActorView alone drives world presentation from accepted events/state. Cosmetic body/outfit/hair/weapon IDs pass manager→authority→profile validation; changing appearance never changes inventory or combatstats. Moon uses attack gesture, frost uses cast, shield uses defend, capture uses channel; these are visual gestures, not a new melee damage system. One-shots are rescaled to existing0.34s/.16s event presentationwindows.

A short bone-pose blend smooths world clip changes. Static HUD/F3 and F6 preview disable transitions for deterministic sampled poses; the showroom owns its clock and speed. Portraits render once and stop updates; hidden views disable their renderpass. Run uses a longer cycle than walk. Hair/cape have additional skeletal motion; no cloth physics. Cast/capture handanchors and dashafterimages now use the rendered3D character.

F6 supports8compassdirections pluscontinuousrotation,11 actions and36 cosmetic combinations. In0.9 three outfit choices have different actual garment cuts, sleeves and skirt lengths. Sword/spear/unarmed select complete motion libraries with family-specific idle/walk/run/attack/defend. Spear uses two hands and a baked support-handIK grip; swordslashes and unarmedpunches differ. Ten editableSVG textile/leather/hair/metal maps useUV-derived tangentframes and albedo/normaltextures. Sculpt/retopology/texturepaint/fingerclearance/combos remain in CHARACTER_MODEL_WBS.md. GodotCompatibility nativecaptures verify visible result; test assertions do not certify art final or FPS.

Gameplaycharacter viewport is384px; orthographiccamera size3.6 contains sampledweapon/body envelopes while theadapter preservesdisplayheight andgroundpivot. SixGLB/scene assets andsixBlenderauthoringfiles preserve22bones/12clips andpackedtextures. Runtimegenerator remains the source until anartistasset loader is integrated; changing aBlend filealone does notchange thegame.
