"""Alpha planning baseline, updated for Godot. Prototype evidence is tracked separately."""
from datetime import date

META = {
    'name': 'GuMaster2D', 'version': '0.2 — Godot PC; alpha đề xuất',
    'prepared': date(2026, 10, 7), 'start': date(2026, 10, 12),
    'weeks': 36, 'hours': 20, 'focus': 0.75, 'reserve': 0.20,
    'source_idea': 'Pasted text.txt — ý tưởng Cổ trùng + MMORPG 2D isometric',
    'source_template': 'DAUN-FSD [EN].xlsx',
}
ROLES = [
    ('GD', 'Thành viên 1 — Product/Game Design + QA', 'Phạm vi, dữ liệu cân bằng, quest, kiểm thử, điều phối và playtest'),
    ('CL', 'Thành viên 2 — Client/Gameplay', 'Godot/GDScript, render isometric, điều khiển, UI và tích hợp gameplay'),
    ('SV', 'Thành viên 3 — Server/Tech Lead', 'Realtime, PostgreSQL, bảo mật, tooling vận hành và triển khai'),
    ('AR', 'Thành viên 4 — 2D/Content/UI', 'Tileset, sprite, icon, map, VFX, âm thanh có nguồn sử dụng rõ ràng'),
]

# One package per owner per two-week sprint. Estimates are productive eight-hour person-days.
SPRINTS = [
 ('1.0', 'Khóa phạm vi và spike',
  ('Khóa MVP, FSD và danh sách quyết định', 'Scope v0.2; FSD có ID, AC, danh sách TBD', '', 2.5),
  ('Spike Godot isometric trên PC; thử Web export', 'Map mẫu, click-to-move, đo render trên máy tham chiếu', '', 3),
  ('Spike authoritative room và lưu dữ liệu', 'Hai client kết nối; server giữ state; thử ghi transaction', '', 3),
  ('Art direction và kiểm kê tài nguyên', 'Moodboard nội bộ, style guide, danh mục asset và nguồn', '', 2.5)),
 ('2.0', 'Nền tảng kỹ thuật',
  ('Chốt luật chiến đấu và mô hình dữ liệu', 'Rulebook, 5 Cổ đầu, flow lỗi và test matrix', 'T01-GD,T01-CL,T01-SV', 2.5),
  ('Client shell, scene và tọa độ', 'Boot/Login/World/HUD; world↔iso; loader và input', 'T01-CL', 3),
  ('Repo, CI, schema và đăng nhập', 'CI build; migration; tài khoản mời; session một nhân vật', 'T01-SV', 3),
  ('Nhân vật và tileset cơ sở', 'Một avatar, 4 hướng hiển thị, idle/walk/attack; tileset dùng lại', 'T01-AR', 2.5)),
 ('2.0', 'Nền tảng kỹ thuật',
  ('Kiểm thử điều khiển và onboarding', 'Checklist click, focus chat, resize; kịch bản 30 giây đầu', 'T02-GD,T02-CL', 2),
  ('Di chuyển, camera, va chạm và chọn mục tiêu', 'A*, camera bám, click marker, target vòng chọn', 'T02-CL,T02-AR', 3),
  ('Room, quyền vào map và session lease', 'Join/leave có auth; single writer; giới hạn map', 'T02-SV', 3),
  ('Bản đồ thị trấn và bố cục HUD', 'MAP-01; spawn/NPC/portal; HUD wireframe và icon nền', 'T02-AR', 2.5)),
 ('2.0', 'Nền tảng kỹ thuật',
  ('Gate G1 — thử hai client và lỗi mạng', 'Biên bản kiểm thử auth, chuyển map và mất kết nối', 'T03-GD,T03-CL,T03-SV', 2.5),
  ('Tích hợp đồng bộ và nội suy', 'Remote players; correction; HUD mạng; không ghost entity', 'T03-CL,T03-SV', 3),
  ('Di chuyển authoritative và AOI', 'Validate đường đi/tốc độ; state lọc theo vùng; chống warp', 'T03-SV,T03-CL', 3),
  ('Hoàn thiện HUD nền và feedback di chuyển', 'HP/mana/target/minimap; click/denied feedback', 'T03-AR', 2.5)),
 ('3.0', 'PvE first playable',
  ('Cân bằng 5 Cổ và combat test cases', 'Thông số sát thương, mana, CC, cooldown có đơn vị', 'T04-GD,T02-GD', 2.5),
  ('Combat UI và 5 kỹ năng đầu', 'QWER, chọn mục tiêu, telegraph, cooldown, hit feedback', 'T04-CL,T04-AR', 3),
  ('Combat resolver và trạng thái', 'Range/LOS/cooldown/mana; damage, shield, slow, stun', 'T04-SV', 3),
  ('VFX/SFX chiến đấu cơ sở', 'Projectile, impact, shield, warning; âm lượng và mute', 'T04-AR', 2.5)),
 ('3.0', 'PvE first playable',
  ('Gate G2 — vòng đánh quái và nhận thưởng', '10 phiên 15 phút; ghi TTK, lỗi; chưa đo retention dài hạn', 'T05-GD,T05-CL,T05-SV', 2.5),
  ('Quái, loot và chết/hồi sinh phía client', 'Nameplate, loot popup, respawn, NPC interaction', 'T05-CL', 3),
  ('AI quái, spawn, loot và hồi sinh', 'FSM idle/aggro/chase/attack/leash/dead; reward exactly once', 'T05-SV', 3),
  ('Map cày bãi và quái cơ sở', 'MAP-02; 6 loại quái dùng biến thể; điểm spawn và collision', 'T05-AR', 3)),
 ('4.0', 'Vòng lặp Cổ và progression',
  ('Thiết kế inventory, economy và dữ liệu Cổ', 'Catalog 20 Cổ/10 vật liệu; nguồn-tiêu; bộ test trùng lệnh', 'T06-GD', 2.5),
  ('Túi đồ, tooltip, trang bị Không Khiếu', '30 ô; drag/click equip; 4 active + 2 passive', 'T06-CL', 3),
  ('Persistence inventory và giao dịch nội bộ', 'Lock/version; ledger; request ID; atomic reward/equip', 'T06-SV', 3),
  ('Icon Cổ và UI inventory', '20 icon + vật liệu; trạng thái khóa/đói/trang bị đọc rõ', 'T06-AR', 2.5)),
 ('4.0', 'Vòng lặp Cổ và progression',
  ('Luật bắt và nuôi Cổ, thử chi phí thức ăn', 'Cấu hình capture; hunger online; recovery; bộ test', 'T07-GD,T07-SV', 2.5),
  ('UI săn bắt và nuôi Cổ', 'Thanh channel bắt Cổ; xác nhận đồ ăn; preview phục hồi', 'T07-CL', 3),
  ('Capture và feeding authoritative', 'Target claim; roll server; atomic seal/food/reward/hunger', 'T07-SV', 3),
  ('Hiệu ứng bắt Cổ và NPC luyện/nuôi', 'Capture FX, NPC, UI hunger và màn thông báo', 'T07-AR', 2)),
 ('4.0', 'Vòng lặp Cổ và progression',
  ('Công thức luyện và xác suất minh bạch', '10 recipe; pity; 5.000 lượt mô phỏng trên dữ liệu nháp', 'T08-GD', 2.5),
  ('UI luyện Cổ và lịch sử kết quả', 'Chọn instance, recipe, preview tỷ lệ; request retry', 'T08-CL', 3),
  ('Luyện Cổ transaction và idempotency', 'Atomic consume/RNG/pity/output/ledger; crash/retry tests', 'T08-SV', 3),
  ('UI luyện Cổ và thông báo kết quả', 'Success/fail khác nhau; không chỉ phân biệt bằng màu', 'T08-AR', 2)),
 ('4.0', 'Vòng lặp Cổ và progression',
  ('Quest, cấp độ và thăng chuyển', '10 quest; level 1–20; rank I–II; XP curve', 'T09-GD', 2.5),
  ('Quest tracker, level up và NPC shop', 'Nhận/trả quest; shop fixed price; kiểm tra rank', 'T09-CL', 3),
  ('Quest/progression/NPC economy', 'Event quest; atomic claim/rank-up/buy/sell; caps', 'T09-SV', 3),
  ('Hoàn thiện map, NPC và props tái sử dụng', 'Town/farm đủ đường đi; 4 NPC; collision đã đánh dấu', 'T09-AR', 2.5)),
 ('4.0', 'Vòng lặp Cổ và progression',
  ('Cân bằng đầy đủ 20 Cổ và nguồn loot', '20 Cổ từ 8 primitive; 3 build khả thi; loot catalog', 'T10-GD', 3),
  ('Tích hợp đầy đủ Cổ, passive và codex', '20 Cổ data-driven; status icons; mô tả đầy đủ', 'T10-CL', 3),
  ('Mở rộng effect primitives và content validator', '8 primitive; passive stack policy; schema/version checks', 'T10-SV', 3),
  ('Hoàn thiện icon, animation và status FX', 'Bộ icon final alpha; hit/death; FX dùng lại', 'T10-AR', 2.5)),
 ('4.0', 'Vòng lặp Cổ và progression',
  ('Gate G3 — E2E vòng Cổ', '20 tester nội bộ/luân phiên; capture→feed→craft→equip→fight', 'T11-GD,T11-CL,T11-SV', 3),
  ('Reconnect UI và E2E sửa lỗi client', 'Overlay mất mạng; resync bag/status; không gửi lệnh cũ', 'T11-CL', 3),
  ('Reconnect, map handoff và crash recovery', 'Lease fencing; reserve/commit transfer; durable state resync', 'T11-SV', 3),
  ('Map phụ bản và boss blockout', 'MAP-03; arena tái dùng vùng; telegraph đủ khoảng né', 'T11-AR', 2.5)),
 ('5.0', 'Nội dung multiplayer giới hạn',
  ('Thiết kế party/boss/arena và QA matrix', 'Party 3; loot cá nhân; trận 1v1 không xếp hạng', 'T12-GD', 2.5),
  ('Party và chat khu vực/party', 'Mời/đồng ý/rời; leader UI; mute/report; focus input', 'T12-CL', 3),
  ('Party state và chat có giới hạn', 'Membership; invite TTL; rate limit; server recipient filter', 'T12-SV', 3),
  ('Sprite boss và quái tinh anh', '1 boss/2 elite biến thể; windup/attack/death', 'T12-AR', 3)),
 ('5.0', 'Nội dung multiplayer giới hạn',
  ('Kiểm thử phụ bản và reward chống lặp', '10 run đủ/thất bại/disconnect; ledger cá nhân', 'T13-GD,T13-CL,T13-SV', 2.5),
  ('Phụ bản và boss UI/telegraph', 'Entry vote, boss HP, kết quả; AoE dễ đọc', 'T13-CL,T13-AR', 3),
  ('Dungeon instance, boss và personal reward', '3 người/15 phút; boss 2 pattern; run ID; cleanup', 'T13-SV', 3),
  ('Boss VFX, dungeon props và âm thanh', '2 telegraph boss; ambient dùng lại; music mute', 'T13-AR', 2.5)),
 ('5.0', 'Nội dung multiplayer giới hạn',
  ('Gate G4 — multiplayer và PvP', 'Party 3; dungeon; 1v1; quyết định cắt phạm vi nếu trễ', 'T14-GD,T14-CL,T14-SV', 2.5),
  ('Đấu tay đôi opt-in và kết quả', 'Invite/ready/countdown/result; quay lại safe spawn', 'T14-CL', 3),
  ('Arena PvP, timer và disconnect policy', 'Two opt-ins; PvP damage factor; no reward farming', 'T14-SV', 3),
  ('Arena/UI social và độ đọc hình', 'Arena từ tileset có sẵn; silhouette/telegraph/party colors', 'T14-AR', 2)),
 ('6.0', 'Ổn định và closed alpha',
  ('Feature freeze, UAT plan và hướng dẫn tester', 'Traceability đóng; checklist NFR; test accounts/instructions', 'T15-GD,T15-CL,T15-SV', 3),
  ('Admin UI tối thiểu và settings client', 'GM tra cứu/read-only; âm lượng/phím/đồ họa; role guard', 'T15-CL', 3),
  ('GM API, audit, metrics và backup jobs', 'RBAC/mute/ban/grant; config publish; daily snapshot', 'T15-SV', 3),
  ('Polish HUD, feedback và asset audit', 'UI thống nhất; lỗi/thành công; file và nguồn asset đầy đủ', 'T15-AR', 2.5)),
 ('6.0', 'Ổn định và closed alpha',
  ('UAT, soak test phối hợp và phân loại lỗi', '20 tester; 50 bots/2 giờ; 3 build; lỗi P0/P1 về 0', 'T16-GD,T16-CL,T16-SV', 3),
  ('Tối ưu client và sửa lỗi UAT', 'FPS p95 frame time; asset budget; Windows matrix và Web spike', 'T16-CL', 3),
  ('Load/fault/security và tối ưu server', '50 CCU toàn shard/20 map; duplicate, kill/restart, expiry', 'T16-SV', 3),
  ('Atlas, compression và pass đọc hình', 'Đo payload, giảm overdraw; font/contrast/audio review', 'T16-AR', 2.5)),
 ('6.0', 'Ổn định và closed alpha',
  ('Gate G5 — release checklist và alpha report', 'NFR/UAT có evidence; lịch beta; go/no-go; báo cáo 7 ngày', 'T17-GD,T17-CL,T17-SV,T17-AR', 3),
  ('Release candidate và sửa lỗi phát hành', 'Client RC tag; smoke test; known issues; rollback compatible', 'T17-CL', 3),
  ('Restore drill, deploy và runbook', 'Staging→private alpha; restore đo RPO/RTO; rollback diễn tập', 'T17-SV', 3),
  ('Hoàn tất asset và gói giới thiệu alpha', 'Asset manifest, credits; screenshot, hướng dẫn hiển thị', 'T17-AR', 2)),
]

