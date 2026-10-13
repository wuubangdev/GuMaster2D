> Cập nhật 0.11: tài liệu này mô tả pipeline 0.10 trước khi chuyển sang pixel 2D. Runtime hiện tại theo [PIXEL_2D_MIGRATION_PLAN.md](PIXEL_2D_MIGRATION_PLAN.md).

# GuMaster2D — WBS nhân vật 3D và animation

Ngày: **08/10/2026**. Phạm vi theo [FSD nhân vật](CHARACTER_MODEL_FSD.md) và [kế hoạch model](CHARACTER_MODEL_PLAN.md). Đây là backlog nhân vật bổ sung, không thay WBS online/economy alpha.

## Công suất và phân vai

Giả định mỗi người 20 giờ/tuần, 75% thời gian tập trung → **15 giờ hữu ích/người/tuần**, 60 giờ cho đội. Các giờ trong bảng là effort còn cần cho một chặng art/engineering có review; không phải số giờ trợ lý đã làm hay một cam kết deadline. Chưa biết kỹ năng dựng 3D/rig/animation thực tế, nên dùng khoảng và đo lại sau tuần 2.

| Vai trò 4 người | Trách nhiệm chính ở chặng nhân vật | Reviewer |
|---|---|---|
| GD/QA | Chốt art brief, FSD, matrix, native playtest, nghiệm thu hình ảnh và bàn giao | CL/AR xác nhận issue tái hiện và gate |
| CL — client/render | SubViewport/world/portrait, input modal, xưởng UI, appearance/save, performance integration | TA cho clip/rig, GD cho hành vi |
| AR — model/wardrobe | Silhouette, body, outfit/hair/weapon, topology/UV/material và asset source | TA kiểm rig, GD kiểm hình gameplay |
| TA — animation/tools | Rig/sockets, clip, weapon grip, import/export, secondary motion và benchmark art | AR kiểm tỉ lệ, CL kiểm API/authority |

Nếu đội hiện phân GD/CL/SV/AR theo plan alpha, người SV có thể phụ trách TA/tools trong chặng này nếu đủ kỹ năng; không đồng thời tính 15 giờ/tuần cho cả server lẫn animation. Thiếu TA thì tăng thời gian hoặc giảm số costume final, không cố giao toàn bộ rig+animation+model cho một AR trong cùng công suất.

## Work packages

| ID | Owner | Việc / đầu ra review được | Giờ hữu ích | Dependency | Acceptance / trace |
|---|---|---|---:|---|---|
| C01 | GD/QA | Art brief, hướng mẫu, silhouette gate, danh sách lỗi model cũ, scope cosmetic/gameplay | 8–12 | Bản local hiện có | Front/side/back + gameplay size; FSD CHR-001…016 được khóa |
| C02 | AR | Body nam/nữ, rest pose và rig contract; source/cấu trúc cho authored mesh về sau | 16–24 | C01; phối hợp TA sớm | Body không chỉ color swap; đơn vị/bone/slot khóa; CHR-001/015 |
| C03 | AR | Hoàn thiện model body/head/hands/boots, topology/skin/UV/material theo mức art được chốt | 24–36 | C02 | Rest pose và extreme poses không seam/xoắn; gate B/F; CHR-001/007/015 |
| C04 | TA | Rig/AnimationPlayer; idle/walk/run/attack/defend/cast/channel/dash/hit/death/respawn | 24–40 | C02; C03 phản hồi | Loop/one-shot và priorities đúng, contact pose rõ; CHR-002…006 |
| C05 | TA | Grip và clip khác nhau cho sword/spear/unarmed; hand/weapon/cloth clearance | 18–28 | C04; C07 bản đầu | Không trôi chuôi, spear tay phụ hợp lý, unarmed không giả cầm kiếm; CHR-004/008 |
| C06 | CL | Renderer orthographic/transparent, ground pivot/y-sort, ActorView event/locomotion, portrait freeze | 24–36 | C02; clip stub từ C04 | Không sửa core damage bằng animation; VFX/socket/pause đúng; CHR-002…006/013/014 |
| C07 | AR | Ba hướng outfit, hai hair, ba weapon và cấu trúc wardrobe modular | 12–20 | C02/C03; feedback C05 | 36 tổ hợp có clearance; nguồn/license/IDs ổn định; CHR-007/008 |
| C08 | CL | Xưởng F6, hướng/action preview, lựa chọn/apply/cancel, modal input gate/responsive | 12–18 | C06; appearance contract | Preview lớn; Esc/window stack; không input xuyên; CHR-009…011 |
| C09 | CL | Appearance cosmetic authority, save schema1 tương thích, sync world/F3/F4 | 10–16 | C08; C07 IDs | Invalid/old/new/bak tests; HP/inventory/progress giữ nguyên; CHR-010/012 |
| C10 | TA | Native animation review, viewport/material budget, benchmark và art optimization | 14–24 | C04/C05/C06/C07 | Ghi số đo thật, sửa crop/clipping/gait; CHR-013/014/016 |
| C11 | GD/QA | Matrix 8 góc/11 nhóm action/36 appearance, Windows/Linux, input/save/native evidence | 16–24 | C06/C08/C09; C10 phối hợp | Blocker về 0; art issues ghi rõ; không dùng Passed logic thay art review; CHR-016 |
| C12 | GD/QA | Asset handoff, source/GLB round-trip phối hợp TA, docs, known issues, demo/re-estimate | 8–12 | C10/C11 | Build hash + source + native evidence + backlog production; CHR-015/016 |

