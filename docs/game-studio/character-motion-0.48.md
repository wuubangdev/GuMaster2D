# Chuyển động nhân vật 0.48

Lượt sửa này xử lý khuỷu tay gập quá sát, vũ khí đổi góc đột ngột, đầu gối bẻ ngang ở hướng trước/sau và chân trượt khi bắt đầu/dừng di chuyển. Giữ artwork 0.47 và nhận diện concept; thay cách giải và phối hợp chuyển động.

## Tay và vũ khí

- Thi triển dùng đường góc vai và góc khuỷu cục bộ liên tục. Đường cổ tay không còn đi qua vai khiến phép giải đổi nhánh đột ngột.
- Vận công tuân theo cùng giới hạn khuỷu 135° với các động tác khác; điểm tay được dịch vào giữa theo đúng chiều dài xương để giữ ngang ngực, không đẩy xuống thắt lưng. Tư thế chuẩn bị kiếm/cuốc mở hơn, tránh giữ tay ở sát giới hạn gập.
- Trục thương liên tục ở hướng xuống phải. Bàn tay, chuôi kiếm/cuốc và điểm phát hiệu ứng vẫn dùng chung socket.
- Giữ nhịp chạm, thời điểm phát skill và quy tắc nhận tài nguyên của gameplay.

## Chân theo góc nhìn

Hai đoạn chân trên bản vẽ phía trước không thể giữ nguyên chiều dài **trên màn hình** khi chân co về phía camera. Ép chuỗi 2D đó tới bàn chân ở gần hông khiến đầu gối văng ra ngoài hoặc thấp hơn đế giày.

Rig mới cho phép chiều dài chiếu của đùi/cẳng chân co lại có giới hạn ở hướng trước/sau. Chiều dài vật lý được kiểm lại bằng khoảng cách màn hình cộng chiều sâu; hướng ngang giữ chiều dài nguồn. Các đoạn chuyển động và đổi hướng dùng cùng phép giải, tránh trở lại khung xương cũ trong lúc blend.

Lưới quần chạy từ hông đến gối và từ gối đến điểm bàn chân sau khi chiếu. Phần vải chồng tại hai đầu được giữ độ dài để khớp vẫn kín. Giày và bàn tay giữ hình cứng. Không thêm mảnh tay/chân cố định vào thân để che lỗi.

## Đồng bộ với di chuyển trong game

`ActorView` chuyển khoảng dịch chuyển thật của nhân vật cho bộ giữ chân trụ. Điểm tiếp đất được giữ trong tọa độ thế giới, kể cả lúc tốc độ và trọng số animation đang tăng/giảm. Chân nhấc được giải phóng theo pha bước; sau khi dừng, nhân vật đưa từng chân về tư thế đứng.

Phần bước chân chỉ áp dụng vào đi/chạy hoặc các động tác cho phép vừa đi vừa đánh/thi triển/đỡ. Đứng, trúng đòn và vận công không nhận trạng thái bước còn sót. Seek thủ công, giảm chuyển động, lướt, gục, hồi sinh và dịch chuyển lớn xóa lịch sử chân trụ; đồng bộ sự kiện với delta bằng 0 giữ nguyên hình đang hiển thị.

## Tái kiểm

```bash
bash tools/run.sh --headless --script res://tests/character48_arm_tests.gd -- --test-mode
bash tools/run.sh --headless --script res://tests/character48_locomotion_tests.gd -- --test-mode
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy \
  --script res://tests/character46_seam_review.gd -- --test-mode --capture-prefix=concept48
```

Trang review dùng framebuffer Godot thật, có kéo frame, phát chậm và hiện xương. Clip lấy mẫu theo thời gian animation và clip `ActorView` chạy trong không gian thế giới được ghi rõ riêng. Baseline 0.47 là bản mã thực thi đã đóng băng trước sửa. Kiểm số không thay thế đánh giá dáng và nhịp chuyển động bằng mắt; kết quả cuối được ghi trong `artifacts/concept48_delivery.json`.

Ở cận cảnh 256 px, nhịp co chân nhấc của hai hướng chéo lên vẫn khá nhanh khi rời giới hạn duỗi. Kiểm mật độ mẫu tăng dần xác nhận đường đi liên tục; ảnh native giữ kín cổ giày và đầu gối. Đây là rig cutout có phép chiếu chiều sâu, chưa phải bộ animation vẽ riêng từng frame hoặc nghiệm thu mỹ thuật cuối.