REQS = []
def req(id, module, group, screen, name, spec, inputs, outputs, errors, ac, wbs, rule='', uc='', phase='MVP', priority='Must'):
    REQS.append(dict(id=id, module=module, group=group, screen=screen, name=name,
      spec=spec, inputs=inputs, outputs=outputs, errors=errors, ac=ac, wbs=wbs,
      rule=rule, uc=uc, phase=phase, priority=priority, status='Đề xuất', test='TC-'+id))

req('CL-001','Tài khoản','Phiên chơi','Login','Đăng nhập bằng tài khoản mời','Nhập username/password; xác thực server; chuyển chọn nhân vật. Không mở đăng ký công khai trong alpha.','Username, password','Session; profile','Sai thông tin hiển thị chung; khóa tạm sau nhiều lần sai','Tài khoản hợp lệ vào được; sai/expired không vào room.','T02-CL,T02-SV',uc='UC-01')
req('CL-002','Tài khoản','Nhân vật','Character','Tạo và chọn nhân vật','Mỗi account 1 nhân vật; đặt tên 3–16 ký tự Unicode chữ/số/khoảng trắng; trim; kiểm tra tên trùng và danh sách cấm.','Tên, avatar cơ sở','Character ID, starter kit','Tên lỗi/trùng; gửi lặp không tạo thêm','Hai request đồng thời chỉ tạo 1 nhân vật và 1 starter kit.','T02-CL,T02-SV',rule='BR-01',uc='UC-01')
req('CL-003','Thế giới','Điều khiển','World','Click-to-move isometric','Click trái nền gửi đích; client tìm đường A* trên nav grid; server xác nhận đường/tốc độ; hỗ trợ hủy bằng click mới.','Tọa độ world, sequence','Path, vị trí render','Đích ngoài map/tường: hiện marker không đi được','Đi quanh vật cản; click liên tục không xuyên tường; UI click không di chuyển.','T03-CL,T04-SV',rule='BR-02',uc='UC-02')
req('CL-004','Thế giới','Camera','World','Camera và depth sorting','Camera bám nhân vật trong biên map; render theo ground Y + layer; props cao che đúng; không xoay camera.','Player/world position','Viewport và thứ tự sprite','Resize vẫn giữ nhân vật trong khung','Đi sau/trước 10 props không đảo layer; 1366×768 và 1920×1080 dùng được.','T02-CL,T03-CL,T03-AR')
req('CL-005','Thế giới','Mục tiêu','World','Chọn và tương tác mục tiêu','Click quái chọn; click NPC trong 2 tile mở tương tác; click xa tự đi đến; vòng chọn và HP mục tiêu.','Entity ID','Target panel/interaction','Target mất AOI/chết: bỏ chọn','Không mở NPC ở xa; mục tiêu biến mất không gây lỗi UI.','T03-CL,T06-CL',rule='BR-02',uc='UC-02')
req('CL-006','Thế giới','Bản đồ','Minimap','Minimap và cổng map','Hiện vị trí bản thân, party, NPC, cổng; dùng portal tương tác để chuyển map; không lộ entity ngoài quyền xem.','Map ID, portal ID','Minimap và loading state','Map đầy hoặc server lỗi: ở map cũ, báo lý do','Chuyển map không xuất hiện hai bản nhân vật; minimap đúng collision/portal.','T04-CL,T12-CL,T12-SV',uc='UC-11')
req('CL-007','Chiến đấu','Kỹ năng','Hotbar','Thanh Cổ Q/W/E/R','4 ô active; 2 ô passive mở rank II; QWER kích hoạt; số 1 dùng vật phẩm hồi phục; remap ở settings.','Gu instance, hotkey, target','Cast request, cooldown UI','Chat/input đang focus không phát skill','Bốn hotkey và click đều hoạt động; skill chưa đủ điều kiện báo cùng mã lỗi.','T05-CL,T07-CL,T11-CL',rule='BR-03',uc='UC-03')
req('CL-008','Chiến đấu','Kỹ năng','Targeting','Thi triển chỉ mục tiêu/điểm đất/tự thân','Cổ định nghĩa targetMode; điểm đất preview vòng AoE; Esc/hủy click; cast bar khi có castTime; server quyết định hit.','Gu ID, target ID hoặc world point','Preview, cast/hit/denied','Target chết/ngoài tầm/không LOS: không trừ mana','Mỗi mode ít nhất 1 skill kiểm thử; không đánh xuyên vật cản LOS.','T05-CL,T05-SV,T11-CL',rule='BR-04',uc='UC-03')
req('CL-009','Chiến đấu','Tài nguyên','HUD','HP và Chân Nguyên','Hiện HP/mana số và thanh; mana cost lấy từ maxMana × cost%; server snapshot là nguồn số thật.','HP/mana/cost server','Bars, mana feedback','Mana thiếu: từ chối cast, không reset cooldown','UI đúng số server sau cast, hồi phục và reconnect.','T04-CL,T05-CL,T05-SV',rule='BR-05')
req('CL-010','Chiến đấu','Trạng thái','HUD','Buff, debuff và combat feedback','Icon có thời gian; shield/slow/stun/heal rõ; damage number có giới hạn; telegraph không chỉ dựa màu.','Combat events/status endTime','Icon, VFX, SFX','Event trùng bỏ qua bằng eventId','Stun/slow đúng duration; mute tắt được audio; denied khác hit.','T05-CL,T11-CL,T11-AR',rule='BR-06')
req('CL-011','Chiến đấu','Sinh tử','Respawn','Chết và hồi sinh','0 HP khóa input combat; 5 giây rồi hồi tại safe spawn; không mất Cổ trong MVP; mất 5% tiền mềm, cap 50.','Death event; respawn intent','Respawn, penalty receipt','Nhấn lặp không trừ nhiều lần; đang mất mạng chờ resync','Một death chỉ một penalty; quest/Gu vẫn còn sau hồi sinh.','T06-CL,T06-SV',rule='BR-07',uc='UC-10')
req('CL-012','PvE','Quái và loot','World','Đánh quái và nhận loot','Quái có cấp, HP, aggro, leash; loot cá nhân vào túi sau server commit; popup theo receipt.','Mob ID, combat intent','XP, tiền, vật liệu/Gu','Túi đầy không mất reward: vào reward inbox','Hai client đánh cùng quái chỉ một owner nhận reward; retry không nhân đôi.','T06-CL,T06-SV,T07-SV',rule='BR-08',uc='UC-03')
req('CL-013','Inventory','Túi đồ','Bag','Túi 30 ô và stack','30 ô; vật liệu stack 99; Gu unique 1 ô/instance; lọc Gu/nguyên liệu/vật phẩm; sort chỉ thay layout.','Items, slot IDs','Bag, count','Không gộp Gu instance; túi đầy báo thiếu ô','Stack 98+3 thành99+2; không tạo/xóa item bằng sort.','T07-CL,T07-SV',rule='BR-09',uc='UC-04')
req('CL-014','Inventory','Chi tiết','Tooltip','Tooltip và khóa Cổ','Hiện rank/type/mana/cooldown/food/hunger/bound; người chơi lock để chống chọn nhầm khi luyện hoặc bán.','Gu instance/config','Tooltip; lock state','Locked/equipped không dùng làm nguyên liệu','Tooltip khớp catalog; khóa có hiệu lực sau reconnect.','T07-CL,T07-SV',rule='BR-10',uc='UC-04')
req('CL-015','Cổ trùng','Không Khiếu','Loadout','Trang bị và tháo Cổ','4 active từ rank I; 2 passive khi rank II; không trùng definition trên cùng loadout; sửa ở safe zone và ngoài combat 5 giây.','Slot, Gu instance, expectedVersion','Loadout, derived stats','Sai rank/type/duplicate/đang combat: reject','Swap nguyên tử; không tồn tại 1 Gu ở 2 slot; stats không cộng lặp.','T07-CL,T07-SV,T11-SV',rule='BR-03,BR-10',uc='UC-04')
req('CL-016','Cổ trùng','Săn bắt','Capture','Bắt Hoang Cổ','Quái có cờ capturable; HP≤30%; gần≤3 tile; channel 2 giây, nhận damage thì hủy; seal tiêu khi channel hợp lệ bắt đầu.','Spawn ID, capture seal','Progress; success/fail receipt','Túi đầy/target không hợp lệ: không bắt đầu, không tiêu seal','Hai người bắt cùng spawn chỉ một người giữ claim; chết/bắt chỉ một terminal result.','T08-CL,T08-SV',rule='BR-11',uc='UC-05')
req('CL-017','Cổ trùng','Nuôi dưỡng','Feed','Cho ăn và trạng thái đói','Hunger 0–100, giảm 1 điểm/5 phút online khi equipped; offline dừng; <20 yếu đi, 0 ngủ, không chết; đồ ăn phù hợp +40.','Gu instance, food instance/qty','Hunger/stat preview; receipt','Sai thức ăn/đầy hunger: reject không mất đồ','Feed một lần +40 cap100; online/offline không bị tính đôi.','T08-CL,T08-SV',rule='BR-12',uc='UC-06')
req('CL-018','Cổ trùng','Luyện chế','Refine','Chọn công thức và preview','10 recipe rank I→II; chọn 2 instance Cổ khác nhau, vật liệu, tiền; hiển thị tỷ lệ hiện tại/pity và điều gì mất khi fail.','Recipe ID, input instance IDs','Preview costs/chance/output','Locked/equipped/sai sở hữu/rank: chặn','Preview và server dùng cùng configVersion; không có xác suất ẩn.','T09-CL,T09-SV',rule='BR-13',uc='UC-07')
req('CL-019','Cổ trùng','Luyện chế','Refine result','Thực hiện luyện và xem kết quả','Server roll; base70%, fail tăng10 điểm phần trăm đến100%; fail mất vật liệu/tiền, giữ 2 Cổ; success mất input và tạo 1 Cổ II.','Request ID, recipe, inputs, version','Durable receipt, pity, inventory version','Timeout: tra receipt/retry cùng ID; không gửi roll mới','Retry20 lần cùng ID trả cùng kết quả và chỉ tiêu hao một lần.','T09-CL,T09-SV',rule='BR-13,BR-14',uc='UC-07')
req('CL-020','Tiến triển','Cấp và rank','Character','Cấp 1–20 và Nhất/Nhị Chuyển','XP tích lũy; rank I ban đầu, rank II cần level10 + quest08 +500 tiền +10 đá; mở passive và dùng CổII.','XP events; rank-up intent','Level/stats/slot unlock','Thiếu điều kiện: liệt kê thiếu; cấp20 dừng tăng','Level10 chưa thăng rank không trang bị CổII; rank-up lặp không tiêu thêm.','T10-CL,T10-SV',rule='BR-15',uc='UC-08')
req('CL-021','Nhiệm vụ','Nhận/trả','Quest log','10 quest và tracker','8 chính +2 phụ; trạng thái locked/available/active/completed/claimed; 3 tracker; event kill/capture/feed/craft/dungeon.','Quest ID; gameplay events','Progress, reward, next quest','Quest item không đủ/đã claim: không nhận lại','Progress reconnect còn đúng; Q08 chỉ mở Q09 khi rank II.','T10-CL,T10-SV',rule='BR-16',uc='UC-08')
req('CL-022','Kinh tế','NPC','Shop','Mua/bán với NPC','NPC fixed price; bán vật liệu và Gu không khóa/không equipped; toàn bộ Gu bound trong MVP; không giao dịch người chơi.','NPC ID, item ID, qty, version','Preview; balance; receipt','Xa NPC, thiếu tiền, thiếu ô, qty sai: reject','Mua/bán concurrent không âm tiền/item; 1 receipt cho 1 request.','T10-CL,T10-SV',rule='BR-09,BR-14',uc='UC-09')
req('CL-023','Xã hội','Tổ đội','Party','Party tối đa 3 người','Mời, accept/decline, kick, leave; invite TTL30giây; leader rời thì chuyển người vào sớm nhất; không auto-match.','Player ID, invite ID','Roster, HP, leader','Đầy/đã party/expired: reject không tạo hai membership','Hai invite đồng thời không làm người chơi ở2 party; thành viên4 bị chặn.','T13-CL,T13-SV',rule='BR-17',uc='UC-12')
req('CL-024','Xã hội','Chat','Chat','Chat zone/party, mute/report','Tối đa200 ký tự/message;2message/giây burst4; hiển thị text escaped; local mute; report lưu bằng chứng message ID.','Channel, text, message ID','Filtered message/report ID','Không party không gửi party; HTML không render','Chat chỉ tới người đúng channel; gõ QWER trong chat không cast.','T13-CL,T13-SV,T16-SV',rule='BR-18')
req('CL-025','PvE','Phụ bản','Dungeon','Phụ bản 1–3 người và boss','Leader tạo; mọi người level10/rankII ở portal và ready; instance15phút;1boss2pattern; loot cá nhân; một reward/run/character.','Party, ready, portal','Run ID, telegraph, results','Thiếu điều kiện từ chối cả nhóm; wipe hồi entry; hết giờ đóng','Ba người vào đúng một run; boss chết lặp không tạo thêm reward.','T14-CL,T14-SV',rule='BR-19',uc='UC-13')
req('CL-026','PvP','Đấu tay đôi','Arena','PK opt-in 1v1','Hai bên accept; ready10giây/countdown3giây; trận180giây; stats thật, PvP damage×0.7; hòa khi hết giờ; không thưởng tiền/loot.','Invite, accept, loadout snapshot','Match state/result','Ngoài arena không gây damage người chơi; disconnect>30giây xử thua','Một trận có1result; không mất Cổ/tiền do chết arena; loadout không sửa giữa trận.','T15-CL,T15-SV',rule='BR-20',uc='UC-14')
req('CL-027','Hệ thống','Mạng','Connection','Mất kết nối và trở lại','Overlay ngay khi mất kết nối; grace30giây; tạm dừng input; reconnect nhận snapshot đầy đủ, receipt còn pending có thể query.','Reconnect token/session','Authoritative snapshot','Hết grace: login lại; không phát lại queue cast cũ','Rút mạng10giây trở lại cùng nhân vật; inventory không nhân đôi.','T12-CL,T12-SV',rule='BR-21',uc='UC-11')
req('CL-028','Hệ thống','Thiết lập','Settings','Thiết lập PC và lưu tùy chọn','Âm lượng master/music/SFX, mute, quality low/normal, remap QWER/1; local preferences; UI tiếng Việt trước.','Settings values','Local settings','Trùng phím: báo và yêu cầu thay; không bind vào chat input','Reload giữ tùy chọn; trình duyệt chặn autoplay thì mở audio sau gesture.','T16-CL,T16-AR')
req('CL-029','Hướng dẫn','First session','Tutorial','30 giây đầu và tutorial','Từ spawn an toàn: click di chuyển, Q đánh mục tiêu huấn luyện, nhặt thức ăn, mở túi; tiếp tục quest dài hơn sau đó.','New character, tutorial step','Hints, starter items','Bỏ qua vẫn có starter kit; reload không cấp thêm','≥80% trong tối thiểu10tester hoàn thành phần điều khiển ≤3phút không người hướng dẫn.','T03-GD,T10-CL,T16-GD',uc='UC-01')
req('CL-030','Cổ trùng','Tra cứu','Codex','Danh mục Cổ và build','20 Cổ với rank, loại, target, mana, cooldown, thức ăn, recipe; lọc owned/all; không gợi ý build trả tiền.','Catalog/configVersion','Codex; loadout inspection bản thân','Config thiếu hiển thị fallback và log lỗi','20/20 Cổ có tooltip đủ số; Cổ chưa sở hữu không equip được.','T11-CL,T11-GD')

