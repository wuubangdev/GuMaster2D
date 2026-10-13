# Timeline và pose map — bản chi tiết 04

Ngày 11/10/2026. Đây là thiết kế hình ảnh đề xuất dựa trên action/duration hiện có trong ANIMATION_AND_SKILLS.md. Các mốc dưới đây điều khiển pose và VFX trình bày, không được đổi gameplay authority, quãng đường, damage, invulnerability, mana, cooldown hoặc trạng thái save.

## 1. Gait

### Walk — một vòng 1.05 giây danh nghĩa

| Tỷ lệ vòng | Pose | Chân chịu lực | Thân/tay |
|---:|---|---|---|
| 0% | Contact A | A chạm đất, B đẩy mũi | tay B về trước; đầu gần ổn định |
| 12.5% | Down A | A nhận tải | hông hạ nhẹ, đầu bob tối thiểu |
| 25% | Passing B | A trụ, B đi qua | tay đổi vai cùng chân |
| 37.5% | Up B | A đẩy mũi | gót A nhấc; tóc/tà theo sau |
| 50% | Contact B | B chạm đất | đổi vai tay/chân |
| 62.5% | Down B | B nhận tải | hông thấp hơn một ít |
| 75% | Passing A | B trụ, A đi qua | arm opposition giữ ổn |
| 87.5% | Up A | B đẩy mũi | chuẩn bị contact đầu vòng |

Walk vẫn phải có chân chống; root actor đi theo vận tốc gameplay. Phase lấy quãng đường thật, không chạy loop cố định nếu nhân vật đứng yên.

### Run — một vòng 0.68 giây danh nghĩa

| Tỷ lệ vòng | Pose | Đọc silhouette |
|---:|---|---|
| 0% | Contact A | trọng tâm hướng tới trước |
| 12.5% | Compression A | gối nén, bàn chân ăn đất |
| 25% | Airborne A→B | flight ngắn, không bay kéo dài |
| 37.5% | Recovery B | chân B thu, tay chống vai |
| 50% | Contact B | chân B đặt, tà áo còn trễ |
| 62.5% | Compression B | gối/hông nhận lực |
| 75% | Airborne B→A | đường bay thấp, đầu không lắc quá |
| 87.5% | Recovery A | trở về contact có kiểm soát |

Walk↔run giữ phase và đổi stride/timing mượt. Dừng dùng bước tiếp đất gần nhất rồi settle; không snap chân về idle pose. Gait 8 pose là key pose source, nội suy phải xem lại ở 60 Hz và tốc độ frame thấp.

## 2. Combat

Attack durations hiện có trong catalog animation là sword 0.86 s, spear 0.94 s, unarmed 0.62 s. Đây là danh nghĩa của clip hiện tại; bảng này phân chia pha để làm pose sheet, không chuyển hit-frame của authority.

| Pha chuẩn hóa | Sword | Spear | Unarmed |
|---:|---|---|---|
| 0% | ready | tay sau giữ cán, tay trước đỡ | guard tay mở |
| 18% | windup, khuỷu gập về sau | hạ mũi thương, support grip cố định | xoay hông/gối, nắm tay |
| 36% | load, lưỡi ở ngoài silhouette | lực dồn chân sau, shaft hướng mục tiêu | thân xoắn, vai nén |
| 50% | release stroke | đâm và mở vai | đấm/chỏ theo profile |
| 70% | follow-through có kiểm soát | hết tầm đâm, cả hai tay vẫn trên cán | thu lực, không duỗi cứng khuỷu |
| 86% | recover về pose cân bằng | rút cán, reset support grip | guard trở lại |
| 100% | neutral/next action | neutral/next action | neutral/next action |

Tay cầm và hướng cong khuỷu phải author theo facing. Khi đổi W↔E, near/far và bend sign cùng đổi theo phía cơ thể; không chỉ xoay weapon. Vũ khí dài được tách vùng nằm trước/sau thân theo depth profile. Attack pose không tự phát damage; effect, knockback và HP vẫn theo gameplay event hiện có.

