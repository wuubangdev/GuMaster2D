# Ma trận sản xuất nhân vật và hoạt ảnh — bản chi tiết 03

Ngày 11/10/2026. Phần này mở rộng [FSD nhân vật](FSD_MODULAR_CHARACTER.md), [animation và skill](ANIMATION_AND_SKILLS.md), [WBS nhóm 4 người](WBS.md). Trạng thái: **thiết kế nền; pilot một phần đã vào runtime, các cổng art còn lại chưa hoàn tất**.

## 1. Hợp đồng hướng nhìn

Giữ thứ tự direction hiện hành: 0/S, 1/SW, 2/W, 3/NW, 4/N, 5/NE, 6/E, 7/SE. Mỗi hướng có source riêng; không phản chiếu nguyên nhân vật để giả hướng đối diện. Cùng ID direction được dùng cho thân, mặt, tay gần/xa, tóc, nón, vũ khí và VFX.

Pivot actor đặt tại trung điểm mặt đất dưới hai chân. Pivot giữ nguyên giữa body và trang bị; sole của chân chịu lực là điểm tiếp đất. Có thể blend thân/tay khi quay nhưng mặt phải đổi view author riêng; không crossfade làm chồng mắt.

## 2. Coverage trạng thái

| State | Key pose tối thiểu cần author | Loop/transition | Phụ thuộc |
|---|---:|---|---|
| idle | 4 | loop thở nhẹ; vào/ra từ chân chống | body, relaxed grip |
| walk | 8 | vòng có stance/swing; phase theo quãng đường | chân, tà, tóc |
| run | 8 | nén và flight ngắn; giữ phase khi đổi tốc độ | chân, tà, tóc, vũ khí |
| attack | 6 | ready, windup, release, follow-through, recovery | sword/spear/unarmed |
| defend | 4 | entry, hold, phản lực, exit | tay và weapon profile |
| cast | 4 | chuẩn bị, tập trung, thả, thu tay | tay/vũ khí; event gameplay |
| channel | 4 | loop nhỏ; cancel đúng state | tóc/áo biên độ nhỏ |
| dash | 4 | hạ trọng tâm, lướt, tiếp đất, settle | hướng/endpoint authority |
| hit | 3 | phản lực, chống chân, phục hồi | không ghi đè death |
| death | 3 | mất lực, khuỵu/gục, settle | dọn VFX/action cũ |
| respawn | 3 | xuất hiện, đứng dậy, idle | hướng/vị trí respawn state |

Đây là số **key pose thiết kế**, không phải frame xuất atlas hay bằng chứng animation mượt. Renderer có thể nội suy layer; các keyframe silhouette quan trọng vẫn phải được author riêng. Chu kỳ chỉ nghiệm thu sau khi xem footage thật ở tốc độ game.

Coverage hiện hành là 11 state × 8 hướng = 88 entry cho mỗi body/weapon profile, tương ứng 528 entry nếu liệt kê 2 body × 3 weapon profile. Đây là bảng phân giải clip, không phải 528 clip độc lập: nhiều state dùng source chung; chỉ override nơi pose/grip thực sự khác. Wardrobe không nhân số clip thành 216 atlas; layer được resolve bằng ID và socket.

## 3. Layer và manifest

- Body: head, face, ears, hands, trousers; hình riêng male/female.
- Hair: fringe, crown, tail; front/back tách để xử lý nón.
- Outfit: torso, collar, belt, sleeve gần/xa, tà trước/sau.
- Boots: chân trái/phải, boot shape và sole.
- Hat: back rim, crown, front rim; mask theo body, hair và direction.
- Weapon: hình cứng, grip tay chính/phụ; spear cần support grip.
- Presentation-only: ground shadow và VFX. Không nối pivot mỹ thuật vào hitbox/navmesh.

Mẫu manifest đề xuất, chưa phải schema được game nạp:

~~~json
{
  "schema": 2,
  "body": "male",
  "slot": "outfit",
  "item": "jade",
  "facing": "E",
  "action": "walk",
  "pose": 0,
  "pivot": [24, 42],
  "sockets": {
    "head": [24, 9],
    "wrist_L": [14, 23],
    "wrist_R": [34, 23],
    "ankle_L": [20, 38],
    "ankle_R": [28, 38],
    "weapon_grip": [35, 24],
    "support_grip": [17, 22]
  },
  "depth_profile": "east_walk_near_arm_front"
}
~~~

Kích thước cell và vị trí socket chỉ chốt sau khi pilot được duyệt ở world scale và màn preview. Validator cần bắt ID trùng, hướng thiếu, socket không hữu hạn, pivot lệch, mask nón thiếu và weapon profile thiếu support grip.