req('SV-001','Identity','Access','Auth service','Xác thực và vòng đời session','Account mời; hash mật khẩu; session hết hạn/revoke; chỉ chủ sở hữu vào character; join room bắt buộc token hợp lệ.','Credentials/token','Session/account claims','Token thiếu/hết hạn/sai chữ ký:401; không tin default library','Tokenless hoặc token account khác không đọc/chơi character.','T02-SV,T03-SV',rule='BR-01',uc='UC-01')
req('SV-002','World','Simulation','World room','Server giữ quyền quyết định','Client gửi intent; server tính vị trí, target, cooldown, HP, loot, RNG; simulation20Hz mục tiêu; patch10Hz ban đầu.','Intent sequence/entity IDs','Validated world state/events','Malformed/overspeed/outdated intent:reject và đếm metric','Sửa HP/mana/position trên client không thay state server.','T04-SV,T05-SV',rule='BR-02,BR-04')
req('SV-003','World','Replication','AOI','Lọc trạng thái theo vùng quan tâm','Grid AOI bán kính12tile + hysteresis2tile; gửi bản thân/entities công khai; inventory/ẩn/GM không broadcast; mỗi map≤20người.','Entity positions/permissions','Per-client view','Không gửi trạng thái private kể cả full join snapshot','Packet inspection không thấy túi đồ người khác hoặc entity ngoài AOI.','T04-SV,T12-SV')
req('SV-004','World','Transfer','Map handoff','Chuyển map không trùng nhân vật','Reserve slot đích, đóng băng map nguồn, commit lease/version, persist checkpoint, join đích; lỗi trả về safe spawn đã lưu.','Portal, character lease','Destination session/snapshot','Target full, process crash, token replay:abort/recover','Kill process ở từng bước: tối đa1writer; không mất bag/đổi tiền.','T03-SV,T12-SV',rule='BR-21',uc='UC-11')
req('SV-005','Combat','Resolver','Combat service','Giải quyết cast và trạng thái','Check ownership/equip/rank/hunger/range/LOS/alive/mana/cooldown; mana và cooldown tiêu khi cast được accept; hủy sau accept vẫn tiêu.','Cast intent/configVersion','Cast result; state delta','CC hoặc target invalid trước accept:không tiêu; server clock quyết định','10negative cases mỗi primitive bị chặn; 1cast không gây hit trùng.','T05-SV,T11-SV',rule='BR-04,BR-05,BR-06',uc='UC-03')
req('SV-006','PvE','Mob','AI & spawn','AI, respawn và quyền thưởng','6normal/2elite/1boss; leash8tile; respawn normal20s/elite60s; owner là first valid hit trong encounter, reset khi leash; kill/capture độc quyền.','Spawn ID, damage events','AI state; durable reward intent','Owner disconnect vẫn giữ10s; sau đó reset nếu không combat','Leash heal/reset đúng; hai kill callbacks chỉ một terminal transition.','T06-SV,T08-SV',rule='BR-08,BR-11')
req('SV-007','Persistence','Character','Save service','Lưu bền vững và checkpoint','Bag/currency/quest/craft/claim ghi transaction trước ACK; vị trí/HP/hunger checkpoint≤30s, logout flush; crash hồi vị trí an toàn nếu cần.','Commands/snapshots','Committed version/receipt','DB lỗi: không ACK thành công, không cấp thưởng trước commit','Kill/restart sau ACK: item/tiền còn đúng; vị trí có thể rollback≤30s.','T07-SV,T12-SV',rule='BR-14,BR-21')
req('SV-008','Economy','Atomic command','Command service','Ledger và idempotency','Unique(characterId,requestId); lock character→items tăng theo ID; validate version; tạo receipt/RNG/ledger trong cùng transaction; giữ receipt≥30ngày.','Request UUID, expectedVersion','Same immutable receipt','Cùng ID payload khác trả409; deadlock retry bounded cùng ID','20retry/2socket của craft, buy, feed chỉ một hiệu lực; ledger cân đối.','T07-SV,T09-SV,T10-SV',rule='BR-14',uc='UC-07')
req('SV-009','Inventory','Overflow','Reward inbox','Reward inbox khi đầy túi','Chỉ server tạo reward inbox persistent;100entry/account; không hết hạn alpha; claim nguyên tử nếu đủ ô; đầy inbox dừng nguồn reward và cảnh báo.','Reward receipt, claim request','Inbox entries/items','Inbox đầy không âm thầm xóa; dungeon entry bị chặn nếu thiếu capacity','Bag đầy khi kill: reward còn trong inbox sau reconnect, claim1lần.','T07-SV,T10-CL',rule='BR-09')
req('SV-010','Cổ trùng','Capture/feed','Gu service','Săn bắt và hunger server','Claim spawn chống race; roll70% sau channel; tiêu seal khi start; hủy không refund; hunger elapsed online dùng serverTime, inventory không equipped không giảm.','Capture/feed intents; timers','Gu instance/hunger receipt','Capture successful commit rồi spawn remove; DB fail phục hồi terminal pending','Feed/reconnect không reset timer để né đói;0hunger khóa active/passive.','T08-SV',rule='BR-11,BR-12')
req('SV-011','Cổ trùng','Refining','Recipe service','Công thức, pity và roll server','Pity theo character+recipe; chance=min(100,70+10×fails); RNG server và kết quả lưu transaction; success reset fails=0; fail giữ input.','Recipe/input IDs/configVersion','Outcome/output/pity/ledger','Stale preview config trảCONFIG_CHANGED trước consume; reuse input đồng thời bịlock','Không output khi rollback; success tiêu2Gu; fail giữ2Gu; cả2mất material/fee.','T09-SV',rule='BR-13,BR-14')
req('SV-012','Progression','Quest/XP','Progress service','XP, quest và rank-up từ event server','Event ID unique; XP cumulative curve; quest chỉ event server; reward và claim cùng transaction; rankII unlock validate toàn bộ điều kiện.','Trusted gameplay event/claim','Level/quest/rank receipt','Event ID lặp bỏ qua; client tự gửi kill count bịreject','Replay100event không tăng progress lần2; rank-up chỉ một phí.','T10-SV',rule='BR-15,BR-16')
req('SV-013','Xã hội','Party/chat','Social service','Party và recipient authorization','Membership unique; leader state; invite TTL; text sanitize/escape; channel kiểm tra membership; persist report không lưu token/password.','Invite/chat/report','Roster/message/report','Kick/leave làm mất quyền party ngay; message rate limited','User ngoài party không nghe/đọc được party channel; invite replay vô hiệu.','T13-SV,T16-SV',rule='BR-17,BR-18')
req('SV-014','PvE/PvP','Instances','Instance service','Dungeon và duel state machine','Dungeon:created→ready→running→won/failed→closed; arena tương tự; fixed roster; key(runId,charId,rewardType) unique.','Entry/ready/timers/combat','Run/match state; receipts','Boss reward pending được retry; đấu trường disconnect30s thua; không rank rewards','Repeated completion không cấp thêm loot; orphan rooms cleanup≤60s.','T14-SV,T15-SV',rule='BR-19,BR-20',uc='UC-13,UC-14')
req('SV-015','Content','Configuration','Catalog pipeline','Data-driven và config version','Gu/item/mob/map/quest/recipe bằng JSON/CSV có schema; build kiểm tra foreign keys; publish immutable version; room đang chạy giữ version cũ tới restart.','Validated catalog/version','Immutable bundle; validation report','Recipe input/output thiếu:fail build; không hotpatch giữa craft','1cấu hình lỗi bị chặn; rollback về version trước khôi phục đúng catalog.','T11-SV,T16-SV')
req('SV-016','Vận hành','Telemetry','Metrics/logs','Metrics, log và economy events','Theo dõi CCU/map, tick p95, intent rejection, DB latency, duplicate request, source/sink, funnel tutorial; correlationID xuyên command; không log secret.','Server events/counters','Dashboard/logs/export','Log endpoint không public; không dùng analytics làm nguồn inventory','Tra một craft receipt thấy request/ledger/config; có alert DB unavailable/tick trễ.','T16-SV,T17-SV')
req('SV-017','Vận hành','Deploy/restore','Private alpha','Backup, restore và rollback','Private staging/local trước; daily DB snapshot + trước release; giữ7daily/4weekly; restore diễn tập; schema migration tương thích rollback.','DB backup/tag/runbook','Restore report/release tag','Không restore đè môi trường live khi chưa cô lập; go/no-go khi NFR fail','Restore vào DB rỗng đạt RTO≤2h/RPO≤24h; restart crash khác disaster restore.','T16-SV,T18-SV')
req('SV-018','Bảo vệ','Validation','Protocol guard','Schema, quota và session fencing','Mọi message schema allowlist, max payload8KB; intents ≤20/s burst40; cast theo cooldown; thiếu auth reject; lease token chống2writer.','Token/payload/sequence/lease','Authorized validated command','Stale lease/oversize/message lạ:reject, audit, close nếu spam','Fuzz malformed không crash; stale room không ghi DB; người chơi không vào GM API.','T03-SV,T17-SV',rule='BR-01,BR-14,BR-18')

