# GuMaster2D — Functional Specification Document

Phiên bản 0.2,07/10/2026. Đề xuất cho closed alpha 4 người; Godot PC. Đây là đặc tả để triển khai, chưa phải phần mềm đã hoàn thành.

Cấu trúc tham khảo DAUN-FSD[EN].xlsx; mở rộng AC/errors/input/output/trace. Rulebook, UC, data/API và catalog nằm trong Excel.

## CL-001 — Đăng nhập bằng tài khoản mời

**Phân cấp:** Tài khoản → Phiên chơi → Login
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Nhập username/password; xác thực server; chuyển chọn nhân vật. Không mở đăng ký công khai trong alpha.

**Input / tiền điều kiện:** Username, password

**Output / hậu điều kiện:** Session; profile

**Validation / ngoại lệ:** Sai thông tin hiển thị chung; khóa tạm sau nhiều lần sai

**Acceptance Criteria:** Tài khoản hợp lệ vào được; sai/expired không vào room.

**Trace:** WBS T02-CL, T02-SV; Test TC-CL-001; Rule Theo rulebook chung; UC UC-01

## CL-002 — Tạo và chọn nhân vật

**Phân cấp:** Tài khoản → Nhân vật → Character
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Mỗi account 1 nhân vật; đặt tên 3–16 ký tự Unicode chữ/số/khoảng trắng; trim; kiểm tra tên trùng và danh sách cấm.

**Input / tiền điều kiện:** Tên, avatar cơ sở

**Output / hậu điều kiện:** Character ID, starter kit

**Validation / ngoại lệ:** Tên lỗi/trùng; gửi lặp không tạo thêm

**Acceptance Criteria:** Hai request đồng thời chỉ tạo 1 nhân vật và 1 starter kit.

**Trace:** WBS T02-CL, T02-SV; Test TC-CL-002; Rule BR-01; UC UC-01

## CL-003 — Click-to-move isometric

**Phân cấp:** Thế giới → Điều khiển → World
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Click trái nền gửi đích; client tìm đường A* trên nav grid; server xác nhận đường/tốc độ; hỗ trợ hủy bằng click mới.

**Input / tiền điều kiện:** Tọa độ world, sequence

**Output / hậu điều kiện:** Path, vị trí render

**Validation / ngoại lệ:** Đích ngoài map/tường: hiện marker không đi được

**Acceptance Criteria:** Đi quanh vật cản; click liên tục không xuyên tường; UI click không di chuyển.

**Trace:** WBS T03-CL, T04-SV; Test TC-CL-003; Rule BR-02; UC UC-02

## CL-004 — Camera và depth sorting

**Phân cấp:** Thế giới → Camera → World
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Camera bám nhân vật trong biên map; render theo ground Y + layer; props cao che đúng; không xoay camera.

**Input / tiền điều kiện:** Player/world position

**Output / hậu điều kiện:** View port và thứ tự sprite

**Validation / ngoại lệ:** Resize vẫn giữ nhân vật trong khung

**Acceptance Criteria:** Đi sau/trước 10 props không đảo layer; 1366×768 và 1920×1080 dùng được.

**Trace:** WBS T02-CL, T03-CL, T03-AR; Test TC-CL-004; Rule Theo rulebook chung; UC Luồng chuyên biệt trong FSD

## CL-005 — Chọn và tương tác mục tiêu

**Phân cấp:** Thế giới → Mục tiêu → World
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Click quái chọn; click NPC trong 2 tile mở tương tác; click xa tự đi đến; vòng chọn và HP mục tiêu.

**Input / tiền điều kiện:** Entity ID

**Output / hậu điều kiện:** Target panel/interaction

**Validation / ngoại lệ:** Target mất AOI/chết: bỏ chọn

**Acceptance Criteria:** Không mở NPC ở xa; mục tiêu biến mất không gây lỗi UI.

**Trace:** WBS T03-CL, T06-CL; Test TC-CL-005; Rule BR-02; UC UC-02

## CL-006 — Minimap và cổng map

**Phân cấp:** Thế giới → Bản đồ → Minimap
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Hiện vị trí bản thân, party, NPC, cổng; dùng portal tương tác để chuyển map; không lộ entity ngoài quyền xem.

**Input / tiền điều kiện:** Map ID, portal ID

**Output / hậu điều kiện:** Minimap và loading state

**Validation / ngoại lệ:** Map đầy hoặc server lỗi: ở map cũ, báo lý do

**Acceptance Criteria:** Chuyển map không xuất hiện hai bản nhân vật; minimap đúng collision/portal.

**Trace:** WBS T04-CL, T12-CL, T12-SV; Test TC-CL-006; Rule Theo rulebook chung; UC UC-11

## CL-007 — Thanh Cổ Q/W/E/R

**Phân cấp:** Chiến đấu → Kỹ năng → Hotbar
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

4 ô active; 2 ô passive mở rank II; QWER kích hoạt; số 1 dùng vật phẩm hồi phục; remap ở settings.

**Input / tiền điều kiện:** Gu instance, hotkey, target

**Output / hậu điều kiện:** Cast request, cooldown UI

**Validation / ngoại lệ:** Chat/input đang focus không phát skill

**Acceptance Criteria:** Bốn hotkey và click đều hoạt động; skill chưa đủ điều kiện báo cùng mã lỗi.

**Trace:** WBS T05-CL, T07-CL, T11-CL; Test TC-CL-007; Rule BR-03; UC UC-03

## CL-008 — Thi triển chỉ mục tiêu/điểm đất/tự thân

**Phân cấp:** Chiến đấu → Kỹ năng → Targeting
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Cổ định nghĩa targetMode; điểm đất preview vòng AoE; Esc/hủy click; cast bar khi có castTime; server quyết định hit.

**Input / tiền điều kiện:** Gu ID, target ID hoặc world point

**Output / hậu điều kiện:** Preview, cast/hit/denied

