# Rà soát bản chơi 0.49 — UI, hành trang và tỷ lệ quái

**Trạng thái:** prototype tiền phát hành trên PC. Dự án có 3 vùng chơi, hệ thống nhiệm vụ/Cổ/điền viên, hồ sơ lưu và kiểm thử tự động; chưa có bằng chứng đủ để gọi là bản production hoặc công bố phát hành.

## Đã sửa trong lượt này

- Minimap hiển thị tọa độ ô hiện tại và mũi tên hướng nhìn. Bấm vào radar mở địa đồ vùng. Khung radar và nút Cổ giới không còn chạm nhau ở 960×640, 1280×800.
- Menu Esc có âm lượng, độ phân giải 960×640 / 1280×800 / 1600×900 / 1920×1080, cửa sổ/toàn màn hình, tắt âm và giảm chuyển động. Tùy chọn lưu trong `user://settings.cfg`.
- Hành trang có menu chuột phải để xem chi tiết, nuôi Cổ bằng vật liệu phù hợp, mở công thức nâng Cổ, và xóa sau xác nhận. Cổ đang khảm bị chặn xóa. Kéo thả đổi thứ tự ô và thứ tự được lưu trong hồ sơ; hồ sơ cũ không có thứ tự vẫn nạp được.
- Quái thường thu nhỏ theo từng loài; đầu lĩnh giữ tỷ lệ lớn hơn. Chiều dài hai đoạn chân và độ dang chân được chỉnh theo dáng sói, lợn, cóc và côn trùng; chân thú bốn chân dùng đoạn thuôn thay cho vòng khớp tròn đậm. Bóng và thanh máu đi theo tỷ lệ mới.

## Bằng chứng

- Bộ hồi quy game Linux: **911/911** sau thay đổi UI và hành trang. Bộ quái Linux và Windows: **170/170** mỗi nền tảng, 51.984 mẫu vùng đánh và 10.752 mẫu khớp chân.
- Kiểm UI và hành trang native Godot: **29/29** trên Linux, **29/29** trên Windows. Ảnh thực ở 960×640 và 1280×800 lưu trong `artifacts/production49_*.png`.
- Bảng đối chiếu native: 8 loài × 8 hướng cạnh nhân vật cao 48 đơn vị ở **cùng tỷ lệ thế giới**, các trạng thái đứng và ba pha bước. Xem `artifacts/production49_beast_idle.png` và `artifacts/production49_beast_walk_*.png`. Bảng này chứng minh tỷ lệ hiển thị, không thay cho đánh giá cảm nhận chuyển động trong trận dài.

## Vấn đề còn lại theo ưu tiên

1. **Ô Cổ 5–8 chưa có luật mở khóa và kỹ năng.** Dữ liệu và authority hiện cố định bốn định nghĩa/bốn cooldown, UI chỉ dựng bốn nút; thêm bốn ô cần thiết kế kỹ năng, điều kiện quest, lưu/tải và tương thích hồ sơ trước khi bật. Đây là phần chức năng được yêu cầu nhưng chưa hoàn thành.
2. **Giới tính và trang bị:** F6 hiện có nam/nữ, ba áo, hai giày, ba nón và ba lựa chọn vũ khí; đổi chọn làm đổi hình trong game. Dáng nữ và bộ asset trang bị chưa được duyệt ở chuẩn hình ảnh cuối; đây là một vòng art riêng, cần xem từng hướng và từng action trên nhân vật nữ.
3. **Bí cảnh:** Thanh Nang đã là vùng riêng có ruộng và chuồng. Nó chưa có vòng xây dựng/trang trí, bố trí tự do và tiến triển kiểu không gian cá nhân mà người chơi mô tả. Cần đặc tả lưới đặt đồ, quyền sở hữu vật thể và lưu dữ liệu trước khi mở rộng.
4. **Hành trang:** nút “Mở bảng nâng cấp Cổ” đưa đến công thức ở G. Chưa có hệ recipe/crafting chung cho mọi vật liệu hay trang bị ngoài Cổ; không nên hiển thị hành động dùng cho vật liệu không có tác dụng đã định nghĩa.
5. **Chất lượng phát hành:** chưa thấy preset export, CI hoặc hồ sơ hiệu năng/FPS cho trận đông quái trên PC mục tiêu. Các test xác nhận logic và bố cục, còn cần kiểm thời gian khung hình, bộ nhớ, tải map, âm thanh thật và cân bằng tiến trình bằng phiên chơi dài. Âm thanh hiện là các hiệu ứng ngắn, chưa có nhạc/nền âm theo vùng.

**Thứ tự triển khai tiếp:** khóa luật và hồ sơ cho ô Cổ 5–8; duyệt ngoại hình nữ/trang bị trên atlas tám hướng; thiết kế vòng bí cảnh xây dựng; sau đó đo hiệu năng và đóng gói bản PC. Mỗi mốc cần kiểm hồ sơ cũ và bản native Windows.
