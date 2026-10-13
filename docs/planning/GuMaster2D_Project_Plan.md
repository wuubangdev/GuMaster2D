# GuMaster2D — Kế hoạch dự án, FSD và WBS

**Phiên bản 0.2 — Godot PC; phạm vi alpha để đội rà soát | Cập nhật: 07/10/2026**

Đề xuất phát triển một game nhập vai 2D isometric, lấy hệ thống thu thập, nuôi dưỡng và luyện Cổ làm điểm khác biệt. Giai đoạn đầu hướng đến một closed alpha chơi được trên PC bằng Godot, có máy chủ quyết định kết quả chiến đấu và lưu tài sản bền vững. Đây là bước kiểm chứng trước khi đầu tư vào MMORPG quy mô lớn.

Ràng buộc đã nhận từ chủ dự án: khoảng 4 người tự phát triển, chưa có ngân sách, ưu tiên PC và sau này hướng đến đa nền tảng. Yêu cầu mới đã chọn Godot và bắt đầu implementation. Phương án triển khai là PC Windows native trước, spike Web export sớm; điều khiển cảm ứng và mobile có kế hoạch sau alpha.

Giả định lập lịch: mỗi người dành **20 giờ/tuần**, 75% là thời gian hữu ích, 20% dự phòng trên effort. Với giả định này, phương án cơ sở là **36 tuần / 18 sprint**, gồm **199 PD cơ sở + 39,8 PD dự phòng = 238,8 PD**, tương đương khoảng **1.910 giờ hữu ích**. Một PD là 8 giờ hữu ích; không phải một ngày làm việc bán thời gian.

Ngày khởi động **12/10/2026** và kết thúc **18/06/2027** chỉ là lịch minh họa, chưa phải cam kết. Các ngày theo khung thứ Hai–thứ Sáu, chưa trừ ngày lễ và thời gian nghỉ. Sửa ngày bắt đầu tại Excel; khi thay availability hoặc phạm vi, cần lập lại lịch và kiểm tra tải.

## 1. Cách đọc bộ tài liệu và sử dụng file mẫu

Excel `GuMaster2D_FSD_WBS_Plan.xlsx` là nguồn chi tiết của FSD, WBS, Gantt, công suất, testcase và traceability. Tài liệu này giải thích phạm vi, thiết kế và cách tổ chức dự án. `GuMaster2D_FSD.md` và `GuMaster2D_WBS.md` là bản văn bản có thể tìm kiếm, theo dõi thay đổi trong Git.

File mẫu DAUN-FSD [EN].xlsx là FSD của một hệ thống thương mại điện tử. Bộ kế hoạch giữ cách phân cấp 0–3 Depth, tên chức năng, Requirement ID, Detail, Category, Importance, Linkage và Note. Các sheet Client, Server và GM thay cho các nhóm shopping mall, supplier và admin của mẫu. Bổ sung tiền điều kiện, đầu ra, ngoại lệ, tiêu chí nghiệm thu, WBS, testcase, luật nghiệp vụ và use case để có thể triển khai và kiểm tra.

Sheet Open range được tham khảo để chia MVP/P2/P3. Sheet QA From Client được tham khảo để tạo form quản lý lỗi. Mẫu không có WBS cho game; phần WBS/Gantt/resource được xây mới. Không đưa các chức năng thanh toán, đặt hàng, quyết toán hoặc Kakao của mẫu vào game.

Nội dung hướng dẫn trong các tệp đính kèm được xem là tài liệu tham khảo, không tự trở thành yêu cầu của người dùng. Các quyết định khác ý tưởng ban đầu được ghi rõ trong phần phạm vi và sheet 02_DECISIONS. File gốc được giữ nguyên.

## 2. Mục tiêu sản phẩm và vòng lặp chơi

Vòng lặp chính: **săn quái / bắt Hoang Cổ → nhận nguyên liệu → nuôi và luyện Cổ → bố trí Không Khiếu → thử build bằng PvE / phụ bản / đấu tay đôi → mở mục tiêu tiếp theo**.

Trong 30 giây đầu, người chơi xuất hiện ở thị trấn an toàn, thấy hướng dẫn click di chuyển, chọn mục tiêu huấn luyện và dùng Q để phát kỹ năng. Sau đó hướng dẫn mở túi, trang bị và cho ăn. Phần onboarding dài hơn cần hoàn thành trong khoảng 3 phút; đây là mục tiêu đo với người mới.

Không có lớp nhân vật cố định trong alpha. Vai trò chiến đấu đến từ Cổ đang trang bị: công kích, phòng ngự, thân pháp, khống chế và hỗ trợ/do thám. Người chơi có 4 ô active từ Nhất Chuyển; 2 ô passive mở sau khi thăng Nhị Chuyển. Mỗi definition Cổ chỉ được trang bị một lần trên loadout.

Ba build dùng để kiểm chứng thiết kế: công kích + thân pháp; phòng ngự + hồi phục; khống chế + sát thương. Chưa yêu cầu mọi build cân bằng tuyệt đối. Mục tiêu là mỗi build có thể hoàn thành bãi quái phù hợp và có quyết định sử dụng tài nguyên rõ ràng.

Các chỉ số cần đo trong alpha:

