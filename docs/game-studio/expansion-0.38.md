# 0.38 — Cổ giới, luyện Cổ và Thanh Nang Bí Cảnh

## Phạm vi và vòng chơi
Bản PC chơi đơn đang phát triển; mở rộng tính năng trong Godot, giữ nhân vật 0.37. Chiến đấu tại Vạn Thú Sơn → qua cổ trận đến Tàn Tích → lấy cổ tinh, phục hồi Thanh Nang → gieo linh thảo/linh hoa/linh quả, nuôi linh tằm/linh kê → thu sản vật → nâng cấp/hợp thành bốn Cổ đang dùng → đánh mạnh hơn và tiếp tục khám phá.

Ba vùng riêng có va chạm, vật thể, điểm hồi sinh và quần thể quái riêng. Dịch chuyển chỉ tại trại/cổ trận, khi sống và hết giao chiến; đổi vùng xoá đường đi, mục tiêu và VFX cũ. Tàn Tích mở sau một lần hạ sói. Bí cảnh mở tại cổ trận Tàn Tích sau tổng 3 lần hạ sói, tốn 2 cổ tinh. Tiến độ chiến đấu của từng vùng giữ khi dịch chuyển trong phiên; khi tải lại, quái được tạo mới như cơ chế cũ.

## Cổ và kinh tế
- Bốn ô kỹ năng giữ phím 1–4; G mở Bảng Cổ. Mỗi Cổ có bậc I–III và mức tu luyện 1–5.
- Nâng cấp: linh thảo 2 × mức hiện tại, chân nguyên thạch × mức, bạc 25 × mức.
- Hợp thành: Cổ chính mức ≥3 (bậc I) hoặc ≥5 (bậc II), một Cổ dự trữ cùng loại bậc I; tơ linh tằm 2 × bậc, cổ tinh 3 × bậc, bạc 100 × bậc. Hiển thị rõ nguyên liệu bị tiêu hao. Cổ đang trang bị không được dùng làm phôi. Kết quả giữ ô kỹ năng, tăng bậc và về mức 1.
- Hệ số sức mạnh = 1 + 0.12 × (mức−1) + 0.6 × (bậc−1). Sát thương/khiên dùng hệ số; Bạch Hạc giảm hồi chiêu tương ứng, giới hạn 45%. Không tăng tầm để tránh thay đổi kiểm tra va chạm.
- Mua hạt và vật nuôi bằng bạc tại bảng Bí cảnh; cây trả lại hạt khi thu hoạch, thú không chết vì chưa cho ăn. Không có thu hoạch ngoại tuyến; thời gian phát triển chạy theo mô phỏng và dừng khi tạm dừng game.
- Sáu ô đất, 3 loại cây, 2 chuồng. Gieo → tưới một lần → chờ → thu. Cho thú ăn linh quả → chờ → thu tơ/trứng. Trứng đổi ra chân nguyên thạch bằng công thức, nối chăn nuôi vào luyện Cổ. Túi đầy chuyển phần thưởng vào hàng chờ, không mất sản vật.

## Trạng thái / lưu
`ExpeditionModel` sở hữu vùng, bí cảnh và đồng hồ cây/thú. `LocalAuthority` kiểm tra điều kiện và thực hiện giao dịch, phát sự kiện. UI chỉ phát lệnh và đọc trạng thái. Lưu mở rộng trong trường `expedition` có version riêng, schema hồ sơ vẫn 1; hồ sơ cũ nhận trạng thái mặc định. Kiểm tra trước khi gán để hồ sơ lỗi không sửa một phần trạng thái. Rollback bằng bản mã nguồn ở `artifacts/expansion38_baseline`; hồ sơ mới cần giữ bản dự phòng trước khi chạy mã cũ vì bậc Cổ mới không được mã cũ hỗ trợ.

## UI và phản hồi
T: địa đồ, G: bảng Cổ, H: bí cảnh; E tương tác gần cổng/đất/chuồng. Một cuốn sổ dùng ba trang, kiểu giấy/mực/ngọc hiện có. Công thức hiển thị có/cần và lý do chưa dùng được; ESC đóng và chặn điều khiển thế giới khi mở. Trên bản đồ có cổng, đất theo giai đoạn sinh trưởng, chuồng và linh thú. Chuyển vùng, mở bí cảnh, thu hoạch/luyện Cổ có dấu ấn riêng; kỹ năng bậc cao có thêm nét ấn và vệt năng lượng, tôn trọng giảm chuyển động. SoundLayer nhận sự kiện và dùng bộ âm thanh hiện có.