**Validation / ngoại lệ:** Target chết/ngoài tầm/không LOS: không trừ mana

**Acceptance Criteria:** Mỗi mode ít nhất 1 skill kiểm thử; không đánh xuyên vật cản LOS.

**Trace:** WBS T05-CL, T05-SV, T11-CL; Test TC-CL-008; Rule BR-04; UC UC-03

## CL-009 — HP và Chân Nguyên

**Phân cấp:** Chiến đấu → Tài nguyên → HUD
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Hiện HP/mana số và thanh; mana cost lấy từ maxMana × cost%; server snapshot là nguồn số thật.

**Input / tiền điều kiện:** HP/mana/cost server

**Output / hậu điều kiện:** Bars, mana feed back

**Validation / ngoại lệ:** Mana thiếu: từ chối cast, không reset cooldown

**Acceptance Criteria:** UI đúng số server sau cast, hồi phục và reconnect.

**Trace:** WBS T04-CL, T05-CL, T05-SV; Test TC-CL-009; Rule BR-05; UC Luồng chuyên biệt trong FSD

## CL-010 — Buff, debuff và combat feed back

**Phân cấp:** Chiến đấu → Trạng thái → HUD
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Icon có thời gian; shield/slow/stun/heal rõ; damage number có giới hạn; telegraph không chỉ dựa màu.

**Input / tiền điều kiện:** Combat events/status endTime

**Output / hậu điều kiện:** Icon, VFX, SFX

**Validation / ngoại lệ:** Event trùng bỏ qua bằng eventId

**Acceptance Criteria:** Stun/slow đúng duration; mute tắt được audio; denied khác hit.

**Trace:** WBS T05-CL, T11-CL, T11-AR; Test TC-CL-010; Rule BR-06; UC Luồng chuyên biệt trong FSD

## CL-011 — Chết và hồi sinh

**Phân cấp:** Chiến đấu → Sinh tử → Respawn
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

0 HP khóa input combat; 5 giây rồi hồi tại safe spawn; không mất Cổ trong MVP; mất 5% tiền mềm, cap 50.

**Input / tiền điều kiện:** Death event; respawn intent

**Output / hậu điều kiện:** Respawn, penalty receipt

**Validation / ngoại lệ:** Nhấn lặp không trừ nhiều lần; đang mất mạng chờ resync

**Acceptance Criteria:** Một death chỉ một penalty; quest/Gu vẫn còn sau hồi sinh.

**Trace:** WBS T06-CL, T06-SV; Test TC-CL-011; Rule BR-07; UC UC-10

## CL-012 — Đánh quái và nhận loot

**Phân cấp:** PvE → Quái và loot → World
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Quái có cấp, HP, aggro, leash; loot cá nhân vào túi sau server commit; popup theo receipt.

**Input / tiền điều kiện:** Mob ID, combat intent

**Output / hậu điều kiện:** XP, tiền, vật liệu/Gu

**Validation / ngoại lệ:** Túi đầy không mất reward: vào reward inbox

**Acceptance Criteria:** Hai client đánh cùng quái chỉ một owner nhận reward; retry không nhân đôi.

**Trace:** WBS T06-CL, T06-SV, T07-SV; Test TC-CL-012; Rule BR-08; UC UC-03

## CL-013 — Túi 30 ô và stack

**Phân cấp:** Inventory → Túi đồ → Bag
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

30 ô; vật liệu stack 99; Gu unique 1 ô/instance; lọc Gu/nguyên liệu/vật phẩm; sort chỉ thay layout.

**Input / tiền điều kiện:** Items, slot IDs

**Output / hậu điều kiện:** Bag, count

**Validation / ngoại lệ:** Không gộp Gu instance; túi đầy báo thiếu ô

**Acceptance Criteria:** Stack 98+3 thành 99+2; không tạo/xóa item bằng sort.

**Trace:** WBS T07-CL, T07-SV; Test TC-CL-013; Rule BR-09; UC UC-04

## CL-014 — Tooltip và khóa Cổ

**Phân cấp:** Inventory → Chi tiết → Tooltip
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Hiện rank/type/mana/cooldown/food/hunger/bound; người chơi lock để chống chọn nhầm khi luyện hoặc bán.

**Input / tiền điều kiện:** Gu instance/config

**Output / hậu điều kiện:** Tooltip; lock state

**Validation / ngoại lệ:** Locked/equipped không dùng làm nguyên liệu

**Acceptance Criteria:** Tooltip khớp catalog; khóa có hiệu lực sau reconnect.

**Trace:** WBS T07-CL, T07-SV; Test TC-CL-014; Rule BR-10; UC UC-04

## CL-015 — Trang bị và tháo Cổ

**Phân cấp:** Cổ trùng → Không Khiếu → Loadout
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

4 active từ rank I; 2 passive khi rank II; không trùng definition trên cùng loadout; sửa ở safe zone và ngoài combat 5 giây.

**Input / tiền điều kiện:** Slot, Gu instance, expectedVersion

**Output / hậu điều kiện:** Loadout, derived stats

**Validation / ngoại lệ:** Sai rank/type/duplicate/đang combat: reject

**Acceptance Criteria:** Swap nguyên tử; không tồn tại 1 Gu ở 2 slot; stats không cộng lặp.

**Trace:** WBS T07-CL, T07-SV, T11-SV; Test TC-CL-015; Rule BR-03, BR-10; UC UC-04

## CL-016 — Bắt Hoang Cổ

**Phân cấp:** Cổ trùng → Săn bắt → Capture
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Quái có cờ capturable; HP≤30%; gần≤3 tile; channel 2 giây, nhận damage thì hủy; seal tiêu khi channel hợp lệ bắt đầu.

**Input / tiền điều kiện:** Spawn ID, capture seal

**Output / hậu điều kiện:** Progress; success/fail receipt

**Validation / ngoại lệ:** Túi đầy/target không hợp lệ: không bắt đầu, không tiêu seal

