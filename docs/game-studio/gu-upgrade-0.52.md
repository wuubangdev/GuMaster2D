# Cường hóa và nâng bậc Cổ 0.52

## Thiết kế trước khi triển khai

Hướng hình ảnh: một mặt giấy màu ấm, nét mực và điểm nhấn ngọc; tranh Cổ hiện có là điểm nhận diện chính, thông tin và nguyên liệu có khoảng cách rõ.

Bố cục: danh sách Cổ trang bị/dự trữ bên trái; tranh và trạng thái Cổ đã chọn bên phải. Hai tab Cường hóa / Nâng bậc dùng cùng bảng so sánh hiện tại → kết quả. Nguyên liệu và nút hành động ở chân vùng làm việc, luôn nhìn được ở 960×640. Vùng chi tiết cuộn riêng khi cần.

Tương tác: chuyển Cổ có đổi tranh nhẹ; hover và tab chọn có nét ngọc; thành công phát phản hồi ngắn trên tranh, cập nhật kết quả và thông báo. Giảm chuyển động giữ phản hồi tĩnh. Chọn phôi cụ thể và xác nhận phần sẽ tiêu hao trước khi nâng bậc.

Phạm vi: Cường hóa là tu luyện từ mức 1 đến 5; Nâng bậc là luyện hợp I → II → III. Giữ các công thức, điều kiện vùng an toàn, chi phí và lưu tiến độ hiện có. Hiển thị chỉ số theo đúng phép tính dùng skill, gồm giới hạn khiên và hồi chiêu lướt.

## Cách dùng

Nhấn **G** hoặc chọn **Nâng / hợp Cổ** trong túi. Chọn Cổ ở danh sách trái; Cổ dự trữ có mã instance riêng, Cổ trang bị hiện phím kỹ năng đang khảm. Khi mở một Cổ ở cuối danh sách, giao diện tự cuộn đến dòng đã chọn.

| Tab | Điều kiện và giá | Kết quả |
| --- | --- | --- |
| Cường hóa | Mức hiện tại L < 5; 2L linh thảo + L nguyên thạch + 25L bạc | Tăng một mức, giữ bậc, Cổ và no đủ |
| Nâng bậc I → II | Cổ chính đạt mức 3; chọn một phôi dự trữ bậc I cùng loại; 2 tơ tằm + 3 cổ tinh + 100 bạc | Cổ chính thành bậc II, mức 1, no đủ 100%; tiêu hao đúng phôi đã chọn; giữ ô kỹ năng |
| Nâng bậc II → III | Cổ chính đạt mức 5; chọn một phôi dự trữ bậc I cùng loại; 4 tơ tằm + 6 cổ tinh + 200 bạc | Cổ chính thành bậc III, mức 1, no đủ 100%; tiêu hao đúng phôi đã chọn; giữ ô kỹ năng |

Hai thao tác cần vùng an toàn, nhân vật còn sống, hết giao chiến và không đang phong ấn. Đủ điều kiện thì thành công 100%. Nút bị khóa có lý do và số nguyên liệu có/cần. Hộp nâng bậc ghi Cổ chính, mã/mức phôi và từng nguyên liệu sẽ tiêu hao; **Giữ lại / Esc** hủy mà không trừ tài sản.

## Chỉ số và phản hồi

Tranh Cổ dùng cùng bốn SVG gốc với thanh skill và hành trang. Bảng so sánh hiện sức mạnh cùng chỉ số chịu tác động trực tiếp: sát thương cho Nguyệt Quang/Băng Tằm, khiên cho Bạch Ngọc, hồi chiêu cho Bạch Hạc. No đủ, chân nguyên và hồi chiêu hiện tại đặt cạnh tên Cổ để giữ bảng gọn.

`GuCultivationRules.stats()` phục vụ cả giao diện lẫn `LocalAuthority.cast()`, giữ phép tính chiến đấu cũ: có ảnh hưởng level nhân vật/no đủ; khiên tối đa 40% sinh lực và hồi chiêu lướt thấp nhất 55% giá trị cơ bản. Bảng không hứa tăng khiên hoặc giảm hồi chiêu vượt giới hạn.

