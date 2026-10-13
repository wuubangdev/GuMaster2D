# System architecture

`scenes/main.tscn` owns GameManager (Node2D), which creates one LocalAuthority, WorldView, GameHUD, SoundLayer and GameInputController. No singleton owns mutable gameplay state.

| Owner | Responsibility |
|---|---|
| LocalAuthority / RefCounted | 20Hz local state, command validation, AI/combat/capture/progression; event records |
| InventoryModel / RefCounted | Unique Gu, stack capacity, feed version/receipt, pending rewards |
| WorldGrid / RefCounted | Navigation, solidity, safe zone, sweep, world↔square-pixel projection |
| GuCatalog | Versioned data-driven definitions |
| SaveStore | JSON profile validation/read/write/backup; no UI |
| GameManager | Lifecycle, fixed-step accumulator, pause, events, save cadence |
| GameInputController | Physical PC keys and unhandled pointer input → commands |
| WorldView / ActorView / PropView | Read-only projection, y-sort, camera, smoothing and canopy fading |
| WorldEffects / SoundLayer | Transient feedback; never grant rewards |
| GameHUD | View state and UI intents; Controls consume pointer input |

Coordinates are continuous logical tiles; navigation rounds to cell centers. Camera/pixels are presentation only. Player dictionary is shared by reference with its actor view; loading merges into it. Inventory replacement happens before view initialization. Save only primitive arrays/maps, never Node/Resource/Vector2 objects.

Restart restores position, XP, currency, inventory/receipts, pending materials and teaching progress; resets HP/mana, cooldown and encounters. Tmp + previous bak provides local recovery, with semantic validation before choosing main/backup. It cannot guarantee DB atomicity or resist edited saves.

Network migration: CommandGateway, explicit snapshots/events, character/session/sequence/config IDs, separate headless process. Server owns RNG/assets; persistence adapter commits inventory/ledger/receipt before ACK. Local profile loading is not authentication. Transport/driver spikes precede server production.

Growth points: split script-built HUD into editor scenes, typed actor state for remote entities, content schema validator, and persistent operations separate from tick state. See ../implementation/GODOT_IMPLEMENTATION_PLAN.md.

## Illustrated character and appearance 0.13

GuCharacterAppearance stores only four cosmetic IDs; schema and authoritative stats are unchanged. ActorView, HUD/F3 dolls and F6 use GuIllustratedCharacterView, a compatible subtype of the retained GuPixelCharacterView. The legacy atlas sprite stays hidden and provides historical tooling snapshots; the visible GuIllustratedCharacterCanvas renders original SVG parts through GuIllustratedCharacterArt.

SVG head, coat, hair, sleeves, boots, hands and weapons have eight compass views and shared immutable resource caches. Sources import at eight texels per design unit with linear filtering; Canvas curves request antialiased strokes; SVG edge coverage comes from the high-resolution import. A deterministic joint sampler owns breathing, blinking, foot lifts, bent arms, charge/release/overshoot/recovery and secondary hair motion. Neither sampler nor draw changes the character root or authority. hand_position reads the exact continuously posed model hand after internal scale. capture_pose deep-copies the accepted appearance and joint coordinates for dash ghosts. F6 uses a fixed safe scale and common ground anchor for all attack directions, including a downward spear at 960x640.

GroundView keeps a 32px TileMapLayer; props and wolves retain their original pixel atlas. Camera uses integer zoom and display-pixel registration; illustrated character motion itself remains continuous. Legacy3D classes are absent from the live scene.

## Vector effects and compact UI

GuVectorEffectsArt draws thirteen original cue families with antialiased curves and float canvas coordinates. GuPixelEffectsArt keeps its legacy atlas inspection API but delegates live drawing to the vector library. WorldEffects owns bounded lifetimes, launch-hand snapshots and fixed contact points; it never changes HP, mana, rewards or collision. Visual contact at0.28s can delay the victim flash/fall while authoritative damage and rewards stay immediate. Reduced motion uses stable spell silhouettes and suppresses flight, ghosts and shake.

