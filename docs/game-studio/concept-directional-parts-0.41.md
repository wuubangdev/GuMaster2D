# Nhân vật 0.41 — chi tiết theo hướng trước khi ghép xương

## Yêu cầu và phạm vi

Sửa chi tiết sai hướng, mảnh tay/chân còn dính thân và phần thiếu lộ ra khi khớp chuyển động. Giữ nhận diện concept hiện tại, nam/nữ, tám hướng, trang phục và vũ khí; giữ hệ thống world/quest 0.40. Mục tiêu là một bước hoàn thiện asset và liên kết có thể mở rộng, không tuyên bố toàn bộ mỹ thuật đã đạt chuẩn phát hành.

## Asset trước, liên kết sau

`tools/author_directional_character_parts.py` tạo 352 SVG độc lập: 16 body/view × hai bên giải phẫu × 11 chi tiết. Mỗi bên có vai nối, tay áo, cẳng tay quấn vải, bàn tay thả/nắm/đấm/thi triển, đùi, cẳng chân và hai kiểu giày. Bản vẽ nằm trong `assets/characters/concept-rig/directional-parts/<body>_<direction>/`.

Bản nhìn trước, nghiêng, sau có cấu trúc nếp/đường may khác nhau. Ngón cái được định hướng theo mặt bàn tay; giày có mũi/hậu theo hướng; tỷ lệ lấy từ điểm khớp của từng bản concept. Hai thân không dùng một bộ tọa độ toàn cục. Đây là bộ công thức SVG theo góc nhìn có file riêng để chỉnh tiếp, không phải 352 tranh vẽ tay hoàn toàn khác nhau.

Các phần khuất tại đầu khớp được vẽ kín. Vai nối có chiều rộng đo đến đường thân áo của đúng góc, tránh một kích thước cố định làm vai rời ngực ở góc N. Đầu và các chi tiết trang trí thân vẫn từ PNG gốc; PNG không bị sửa. Hai bảng chi tiết HTML được kiểm trước bước ghép.

## Hợp đồng liên kết

`directional_art.parts` trong manifest khai báo bone, side, bounds, anchors, overlap, plane, complete_hidden_surface, atlas_rect. Xương định vị artwork bằng phép quay + tịnh tiến, không kéo giãn chiều dài nét. Vai nối bám ngực; tay áo bám vai–khuỷu; viền ngà thuộc cửa tay áo và che lên lớp quấn cẳng tay; cẳng tay bám khuỷu–cổ tay; bàn tay quay riêng ở cổ tay và có điểm grip trùng vũ khí. Đùi/cẳng chân/giày giữ các điểm hông–gối–bàn chân đang dùng trong rig.

`GuConceptDirectionalParts` sở hữu cách chọn bàn tay và đặt asset. Renderer dùng bộ mới cho các chi tiết tay/chân; không vẽ chồng lại fragment tay/chân cắt từ nguồn. Góc sau đặt toàn bộ tay sau thân, bỏ nhánh cẳng tay hiện lên trên lưng trong mọi động tác. Đường cong chuyển động và giới hạn IK hiện có tiếp tục được dùng; thêm xương không tự sửa được tranh sai/thiếu.

Atlas SVG riêng có gutter, 8 pixel nguồn/native unit và sampler page 9. Quy trình author masks gọi cùng bộ tác giả để không làm mất bộ mới khi rebuild. Nhuộm trang phục và đổi giày dùng chung pipeline game, NPC, chân dung và studio.

## Kiểm chứng và cách tái tạo

1. `python3 tools/author_directional_character_parts.py`
2. `bash tools/run.sh --headless --editor --import --quit` — chờ import xong trước chạy test/capture.
3. `bash tools/run.sh --headless --script res://tests/concept_directional_parts_runner.gd -- --test-mode`
4. `DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_directional_parts_review.gd -- --test-mode --capture-offscreen`
5. `python3 tools/build_directional_character_review.py`
6. `bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode`

Kiểm dữ liệu: đường dẫn riêng, phần khuất đục, các điểm nối và grip trên 12.000 tư thế (16 góc/body × 3 vũ khí × 10 động tác × 25 thời điểm), phép biến đổi không scale/đảo hình, hash concept gốc. Kiểm GPU so màu từng chi tiết thật trong atlas với SVG nguồn. Kiểm hình native gồm thân riêng, tách lớp, đứng, đi/chạy, kiếm/thương/tay không, thủ, thi triển, vận công, trúng đòn, lướt, gục và overlay xương.

Báo cáo máy ở `artifacts/concept41_constraints.json`, `concept41_gpu.json`, `concept41_native.json`; trang xem `http://localhost:8879/concept41_character_review.html`. Kết quả: **636/636** hồi quy (613 cũ + 23 kiểm mới), **12.000** pose rời + **512** pose chuyển hướng/blend thực, sai lệch điểm bám tối đa **0,0000064 native unit**. Các đĩa phủ khớp đều đục. GPU: **352/352** chi tiết so màu đạt ngưỡng; sai số RGB lớn nhất 0,0435. Có **198 ảnh native** (194 bảng/frame/overlay + 4 ảnh trong game/F3/F6), **23 trạng thái browser** và viewport 390 px. Log import, regression và capture không có SCRIPT ERROR/ERROR/FAIL. [Báo cáo bàn giao](../../artifacts/concept41_delivery.json).

## Giới hạn còn lại

Đây là chuyển động bằng rig với các trạng thái bàn tay và hình chiếu 8 hướng, chưa là vẽ tay từng frame hay xoay 3D liên tục. Đầu và thân vẫn giữ mật độ nét sketch của concept, trong khi chi tiết limb mới có nét sạch hơn; cần tiếp tục duyệt độ đồng nhất ở kích thước game. Thử nghiệm hình/chuyển động bằng Godot Linux/Mesa không thay cho đánh giá hiệu năng trên PC Windows mục tiêu.