**Acceptance Criteria:** Hai người bắt cùng spawn chỉ một người giữ claim; chết/bắt chỉ một terminal result.

**Trace:** WBS T08-CL, T08-SV; Test TC-CL-016; Rule BR-11; UC UC-05

## CL-017 — Cho ăn và trạng thái đói

**Phân cấp:** Cổ trùng → Nuôi dưỡng → Feed
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Hunger 0–100, giảm 1 điểm/5 phút online khi equipped; offline dừng; <20 yếu đi, 0 ngủ, không chết; đồ ăn phù hợp +40.

**Input / tiền điều kiện:** Gu instance, food instance/qty

**Output / hậu điều kiện:** Hunger/stat preview; receipt

**Validation / ngoại lệ:** Sai thức ăn/đầy hunger: reject không mất đồ

**Acceptance Criteria:** Feed một lần +40 cap100; online/offline không bị tính đôi.

**Trace:** WBS T08-CL, T08-SV; Test TC-CL-017; Rule BR-12; UC UC-06

## CL-018 — Chọn công thức và preview

**Phân cấp:** Cổ trùng → Luyện chế → Refine
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

10 recipe rank I→II; chọn 2 instance Cổ khác nhau, vật liệu, tiền; hiển thị tỷ lệ hiện tại/pity và điều gì mất khi fail.

**Input / tiền điều kiện:** Recipe ID, input instance IDs

**Output / hậu điều kiện:** Preview costs/chance/output

**Validation / ngoại lệ:** Locked/equipped/sai sở hữu/rank: chặn

**Acceptance Criteria:** Preview và server dùng cùng configVersion; không có xác suất ẩn.

**Trace:** WBS T09-CL, T09-SV; Test TC-CL-018; Rule BR-13; UC UC-07

## CL-019 — Thực hiện luyện và xem kết quả

**Phân cấp:** Cổ trùng → Luyện chế → Refine result
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Server roll; base 70%, fail tăng 10 điểm phần trăm đến 100%; fail mất vật liệu/tiền, giữ 2 Cổ; success mất input và tạo 1 Cổ II.

**Input / tiền điều kiện:** Request ID, recipe, inputs, version

**Output / hậu điều kiện:** Durable receipt, pity, inventory version

**Validation / ngoại lệ:** Timeout: tra receipt/retry cùng ID; không gửi roll mới

**Acceptance Criteria:** Retry 20 lần cùng ID trả cùng kết quả và chỉ tiêu hao một lần.

**Trace:** WBS T09-CL, T09-SV; Test TC-CL-019; Rule BR-13, BR-14; UC UC-07

## CL-020 — Cấp 1–20 và Nhất/Nhị Chuyển

**Phân cấp:** Tiến triển → Cấp và rank → Character
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

XP tích lũy; rank I ban đầu, rank II cần level 10 + quest 08 +500 tiền +10 đá; mở passive và dùng Cổ II.

**Input / tiền điều kiện:** XP events; rank-up intent

**Output / hậu điều kiện:** Level/stats/slot unlock

**Validation / ngoại lệ:** Thiếu điều kiện: liệt kê thiếu; cấp 20 dừng tăng

**Acceptance Criteria:** Level 10 chưa thăng rank không trang bị Cổ II; rank-up lặp không tiêu thêm.

**Trace:** WBS T10-CL, T10-SV; Test TC-CL-020; Rule BR-15; UC UC-08

## CL-021 — 10 quest và tracker

**Phân cấp:** Nhiệm vụ → Nhận/trả → Quest log
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

8 chính +2 phụ; trạng thái locked/available/active/completed/claimed; 3 tracker; event kill/capture/feed/craft/dungeon.

**Input / tiền điều kiện:** Quest ID; gameplay events

**Output / hậu điều kiện:** Progress, reward, next quest

**Validation / ngoại lệ:** Quest item không đủ/đã claim: không nhận lại

**Acceptance Criteria:** Progress reconnect còn đúng; Q08 chỉ mở Q09 khi rank II.

**Trace:** WBS T10-CL, T10-SV; Test TC-CL-021; Rule BR-16; UC UC-08

## CL-022 — Mua/bán với NPC

**Phân cấp:** Kinh tế → NPC → Shop
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

NPC fixed price; bán vật liệu và Gu không khóa/không equipped; toàn bộ Gu bound trong MVP; không giao dịch người chơi.

**Input / tiền điều kiện:** NPC ID, item ID, qty, version

**Output / hậu điều kiện:** Preview; balance; receipt

**Validation / ngoại lệ:** Xa NPC, thiếu tiền, thiếu ô, qty sai: reject

**Acceptance Criteria:** Mua/bán concurrent không âm tiền/item; 1 receipt cho 1 request.

**Trace:** WBS T10-CL, T10-SV; Test TC-CL-022; Rule BR-09, BR-14; UC UC-09

## CL-023 — Party tối đa 3 người

**Phân cấp:** Xã hội → Tổ đội → Party
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Mời, accept/decline, kick, leave; invite TTL 30 giây; leader rời thì chuyển người vào sớm nhất; không auto-match.

**Input / tiền điều kiện:** Player ID, invite ID

**Output / hậu điều kiện:** Roster, HP, leader

**Validation / ngoại lệ:** Đầy/đã party/expired: reject không tạo hai membership

**Acceptance Criteria:** Hai invite đồng thời không làm người chơi ở2 party; thành viên 4 bị chặn.

**Trace:** WBS T13-CL, T13-SV; Test TC-CL-023; Rule BR-17; UC UC-12

## CL-024 — Chat zone/party, mute/report

**Phân cấp:** Xã hội → Chat → Chat
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Tối đa 200 ký tự/message;2 message/giây burst 4; hiển thị text escaped; local mute; report lưu bằng chứng message ID.

**Input / tiền điều kiện:** Channel, text, message ID

**Output / hậu điều kiện:** Filtered message/report ID

