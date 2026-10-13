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

36 tuần /199PD vẫn là forecast phạm vi alpha ban đầu; chưa re-estimate theo năng lực Godot của đội. Sau spike online/DB cần rebaseline và cập nhật ngày. Mobile, patcher, signing và store distribution là đầu việc mới.

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
| Cổ | Owned / Equipped; hunger0 → Dormant; feed hợp lệ → Active; khóa chống consume nhầm |
| Craft | Preview → Requested → Validated → Committed / Rejected; UI timeout là Unknown, phải query receipt |
| Quest | Locked → Available → Active → Completed → Claimed; reward và claimed ghi cùng transaction |
| Dungeon | Created → Ready → Running → Won / Failed → Closed; reward unique theo run/character |
| Duel | Invited → Ready → Countdown → Running → Won / Draw / Forfeit → Closed |

Một character chỉ có một active write lease. Lease thử nghiệm TTL30 giây, renew mỗi10 giây và có fencing counter trong DB. Room cũ đã mất lease không được ghi tài sản. Chuyển map theo reserve → freeze → commit lease/checkpoint → join đích; lỗi thì abort hoặc phục hồi ở safe spawn, không để hai room cùng ghi character.

## 7. Luật gameplay v0.1

Thông số dưới đây là điểm xuất phát để lập trình và playtest, chưa phải cân bằng đã kiểm chứng.

| Hệ thống | Quy tắc alpha |
|---|---|
| Loadout | 4 active từ rankI, 2 passive từ rankII; không trùng definition; đổi trong safe zone và ngoài combat5 giây |
| Mana | Max100 cơ sở; cost=`ceil(maxMana×costPct/100)`; hồi1/s trong combat,2/s sau5 giây ngoài combat |
| Capture | Target capturable, owner là mình, HP≤30%, range≤3tile; channel2 giây; roll70% server; seal tiêu khi start hợp lệ |
| Hunger | 0–100; equipped online giảm1/5phút; offline/un-equipped dừng; food đúng loại+40 cap100 |
| Cổ đói | Hunger1–19: damage/heal/shield output×0,8; hunger0 ngủ, active/passive vô hiệu; Cổ không chết |
| Refine | 2instance CổI khác nhau +3MAT-02 +2MAT-05 +100currency → 1CổII; inputs unlocked/unequipped |
| Craft pity | Rate=min(100,70+10×failCount)%; fail giữ2Cổ, mấtmaterial/phí; success mất2Cổ, resetpity |
| Bag | 30ô; material/food/seal stack99; Gu unique1ô; equipped vẫn chiếmô, loadout làreference |
| Overflow | Reward vào inbox100entry, khôngexpire alpha; đầy cảbag/inbox thì chặn nguồnreward mới có cảnh báo |
| Death | PvE chờ5giây vềsafe spawn; mấtmin(50,5%tiền mềm), khôngmấtGu/item/XP; arena khôngpenalty |
| PvP | Hai bên opt-in; countdown3giây, trận180giây; PvPdamage×0,7; hếtgiờhòa; DC>30giây xửthua |

Công thức damage alpha:

`damage = max(1, floor((basePower + 0.8 × attack) × rankFactor × hungerFactor × 100/(100+defense) × modeFactor))`

`rankFactor`: rankI=1,0; rankII=1,25. `modeFactor`: PvE=1,0; PvP=0,7. `hungerFactor`: hunger≥20 là1,0; hunger1–19 là0,8; hunger0 khôngcast. Shield hấp thụ damage trước HP. Không crit hoặc damage RNG trong alpha để việc kiểm tra dễ hơn.

Heal/shield dùng `floor((basePower + 0.5 × attack) × rankFactor × hungerFactor)`; shield tổng tối đa40%maxHP. Giá trị buff trong catalog có đơn vị riêng: Kim Chung+defense; Du Cương+%speed; Địa Thính+4tile minimap nhưng không vượt dữ liệu AOI được phép xem. Slow30%; cùng loại lấy mạnh nhất. Stun PvP tối đa2giây; refresh không cộng dồn vô hạn. Mana và cooldown tiêu khi cast được accept; cast bị reject không tiêu; interrupt sau accept không refund.

XP tích lũy đến levelL: `50×(L−1)×L`. Level10 cần4500XP, level20 cần19000XP. Attack cơ sở=`10+2×(L−1)`, defense=`5+(L−1)`, HP=`200+20×(L−1)`. Thăng rankII cần level10, Q08 đã claim,500currency và10MAT-02. Tám quest chính cộng4500XP và có thưởng đá trước rank-up, tránh vòng prerequisite cần CổII để mở rankII.

