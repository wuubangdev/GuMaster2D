# Character and Skill Art Direction — Review Set 02

## Mục đích
Phát triển concept có thể duyệt trước khi làm runtime art. Hình hướng tới nét vẽ tay tối, mực loang, giấy màu ấm và silhouette đọc rõ như truyện tranh cổ tích gỗ; lấy cảm hứng không khí Don't Starve Together nhưng giữ nhân vật, biểu tượng và giao diện nguyên bản của dự án.

## Phạm vi concept
- Bộ dáng nam và nữ, cùng tỷ lệ chibi, nhận diện và bảng màu hiện có.
- Tám hướng: bắc, đông bắc, đông, đông nam, nam, tây nam, tây, tây bắc. Không lật gương sprite bất đối xứng.
- Key pose đứng, đi, chạy, tấn công, thủ, thi triển skill và nhận đòn. Đây là pose sheet để chốt thiết kế, chưa phải sprite sheet runtime đủ frame.
- Concept lắp ghép tóc/mũ, thân áo, giày và vũ khí trên cùng hệ trục và mốc khớp.
- Giữ đúng bốn skill hiện hữu: Nguyệt Quang, Bạch Ngọc, Bạch Hạc, Băng Tằm.

## Hệ nhân vật có thể thay trang bị
Quy ước layer độc lập: nền trong suốt; bóng chân; giày/chân; thân áo; tay gần; tay xa; phụ kiện thân; tóc sau; đầu/mặt; tóc trước hoặc mũ; vũ khí. Các lớp được tô, viền và đổ bóng cùng một hướng sáng. Mỗi hướng có bộ pose riêng để tay cầm, đầu, chân và nếp áo không bị lật sai.

Điểm neo ổn định theo từng hướng: origin đất giữa hai chân, hông, vai gần/xa, cổ, tâm đầu, cổ tay cầm, điểm nắm vũ khí, gối và mắt cá. Giới tính có silhouette, khuôn mặt và tỷ lệ tay/chân riêng; cả hai dùng chung tên điểm neo và khung animation để trang bị tương thích. Tóc, áo, giày, mũ và vũ khí là slot hình ảnh độc lập; mũ che tóc theo mask, tay đổi pose theo loại vũ khí, giày bám chân và mặt đất.

Hiện dự án có hai dáng nhân vật, ba màu/kiểu áo, hai kiểu tóc và ba vũ khí. Concept đề xuất thêm hai kiểu mũ và hai kiểu giày. Bộ đặc tả chi tiết thống nhất ma trận 216 look (hai giới tính, ba outfit, ba trạng thái nón gồm không đội/khăn/nón tre, hai tóc, hai giày, ba vũ khí). Xem [ma trận sản xuất](detail-02/PRODUCTION_MATRIX_03.md); đây là coverage mục tiêu, không phải 216 atlas hoàn chỉnh.

## Animation và skill
Đồ họa pose cần giữ chung chiều cao, độ dày nét, điểm đặt chân và góc sáng. Đi/chạy dùng nhịp có tiếp đất rõ, thân nghiêng vừa phải, tay đối chuyển động với chân, áo/tóc có độ trễ nhỏ. Khi quay hướng, cả tay cầm lẫn vũ khí đổi sang pose tương ứng. Đánh, thủ và thi triển có anticipation, khoảnh khắc chạm/đỡ và settle, tránh quầng sáng phủ kín silhouette.

Mỗi skill có icon đọc được ở kích thước nhỏ và nghiên cứu hiệu ứng trong cảnh: cast → travel → impact/guard → fade. Mực, bụi, giấy rách và nét cọ dùng có tiết chế; mỗi skill giữ hình dạng khác nhau để nhận ra bằng silhouette, không chỉ đổi màu.

## Điều kiện chuyển từ duyệt sang triển khai
Chỉ sau khi người dùng duyệt hướng vẽ và thiết kế nhân vật mới chuyển concept thành sprite/layer runtime. Trước khi đưa vào game sẽ chốt kích thước ô, pivot, quy tắc naming/import, atlas và các frame cần thiết; sau đó thay theo lát nhỏ và kiểm tra trực quan chuyển hướng, đổi đồ và skill trong Godot.
