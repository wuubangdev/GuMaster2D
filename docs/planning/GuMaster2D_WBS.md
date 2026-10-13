# GuMaster2D — Work Breakdown Structure

Đề xuất 0.2 /07/10/2026. 72 work packages;199PDbase;238.8 PD gồm dự phòng. 1 PD=8 giờ hữu ích. Baseline 36 tuần/18 sprint;20h/người/tuần;4 người.

Dependency làfinish-to-start giữa các sprint. Cùng sprint phối hợp build/integrate/test; gate đánh giá cuối sprint. Lịch tại file Excel bám 00_START!B7. Test prototype báo cáo riêng;79 testcase alpha chưa chạy. Ba gói spike S01 đang làm; code prototype tham khảo cho các gói sau không đồng nghĩa mở toàn bộ WIP hoặc hoàn thành AC alpha.

| Code / ID | Sprint / tuần | Owner | Gói công việc | Predecessors | Base / Total PD | Status | Definition of Done |
|---|---|---|---|---|---|---|---|
| 1.1 / T01-GD | S01 / 1–2 | GD | Khóa MVP, FSD và danh sách quyết định | — | 2.5 / 3.0 | Đang làm (prototype) | Scope v0.2; FSD có ID, AC, danh sách TBD |
| 1.2 / T01-CL | S01 / 1–2 | CL | Spike Godot isometric trên PC; thử Web export | — | 3.0 / 3.6 | Đang làm (prototype) | Map mẫu, click-to-move, đo render trên máy tham chiếu |
| 1.3 / T01-SV | S01 / 1–2 | SV | Spike authoritative room và lưu dữ liệu | — | 3.0 / 3.6 | Chưa bắt đầu | Hai client kết nối; server giữ state; thử ghi transaction |
| 1.4 / T01-AR | S01 / 1–2 | AR | Art direction và kiểm kê tài nguyên | — | 2.5 / 3.0 | Đang làm (prototype) | Moodboard nội bộ, style guide, danh mục asset và nguồn |
| 2.1 / T02-GD | S02 / 3–4 | GD | Chốt luật chiến đấu và mô hình dữ liệu | T01-GD, T01-CL, T01-SV | 2.5 / 3.0 | Chưa bắt đầu | Rulebook, 5 Cổ đầu, flow lỗi và test matrix |
| 2.2 / T02-CL | S02 / 3–4 | CL | Client shell, scene và tọa độ | T01-CL | 3.0 / 3.6 | Chưa bắt đầu | Boot/Login/World/HUD; world↔iso; loader và input |
| 2.3 / T02-SV | S02 / 3–4 | SV | Repo, CI, schema và đăng nhập | T01-SV | 3.0 / 3.6 | Chưa bắt đầu | CI build; migration; tài khoản mời; session một nhân vật |
| 2.4 / T02-AR | S02 / 3–4 | AR | Nhân vật và tileset cơ sở | T01-AR | 2.5 / 3.0 | Chưa bắt đầu | Một avatar, 4 hướng hiển thị, idle/walk/attack; tileset dùng lại |
| 2.5 / T03-GD | S03 / 5–6 | GD | Kiểm thử điều khiển và onboarding | T02-GD, T02-CL | 2.0 / 2.4 | Chưa bắt đầu | Check list click, focus chat, resize; kịch bản 30 giây đầu |
| 2.6 / T03-CL | S03 / 5–6 | CL | Di chuyển, camera, va chạm và chọn mục tiêu | T02-CL, T02-AR | 3.0 / 3.6 | Chưa bắt đầu | A*, camera bám, click marker, target vòng chọn |
| 2.7 / T03-SV | S03 / 5–6 | SV | Room, quyền vào map và session lease | T02-SV | 3.0 / 3.6 | Chưa bắt đầu | Join/leave có auth; single writer; giới hạn map |
| 2.8 / T03-AR | S03 / 5–6 | AR | Bản đồ thị trấn và bố cục HUD | T02-AR | 2.5 / 3.0 | Chưa bắt đầu | MAP-01; spawn/NPC/portal; HUD wireframe và icon nền |
| 2.9 / T04-GD | S04 / 7–8 | GD | Gate G1 — thử hai client và lỗi mạng | T03-GD, T03-CL, T03-SV | 2.5 / 3.0 | Chưa bắt đầu | Biên bản kiểm thử auth, chuyển map và mất kết nối |
| 2.10 / T04-CL | S04 / 7–8 | CL | Tích hợp đồng bộ và nội suy | T03-CL, T03-SV | 3.0 / 3.6 | Chưa bắt đầu | Remote players; correction; HUD mạng; không ghost entity |
| 2.11 / T04-SV | S04 / 7–8 | SV | Di chuyển authoritative và AOI | T03-SV, T03-CL | 3.0 / 3.6 | Chưa bắt đầu | Validate đường đi/tốc độ; state lọc theo vùng; chống warp |
| 2.12 / T04-AR | S04 / 7–8 | AR | Hoàn thiện HUD nền và feed back di chuyển | T03-AR | 2.5 / 3.0 | Chưa bắt đầu | HP/mana/target/minimap; click/denied feed back |
| 3.1 / T05-GD | S05 / 9–10 | GD | Cân bằng 5 Cổ và combat test cases | T04-GD, T02-GD | 2.5 / 3.0 | Chưa bắt đầu | Thông số sát thương, mana, CC, cooldown có đơn vị |
| 3.2 / T05-CL | S05 / 9–10 | CL | Combat UI và 5 kỹ năng đầu | T04-CL, T04-AR | 3.0 / 3.6 | Chưa bắt đầu | QWER, chọn mục tiêu, telegraph, cooldown, hit feed back |
| 3.3 / T05-SV | S05 / 9–10 | SV | Combat resolver và trạng thái | T04-SV | 3.0 / 3.6 | Chưa bắt đầu | Range/LOS/cooldown/mana; damage, shield, slow, stun |
| 3.4 / T05-AR | S05 / 9–10 | AR | VFX/SFX chiến đấu cơ sở | T04-AR | 2.5 / 3.0 | Chưa bắt đầu | Projectile, impact, shield, warning; âm lượng và mute |
| 3.5 / T06-GD | S06 / 11–12 | GD | Gate G2 — vòng đánh quái và nhận thưởng | T05-GD, T05-CL, T05-SV | 2.5 / 3.0 | Chưa bắt đầu | 10 phiên 15 phút; ghi TTK, lỗi; chưa đo retention dài hạn |
| 3.6 / T06-CL | S06 / 11–12 | CL | Quái, loot và chết/hồi sinh phía client | T05-CL | 3.0 / 3.6 | Chưa bắt đầu | Nameplate, loot popup, respawn, NPC interaction |
| 3.7 / T06-SV | S06 / 11–12 | SV | AI quái, spawn, loot và hồi sinh | T05-SV | 3.0 / 3.6 | Chưa bắt đầu | FSM idle/aggro/chase/attack/leash/dead; reward exactly once |
| 3.8 / T06-AR | S06 / 11–12 | AR | Map cày bãi và quái cơ sở | T05-AR | 3.0 / 3.6 | Chưa bắt đầu | MAP-02; 6 loại quái dùng biến thể; điểm spawn và collision |
| 4.1 / T07-GD | S07 / 13–14 | GD | Thiết kế inventory, economy và dữ liệu Cổ | T06-GD | 2.5 / 3.0 | Chưa bắt đầu | Catalog 20 Cổ/10 vật liệu; nguồn-tiêu; bộ test trùng lệnh |
| 4.2 / T07-CL | S07 / 13–14 | CL | Túi đồ, tooltip, trang bị Không Khiếu | T06-CL | 3.0 / 3.6 | Chưa bắt đầu | 30 ô; drag/click equip; 4 active + 2 passive |
| 4.3 / T07-SV | S07 / 13–14 | SV | Persistence inventory và giao dịch nội bộ | T06-SV | 3.0 / 3.6 | Chưa bắt đầu | Lock/version; ledger; request ID; atomic reward/equip |
| 4.4 / T07-AR | S07 / 13–14 | AR | Icon Cổ và UI inventory | T06-AR | 2.5 / 3.0 | Chưa bắt đầu | 20 icon + vật liệu; trạng thái khóa/đói/trang bị đọc rõ |
| 4.5 / T08-GD | S08 / 15–16 | GD | Luật bắt và nuôi Cổ, thử chi phí thức ăn | T07-GD, T07-SV | 2.5 / 3.0 | Chưa bắt đầu | Cấu hình capture; hunger online; recovery; bộ test |
| 4.6 / T08-CL | S08 / 15–16 | CL | UI săn bắt và nuôi Cổ | T07-CL | 3.0 / 3.6 | Chưa bắt đầu | Thanh channel bắt Cổ; xác nhận đồ ăn; preview phục hồi |
| 4.7 / T08-SV | S08 / 15–16 | SV | Capture và feeding authoritative | T07-SV | 3.0 / 3.6 | Chưa bắt đầu | Target claim; roll server; atomic seal/food/reward/hunger |
| 4.8 / T08-AR | S08 / 15–16 | AR | Hiệu ứng bắt Cổ và NPC luyện/nuôi | T07-AR | 2.0 / 2.4 | Chưa bắt đầu | Capture FX, NPC, UI hunger và màn thông báo |
| 4.9 / T09-GD | S09 / 17–18 | GD | Công thức luyện và xác suất minh bạch | T08-GD | 2.5 / 3.0 | Chưa bắt đầu | 10 recipe; pity; 5.000 lượt mô phỏng trên dữ liệu nháp |
| 4.10 / T09-CL | S09 / 17–18 | CL | UI luyện Cổ và lịch sử kết quả | T08-CL | 3.0 / 3.6 | Chưa bắt đầu | Chọn instance, recipe, preview tỷ lệ; request retry |
| 4.11 / T09-SV | S09 / 17–18 | SV | Luyện Cổ transaction và idempotency | T08-SV | 3.0 / 3.6 | Chưa bắt đầu | Atomic consume/RNG/pity/output/ledger; crash/retry tests |
| 4.12 / T09-AR | S09 / 17–18 | AR | UI luyện Cổ và thông báo kết quả | T08-AR | 2.0 / 2.4 | Chưa bắt đầu | Success/fail khác nhau; không chỉ phân biệt bằng màu |
| 4.13 / T10-GD | S10 / 19–20 | GD | Quest, cấp độ và thăng chuyển | T09-GD | 2.5 / 3.0 | Chưa bắt đầu | 10 quest; level 1–20; rank I–II; XP curve |
| 4.14 / T10-CL | S10 / 19–20 | CL | Quest tracker, level up và NPC shop | T09-CL | 3.0 / 3.6 | Chưa bắt đầu | Nhận/trả quest; shop fixed price; kiểm tra rank |
| 4.15 / T10-SV | S10 / 19–20 | SV | Quest/progression/NPC economy | T09-SV | 3.0 / 3.6 | Chưa bắt đầu | Event quest; atomic claim/rank-up/buy/sell; caps |
| 4.16 / T10-AR | S10 / 19–20 | AR | Hoàn thiện map, NPC và props tái sử dụng | T09-AR | 2.5 / 3.0 | Chưa bắt đầu | Town/farm đủ đường đi; 4 NPC; collision đã đánh dấu |
| 4.17 / T11-GD | S11 / 21–22 | GD | Cân bằng đầy đủ 20 Cổ và nguồn loot | T10-GD | 3.0 / 3.6 | Chưa bắt đầu | 20 Cổ từ 8 primitive; 3 build khả thi; loot catalog |
| 4.18 / T11-CL | S11 / 21–22 | CL | Tích hợp đầy đủ Cổ, passive và codex | T10-CL | 3.0 / 3.6 | Chưa bắt đầu | 20 Cổ data-driven; status icons; mô tả đầy đủ |
| 4.19 / T11-SV | S11 / 21–22 | SV | Mở rộng effect primitives và content validator | T10-SV | 3.0 / 3.6 | Chưa bắt đầu | 8 primitive; passive stack policy; schema/version checks |
| 4.20 / T11-AR | S11 / 21–22 | AR | Hoàn thiện icon, animation và status FX | T10-AR | 2.5 / 3.0 | Chưa bắt đầu | Bộ icon final alpha; hit/death; FX dùng lại |
| 4.21 / T12-GD | S12 / 23–24 | GD | Gate G3 — E2E vòng Cổ | T11-GD, T11-CL, T11-SV | 3.0 / 3.6 | Chưa bắt đầu | 20 tester nội bộ/luân phiên; capture→feed→craft→equip→fight |
| 4.22 / T12-CL | S12 / 23–24 | CL | Reconnect UI và E2E sửa lỗi client | T11-CL | 3.0 / 3.6 | Chưa bắt đầu | Overlay mất mạng; resync bag/status; không gửi lệnh cũ |
| 4.23 / T12-SV | S12 / 23–24 | SV | Reconnect, map handoff và crash recovery | T11-SV | 3.0 / 3.6 | Chưa bắt đầu | Lease fencing; reserve/commit transfer; durable state resync |
| 4.24 / T12-AR | S12 / 23–24 | AR | Map phụ bản và boss blockout | T11-AR | 2.5 / 3.0 | Chưa bắt đầu | MAP-03; arena tái dùng vùng; telegraph đủ khoảng né |
| 5.1 / T13-GD | S13 / 25–26 | GD | Thiết kế party/boss/arena và QA matrix | T12-GD | 2.5 / 3.0 | Chưa bắt đầu | Party 3; loot cá nhân; trận 1v1 không xếp hạng |
| 5.2 / T13-CL | S13 / 25–26 | CL | Party và chat khu vực/party | T12-CL | 3.0 / 3.6 | Chưa bắt đầu | Mời/đồng ý/rời; leader UI; mute/report; focus input |
| 5.3 / T13-SV | S13 / 25–26 | SV | Party state và chat có giới hạn | T12-SV | 3.0 / 3.6 | Chưa bắt đầu | Membership; invite TTL; rate limit; server recipient filter |
| 5.4 / T13-AR | S13 / 25–26 | AR | Sprite boss và quái tinh anh | T12-AR | 3.0 / 3.6 | Chưa bắt đầu | 1 boss/2 elite biến thể; windup/attack/death |
| 5.5 / T14-GD | S14 / 27–28 | GD | Kiểm thử phụ bản và reward chống lặp | T13-GD, T13-CL, T13-SV | 2.5 / 3.0 | Chưa bắt đầu | 10 run đủ/thất bại/disconnect; ledger cá nhân |
| 5.6 / T14-CL | S14 / 27–28 | CL | Phụ bản và boss UI/telegraph | T13-CL, T13-AR | 3.0 / 3.6 | Chưa bắt đầu | Entry vote, boss HP, kết quả; AoE dễ đọc |
| 5.7 / T14-SV | S14 / 27–28 | SV | Dungeon instance, boss và personal reward | T13-SV | 3.0 / 3.6 | Chưa bắt đầu | 3 người/15 phút; boss 2 pattern; run ID; cleanup |
| 5.8 / T14-AR | S14 / 27–28 | AR | Boss VFX, dungeon props và âm thanh | T13-AR | 2.5 / 3.0 | Chưa bắt đầu | 2 telegraph boss; ambient dùng lại; music mute |
| 5.9 / T15-GD | S15 / 29–30 | GD | Gate G4 — multiplayer và PvP | T14-GD, T14-CL, T14-SV | 2.5 / 3.0 | Chưa bắt đầu | Party 3; dungeon; 1v1; quyết định cắt phạm vi nếu trễ |
| 5.10 / T15-CL | S15 / 29–30 | CL | Đấu tay đôi opt-in và kết quả | T14-CL | 3.0 / 3.6 | Chưa bắt đầu | Invite/ready/countdown/result; quay lại safe spawn |
| 5.11 / T15-SV | S15 / 29–30 | SV | Arena PvP, timer và disconnect policy | T14-SV | 3.0 / 3.6 | Chưa bắt đầu | Two opt-ins; PvP damage factor; no reward farming |
| 5.12 / T15-AR | S15 / 29–30 | AR | Arena/UI social và độ đọc hình | T14-AR | 2.0 / 2.4 | Chưa bắt đầu | Arena từ tileset có sẵn; silhouette/telegraph/party colors |
| 6.1 / T16-GD | S16 / 31–32 | GD | Feature freeze, UAT plan và hướng dẫn tester | T15-GD, T15-CL, T15-SV | 3.0 / 3.6 | Chưa bắt đầu | Traceability đóng; check list NFR; test accounts/instructions |
| 6.2 / T16-CL | S16 / 31–32 | CL | Admin UI tối thiểu và settings client | T15-CL | 3.0 / 3.6 | Chưa bắt đầu | GM tra cứu/read-only; âm lượng/phím/đồ họa; role guard |
| 6.3 / T16-SV | S16 / 31–32 | SV | GM API, audit, metrics và backup jobs | T15-SV | 3.0 / 3.6 | Chưa bắt đầu | RBAC/mute/ban/grant; config publish; daily snapshot |
| 6.4 / T16-AR | S16 / 31–32 | AR | Polish HUD, feed back và asset audit | T15-AR | 2.5 / 3.0 | Chưa bắt đầu | UI thống nhất; lỗi/thành công; file và nguồn asset đầy đủ |
| 6.5 / T17-GD | S17 / 33–34 | GD | UAT, soak test phối hợp và phân loại lỗi | T16-GD, T16-CL, T16-SV | 3.0 / 3.6 | Chưa bắt đầu | 20 tester; 50 bots/2 giờ; 3 build; lỗi P0/P1 về 0 |
| 6.6 / T17-CL | S17 / 33–34 | CL | Tối ưu client và sửa lỗi UAT | T16-CL | 3.0 / 3.6 | Chưa bắt đầu | FPS p95 frame time; asset budget; Windows matrix và Web spike |
| 6.7 / T17-SV | S17 / 33–34 | SV | Load/fault/security và tối ưu server | T16-SV | 3.0 / 3.6 | Chưa bắt đầu | 50 CCU toàn shard/20 map; duplicate, kill/restart, expiry |
| 6.8 / T17-AR | S17 / 33–34 | AR | Atlas, compression và pass đọc hình | T16-AR | 2.5 / 3.0 | Chưa bắt đầu | Đo payload, giảm overdraw; font/contrast/audio review |
| 6.9 / T18-GD | S18 / 35–36 | GD | Gate G5 — release check list và alpha report | T17-GD, T17-CL, T17-SV, T17-AR | 3.0 / 3.6 | Chưa bắt đầu | NFR/UAT có evidence; lịch beta; go/no-go; báo cáo 7 ngày |
| 6.10 / T18-CL | S18 / 35–36 | CL | Release candidate và sửa lỗi phát hành | T17-CL | 3.0 / 3.6 | Chưa bắt đầu | Client RC tag; smoke test; known issues; rollback compatible |
| 6.11 / T18-SV | S18 / 35–36 | SV | Restore drill, deploy và runbook | T17-SV | 3.0 / 3.6 | Chưa bắt đầu | Staging→private alpha; restore đo RPO/RTO; rollback diễn tập |
| 6.12 / T18-AR | S18 / 35–36 | AR | Hoàn tất asset và gói giới thiệu alpha | T17-AR | 2.0 / 2.4 | Chưa bắt đầu | Asset manifest, credits; screenshot, hướng dẫn hiển thị |