Farm cung cấp tiền mềm, thức ăn, nguyên liệu và nguồn CổI. Mọi Cổ bound trong MVP. NPC dùng giá cố định; chưa có kinh tế trao đổi giữa người chơi. Cần theo dõi nguồn/tiêu tiền, chi phí feed, số lần craft và tỷ lệ kẹt tài nguyên; không thêm thị trường tự do trước khi ledger và chống dupe đạt G3.

## 8. FSD và cách kiểm soát thay đổi

Bộ FSD có **55 yêu cầu chức năng:30Client,18Server,7GM/Admin**, cộng **12NFR**. Mỗi yêu cầu có ID duy nhất, mô tả hành vi, input, output, validation/exception, acceptance criteria, WBS và testcase. Không để Requirement ID trống như phần lớn các dòng trong mẫu.

Ví dụ truy vết tính năng luyện Cổ: `CL-018/CL-019 → BR-13/BR-14 → UC-07 → SV-008/SV-011 → T09-CL/T09-SV → TC-CL-019 + E2E-02/E2E-03`. Retry cùng UUID phải trả đúng receipt cũ; không roll lại và không trừ nguyên liệu lần hai.

Ví dụ chuyển map: `CL-006/CL-027 → BR-21 → UC-11 → SV-004 → T12-CL/T12-SV → E2E-04`. Kill process ở từng bước transfer phải chứng minh tối đa một writer và không thay đổi tài sản sai.

Change request cần ghi vấn đề, Requirement ID bị ảnh hưởng, giải pháp, effort, owner, dependency, test bổ sung và feature bỏ đi hoặc lịch đổi. GD cập nhật scope; CL/SV đánh giá kỹ thuật; AR đánh giá content; cả đội chốt trước khi đưa vào sprint. Feature không thuộc MVP giữ ở backlog P2/P3.

{{FSD_SUMMARY}}

## 9. WBS, thứ tự triển khai và dependency

WBS có72leafpackage, nhóm dưới6deliverable lớn. Mỗi package có một owner chính và một khung2tuần; effort có đơn vịPD hữuích. Quan hệ predecessor trong Excel là finish-to-start giữa các sprint. Trong cùng sprint, chủ động chia nửa đầu xây/integrate và nửa sau test/review; việc phối hợp không tạo thêm một người làm toàn thời gian.

{{PHASE_SUMMARY}}

Các chuỗi quyết định tiến độ: **CL spike → shell → movement → sync → combat → inventory → capture/feed → refine → progression → content → reconnect → social/instance → polish → RC**; và chuỗi server tương ứng **auth → lease → movement → combat → atomic persistence → economy → recovery → instances → operation tests**. Đây là chuỗi kiểm soát theo lịch và tài nguyên đã phân; chưa phải báo cáo CPM có tính float.

Các hạng mục không được triển khai đảo thứ tự: transaction/receipt trước trade hoặc reward nhiều người; server combat trước PvP; capture/feed/refine trước content expansion; crash/reconnect trước alpha; backup/restore và metrics trước mở host cho tester từ xa.

## 10. Roadmap theo 18 sprint

{{SPRINT_ROADMAP}}

Các mốc G0–G5 có exit criteria trong sheet15_GATES. G2 là first playable. G3 là bản đủ core loop nội bộ. G5 là closed alpha và báo cáo thử nghiệm7ngày; không phải commercial launch. Feature freeze ở cuốiS16/tuần32; S17–18 tập trung UAT, load/fault/security, sửa lỗi, restore và release.

## 11. Công suất, effort và phương án ít giờ hơn

Công suất hữu ích của đội: `4×36tuần×20giờ×75%÷8=270PD`. Công việc gồm dự phòng là238,8PD; còn31,2PD so với công suất tổng. Khoảng trống này phân bố không đều và không tự chuyển từ artist sang server được.

{{RESOURCE_SUMMARY}}

Mỗi sprint2tuần có3,75PD hữu ích/người. Package client/server3PD cơ sở +20%=3,6PD, dùng96% công suất hữu ích của người đó. Nếu hai kỹ sư chỉ làm15giờ/tuần trong khi người khác làm20giờ, kế hoạch vẫn bị quá tải ở hai vai trò này; không dùng tổng giờ cảđội để che bottleneck.