Đường dẫn nguồn đề xuất: art/source/characters/ink/{body}/{slot}/{item}/{facing}/{action}/pose_{index}.svg. File render/import nằm trong thư mục build asset riêng; không cắt ảnh concept nền giấy thành sprite.

## 4. Tổ hợp trang bị

Appearance runtime có body, outfit, weapon, hair, boots, hat; catalog hiện resolve 2 body × 3 outfit × 3 trạng thái nón (none/nón lá/quan mây) × 2 tóc × 2 giày × 3 vũ khí = **216 look**. Profile giữ bốn field legacy và lưu phụ kiện riêng trong `appearance_v2`. Đây là số cấu hình cần resolve, không phải số sheet cần vẽ.

Thứ tự resolve: body → facing/action base → outfit fit → boots → hair → hat mask → weapon/grip/depth. Outfit fit theo body; nón che crown nhưng giữ fringe theo mask; tóc đuôi có socket sau; giày giữ sole contact; weapon theo grip/depth của hướng. Lỗi một slot thì fallback riêng slot và ghi log, không reset cả ngoại hình.

Trước khi mở rộng catalog, kiểm tra cả hai body ở tám hướng với nón rộng, tóc dài, tà áo dài, giày cao và thương dài. Sau đó tự động resolve 216 ID; kiểm tra trực quan extreme fits riêng.

## 5. Naming và công cụ preview

Clip key: body/facing/action/weapon_profile. Part key: slot/item/body_fit/facing. Manifest không chứa combat stats, phím điều khiển, localization hay save state.

Preview tool sau duyệt cần scrub action/pose, chọn body/facing/weapon, đổi slot, bật socket/mask overlay, nền sáng/tối và xuất contact sheet. Preview không gọi attack/damage, save profile thật hoặc giữ input khi đóng. Đây là công cụ nghiệm thu source, không phải UI người chơi.

## 6. Thứ tự sản xuất

1. Khóa mặt/tỷ lệ/màu ở 48 px; vẽ pilot male và female, kiểm bốn hướng cardinal.
2. Mở pilot lên tám hướng; kiểm tay gần/xa và vũ khí dài.
3. Chốt idle/walk/run/stop, chạy quay hướng và đổi walk↔run; sửa contact trước combat.
4. Thêm outfit, tóc, mũ và giày dạng layer; duyệt extreme fit trước khi nhân outfit.
5. Thêm attack/defend cho ba weapon profile, rồi cast/channel/dash/hit/death/respawn.
6. Author bốn icon/VFX theo cùng recipe; nối event thật ở gói implementation tiếp theo sau pilot phụ kiện.
7. Nối resolver vào renderer hiện có, HUD/F3/F6 và profile mới; giữ fallback/migration riêng.

## 7. Chia việc cho bốn người

| Vai trò | Gói chính | Review bắt buộc |
|---|---|---|
| A — nhân vật/wardrobe | silhouette, face, outfit, hair/hat/boots, alpha source | D duyệt readability; B duyệt fit theo pose |
| B — animation/rig | 8 hướng, key pose, arm bend, feet, weapon grip | A duyệt shape; D duyệt footage/contact |
| C — Godot/data | manifest, resolver, renderer, preview, migration | B review socket/depth; D review fallback/regression |
| D — skill/UI/verification | icon/VFX, HUD preview, contact sheet, evidence | A duyệt art; C duyệt event/state |

Nhóm bốn người là năng lực dự kiến. Nếu thiếu người chuyên vẽ/animate, giảm outfit/vũ khí của pilot; không coi ảnh concept là sprite chạy được.

## 8. Cổng nghiệm thu

- Concept: duyệt nét, identity, tỷ lệ, màu; chưa có asset runtime.
- Source pilot: alpha tách lớp, pivot/socket và coverage 8 hướng có manifest.
- Animation: footage thật idle→walk→run→stop, quay hướng và attack/guard; kiểm mặt ngang/sau và tay cầm tại world size.
- Appearance: đổi từng slot giữ action phase, hướng, save và chỉ số; 216 ID resolve/fallback ổn định.
- Skills: bốn icon đọc ở 32/48/64 px; cast/travel/contact/end bám event thật, không đổi balance.
- Build: cold import, log, migration và bằng chứng PC; production-ready chỉ sau review + verify.

Liên kết: [bộ duyệt bổ sung 03](REVIEW_SUPPLEMENT_03.md), [FSD](FSD_MODULAR_CHARACTER.md), [WBS](WBS.md), [cổng nghiệm thu](ACCEPTANCE.md).
