# HUD 0.54 — Chữ bên trong ô và khung

Mục tiêu: sửa các điểm chữ còn chạm viền sau 0.53, giữ phong cách giấy/mực. Nội dung chính có vùng riêng với hình và đường viền; dùng phản hồi hover/chọn hiện có. Bản sửa tập trung lớp UI, không đổi dữ liệu save hoặc cơ chế chơi.

## Phát hiện và sửa

| Phát hiện | Sửa | Bằng chứng |
| --- | --- | --- |
| Số lượng vật phẩm có baseline cách đáy 5 px; đường chọn nằm cách đáy 4 px, đi qua phần chân chữ. | Ô đồ 68×72, nhãn số lượng riêng cách đáy 10 px; icon nằm trên vùng số lượng. | Code trước/sau, ảnh chồng 1/9/99 và đo vùng chữ native. Độ tin cậy cao. |
| Ba dòng danh sách Cổ dùng baseline cố định trong hàng cao 64 px; tên sát mép trên. | Hàng 84 px, ba Label riêng có lề và khoảng dòng; mã dự trữ dài có dấu … và tooltip đầy đủ. | Code, ảnh G và kiểm nhãn không giao nhau. Độ tin cậy cao. |
| Phím tắt, tên và trạng thái kỹ năng vẽ chuỗi trực tiếp trong ô. | Label nhận kích thước font thực, phím có nền riêng; giữ dấu khi hồi chiêu, thiếu khí, đói và trọng thương. | 5 trạng thái trên cả 4 Cổ, hai độ phân giải. Độ tin cậy cao. |
| Nút và khung 0.53 vẫn khá chật theo phản hồi người dùng. | Lề dọc nút 6→8 px; lề khung giấy 16→20 px; chữ lọc túi 11→12. Tên ô Cổ trong bảng nhân vật dịch theo chiều cao ô mới. | 24 ảnh native, ba độ phân giải. Độ tin cậy cao. |
| Trang hành trang người dùng mở vẫn mang nhãn 0.51 và tên ảnh cũ. | Giữ URL `inventory51_review.html`, đổi nhãn UI 0.54 và trỏ đến bộ ảnh `hud54_inventory_*` có phiên bản URL. | Kiểm browser tải đúng ảnh mới tại URL cũ. Độ tin cậy cao. |

Các dòng thông tin skill dài được phép xuống dòng. Nút, nhãn, ô đồ vẫn nhận input ở control cha; nhãn con dùng `MOUSE_FILTER_IGNORE` để kéo đồ và chuột phải không bị chặn.

## Kiểm chứng

- 78/78 bố cục native Windows, 960×640 / 1280×800 / 1920×1080; 24 ảnh.
- 632/632 đo vùng chữ và trạng thái native; 20 ảnh. Kiểm số lượng 1/9/99, phím tắt, trạng thái kỹ năng, dòng Cổ và mã dài. Fixture đóng băng simulation để chụp; cập nhật HUD khi đổi bảng như vòng lặp game thật.
- 49/49 thao tác hành trang native, gồm kéo/đổi ô, chuột phải, cho ăn, chế tạo và xóa có xác nhận; 8 ảnh riêng cho trang hành trang.
- 63/63 kiểm bảng Cổ native, gồm chọn Cổ, nâng cấp, xác nhận phôi và tự cuộn hàng được chọn.
- 911/911 hồi quy Linux trên mã game cuối cùng.
- 60/60 kiểm browser, bao gồm URL hành trang cũ, bộ ảnh mới, so sánh 0.53/0.54, các trạng thái bổ sung, viewport hẹp và zoom.

Không có lỗi runtime hoặc tài nguyên trong các log cuối. Phạm vi xác nhận là bố cục/đọc chữ và thao tác UI trên các kích thước đã kiểm; đây không phải kết luận toàn game đã sẵn sàng phát hành.

## Chạy lại

```bash
.tools/godot/Godot_v4.7.2-stable_win64_console.exe --path 'D:\freelance\gumaster2d' --script res://tests/hud53_review.gd -- --test-mode --review-prefix=hud54
.tools/godot/Godot_v4.7.2-stable_win64_console.exe --path 'D:\freelance\gumaster2d' --script res://tests/hud54_text_review.gd -- --test-mode
.tools/godot/Godot_v4.7.2-stable_win64_console.exe --path 'D:\freelance\gumaster2d' --script res://tests/inventory51_review.gd -- --test-mode --review-prefix=hud54_inventory
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
```

Báo cáo `artifacts/hud54_*json`, log `artifacts/hud54_*log`; nguồn và ảnh trước sửa nằm trong `artifacts/hud54_baseline/`. [Review đầy đủ](http://localhost:8879/hud54_review.html) · [Hành trang đã cập nhật](http://localhost:8879/inventory51_review.html?v=54).