GameHUD uses shared curved icon/frame recipes and GuLacquerPanel; GuVitalBar shows a brief lost-health edge over the true value. The352x104 action dock leaves free lower corners for map input. Selected item/feed controls sit above the inventory grid. Save compatibility, input mappings and gameplay navigation are preserved.


## Continuous playback 0.14

GuIllustratedCharacterArt retains pure deterministic pose sampling. Its gait_foot stance is linear in travelled phase, with velocity-matched Hermite return and zero-velocity lift contacts. Feet have ground projections/contact weights; articulated pants/boots draw before the coat.

GuIllustratedCharacterView owns render-only blend and damped angular spring history. present(...) is deterministic sampling/seek and clears that history. present_smooth(...) blends from the displayed pose on clip/facing/replay interruption; delta0 retains the actual hands and spring angles while accepted action metadata changes immediately. The analytical springs affect hair/head/weapon angles, never the grip endpoints or authority. Reduced motion bypasses blend/spring and holds planted loop poses. Cosmetic swaps reset history to the selected look.

ActorView._sync_character(delta) passes actual travelled gait, speed weight and movement facing separately from upper-body cast facing. Ordinary moving casts continue lower-body locomotion; dash uses its accepted interpolation. hand_position/capture_pose expose the pose that draw actually consumes, so projectile launch and deep-copied afterimages remain exact. F6 button changes start the same blend at delta0; playback advances it and pause holds the exact rendered pose. Camera still uses integer zoom, but registration is now (follow*zoom).round()/zoom to advance in display pixels.


## Side profile presentation 0.15

The shared character generator now authors profile skull/fringe/eye/ear/nose/mouth and twenty complete closed-eye heads. Blink selects an authored layer; it never paints a generic skin mask over hair. Tail placement moves behind the profile head. Directional hip/foot anchors narrow the side stance; leg_joints builds finite flexing knees from displayed hips and boots, and ground projections order the legs. Travel-driven walk/run strides are32/44px; upper-body cast authority and exact hand anchors remain unchanged. Moving casts blend hips/leg-forward along with the lower-body foot fields.

Dash retains deep-copied pose capture but displays two low-alpha echoes on the travelled segment and one small feather; wake and dust use restrained geometry. A focused native180-frame side review complements full gameplay/F6 capture. Tests allow the async audio mixer to retire stopped fixture playback before process shutdown.


## Existing-character material refinement 0.16

The0.15 generator, anatomy, compass silhouettes and joint sampler are retained. material_finish adds original SVG gradient paints for skin/hair/iris/fabric/leather/metal/bronze and fold accents inside existing coat/sleeve silhouettes. The library retains131 part IDs, rects and8texels-per-unit. There is no replacement anatomy or new model.

A fixture records imported alpha/dimensions/RGBA of the restored0.15 assets before refinement. Acceptance compares alpha/dimensions exactly to protect silhouette and compares RGBA to prove actual color changes. Existing pose anchors, paused/reduced playback, exact spell hands and afterimage contracts still apply.

GuCultivationPalette caches a shared immutable ShaderMaterial on terrain/props/wolves; characters and HUD retain their authored colors. Canvas fragment COLOR already includes texture/modulation, applied once. Foreground fading observes the existing head(-43), torso(-21) and boot anchors. Tile selection, navigation and water clocks are preserved.


## Directional arms and limb surfaces 0.17

GuIllustratedCharacterArt projects anatomical shoulder/wrist spans into each facing and carries arm_bend_L/R as pose floats. connect_arms reconstructs the elbows from the blended endpoints and the blended facing projection, so interruption does not restore a fixed L/R screen-space bend. Walk/run counter-swing derives from each foot travel, including the different run stance.

Depth order observes facing-projected shoulder depth stored in the pose; screen-y body sway does not change layering. held-arm drawing groups sleeve, tapered forearm, rotated wrist, weapon and grip. Curved limb ribbons use explicit quads, gradient vertex colors and thin antialiased outlines. Folded knees cannot abort polygon triangulation. Original SVG IDs/silhouettes and all authoritative state remain unchanged. The view still exposes the exact rendered wrist center and deep-copied pose to effects; moving casts retain independent lower-body gait.