Sau giao dịch, mức/bậc, số nguyên liệu, danh sách phôi và hạng trên thanh skill cập nhật từ authority. Kết quả hiện ngay trong bảng và qua toast/âm thanh hiện có. Đổi Cổ có fade tranh 0,14 giây; thành công có vòng phản hồi 0,48 giây. Bật giảm chuyển động dừng các hiệu ứng này ngay và giữ thông báo tĩnh.

## Mã và dữ liệu

- `GuCultivationWorkshop` xây control một lần, cập nhật dữ liệu tại chỗ; danh sách Cổ và phần chi tiết cuộn riêng, chân nguyên liệu/nút chính giữ trong viewport. Tab T và H tiếp tục dùng trang địa đồ/bí cảnh hiện có.
- `GuCultivationRules.preview()` là truy vấn thuần; UI và lệnh upgrade/fuse dùng cùng điều kiện. UI gửi phiên bản túi, hộp xác nhận giữ snapshot riêng; yêu cầu cũ bị từ chối trước khi tiêu hao phôi/nguyên liệu.
- Phiên bản trong args là trường tùy chọn, nên lệnh gameplay/quest cũ vẫn dùng được. Giữ schema profile 1, các trường rank/cultivation và công thức lưu hiện có.
- Theme popup được chuyển vào `GuPixelUI.popup_theme()` để hành trang và luyện Cổ dùng chung. Menu/hộp xác nhận được dọn khi đóng, đổi trang hoặc pause.
- Capture được đưa vào chữ ký cập nhật UI, để kết thúc phong ấn làm nút hoạt động trở lại ngay cả khi túi không đổi.

## Kiểm chứng

| Kiểm | Kết quả |
| --- | --- |
| Logic Linux / Windows | **25/25 trên mỗi nền tảng**; chi phí chính xác, preview thuần, phôi không hợp lệ, version cũ, giới hạn, lưu thật và nạp lại |
| Chỉ số với skill thật | **120 lượt cast trên mỗi nền tảng**, bốn Cổ × ba bậc × năm mức × hai trạng thái no đủ; giữ các giá trị chuẩn của chiến đấu cũ |
| Cơ chế tu luyện/bí cảnh có sẵn | **60/60**, gồm nâng Cổ, luyện hợp, sản xuất tài nguyên và lưu profile cũ |
| Hồi quy toàn game Linux | **911/911**, không lỗi, chạy lại trên nguồn cuối |
| UI native Windows/NVIDIA | **63/63**; chuột/phím qua hệ input thật, chọn phôi và xác nhận thật, ba kích thước 960×640 / 1280×800 / 1920×1080 |
| Trang review | **19/19**, đủ bốn Cổ, các trạng thái và ảnh native; không lỗi JS/tài nguyên hoặc tràn ngang ở 390 px |

Đã xem ảnh cường hóa, nâng bậc và xác nhận ở cỡ nhỏ; sửa nhãn nguyên liệu/phôi bị co chữ thành cột, giữ bảng so sánh và chọn phôi cùng nhìn được. Kiểm native cũng thử giảm chuyển động, bắt đầu/kết thúc capture, Cổ ở cuối danh sách, chuyển T/H và đóng Esc. Hồi quy toàn game được lưu trong `artifacts/gu52_regression_linux.json`; manifest chốt nguồn và ảnh là `artifacts/gu52_delivery.json`.

[Xem giao diện, bốn loại Cổ và ảnh trước/sau](http://localhost:8879/gu52_review.html).

Chạy lại:

```sh
bash tools/run.sh --headless --script tests/gu52_tests.gd -- --test-mode
bash tools/run.sh --headless --script tests/cultivation_tests.gd -- --test-mode
bash tools/run.sh --headless --script tests/test_runner.gd -- --test-mode
.tools/godot/Godot_v4.7.2-stable_win64_console.exe --path 'D:\freelance\gumaster2d' --script res://tests/gu52_review.gd -- --test-mode
```

Các kiểm dùng profile riêng/test-mode. Đây là tính năng cho bản chơi PC local hiện có; chất lượng cân bằng dài hạn được theo dõi cùng hệ kinh tế của game.
