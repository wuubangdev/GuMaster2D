> Cập nhật 0.11: tài liệu này mô tả pipeline 0.10 trước khi chuyển sang pixel 2D. Runtime hiện tại theo [PIXEL_2D_MIGRATION_PLAN.md](PIXEL_2D_MIGRATION_PLAN.md).

# GuMaster2D — FSD model nhân vật

Phiên bản 0.2, **08/10/2026**. Đặc tả chức năng cho đợt nhân vật 3D trong world 2D; tham chiếu [kế hoạch](CHARACTER_MODEL_PLAN.md) và [WBS](CHARACTER_MODEL_WBS.md). Dùng cấu trúc function/input/output/validation/acceptance/trace của FSD dự án. Chưa đánh dấu Passed cho yêu cầu chưa có evidence.

## Dữ liệu và tiền điều kiện chung

Appearance chứa ID: `body: male|female`, `outfit: jade|crimson|ivory`, `hair: topknot|ponytail`, `weapon: sword|spear|unarmed`. Đây là hợp đồng nội dung mục tiêu; tên trường cụ thể của code phải được ghi cùng asset/schema khi bàn giao. Không lưu màu/material/NodePath do UI tự đưa vào profile.

Game vẫn chơi đơn local. Người chơi có state từ LocalAuthority; hướng/cell world không đổi hệ tọa độ. Giới tính và wardrobe cosmetic không làm đổi HP, mana, cooldown, damage, quest, inventory hoặc phần thưởng. Online create-character CL-002 không được nghiệm thu bằng xưởng offline này.

| ID | Chức năng / phân cấp | Input → Output | Validation / ngoại lệ | Acceptance Criteria | WBS / test |
|---|---|---|---|---|---|
| CHR-001 | Nhân vật → Model → Rig chung | Body ID + rig → model với rest pose/socket | Bone trùng, thiếu parent hoặc transform không finite: asset không được xuất bản | Nam/nữ cùng hierarchy; chân, đầu và tay đúng silhouette ở 8 góc; không seam hở tại rest pose | C02/C03; ART-01, RIG-01 |
| CHR-002 | Nhân vật → Hướng nhìn → Facing | Hướng world/event → hướng render 3D | Hướng zero giữ hướng cuối hợp lệ; zero không làm NaN | 8 hướng chuẩn đúng screen-space; xoay liên tục không đảo hoặc giật 180°; hướng cast giữ theo accepted target trong recovery | C04/C06; DIR-01/02 |
| CHR-003 | Di chuyển → Idle / walk / run | Quãng đường render + running state → clip và cadence | Không đi thì không tăng gait; diagonal không tự nhanh hơn | Idle ổn định; walk/run có pose khác; chân không trượt rõ ở tốc độ thực; thả WASD dừng; click vẫn đi đúng path | C04/C06; LOC-01/02 |
| CHR-004 | Chiến đấu → Attack / defend | Accepted action hoặc showroom action → clip one-shot | Action preview không damage; clip loop sai bị review | Attack có anticipation/contact/recovery; defend hạ trọng tâm; socket và tay cầm vũ khí đi cùng pose; không lùi frame đột ngột | C04/C05; ACT-01, ART-02 |
| CHR-005 | Cổ → Cast / channel / dash | Event Cổ/capture + hướng → pose, VFX anchor | Cancel/death dừng channel; denied không giả cast thành công | Các Cổ 1–4 có pose phù hợp; channel nhìn đúng mục tiêu; dash kết thúc đúng endpoint; FX tay theo model mới | C04/C06; ACT-02/03 |
| CHR-006 | Sinh tử → Hit / death / respawn | Hit/dead/respawn state → pose ưu tiên | Dead không bị hit/cast ghi đè; respawn reset action cũ | Death one-shot giữ pose cuối; respawn tại cell authority và trở về idle; không restore held input | C04/C06; LIFE-01/02 |
| CHR-007 | Ngoại hình → Giới tính / tóc / áo | Draft appearance → preview đồng bộ | ID ngoài danh mục từ chối hoặc normalize theo policy; không dùng path tùy ý | Hai silhouette body và hai kiểu tóc nhận biết; ba outfit thay riêng; đủ 36 tổ hợp không mất body/material/attachment | C03/C07/C08; APP-01/02 |
| CHR-008 | Ngoại hình → Vũ khí / socket | Weapon ID → mesh + grip offset + stance | Unarmed bỏ weapon; spear/sword không cùng grip nếu hình học khác | Weapon giữ đúng chuôi; không trôi ngoài tay ở attack/defend; full length trong frame; thay weapon không cấp damage/stat | C05/C07; WPN-01/02 |
| CHR-009 | UI → Xưởng F6 | F6/nút bảng nhân vật → cửa sổ preview | Mở xưởng khi pause/modal phải theo window policy; phím lặp không mở/đóng liên tục | Chọn body/outfit/hair/weapon/action/direction rõ; preview đủ lớn; Esc đóng top window; không click xuyên tới map | C08; UI-01/02 |
| CHR-010 | UI → Áp dụng / hủy ngoại hình | Apply / close → appearance game / giữ bản cũ | Apply qua manager/authority; không sửa player từ Control | Apply đồng bộ world/F3/F4; hủy giữ appearance cũ; không đổi HP/mana/position/progress/inventory | C08/C09; APP-03 |
| CHR-011 | Input → Modal / focus / pause | Mở/đóng/focus lost → clear held input | Không dựa riêng Input.is_key_pressed để tự rearm | Mở F6 dừng WASD ngay, chặn 1–4/C; đóng không chạy tiếp bằng phím cũ; pause/focus/death không giữ sprint/preview | C06/C08; UI-03, LOC-03 |
| CHR-012 | Lưu → Appearance tương thích | Schema1 cũ/mới → profile load hợp lệ | Không có appearance dùng default; sai semantic không mutate nửa state | Save/load round-trip appearance; cũ vẫn load; malformed field không crash; main lỗi fallback bak; test-mode không ghi profile thật | C09; SAVE-01/02/03 |
| CHR-013 | Render → Isometric / chân / occlusion | Cell + orthographic viewport → Sprite2D texture | Alpha/lighting/bounds phải đọc trên nền tối và sáng | Chân trùng ground pivot; không nổi; đi trước/sau props đúng y-sort; head/weapon không crop; HUD portrait cùng ngoại hình | C06/C10; RND-01/02 |
| CHR-014 | Render → Freeze / reduced motion | Portrait visibility + setting → budget có giới hạn | Viewport ẩn không update; gameplay feedback quan trọng vẫn rõ | Đóng xưởng dừng render preview; portrait đứng yên cập nhật khi appearance thay; pause dừng world animation; reduced motion không lắc camera/ghost excessive | C06/C10; RND-03/04 |
| CHR-015 | Art pipeline → Import / export / thay model | Rig contract + source mesh → Godot asset | Skin weights/rest pose/unit mismatch phải báo | GLB/authored asset về sau dùng cùng state/appearance API; round-trip giữ skeleton, material, socket; không sửa LocalAuthority để đổi mesh | C02/C03/C12; PIPE-01 |
| CHR-016 | Quality → Native evidence và performance | Build/runtime → log, capture, số đo | Headless Passed không thay được native art review | Windows/Linux import/tests sạch; native 8 góc/11 nhóm action; FPS/frame-time chỉ báo sau đo; lỗi art/giới hạn ghi riêng | C10/C11/C12; QA-01/02 |

