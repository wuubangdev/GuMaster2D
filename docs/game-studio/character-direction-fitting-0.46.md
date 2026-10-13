# Nhân vật theo từng hướng — 0.46

## Quy trình

Làm hướng xuống trước: đo tư thế đứng và các điểm vai, khuỷu, cổ tay, hông, gối, bàn chân; vẽ chi tiết theo hệ tọa độ của xương; kiểm tấn công, đỡ, hái lượm, khai khoáng, đi và chạy. Sau khi đối chiếu hình và kiểm ràng buộc ở hướng này mới áp dụng hợp đồng tương tự cho bảy hướng còn lại. Từng hướng vẫn có dữ liệu riêng, không xoay toàn bộ một hình nhân vật.

Giữ hình đầu/áo và tỷ lệ concept hiện hành, hai giới tính và các lựa chọn trang phục/vũ khí. Mô phỏng chiến đấu, thời điểm phóng Cổ/va chạm và phần thưởng thu thập vẫn là thẩm quyền riêng; renderer chỉ đọc pose và sự kiện.

## Asset gắn vào xương

`tools/author_directional_character_parts.py --directions 0` cho phép vẽ lại đúng hướng đang kiểm; các hướng khác giữ bộ chi tiết đã có. Manifest lưu chuỗi xương tư thế gốc cùng điểm neo, độ phủ phần khuất và các đường hướng dẫn co vải. Có 352 SVG chi tiết độc lập cho 16 tổ hợp giới tính/hướng.

Một tay áo có một chủ thể vẽ. `concept_pose_fit.gd` nội suy độ rộng mặt trong/mặt ngoài từ góc gập khuỷu và độ nâng cánh tay. Đường viền, nếp vải và màu của cùng SVG đi theo lưới; không xếp thêm một tay áo mờ ở tư thế cũ. Viền kem mỏng hơn và có miệng tay áo tối để đọc được độ dày. Bàn tay, giày và vật cầm giữ cứng.

Các mặt trước, chéo, ngang và sau có đường co vải riêng. Mép tay áo được bo tròn, thu ngắn phần sáng phía dưới để khi gập vào trong không tạo một mũi nhọn giống ngón tay thừa. Vùng vai có màu vải đầy đủ ở phần khuất, giúp động tác giơ tay không mở ra một khoảng trong suốt.

Miếng nối vai giữ điểm may vào thân và điểm gốc cánh tay. Phép trượt theo chiều dọc chỉ phụ thuộc tọa độ ngang, có định thức bằng một: không lật miếng nối khi giơ tay cao. Các phép biến dạng được đặt sau bộ giải xương, không thay chiều dài xương.

## Động tác

`direction_action_fit.gd` lưu mốc tay/thân theo hướng và thao tác; mục tiêu tay tính theo chiều dài thật của từng bên. Kiểm cả chuyển tiếp, không chỉ các ảnh đứng yên ở mốc đẹp. Góc vũ khí và góc bàn tay dùng cùng giới hạn cổ tay; thương giữ hợp đồng hai bàn tay trên một cán.

Đỡ kiếm phải đồng thời thỏa chiều dài chi, góc khuỷu, vùng tay trước ngực và hướng lưỡi kiếm. Kết quả fitting lưu ở tọa độ thân trong cache giới hạn; nhịp thở chỉ biến đổi kết quả đã tìm, không tìm kiếm lại hàng trăm ứng viên mỗi frame.

Thế đỡ dùng kiếm giơ chéo ra ngoài, thay vì ép kiếm gần thẳng đứng ở mọi góc. Với một số tỷ lệ tay gốc, ràng buộc thẳng đứng khiến lưỡi kiếm cắt ngang mắt dù xương vẫn đúng. Bộ giải đo khoảng cách của toàn đoạn lưỡi kiếm với vùng mặt hình ellipse; bài kiểm kiểm lại kết quả đã gắn vào bàn tay trong suốt chu kỳ, không chỉ đo mục tiêu lý tưởng.

Lượt xem clip phát hiện hướng lên trái đưa tay vào sau đầu ở pha chạm: khớp đúng nhưng chỉ còn một mẩu mũi kiếm nhìn thấy. Điểm chạm kiếm/hái lượm của riêng hướng này được chuyển sang bên trái và thấp hơn đầu. Bài kiểm đo khoảng cách bàn tay thực với cả đường bao đầu lẫn áo, rồi đối chiếu lại hình để bảo đảm ngón tay không bị tay áo còn lại che hết. Nhịp chuẩn bị hướng lên và xuống phải có dữ liệu riêng để giữ giới hạn tốc độ xoay lưỡi kiếm; thời điểm sự kiện chiến đấu vẫn giữ nguyên.

## Kiểm chứng và xem ảnh

- `tests/character_pose_fit_tests.gd`: đúng các đỉnh được renderer dùng; giữ điểm neo, giới hạn diện tích tam giác, không lật lưới và không thay dáng gốc ở pha đứng.
- Bộ kiểm chuyển động kiểm chiều dài chi, chân trụ, chuyển trọng tâm và góc vật cầm.
- `tests/character46_seam_review.gd`: đo alpha quanh vai, khuỷu, cổ tay, gối và cổ chân trên framebuffer trong suốt khi chạy chuỗi chuyển động bằng `present_smooth`. Phép kiểm này phát hiện lỗ ở các điểm nối đã lấy mẫu; ảnh và playback vẫn cần được xem để đánh giá đường viền và tư thế.
- [Xưởng xem từng hướng](http://localhost:8879/concept46_character_workshop.html): xương → asset trên xương → hình hoàn chỉnh, cả nam và nữ, ảnh/chuỗi frame Godot thật.
- [Hợp đồng capture và browser](character46-workshop.md) ghi các lệnh dựng và giới hạn của bằng chứng hình ảnh.

Baseline 0.44 được giữ trong fixture để đối chiếu đúng động tác/pha. Không tự coi việc các kiểm số học đạt là nghiệm thu mỹ thuật.
