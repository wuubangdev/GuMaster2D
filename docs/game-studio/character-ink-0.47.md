# Nét vẽ nhân vật 0.47

Tiếp tục hoàn thiện nhân vật đã duyệt: nét tay áo, băng cổ tay và giày trước đây quá đều, mảng màu phẳng, lệch với đầu và áo thân. Ở kích thước chơi, nét tóc và các đường nhỏ trên asset cũng bị lấp nhấp khi dịch qua pixel.

## Mỹ thuật

- Cập nhật 352 chi tiết SVG của 16 bộ nam/nữ × tám hướng. Tay áo có mảng màu đất, mặt sáng rộng và nếp vải thuôn đầu; không thêm hạt nhiễu hoặc đường gạch dày.
- Tăng trọng lượng mực ở mép khuất bằng mảng thuôn nằm phía trong đường bao. Giữ đường bao và mốc vai, khuỷu, cổ tay, bàn chân của bản 0.46.
- Băng quấn cong và nghiêng theo bề mặt; mặt trước, nghiêng và sau có cách đặt nếp khác nhau. Giày có mặt mũi/gót và đế màu đất thay cho những dải ngang phẳng.
- Giữ nguyên hai PNG concept, nhận diện đầu, tóc, mặt, cổ áo, hoa văn thân và ngọc bội. Đây là lượt chỉnh nét/tô các chi tiết gắn xương, không phải vẽ lại toàn bộ nhân vật hay từng frame.

`art_revision=47` tách khỏi `fitting_revision=46`. Bounds, điểm bám, rest chains, đường co vải và tọa độ atlas giữ nguyên. Generator chạy lại cho kết quả giống từng byte; bằng chứng nằm trong `artifacts/concept47_asset_contract.json`.

## Lọc nét ở kích thước nhỏ

`concept_cutout.gdshader` áp dụng bộ lọc theo diện tích pixel đang hiển thị cho cả đầu. Khi phóng lớn, nét nguồn vẫn dùng đường lấy mẫu cũ. Màu giấy và phần cơ thể khác được loại trước khi trộn để tránh viền sáng.

Atlas chi tiết dùng chín mẫu theo footprint của pixel, trộn màu đã nhân alpha rồi chia lại. Mỗi mẫu bị giới hạn trong ô của chính chi tiết đó, tránh lấy màu bàn tay hoặc cổ tay ở ô cạnh. Đây là giảm aliasing bằng lấy mẫu, không làm sắc toàn ảnh hoặc thêm viền bằng hậu kỳ.

**Hợp đồng cần giữ:** schema atlas hiện dùng ô 96×144 px và gutter ít nhất 2 px. Nếu đổi cách đóng atlas trong generator, phải cập nhật giới hạn ô của shader và chạy lại kiểm packing/cell isolation. Không bật mipmap thông thường cho các ảnh có ownership mask.

## Bằng chứng và tái kiểm

[Trang so sánh](http://localhost:8879/concept47_character_review.html) dùng ảnh Godot thật ở cỡ cấu hình 200 và 48 px. Hai phiên bản có cùng pose, giới tính, hướng và thời điểm. Bộ atlas/shader 0.46 được đóng băng để đối chiếu; ảnh hiển thị trên trình duyệt không phóng quá độ phân giải native. Xem [quy trình chụp](character47-review.md) để tái tạo đủ clip và kiểm dấu vết nguồn.

Kiểm GPU trên Linux/Mesa và Windows/NVIDIA đều qua: nét mực đục, phân tách giấy/owner, alpha khi mờ và chặn màu ô bên cạnh. Trong phép thử đường kẻ nhân tạo dịch qua 16 vị trí dưới pixel, sai số alpha trung bình giảm từ khoảng 0,2495 xuống 0,0284 trên Linux và 0,0282 trên Windows. Đây là phép kiểm lấy mẫu có kiểm soát, không phải điểm chất lượng mỹ thuật hay số đo FPS.

```bash
bash tools/run.sh --headless --editor --quit
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy \
  --script res://tests/character47_filter_tests.gd -- --test-mode
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy \
  --script res://tests/character46_seam_review.gd -- --test-mode --capture-prefix=concept47
```

Kết quả cuối và đường dẫn bằng chứng được tổng hợp trong `artifacts/concept47_delivery.json`. Kiểm alpha chỉ chứng minh độ kín tại các điểm đã lấy mẫu; xem ảnh và chuyển động vẫn cần thiết để đánh giá nét vẽ và đường bao.