**Tổng base: 186–290 giờ. Dự phòng 25%: 46,5–72,5 giờ. Tổng forecast: 232,5–362,5 giờ.** AR 52–80h; TA 56–92h; CL 46–70h; GD/QA 32–48h, chưa cộng dự phòng. Critical path là art contract → rig/clip → wardrobe/weapon contact → native polish; không chia tổng giờ cho 4 rồi bỏ qua tải TA.

Theo 15 giờ hữu ích/người/tuần, tải TA gồm dự phòng là 70–115h → khoảng 4,7–7,7 tuần; tính cả dependency/review, dự báo **6–8 tuần** cho chặng hoàn thiện này. Bản prototype tích hợp có thể chạy sớm hơn, nhưng chạy được chưa phải final art/weapon-specific acceptance.

## Lịch đề xuất và gate

| Tuần | AR | TA | CL | GD/QA | Gate cuối tuần |
|---|---|---|---|---|---|
| 1 | Body rest pose, silhouette và modular slots | Rig/socket contract, idle/walk stub | Renderer/world pivot bằng model stub | Brief + test matrix + camera art review | A: model quay 8 góc trong map; tên bone/sockets khóa |
| 2 | Body/head/hands và outfit jade | Walk/run/cast/defend, events/timing | ActorView integration, portrait freeze, xưởng bản đầu | Playtest WASD/1–4/capture và update estimate | D sơ bộ: loop chơi không hỏng; quyết định giữ hay sửa silhouette |
| 3 | Outfit/hair/weapon bản đầu | Attack/dash/hit/death/respawn | Apply/cancel, appearance save/backward compatibility | Native clip contact + save/input cases | C sơ bộ: đủ action có pose đọc rõ, save cũ load được |
| 4 | Topology/weights/UV/material sửa theo stress poses | Sword/spear/unarmed grip/clip variants | Camera crop/modal resize; performance instrumentation | 36 tổ hợp và 8 hướng, tổng hợp lỗi | B/C: không lỗi silhouette/clipping lớn; mọi weapon cầm đúng |
| 5 | Wardrobe polish, asset cleanup/source | Secondary motion có giới hạn, gait và frame-time tuning | Update/render budget, UI polish/quality settings | Regression và máy Windows thứ hai nếu có | E đo được: log/test sạch, viewport/material/frame-time ghi thật |
| 6 | Fix art blocker, asset source hoàn chỉnh | GLB/import round-trip, clip cleanup | Fix integration blocker, build handoff | Demo, nghiệm thu A–F theo phạm vi, known issues | Bản bàn giao hoặc backlog tuần7–8 rõ owner/giờ |
| 7–8 nếu cần | Sửa sculpt/skin/clipping chưa đạt | Weapon-specific/recovery và tối ưu chưa đạt | Máy yếu/Web spike chỉ khi PC đã ổn | Retest phần sửa, benchmark lại có lý do | Hoàn thành gate production art được chốt |

Pipeline cần ghép hằng tuần. AR không chờ mọi clip hoàn tất mới gửi model; TA không chờ UV final mới làm kinematics; CL dùng contract/stub để xây viewport/xưởng. Sau tuần 2, cập nhật effort dựa trên số lỗi và clip/asset thực sự đã qua review.

## Phạm vi đợt implementation hiện tại

Đợt đang làm xây model/rig/render/clip/xưởng và cosmetic save trong prototype hiện có để tạo kết quả kiểm được ngay. Các work package C02/C04/C06/C08/C09 có phần đã bắt đầu; trạng thái Passed chỉ điền sau evidence thực tế. Model/texture artist hoàn chỉnh, combo cận chiến và benchmark nhiều người tiếp tục là backlog. Bản 0.9 đã có clip riêng theo vũ khí, grip thương hai tay và nguồn Blender; chưa nghiệm thu toàn bộ clearance artist.

