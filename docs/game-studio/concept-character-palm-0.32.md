# Cổ tay, nhát chém và vùng áo bị thiếu — 0.32

Ngày: 12/10/2026. Tiếp nối [0.31](concept-character-combat-0.31.md), giữ nguyên PNG concept đã duyệt. Revision: `concept-native-palm-32`.

Bàn tay trước đây đi cứng cùng cẳng tay trong khi kiếm đã có góc cổ tay riêng. Nay mesh có ba vùng rigid: upper sleeve, forearm và palm. Cổ tay nằm ở cuff, palm xoay quanh điểm này; điểm nắm xuất cho drawing, vũ khí và kỹ năng là tâm bàn tay đã xoay. Chiều dài thật elbow–wrist và wrist–grip không thay đổi. Chuỗi IK ba điểm cũ giữ endpoint trung tính để tương thích, không dùng endpoint đó thay cho grip thực nữa. Cuff được suy ra theo tỷ lệ nguồn, chưa phải landmark do họa sĩ đặt riêng cho từng drawing.

Các key vai/khuỷu/cổ tay dùng đường Hermite đơn điệu qua contact ở pha 0,34, thu tay từ 0,56. Bỏ hai khoảng dừng giữa nhát chém; không đổi duration vũ khí hoặc luật gameplay. Lấy đà co gần ngực, wrist chỉ bẻ tối đa 0,30 rad ở load; strike vẫn giới hạn 0,85 rad. Đường cong không vượt các key hợp lệ, vai/khuỷu vẫn theo tỷ lệ nguồn. Mảng upper sleeve lộ ra dùng đường cong thuôn thay cho sáu góc thẳng. Tay kiếm đi trước lớp head khi render pha đánh để tránh dán chi tiết lên mặt.

Kiểm tra source ownership tìm thấy đoạn cẳng tay nam W/N bị trống sau khi xóa kiếm baked. Chỉ những khoảng trống liên tục đủ lớn được nối bằng dải cuff hẹp dưới pixel gốc. Bề rộng tối đa 0,83 native unit mỗi phía; không thêm tube cho toàn bộ forearm hoặc cap ở lòng bàn tay. Viền và mesh bàn tay cắt cùng hai mặt phẳng elbow/wrist, không outline các đường cắt nội bộ.

## Kiểm chứng

**593/593 regression Linux/Godot 4.7.2, 0 failure**: [log](../../artifacts/concept32_tests.log). Nguồn màu có cùng SHA-256 với baseline, không sửa bitmap để tạo tư thế.

| Kiểm tra | Bằng chứng |
|---|---|
| 4.656 pose combat, 976 pose playback | [Constraint report](../../artifacts/concept32_combat_constraints.json): elbow ≤135°; hand step lớn nhất 2,3655 native unit / 1⁄96 chu kỳ; blade step 15,228° so với 15,997° ở 0.31; hai tay thương lệch cán tối đa 0,00000728 native unit. |
| Palm thực | [784 pose](../../artifacts/concept32_palm_constraints.json): cạnh tam giác palm xoay cùng wrist/blade, wrist–grip giữ độ dài, grip query sai lệch 0; 16 view đều có articulation. |
| UV, topology, chuyển hướng | Test đầy đủ nguồn contour, area neutral, winding, cạnh rigid; giữ zero-time event/tip, hierarchy và điểm phát VFX. Test mới kiểm đạo hàm qua contact, curve không overshoot, cuff bridge theo đúng khoảng thiếu owner. |
| Frame combat | [Inspector 0.31 → 0.32](../../artifacts/concept32_combat_review.html): 144 PNG + 21 overlay thực. Cam/xanh: chuỗi tay; trắng: wrist và palm; vàng: trục vũ khí. |
| Các action khác | [11 action](../../artifacts/concept32_frame_review.html): 352 PNG × 16 view và 11 sheet S/N. [Chi tiết native](../../artifacts/concept32_detail_attack_02.png): 8 pha render trực tiếp ở height 192. |
| Gameplay và viền | [Native log](../../artifacts/concept32_native.log): 256 frame đi/chạy/đổi hướng/input thật, 22 still; [4 probe pigment](../../artifacts/concept32_edge_filter.json), [12 probe ink](../../artifacts/concept32_ink_core.json). |
| UI | [11 trạng thái / 3 viewport](../../artifacts/concept32_ui.log), dùng chung renderer nhân vật. |
| Browser / clip | Chrome Windows giải mã 165 ảnh combat và 352 ảnh action, kiểm scrub/play/body/direction/overlay/responsive. [Combat browser](../../artifacts/concept32_combat_review_browser.json), [action browser](../../artifacts/concept32_frame_review_browser.json). [Combat RGB](../../artifacts/concept32_combat_clip_validation.json), [motion RGB](../../artifacts/concept32_clip_validation.json): lossless từ nguyên framebuffer. |

[Clip kiếm](../../artifacts/concept32_combat_sword.webp) · [thương](../../artifacts/concept32_combat_spear.webp) · [tay không](../../artifacts/concept32_combat_unarmed.webp) · [đi lên/xuống](../../artifacts/concept32_vertical.webp).

## Giới hạn của pass

Palm đã có khớp riêng nhưng vẫn là drawing bàn tay đứng, chưa có biến thể ngón tay/kiểu nắm hoặc foreshortening theo action. Guard giữ góc vũ khí chuyên biệt của 0.31; giới hạn góc palm không xác nhận biomechanical mọi kiểu phòng thủ. Sleeve bridge là phần nối vector cho pigment bị thiếu, không thay cho artwork nếp gập mạnh. Chưa nghiệm thu mỹ thuật phát hành.

Capture và regression chạy Linux/Godot 4.7.2, X11/Mesa llvmpipe; không dùng capture làm benchmark FPS. Chrome Windows chỉ kiểm inspector; Godot Windows chưa chạy lại.

## Chạy lại

```bash
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_combat_review.gd -- --test-mode --capture-prefix=concept32 --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_action_frame_review.gd -- --test-mode --capture-prefix=concept32 --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_character_visual_smoke.gd -- --test-mode --capture-prefix=concept32 --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_locomotion_detail.gd -- --test-mode --capture-prefix=concept32 --combat-detail --capture-offscreen
python tools/build_concept_combat_review.py concept32
python tools/build_concept_frame_review.py concept32
python tools/render_concept_combat_preview.py concept32
node tools/verify_concept_combat_review.cjs concept32
node tools/verify_concept_frame_review.cjs concept32
```