## Animation contract

11 nhóm bắt buộc: **idle, walk, run, attack, defend, cast, channel, dash, hit, death, respawn**. Idle/walk/run/channel dùng loop phù hợp; attack/cast/dash/hit/death/respawn dùng one-shot hoặc hold theo state, defend có entry/hold/recovery rõ. Tên clip nội bộ có thể khác nhóm hiển thị nhưng phải có mapping được test.

Selector ưu tiên: death → respawn → accepted dash/action → channel → hit có giới hạn → locomotion → idle. Facing cho cast/dash lấy từ accepted event, không bị con trỏ di chuyển sau lệnh làm xoay lại. Clip không được có method track gây damage, cấp vật phẩm hoặc sửa cell. Các key skeleton trong clip phải trỏ bone/property đang tồn tại.

Đổi appearance giữa clip không được reset cell hay tạo quyền đánh lại; animation phase có thể giữ hoặc về rest pose theo policy presentation. Chính sách chọn phải giữ model ở pose hợp lệ và được kiểm ở attack peak/death.

## Test matrix và evidence tối thiểu

| Test ID | Kịch bản | Loại kiểm | Dữ liệu / evidence |
|---|---|---|---|
| ART-01 | Default model nhìn 8 góc + body nam/nữ | Native art review | Contact sheet, ảnh gameplay và preview lớn |
| ART-02 | Freeze attack contact, defend và run passing | Native art review | Tay, chuôi, ngực, đầu gối không gập sai; ghi clipping |
| RIG-01 | Hierarchy, rest pose, tracks và socket | Headless + native | Bone parent/name unique; transform finite; đầy đủ joints |
| DIR-01/02 | WASD 4 hướng/chéo; cast rồi đổi cursor | Input/runtime | World direction đúng; facing action không đổi trong recovery |
| LOC-01/02/03 | Walk/run/stop; opposing keys; UI/focus/death | Scenario | Tốc độ authority đúng; chân cadence; không drift/rearm |
| ACT-01/02/03 | Attack showroom; 4 Cổ; capture cancel và dash | Scenario + capture | Không side effect từ showroom; VFX xuất đúng model; endpoint đúng |
| LIFE-01/02 | Death giữa cast/channel; respawn | Scenario | One-shot/hold; không old action; state và cell đúng |
| APP-01/02/03 | 36 tổ hợp; apply/hủy khi preview pose | Data + native | Mesh/attachment đầy đủ; world/portrait đồng bộ; gameplay invariant |
| WPN-01/02 | Sword/spear/unarmed ở 8 hướng, attack/defend/death | Native review | Grip/camera bounds/clipping; unarmed không giữ mesh cũ |
| UI-01/02/03 | F6, Esc, click controls, resize, giữ WASD rồi mở | Native input + UI assertions | 960×640 / 1280×800 / 1920×1080; không click/skill xuyên |
| SAVE-01/02/03 | Old schema1, new round-trip, malformed main/bak | Headless local storage | Dùng đường dẫn test riêng; state không mutate khi invalid |
| RND-01/02/03/04 | Props/camera; hidden preview; pause/reduced motion | Native + resource lifecycle | Capture trước/sau props; viewport updates ngừng khi ẩn |
| PIPE-01 | Export/import source rig và asset | Tools / import | Skeleton/rest/socket/material đúng, log sạch |
| QA-01/02 | Native full smoke; Windows/Linux checks; perf run | Runtime / measured benchmark | Build/source hash, GPU/renderer, counts, frame-time nếu đã đo |