**Validation / ngoại lệ:** Không party không gửi party; HTML không render

**Acceptance Criteria:** Chat chỉ tới người đúng channel; gõ QWER trong chat không cast.

**Trace:** WBS T13-CL, T13-SV, T16-SV; Test TC-CL-024; Rule BR-18; UC Luồng chuyên biệt trong FSD

## CL-025 — Phụ bản 1–3 người và boss

**Phân cấp:** PvE → Phụ bản → Dungeon
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Leader tạo; mọi người level 10/rank II ở portal và ready; instance 15 phút;1 boss 2 pattern; loot cá nhân; một reward/run/character.

**Input / tiền điều kiện:** Party, ready, portal

**Output / hậu điều kiện:** Run ID, telegraph, results

**Validation / ngoại lệ:** Thiếu điều kiện từ chối cả nhóm; wipe hồi entry; hết giờ đóng

**Acceptance Criteria:** Ba người vào đúng một run; boss chết lặp không tạo thêm reward.

**Trace:** WBS T14-CL, T14-SV; Test TC-CL-025; Rule BR-19; UC UC-13

## CL-026 — PK opt-in 1v1

**Phân cấp:** PvP → Đấu tay đôi → Arena
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Hai bên accept; ready 10 giây/countdown 3 giây; trận 180 giây; stats thật, PvP damage×0.7; hòa khi hết giờ; không thưởng tiền/loot.

**Input / tiền điều kiện:** Invite, accept, loadout snapshot

**Output / hậu điều kiện:** Match state/result

**Validation / ngoại lệ:** Ngoài arena không gây damage người chơi; disconnect>30 giây xử thua

**Acceptance Criteria:** Một trận có 1 result; không mất Cổ/tiền do chết arena; loadout không sửa giữa trận.

**Trace:** WBS T15-CL, T15-SV; Test TC-CL-026; Rule BR-20; UC UC-14

## CL-027 — Mất kết nối và trở lại

**Phân cấp:** Hệ thống → Mạng → Connection
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Overlay ngay khi mất kết nối; grace 30 giây; tạm dừng input; reconnect nhận snapshot đầy đủ, receipt còn pending có thể query.

**Input / tiền điều kiện:** Reconnect token/session

**Output / hậu điều kiện:** Authoritative snapshot

**Validation / ngoại lệ:** Hết grace: login lại; không phát lại queue cast cũ

**Acceptance Criteria:** Rút mạng 10 giây trở lại cùng nhân vật; inventory không nhân đôi.

**Trace:** WBS T12-CL, T12-SV; Test TC-CL-027; Rule BR-21; UC UC-11

## CL-028 — Thiết lập PC và lưu tùy chọn

**Phân cấp:** Hệ thống → Thiết lập → Settings
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Âm lượng master/music/SFX, mute, quality low/normal, remap QWER/1; local preferences; UI tiếng Việt trước.

**Input / tiền điều kiện:** Settings values

**Output / hậu điều kiện:** Local settings

**Validation / ngoại lệ:** Trùng phím: báo và yêu cầu thay; không bind vào chat input

**Acceptance Criteria:** Reload giữ tùy chọn; trình duyệt chặn autoplay thì mở audio sau gesture.

**Trace:** WBS T16-CL, T16-AR; Test TC-CL-028; Rule Theo rulebook chung; UC Luồng chuyên biệt trong FSD

## CL-029 — 30 giây đầu và tutorial

**Phân cấp:** Hướng dẫn → First session → Tutorial
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Từ spawn an toàn: click di chuyển, Q đánh mục tiêu huấn luyện, nhặt thức ăn, mở túi; tiếp tục quest dài hơn sau đó.

**Input / tiền điều kiện:** New character, tutorial step

**Output / hậu điều kiện:** Hints, starter items

**Validation / ngoại lệ:** Bỏ qua vẫn có starter kit; reload không cấp thêm

**Acceptance Criteria:** ≥80% trong tối thiểu 10 tester hoàn thành phần điều khiển ≤3 phút không người hướng dẫn.

**Trace:** WBS T03-GD, T10-CL, T16-GD; Test TC-CL-029; Rule Theo rulebook chung; UC UC-01

## CL-030 — Danh mục Cổ và build

**Phân cấp:** Cổ trùng → Tra cứu → Codex
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

20 Cổ với rank, loại, target, mana, cooldown, thức ăn, recipe; lọc owned/all; không gợi ý build trả tiền.

**Input / tiền điều kiện:** Catalog/configVersion

**Output / hậu điều kiện:** Codex; loadout inspection bản thân

**Validation / ngoại lệ:** Config thiếu hiển thị fallback và log lỗi

**Acceptance Criteria:** 20/20 Cổ có tooltip đủ số; Cổ chưa sở hữu không equip được.

**Trace:** WBS T11-CL, T11-GD; Test TC-CL-030; Rule Theo rulebook chung; UC Luồng chuyên biệt trong FSD

## SV-001 — Xác thực và vòng đời session

**Phân cấp:** Identity → Access → Auth service
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Account mời; hash mật khẩu; session hết hạn/revoke; chỉ chủ sở hữu vào character; join room bắt buộc token hợp lệ.

**Input / tiền điều kiện:** Credentials/token

**Output / hậu điều kiện:** Session/account claims

**Validation / ngoại lệ:** Token thiếu/hết hạn/sai chữ ký:401; không tin default library

**Acceptance Criteria:** Tokenless hoặc token account khác không đọc/chơi character.

**Trace:** WBS T02-SV, T03-SV; Test TC-SV-001; Rule BR-01; UC UC-01

## SV-002 — Server giữ quyền quyết định

**Phân cấp:** World → Simulation → World room
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Client gửi intent; server tính vị trí, target, cooldown, HP, loot, RNG; simulation20Hz mục tiêu; patch10Hz ban đầu.

**Input / tiền điều kiện:** Intent sequence/entity IDs

