# Ngữ pháp phản hồi nét mực — 0.19

Phản hồi vẫn dựa trên trạng thái thật. UI dùng tương phản và chữ để người chơi hiểu điều kiện; thế giới dùng pose, silhouette và nhịp hiệu ứng để đọc hành động. Màu là tín hiệu bổ sung; bốn Cổ có hình riêng.

| Sự kiện | Thế giới | HUD / âm thanh |
|---|---|---|
| Di chuyển | Chân tì/nhấc, chuyển trọng tâm, vạt/tóc trễ; bụi rất nhỏ, ít sau ảnh khi lướt | WASD/Shift giữ hướng và tốc độ hiện có |
| Thi triển | Mắt lấy đà, tay phóng từ pose đang render; Nguyệt Quang cung mực ngà/xanh đất, Băng Tằm mảnh giấy nhọn xám lạnh | Mana/cooldown thật, âm chấp nhận hiện có |
| Bảo vệ | Khung khiên vàng giấy, giữa trong để đọc nhân vật | Khiên/HP thật; các số và glyph không áp shader viền mực của SVG |
| Lướt | Hai vệt nhỏ/một lông và bóng pose cũ; nét bút hẹp theo hướng thật | Alt vẫn xem trước đường và vật cản; skill3 dùng đúng điểm dừng |
| Tiếp xúc/trúng đòn | Ngôi sao mực lệch, mảnh sắc và recoil; contact ở .28s, mắt nhắm rồi mở | HP có vệt mất máu/chữ số thật, âm tiếp xúc hiện có |
| Từ chối | Không phát projectile hay trừ mana khi input bị từ chối | Lý do rõ ở dock/tooltip/toast và âm từ chối hiện có |
| Nguy hiểm | Telegraph/target/hit thật vẫn giữ thứ tự trước khi damage | HP/cảnh báo hiện có; không tạo thông tin gameplay mới bằng grain |
| Phần thưởng | Ngôi sao giấy và cung bút ngắn | XP/vật phẩm/nhiệm vụ thật, âm thưởng hiện có |

Reduced motion bỏ secondary reactions/ghost/flight/shake theo setting hiện có. Pause giữ cả simulation và pose/effect clock. Họa tiết tĩnh không có TIME hoặc RNG. Không thêm âm thanh trong pass này; layering và trigger âm thanh giữ hệ thống hiện có.

Review cần nhìn kỹ năng ở giai đoạn bay và tiếp xúc trên nền map, đọc được người đứng giữa khiên, phân biệt frost/moon bằng hình, và kiểm các số sát thương không bị shader SVG làm đen. Sheet 13 hiệu ứng là phụ trợ; gameplay native quyết định mức đọc được.
