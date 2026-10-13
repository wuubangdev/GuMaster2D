# Làm đẹp nhân vật cũ — 0.16

Yêu cầu đã được người dùng làm rõ: giữ nhân vật cũ, chỉ tối ưu đồ họa cho đẹp hơn. Giữ tỷ lệ chibi, hình đầu/mắt/tóc/áo/giày/vũ khí và toàn bộ mốc animation của0.15; không thay bằng mẫu người trưởng thành.

Tham khảo đề tài qua nguồn Steam chính thức đã đọc ngày2026-10-11: [Tale of Immortal](https://store.steampowered.com/app/1468810/), [Hero’s Adventure](https://store.steampowered.com/app/1948980/) và [Wandering Sword](https://store.steampowered.com/app/1876890/Wandering_Sword/). Chọn tinh chỉnh màu/chất liệu cho thư viện SVG có sẵn; không sao chép asset hoặc đo animation của game tham chiếu.

Da có chuyển sáng–tối ấm, tóc có vùng sáng mềm và chân tóc trầm, iris có độ sâu, vải có chuyển sắc/nếp mảnh, giày có chất liệu và lưỡi vũ khí có ánh kim. Bảng màu ngọc/chu sa/ngà của các trang phục cũ được giữ nhận diện. Các lớp SVG vẫn import8texel/đơn vị, linear; không làm mờ ảnh hay đổi silhouette.

Nghiệm thu: hash alpha và kích thước của131 phần SVG import khớp bản0.15; màu thực có thay đổi, mốc đầu/thân giữ nguyên. Native ảnh/clip của renderer thật để đánh giá hình ảnh. Nền/props/sói giảm bão hòa và props tiền cảnh mờ theo đầu/thân/chân của nhân vật cũ; navigation/authority không đổi. Đây vẫn là prototype, không dùng số test hoặc sampling rate để tuyên bố chất lượng release Steam.