**Output / hậu điều kiện:** Validated world state/events

**Validation / ngoại lệ:** Malformed/overspeed/outdated intent: reject và đếm metric

**Acceptance Criteria:** Sửa HP/mana/position trên client không thay state server.

**Trace:** WBS T04-SV, T05-SV; Test TC-SV-002; Rule BR-02, BR-04; UC Luồng chuyên biệt trong FSD

## SV-003 — Lọc trạng thái theo vùng quan tâm

**Phân cấp:** World → Replication → AOI
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Grid AOI bán kính 12 tile + hysteresis2 tile; gửi bản thân/entities công khai; inventory/ẩn/GM không broadcast; mỗi map≤20 người.

**Input / tiền điều kiện:** Entity positions/permissions

**Output / hậu điều kiện:** Per-client view

**Validation / ngoại lệ:** Không gửi trạng thái private kể cả full join snapshot

**Acceptance Criteria:** Packet inspection không thấy túi đồ người khác hoặc entity ngoài AOI.

**Trace:** WBS T04-SV, T12-SV; Test TC-SV-003; Rule Theo rulebook chung; UC Luồng chuyên biệt trong FSD

## SV-004 — Chuyển map không trùng nhân vật

**Phân cấp:** World → Transfer → Map handoff
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Reserve slot đích, đóng băng map nguồn, commit lease/version, persist checkpoint, join đích; lỗi trả về safe spawn đã lưu.

**Input / tiền điều kiện:** Portal, character lease

**Output / hậu điều kiện:** Destination session/snapshot

**Validation / ngoại lệ:** Target full, process crash, token replay: abort/recover

**Acceptance Criteria:** Kill process ở từng bước: tối đa 1 writer; không mất bag/đổi tiền.

**Trace:** WBS T03-SV, T12-SV; Test TC-SV-004; Rule BR-21; UC UC-11

## SV-005 — Giải quyết cast và trạng thái

**Phân cấp:** Combat → Resolver → Combat service
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Check ownership/equip/rank/hunger/range/LOS/alive/mana/cooldown; mana và cooldown tiêu khi cast được accept; hủy sau accept vẫn tiêu.

**Input / tiền điều kiện:** Cast intent/configVersion

**Output / hậu điều kiện:** Cast result; state delta

**Validation / ngoại lệ:** CC hoặc target invalid trước accept: không tiêu; server clock quyết định

**Acceptance Criteria:** 10negative cases mỗi primitive bị chặn; 1 cast không gây hit trùng.

**Trace:** WBS T05-SV, T11-SV; Test TC-SV-005; Rule BR-04, BR-05, BR-06; UC UC-03

## SV-006 — AI, respawn và quyền thưởng

**Phân cấp:** PvE → Mob → AI & spawn
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

6 normal/2 elite/1 boss; leash 8 tile; respawn normal20s/elite60s; owner là first valid hit trong encounter, reset khi leash; kill/capture độc quyền.

**Input / tiền điều kiện:** Spawn ID, damage events

**Output / hậu điều kiện:** AI state; durable reward intent

**Validation / ngoại lệ:** Owner disconnect vẫn giữ10s; sau đó reset nếu không combat

**Acceptance Criteria:** Leash heal/reset đúng; hai kill callbacks chỉ một terminal transition.

**Trace:** WBS T06-SV, T08-SV; Test TC-SV-006; Rule BR-08, BR-11; UC Luồng chuyên biệt trong FSD

## SV-007 — Lưu bền vững và checkpoint

**Phân cấp:** Persistence → Character → Save service
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Bag/currency/quest/craft/claim ghi transaction trước ACK; vị trí/HP/hunger checkpoint≤30s, logout flush; crash hồi vị trí an toàn nếu cần.

**Input / tiền điều kiện:** Commands/snapshots

**Output / hậu điều kiện:** Committed version/receipt

**Validation / ngoại lệ:** DB lỗi: không ACK thành công, không cấp thưởng trước commit

**Acceptance Criteria:** Kill/restart sau ACK: item/tiền còn đúng; vị trí có thể rollback≤30s.

**Trace:** WBS T07-SV, T12-SV; Test TC-SV-007; Rule BR-14, BR-21; UC Luồng chuyên biệt trong FSD

## SV-008 — Ledger và idempotency

**Phân cấp:** Economy → Atomic command → Command service
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Unique(characterId, requestId); lock character→items tăng theo ID; validate version; tạo receipt/RNG/ledger trong cùng transaction; giữ receipt≥30 ngày.

**Input / tiền điều kiện:** Request UUID, expectedVersion

**Output / hậu điều kiện:** Same immutable receipt

**Validation / ngoại lệ:** Cùng ID payload khác trả 409; deadlock retry bounded cùng ID

**Acceptance Criteria:** 20 retry/2 socket của craft, buy, feed chỉ một hiệu lực; ledger cân đối.

**Trace:** WBS T07-SV, T09-SV, T10-SV; Test TC-SV-008; Rule BR-14; UC UC-07

## SV-009 — Reward inbox khi đầy túi

**Phân cấp:** Inventory → Overflow → Reward inbox
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Chỉ server tạo reward inbox persistent;100 entry/account; không hết hạn alpha; claim nguyên tử nếu đủ ô; đầy inbox dừng nguồn reward và cảnh báo.

**Input / tiền điều kiện:** Reward receipt, claim request

**Output / hậu điều kiện:** Inbox entries/items

**Validation / ngoại lệ:** Inbox đầy không âm thầm xóa; dungeon entry bị chặn nếu thiếu capacity

**Acceptance Criteria:** Bag đầy khi kill: reward còn trong inbox sau reconnect, claim 1 lần.

**Trace:** WBS T07-SV, T10-CL; Test TC-SV-009; Rule BR-09; UC Luồng chuyên biệt trong FSD

## SV-010 — Săn bắt và hunger server

