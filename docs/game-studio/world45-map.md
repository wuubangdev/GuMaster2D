# 0.45 — Đại vực 256 × 256

Ba vùng đang có được mở từ 96 × 96 lên **256 × 256 ô**: mỗi vùng 8.192 × 8.192 đơn vị thế giới, diện tích gấp **7,11 lần** bản 0.40. Đây là quy mô cụ thể của dự án để tạo cảm giác đi qua nhiều địa khu; không khẳng định bằng đúng kích thước bản đồ Võ Lâm Truyền Kỳ 2.

| Vùng | Địa khu | Bãi quái | Trạm | Nguồn thu thập |
| --- | --- | ---: | ---: | ---: |
| Thanh Mao Sơn | Trại cũ, Trúc Hải, Nam Khê, Đầm Sương, Nam Lâm, Lôi Lĩnh | 22 | 11 | 60 |
| Tam Vương Cổ Địa | Tiền điện, Thạch Trụ, Cựu Chiến Trường, Tàng Kinh, Phế Đô, Nội Điện | 22 | 11 | 60 |
| Thanh Nang Phúc Địa | Linh điền, Hoa Hải, Phúc Mộc, Bích Hồ, Liên Trì, Nguồn Linh Mạch | 20 | 11 | 56 |
| **Tổng** | **18 địa khu** | **64** | **33** | **176** |

Mỗi vùng thêm 16 bãi (14 bãi thường, 2 bãi đầu lĩnh), 8 trạm và 48 nguồn nguyên liệu. Loài quái dùng ID danh mục hiện có, không tạo vật phẩm hoặc công thức không có đầu ra. Các bãi nối với hai trạm gần nhất và vòng đường chính, có nhiều đường tiếp cận hoặc rút lui. Hai sông và hai hồ lớn mới mỗi vùng chia địa khu; đường qua nước trở thành cầu đá có va chạm chính xác. Khu linh điền ban đầu vẫn an toàn. T mở địa đồ, chọn bãi để dẫn đường; trạm mới vẫn cần khám phá và quyền dịch chuyển từ tuyến nhiệm vụ cũ.

## Tích hợp và bảo toàn

- `data/world_content.json`: giữ nguyên toàn bộ ID, tọa độ, quy tắc vật liệu và thời gian hồi cũ. Phần thêm có tiền tố `w45_`; lưu đường cũ ở `legacy_roads` để tái tạo địa hình tương thích. Không đổi schema save.
- `WorldContent`: raster khoảng trống và lòng đường một lần vào mảng byte, tránh quét mọi đường/bãi cho từng ô địa hình. Dữ liệu sông, hồ và địa khu nằm trong catalog.
- `WorldGrid`: tạo phần 95 × 95 bên trong bản đồ cũ bằng đường và chuỗi PRNG cũ, sau đó thêm vùng ngoài. Đường mới đi vào phần cũ chỉ xóa vật cản, không thêm vật cản vào vị trí từng đi được. Mở hàng rào ở mép cũ và giữ hàng rào ở biên 256.
- `WorldGrid.props_near`: chia props thành bucket 16 ô, trả nguồn có `stream_id` ổn định để WorldView chỉ giữ các props gần camera. Truy vấn không thay đổi thẩm quyền va chạm.
- `GroundView`: TileMap chỉ chứa cửa sổ camera, biên dự phòng 6 ô và bước 8 ô; nước chỉ cập nhật trong cửa sổ này. Phạm vi tự tính từ viewport/zoom, không khóa vào bán kính nhỏ. Hàng rào biên cũng chỉ tạo gần camera.
- `RegionalAtlas`: ảnh địa hình được tạo và cache một lần mỗi vùng; vị trí người chơi và các điểm tương tác tiếp tục cập nhật. Nhãn hiển thị 256 × 256, số bãi, trạm và địa khu thực tế.

Tái tạo phần mở rộng bằng `python3 tools/author_world45_data.py`. Lệnh này lặp lại không thay đổi kết quả và chỉ ghi `world_content.json`; không chạy lại `author_world40_data.py` để sửa 0.45 vì script cũ tái tạo các catalog của bản 0.40.

## Kiểm chứng

`bash tools/run.sh --headless --script res://tests/world45_map_tests.gd -- --test-mode`

**437/437 kiểm tra đạt, 0 lỗi** (`artifacts/world45_map_tests.json` và `.log`). Flood-fill theo bốn hướng xác nhận mọi bãi, trạm, tài nguyên và NPC đi đến được từ trại. Kiểm tra mọi bãi nằm ngoài vùng bảo hộ, mọi trạm có vùng an toàn, toàn bộ ruộng cũ được bảo hộ. Quét độc lập thuật toán cũ dùng khoảng cách hình học và PRNG xác nhận **21.322 vị trí đi được ở phần ngoài làng của bản 0.40 vẫn đi được** (7.082 / 7.334 / 6.906), và props cũ ngoài đường mở mới giữ đúng loại/biến thể.

| Phép đo trên môi trường phát triển này | Thanh Mao | Cổ Địa | Phúc Địa |
| --- | ---: | ---: | ---: |
| Tạo lần đầu (ms) | 1.402 | 935 | 984 |
| Tạo lại từ cache (ms) | 39 | 23 | 68 |
| Ô liên thông từ trại | 55.798 | 57.394 | 55.242 |
| Ô nước có va chạm | 2.694 | 2.758 | 3.376 |
| Ô cầu đi được | 371 | 411 | 462 |
| Props toàn vùng | 6.000 | 4.363 | 5.879 |
| Props tối đa trong bán kính 28 ô ở 4 điểm mẫu | 251 | 211 | 248 |

Fixture kiểm cửa sổ đất ở 3 vị trí xa và zoom 1×/2×/4×, giữ dưới 6.000 tile trong viewport 1280 × 720 và không cập nhật nước ngoài cửa sổ. Bucket props được đối chiếu với quét tuyến tính để không mất hoặc lặp một nguồn.

Các số trên đo geography và streaming, không phải chứng nhận FPS của toàn game. Bộ test tích hợp, ảnh native ba vùng, kỹ năng và quái do task 0.45 tổng hợp riêng. Cân bằng kinh tế cho số bãi tăng lên cần playtest dài hơn; không thêm tuyến nhiệm vụ mới trong lát cắt map này.