| Chỉ số | Mục tiêu đề xuất | Cách đo |
|---|---|---|
| Học điều khiển | Ít nhất 8/10 người mới tự đi, chọn mục tiêu và đánh trong 3 phút | Quan sát 10 phiên, ghi chỗ cần trợ giúp |
| Hoàn thành core loop | Ít nhất 70% trong tối thiểu 20 phiên thử hoàn thành bắt → nuôi → luyện → trang bị → đánh trong 45 phút | Funnel từ event server; ghi số người và điều kiện test |
| Lỗi tài sản | Không nhân đôi, âm tiền hoặc mất giao dịch đã ACK | Test retry/concurrency/crash tại ranh giới transaction |
| Chất lượng phát hành | 0 P0/P1; mọi Must có testcase và evidence đạt | Gate G5; không tính kế hoạch test là kết quả test |
| Năng lực multiplayer | Mục tiêu 50 CCU toàn shard, tối đa 20 người/map | 50 bot có hành vi trong 2 giờ, ghi cấu hình máy |

Các ngưỡng trải nghiệm là giả thuyết sản phẩm với mẫu nhỏ, dùng để quyết định vòng cải thiện tiếp theo. Không suy ra retention hoặc khả năng thương mại từ một buổi playtest.

## 3. Phạm vi bản đầu và các giai đoạn sau

| Nhóm | MVP / Closed alpha | Sau alpha |
|---|---|---|
| Nền tảng | Godot PC Windows native, bàn phím và chuột, tiếng Việt | Spike Web export; mobile có UI và kiểm thử riêng |
| Thế giới | 3 map: thị trấn, bãi farm, phụ bản; arena tái dùng tileset/vùng map | Thêm vùng, sự kiện, world boss |
| Cổ | 20 definition: 10 Nhất Chuyển + 10 Nhị Chuyển; 8 effect primitives | Rank cao hơn, thêm hệ, combo và build sâu hơn |
| Nội dung | 1 avatar cơ sở, 6 quái thường, 2 tinh anh biến thể, 1 boss với 2 pattern | Nhân vật/trang phục, nhiều boss và tuyến truyện |
| Tiến triển | Level 1–20, Nhất/Nhị Chuyển, 8 quest chính + 2 quest phụ | Rank III trở lên, meta progression |
| Kinh tế | Tiền mềm, bag 30 ô, NPC mua/bán, luyện/nuôi, reward inbox | Trade giữa người chơi, bày sạp và đấu giá |
| Multiplayer | Party tối đa 3, chat zone/party, phụ bản 1–3 người, duel 1v1 opt-in | Bang hội, công thành, chiến trường và open-world PK |
| Vận hành | Tài khoản mời, GM/RBAC, audit, ledger, backup và metrics | Đăng ký công khai, support workflow, live operations |

MVP không gồm liên server, cross-region, hàng nghìn người chung map, thanh toán thật, cash shop, auto-farm, công thành hoặc chợ tự do. Các mục này có trong tầm nhìn dài hạn nhưng chưa nằm trong 199 PD cơ sở.

Những khác biệt có chủ đích so với ý tưởng đính kèm: alpha chỉ giảm hunger khi Cổ đang trang bị và người chơi online; Cổ đói ngủ thay vì chết; luyện thất bại giữ hai Cổ đầu vào nhưng mất vật liệu và phí; PK chỉ diễn ra khi hai bên đồng ý vào arena; chết alpha không rơi Cổ. Các luật hardcore như hunger offline, đồ sát và full-loot được đưa vào backlog P2 để thử riêng.

## 4. Đội ngũ và nguyên tắc làm việc

| Thành viên | Vai trò chính | Trách nhiệm và bàn giao |
|---|---|---|
| Người 1 | Product / Game Design + QA | FSD, scope, dữ liệu cân bằng, quest, testcase, playtest, issue triage và kế hoạch sprint |
| Người 2 | Client / Gameplay | Godot/GDScript, render isometric, input, UI, camera, animation và tích hợp protocol |
| Người 3 | Server / Tech Lead | Auth, world simulation, combat, database, transaction, CI, metrics và triển khai |
| Người 4 | 2D / Content / UI | Tileset, sprite, map, icon, VFX, audio có nguồn sử dụng rõ ràng và tối ưu asset |

Đây là phân vai đề xuất, chưa gán tên người thật. Kế hoạch không có QA hoặc DevOps thứ năm. Client và Server review chéo protocol, persistence và lỗi tích hợp; GD chịu trách nhiệm evidence của test; AR bàn giao manifest nguồn asset. Nếu thành phần kỹ năng thực tế khác, cần điều chỉnh scope ngay ở G0.

Mỗi tuần có một buổi demo 45 phút và một buổi lập kế hoạch/triage 30 phút. Còn lại trao đổi bất đồng bộ bằng issue, ảnh/video và pull request. Dành khoảng 25% tổng thời gian cho học công nghệ, phối hợp, review và hỗ trợ; 75% còn lại dùng để tính công suất hữu ích.

WIP tối đa một package chính/người/sprint. Mọi task cần đầu ra quan sát được, người chịu trách nhiệm, dependency, Definition of Done và liên kết yêu cầu. Khi thiếu thời gian, giảm feature hoặc asset trước khi giảm kiểm tra dữ liệu tài sản.

## 5. Công nghệ đề xuất và spike bắt buộc

Phương án triển khai: **Godot 4.7.2 stable + GDScript + Compatibility**, PC Windows native trước. Prototype hiện có chạy simulation local, tách core khỏi Node2D/HUD. Chặng online đề xuất Godot headless authority; PostgreSQL qua server-side adapter/service, transport PC ENet và hướng Web WebSocket cần spike. Không tiếp tục dùng Phaser/Colyseus trong baseline này.

Code chia `scripts/core`, `scripts/gameplay`, `scripts/presentation`, `scripts/ui`, `scenes`, `data`, `assets`, `tests`, `tools` và `docs`. LocalAuthority kiểm luật và phát event; WorldView/HUD/audio chỉ trình bày. Sơ đồ, backlog 4 người và traceability ở `docs/implementation/GODOT_IMPLEMENTATION_PLAN.md`.