**Phân cấp:** Cổ trùng → Capture/feed → Gu service
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Claim spawn chống race; roll 70% sau channel; tiêu seal khi start; hủy không refund; hunger elapsed online dùng serverTime, inventory không equipped không giảm.

**Input / tiền điều kiện:** Capture/feed intents; timers

**Output / hậu điều kiện:** Gu instance/hunger receipt

**Validation / ngoại lệ:** Capture successful commit rồi spawn remove; DB fail phục hồi terminal pending

**Acceptance Criteria:** Feed/reconnect không reset timer để né đói;0 hunger khóa active/passive.

**Trace:** WBS T08-SV; Test TC-SV-010; Rule BR-11, BR-12; UC Luồng chuyên biệt trong FSD

## SV-011 — Công thức, pity và roll server

**Phân cấp:** Cổ trùng → Refining → Recipe service
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Pity theo character+recipe; chance=min(100,70+10×fails); RNG server và kết quả lưu transaction; success reset fails=0; fail giữ input.

**Input / tiền điều kiện:** Recipe/input IDs/configVersion

**Output / hậu điều kiện:** Outcome/output/pity/ledger

**Validation / ngoại lệ:** Stale preview config trả CONFIG_CHANGED trước consume; reuse input đồng thời bị lock

**Acceptance Criteria:** Không output khi rollback; success tiêu 2 Gu; fail giữ 2 Gu; cả 2 mất material/fee.

**Trace:** WBS T09-SV; Test TC-SV-011; Rule BR-13, BR-14; UC Luồng chuyên biệt trong FSD

## SV-012 — XP, quest và rank-up từ event server

**Phân cấp:** Progression → Quest/XP → Progress service
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Event ID unique; XP cumulative curve; quest chỉ event server; reward và claim cùng transaction; rank II unlock validate toàn bộ điều kiện.

**Input / tiền điều kiện:** Trusted gameplay event/claim

**Output / hậu điều kiện:** Level/quest/rank receipt

**Validation / ngoại lệ:** Event ID lặp bỏ qua; client tự gửi kill count bị reject

**Acceptance Criteria:** Replay 100 event không tăng progress lần 2; rank-up chỉ một phí.

**Trace:** WBS T10-SV; Test TC-SV-012; Rule BR-15, BR-16; UC Luồng chuyên biệt trong FSD

## SV-013 — Party và recipient authorization

**Phân cấp:** Xã hội → Party/chat → Social service
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Membership unique; leader state; invite TTL; text sanitize/escape; channel kiểm tra membership; persist report không lưu token/password.

**Input / tiền điều kiện:** Invite/chat/report

**Output / hậu điều kiện:** Roster/message/report

**Validation / ngoại lệ:** Kick/leave làm mất quyền party ngay; message rate limited

**Acceptance Criteria:** User ngoài party không nghe/đọc được party channel; invite replay vô hiệu.

**Trace:** WBS T13-SV, T16-SV; Test TC-SV-013; Rule BR-17, BR-18; UC Luồng chuyên biệt trong FSD

## SV-014 — Dungeon và duel state machine

**Phân cấp:** PvE/PvP → Instances → Instance service
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Dungeon: created→ready→running→won/failed→closed; arena tương tự; fixed roster; key(runId, charId, rewardType) unique.

**Input / tiền điều kiện:** Entry/ready/timers/combat

**Output / hậu điều kiện:** Run/match state; receipts

**Validation / ngoại lệ:** Boss reward pending được retry; đấu trường disconnect30s thua; không rank rewards

**Acceptance Criteria:** Repeated completion không cấp thêm loot; orphan rooms cleanup≤60s.

**Trace:** WBS T14-SV, T15-SV; Test TC-SV-014; Rule BR-19, BR-20; UC UC-13, UC-14

## SV-015 — Data-driven và config version

**Phân cấp:** Content → Configuration → Catalog pipeline
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Gu/item/mob/map/quest/recipe bằng JSON/CSV có schema; build kiểm tra foreign keys; publish immutable version; room đang chạy giữ version cũ tới restart.

**Input / tiền điều kiện:** Validated catalog/version

**Output / hậu điều kiện:** Immutable bundle; validation report

**Validation / ngoại lệ:** Recipe input/output thiếu: fail build; không hotpatch giữa craft

**Acceptance Criteria:** 1 cấu hình lỗi bị chặn; rollback về version trước khôi phục đúng catalog.

**Trace:** WBS T11-SV, T16-SV; Test TC-SV-015; Rule Theo rulebook chung; UC Luồng chuyên biệt trong FSD

## SV-016 — Metrics, log và economy events

**Phân cấp:** Vận hành → Telemetry → Metrics/logs
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Theo dõi CCU/map, tick p95, intent rejection, DB latency, duplicate request, source/sink, funnel tutorial; correlationID xuyên command; không log secret.

**Input / tiền điều kiện:** Server events/counters

**Output / hậu điều kiện:** Dashboard/logs/export

**Validation / ngoại lệ:** Log endpoint không public; không dùng analytics làm nguồn inventory

**Acceptance Criteria:** Tra một craft receipt thấy request/ledger/config; có alert DB unavailable/tick trễ.

**Trace:** WBS T16-SV, T17-SV; Test TC-SV-016; Rule Theo rulebook chung; UC Luồng chuyên biệt trong FSD

## SV-017 — Backup, restore và rollback

**Phân cấp:** Vận hành → Deploy/restore → Private alpha
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Private staging/local trước; daily DB snapshot + trước release; giữ 7 daily/4 weekly; restore diễn tập; schema migration tương thích rollback.

**Input / tiền điều kiện:** DB backup/tag/runbook

**Output / hậu điều kiện:** Restore report/release tag

**Validation / ngoại lệ:** Không restore đè môi trường live khi chưa cô lập; go/no-go khi NFR fail

**Acceptance Criteria:** Restore vào DB rỗng đạt RTO≤2h/RPO≤24h; restart crash khác disaster restore.