Directional native evidence adds 240 frames spanning every facing at large and gameplay scale; regression includes nine new directional/geometry acceptance checks.

Góc vũ khí nghỉ chiếu theo phía bàn tay cầm; tip kiếm nằm ngoài đầu ở cả tám hướng, tránh bị che hết khi quay lưng.


## Nhân vật 0.18 — giải phẫu và vải

GuIllustratedCharacterArt giải gối với LEG_SEGMENT, WALK/RUN_STRIDE và WALK/RUN_LIFT; actor tích lũy pha từ cùng stride để stance không trượt. coat_vertex biến dạng cục bộ dưới đai, _coat vẽ 32 cell convex với UV của SVG gốc. Các tham số cloth_* là dữ liệu pose, được blend và chuyển theo lower-body gait khi moving cast. Snapshot/hand origin/save authority không đổi. Generator chỉ thay paint/detail trong alpha gốc; golden fixture 0.15 vẫn là guard nhận diện.


## Nét mực 0.19

GuIllustratedCharacterArt dùng chung ShaderMaterial bất biến từ ink_cutout.gdshader cho các canvas nhân vật. Shader lấy COLOR đã nhân texture/modulation, giữ alpha và chỉ đổi màu viền/grain trong texture; không có TIME/RNG. SVG generator phân bóng thành mảng và thêm nét gạch trong silhouette gốc. GuVectorEffectsArt tạo ribbon pressure từ đường đã tác giả hóa, mép alpha liên tục; world effects dùng palette này mà không áp shader nhân vật lên text sát thương. Animation biểu cảm/lấy đà vẫn là sampler thuần; không thêm state gameplay. Atlas môi trường chỉ grade màu/mép trong.

## Character modular cloth 0.37

`author_concept_character_masks.py` delegates per-view SVG cloth authoring and atlas registration to `author_concept_modular_parts.py`. `build_concept_mattes.gd` isolates full sleeve stitches and restricts body pigment to its independent clean silhouette. Source-pixel contours bind visible sleeve meshes; independent SVG cloth completes concealed regions. `GuConceptClothGuides` supplies five deform controls with anchored shoulder/elbow endpoints; anatomical IK and rigid wrist/palm remain in `GuConceptCharacterRig`. Shader UV page 8 selects one explicit cloth atlas sampler, keeping source parts on their existing samplers. All paths share the presentation renderer and do not own gameplay or save data. [Contract, assets and rollback](concept-character-modular-cloth-0.37.md).

## Cổ giới / bí cảnh 0.38
`ExpeditionModel` giữ version/trạng thái vùng, 6 cây và 2 vật nuôi; `CultivationActions` kiểm tra toàn bộ điều kiện trước giao dịch. `LocalAuthority` sở hữu việc đổi WorldGrid và lưu quần thể từng vùng trong phiên. Các lệnh phát sự kiện có `persistent=true`, GameManager lưu ngay qua SaveStore. Thu hoạch đầy túi dùng pending_materials có sẵn; validator nay nhận toàn bộ loại vật liệu Cổ giới.

`CultivationBook` là view thuần với ba trang T/G/H; emits command, không sửa inventory/player. Cùng window stack/backdrop của GameHUD; mở sổ dừng đường click, giữ thời gian mô phỏng. `CultivationWorld` vẽ cổng/đất/cây/chuồng theo state bằng geometry vector. WorldView thay ground/prop/actor của vùng, xoá targets và VFX cũ, giữ instance player/camera. Minimap nhận region mới để redraw. Bậc/mức Cổ ảnh hưởng công thức cast ở authority; VFX chỉ nhận metadata rank và không gây sát thương.

Chi tiết yêu cầu, công thức, WBS, tương thích và giới hạn: [expansion-0.38.md](expansion-0.38.md).


## NPC và nhiệm vụ 0.39

