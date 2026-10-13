# Tay, chi tiết khớp và chuyển hướng — 0.17

Giữ nhân vật chibi hiện có theo yêu cầu người dùng. Phạm vi là chuyển động và nét khớp; đầu, mặt, tóc, áo, giày, vũ khí và 131 SVG gốc giữ nhận diện/chất liệu 0.16.

Vai/cổ tay dùng cùng frame thân ở tám hướng. Khuỷu tay có hướng gập chiếu từ facing; góc ngang cả hai tay gập về sau cổ tay, quay trái/phải thì đổi hướng gập. Khi blend hoặc bị ngắt bởi ra đòn, tham số gập pha trộn cùng endpoint. Tay gần/xa chọn theo độ sâu vai chiếu từ hướng nhìn, độc lập với vai nhún lên/xuống khi đi/chạy, vũ khí vẽ cùng tay cầm; tay xa/vũ khí xa có thể bị thân/đầu che đúng lớp.

Tay đi/chạy đối trọng theo travel thực từng chân; nhịp chạy dùng stance ngắn riêng thay vì cùng một sine không gắn với contact. Cổ tay xoay theo cẳng tay, giữ tâm bàn tay làm grip/điểm phóng thật. Các đường cẳng tay/chân là dải cong thuôn với chuyển sắc sáng–tối nhẹ và viền 0.65 đơn vị, giữ silhouette tay áo/giày đã có. Dải được vẽ theo quad để tư thế gập không gây polygon lỗi; chi tiết không tăng kích thước đầu/thân.

Bằng chứng: tests/directional_motion_smoke.gd quay renderer dùng trong game/F6 ở kích thước 128 và 48 px, tám hướng, đi/chạy tay không, phòng thủ kiếm, đánh thương. 240 framebuffer native ở 60Hz/4 giây; WebP lossless và GIF lấy mẫu, không tạo frame giả. Các capture world/F3/F6 và profile được chạy lại với rig mới. Chín acceptance thêm vào tests/smooth_motion_tests.gd; guard nhận diện và tay phóng vẫn giữ.

Tỷ lệ chibi và tám view đầu/áo vẫn là phong cách của game hiện tại. Tốc độ lấy mẫu clip không phải đo FPS. Mục tiêu lần sửa này là loại bỏ hướng tay sai, nối khớp cứng và chuyển động thiếu đối trọng, không công bố đồ họa đã đạt chuẩn phát hành.

Góc vũ khí nghỉ chiếu theo phía bàn tay cầm; tip kiếm nằm ngoài đầu ở cả tám hướng, tránh bị che hết khi quay lưng.