**Trace:** WBS T16-SV, T18-SV; Test TC-SV-017; Rule Theo rulebook chung; UC Luồng chuyên biệt trong FSD

## SV-018 — Schema, quota và session fencing

**Phân cấp:** Bảo vệ → Validation → Protocol guard
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Mọi message schema allowlist, max payload8KB; intents ≤20/s burst 40; cast theo cooldown; thiếu auth reject; lease token chống 2 writer.

**Input / tiền điều kiện:** Token/payload/sequence/lease

**Output / hậu điều kiện:** Authorized validated command

**Validation / ngoại lệ:** Stale lease/oversize/message lạ: reject, audit, close nếu spam

**Acceptance Criteria:** Fuzz malformed không crash; stale room không ghi DB; người chơi không vào GM API.

**Trace:** WBS T03-SV, T17-SV; Test TC-SV-018; Rule BR-01, BR-14, BR-18; UC Luồng chuyên biệt trong FSD

## AD-001 — Đăng nhập GM và RBAC

**Phân cấp:** GM → Quyền truy cập → Admin login
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Role GM_READ, GM_MOD, GM_OWNER; chỉ OWNER cấp role; kiểm tra server từng endpoint; tài khoản game không mặc định vào admin.

**Input / tiền điều kiện:** Admin credentials/role

**Output / hậu điều kiện:** Authorized admin session

**Validation / ngoại lệ:** 403 dù client tự sửa role; revoke có hiệu lực khi gọi tiếp

**Acceptance Criteria:** Player và GM_READ không ban/grant; mọi thao tác đặc quyền có audit.

**Trace:** WBS T16-CL, T16-SV; Test TC-AD-001; Rule Theo rulebook chung; UC Luồng chuyên biệt trong FSD

## AD-002 — Tra cứu nhân vật và receipt

**Phân cấp:** GM → Tra cứu → Player detail
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Tìm theo characterId/name; xem level/rank/bag/loadout/ledger/quest/session; read-only; che thông tin nhạy cảm.

**Input / tiền điều kiện:** Search/filter/page

**Output / hậu điều kiện:** Paginated profile/log

**Validation / ngoại lệ:** Không tìm thấy: empty; không hiển thị password/token

**Acceptance Criteria:** GM_READ xem được lịch sử craft bằng requestId mà không sửa dữ liệu.

**Trace:** WBS T16-CL, T16-SV; Test TC-AD-002; Rule Theo rulebook chung; UC Luồng chuyên biệt trong FSD

## AD-003 — Mute/ban và xử lý report

**Phân cấp:** GM → Kiểm duyệt → Moderation
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

GM_MOD mute/ban có lý do, thời hạn; kick session active; report kèm messageID; unban có audit.

**Input / tiền điều kiện:** Target, action, reason, expiry

**Output / hậu điều kiện:** Moderation record/session revoke

**Validation / ngoại lệ:** Reason rỗng/expiry sai: reject

**Acceptance Criteria:** Banned không join lại; mute không gửi chat; hết hạn tự gỡ.

**Trace:** WBS T16-CL, T16-SV; Test TC-AD-003; Rule Theo rulebook chung; UC Luồng chuyên biệt trong FSD

## AD-004 — Cấp vật phẩm có kiểm soát

**Phân cấp:** GM → Hỗ trợ → Grant item
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

OWNER grant theo catalog/qty; lý do bắt buộc; preview; unique requestId; server gửi inbox khi bag đầy; không edit DB trực tiếp.

**Input / tiền điều kiện:** Character, item, qty, reason, UUID

**Output / hậu điều kiện:** Grant receipt/audit/inbox

**Validation / ngoại lệ:** GM_MOD bị 403; ID lặp không cấp thêm

**Acceptance Criteria:** Grant bị lặp chỉ 1 receipt; tra được người làm/lý do/giá trị trước-sau.

**Trace:** WBS T16-CL, T16-SV; Test TC-AD-004; Rule BR-14; UC Luồng chuyên biệt trong FSD

## AD-005 — Publish/rollback config qua pipeline

**Phân cấp:** GM → Cấu hình → Publish
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

OWNER chọn bundle đã validate; staging smoke; alpha restart có thông báo; lưu version trước/sau và actor.

**Input / tiền điều kiện:** Bundle version/change reason

**Output / hậu điều kiện:** Published config/audit

**Validation / ngoại lệ:** Bundle lỗi chưa validate không publish

**Acceptance Criteria:** 1 invalid foreign key chặn publish; rollback dùng bundle bất biến.

**Trace:** WBS T16-SV, T18-SV; Test TC-AD-005; Rule Theo rulebook chung; UC Luồng chuyên biệt trong FSD

## AD-006 — Dashboard vận hành tối thiểu

**Phân cấp:** GM → Giám sát → Dashboard
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Trang read-only số CCU/map, errors, tick, DBhealth; export report alpha; dùng dashboard sẵn có hoặc trang đơn giản.

**Input / tiền điều kiện:** Time range/server stats

**Output / hậu điều kiện:** Dashboard/export

**Validation / ngoại lệ:** Không có metrics hiện No data; không hiện 0 giả

**Acceptance Criteria:** DB mất kết nối hiện cảnh báo trong60s; số CCU khớp active lease.

**Trace:** WBS T16-CL, T16-SV; Test TC-AD-006; Rule Theo rulebook chung; UC Luồng chuyên biệt trong FSD

## AD-007 — Audit bất biến qua API

**Phân cấp:** GM → Audit → Audit log
**Giai đoạn / ưu tiên / trạng thái:** MVP / Must / Đề xuất

Actor/action/target/reason/requestId/timestamp/before-after; quyền read phân vai; không có API xóa hoặc sửa audit; chỉ mask secret.

**Input / tiền điều kiện:** Privileged commands

**Output / hậu điều kiện:** Append-only audit records