`QuestCatalog` đọc nội dung NPC/quest từ JSON. `QuestJournal` giữ accepted/claimed/counters/tracked, xác thực trước khi load, truy vấn trạng thái từ tiến độ hiện có. `LocalAuthority` sở hữu lệnh talk/accept/claim/track, kiểm NPC/cự ly/LOS/sống/giao chiến; đánh dấu claim trước khi phát thưởng qua inventory/pending. Metadata `cultivated_gu` phân biệt nâng Cổ thật với đổi trứng. Field `quests` tùy chọn trong profile giữ tương thích hồ sơ cũ.

`NpcDialogue` và `NpcQuestList` chỉ hiển thị/truyền lệnh. `GameManager` nối UI và authority, đóng hội thoại khi mất điều kiện, dừng route và chặn input khi mở. `interaction_npc()` dùng chung cho E và lời nhắc. `NpcView` dùng renderer/rig hiện hành với appearance từ catalog; animation không sửa mô phỏng. `StoryLandmark`/`EnvironmentDetails` chỉ vẽ, footprint do `WorldGrid` giữ. `WorldView.rebuild_region()` giải phóng actor/trang trí vùng cũ trước khi dựng vùng mới.


## Ba đại vực 0.40

`data/world_content.json`, `bestiary.json`, `quest_catalog.json` tác giả hóa đường/bãi/tài nguyên, tám loài và 18 nhiệm vụ. `WorldContent` là nguồn chung cho map, navigation và UI; `WorldGrid` tạo 96×96 ô với blueprint tĩnh theo vùng rồi sao chép collision riêng cho từng authority. Bãi/đường/điểm tương tác được giữ thông trước khi đặt cây, trúc, cột vỡ và nước có va chạm. World size hữu hạn, không dùng streaming.

`Bestiary` tạo quần thể theo bãi. `WildlifeAI` giữ state tại authority: nghỉ, đi, đuổi, lấy đà, quay về, chết/hồi sinh. Aim được khóa khi lấy đà; melee dùng sector ±0,9 radian, charge corridor 0,72 ô, spit vòng 1,05 ô. LOS, va chạm và safe zone dùng chung WorldGrid. Quái xa ở điểm nhà không tìm đường; A* của chase có thời gian chờ. WorldView tắt process của actor xa, bật lại tại vị trí authority. `BeastArt`/`OverlandView` chỉ đọc state để vẽ; sinh vật có sáu cấu trúc hình thể và hai đầu lĩnh, không thay renderer nhân vật concept.

`JourneyModel` lưu khám phá/cooldown gather/dược phương; field journey tùy chọn giữ tương thích save 0.39. `JourneyActions` kiểm sống, giao chiến, vị trí, unlock và chi phí trước khi thực thi gather/waygate/medicine/irrigate. Unlock suy ra từ quest claimed. `QuestJournal` thêm mục tiêu khám phá, đúng bãi và giao vật liệu; giao đồ/claim là một transaction. Journey cooldown theo thời gian chơi; quần thể vùng giữ trong phiên và tạo lại khi load profile như baseline 0.38.

`RegionalAtlas` và radar nhìn cùng dữ liệu vùng. CultivationBook tách bản đồ trong vùng và tuyến sang vùng khác, cùng stack T/G/H; lựa chọn bãi hiển thị loot, thời gian hồi và đường tới. Journal chính/phụ chuyển điểm dẫn tới bãi khi còn thiếu mục tiêu và tới NPC khi đủ. Bộ kiểm `world_expansion_tests.gd` + `world40_visual_smoke.gd` đối chiếu authority với input/render native. [Yêu cầu, nguồn cốt truyện và nghiệm thu](world-expansion-0.40.md).


## Directional limb kit 0.41

`GuConceptDirectionalParts` replaces visible source-cutout arms/legs when `view.directional_art` exists. Its 352 SVG assets have per-body/view/side bone-local anchors; placement is a rigid `Transform2D`. Shoulder yokes follow torso rotation and measure their medial overlap from the actual coat silhouette. Forearm cuffs follow the elbow; palm grip equals the rig/weapon grip. Source head/coat ornament and existing motion/IK remain. UV page 9 samples a separate, guttered atlas; old cloth/source paths remain available for legacy review and fallback. Source ownership tests still cover torso separation; new tests exercise the live replacement pieces. [Asset contracts and reproduction](concept-directional-parts-0.41.md).