Các testcase mới chỉ kiểm phạm vi nhân vật local; không cập nhật 79 testcase alpha/online thành Passed. Nghiệm thu production cần reviewer khác kiểm model/weights/texture và animation vũ khí riêng theo gate F của kế hoạch.

## Mapping implementation 0.9

CHR-007 có ba thiết kế wardrobe khác geometry, hai body/hair và 36 tổ hợp. CHR-004/008 có ba motion family với idle/walk/run/attack/defend riêng, IK tay phụ thương và GuWeaponRig socket; chưa có melee command/damage mới. CHR-013 camera size 3.6 kiểm 1.584 view, gameplay viewport 384 px giữ pivot. CHR-015 có sáu GLB/tscn và sáu Blender nguồn packed texture, kiểm bone/clip/material/UV/weight/hash và reopen; runtime vẫn dùng generator nên loader cho asset chỉnh tay chưa triển khai. CHR-016 chưa có benchmark đa hero/Web hoặc final artist review. Số assertion và native evidence hiện hành nằm trong [quality report](../game-studio/quality-report.md), [acceptance](CHARACTER_POLISH_ACCEPTANCE.md) và [pipeline](CHARACTER_ART_PIPELINE.md).


## Mapping implementation 0.10

CHR-007/015: game và portrait nạp 36 resource `GuCharacterMeshAsset` dưới `assets/characters/runtime/`, mesh dùng chung bất biến giữa các view, rig/clip vẫn do `GuCharacterModel` sở hữu. Resource kiểm revision, appearance, bone name/global rest, geometry/UV/weights. Generator chỉ phục vụ authoring và fallback. CLI `--from-glb` thay một tổ hợp từ mesh artist; mẫu nam/Thanh Ngọc/búi tóc/kiếm đã dùng GLB re-export Blender trong game, không chỉ lưu file tham khảo.

CHR-007: mặt contoured liên tục, mắt almond, tóc curved locks; tunic/sleeves nối vai và có weights elbow, tà split-robe theo hai chân. Các phần da upper-arm đã bị áo che được loại khỏi runtime để tránh skin xuyên vai. Triangle winding theo clockwise của Godot; skin weights được phân bổ theo UNORM16 trước khi pack.

CHR-013/016: environment dùng PNG atlas mipmap thật, continuous world UV và soft path shoulders; decorative forest ngoài biên chỉ là presentation. Y-sort, nav/LOS/safe-zone, input, save, damage không đổi. Sói vector cong có bốn chân articulated, telegraph/HP/slow/hit vẫn nối trạng thái thật. Native evidence và giới hạn mỹ thuật tại quality report và acceptance 0.10.