| Giờ/người/tuần, cả4người cùng mức | Quy đổi theo công suất | Cách sử dụng |
|---|---|---|
| 10 | Khoảng72tuần | Cần chia task nhỏ và giữ scope rất hẹp |
| 15 | Khoảng48tuần | Cần lập lại WBS theo availability thực tế |
| 20 | Phương án cơ sở36tuần | 18sprint×2tuần |
| 30 | Khoảng24tuần | Chỉ là quy đổi effort, còn ràng buộc tích hợp và test |
| 40 | Khoảng18tuần | Không hứa tuyến tính; cần rebaseline và kiểm tra lại spike |

Các con số quy đổi giữ nguyên scope, focus và reserve; không tự nén ngày của các dependency. Nếu chỉ còn1–2người, kế hoạch4người không còn áp dụng: ưu tiên solo/local hoặc multiplayer2người với5–8Cổ,1map,khôngparty/dungeon/duel trước khi ước lượng lại.

## 12. Không ngân sách và điều kiện mở alpha

Nhân sự là công sức đóng góp.199PD cơ sở tương đương1592giờ hữu ích; dự phòng318,4giờ. Không coi giờ công là miễn phí về mặt công suất chỉ vì không trả lương. Sheet22_COST tách giá trị công sức và cash; đơn giá0 là placeholder/mục tiêu, không phải báo giá đã xác nhận.

Trong giai đoạn phát triển, dùng máy sẵn có và local/LAN; tự tạo hoặc dùng asset có nguồn sử dụng rõ ràng, ghi manifest từ lúc nhập. Chưa cần domain hoặc dịch vụ phân phối desktop. Với hosting miễn phí nếu có, phải kiểm tra quota, khả năng chạy WebSocket liên tục, sleep, RAM, storage và backup ở thời điểm lựa chọn; tài liệu này không giả định có một dịch vụ miễn phí đáp ứng sẵn.

TrướcS16 cần chốt host cho tester từ xa và nơi backup độc lập với máy chạy. Nếu chưa có tài nguyên hoặc ngân sách phù hợp, kết quả của G5 được giới hạn thành local/LAN alpha; không cam kết máy chủ Internet24/7. Mọi chi phí phát sinh được điền vào sheet22_COST bằng báo giá thực tế trước khi quyết định.

## 13. Kiểm thử và Definition of Done

Bộ test có79dòng kế hoạch:55test theo chức năng,12test theoNFR và12luồngE2E. Tất cả testcase alpha ở trạng thái **Chưa chạy**. Test prototype Godot được báo cáo riêng, không chuyển trạng thái alpha. Kiểm tra tính nhất quán của tài liệu không đồng nghĩa game đã được kiểm thử hoặc các NFR đã đạt.

Một package chỉ Done khi: đầu ra chạy/đọc được; acceptance criteria của yêu cầu liên quan đạt; code/content được peer review; có test phù hợp rủi ro; lỗi mới đã ghi; schema/protocol/config/docs được cập nhật nếu thay đổi; có evidence gắn build/config. Test sửa giao diện nhỏ ưu tiên kiểm tra trực quan; transaction/reward/recovery bắt buộc có test hành vi và fault/concurrency.

Các tình huống bắt buộc trước alpha: gửi cùng economic request20lần và hai socket đồng thời; kill process trước/saucommit/trướcACK; capture và last-hit cùngtick; chuyểnmap khi room đích đầy hoặc room nguồn chết; bag/inbox đầy; stalelease; tokenaccountkhác; client gọiGMgrant; chatXSS; reconnect trongcombat/craft; bossreward lặp; duelDC; restoreDB và rollback release.

Mục tiêuNFR chính: client medianFPS≥50 vàframetimep95≤33ms trongscene thamchiếu; ACKp95≤250ms vớiRTT100ms; tickp95≤40ms ở20Hz;50CCU/2giờ;0giao dịch đãACK bị mất khi processcrash; disasterrestoreRPO≤24h/RTO≤2giờ. Sheet06_NFR ghi rõ điều kiện, máy và evidence để phân biệt mục tiêu với kết quả đo.

Phân loại lỗi: **P0** mất/nhân tài sản, truy cập đặc quyền nghiêm trọng hoặc hỏng dữ liệu; **P1** chặn core loop/đăng nhập/phụ bản bắt buộc; **P2** chức năng suy giảm có workaround; **P3** hiển thị. G5 cần0P0/P1;P2/P3 phải được ghi knownissues và người chịu trách nhiệm.