## WBS và tiêu chí hoàn tất
Người triển khai, tự rà soát, kiểm chứng: agent hiện tại; thực hiện ba giai đoạn độc lập, không yêu cầu đội khác.
1. **Vùng và dịch chuyển** — WorldGrid, ExpeditionModel, LocalAuthority, WorldView. Xong khi ba vùng vào/ra được, không mang mục tiêu/VFX xuyên vùng, bản đồ hiển thị đúng và hồi sinh an toàn.
2. **Luyện Cổ** — giao dịch nâng cấp/hợp thành, UI công thức, thông số thực chiến. Xong khi thiếu vật liệu không tiêu hao, không dùng nhầm Cổ trang bị, mạnh lên thật và lưu được.
3. **Bí cảnh** — nhiệm vụ mở cửa, sáu đất/ba cây/hai thú, thu hoạch và chuỗi nguyên liệu. Xong khi chơi được từ trạng thái mới, không cần lệnh debug và không mất đồ khi đầy túi.
4. **Phản hồi & tích hợp UI** — sổ, phím tắt, cổng/đất/chuồng, VFX và âm thanh. Xong khi thao tác/điều kiện đọc được tại 960×640 và1280×800, điều khiển không xuyên cửa sổ.
5. **Kiểm chứng** — kịch bản tiến trình, lưu cũ/mới/lỗi, chống lặp tiêu hao, native smoke và hồi quy. Báo riêng kết quả thực tế, không gọi toàn bộ game production-ready.

Không thuộc lượt này: MMO, giao dịch mạng, thời tiết/mùa, thú có di truyền, hàng chục bản đồ/cây, trồng trọt ngoại tuyến và cân bằng kinh tế dài hạn. Thiết kế dữ liệu cho phép thêm nội dung sau khi thử vòng chơi này.

## Bản triển khai và kiểm chứng
- Hoàn tất WBS1–4: ba WorldGrid có địa hình/props/population riêng; sổ ba trang dùng window stack; 4 Cổ mức1–5/bậcI–III; hệ thống6 đất/3 cây/2 chuồng/2 thú; hiển thị vật liệu mới trong hành trang; dấu ấn thi triển, VFX dịch chuyển/luyện Cổ/thu hoạch và âm thanh.
- Cho phép thả vật nuôi sau khi thu hết sản vật để đổi loài; yêu cầu bấm xác nhận rõ “không hoàn bạc”. Không bị mắc kẹt vì chọn cả hai chuồng cùng loài.
- Mở sổ dừng đường click cũ. Nút Cổ giới nằm dưới backdrop khi mở hành trang, không che nút cho ăn.
- Kiểm tra cơ chế: **60/60** (`artifacts/expansion38_mechanics.json`). Kiểm tra tương tác native: **35/35**,11 ảnh (`artifacts/expansion38_native.json`), gồm phím T/G/H/E, nút gieo/tưới/nâng cấp/hợp thành, bỏ target khi đổi vùng, viewport960/1280, chặn cast trong sổ và dừng đồng hồ khi pause.
- Hoàn tất WBS5: báo cáo cơ chế/native/hồi quy và review đã lưu.
- Hồi quy: **613/613** (`artifacts/expansion38_regression.json`). Kiểm tra riêng metadata/bộ VFX bốn Cổ ở bậcI/II và reduced motion: `artifacts/expansion38_fx.json`.
- Ảnh và hướng dẫn duyệt: `artifacts/expansion38_review.html` (server localhost8879). Các ảnh là framebuffer native, không phải mockup.

Lệnh tái kiểm:
```bash
bash tools/run.sh --headless --script res://tests/cultivation_tests.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/cultivation_visual_smoke.gd -- --test-mode --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/cultivation_fx_review.gd -- --test-mode
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
python3 tools/build_expansion38_review.py
```
Native smoke kiểm tra luồng vào game bằng phím/nút; fixture tạo một phần tiến trình để kiểm tra nhanh các nhánh sau. Cân bằng toàn bộ từ đầu bằng người chơi, nhịp thu hoạch dài hạn, tối ưu hiệu năng trên PC yếu và bản Web vẫn cần thử tiếp. VFX và đồ điền viên hiện dùng nét vector vẽ bằng code; chưa có bộ sprite hoạt ảnh riêng chất lượng phát hành cho linh thú/nông vụ. Không thay nhân vật0.37 ở lượt này.