req('AD-001','GM','Quyền truy cập','Admin login','Đăng nhập GM và RBAC','Role GM_READ, GM_MOD, GM_OWNER; chỉ OWNER cấp role; kiểm tra server từng endpoint; tài khoản game không mặc định vào admin.','Admin credentials/role','Authorized admin session','403 dù client tự sửa role; revoke có hiệu lực khi gọi tiếp','Player và GM_READ không ban/grant; mọi thao tác đặc quyền có audit.','T16-CL,T16-SV')
req('AD-002','GM','Tra cứu','Player detail','Tra cứu nhân vật và receipt','Tìm theo characterId/name; xem level/rank/bag/loadout/ledger/quest/session; read-only; che thông tin nhạy cảm.','Search/filter/page','Paginated profile/log','Không tìm thấy:empty; không hiển thị password/token','GM_READ xem được lịch sử craft bằng requestId mà không sửa dữ liệu.','T16-CL,T16-SV')
req('AD-003','GM','Kiểm duyệt','Moderation','Mute/ban và xử lý report','GM_MOD mute/ban có lý do, thời hạn; kick session active; report kèmmessageID; unban có audit.','Target, action, reason, expiry','Moderation record/session revoke','Reason rỗng/expiry sai:reject','Banned không join lại; mute không gửichat; hết hạn tự gỡ.','T16-CL,T16-SV')
req('AD-004','GM','Hỗ trợ','Grant item','Cấp vật phẩm có kiểm soát','OWNER grant theo catalog/qty; lý do bắt buộc; preview; unique requestId; server gửi inbox khi bag đầy; không edit DB trực tiếp.','Character, item, qty, reason, UUID','Grant receipt/audit/inbox','GM_MOD bị403; ID lặp không cấp thêm','Grant bị lặp chỉ1receipt; tra được người làm/lýdo/giá trịtrước-sau.','T16-CL,T16-SV',rule='BR-14')
req('AD-005','GM','Cấu hình','Publish','Publish/rollback config qua pipeline','OWNER chọn bundle đã validate; staging smoke; alpha restart có thông báo; lưu version trước/sau và actor.','Bundle version/change reason','Published config/audit','Bundle lỗi chưa validate không publish','1invalid foreign key chặn publish; rollback dùng bundle bất biến.','T16-SV,T18-SV')
req('AD-006','GM','Giám sát','Dashboard','Dashboard vận hành tối thiểu','Trang read-only sốCCU/map, errors, tick, DBhealth; export report alpha; dùng dashboard sẵn có hoặc trang đơn giản.','Time range/server stats','Dashboard/export','Không có metrics hiệnNo data; không hiện0giả','DB mất kết nối hiện cảnh báo trong60s; sốCCU khớpactive lease.','T16-CL,T16-SV')
req('AD-007','GM','Audit','Audit log','Audit bất biến qua API','Actor/action/target/reason/requestId/timestamp/before-after; quyền read phân vai; không có API xóa hoặc sửa audit; chỉ masksecret.','Privileged commands','Append-only audit records','Audit ghi lỗi: đặc quyền thất bại cùng transaction','Ban/grant/role/config đều có log; GM không xóa được qua API.','T16-SV')

NFR = [
 ('NFR-01','Client performance','Godot PC Windows foreground; scene tham chiếu20player+50mob+VFX vừa;1366×768 low; máy i5-8250U/8GB/UHD620 hoặc máy đội chốt S01','Sau warmup2phút đo5phút: FPS trung vị≥50; frame time p95≤33ms; máy thực tế phải ghi rõ','T01-CL,T17-CL,T17-GD','Perf capture, engine/OS/hardware/build ID'),
 ('NFR-02','Realtime latency','Máy test cùng khu vực; RTT giả lập100ms, jitter20ms, packet loss1%; input hợp lệ không rate-limit','Command ACK p95≤250ms; correction không xuyên tường; báo riêng RTT và xử lý server','T04-SV,T17-SV,T17-GD','10.000intent; latency distribution'),
 ('NFR-03','Capacity alpha','50CCU tổng1shard;≤20player/maproom;50mob hoạt động/map; instance roster≤3; 50bots2giờ có cast/loot/craft','Simulation20Hz: tick duration p95≤40ms; không disconnect do quá tải; memory không tăng không giới hạn; p95DBcommand≤200ms','T17-SV,T17-GD','Ghi CPU/RAM/server config; đây là mục tiêu kiểm thử, chưa là benchmark'),
 ('NFR-04','Tài sản bền vững','Inventory/tiền/quest/reward/craft đã ACK commit; position/HP/hunger checkpoint30s','Crash process: mất0giao dịch đã ACK; vị trí có thể lùi≤30s;20retry cùng ID đúng1hiệu lực','T07-SV,T09-SV,T12-SV,T17-SV','Fault injection trước/sau commit và trước/sau ACK'),
 ('NFR-05','Access/security','Auth/game/admin API; token hết hạn; account khác; sửapayload; spam; XSS chat','100% negative matrix bắt buộc bị chặn; không secret trong log; không client-authoritative reward; 0lỗi P0/P1 auth/dupe','T02-SV,T16-SV,T17-SV','Danh sách test và evidence; không gọi là chứng nhận bảo mật'),
 ('NFR-06','Backup/disaster','Snapshot hằng ngày + trướcrelease; giữ7daily/4weekly; restore vào môi trường cô lập','RPO≤24h; RTO≤2giờ trong diễn tập; item/ledger đối chiếu khớp backup; khác crash checkpoint','T16-SV,T18-SV','Log thời điểm snapshot, mất dữ liệu giả lập và hoàn tất restore'),
 ('NFR-07','Compatibility','Godot native Windows10/11;1366×768/1920×1080; keyboard+mouse; Web export kiểm chứng riêng','Login→quest→craft→dungeon chạy trên Windows10/11; UI không chặn nútchính; version ghi trong báo cáo','T17-CL,T17-GD','OS/engine matrix; Web là spike, chưa cam kếtmobile/nativeMac/Linux'),
 ('NFR-08','Asset budget','PC cold start; content shell+town không tính engine; Web spike qua mạng20Mbps;cache cold; không tính thời gian nhập password; lazyload farm/dungeon','Initial compressed payload≤25MB; interactive p95≤15giây trên10lượt; asset progress/failure retry có UI','T02-CL,T17-CL,T17-AR','Network waterfall; dung lượng bundle; ngân sách cần kiểm chứng S01'),
 ('NFR-09','Maintainability','Client/server/shared-content tách rõ; server không import UI; config cóschema và version','CI chặn typecheck/build/schema/transaction tests fail; dev mới chạylocal theoREADME≤60phút','T02-SV,T11-SV,T16-GD','Clean-machine setup run; dependency graph review'),
 ('NFR-10','Observability','Auth/room/cast/craft/inventory/admin; mỗicommand cócorrelationID','Tra1receipt tìm đủ configVersion/outcome/ledger; alert DBunavailable hoặc tickoverrun trong60giây; log không secret','T16-SV,T17-SV','Dashboard capture; trace một happy và một failed command'),
 ('NFR-11','UX và readability','10tester chưa được hướng dẫn; lowgraphics và mute; skillerrors vàtelegraphs','≥8/10tự di chuyển/chọn/đánh trong3phút;5/5telegraph kiểm tra có shape/icon ngoài màu; scale chữ≥14px ở1366×768','T03-GD,T16-AR,T17-GD','Quan sát task completion; note lý do thất bại'),
 ('NFR-12','Release gate','Feature freeze; E2E,dupe,security,load,restore;5gate cóbiên bản','0P0/0P1;100%Must có ít nhất1testpassed với evidence;Should cóknownissues; build/config/schema tags và rollback runbook','T16-GD,T17-GD,T18-GD,T18-SV','Go/no-go checklist; chưa cótestnào được đánh dấupassed trongbảnkếhoạch'),
]