Defend giữ pose theo weapon hiện tại: entry 0–20%, hold 20–80%, phản lực nhỏ 80–90%, exit 90–100%. Hold lặp chỉ ở presentation; không tự tăng giảm duration khi authority chưa phát trạng thái.

## 3. Cast và channel

Cast danh nghĩa 0.90 s: chuẩn bị tay 0–25%, tập trung 25–55%, release 55–70%, thu tay 70–100%. Tia/biểu tượng không xuất hiện khi cast bị reject. Trong khi di chuyển, upper-body cast có thể chạy chồng gait dưới dạng pose override; chân tiếp tục phase theo quãng đường.

Channel danh nghĩa 2.4 s: gather 0–15%, hold/loop 15–85%, release khi accepted event đến, recovery 85–100%. Hủy thì dừng loop phụ ngay, tắt VFX thuộc channel và blend về state mới; không tự kết thúc theo số giây nếu gameplay chưa kết thúc.

## 4. Dash, hit và vòng đời nhân vật

- Dash hiện danh nghĩa 0.42 s: lower 0–20%, travel pose 20–70%, contact 70–85%, settle 85–100%. Root/path và va chạm thuộc actor; pose không dịch chuyển nhân vật độc lập.
- Hit hiện danh nghĩa 0.38 s: anticipation ngắn 0–15%, recoil 15–45%, brace 45–70%, return 70–100%. Giữ weapon grip; death/knockout state có ưu tiên theo authority.
- Death hiện danh nghĩa 1.15 s: mất cân bằng 0–30%, khuỵu 30–60%, land 60–80%, settle 80–100%. Không làm hiệu ứng máu/va chạm che character silhouette.
- Respawn hiện danh nghĩa 1.0 s: gather 0–30%, rise 30–65%, feet plant 65–85%, idle 85–100%. Vị trí, hướng, HP và quyền điều khiển do respawn logic cung cấp.

## 5. Bốn skill: effect beats

| Skill | Cast | Travel/hold | Contact/end | Quy tắc |
|---|---|---|---|---|
| Nguyệt Quang | hình lưỡi liềm tụ ngắn | một arc cong theo mục tiêu | arc vỡ thành vài nét mực | không tạo quả cầu sáng |
| Bạch Ngọc | glyph/ward dựng lên | vòng rỗng giữ nhân vật nhìn rõ | mảnh ngọc tan ra ngoài | không che mặt và chân |
| Bạch Hạc | thân hạ trọng tâm | vệt lông thấp theo đường dash | vài lông/nét bụi ở endpoint | không nhân bản nhân vật |
| Băng Tằm | tằm và nét băng thu | chỉ/kim băng theo đường travel | tinh thể gãy và dấu lạnh ngắn | không để crystal che sprite |

Timeline lấy từ accepted cast/travel/contact/end event của gameplay, không chạy timer độc lập. Icon UI dùng cùng glyph/silhouette nhưng không dùng PNG icon làm projectile. Wipe cooldown/mana/range lấy state thật; ảnh không đặt thông số.

## 6. Layer draw-order theo hướng

Resolve body → outfit/body parts → boots/legs → shadow/ground → torso → far arm/weapon-back → head/hair-back → face/hair-front → near arm/weapon-front → hat brim/front → skill VFX. Thứ tự được override per facing/action/depth, không giữ nguyên tuyệt đối cho cả tám hướng. VFX nằm trước hay sau player theo mặt phẳng gameplay/contact, không phủ hit marker.

## 7. Điều kiện duyệt và triển khai

1. Duyệt silhouette từng strip concept; sửa hình nếu weapon hand/shoulder/foot sai hướng.
2. Author source tách layer ở tám hướng; gắn pivot, grip, support grip và depth profile.
3. Nối pose với animation state hiện tại; so duration/accepted event, không thay gameplay.
4. Dựng native preview và ghi hình idle→walk→run→turn, attack, defend, cast, channel/cancel, dash/wall, hit/death/respawn.
5. Reviewer xem world scale, HUD/F3/F6 và giảm chuyển động; verifier kiểm authority, save, control và log.

**Bản hiện tại dừng ở thiết kế:** các mốc trên chưa được test trong Godot và không chứng minh hình concept đã có đủ frame.
