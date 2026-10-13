# HUD 0.53 — Chữ và viền

## Phạm vi

Sửa chữ sát hoặc chạm viền trong HUD và các bảng hiện có. Giữ phong cách giấy/mực, tăng khoảng trống bên trong thay vì tăng độ dày đường viền. Nội dung ưu tiên: số HP/chân nguyên và phím kỹ năng trong map; thông tin vật phẩm và thao tác trong túi; nội dung chi tiết cuộn trong cửa sổ. Phản hồi hover/nhấn và mở bảng tiếp tục dùng hành vi hiện có; không thêm chuyển động trang trí.

## Nguyên nhân và thay đổi

- `GuInkButton._ready()` trước đây ghi đè mọi StyleBox thành `StyleBoxEmpty` không có content margin. Nút do container định kích thước co sát chiều cao chữ; phần vẽ chữ thủ công cũng bỏ qua vùng nội dung. Nay Godot đo/vẽ chữ một lần với lề ngang **12 px**, dọc **6 px**, cùng nét viền vẽ tay bên ngoài. Native text shaping hỗ trợ cả dấu tiếng Việt và ký hiệu hướng.
- `GuLacquerPanel` tăng content inset **10 → 16 px**, tách tiêu đề và nội dung khỏi nét mực, góc trang trí. Tiêu đề cửa sổ có khoảng cách riêng với nút đóng và được phép xuống dòng.
- Bảng chế tạo tăng padding **8 → 12 px**. Hành trang và bảng nhân vật chừa **8 px** với thanh kỹ năng ở cửa sổ nhỏ; nội dung vẫn cuộn được.
- Thanh HP/chân nguyên cao **28 px**; panel trạng thái và vị trí bảng nhiệm vụ được điều chỉnh để không chồng nhau. Thanh kỹ năng cao **94 px**, tên và trạng thái dùng hai dòng riêng với lề ngang.
- Bỏ outline đậm trên dòng hướng dẫn đặt trên giấy; thông báo dài tự xuống dòng trong vùng giữa panel trạng thái và minimap.

## Kiểm chứng

- **78/78** kiểm native Windows tại 960×640, 1280×800 và 1920×1080. Đo khoảng trống theo kích thước chữ, kiểm panel con và khoảng cách các bảng; thao tác thật mở túi, bảng nhân vật, chế tạo, G, Esc, F6 và J. **24 ảnh chụp trực tiếp**.
- **49/49** kiểm hành trang native: kéo/đổi vị trí, menu chuột phải, cho ăn, chế tạo, xóa có xác nhận và bố cục ba độ phân giải.
- **63/63** kiểm bảng Cổ native: chọn Cổ, cường hóa, chọn phôi/nâng bậc, đối thoại xác nhận, cuộn và trường hợp không đủ nguyên liệu.
- **911/911** hồi quy toàn game trên Linux, không `SCRIPT ERROR`/`ERROR`/`FAIL`.
- **31/31** kiểm trang review: 24 ảnh đúng độ phân giải, ảnh trước/sau, zoom 100%, viewport hẹp và không lỗi script/tài nguyên.

Ảnh và báo cáo: `artifacts/hud53_review.html`, `hud53_review.json`, `hud53_*_regression_windows.json`, `hud53_regression_linux.json`, `hud53_browser.json`. Các kiểm thử chạy với `--test-mode`, tách khỏi save người chơi. Trang review là ảnh native có điều khiển xem; chơi tương tác bằng bản Godot.

## Chạy lại

```bash
.tools/godot/Godot_v4.7.2-stable_win64_console.exe --path 'D:\freelance\gumaster2d' --script res://tests/hud53_review.gd -- --test-mode
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
```

Thay đổi thuộc lớp trình bày; không thêm trường save hay thay đổi dữ liệu vật phẩm. Bản nguồn trước sửa nằm ở `artifacts/hud53_baseline/scripts/ui/`. Nội dung dài hơn của các tính năng thêm sau này cần tiếp tục tuân theo các inset và vùng cuộn này.