## 14. Rủi ro và thứ tự cắt phạm vi

Rủi ro lớn nhất là availability và năng lực hai vai trò client/server. Theo dõi giờ thật và taskcarryover ngay hai sprint đầu. Nếu tải vượt công suất hoặc trễ hơn một sprint, chốt lại kế hoạch ở gate gần nhất thay vì âm thầm kéo dài.

Thứ tự cắt đề xuất: duel → chat/report nâng cao → party và dungeon chuyển sau core alpha →20Cổ giảm12 →6quái giảm4 →map/asset phụ giảm. Party bị cắt thì chuyển dungeon sang solo hoặc hoãn cảhai; không để lại dependency hỏng. Sau mỗi lần cắt phải cập nhật FSD/WBS/test và ước lượng lại, không cộng trừ tuần tùy ý.

Các mục giữ lại: authoritative combat, ownership/lease, transaction, idempotency, ledger, recovery, backup/restore và coreloopcapture/feed/refine. Nếu mất một thành viên, rebaseline theo ba vai trò còn lại và giảmcontent/social; deadline4người không còn cơ sở.

Về tên và hình ảnh: GuMaster2D là tên làm việc; Cổ Chân Nhân/Võ Lâm là tham chiếu thiết kế trong ý tưởng. Chủ dự án cần chốt tên, nội dung và nguồn asset được sử dụng trước khi phát hành công khai; kế hoạch không mặc định đã có asset hoặc quyền thương hiệu.

## 15. Việc làm ngay trong hai tuần đầu

| Owner | Tuần1 | Tuần2 | Đầu ra review cuốiS01 |
|---|---|---|---|
| GD/QA | Điền availability thật; chốt fantasy/coreloop; đánh dấu MVP/P2; mở decisionlog | Rà FSD, test matrix, quest và economy rủi ro; chuẩn bị gateG0 | Scope/FSDv0.2, danh sáchTBD và3build cầntest |
| Client | Spike projection64×32, click-to-move, camera và depthsort | Ghép scene/HUD tạm; đoFPS/payload; ghi hạn chế | DemoPC2–3phút và báo cáo máy/engine/OS |
| Server | Spike2client/auth/room; validate move; PostgreSQL transaction | Retry command; simulatecrash; viết prototype singlewriter | Demo2client + evidence1request/1receipt |
| 2D/Content | Moodboard, styleguide, danh mụcasset/nguồn; testtile/sprite | Avatar4hướng cơbản, tilesetmẫu; 5iconCổ; đo kíchthước | Bộasset dùngđược + manifest + listphầnphải tựtạo |

Kickoff90phút cần chốt bốn điều: ai nhận bốn vai trò; mỗi người cam kết bao nhiêu giờ/tuần; dùng Godot PC native làm bảnđầu và spike Web; có đồng ý phạmvi và các luậtalpha đềxuất không. Những điểm này là quyết định triển khai nội bộ sau khi đọc kế hoạch, không phải điều kiện để tạo bộ tài liệu.

SauS01, dùng kết quảspike và giờ thực tế để chỉnh estimate; cuốiS02/G0 mới khóa baseline. Nếu không chứng minh được nền tảng hoặc availability, giảmscope ngay trước khi sản xuất nhiều content.

## 16. Trạng thái bàn giao

Đã có bộ tài liệu và prototype Godot chơi đơn: movement,4Cổ,AI,capture/feed,local save. Các gói client liên quan mới triển khai một phần; chưa đạt gate alpha, chưa benchmark mục tiêu, chưa chạy79testcase alpha, chưa duyệt scope và chưa triển khai máy chủ. Evidence prototype nằm tại docs/game-studio/quality-report.md; không thay cho acceptance online. Các chỉ số hiệu năng và trải nghiệm là tiêu chí nghiệm thu của dự án tương lai.

Tài liệu tham chiếu chính: ý tưởng đính kèm; DAUN-FSD [EN].xlsx; ràng buộc4người/khôngngânsách/PCtrước trongchat. Các liên kết tài liệu công nghệ được lưu tại sheet24_SOURCES và phần5; đối chiếu ngày07/10/2026. Khi khởi động, đội pin phiên bản dependency đã spike, không tự dùng API của phiên bản khác.