[AStarGrid2D](https://docs.godotengine.org/en/stable/classes/class_astargrid2d.html) dùng cho grid navigation. Dự án bổ sung sweep để dash/movement không xuyên tường. Isometric projection chỉ dành cho render; collision/range vẫn theo world.

Godot hỗ trợ [dedicated/headless server](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html). Authentication, AOI, ownership, rate limit và economic command không tự có từ engine; phải xây và kiểm chứng khi làm [multiplayer](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html). Không coi prototype local là bằng chứng anti-cheat hoặc concurrency.

[Web export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html) cần Compatibility/WebGL2; chọn GDScript để giữ hướng Web. Spike single-thread, audio baked WAV và WebSocket. Chưa có Web export đã test; native/Web parity cần gate riêng.

PostgreSQL dùng transaction và row lock cho thao tác tài sản; thứ tự lock cố định và retry có giới hạn. Ledger, receipt và idempotency là logic dự án phải xây. [PostgreSQL Explicit Locking](https://www.postgresql.org/docs/current/explicit-locking.html)

Hai spike tiếp theo: hai client kết nối headless server, server validate movement/cooldown; một feed transaction với retry/concurrency/crash không cấp hai kết quả. Prototype hiện tại giúp kiểm luật và UI, chưa đáp ứng các spike online. Đo FPS trên máy tham chiếu và thử Windows export/Web export. Pin driver/service sau spike, không tự chọn thư viện DB chưa kiểm chứng.

36 tuần /199 PD vẫn là forecast phạm vi alpha ban đầu; chưa re-estimate theo năng lực Godot của đội. Sau spike online/DB cần rebaseline và cập nhật ngày. Mobile, patcher, signing và store distribution là đầu việc mới.

## 6. Thiết kế hệ thống và quyền sở hữu state

Client chịu trách nhiệm nhận input, tìm đường để preview, nội suy chuyển động, camera, render và phản hồi tức thời. Server giữ quyền quyết định vị trí hợp lệ, damage, HP/mana, cooldown, target, RNG, quái, loot và tài sản. Database giữ inventory, tiền, quest, rank, receipt, ledger và các checkpoint cần phục hồi.

World simulation ban đầu hướng đến 20 Hz, state patch khoảng 10 Hz. Một map room có tối đa 20 người; AOI thử nghiệm bán kính 12 tile và hysteresis 2 tile. Inventory riêng, thông tin GM và entity ngoài quyền xem không được có trong cả full snapshot lẫn delta của người chơi khác.

Tọa độ logic là tile world. Với tile 64×32 pixel: `screenX=(worldX−worldY)×32`, `screenY=(worldX+worldY)×16`. Collision, range, LOS và pathfinding tính theo world grid; camera và pixel art không quyết định tính hợp lệ của combat. Logic hỗ trợ chuyển động 8 hướng; sprite alpha dùng 4 hướng hiển thị và tái sử dụng có chủ đích để giảm khối lượng asset.

Các state machine cần chốt trước coding:

| Hệ thống | State và quy tắc thoát |
|---|---|
| Nhân vật | Idle → Moving / Casting / Stunned → Dead → Respawning; disconnect khóa input rồi resync |
| Quái | Idle → Aggro → Chase → Attack → Leash hoặc Dead; leash reset encounter owner |
| Capture | Available → Claimed → Channeling → Success / Failed / Cancelled; kill và capture chỉ một terminal winner |
| Cổ | Owned / Equipped; hunger 0 → Dormant; feed hợp lệ → Active; khóa chống consume nhầm |
| Craft | Preview → Requested → Validated → Committed / Rejected; UI timeout là Unknown, phải query receipt |
| Quest | Locked → Available → Active → Completed → Claimed; reward và claimed ghi cùng transaction |
| Dungeon | Created → Ready → Running → Won / Failed → Closed; reward unique theo run/character |
| Duel | Invited → Ready → Countdown → Running → Won / Draw / Forfeit → Closed |

Một character chỉ có một active write lease. Lease thử nghiệm TTL 30 giây, renew mỗi 10 giây và có fencing counter trong DB. Room cũ đã mất lease không được ghi tài sản. Chuyển map theo reserve → freeze → commit lease/checkpoint → join đích; lỗi thì abort hoặc phục hồi ở safe spawn, không để hai room cùng ghi character.

## 7. Luật gameplay v0.1

Thông số dưới đây là điểm xuất phát để lập trình và playtest, chưa phải cân bằng đã kiểm chứng.

| Hệ thống | Quy tắc alpha |
|---|---|
| Loadout | 4 active từ rank I, 2 passive từ rank II; không trùng definition; đổi trong safe zone và ngoài combat 5 giây |
| Mana | Max100 cơ sở; cost=`ceil(maxMana×costPct/100)`; hồi 1/s trong combat,2/s sau5 giây ngoài combat |
| Capture | Target capturable, owner là mình, HP≤30%, range≤3 tile; channel 2 giây; roll 70% server; seal tiêu khi start hợp lệ |
| Hunger | 0–100; equipped online giảm 1/5 phút; offline/un-equipped dừng; food đúng loại+40 cap100 |
| Cổ đói | Hunger 1–19: damage/heal/shield output×0,8; hunger 0 ngủ, active/passive vô hiệu; Cổ không chết |
| Refine | 2 instance Cổ I khác nhau +3 MAT-02 +2 MAT-05 +100 currency → 1 Cổ II; inputs unlocked/unequipped |
| Craft pity | Rate=min(100,70+10×failCount)%; fail giữ 2 Cổ, mất material/phí; success mất 2 Cổ, reset pity |
| Bag | 30ô; material/food/seal stack 99; Gu un i q u e 1 ô; equipped vẫn chiếm ô, loadout là reference |
| Overflow | Reward vào inbox 100 entry, không expire alpha; đầy cả bag/inbox thì chặn nguồn reward mới có cảnh báo |
| Death | PvE chờ 5 giây về safe spawn; mất min(50,5% tiền mềm), không mất Gu/item/XP; arena không penalty |
| PvP | Hai bên opt-in; countdown 3 giây, trận 180 giây; PvPdamage×0,7; hết giờ hòa; DC>30 giây xử thua |

Công thức damage alpha:

`damage = max(1, floor((basePower + 0.8 × attack) × rankFactor × hungerFactor × 100/(100+defense) × modeFactor))`

`rankFactor`: rank I=1,0; rank II=1,25. `modeFactor`: PvE=1,0; PvP=0,7. `hungerFactor`: hunger≥20 là1,0; hunger 1–19 là0,8; hunger 0 không cast. Shield hấp thụ damage trước HP. Không crit hoặc damage RNG trong alpha để việc kiểm tra dễ hơn.

Heal/shield dùng `floor((basePower + 0.5 × attack) × rankFactor × hungerFactor)`; shield tổng tối đa 40% maxHP. Giá trị buff trong catalog có đơn vị riêng: Kim Chung+defense; Du Cương+% speed; Địa Thính+4 tile minimap nhưng không vượt dữ liệu AOI được phép xem. Slow 30%; cùng loại lấy mạnh nhất. Stun PvP tối đa 2 giây; refresh không cộng dồn vô hạn. Mana và cooldown tiêu khi cast được accept; cast bị reject không tiêu; interrupt sau accept không refund.

XP tích lũy đến levelL: `50×(L−1)×L`. Level 10 cần 4500 XP, level 20 cần 19000 XP. Attack cơ sở=`10+2×(L−1)`, defense=`5+(L−1)`, HP=`200+20×(L−1)`. Thăng rank II cần level 10, Q08 đã claim,500 currency và 10 MAT-02. Tám quest chính cộng 4500 XP và có thưởng đá trước rank-up, tránh vòng prerequisite cần Cổ II để mở rank II.

Farm cung cấp tiền mềm, thức ăn, nguyên liệu và nguồn Cổ I. Mọi Cổ bound trong MVP. NPC dùng giá cố định; chưa có kinh tế trao đổi giữa người chơi. Cần theo dõi nguồn/tiêu tiền, chi phí feed, số lần craft và tỷ lệ kẹt tài nguyên; không thêm thị trường tự do trước khi ledger và chống dupe đạt G3.

## 8. FSD và cách kiểm soát thay đổi

Bộ FSD có **55 yêu cầu chức năng:30 Client,18 Server,7 GM/Admin**, cộng **12 NFR**. Mỗi yêu cầu có ID duy nhất, mô tả hành vi, input, output, validation/exception, acceptance criteria, WBS và testcase. Không để Requirement ID trống như phần lớn các dòng trong mẫu.

Ví dụ truy vết tính năng luyện Cổ: `CL-018/CL-019 → BR-13/BR-14 → UC-07 → SV-008/SV-011 → T09-CL/T09-SV → TC-CL-019 + E2E-02/E2E-03`. Retry cùng UUID phải trả đúng receipt cũ; không roll lại và không trừ nguyên liệu lần hai.

Ví dụ chuyển map: `CL-006/CL-027 → BR-21 → UC-11 → SV-004 → T12-CL/T12-SV → E2E-04`. Kill process ở từng bước transfer phải chứng minh tối đa một writer và không thay đổi tài sản sai.

Change request cần ghi vấn đề, Requirement ID bị ảnh hưởng, giải pháp, effort, owner, dependency, test bổ sung và feature bỏ đi hoặc lịch đổi. GD cập nhật scope; CL/SV đánh giá kỹ thuật; AR đánh giá content; cả đội chốt trước khi đưa vào sprint. Feature không thuộc MVP giữ ở backlog P2/P3.

### Player Client

| ID | Chức năng | Tiêu chí nghiệm thu tiêu biểu |
|---|---|---|
| CL-001 | Đăng nhập bằng tài khoản mời | Tài khoản hợp lệ vào được; sai/expired không vào room. |
| CL-002 | Tạo và chọn nhân vật | Hai request đồng thời chỉ tạo 1 nhân vật và 1 starter kit. |
| CL-003 | Click-to-move isometric | Đi quanh vật cản; click liên tục không xuyên tường; UI click không di chuyển. |
| CL-004 | Camera và depth sorting | Đi sau/trước 10 props không đảo layer; 1366×768 và 1920×1080 dùng được. |
| CL-005 | Chọn và tương tác mục tiêu | Không mở NPC ở xa; mục tiêu biến mất không gây lỗi UI. |
| CL-006 | Minimap và cổng map | Chuyển map không xuất hiện hai bản nhân vật; minimap đúng collision/portal. |
| CL-007 | Thanh Cổ Q/W/E/R | Bốn hotkey và click đều hoạt động; skill chưa đủ điều kiện báo cùng mã lỗi. |
| CL-008 | Thi triển chỉ mục tiêu/điểm đất/tự thân | Mỗi mode ít nhất 1 skill kiểm thử; không đánh xuyên vật cản LOS. |
| CL-009 | HP và Chân Nguyên | UI đúng số server sau cast, hồi phục và reconnect. |
| CL-010 | Buff, debuff và combat feed back | Stun/slow đúng duration; mute tắt được audio; denied khác hit. |
| CL-011 | Chết và hồi sinh | Một death chỉ một penalty; quest/Gu vẫn còn sau hồi sinh. |
| CL-012 | Đánh quái và nhận loot | Hai client đánh cùng quái chỉ một owner nhận reward; retry không nhân đôi. |
| CL-013 | Túi 30 ô và stack | Stack 98+3 thành 99+2; không tạo/xóa item bằng sort. |
| CL-014 | Tooltip và khóa Cổ | Tooltip khớp catalog; khóa có hiệu lực sau reconnect. |
| CL-015 | Trang bị và tháo Cổ | Swap nguyên tử; không tồn tại 1 Gu ở 2 slot; stats không cộng lặp. |
| CL-016 | Bắt Hoang Cổ | Hai người bắt cùng spawn chỉ một người giữ claim; chết/bắt chỉ một terminal result. |
| CL-017 | Cho ăn và trạng thái đói | Feed một lần +40 cap100; online/offline không bị tính đôi. |
| CL-018 | Chọn công thức và preview | Preview và server dùng cùng configVersion; không có xác suất ẩn. |
| CL-019 | Thực hiện luyện và xem kết quả | Retry 20 lần cùng ID trả cùng kết quả và chỉ tiêu hao một lần. |
| CL-020 | Cấp 1–20 và Nhất/Nhị Chuyển | Level 10 chưa thăng rank không trang bị Cổ II; rank-up lặp không tiêu thêm. |
| CL-021 | 10 quest và tracker | Progress reconnect còn đúng; Q08 chỉ mở Q09 khi rank II. |
| CL-022 | Mua/bán với NPC | Mua/bán concurrent không âm tiền/item; 1 receipt cho 1 request. |
| CL-023 | Party tối đa 3 người | Hai invite đồng thời không làm người chơi ở2 party; thành viên 4 bị chặn. |
| CL-024 | Chat zone/party, mute/report | Chat chỉ tới người đúng channel; gõ QWER trong chat không cast. |
| CL-025 | Phụ bản 1–3 người và boss | Ba người vào đúng một run; boss chết lặp không tạo thêm reward. |
| CL-026 | PK opt-in 1v1 | Một trận có 1 result; không mất Cổ/tiền do chết arena; loadout không sửa giữa trận. |
| CL-027 | Mất kết nối và trở lại | Rút mạng 10 giây trở lại cùng nhân vật; inventory không nhân đôi. |
| CL-028 | Thiết lập PC và lưu tùy chọn | Reload giữ tùy chọn; trình duyệt chặn autoplay thì mở audio sau gesture. |
| CL-029 | 30 giây đầu và tutorial | ≥80% trong tối thiểu 10 tester hoàn thành phần điều khiển ≤3 phút không người hướng dẫn. |
| CL-030 | Danh mục Cổ và build | 20/20 Cổ có tooltip đủ số; Cổ chưa sở hữu không equip được. |

### Server & Persistence

| ID | Chức năng | Tiêu chí nghiệm thu tiêu biểu |
|---|---|---|
| SV-001 | Xác thực và vòng đời session | Tokenless hoặc token account khác không đọc/chơi character. |
| SV-002 | Server giữ quyền quyết định | Sửa HP/mana/position trên client không thay state server. |
| SV-003 | Lọc trạng thái theo vùng quan tâm | Packet inspection không thấy túi đồ người khác hoặc entity ngoài AOI. |
| SV-004 | Chuyển map không trùng nhân vật | Kill process ở từng bước: tối đa 1 writer; không mất bag/đổi tiền. |
| SV-005 | Giải quyết cast và trạng thái | 10negative cases mỗi primitive bị chặn; 1 cast không gây hit trùng. |
| SV-006 | AI, respawn và quyền thưởng | Leash heal/reset đúng; hai kill callbacks chỉ một terminal transition. |
| SV-007 | Lưu bền vững và checkpoint | Kill/restart sau ACK: item/tiền còn đúng; vị trí có thể rollback≤30s. |
| SV-008 | Ledger và idempotency | 20 retry/2 socket của craft, buy, feed chỉ một hiệu lực; ledger cân đối. |
| SV-009 | Reward inbox khi đầy túi | Bag đầy khi kill: reward còn trong inbox sau reconnect, claim 1 lần. |
| SV-010 | Săn bắt và hunger server | Feed/reconnect không reset timer để né đói;0 hunger khóa active/passive. |
| SV-011 | Công thức, pity và roll server | Không output khi rollback; success tiêu 2 Gu; fail giữ 2 Gu; cả 2 mất material/fee. |
| SV-012 | XP, quest và rank-up từ event server | Replay 100 event không tăng progress lần 2; rank-up chỉ một phí. |
| SV-013 | Party và recipient authorization | User ngoài party không nghe/đọc được party channel; invite replay vô hiệu. |
| SV-014 | Dungeon và duel state machine | Repeated completion không cấp thêm loot; orphan rooms cleanup≤60s. |
| SV-015 | Data-driven và config version | 1 cấu hình lỗi bị chặn; rollback về version trước khôi phục đúng catalog. |
| SV-016 | Metrics, log và economy events | Tra một craft receipt thấy request/ledger/config; có alert DB unavailable/tick trễ. |
| SV-017 | Backup, restore và rollback | Restore vào DB rỗng đạt RTO≤2h/RPO≤24h; restart crash khác disaster restore. |
| SV-018 | Schema, quota và session fencing | Fuzz malformed không crash; stale room không ghi DB; người chơi không vào GM API. |

### GM / Admin

| ID | Chức năng | Tiêu chí nghiệm thu tiêu biểu |
|---|---|---|
| AD-001 | Đăng nhập GM và RBAC | Player và GM_READ không ban/grant; mọi thao tác đặc quyền có audit. |
| AD-002 | Tra cứu nhân vật và receipt | GM_READ xem được lịch sử craft bằng requestId mà không sửa dữ liệu. |
| AD-003 | Mute/ban và xử lý report | Banned không join lại; mute không gửi chat; hết hạn tự gỡ. |
| AD-004 | Cấp vật phẩm có kiểm soát | Grant bị lặp chỉ 1 receipt; tra được người làm/lý do/giá trị trước-sau. |
| AD-005 | Publish/rollback config qua pipeline | 1 invalid foreign key chặn publish; rollback dùng bundle bất biến. |
| AD-006 | Dashboard vận hành tối thiểu | DB mất kết nối hiện cảnh báo trong60s; số CCU khớp active lease. |
| AD-007 | Audit bất biến qua API | Ban/grant/role/config đều có log; GM không xóa được qua API. |

## 9. WBS, thứ tự triển khai và dependency

WBS có 72 leaf packages, nhóm dưới 6 deliverable lớn. Mỗi package có một owner chính và một khung 2 tuần; effort có đơn vị PD hữu ích. Quan hệ predecessor trong Excel là finish-to-start giữa các sprint. Trong cùng sprint, chủ động chia nửa đầu xây/integrate và nửa sau test/review; việc phối hợp không tạo thêm một người làm toàn thời gian.

| Nhóm | Deliverable | Packages | Base PD | Reserve PD | Total PD |
|---|---|---|---|---|---|
| 1.0 | Khóa phạm vi và spike | 4 | 11.0 | 2.2 | 13.2 |
| 2.0 | Nền tảng kỹ thuật | 12 | 32.5 | 6.5 | 39.0 |
| 3.0 | PvE first playable | 8 | 22.5 | 4.5 | 27.0 |
| 4.0 | Vòng lặp Cổ và progression | 24 | 66.0 | 13.2 | 79.2 |
| 5.0 | Nội dung multiplayer giới hạn | 12 | 33.0 | 6.6 | 39.6 |
| 6.0 | Ổn định và closed alpha | 12 | 34.0 | 6.8 | 40.8 |

Các chuỗi quyết định tiến độ: **CL spike → shell → movement → sync → combat → inventory → capture/feed → refine → progression → content → reconnect → social/instance → polish → RC**; và chuỗi server tương ứng **auth → lease → movement → combat → atomic persistence → economy → recovery → instances → operation tests**. Đây là chuỗi kiểm soát theo lịch và tài nguyên đã phân; chưa phải báo cáo CPM có tính float.

Các hạng mục không được triển khai đảo thứ tự: transaction/receipt trước trade hoặc reward nhiều người; server combat trước PvP; capture/feed/refine trước content expansion; crash/reconnect trước alpha; backup/restore và metrics trước mở host cho tester từ xa.

## 10. Roadmap theo 18 sprint

| Sprint / tuần | Trọng tâm | Đầu ra để review | Gate |
|---|---|---|---|
| S01 / W1–2 | Scope + spike | Map mẫu, click-to-move, đo render trên máy tham chiếu; Hai client kết nối; server giữ state; thử ghi transaction | — |
| S02 / W3–4 | Luật + nền tảng | Boot/Login/World/HUD; world↔iso; loader và input; CI build; migration; tài khoản mời; session một nhân vật | G0 |
| S03 / W5–6 | Điều khiển + session | A*, camera bám, click marker, target vòng chọn; Join/leave có auth; single writer; giới hạn map | — |
| S04 / W7–8 | Realtime + AOI | Remote players; correction; HUD mạng; không ghost entity; Validate đường đi/tốc độ; state lọc theo vùng; chống warp | G1 |
| S05 / W9–10 | Combat 5 Cổ | QWER, chọn mục tiêu, telegraph, cooldown, hit feed back; Range/LOS/cooldown/mana; damage, shield, slow, stun | — |
| S06 / W11–12 | PvE và loot | Nameplate, loot popup, respawn, NPC interaction; FSM idle/aggro/chase/attack/leash/dead; reward exactly once | G2 |
| S07 / W13–14 | Bag / loadout / atomic economy | 30 ô; drag/click equip; 4 active + 2 passive; Lock/version; ledger; request ID; atomic reward/equip | — |
| S08 / W15–16 | Capture / feed | Thanh channel bắt Cổ; xác nhận đồ ăn; preview phục hồi; Target claim; roll server; atomic seal/food/reward/hunger | — |
| S09 / W17–18 | Refine / pity / receipt | Chọn instance, recipe, preview tỷ lệ; request retry; Atomic consume/RNG/pity/output/ledger; crash/retry tests | — |
| S10 / W19–20 | Quest / rank / NPC shop | Nhận/trả quest; shop fixed price; kiểm tra rank; Event quest; atomic claim/rank-up/buy/sell; caps | — |
| S11 / W21–22 | 20 Cổ / content validator | 20 Cổ data-driven; status icons; mô tả đầy đủ; 8 primitive; passive stack policy; schema/version checks | — |
| S12 / W23–24 | Recovery / core loopE2E | Overlay mất mạng; resync bag/status; không gửi lệnh cũ; Lease fencing; reserve/commit transfer; durable state resync | G3 |
| S13 / W25–26 | Party / chat | Mời/đồng ý/rời; leader UI; mute/report; focus input; Membership; invite TTL; rate limit; server recipient filter | — |
| S14 / W27–28 | Dungeon / boss | Entry vote, boss HP, kết quả; AoE dễ đọc; 3 người/15 phút; boss 2 pattern; run ID; cleanup | — |
| S15 / W29–30 | Duel opt-in | Invite/ready/countdown/result; quay lại safe spawn; Two opt-ins; PvP damage factor; no reward farming | G4 |
| S16 / W31–32 | GM / metrics / feature freeze | GM tra cứu/read-only; âm lượng/phím/đồ họa; role guard; RBAC/mute/ban/grant; config publish; daily snapshot | — |
| S17 / W33–34 | UAT / load / performance | FPS p95 frame time; asset budget; Windows matrix và Web spike; 50 CCU toàn shard/20 map; duplicate, kill/restart, expiry | — |
| S18 / W35–36 | RC / restore / alpha report | Client RC tag; smoke test; known issues; rollback compatible; Staging→private alpha; restore đo RPO/RTO; rollback diễn tập | G5 |

Các mốc G0–G5 có exit criteria trong sheet 15_GATES. G2 là first playable. G3 là bản đủ core loop nội bộ. G5 là closed alpha và báo cáo thử nghiệm 7 ngày; không phải commercial launch. Feature freeze ở cuốiS16/tuần 32; S17–18 tập trung UAT, load/fault/security, sửa lỗi, restore và release.

## 11. Công suất, effort và phương án ít giờ hơn

Công suất hữu ích của đội: `4×36 tuần×20 giờ×75% ÷8=270 PD`. Công việc gồm dự phòng là 238,8 PD; còn 31,2 PD so với công suất tổng. Khoảng trống này phân bố không đều và không tự chuyển từ artist sang server được.

| Vai trò | Cơ sở / Gồm dự phòng | Công suất | Còn lại |
|---|---|---|---|
| GD | 47.0 / 56.4 PD | 67.5 PD | 11.1 PD |
| CL | 54.0 / 64.8 PD | 67.5 PD | 2.7 PD |
| SV | 54.0 / 64.8 PD | 67.5 PD | 2.7 PD |
| AR | 44.0 / 52.8 PD | 67.5 PD | 14.7 PD |

Mỗi sprint 2 tuần có3,75 PD hữu ích/người. Package client/server3 PD cơ sở +20%=3,6 PD, dùng 96% công suất hữu ích của người đó. Nếu hai kỹ sư chỉ làm 15 giờ/tuần trong khi người khác làm 20 giờ, kế hoạch vẫn bị quá tải ở hai vai trò này; không dùng tổng giờ cả đội để che bottleneck.

| Giờ/người/tuần, cả 4 người cùng mức | Quy đổi theo công suất | Cách sử dụng |
|---|---|---|
| 10 | Khoảng 72 tuần | Cần chia task nhỏ và giữ scope rất hẹp |
| 15 | Khoảng 48 tuần | Cần lập lại WBS theo availability thực tế |
| 20 | Phương án cơ sở 36 tuần | 18 sprint×2 tuần |
| 30 | Khoảng 24 tuần | Chỉ là quy đổi effort, còn ràng buộc tích hợp và test |
| 40 | Khoảng 18 tuần | Không hứa tuyến tính; cần rebaseline và kiểm tra lại spike |

Các con số quy đổi giữ nguyên scope, focus và reserve; không tự nén ngày của các dependency. Nếu chỉ còn 1–2 người, kế hoạch 4 người không còn áp dụng: ưu tiên solo/local hoặc multiplayer 2 người với 5–8 Cổ,1 map, không party/dungeon/duel trước khi ước lượng lại.

## 12. Không ngân sách và điều kiện mở alpha

Nhân sự là công sức đóng góp.199 PD cơ sở tương đương 1592 giờ hữu ích; dự phòng 318,4 giờ. Không coi giờ công là miễn phí về mặt công suất chỉ vì không trả lương. Sheet 22_COST tách giá trị công sức và cash; đơn giá 0 là placeholder/mục tiêu, không phải báo giá đã xác nhận.

Trong giai đoạn phát triển, dùng máy sẵn có và local/LAN; tự tạo hoặc dùng asset có nguồn sử dụng rõ ràng, ghi manifest từ lúc nhập. Chưa cần domain hoặc dịch vụ phân phối desktop. Với hosting miễn phí nếu có, phải kiểm tra quota, khả năng chạy WebSocket liên tục, sleep, RAM, storage và backup ở thời điểm lựa chọn; tài liệu này không giả định có một dịch vụ miễn phí đáp ứng sẵn.

Trước S16 cần chốt host cho tester từ xa và nơi backup độc lập với máy chạy. Nếu chưa có tài nguyên hoặc ngân sách phù hợp, kết quả của G5 được giới hạn thành local/LAN alpha; không cam kết máy chủ Internet 24/7. Mọi chi phí phát sinh được điền vào sheet 22_COST bằng báo giá thực tế trước khi quyết định.

## 13. Kiểm thử và Definition of Done

Bộ test có 79 dòng kế hoạch:55 test theo chức năng,12 test theo NFR và 12 luồng E2E. Tất cả testcase alpha ở trạng thái **Chưa chạy**. Test prototype Godot được báo cáo riêng, không chuyển trạng thái alpha. Kiểm tra tính nhất quán của tài liệu không đồng nghĩa game đã được kiểm thử hoặc các NFR đã đạt.

Một package chỉ Done khi: đầu ra chạy/đọc được; acceptance criteria của yêu cầu liên quan đạt; code/content được peer review; có test phù hợp rủi ro; lỗi mới đã ghi; schema/protocol/config/docs được cập nhật nếu thay đổi; có evidence gắn build/config. Test sửa giao diện nhỏ ưu tiên kiểm tra trực quan; transaction/reward/recovery bắt buộc có test hành vi và fault/concurrency.

Các tình huống bắt buộc trước alpha: gửi cùng economic request 20 lần và hai socket đồng thời; kill process trước/saucommit/trước ACK; capture và last-hit cùng tick; chuyển map khi room đích đầy hoặc room nguồn chết; bag/inbox đầy; stale lease; token account khác; client gọi GM grant; chat XSS; reconnect trong combat/craft; boss reward lặp; duel DC; restore DB và rollback release.

Mục tiêu NFR chính: client median FPS≥50 và frame time p95≤33ms trong scene tham chiếu; ACK p95≤250ms với RTT100ms; tick p95≤40ms ở20Hz;50CCU/2 giờ;0 giao dịch đã ACK bị mất khi process crash; disaster restore RPO≤24h/RTO≤2 giờ. Sheet 06_NFR ghi rõ điều kiện, máy và evidence để phân biệt mục tiêu với kết quả đo.

Phân loại lỗi: **P0** mất/nhân tài sản, truy cập đặc quyền nghiêm trọng hoặc hỏng dữ liệu; **P1** chặn core loop/đăng nhập/phụ bản bắt buộc; **P2** chức năng suy giảm có workaround; **P3** hiển thị. G5 cần 0 P0/P1; P2/P3 phải được ghi known issues và người chịu trách nhiệm.

## 14. Rủi ro và thứ tự cắt phạm vi

Rủi ro lớn nhất là availability và năng lực hai vai trò client/server. Theo dõi giờ thật và task carryover ngay hai sprint đầu. Nếu tải vượt công suất hoặc trễ hơn một sprint, chốt lại kế hoạch ở gate gần nhất thay vì âm thầm kéo dài.

Thứ tự cắt đề xuất: duel → chat/report nâng cao → party và dungeon chuyển sau core alpha →20 Cổ giảm 12 →6 quái giảm 4 →map/asset phụ giảm. Party bị cắt thì chuyển dungeon sang solo hoặc hoãn cả hai; không để lại dependency hỏng. Sau mỗi lần cắt phải cập nhật FSD/WBS/test và ước lượng lại, không cộng trừ tuần tùy ý.

Các mục giữ lại: authoritative combat, ownership/lease, transaction, idempotency, ledger, recovery, backup/restore và core loop capture/feed/refine. Nếu mất một thành viên, rebaseline theo ba vai trò còn lại và giảm content/social; deadline 4 người không còn cơ sở.

Về tên và hình ảnh: GuMaster2D là tên làm việc; Cổ Chân Nhân/Võ Lâm là tham chiếu thiết kế trong ý tưởng. Chủ dự án cần chốt tên, nội dung và nguồn asset được sử dụng trước khi phát hành công khai; kế hoạch không mặc định đã có asset hoặc quyền thương hiệu.

## 15. Việc làm ngay trong hai tuần đầu

| Owner | Tuần 1 | Tuần 2 | Đầu ra review cuối S01 |
|---|---|---|---|
| GD/QA | Điền availability thật; chốt fantasy/core loop; đánh dấu MVP/P2; mở decision log | Rà FSD, test matrix, quest và economy rủi ro; chuẩn bị gate G0 | Scope/FSDv0.2, danh sách TBD và 3 build cần test |
| Client | Spike projection 64×32, click-to-move, camera và depth sort | Ghép scene/HUD tạm; đo FPS/payload; ghi hạn chế | Demo PC2–3 phút và báo cáo máy/engine/OS |
| Server | Spike 2 client/auth/room; validate move; PostgreSQL transaction | Retry command; simulatecrash; viết prototype single writer | Demo 2 client + evidence 1 request/1 receipt |
| 2D/Content | Moodboard, style guide, danh mục asset/nguồn; test tile/sprite | Avatar 4 hướng cơ bản, tileset mẫu; 5 icon Cổ; đo kích thước | Bộ asset dùng được + manifest + list phần phải tự tạo |

Kickoff 90 phút cần chốt bốn điều: ai nhận bốn vai trò; mỗi người cam kết bao nhiêu giờ/tuần; dùng Godot PC native làm bản đầu và spike Web; có đồng ý phạm vi và các luật alpha đề xuất không. Những điểm này là quyết định triển khai nội bộ sau khi đọc kế hoạch, không phải điều kiện để tạo bộ tài liệu.

Sau S01, dùng kết quả spike và giờ thực tế để chỉnh estimate; cuối S02/G0 mới khóa baseline. Nếu không chứng minh được nền tảng hoặc availability, giảm scope ngay trước khi sản xuất nhiều content.

## 16. Trạng thái bàn giao

Đã có bộ tài liệu và prototype Godot chơi đơn: movement,4 Cổ, AI, capture/feed, local save. Các gói client liên quan mới triển khai một phần; chưa đạt gate alpha, chưa benchmark mục tiêu, chưa chạy 79 testcase alpha, chưa duyệt scope và chưa triển khai máy chủ. Evidence prototype nằm tại docs/game-studio/quality-report.md; không thay cho acceptance online. Các chỉ số hiệu năng và trải nghiệm là tiêu chí nghiệm thu của dự án tương lai.

Tài liệu tham chiếu chính: ý tưởng đính kèm; DAUN-FSD [EN].xlsx; ràng buộc 4 người/không ngân sách/PC trước trong chat. Các liên kết tài liệu công nghệ được lưu tại sheet 24_SOURCES và phần 5; đối chiếu ngày 07/10/2026. Khi khởi động, đội pin phiên bản dependency đã spike, không tự dùng API của phiên bản khác.