**Validation / ngoại lệ:** Audit ghi lỗi: đặc quyền thất bại cùng transaction

**Acceptance Criteria:** Ban/grant/role/config đều có log; GM không xóa được qua API.

**Trace:** WBS T16-SV; Test TC-AD-007; Rule Theo rulebook chung; UC Luồng chuyên biệt trong FSD

# Non-functional Requirements

## NFR-01 — Client performance

**Điều kiện:** Godot PC Windows foreground; scene tham chiếu 20 player+50 mob+VFX vừa;1366×768 low; máy i5-8250U/8GB/UHD620 hoặc máy đội chốt S01

**Pass:** Sau warmup2 phút đo 5 phút: FPS trung vị≥50; frame time p95≤33ms; máy thực tế phải ghi rõ

**Evidence:** Perf capture, engine/OS/hardware/build ID

**WBS:** T01-CL, T17-CL, T17-GD

## NFR-02 — Realtime latency

**Điều kiện:** Máy test cùng khu vực; RTT giả lập100ms, jitter20ms, packet loss 1%; input hợp lệ không rate-limit

**Pass:** Command ACK p95≤250ms; correction không xuyên tường; báo riêng RTT và xử lý server

**Evidence:** 10.000 intent; latency distribution

**WBS:** T04-SV, T17-SV, T17-GD

## NFR-03 — Capacity alpha

**Điều kiện:** 50CCU tổng 1 shard;≤20 player/map room;50 mob hoạt động/map; instance roster≤3; 50bots2 giờ có cast/loot/craft

**Pass:** Simulation20Hz: tick duration p95≤40ms; không disconnect do quá tải; memory không tăng không giới hạn; p95DBcommand≤200ms

**Evidence:** Ghi CPU/RAM/server config; đây là mục tiêu kiểm thử, chưa là benchmark

**WBS:** T17-SV, T17-GD

## NFR-04 — Tài sản bền vững

**Điều kiện:** Inventory/tiền/quest/reward/craft đã ACK commit; position/HP/hunger checkpoint30s

**Pass:** Crash process: mất 0 giao dịch đã ACK; vị trí có thể lùi≤30s;20 retry cùng ID đúng 1 hiệu lực

**Evidence:** Fault injection trước/sau commit và trước/sau ACK

**WBS:** T07-SV, T09-SV, T12-SV, T17-SV

## NFR-05 — Access/security

**Điều kiện:** Auth/game/admin API; token hết hạn; account khác; sửa payload; spam; XSS chat

**Pass:** 100% negative matrix bắt buộc bị chặn; không secret trong log; không client-authoritative reward; 0 lỗi P0/P1 auth/dupe

**Evidence:** Danh sách test và evidence; không gọi là chứng nhận bảo mật

**WBS:** T02-SV, T16-SV, T17-SV

## NFR-06 — Backup/disaster

**Điều kiện:** Snapshot hằng ngày + trước release; giữ 7 daily/4 weekly; restore vào môi trường cô lập

**Pass:** RPO≤24h; RTO≤2 giờ trong diễn tập; item/ledger đối chiếu khớp backup; khác crash checkpoint

**Evidence:** Log thời điểm snapshot, mất dữ liệu giả lập và hoàn tất restore

**WBS:** T16-SV, T18-SV

## NFR-07 — Compatibility

**Điều kiện:** Godot native Windows 10/11;1366×768/1920×1080; keyboard+mouse; Web export kiểm chứng riêng

**Pass:** Login→quest→craft→dungeon chạy trên Windows 10/11; UI không chặn nútchính; version ghi trong báo cáo

**Evidence:** OS/engine matrix; Web là spike, chưa cam kết mobile/nativeMac/Linux

**WBS:** T17-CL, T17-GD

## NFR-08 — Asset budget

**Điều kiện:** PC cold start; content shell+town không tính engine; Web spike qua mạng 20 Mbps; cache cold; không tính thời gian nhập password; lazyload farm/dungeon

**Pass:** Initial compressed payload≤25MB; interactive p95≤15 giây trên 10 lượt; asset progress/failure retry có UI

**Evidence:** Network waterfall; dung lượng bundle; ngân sách cần kiểm chứng S01

**WBS:** T02-CL, T17-CL, T17-AR

## NFR-09 — Maintainability

**Điều kiện:** Client/server/shared-content tách rõ; server không import UI; config có schema và version

**Pass:** CI chặn typecheck/build/schema/transaction tests fail; dev mới chạy local theoREADME≤60 phút

**Evidence:** Clean-machine setup run; dependency graph review

**WBS:** T02-SV, T11-SV, T16-GD

## NFR-10 — Observability

**Điều kiện:** Auth/room/cast/craft/inventory/admin; mỗi command có correlationID

**Pass:** Tra1 receipt tìm đủ configVersion/outcome/ledger; alert DBunavailable hoặc tick overrun trong 60 giây; log không secret

**Evidence:** Dashboard capture; trace một happy và một failed command

**WBS:** T16-SV, T17-SV

## NFR-11 — UX và readability

**Điều kiện:** 10 tester chưa được hướng dẫn; low graphics và mute; skill errors và telegraphs

**Pass:** ≥8/10 tự di chuyển/chọn/đánh trong 3 phút;5/5telegraph kiểm tra có shape/icon ngoài màu; scale chữ≥14px ở 1366×768

**Evidence:** Quan sát task completion; note lý do thất bại

**WBS:** T03-GD, T16-AR, T17-GD

## NFR-12 — Release gate

**Điều kiện:** Feature freeze; E2E, dupe, security, load, restore;5 gate có biên bản

**Pass:** 0P0/0P1;100% Must có ít nhất 1 test passed với evidence; Should có known issues; build/config/schema tags và rollback runbook

**Evidence:** Go/no-go check list; chưa có test nào được đánh dấu passed trong bản kế hoạch

**WBS:** T16-GD, T17-GD, T18-GD, T18-SV
