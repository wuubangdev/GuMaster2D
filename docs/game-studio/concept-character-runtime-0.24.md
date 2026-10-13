# Nhân vật ngoài bản đồ từ concept gốc — 0.24

Mốc hiện hành: [sửa tách lớp và khớp 0.25](concept-character-articulation-0.25.md). Báo cáo dưới đây mô tả baseline 0.24 trước khi sửa chi tiết dính lớp và giày bị kéo giãn.

Ngày 11/10/2026. Yêu cầu: nhân vật chơi ngoài bản đồ cũng phải dùng bản vẽ đã duyệt. Renderer hiện lấy màu trực tiếp từ ảnh concept, thay phần đầu/thân/tay/chân SVG pilot trong world và các preview động.

## Nguồn và phạm vi khớp hình

- Nam hướng S, N, E dùng ba hình turnaround trên [concept 01](concepts/ink20/character-concept-01.png); SE dùng minh họa lớn bên trái của cùng ảnh.
- Bốn góc nam còn lại và tám góc nữ lấy từ [bảng hướng 02](concepts/ink20/detail-02/character-directions-02.png) đã có trong dự án. Mapping giữ S0/SW1/W2/NW3/N4/NE5/E6/SE7.
- Hai PNG màu trong `assets/characters/concept-rig` có SHA-256 trùng nguồn. Với áo jade, shader giữ màu nguồn; giấy quanh silhouette được bỏ bằng resource opacity riêng. Mặt, cổ áo ngà và bàn tay kín nét được giữ lại.
- Chân dung mặc định F3 vẫn dùng crop nguyên bản lớn của mốc 0.23. HUD, world, F6 và F3 ở các diện mạo khác dùng renderer nguồn mới.

Hình đứng giữ nét nguồn, nhưng chuyển động được rig nội suy từ các phần cắt. Bảng concept không chứa đầy đủ frame cho mọi hướng/hành động: chưa thể gọi mọi frame animation là bản sao 1:1 của key pose vẽ trên bảng. Ba bộ áo hiện đổi pigment trên cùng form; nón, tóc đuôi ngựa và thương vẫn là các lớp SVG hiện có, chưa có artwork concept riêng tương ứng.

## Hợp đồng runtime

`GuConceptCharacterArt` đọc manifest gồm 16 view, mỗi view có sáu mask: `head`, `torso`, hai tay và hai chân. Các mask và joint là tọa độ trên ảnh nguồn; mỗi view có ground pivot và hệ số chuẩn hóa chiều cao 64 đơn vị. Renderer tiếp tục dùng `display_height/NATIVE_HEIGHT` của API hiện hành, không đổi scale camera hoặc cell/hitbox.

Geometry được triangulate và cache ở source space trước khi biến dạng. Head chuyển động cứng; áo có sway; tay/chân dùng hai xương. Texture UV giữ nguyên trên hình nguồn. Mỗi view có material riêng cho blink, dùng vùng mắt đúng bảng hướng; sprite atlas lịch sử tiếp tục bị ẩn.

Offset joint nguồn được pha cùng pose khi đổi hướng/động tác. `hand_position()` và `weapon_tip()` lấy từ bàn tay và lưỡi kiếm đang vẽ; bốn Cổ và ghost lướt dùng cùng snapshot nguồn. Bản alpha được nạp sẵn; không flood fill PNG hoặc đọc ảnh thô mỗi frame.

Appearance vẫn có sáu slot `body/outfit/weapon/hair/boots/hat`. Đổi ngoại hình đi qua luồng Apply/save hiện hành. Cosmetic không cấp chỉ số và animation không gây damage.

## Tạo lại asset và evidence

Chạy từ thư mục dự án:

```sh
python3 tools/author_concept_character_masks.py
bash tools/run.sh --headless --editor --quit --import
bash tools/run.sh --headless --script res://tools/build_concept_mattes.gd
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
bash tools/run.sh --audio-driver Dummy --script res://tests/concept_character_visual_smoke.gd -- --test-mode
python tools/render_concept_motion_preview.py
```

Hai bước tạo mask chỉ ghi manifest, bản sao PNG không sửa màu và opacity `.res`. PNG nguồn gốc trong docs giữ nguyên. Bước đóng clip cần Python có Pillow; game không cần Python. Capture cần renderer native, không chạy với `--headless`.

## Kiểm chứng

| Kiểm tra | Kết quả / evidence |
|---|---|
| Regression Linux, Godot 4.7.2 | 539/539, không có lỗi trong [log](../../artifacts/concept24_tests.log) hoặc [kết quả JSON](../../artifacts/test_results_linux.json) |
| Nguồn đúng bản duyệt | SHA-256 hai ảnh trùng; 96 mask có tọa độ hữu hạn, đúng bounds và triangulate được; mặt/cổ áo/tay không bị opacity xóa |
| World | [Chính diện](../../artifacts/concept24_world_front.png), [góc SE](../../artifacts/concept24_world_quarter.png) lấy từ framebuffer của scene gameplay |
| Hướng và body | [Hai body × tám hướng](../../artifacts/concept24_directions.png) dùng cùng class với actor world |
| Hành động | [Đi](../../artifacts/concept24_walk.png), [chạy](../../artifacts/concept24_run.png), [đánh](../../artifacts/concept24_attack.png), [phòng thủ](../../artifacts/concept24_defend.png); [clip 48 frame](../../artifacts/concept24_motion.webp) lấy mẫu 24 Hz |
| Kỹ năng | [1](../../artifacts/concept24_world_skill_1.png), [2](../../artifacts/concept24_world_skill_2.png), [3](../../artifacts/concept24_world_skill_3.png), [4](../../artifacts/concept24_world_skill_4.png) được chấp nhận qua input số trong game; unit test giữ điểm phát từ grip đang hiển thị |
| Cosmetic | [Áo/mũ/giày/tóc/vũ khí](../../artifacts/concept24_equipment.png), hiện vẫn có phụ kiện vector cần artwork concept riêng |
| UI | 11/11 ảnh HUD/F3/F6/túi/nhiệm vụ/pause ở 960×640, 1280×720, 1280×800; [metadata](../../artifacts/ink20_ui_visual_capture.json), [log](../../artifacts/concept24_ui.log) không có lỗi runtime |
| Capture native | 12 PNG + 48 frame trên X11/Mesa llvmpipe; [metadata](../../artifacts/concept24_capture.json), [log](../../artifacts/concept24_native.log) không có lỗi runtime |

Tần suất capture là mẫu review xác định, không phải benchmark FPS. Windows và thiết bị PC mục tiêu chưa được chạy lại ở mốc 0.24. Các pose vận động, overlap kín khớp, form trang phục riêng và phụ kiện cần tiếp tục review mỹ thuật trước nghiệm thu phát hành.