RULES = [
 ('BR-01','Identity','1 account→1 character; mỗi character chỉ1write lease; têntrim/casefold đểso trùng;3–16ký tự.','Tấtcảsession/room/admin validateownership server.','CL-001,CL-002,SV-001,SV-018'),
 ('BR-02','Tọa độ','Logic dùngworldtile float; iso sx=(x−y)×32,sy=(x+y)×16, tile64×32; collision/nav không dựa pixelcamera.','Speed3tile/s; serverpath vàsweptcollision; AOI12tile+hysteresis2.','CL-003,CL-004,SV-002,SV-003'),
 ('BR-03','Loadout','4active rankI;2passive rankII; không trùngguDef; đổi ởsafezone và ngoài combat5s; khôngđổi arena.','RankII unlock vàhunger≥1; passivengủ khôngtácdụng.','CL-007,CL-015,CL-020'),
 ('BR-04','Damage','Damage=max(1, floor((basePower+0.8×attack)×rankFactor×hungerFactor×100/(100+defense)×modeFactor)); rank I=1.0 / rank II=1.25; modeFactor PvP=0.7.','Heal/shield=floor((basePower+0.5×attack)×rankFactor×hungerFactor); không crit/RNG damage alpha; shield hấp thụ trước HP, tổng cap40% maxHP.','CL-008,SV-005'),
 ('BR-05','Mana','Cost=ceil(maxMana×costPct/100); baseMaxMana100; hồi2mana/s ngoài combat5s,1mana/s trongcombat; HPkhông tựhồi trongcombat.','Acceptedcast tiêu mana+cooldown; rejectedcast khôngtiêu; interrupt sauaccept khôngrefund.','CL-009,SV-005'),
 ('BR-06','Status','Slow cùngtype lấy mạnhnhất, khôngcộng; stunrefresh lấyendTimemax, cap2s PvP; shieldcùngsource refresh, khácsource tổngcap40%maxHP.','Timer dùngservertime; buffpassiveunique theoeffectgroup; dispelgỡdebuff hợp lệ.','CL-010,SV-005'),
 ('BR-07','Death','PvEdeath:5s→safespawn fullHP/mana; penalty=min(50,floor(balance×0.05)); noXP/Gu/itemloss.','Arenadeath khôngpenalty; battleterminaluniquedeathID.','CL-011,SV-007'),
 ('BR-08','Loot','Openworldencounter owner=firstvalidhit; lock đếnkill/capture/leash; ownerdisconnect10s rồi reset nếu khôngcombat; reward personal.','Khi kill cùnglúc capture chỉterminaltransitionđầu thànhcông; loot khôngrơi đất alpha.','CL-012,SV-006'),
 ('BR-09','Bag','30 slot; material/food/seal stack99; Gu unique1 slot; tất cả Gu bound; equipped vẫn chiếm ô bag, loadout là reference; reward overflow→inbox100 entry, không expire alpha.','Túi/inbox đều đầy chặn nguồn reward mới có cảnh báo; buy/feed/craft capacity validate trước random.','CL-013,CL-022,SV-009'),
 ('BR-10','Gu instance','Fields:owner,definition,rank,hunger,locked,bound,equippedSlot,version; locked/equipped khôngbán/luyện.','InputinstanceIDs khácnhau; thao tácownership/type/rank/version server.','CL-014,CL-015,CL-018'),
 ('BR-11','Capture','Capturable spawn HP≤30%,range≤3tile,owner=you,seal≥1,slotavailable; channel2s;70%roll; nhận damage/hết range thìhủy.','Sealmất khistartaccepted, hủy/fail khôngrefund;spawnclaim exclusive; successspawnremoved+createGu.','CL-016,SV-006,SV-010'),
 ('BR-12','Hunger','100start; equippedonline giảm1/5phút; offline hoặc un-equipped dừng; 1–19 damage/heal/shield output×0.8;0ngủ khóaactive/passive.','Foodđúngtype+40cap100;khôngchết/khôngphạt offline; cooldown/mobility/CCdurationkhôngnhân0.8.','CL-017,SV-010'),
 ('BR-13','Refine','2CổI +vậtliệu +fee→CổII; rate=min(100,70+10×recipeFailCount)%; successconsume2Gu/resetpity; failgiữ2Gu/tăngpity.','Cảhairesulttiêu vậtliệu+fee;requestUUIDlưuRNG/receipt;outputbound; khôngrerollvìretry.','CL-018,CL-019,SV-011'),
 ('BR-14','Atomic economy','Mỗi command economic cóUUID+expectedVersion; lockcharacter vàitemIDs tăngdần; validate→roll→writeall→receipt→commit→ACK.','Unique(character,requestId);payloadkhácsameID409;deadlockretry3lầnbounded;receipt30ngày.','SV-007,SV-008,AD-004'),
 ('BR-15','Progression','XPcum(L)=50×(L−1)×L; L1=0,L10=4500,L20=19000; attack=10+2×(L−1); defense=5+(L−1); HP=200+20×(L−1).','RankII:level10,Q08claimed,500currency+10MAT-02;rankfactorảnhhưởngdamagekhôngnhânmọistat.','CL-020,SV-012'),
 ('BR-16','Quest','Locked→available→active→completed→claimed; eventunique; Q01–Q08chínhmởrankII;Q09craftII;Q10dungeon đượcđặtlại2questphụ trongcatalog.','Questrewardđảm bảoXPsum đủlevel10 trướcQ08; khôngtạovòngcraftII→rankII prerequisite.','CL-021,SV-012'),
 ('BR-17','Party','1–3người;1membership/person;inviteTTL30s;leaderchuyểnngườivàosớmnhất; rostersnapshot khienterdungeon.','Khôngchoinvite/kick giữa runningdungeon;disconnectedgrace30s giữslot.','CL-023,SV-013'),
 ('BR-18','Chat/quotas','Chat200ký tự,2/sburst4;gameintent20/sburst40;payload8KB; channelszone/party; sanitizecontrolchars vàescaperender.','Mute/ban server;localmute khôngđổiquyền; khônglogpassword/token.','CL-024,SV-013,SV-018'),
 ('BR-19','Dungeon','1–3ngườilevel10rankII;portalready;15phút;boss2pattern;rewardmỗicharacter1lần/run;wiperespawnentry,timeoutfail.','Disconnect≤30srejoinrun;hếtgrace vềtown,quyềnrewardtheoroster+participationdamage/heal≥1event.','CL-025,SV-014'),
 ('BR-20','PvP','Onlyarenaopt-in;match180s;damagefactor0.7;stun≤2s;countdown3s;hếtgiờhòa;disconnect>30sthualuật;nomoney/lootreward.','NoopenworldPK/full-loot alpha; khôngfarmthưởnghoặcmấtitem trongarena.','CL-026,SV-014'),
 ('BR-21','Recovery','Grace30s;singlewriterleaseTTL30s/renew10s,fencingcounterDB;checkpointposition/HP/hunger30s;economiccommitbeforeACK.','Expiredlease khôngghi;newroomkhôi phụcstatebềnvững; maptransferreserve/commit/abort cóexpiry.','CL-006,CL-027,SV-004,SV-007'),
]

SCOPE = [
 ('SC-01','Nền tảng','MVP','Godot native PC Windows, keyboard+mouse; UI tiếng Việt','User yêu cầu Godot/implement; Web spike tiếp theo, mobile sau alpha','G1'),
 ('SC-02','Quy mô','MVP','Closed alpha 20tester; mục tiêu test50CCU/shard và20người/map','Mục tiêu đểđo, chưacam kếtMMO hàngnghìnngười','G5'),
 ('SC-03','Combat','MVP','Isometric,click-to-move,4active+2passive,8effectprimitives','5Cổfirstplayable,20CổđầyđủtrướcG3','G2/G3'),
 ('SC-04','Cổ','MVP','20Cổ(10I+10II),capture,feed,refine,rankI–II','Khôngđói offline;khôngchếtCổ;recipe70%+pity','G3'),
 ('SC-05','Nội dung','MVP','3map:town/farm/dungeon;arena táidùng;6normal/2elite/1boss;4NPC;10quest','8main+2side;1avatar;biếnthểassetđểgiảmkhối lượng','G3/G4'),
 ('SC-06','Social/PvP','MVP','Party≤3,chat zone/party,1dungeon,duelopt-in1v1','KhôngmởPVPtựdo; khôngxếphạng/rewardarena','G4'),
 ('SC-07','Vận hành','MVP','Accountmời,GM,RBAC,audit,ledger,backup,restore,metrics','Khôngpayment;staginglocal trướcpublicprivatealpha','G5'),
 ('SC-08','Trading','P2','Giao dịch2người,market,bàysạp,auction','Chỉsauledger/economy/anti-dupe ổn; estimate saubeta','SauG5'),
 ('SC-09','Hardcore PK','P2','Hòabình/Tôngmôn/Đồsát,karma,drop item/Gu cóbảohộ','Khác luậtsoftalpha; cầnthửnghiệmretention vàrecovery','SauG5'),
 ('SC-10','Guild','P2','Banghội,bangchiến,côngthành','Cầntesttải,quảntrịvàthiếtkếeconomy bổsung','SauG5'),
 ('SC-11','Web distribution','P2','Web export sau khi PC ổn; Compatibility, GDScript, transport WebSocket','Spike sớm S01–S02; chưa cam kết feature parity hay ngày phát hành Web','SauPC'),
 ('SC-12','Mobile/cross-platform','P3','TouchUI,memorybudget,Android/iOS,cross-save','Thiếtkếprotocol/contentđộc lậpclient ngay;portcầnprojectriêng','SauP2'),
 ('SC-13','Massive scale','P3','Cross-server,worldboss lớn,sharding vàmulti-region','Khôngthiếtkếmicroservice/kubernetes trướcnhucầuthực','SauP2'),
 ('SC-14','Monetization','Chưa chốt','Khôngrealpayment,cashshop,gacha trálấy tiềntrongMVP','Môhìnhkinhdoanh doownerchốtsaualpha','TBD'),
 ('SC-15','Chiến lược','MVP','guided-build→first-playableG2→closedalphapolished-prototypeG5','Phạmvi sảnphẩmthửnghiệm; khôngcommerciallaunch','G5'),
]

DECISIONS = [
 ('D-01','Sốgiờmỗingười','Giả định','20h/người/tuần;4người;75%thờigianhữuích;20%dựphòng','Cảđội','S01','Chốt availability từngngười;20h làgiảđịnh,khôngphảiphản hồichínhthức'),
 ('D-02','Nền tảng đầu tiên','Theo user','Godot PC native trước theo yêu cầu triển khai mới; Web spike sớm','Owner','S01','Mobile/store/patcher/signing chưa nằm trong alpha'),
 ('D-03','Phânvai','Đề xuất','GD/QA,Client,Server/TechLead,2D/Content;cross-reviewhàngtuần','Cảđội','S01','Nếu thiếuartisthoặcbackendthìphảigiảmcontent/đổilịch'),
 ('D-04','Phạm vi alpha','Đề xuất','20Cổ/3map/1boss/party3/duel1v1','Owner+GD','S01','Cóthểcắtsocialtrước,khôngcắtatomicpersistence'),
 ('D-05','Naming/assets','Chưa chốt','GuMaster2D làtênlàmviệc;CổChânNhân/VLTK làthamchiếuthiếtkế','Owner+AR','Trướcpublicalpha','Chốt tên/nộidung/nguồnassetđượcsửdụng trướcpháthành;khôngmặcđịnhcóasset/quyềnthươnghiệu'),
 ('D-06','Engine/version','Godot theo user; backend đề xuất','Godot4.7.2/GDScript/Compatibility; headless authority; PostgreSQL qua server adapter','CL+SV','S01–S02','Engine đã chạy prototype; headless/transport/DB adapter còn phải spike; estimate cần rebaseline'),
 ('D-07','Máy tham chiếu','Giả định','i5-8250U/8GB/UHD620hoặcmáythực tếđộicungcấp','CL','S01','Khôngbenchmarkkhikhôngcómáy;ghiNFRunverifiedvàchốtlại'),
 ('D-08','Hunger/craft/death','Đề xuất khác ý tưởng','Đóionline/noGu-death;refine70%pity;PvEdeath mấtítcurrency','GD+Owner','S02','Hardcorefull-loot/offlinehungerđểP2; cầnđồngthuậntrướcbaseline'),
 ('D-09','Hosting alpha','Chưa chốt','Local/LANtrước;chỉpublicprivatealpha khicómáy/hostingđủđiềukiện','SV+Owner','S16','Ngânsách0khôngđồngnghĩa0chi phíhạtầng; khôngcamkếtfreelifetime'),
 ('D-10','Ngày bắt đầu','Minh họa','12/10/2026,thứHai;đổitạisheet00_START','Cảđội','Trướckickoff','Lịchtựdịchtheongàybắtđầu;khôngtrừngàylễ/nghỉphép'),
 ('D-11','Thời gian alpha','Giả định','36tuầnở20h/người/tuần;0P0/P1;testdatawipecóthôngbáo','Owner','G5','Alpha7ngàycuốichặng;khôngcamkếtgiữprogresssangcommercial'),
]