Không chuyển C03/C05 hay gate F sang “xong” chỉ vì hiện đã chọn được nam/nữ/kiếm/giáo trong dropdown. Không chuyển WBS server/persistence/online alpha sang “xong” bằng save local hay một hero 3D.

## Quy tắc cắt phạm vi khi thiếu công suất

1. Giữ một body/outfit/weapon đạt chất lượng hình ảnh trước, giữ rig/appearance API để thêm bộ khác; giảm số asset final nhưng không bỏ ground pivot, modal input hay save compatibility.
2. Ưu tiên idle/walk/run/cast/defend/death/respawn chơi thật trước animation combo dài; các clip showroom chưa nối gameplay được ghi rõ.
3. Secondary motion dùng bone/clip trước cloth physics; không kéo thêm shader/render pipeline mới trước benchmark Compatibility.
4. Web/mobile và battle nhiều hero chỉ sau gate PC; có thể bake sprite/atlas từ cùng rig nếu SubViewport cost quá cao.
5. Chốt một reviewer art và một reviewer code cho mỗi handoff; không tự chứng nhận cả source và art bằng số test assertions.

## Cập nhật đợt 0.9

| Package | Implementation hiện có | Việc còn lại để nghiệm thu production |
|---|---|---|
| C01/C02 | Plan/FSD/WBS; hai body, rig 22 bone; nguồn GLB/scene/Blender | Artist khóa anatomy/rest pose theo target cuối |
| C03 | Mặt/cằm/mí mắt/vai/sleeve và robe cải thiện; UV/tangent; 10 map vải/da/tóc/kim loại | Sculpt/retopology, texture paint/bake, kiểm skin/artifact cận cảnh |
| C04/C05 | 11 action + RESET; ba thư viện weapon; idle/walk/run/attack/defend riêng; tay phụ thương sai số FK max 2 mm | Artist chỉnh curve, fingers/socket clearance, combo riêng nếu thêm melee |
| C06/C08/C09 | Renderer/world/portrait/xưởng/apply/save/input, viewport 384 px và camera đủ vũ khí | Loader asset chỉnh tay và kiểm budget máy yếu |
| C07 | Ba outfit khác geometry, hai hair, ba weapon; 36 tổ hợp | Artist stress-test clearance và cleanup từng costume |
| C10/C11 | 1.584 view envelope; Windows/Linux regression, native gameplay/studio/weapon capture | Benchmark frame-time, multihero, playtest người mới và Web sau PC |
| C12 | Sáu GLB/scene và sáu Blender nguồn; manifest/hash và source package | Handoff artist final, release/export nền tảng và retest phần sửa |

Đã hoàn thành các đầu ra prototype nêu trên theo evidence trong [báo cáo kiểm chứng](../game-studio/quality-report.md); chưa chuyển gate F Production hay WBS online thành Passed. Tổng forecast 232,5–362,5h là ước lượng ở thời điểm lập kế hoạch, không phải effort còn lại sau 0.9; GD/QA cần re-estimate sau review source/asset cùng AR và TA.


## Cập nhật đợt đồ họa 0.10

| Package | Đầu ra tích hợp | Gate còn lại cho art final |
|---|---|---|
| C03/C07 | Mặt continuous contour/mí/iris, tóc nhiều curved lock, shoulder gusset, nếp và split-hem weights, 11 map SVG | Sculpt có phong cách, fingers, UV paint và kiểm giao áo/tóc ở extreme pose |
| C06/C12 | 36 runtime resource; loader kiểm rig/revision; mẫu Blender → GLB thay mesh chơi thật; 6 nguồn Blender mở lại được | Artist authoring nhiều biến thể và resource budget sau đo máy đích |
| Environment | 2 PNG atlas, cây/đá/di tích vẽ chi tiết, nền continuous blend, mipmaps/cache, rừng nền ngoài navigation, sói vector có chân khớp | Thêm asset biến thể, polish interaction props và creature art theo cùng phong cách |
| C10/C11 | Regression Windows/Linux và native gameplay/studio/weapon evidence từ bản mới | Benchmark FPS/frame-time, Windows thứ hai và playtest người mới |

Trạng thái này phản ánh đầu ra hiện có, không chuyển toàn bộ production art thành Passed. Loader artist đã hoàn thành trong scope hiện tại; không còn là công việc tương lai của C06/C12. Số kiểm và source hash cuối được cập nhật trong quality report.
