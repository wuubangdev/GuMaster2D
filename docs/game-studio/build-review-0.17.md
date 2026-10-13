# Build review — 0.17

Brief: làm đẹp chuyển động và chi tiết trên nhân vật cũ; sửa tay cong cố định khi quay. Không thay model, không đổi điều khiển/combat/save.

| Phát hiện | Mức độ / bằng chứng | Sửa |
|---|---|---|
| Khuỷu tay L/R có bend screen-space cố định, vai/cổ tay chỉ đổi ở profile | important; high confidence; code connect_arms/sample và native baseline 0.16 | Frame vai/cổ tay theo facing; bend chiếu theo hướng; blend mang bend |
| Tay L luôn sau/R luôn trước kể cả quay trái | important; high confidence; code draw | Chọn gần/xa theo vai; nhóm vũ khí/grip với tay cầm |
| Cẳng tay/chân là nét đậm với khớp tròn | important; high confidence; code và ảnh baseline | Dải cong thuôn có chuyển sắc và viền mảnh; nối dưới cuff |
| Sine tay độc lập lệch pha stance chạy | important; high confidence; acceptance counter-swing | Đối trọng theo travel từng chân |
| Góc kiếm nghỉ trước mặt che hết blade khi quay lưng | important; high confidence; native 8 hướng | Hướng nghỉ theo vị trí anatomical wrist; tip ngoài đầu mọi hướng |
| Polygon dải chân gập tự giao, lỗi triangulation | important; high confidence; native log trong sửa | Vẽ quad tường minh; chạy lại native toàn bộ sau sửa |

Khớp pose và renderer dùng chung world/HUD/F3/F6. Endpoint tay vẫn là nguồn grip/projectile; actor/camera/authority không thay. Silhouette alpha và kích thước 131 SVG được bảo vệ bởi fixture 0.15, không cập nhật fixture để ép pass. Không cần refactor ngoài presentation.

Kiểm chứng cuối và ảnh/clip xem quality-report.md cùng evidence/verification_manifest.json; assertions là kiểm hợp đồng, không phải thang điểm đẹp. Hình đầu/thân vẫn dùng tám view và tỷ lệ chibi cũ.