USE_CASES = [
 ('UC-01','Người chơi mới','Có tài khoản mời; server hoạt động','Đăng nhập → tạo tên → nhận starter kit một lần → vào thị trấn → tutorial','Tên trùng thì sửa; token hết hạn đăng nhập lại; tạo lặp trả character cũ','Character, starter receipt, tutorial step','CL-001,CL-002,CL-029,SV-001'),
 ('UC-02','Người chơi','Đã ở map, còn sống','Click nền → tìm đường → server kiểm tra → di chuyển; click target/NPC → đi vào tầm → tương tác','UI focus không di chuyển; tường/đích ngoài biên từ chối; target rời AOI bỏ chọn','Position checkpoint, selected target transient','CL-003,CL-004,CL-005'),
 ('UC-03','Người chơi','Cổ hợp lệ, đủ mana, target có quyền đánh','Chọn target → QWER → validate cast → trừ mana/cooldown → resolve hit → mob chết → reward commit → popup','Ngoài tầm/LOS không cast; full bag chuyển inbox; death event lặp bỏ qua','Combat event ID, reward receipt, ledger','CL-007,CL-008,CL-012,SV-005,SV-006'),
 ('UC-04','Người chơi','Ở safe zone, ngoài combat 5s','Mở bag → xem tooltip → lock/unlock → equip slot đúng type/rank → version mới → derived stats','Equipped hoặc locked không được bán/luyện; duplicate definition reject; stale version refresh','Gu instance, loadout, inventoryVersion','CL-013,CL-014,CL-015,SV-008'),
 ('UC-05','Người chơi','Sở hữu encounter; target capturable HP≤30%; có seal và ô','Chọn Bắt → claim spawn → tiêu seal/start 2s channel → server roll70% → commit Gu hoặc fail → receipt','Bị đánh/đi xa hủy, không refund seal; target bị giết thì một terminal winner; DB lỗi không ACK success','Spawn claim/terminal ID, Gu instance, request receipt','CL-016,SV-006,SV-010'),
 ('UC-06','Người chơi','Có Cổ và thức ăn đúng loại; hunger<100','Mở Feed → xem +40 cap100 → confirm → lock/version validate → consume food + update hunger → commit','Sai food/đã đầy/version cũ reject không consume; retry cùng UUID trả receipt cũ','Food stack, Gu hunger, ledger, receipt','CL-017,SV-008,SV-010'),
 ('UC-07','Người chơi','Đủ 2 CổI hợp lệ, material, tiền và capacity','Chọn recipe/instance → preview chance/pity/cost → confirm UUID → lock → roll → write consume/output/pity/ledger/receipt → commit → show','Fail giữ 2Gu mất material+fee; success mất2Gu; timeout query cùng UUID; config mới yêu cầu preview lại','RefineAttempt, pity, inventory, currency ledger','CL-018,CL-019,SV-008,SV-011'),
 ('UC-08','Người chơi','Quest prerequisites hợp lệ','Nhận quest → gameplay events server → đủ progress → claim reward một lần → level10/Q08 → confirm rankII','Client không gửi tăng count; Q08 cấp đủ XP/đá; thiếu500currency thì farm; rank-up retry không trừ lặp','QuestProgress, event dedupe, XP/rank ledger','CL-020,CL-021,SV-012'),
 ('UC-09','Người chơi','Đứng gần NPC shop ≤2tile','Chọn item/qty → preview giá → confirm UUID → validate tiền/slot/item → atomic buy/sell → receipt','Locked/equipped không bán; không âm tiền; bag đầy mua bị chặn; request cũ trả receipt','Inventory, soft currency, ledger','CL-022,SV-008'),
 ('UC-10','Người chơi','HP về0 ngoài arena','Death ID → khóa input → penalty một lần → chờ5s → safe respawn fullHP/mana','Reconnect giữa death tiếp tục cùng state; arena không penalty; no Gu/item drop alpha','Death receipt, currency ledger, position checkpoint','CL-011,SV-007'),
 ('UC-11','Người chơi','Session/lease đang hợp lệ','Portal: reserve đích → freeze nguồn → commit lease/checkpoint → join đích; reconnect: grace30s → auth → snapshot','Đích đầy abort về nguồn; process crash recovery từDB; lease cũ không ghi; pending economic query receipt','Lease/fencing, transfer record, committed inventory','CL-006,CL-027,SV-004,SV-007'),
 ('UC-12','Người chơi/leader','Chưa ở party hoặc là leader','Mời → accept trong30s → roster tối đa3 → chat đúng channel → leave/kick → đổi leader nếu cần','Accept2invite cùng lúc chỉ1membership; không kick/invite khi dungeon running','Party/member records; chat/report metadata','CL-023,CL-024,SV-013'),
 ('UC-13','Party leader/1–3 người','Level10/rankII; ở portal; đủ inbox capacity','Leader enter → all ready → fixed roster → run15min → né2pattern boss → win → personal reward commit → return','Wipe hồi entry; hếtgiờ fail; disconnect>30s vềtown; completion lặp không thêm reward','DungeonRun, roster, participation, reward receipt','CL-025,SV-014'),
 ('UC-14','Hai người chơi','Không ở dungeon/arena; cùng đồng ý','Invite → accept → ready10s → countdown3s → combat180s → death/timeout/disconnect → result → safe return','Hết giờ hòa; disconnect>30s thua; double disconnect hòa; không tiền thưởng/drop/rank','Match result, roster snapshot','CL-026,SV-014'),
 ('UC-15','GM','Role đủ quyền','Login GM → tra character/receipt → chọn mute/ban/grant → lý do + preview → confirm → audit + action atomic','Không role403; grant retry cùngID không cấp lại; audit fail thì action rollback','AdminAction, moderation, grant receipt','AD-001,AD-002,AD-003,AD-004,AD-007'),
 ('UC-16','Server owner','Có snapshot và môi trường restore cô lập','Chọn snapshot/tag → restore DB rỗng → migrate tương thích → verify ledger/items → smoke → đo RPO/RTO → lưu báo cáo','Restore fail không chuyển traffic; rollback app cần schema tương thích; không xóa snapshot nguồn','Restore log, checksums/row counts, report','SV-017,NFR-06'),
]

DATA = [
 ('Account','account_id PK; username UNIQUE; password_hash; status; token_version','1:1 Character; 1:N Session','SV','Không lưu plaintext password; account mời alpha'),
 ('Character','character_id PK; account_id UNIQUE FK; normalized_name UNIQUE; level; rank; xp; currency; inventory_version','1:N GuInstance/InventoryStack/QuestProgress','SV','Currency≥0; level1..20; rankI/II; balance thay đổi qua ledger'),
 ('SessionLease','character_id PK/FK; session_id; room_id; fencing_counter; expires_at','1:1 active Character writer','SV','Renew10s/TTL30s; UPDATE phải kiểm fencing; revoke khi ban'),
 ('CharacterSnapshot','character_id PK; map_id; position; hp; mana; hunger_clock; checkpoint_at','1:1 Character','SV','Checkpoint≤30s; economic assets không dựa snapshot này'),
 ('InventoryStack','stack_id PK; character_id FK; item_def_id; qty; bag_slot; version','N:1 ItemDefinition','SV','Qty1..99; UNIQUE(character,bag_slot); Gu không dùng stack'),
 ('GuInstance','gu_id PK; character_id FK; gu_def_id; hunger; locked; bound; bag_slot; version','N:1 GuDefinition; 0..1 LoadoutSlot','SV','Hunger0..100; unique slot chung bag; equipped vẫn chiếm ô bag'),
 ('LoadoutSlot','character_id FK; slot_no; gu_id UNIQUE FK','PK(character_id,slot_no); 1:N Character','SV','Slot1..4 active;5..6 passive rankII; unique definition per loadout validate transaction'),
 ('CommandReceipt','character_id FK; request_id; payload_hash; kind; config_version; result; committed_at','UNIQUE(character_id,request_id)','SV','Result immutable≥30ngày; sameID khácpayload409; recovery qua receipt'),
 ('EconomyLedger','entry_id PK; character_id; request_id; asset_type; asset_id; delta; reason; balance_after','N:1 CommandReceipt hoặc trustedRewardReceipt','SV','Append-only quaAPI; atomic với balance/item; không dùng log analytics làm source of truth'),
 ('RefineAttempt','attempt_id PK; character_id; recipe_id; input_ids; roll; chance; outcome; request_id UNIQUE','N:1 RecipeDefinition/CommandReceipt','SV','Persist RNG cùng consume/output; không expose RNG seed client'),
 ('RecipePity','character_id; recipe_id; fail_count; version','PK(character_id,recipe_id)','SV','0..3 đến100%; success reset0; không share giữa recipe'),
 ('QuestProgress','character_id; quest_id; state; progress; claimed_at; version','PK(character_id,quest_id)','SV','Trusted event dedupe; claimunique; reward cùngtransaction'),
 ('ProcessedEvent','character_id; event_id; event_type; created_at','UNIQUE(character_id,event_id)','SV','Chống event quest/XP/reward lặp; retention ít nhất vòngđờialpha'),
 ('RewardInbox','entry_id PK; character_id; source_run; reward_payload; claimed_at','1:N Character; unique source/key','SV','100entry max; noexpiry alpha; claimatomic và slotcheck'),
 ('Party/PartyMember','party_id PK; leader_id; status; member character_id UNIQUE; joined_at','Party1:N Member≤3','SV','Party state cóthểmemory; membership snapshot durable khivàodungeon'),
 ('DungeonRun/Match','run_id PK; kind; roster; state; start/end; config_version; result','1:N Participation/RunReward','SV','Terminalstatewriteonce; reward UNIQUE(run_id,character_id,type)'),
 ('SpawnTerminal','spawn_id PK; encounter_owner; terminal_kind; reward_request_id; status','Kill/capture mutually exclusive','SV','Persist terminal reward intent trướcACK; recovery pending saucrash'),
 ('MapTransfer','transfer_id PK; character_id; source; target; lease_version; state; expires_at','1:1 active transfer percharacter','SV','Reserve/commit/abort; expiry cleanup; idempotent join'),
 ('Moderation/Report','report_id; message_id; actor/target; reason; action; expires_at','N:1 Account; moderation record','SV','Mute/ban cóexpiry; evidence khôngchứasecret'),
 ('AdminAudit','audit_id PK; actor; role; action; target; reason; request_id; before_after; created_at','N:1 AdminAccount/CommandReceipt','SV','KhôngAPIupdate/delete; rolechecked; masksecret'),
 ('ContentBundle','version PK; hash; schema_version; gu/item/mob/map/recipe/quest definitions','Immutable; all FK validate buildtime','CL+SV+GD','Runtime pin bundle; khôngđổi config giữacraft; sourceJSON/CSV'),
]

