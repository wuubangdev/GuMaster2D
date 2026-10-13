# Nhịp kiếm và thu thập 0.42

## Phạm vi

Cải thiện animation kiếm của nhân vật concept hiện hành; thêm hái lượm và khai khoáng vào thao tác E. Giữ hai giới tính, tám hướng, trang phục và các vũ khí. Đây là chỉnh chuyển động của prototype PC hiện có; nghiệm thu mỹ thuật vẫn cần người dùng xem playback.

## Nguồn tham khảo đã kiểm

- [Trailer gameplay chính thức DST, Klei](https://www.youtube.com/watch?v=dU-aq2JbLkk): mở trình phát và kiểm chuỗi ảnh gameplay trồng trọt ở 26–29 giây, chiến đấu ở 33–33,6 giây. Các ảnh quan sát nằm trong `artifacts/reference42/`. Đoạn chiến đấu có cả phản ứng trúng đòn, không dùng nó như dữ liệu chính xác của một chu kỳ chém kiếm.
- [Slide 2-D Animation at Klei Entertainment, GDC 2014](https://media.gdcvault.com/GDC2014/Presentations/Agala_Jeff_2D_Animation_at.pdf), Jeff Agala và Aaron Bouthillier: các trang 5–15 trình bày rough animation, tư thế chính, symbol theo khớp, atlas và nội suy theo lớp. Dùng để định hướng thứ tự: chọn dáng → bám khớp → nội suy → xem lại.
- [Video bài trình bày trên kênh GDC](https://www.youtube.com/watch?v=8_KBjd0iaCU): đã mở trình phát; việc seek các đoạn xa bị treo nên phần kỹ thuật dựa vào slide đã đọc. Không tuyên bố đã xem toàn bộ bài nói 23 phút.

Các thời lượng và key bên dưới do dự án tự thiết kế, không phải dữ liệu frame trích từ DST. Asset nhân vật và công cụ thuộc bộ Cổ Sư hiện tại.

## Quyết định chuyển động

| Động tác | Thời lượng | Mốc chạm/ra đòn | Hành vi |
|---|---:|---:|---|
| Kiếm | 0,64 s | pha 0,34 = 0,2176 s | Thân và tay cùng các mốc lấy đà, ra đòn và theo đà; cổ tay dùng đường cong liên tục thay cho độ trễ lò xo ở lúc chạm |
| Hái lượm | 0,88 s | pha 0,50 = 0,44 s | Hạ hông, nghiêng thân, đưa tay, nắm, rút; tay trái cân bằng |
| Khai khoáng | 0,96 s | pha 0,48 = 0,4608 s | Giơ cuốc tới pha 0,28, giữ tới 0,30, bổ và thu; công cụ gắn vào grip thực |

`GuCharacterActionMotion` sở hữu thời lượng và đường cong Hermite đơn điệu. `GuConceptCharacterRig` giải vai/khuỷu/cổ tay theo từng hình chiếu, giữ chiều dài xương. Khi đứng thao tác, pelvis được giới hạn trong khoảng cả hai chân chạm đất; điểm đầu/cuối quay về dáng nguồn. Đầu và vạt áo còn độ trễ nhẹ; cổ tay cầm vũ khí nhận key trực tiếp ở action để không tới chậm hơn hiệu ứng.

`GuHarvestToolArt` vẽ một cuốc ngắn với cán, đầu kim loại và dây quấn bằng hình học gốc; cùng transform với bàn tay. Renderer dùng bàn tay thả/nắm theo pha, tạm ẩn vũ khí khi làm việc và đặt công cụ sau đầu khi lấy đà. Descriptor trang bị không thay đổi. F6 thêm Hái lượm và Khai khoáng; atlas pixel/clip 3D lưu trữ cũ không được giả lập như có những frame mới.

## Sự kiện và quyền sở hữu trạng thái

`JourneyActions` thêm metadata `harvest_action`, `site_id`, `origin` vào sự kiện thu thập đã được xác nhận. Quặng/đá dùng mine; vật liệu khác dùng gather. `CultivationActions` bổ sung metadata cho thu hoạch ruộng. Vật phẩm, cooldown và điều kiện từ chối vẫn xử lý nguyên tử ở authority.

`WorldView` chỉ chạy động tác khi người chơi đứng gần nguồn trong bán kính tương tác hiện hành. Thu hoạch từ bảng điền viên ở xa vẫn dùng phản hồi tài nguyên hiện có. `ActorView` giữ thời gian riêng và số lượt action: di chuyển, bị đánh, dùng Cổ, chết hoặc chuyển map kết thúc động tác. Hiệu ứng lá/mảnh khoáng đợi tới mốc chạm; nếu ngắt trước đó thì bỏ hiệu ứng chưa phát. Việc ngắt hình ảnh không thu hồi phần thưởng đã được authority xác nhận.

Nguyệt Nhận lấy gốc phát từ bàn tay đang hiển thị ở thời điểm kiếm ra đòn, giữ mốc va chạm projectile 0,28 s. Máu, sát thương, chi phí Cổ không bị animation tính lại.

## Kiểm chứng

- `character_action_motion_tests.gd`: 9.312 tư thế qua hai action × hai giới tính × tám hướng × ba vũ khí × 97 pha; kiểm chiều dài xương, điểm vai, giới hạn khuỷu/cổ tay, chân trụ và về nghỉ. Kiểm sự kiện tài nguyên thành công/từ chối, ngắt khi di chuyển/trúng đòn/thi triển.
- `concept_combat_tests.gd` và các suite cũ: tiếp tục kiểm tiếp xúc kiếm, grip thương, tay phụ, liên tục đường cong và các pose nguồn. Các assertion đợi phóng projectile cập nhật sang thời điểm release mới, đồng thời kiểm không phát trước mốc.
- `character_action_ingame_review.gd`: phím E thật ở rừng và mỏ, bấm lặp, thưởng đúng một lần, hết action, F6; fixture đặt vị trí và một lượt hạ quái để mở map, không sửa save người dùng.
- `character_action_motion_review.gd`: 96 bảng frame của ba action, 12 overlay xương; 16 hình chiếu mỗi bảng, dùng `present_smooth` thật. Trang xem phát ở đúng thời lượng hoặc 1/2 và 1/4 tốc độ.
- `verify_action_motion_review.cjs`: 48 tổ hợp action/body/hướng, playback, overlay, ảnh gốc 2560 px và viewport 390 px.

Kết quả cuối và hash concept được ghi trong `artifacts/concept42_delivery.json`. Nguồn PNG concept giữ nguyên. Kiểm hình chạy Godot Linux/Mesa; chưa benchmark FPS trên máy Windows mục tiêu. Độ mượt và số học khớp không tự xác nhận chất lượng hình vẽ đạt ngang Klei.

## Chạy lại

```sh
bash tools/run.sh --headless --script res://tests/character_action_combat_runner.gd -- --test-mode
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/character_action_motion_review.gd -- --test-mode --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/character_action_ingame_review.gd -- --test-mode --capture-offscreen
python3 tools/build_action_motion_review.py
```

Trang xem: <http://localhost:8879/concept42_action_review.html>. `tools/serve_action_review.cjs` phục vụ riêng thư mục artifacts tại cổng loopback 8879; chạy bằng Node trên Windows nếu trình duyệt Windows không nối localhost WSL.
