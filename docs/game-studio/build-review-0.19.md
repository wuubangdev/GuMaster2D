# Review nét mực — 0.19

Brief: tham khảo chất vẽ/animation/VFX Don’t Starve Together, giữ nhân vật cũ và mọi điều khiển/cosmetic/gameplay hiện có. Đây là pass làm đẹp prototype trên Godot PC, không thay mẫu hay hứa chất lượng phát hành.

## Vấn đề và quyết định sửa

| Mức | Trước sửa / quan sát | Kết quả / tiêu chí |
|---|---|---|
| P1 | Màu/chất liệu còn bóng đều, cùng cảm giác vector sạch trước pass; chưa có nét mực/giấy | Da/vải/tóc/kim loại phân thành mảng trầm; viền đen ấm, hatching thuôn bên trong hình cũ; grain texture rất nhẹ |
| P2 | Nét tóc phía sau và viền cẳng tay còn xanh lạnh so bảng màu mới | Đổi cùng bộ ô-liu/đen ấm, vẫn giữ hình/hair ID |
| P2 | Nhịp lấy đà kiếm thiếu khoảng giữ; vai trôi theo breath có thể sửa vị trí grip khi tay gần vai ở profile | Bỏ breath trong attack, giữ body beat/grip/góc từ pha .17 đến .21; release ngắn .21–.38. Acceptance kiểm đủ tám hướng |
| P2 | VFX bloom/halo tròn và màu lạnh chói tranh với nhân vật | Thay bằng cung mực mờ, mảnh giấy sắc, star lệch bảy cánh, khiên trống. Moon/frost phân biệt bằng silhouette |
| P2 | Nét bút nhiều segment mảnh khó đọc tại scale nhỏ; primitive rời sinh nhiều lệnh vẽ | Dùng triangle array chung cho core và mép alpha mỗi nét; sheet review ở 1.5× và kiểm thêm gameplay/ảnh phóng native |

Baseline 0.18 tại artifacts/baseline_v18. Không sửa fixture nhận diện để cho test qua. Sheet là renderer game lấy mẫu để review; gameplay dùng input thật và authority fixture.

## Quan sát native

Đã xem sheet tám góc, F6 nữ/thương, gameplay 1280, kỹ năng moon đang bay/khiên, sheet 13 hiệu ứng ở ba pha và directional frame065/frame195 tại 128 và 48px. Màu đất/ngà và viền mực đọc rõ trên nền giấy F6; mặt/tóc/trang phục vẫn nhận ra là mẫu cũ. Tóc sau được đổi màu cùng bộ, lớp tay/grip và diện mạo khác giới giữ được. Các cung và viền kỹ năng liền khi xem native phóng lớn; ở scale nhỏ, nét song song mảnh vẫn chỉ đọc như sắc độ. Khiên giữ trống giữa, băng có mảng nhọn và moon có cung cong, không dựa riêng vào màu. Nền map trầm/ấm hơn nhưng atlas pixel vẫn lộ rõ.

Frame tĩnh sheet hai diện mạo × tám góc giữ framebuffer giống hệt trong 12 frame; shader không tạo nhiễu theo thời gian. 524/524 assertions đạt trên Windows và Linux. Các harness native hoàn tất 18 PNG, 96/144/600/180/240 frame; cold source tải đủ 131 SVG/36 look/13 VFX và đối chiếu 497 runtime files. Clip tám hướng/profile/world/F6 và kiểm chứng cuối nằm trong quality-report.md và evidence/verification_manifest.json; không dùng ảnh dựng lại hay frame nội suy để chứng minh chuyển động.

## Giới hạn còn lại

Mặt chibi/tỷ lệ cũ được giữ, nên mức giống DST tập trung ở chất vẽ/màu/nét và ngữ pháp VFX. Tám view đầu/tóc chưa có bộ hình trung gian vẽ tay để chuyển silhouette hoàn toàn liên tục. Atlas map/sói còn khác chất nét nhân vật. Cần art review trong cảnh đông, animation frame vẽ tay bổ sung nếu muốn cao hơn, và benchmark máy mục tiêu trước khi nhận là production. Các thông số animation là lựa chọn cho bộ hình này; nguồn tham khảo không được đo frame-by-frame.