API = [
 ('API-01','HTTPS','POST /auth/login','Public mời','username,password','sessionToken,expiresAt','AUTH_FAILED/RATE_LIMIT','SV-001,CL-001'),
 ('API-02','HTTPS','POST /characters','Account owner','name,avatar,requestId','characterId,starterReceipt','NAME_TAKEN/ALREADY_EXISTS','CL-002,SV-001'),
 ('API-03','HTTPS','GET /characters/me','Account owner','session token','profile,bag,loadout,quest,version','401/403','SV-007'),
 ('API-04','HTTPS','GET /config/:version','Authenticated','version/hash','immutable catalog bundle','CONFIG_NOT_FOUND','SV-015,CL-030'),
 ('API-05','Room','joinMap','Character owner','mapId,sessionToken,leaseToken','snapshot,selfID,configVersion','AUTH_REQUIRED/MAP_FULL/STALE_LEASE','SV-001,SV-003,SV-004'),
 ('API-06','WS','moveIntent','Active room lease','seq,destX,destY','path/correction,serverTime','BAD_PATH/OVERSPEED/STALE_SEQ','CL-003,SV-002'),
 ('API-07','WS','castIntent','Active room lease','seq,guId,targetId/point','castId,accepted/hit/events','NO_MANA/CD/RANGE/LOS/STUN/HUNGRY','CL-008,SV-005'),
 ('API-08','WS','equipGu','Character owner','requestId,expectedVersion,guId,slot','receipt,loadout,newVersion','BAD_SLOT/RANK/COMBAT/LOCKED','CL-015,SV-008'),
 ('API-09','WS','captureStart/cancel','Encounter owner','requestId,spawnId,sealId,version','channelId/outcomeReceipt','CLAIMED/HP_HIGH/NO_SLOT/INVALID','CL-016,SV-010'),
 ('API-10','WS','feedGu','Character owner','requestId,expectedVersion,guId,foodId','receipt,hunger,newVersion','WRONG_FOOD/FULL/NO_ITEM','CL-017,SV-010'),
 ('API-11','WS','refinePreview','Character owner','recipeId,inputGuIds','cost,chance,pity,configVersion','INVALID_INPUT/LOCKED/EQUIPPED','CL-018,SV-011'),
 ('API-12','WS','refineCommit','Character owner','requestId,expectedVersion,configVersion,recipeId,inputGuIds','immutable receipt,outcome,newVersion','CONFIG_CHANGED/NO_MONEY/VERSION_CONFLICT','CL-019,SV-011'),
 ('API-13','HTTPS','GET /receipts/:requestId','Character owner','requestId','committed receipt hoặc pending/notfound','403/NOT_FOUND; khôngtựrollmới','SV-008,CL-019'),
 ('API-14','WS','questAccept/claim,rankUp','Character owner','requestId,questId/version','receipt,progress,rank/XP','LOCKED/NOT_DONE/ALREADY_CLAIMED','CL-020,CL-021,SV-012'),
 ('API-15','WS','npcBuy/npcSell','Active owner gầnNPC','requestId,npcId,item/guId,qty,version','receipt,balance,newVersion','FAR/NO_SLOT/NO_MONEY/LOCKED','CL-022,SV-008'),
 ('API-16','WS','partyInvite/accept/leave/kick','Owner/leader theoaction','requestId,targetId/inviteId','roster/invite expiresAt','FULL/EXPIRED/ALREADY_MEMBER/RUNNING','CL-023,SV-013'),
 ('API-17','WS','chatSend/report','Zone/party authorized','channel,text hoặcmessageId/reason','messageId/reportId','MUTED/TOO_LONG/RATE_LIMIT/403','CL-024,SV-013'),
 ('API-18','WS','dungeonEnter/ready','Leader/member nearportal','requestId,partyId,ready','runId,state/roster','NOT_READY/RANK/LEVEL/INBOX_FULL','CL-025,SV-014'),
 ('API-19','WS','duelInvite/accept/ready','Two opt-in players','inviteId,ready','matchId,countdown,result','BUSY/EXPIRED/DECLINED','CL-026,SV-014'),
 ('API-20','Room','reconnect/portalTransfer','Session/lease owner','reconnectToken hoặcportalId,transferId','snapshot/newLease/receipt statuses','EXPIRED/STALE_LEASE/DEST_FULL','CL-006,CL-027,SV-004'),
 ('API-21','HTTPS','GET /admin/characters, /admin/receipts','GM_READ+','query,page,filters','masked profile/history','401/403','AD-001,AD-002'),
 ('API-22','HTTPS','POST /admin/moderation','GM_MOD+','requestId,target,action,reason,expiry','auditId,actionReceipt','403/INVALID_REASON','AD-003,AD-007'),
 ('API-23','HTTPS','POST /admin/grant, /admin/config/publish','GM_OWNER','requestId,target/item/version,reason','receipt,auditId','403/INVALID_CONFIG/DUPLICATE_PAYLOAD','AD-004,AD-005'),
 ('API-24','HTTPS','GET /admin/metrics, /admin/audit','GM_READ+','range,filters,page','stats/audit list','401/403','AD-006,AD-007,SV-016'),
 ('API-25','WS','inboxList/inboxClaim','Character owner','entryId,requestId,version','inbox hoặcclaimReceipt/newVersion','NO_SLOT/ALREADY_CLAIMED/403','SV-009,CL-013'),
 ('API-26','WS','lockGu/respawn/useConsumable','Character owner/active lease','requestId,version,guId hoặcitemId','receipt,state','DEAD/NOT_DEAD/LOCKED/NO_ITEM','CL-011,CL-014,SV-008'),
]

GU = []
# name, category, primitive, target, power, mana %, cooldown s, range tiles, duration s, food, source
GU_BASE = [
 ('Nguyệt Quang Cổ','Công kích','projectile','enemy',35,8,2,6,0,'MAT-01','Starter; sói rừng'),
 ('Lôi Điệp Cổ','Công kích','aoe','ground',25,14,6,5,0,'MAT-04','Hoang Cổ ở farm'),
 ('Bạch Ngọc Cổ','Phòng ngự','shield','self',70,12,12,0,5,'MAT-02','Starter; sơn thú'),
 ('Kim Chung Cổ','Phòng ngự','buff','passive',10,0,0,0,0,'MAT-02','Hoang Cổ tinh anh; +10 defense'),
 ('Bạch Hạc Cổ','Thân pháp','dash','ground',0,10,8,3,0,'MAT-03','Starter; hạc núi'),
 ('Du Cương Cổ','Thân pháp','buff','self',20,8,10,0,4,'MAT-03','Hoang Cổ ở farm; +20% speed'),
 ('Băng Tằm Cổ','Khống chế','slow','enemy',20,10,8,5,3,'MAT-04','Starter; băng tằm; slow30%'),
 ('Hóa Thạch Cổ','Khống chế','stun','enemy',10,16,14,4,1.2,'MAT-02','Hoang Cổ tinh anh'),
 ('Hồi Xuân Cổ','Phụ trợ','heal','ally/self',65,15,12,4,0,'MAT-03','Hoang Cổ ở farm'),
 ('Địa Thính Cổ','Do thám','buff','passive',4,0,0,0,0,'MAT-01','Hoang Cổ tinh anh; minimap8→12tile trong AOI'),
]
for i, x in enumerate(GU_BASE, 1):
    GU.append((f'GU-{i:02}',x[0],'I',*x[1:], 'Nháp cân bằng — chưa playtest'))
    # Rank II also uses rankFactor 1.25. Power progression intentionally modest.
    power = round(x[4] * 1.15, 1) if x[2] not in ('dash','buff') else x[4]
    if i == 4: power=15
    if i == 10: power=4
    GU.append((f'GU-{i+10:02}',x[0]+' II','II',x[1],x[2],x[3],power,x[5]+(2 if x[5] else 0),x[6],x[7],x[8],x[9],f'REC-{i:02}', 'Cùng primitive; rankFactor1.25; tên minh họa'))
GU.sort(key=lambda x:x[0])

CONTENT = [
 ('Map','MAP-01','Thị trấn Sơn Trại','Safe zone,4NPC,spawn,training target,portal farm;64×64tile','RankI; khôngPvP','AR+GD'),
 ('Map','MAP-02','Vạn Thú Sơn','Open farm3bãi theo level;128×128tile;≤20player/room;50active mobs','Level1–20; capture; noopenPK','AR+GD'),
 ('Map','MAP-03','Di tích Bạch Cốt','Dungeon1–3;64×64tile;1boss2pattern;15min','Level10/rankII','AR+GD'),
 ('Map variant','MAP-02A','Đấu trường thử luyện','Tái dùng1vùngMAP-02,instance2người; khôngtínhmapassetmới','Opt-in; no rewards','AR+GD'),
 ('NPC','NPC-01','Dẫn lộ','Tutorial,8mainquests','Town','GD'),
 ('NPC','NPC-02','Cổ thương','Food/seal/material fixed shop','Town;shoprange2tile','GD'),
 ('NPC','NPC-03','Luyện Cổ sư','Refine/rank-up UI','Town;recipe/rank validate','GD'),
 ('NPC','NPC-04','Thủ hộ di tích','2sidequests;dungeonportal','Town/farmportal','GD'),
 ('Item','MAT-01','Thịt thú','Food meat;stack99;NPCbuy8/sell2currency','Farmnormal;GU01/GU10','GD'),
 ('Item','MAT-02','Chân Nguyên Thạch','Food mineral/refine/rank-up;stack99;buy20/sell5','Farmelite/quest;GU03/04/08','GD'),
 ('Item','MAT-03','Linh quả','Food fruit;stack99;buy8/sell2','Farmnormal;GU05/06/09','GD'),
 ('Item','MAT-04','Mật linh hoa','Food nectar;stack99;buy8/sell2','Farmnormal;GU02/07','GD'),
 ('Item','MAT-05','Tơ luyện','Refine material;stack99;buy15/sell3','Farmnormal/quest','GD'),
 ('Item','MAT-06','Tinh huyết','Refine material;stack99;buy25/sell5','Elite/boss','GD'),
 ('Item','MAT-07','Cốt phấn','Refine material;stack99;buy15/sell3','Farmnormal','GD'),
 ('Item','MAT-08','Linh thảo','Refine material;stack99;buy15/sell3','Farmnormal','GD'),
 ('Item','MAT-09','Phong ấn bắt Cổ','Captureseal;stack99;buy10/sell1;starter5','Tiêu ởcapturechannelstart','GD'),
 ('Item','MAT-10','Hồi nguyên tán','Consumable;stack99;buy10/sell2;+30mana,CD10s','Hotkey1;notusabledead','GD'),
]
for i,name in enumerate(['Sói rừng','Hạc núi','Sơn thú','Băng tằm','Độc trùng','Cốt binh'],1):
    CONTENT.append(('Mob',f'MOB-{i:02}',name,f'Normal;level{[1,3,5,7,10,13][i-1]};HP={80+40*i};damage={5+2*i};XP={10+5*i};currency={2+i};respawn20s', 'Loot roll1material60%;food25%;Gu3% khi kill; captureflag theo spawnconfig','GD+AR'))
CONTENT.extend([
 ('Mob','MOB-07','Sói đầu đàn','Elitelevel10;HP900;XP120;currency40;respawn60s','MAT-02/MAT-06;capture GU04/08/10','GD+AR'),
 ('Mob','MOB-08','Cốt vệ','Elitelevel15;HP1400;XP180;currency60;respawn60s','MAT-02/MAT-06;capture GU04/08/10','GD+AR'),
 ('Boss','BOSS-01','Bạch Cốt Dị Thú','Level15;HP6000;2pattern:cone1.2s windup,groundAoE1.8s windup;damage35/55','Personalreward200currency,300XP,3MAT-02,2MAT-06;one/run','GD+AR'),
 ('Starter','START-01','Gói khởi đầu','GU-01,03,05,07;5MAT-09;4MAT-01/02/03/04;3MAT-10;100currency','Issueonce/character;equippedGu vẫnchiếmslotbag','SV+GD'),
])
RECIPES=[]
for i in range(1,11):
    secondary=(i%10)+1
    RECIPES.append((f'REC-{i:02}',f'GU-{i:02} + GU-{secondary:02}', 'Hai instance khác nhau, rankI, unlocked/unequipped', '3 MAT-02 + 2 MAT-05',100,f'GU-{i+10:02}',70,10, 'Success mất2Gu;failgiữ2Gu;cảhai mấtmaterial+100currency'))
