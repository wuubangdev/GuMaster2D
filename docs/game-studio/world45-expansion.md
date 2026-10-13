# 0.45 — Đại vực, Cổ thuật và quần thể dị thú

## Phạm vi

Mở rộng ba bản đồ đang chơi từ 96×96 lên 256×256 ô: 8.192×8.192 đơn vị thế giới mỗi vùng, diện tích gấp 7,11 lần bản 0.44. Giữ tuyến nhập môn, ID nhiệm vụ, cơ chế nâng/hợp Cổ, ruộng và hồ sơ người chơi. Nối 64 bãi farm, 33 trạm và 176 nguồn tài nguyên bằng đường vòng, cầu và các khu cảnh quan có tên; khám phá trước khi dùng trạm xa.

Tham khảo cảm giác hành trình qua nhiều khu vực của [cẩm nang nhiệm vụ thế giới Võ Lâm Truyền Kỳ II](https://volam2.vnggames.com/cam-nang/nhiem-vu/nhiem-vu-the-gioi.html), đã đọc ngày 2026-10-12. Không có số đo bản đồ chính thức được xác minh; kích thước nêu trên là thiết kế cụ thể cho dự án này. Địa danh, sinh vật, bố cục và tranh Cổ là phần sáng tác cho game.

Bốn Cổ đang có trong catalog nhận minh họa riêng thống nhất từ thanh phím số đến bảng Cổ. Hiệu ứng giữ nguyên thời điểm thi triển/va chạm đã nghiệm thu; trình vẽ không thay đổi HP hoặc trả thưởng. Quái có chi tiết cơ thể và khớp chuyển động theo góc, động tác báo đòn, ra đòn và hồi thế. Vùng báo nguy lấy cùng hình học với kiểm sát thương.

## Tích hợp

- WorldContent giữ dữ liệu địa lý; WorldGrid tạo va chạm và chỉ mục vật thể. Địa hình, cây/đá và mặt nước dựng gần camera; vùng xa vẫn có dữ liệu va chạm và đường đi.
- WildlifeAI giữ nhịp đánh, hướng khóa lúc lấy đà và hồi thế. BeastAttackGeometry chia sẻ diện tích đòn với hình báo nguy; BeastArt đọc trạng thái, không gây sát thương.
- ActorView dùng hình quái mới cho cả sói nhập môn; giữ nguyên cơ chế AI nhập môn. Nhân vật chính và bộ concept 0.44 giữ nguyên.
- Save schema 1 không đổi. Các ID mới hợp lệ trong JourneyModel; nội dung cũ vẫn đọc được. Test chạy với --test-mode, không dùng hồ sơ thật.

## Nghiệm thu

Builder theo ba phần sở hữu riêng → review chéo → kiểm mô phỏng và scene thật. Kiểm đường đến nguồn/bãi/trạm, hồ sơ cũ, phạm vi báo đòn, né đòn, damage một lần, việc dựng/giải phóng cảnh khi dịch chuyển, bảng Cổ và hình native theo các hướng/động tác. Đo thời gian bước mô phỏng riêng với render phần mềm; không quy thành tuyên bố FPS trên PC khác.

| Phần kiểm | Kết quả |
| --- | --- |
| Hồi quy toàn game | 906/906, 0 lỗi; log cuối `artifacts/world45_regression_final.log` |
| Địa lý và bảo toàn địa hình cũ | 437/437; mọi bãi, trạm, nguồn và NPC có đường đi; 21.322 ô đi được cũ vẫn đi được |
| Thế giới, chiến đấu, tài nguyên và save | 887/887 |
| Quest và điền viên hiện hành | 76/76 và 60/60 |
| Quái | 170/170; 51.984 mẫu vùng đòn, 10.752 phép giải chân; ảnh ở tám hướng |
| Minh họa và nhịp Cổ | 21/21; phím 1–4 và bảng G qua 17/17 kiểm trong scene native |
| Scene bản đồ mở rộng | 151/151; dẫn đường xa qua T, trạm, hồi sinh, camera, zoom và giảm chuyển động |
| Trang review | 34 ảnh tổng hợp; bộ quái 59/59 trạng thái browser, bộ Cổ 9/9; không tràn ngang ở 390 px |

Trong ba vị trí benchmark, chỉ 61–90 vật thể có node hiển thị trên tổng 4.363–6.000 vật thể mỗi map; 6 actor đang cập nhật hình trong số 105–123 quái. 180 bước mô phỏng tốn 486–756 ms khi chạy đồng thời bộ hồi quy, không gồm thời gian render. Scene test khởi tạo 11,7 giây với Linux/Mesa phần mềm và tài nguyên trên ổ Windows. Đây không phải benchmark FPS hoặc thời gian khởi động bản export trên GPU Windows.

Xem [trang tổng hợp](http://localhost:8879/world45_review.html), [phát chậm quái](http://localhost:8879/beast45_review.html), [Cổ và VFX](http://localhost:8879/gu45_review.html). Ảnh trong game dùng scene thật với save test riêng. Bộ xem quái thay hàng cóc bằng ảnh cuối sau khi sửa độ mở chân; các ảnh gốc trước sửa còn giữ để đối chiếu.

Chưa bao gồm MMO, nội dung nhiệm vụ mới, map vô hạn hay nghiệm thu cân bằng phát hành. Mật độ farm, thời gian di chuyển và phần thưởng cần playtest dài hơn; quái hiện có tám loại với hai biến thể đầu lĩnh trong số đó. Charge giữ hợp đồng mô phỏng cũ: vị trí đổi tại mốc va chạm, hình ảnh nội suy tới đích.

## Các lỗi phát hiện và đã sửa trong review

- Quái đầu lĩnh phóng hình 1,34× nhưng chu kỳ chân chưa tính tỷ lệ: stride dùng cùng body_scale với renderer, kiểm chân trụ trong tọa độ thế giới.
- Các mảng 3D chiếu thành đa giác tự cắt/điểm trùng: tạo silhouette từ đường bao điểm đã chiếu, làm tròn góc có giới hạn và tách đường nét khép kín khỏi đa giác tô; không bỏ cả bộ phận để giấu lỗi.
- Khiên xuất hiện hai lớp từ actor và WorldEffects: actor sở hữu toàn bộ hình khiên; hiệu ứng sự kiện chỉ thêm nét kích hoạt.
- Bật giảm chuyển động khiến cỏ không vẽ lại ở chỗ mới: vẫn cập nhật vùng nhìn, giữ pha cỏ đứng yên.
- Hồi sinh xa khiến camera lướt qua vùng chưa dựng: chốt camera và tải ngay ô đất/vật thể khi nhận sự kiện hồi sinh/dịch chuyển.
- Chân cóc bị thân che và lỗ mũi heo rừng hiện từ phía sau: mở chân theo đúng chiều dài khớp, thêm bàn chân có màng và giới hạn chi tiết mặt theo hướng nhìn.
- Fixture click sau cửa sổ RPG đặt camera nhưng chưa đồng bộ điểm bám: chốt cùng điểm bám và đợi một frame trước khi gửi input. Giữ nguyên hai assertion về chuyển từ WASD sang click dẫn đường; chuỗi này đạt 54/54 sau sửa.

Tham khảo chi tiết [map](world45-map.md), [quái](beasts45.md), [Cổ](gu45.md), [báo cáo bàn giao](../../artifacts/world45_delivery.json). Các PNG concept nhân vật gốc giữ nguyên SHA-256. Lượt hồi quy cuối chạy lại toàn bộ sau sửa fixture input đạt 906/906; log lần cũ còn giữ để truy vết hai lỗi fixture đã giải quyết.

## Chạy lại

```sh
bash tools/run.sh --headless --script res://tests/world45_map_tests.gd -- --test-mode
bash tools/run.sh --headless --script res://tests/world_expansion_tests.gd -- --test-mode
bash tools/run.sh --headless --script res://tests/beast45_tests.gd -- --test-mode
bash tools/run.sh --headless --script res://tests/gu45_art_runner.gd -- --test-mode
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/world45_native_review.gd -- --test-mode --capture-offscreen
python3 tools/build_world45_review.py
```
