# WBS — từ concept sang nhân vật chơi được

Ngày 11/10/2026. **Đã bắt đầu triển khai pilot runtime sau khi người dùng duyệt hướng concept và yêu cầu tạo nhân vật trong game.** Phạm vi pilot hiện tại gồm slot nón/giày, asset SVG 8 hướng, F6 preview, danh mục 216 tổ hợp và tương thích save; UI được bổ sung slice mực/giấy theo concept 01. Đây chưa phải toàn bộ WBS hay nghiệm thu production.

## Trạng thái hiện tại

| Gói | Trạng thái | Bằng chứng / phần còn lại |
|---|---|---|
| W01–W05 | Nền hiện có + đang polish | Renderer đang có 2 body, 8 hướng, rig liên tục và 11 action; cần tiếp tục duyệt silhouette, tỷ lệ và contact ở kích thước world. |
| W06 | Pilot phụ kiện đã vào game | Có 2 kiểu giày, 2 kiểu nón + `none`, mỗi kiểu 8 SVG hướng. Ba outfit vẫn dùng cùng form hiện tại; cần vẽ fit/form phân biệt và review hair-mask. |
| W09 | Pilot đã tích hợp | Xưởng F6 có 6 slot; writer giữ `appearance` 4 field và lưu nón/giày trong `appearance_v2`; suite kiểm legacy/partial/ID lạ. |
| W07–W08, W10 | Nền hiện có; polish tiếp | Vũ khí và 11 action đang chạy; 4 skill/VFX chưa được làm lại trong slice này. |
| W11 | Đang kiểm chứng | Import SVG, suite logic và native screenshot có kiểm tra; còn review art trong gameplay và test build PC cuối. |
| W12 | Chưa bắt đầu | Đóng gói, profiler và pipeline phát hành vẫn theo mốc sau. |
| W13 | Đã áp dụng, đang review | HUD/F3/F4/F6/F11/Esc theo UI 0.20–0.22; panel giấy có viền mực đôi/nét khô, button tab vẽ tay, Patrick Hand hỗ trợ tiếng Việt; 11 ảnh native tại 960×640, 1280×720 và 1280×800. UI smoke 11/11 và regression 531/531 đạt; còn review cảm quan trên PC mục tiêu. |

## Vai trò cho nhóm 4 người

| Vai trò đề xuất | Trọng tâm | Đầu ra |
|---|---|---|
| A — mỹ thuật nhân vật | Mặt/tỷ lệ, 8 view, trang phục, tóc/nón/giày | Nguồn tách lớp và review silhouette |
| B — animation/rig 2D | Pose, pivot, tay/chân, grip, cloth | Clip/pose data và contact sheets |
| C — Godot/data | Renderer, catalog, cosmetic flow, migration | Tích hợp world/F3/F6 và profile |
| D — VFX/UI/verification | Icon/effect, hiển thị UI, native review, regression | Kỹ năng nhất quán + evidence |

Đây là phân công theo năng lực, chưa gửi/assign cho người thật. A và B cần cùng review grip/khớp; D kiểm mỹ thuật bên cạnh assertions. Một người có thể kiêm nhiều vai trò, nhưng không bỏ thời gian review để bù thiếu người.

## Các gói công việc

Ước lượng là **ngày công tập trung khoảng 6 giờ/ngày**, dùng để định cỡ, không phải ngày lịch hoặc cam kết hoàn thành. Phụ thuộc tay nghề vẽ/animation của nhóm. Tổng tham chiếu 40–66 ngày công gồm slice W13; lập lịch 4–6 tuần nếu nhóm 4 người dành được thời gian ổn định. Nếu làm buổi tối, tính lại lịch theo giờ thực tế.