QUESTS=[
 ('Q-01','Main','Bước đầu','Không','Đi đến marker + nóiNPC-01',100,30,'1MAT-09'),
 ('Q-02','Main','Săn thú','Q-01 claimed','Kill3MOB-01',250,40,'2MAT-01'),
 ('Q-03','Main','Chọn Cổ','Q-02 claimed','Mởbag+equip/inspect đủ4active',450,60,'2MAT-03'),
 ('Q-04','Main','Nuôi Cổ','Q-03 claimed','Feed1Gu khi hunger<100;quest hướngdẫn farm đủ5phút',600,80,'2MAT-02'),
 ('Q-05','Main','Bắt Hoang Cổ','Q-04 claimed','Capture1spawn;starterseal+NPC mua thêm',700,100,'2MAT-02'),
 ('Q-06','Main','Khai thác tài nguyên','Q-05 claimed','Kill10normal;collect5MAT-05',800,150,'2MAT-02'),
 ('Q-07','Main','Chuẩn bị đột phá','Q-06 claimed','Giao3MAT-01+3MAT-03;previewrecipe;khôngbắtbuộccraftII',800,200,'2MAT-02'),
 ('Q-08','Main','Thử thách Cổ Sư','Q-07 claimed','Kill1MOB-07,claim đểđủXP4500/level10',800,250,'4MAT-02;unlockrank-up'),
 ('Q-09','Side','Hợp luyện lần đầu','RankII;Q-08 claimed','Craft thànhcông1CổII',300,150,'2MAT-05'),
 ('Q-10','Side','Di tích cổ','RankII;Q-08 claimed','Finish1dungeonrun',500,200,'3MAT-02'),
]

GATES = [
 ('G0',2,'Tuần4 — Baseline khả thi','FSD/WBS/luật/availability/art nguồn rõ; stack spike2client; chốt hoặc giảm scope','GD+CL+SV+AR','Không khả thi giờ/stack→cắtcontent/đổi nềntrướcG1'),
 ('G1',4,'Tuần8 — Multiplayer nền','Click/movement/auth/room/AOI;2client; rejectwarp; handoffhappy path','CL+SV;GD kiểm tra','Chưa cóauthoritative movement→khôngxâycontentthêm'),
 ('G2',6,'Tuần12 — First playable','Town/farm,5Cổ,combat,mob,loot,death;10phiên15phút; lỗi blocker0','GD;CL+SV sửa','TTK/điều khiểnkhôngổn→dùngdựphòng;giảmVFX'),
 ('G3',12,'Tuần24 — Core loop alpha','20Cổ;capture/feed/refine/equip/quest/rank;reconnect;atomic/dupetests pass','Cảđội','Ledger/dupefail→dừngsocial,fixdữliệutrước'),
 ('G4',15,'Tuần30 — Content/social đủ','Party3,chat,dungeon1boss,duel1v1;noopenworlddamage','Cảđội','Trễ>1sprint→cắtparty/dungeon/duel theo cutline'),
 ('G5',18,'Tuần36 — Closed alpha','Musttracepassed;0P0/P1;NFRload/restore/security;20tester mời; report7ngày','Owner+GD+SV','Khôngmáyhost/quáload→chỉlocal/LANalpha và ghi giới hạn'),
]

RISKS = [
 ('R-01','Thời gian kiêm nhiệm không đủ',5,5,'Giờ hữu ích <75% giả định trong2sprint;taskcarryover>20%','GD','Ghi giờ thật;giảmscope; dùngscenario10/15h;khônggiảlàmfulltime','Bỏduel/chat trước; giữcore loop vàtransaction'),
 ('R-02','Thiếu kỹ năng authoritative/backend',4,5,'SpikeS01 khôngchặnwarphoặc2socketgâydupe','SV','Spike vàpeerreview;singlewriter+transactiontrướcsocial','Thêmspike;giảmCCU/map;khôngchuyểnclientauthority'),
 ('R-03','Asset vượt sức1artist',4,4,'Danh sáchsprite>3pd/sprint;payload>budget','AR','1avatar,4facing;mirror/recolor;8primitive;tilesetdùnglại','Giảmquái6→4,Gu20→12;khôngtạo8hướngmọiloại'),
 ('R-04','Dupe hoặc mất tài sản',3,5,'Retry/killprocess cho2output hoặcACKkhôngdurable','SV','Idempotency,lock,ledger,receipt,faulttests;PKdropđểsau','BlockG3/G5;khóaeconomiccommandsnếucần;khôngxóalog'),
 ('R-05','Tải server/render không đạt',4,4,'Tickp95>40ms;FPSmedian<50ởscenechuẩn','CL+SV','AOI;spawnlimit;atlas;loadtestS04/S17;đomáythật','Giảm20→10/map,50→20CCU;phảighiNFRthayđổi'),
 ('R-06','Nuôi/luyện gây mệt hoặc bế tắc',3,4,'≥30%tester khôngtiếptụcsaucraftfail;thiếufood;questkhôngđủrank','GD','Onlinehunger;nopermadeath;pity;mainquestXP4500;3buildtests','Tăngnguồnfood;recipe100%trongtest;so sánhfunnel'),
 ('R-07','Không có tiền/máy host public alpha',4,4,'S16 chưa cóhostvàbackup ngoài máy đang chạy','SV+Owner','Local/LANtrước;ghiđiều kiệnfreeresource;chốtcashsheet','ChỉalphaLAN;khôngcamkếtinternet24/7'),
 ('R-08','Naming/asset chưa rõ nguồn dùng',3,4,'Khôngcómanifest nguồn hoặcchưa chốttênpháthành','Owner+AR','Tênlàmviệc;ghiassetlicense/source/author ngaykhiimport','Thayasset/têntrướcalpha côngkhai'),
 ('R-09','Scope nở thành MMORPG đầy đủ',5,4,'Thêmguild/auction/côngthành khichưaG3','GD','Change request phải cóeffort/owner/deps;oneinoneout','GiữP2/P3;khôngâmthầmkéodàilịch'),
 ('R-10','Một thành viên ngừng tham gia',3,5,'Vắng2tuần/khônghandoff;knowledgechỉ1người','Cảđội','README;weeklydemo;client/servercrossreview;assetmanifest','Rebaseline theo3người;giảmcontent/social;khônggiữdeadlinecũ'),
]

E2E_TESTS = [
 ('E2E-01','Tutorial→farm→feed→capture→refine→equip→fight','Nhân vật mới;testfood/timers không thay data production','Đi hết UC01–08;verifybag/currency/XP/hunger/receipt từngbước','Khôngkẹtquest;outputIIđúng;rankgatekhôngbịvònglặp','G3','CL-001,CL-016,CL-017,CL-019,CL-020,CL-021'),
 ('E2E-02','Duplicate economic commands','2socket cùngaccount;20retry UUID;payloadconflict','Buy/feed/refine/grant;timeout/resend;queryreceipt','1hiệu lực/UUID;payloadkhác409;balance/item khôngâm','G3','SV-008,SV-011,AD-004'),
 ('E2E-03','Crash transaction boundary','Faultinjection trướccommit/saucommit/trướcACK','Killserver rồi restart/queryreceipt','Trướccommitrollback; saucommitđúng1receipt;khôngreroll','G3','SV-007,SV-008'),
 ('E2E-04','Two writers/map transfer','2roomprocess;leaseexpiry;reserve/commit/abort','Killtừngbướchandoff;roomcũtiếp tụcghi','Tốiđa1writer;staleleaseblocked;bag/tiền nguyênvẹn','G3','SV-004,SV-018'),
 ('E2E-05','Capture versus kill race','2client+capturabletargetlowHP','Capturecompletevàlast-hit cùngtick;DBfaultreward','1terminaloutcome;no2Gu/noGu+killlootdouble','G3','CL-016,SV-006,SV-010'),
 ('E2E-06','Bag full và inbox full','30slotđầy;inbox99/100entry','Kill/claim/shop/craft;reconnect','Khôngmấtreward;khôngoverflow>100;claimexactlyonce','G3','SV-009,CL-013'),
 ('E2E-07','Private state và access','Tokenmissing/expired/accountkhác/GMrole','Inspectfullsnapshot/AOI;callGMgrant;partychannelngoàiđội','Rejectunauthorized;khônglộbag/private/chatparty','G5','SV-001,SV-003,SV-013,AD-001'),
 ('E2E-08','Dungeon completion retry','Party3;1disconnect;bossfinish2callback','Runwin;retryreward;rejoin vàclaim','Personalreward1lần;participationruleđúng;roomcleanup','G4','CL-025,SV-014'),
 ('E2E-09','Duel và safe zone','2accept;1disconnect;timeout;doubleDC','Đánhngoàiarena;duelchođếnterminal','OutsidePvP0damage;1result;khôngdrop/penalty;doubleDChòa','G4','CL-026,SV-014'),
 ('E2E-10','Hunger online/offline/reconnect','Equip0/1/19/20hunger;offline15min;reconnect','Serverclockadvance;feedretry;unequip;passive','Onlinechỉ1lầnelapsed;offlinestop;0khóaskill;feedcap100','G3','CL-017,SV-010'),
 ('E2E-11','Load+network degradation','50bots tổng,20/map,50mob/map;RTT100msloss1%','2giờmove/cast/loot;craftbatch;reconnect','NFR02/03/04đạt;ghiCPU/RAM/build/config vàphânphối','G5','NFR-02,NFR-03,NFR-04'),
 ('E2E-12','Restore và release rollback','Snapshotdaily+beforetag;DBrỗng','Restore;verifyrowcounts/ledger;smoke;rollbackcompatibleapp','RPO≤24h/RTO≤2h;biênbản;khôngđụngDBnguồn','G5','NFR-06,SV-017'),
]

SOURCES = [
 ('SRC-01','User request','Yêu cầu chat, 07/10/2026','Lập kế hoạch cụ thể gồm FSD và WBS; tham khảo Excel','Yêu cầu ban đầu là planning; user đã bổ sung Godot và implementation'),
 ('SRC-02','User constraint','Phản hồi chat, 07/10/2026','Khoảng4người tự phát triển, không ngân sách; PC trước, hướngđa nền tảng','Ban đầu Web PC; yêu cầu mới Godot/implement được triển khai PC native trước, giữ hướng Web'),
 ('SRC-03','Ý tưởng','Pasted text.txt (file đính kèm)','Coreloop,Gu/hunger/refine,PK/trading,techoptions,roadmap gợiý','Nội dung tham khảo; sốtuần/stack/luật không tự thành quyếtđịnh đãchốt'),
 ('SRC-04','Mẫu FSD','DAUN-FSD [EN].xlsx; Front (shopping mall)!B2:M2; Admin!B2:M2','No/Depth0–3/Function/RequirementID/Detail/Category/Importance/Linkage/Note','Thamkhảocấu trúc,khôngmangworkflowB2B/payment/Kakao sanggame'),
 ('SRC-05','Mẫu scope/QA','DAUN-FSD [EN].xlsx; Open range!B23:K23; QA From Client!A1:L1','ScopeMVP/P2; QArequesttracker','BổsungWBS/Gantt/resource/testtrace vìmẫukhôngcóWBS'),
 ('SRC-06','Godot release','https://godotengine.org/download/windows/','Godot4.7.2 stable; pin engine của prototype','Đã tải và chạy07/10/2026; không tự nâng engine'),
 ('SRC-07','Godot navigation','https://docs.godotengine.org/en/stable/classes/class_astargrid2d.html','AStarGrid2D; diagonal không cắt góc','WorldGrid dùng logical tile và sweep bổ sung'),
 ('SRC-08','Godot multiplayer','https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html','High-level multiplayer; server phải validate intent','Prototype hiện tại chơi đơn; chưa có server/network'),
 ('SRC-09','Godot Web export','https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html','WebGL2/Compatibility; GDScript; Web transport cần spike','Chưa export/test browser; không hứa ENet chạy trên Web'),
 ('SRC-10','Godot dedicated server','https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html','Headless/server export cho chặng online','PostgreSQL adapter/AOI/auth là phần dự án phải xây'),
 ('SRC-11','PostgreSQL official','https://www.postgresql.org/docs/current/explicit-locking.html','Rowlock vàdeadlock behavior','Atomicledger/idempotency làthiếtkếđềxuất;khôngphảifeaturegamecósẵn'),
]
