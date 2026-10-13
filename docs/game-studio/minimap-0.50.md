# Minimap và địa đồ lớn 0.50

Minimap có khung mảnh ôm sát địa hình, rộng 192 và cao 124 đơn vị UI. Tên vùng và dải thông tin nằm ngoài viền bản đồ; bỏ khung giấy dài bao toàn bộ widget. Đường và mặt nước rõ hơn, cây/đá dùng dấu nền nhỏ; NPC, trạm và quái dùng dấu tương phản riêng.

Tọa độ **X/Y theo ô thế giới** hiện bên dưới, cùng tên một trong tám hướng: Bắc, Đông Bắc, Đông, Đông Nam, Nam, Tây Nam, Tây, Tây Bắc. Mũi tên trắng và vùng hình quạt biểu thị hướng nhìn. Nhân vật giữ giữa minimap cả khi di chuyển qua tọa độ lẻ; địa hình lấy từ ảnh vùng lưu trong bộ nhớ rồi cuộn theo vị trí hiện tại.

**Bấm minimap, nút ↗ hoặc F2** mở cửa sổ địa đồ lớn. **Esc/F2** đóng. Bản đồ lớn hiện tọa độ/hướng, cho chọn bãi farm, trạm và NPC; nút “Dẫn đường / Cổ trận [T]” chuyển điểm đang chọn sang bảng dẫn đường/dịch chuyển. Phím T tiếp tục mở bảng này. Mở bản đồ lớn dừng cả WASD và đường đi đã chọn trước đó.

## Kiểm chứng

- Windows native Godot 4.7.2: **68/68** kiểm tra. Thử chuột/phím thật, tám hướng, tọa độ lẻ, ba vùng, chuyển cửa sổ và kích thước 960×640 / 1280×800 / 1920×1080.
- Hồi quy toàn game Linux: **911/911**, không báo lỗi. Bản chụp kết quả: `artifacts/minimap50_regression.json`.
- Địa hình trong cửa sổ lớn rộng ít nhất hai lần phần địa hình minimap ở cả ba kích thước thử.
- Trang so sánh native trước/sau: **12/12** kiểm ảnh và nút đổi chế độ/kích thước, không có lỗi JavaScript.
- Ảnh game và địa đồ: `artifacts/minimap50_hud_*.png`, `artifacts/minimap50_large_*.png`. Kết quả kiểm: `artifacts/minimap50_review_windows.json`, `artifacts/minimap50_browser.json`.

[Xem trước/sau và địa đồ lớn](http://localhost:8879/minimap50_review.html).