| ID | Công việc và yêu cầu liên quan | Phụ thuộc | Chính / review | Ngày công | Đầu ra nghiệm thu |
|---|---|---|---|---:|---|
| W01 | Khóa mặt/tỷ lệ/palette, thử world 48 px — INK-01/02 | Duyệt concept | A / D | 2–3 | 2 body và 8 view không drift; không mất mắt/cổ áo ở world |
| W02 | Source pilot male/jade/cloth/no-hat/sword, đủ 8 view — INK-02/05/08 | W01 | A / B | 3–5 | Layer thật có alpha/pivot/overlap; SVG/nguồn chỉnh được |
| W03 | Manifest phần/socket/mask và loader mở rộng — INK-05/06/07/14 | W02 | C / B | 2–4 | Missing slot báo đúng, fallback riêng; không ảnh hưởng gameplay |
| W04 | Idle/walk/run/stop 8 hướng — INK-03/13 | W02/W03 | B / D | 2–4 | Foot-contact footage native; không cong tay sai khi quay nhanh |
| W05 | Female body/face/fit/tóc, dùng chung rig — INK-01/09 | W03/W04 | A+B / D | 4–6 | Cả 2 body đi/chạy đúng; nữ có shape riêng, cùng socket contract |
| W06 | 3 áo, 2 giày, 3 nón, mask tóc — INK-05/06/07/09 | W03/W05 | A / B+C | 5–8 | 216 tổ hợp resolve đủ parts; nón/giày đổi độc lập đúng fit |
| W07 | Kiếm/thương/tay không và attack/guard/cast — INK-04/08 | W04/W05 | B / C+D | 5–8 | 8 hướng, release grip chắc; thương support hand không trượt |
| W08 | 4 icon + VFX cast/travel/contact/end — INK-11 | W01; integration sau W07 | D / A+C | 4–6 | World và dock cùng nét/màu; 4 skill phản ánh state thật |
| W09 | F6 preview/apply/hủy, portrait và save migration — INK-10/12 | W03/W06 | C / D | 3–5 | Đổi ngoại hình đồng bộ; profile cũ giữ data; rollback đọc được v1 |
| W10 | Channel/dash/hit/death/respawn + moving cast — INK-04/13 | W07 | B+C / D | 4–6 | 11 nhóm action đúng ưu tiên; không old VFX sau death/respawn |
| W11 | Matrix native/regression/readability/reduced motion — tất cả | W06–W10 | D / A+B+C | 3–5 | Có evidence thực tế; art lỗi còn lại được ghi, không chỉ test Passed |
| W12 | Resource/performance/import/export và đóng gói — INK-13/14 | W11 | C+D / A+B | 1–2 | Build và nguồn cùng revision, assets không phụ thuộc máy author |
| W13 | UI mực/giấy 0.20: theme, dock, vitals, minimap, lưới 5×6, cửa sổ HUD — UI-20 | UI concept 01 + pilot hiện hành | D+C / A+B | 2–4 | Native captures 960×640/1280×720; độ tương phản và modal/navigation regression đạt; reduced motion không rung |

## Lịch theo mốc, không chạy tất cả đồng thời

| Mốc | Nội dung | Điều kiện chuyển tiếp |
|---|---|---|
| M0 — hoàn tất | 5 bảng concept + FSD/WBS/contract được dùng để bắt đầu pilot | Người dùng đã yêu cầu chuyển bản thiết kế vào game |
| M1 — đang tiến hành | W01–W04: một look chơi được, kiểm ở world/F6 | Hoàn tất native review 8 hướng, bước đi/run/stop và silhouette ở kích thước world |
| M2 — tuần 2 | W05–W06: hai body và đổi đồ | Fit/mask/ankle đúng, đủ coverage slot và resolve combinations |
| M3 — tuần 3 | W07–W08–W10: action và kỹ năng | Grip/phase/VFX/state đúng; không để animation gây gameplay side effect |
| M4 — tuần 4 | W09–W11 + W13: UI/save/regression | Apply/Hủy/profile cũ/reduced motion/input giữ đúng contract; theme UI mới đọc rõ ở hai viewport |
| M5 — tuần 5–6 dự phòng | W11–W12: sửa art lỗi, perf và handoff | Native art review đạt, logs sạch và hạn chế đã được ghi |

Không nhân toàn bộ bộ asset trước khi pilot đạt. Nếu 48 px làm mất nét, sửa style/tỷ lệ ở M1 trước khi vẽ thêm áo/nón. Nếu grip lỗi, sửa solver/socket trước khi thêm mọi animation vũ khí. W08 có thể làm concept/source song song W02–W07, nhưng chỉ tích hợp khi accepted event hookup đã rõ.

## Trình tự tiếp theo

1. Soát pilot mới ở world/F6; chỉnh tỷ lệ/nón/tóc nếu silhouette bị che hoặc nhòe tại kích thước gameplay.
2. Chốt form riêng cho jade/crimson/ivory và tiếp tục rig/action theo 8 hướng.
3. Hoàn thiện missing-resource fallback, tóc/nón mask và test migration với file save cũ thực tế.
4. Hoàn tất W13: kiểm HUD, hành trang 5×6, nhân vật, nhiệm vụ và xưởng ở native resolution; sau đó polish 4 kỹ năng, hiệu năng và build PC.

Mỗi gói đi qua xây → review mỹ thuật/code → kiểm chứng. Review được thực hiện theo vai trò nhóm; tài liệu không yêu cầu tạo agent hoặc thread mới. Xem [ACCEPTANCE.md](ACCEPTANCE.md) để biết evidence cần giữ.
