# Nhân vật 0.34 — vải tay áo theo khuỷu

Ngày: 12/10/2026. Revision: `concept-native-soft-sleeve-34`. Phạm vi: tiếp tục sửa độ cứng của nhân vật 0.33, ưu tiên tay áo gập và khoảng nối vai ở W/N. Giữ nguyên hai PNG concept đã duyệt, hai body, tám hướng, wardrobe và rig gameplay.

## Thay đổi trong game

Vải cánh tay trên uốn cục bộ trong khoảng 3,2 đơn vị native trước khuỷu, theo một phần góc xoay của cẳng tay. Giới hạn mềm `tanh` tối đa 0,22 rad tránh đổi vận tốc đột ngột khi gập mạnh. Phần cẳng tay/bracer và lòng bàn tay tiếp tục là các mảnh cứng độc lập; độ dài xương, nhịp ra đòn, cổ tay, chuôi vũ khí và điểm phát kỹ năng kế thừa 0.33.

Mesh áo được cắt theo lưới tam giác 0,8 đơn vị native. Mỗi tam giác nguồn nằm trong một ô biến dạng affine, thay cho uốn trực tiếp các tam giác dài/mỏng dễ lật. UV và mọi landmark tư thế đứng giữ đúng nguồn. Đường viền cũng cắt tại các biên ô đó và theo cùng biến dạng; bridge khuỷu bám mép áo đã uốn, chỉ lấp phía mở. Phần áo bổ sung bắt đầu dưới vai 0,65 đơn vị, giảm chỗ hở do điểm bắt đầu cũ nằm cách vai 0,8 đơn vị.

Binding mesh và các đoạn contour được cache theo view; mỗi pose chỉ xoay các đỉnh lưới dùng chung, sau đó nội suy đỉnh vải. Bỏ lượt dựng outline đầy đủ không được sử dụng trước lượt outline theo ownership. Đây là giảm công việc trong renderer, chưa phải kết quả benchmark FPS.

Regression giữ kiểm tra chiều dài xương, mesh bracer/palm cứng, coverage UV, winding và grip. Hợp đồng isometry cũ cho toàn bộ áo được thay riêng ở vùng vải bằng strain có giới hạn; không bỏ kiểm tra tam giác lật. Tỷ lệ cạnh chỉ thống kê từ 0,01 đơn vị native; mọi cạnh nhỏ hơn vẫn kiểm giới hạn với sai số tuyệt đối 0,00002 và mọi tam giác vẫn kiểm winding nghiêm ngặt.

Fixture lướt qua input thật dùng điểm đến từ navigation preview, vì camera nội suy có thể đặt con trỏ qua vật cản; kỳ vọng cũ luôn đi thẳng ba ô. Fixture đóng túi chờ thêm một process tick cho callback tween nối tiếp. Không sửa luật lướt, vật cản hoặc giao dịch túi.

## Bằng chứng

**600/600 kiểm thử Linux/Godot 4.7.2, 0 failure; log cuối không có runtime/script error.** Kiểm 11.616 pose tay trong 11 action × 33 pha × 32 arm/view: coverage UV và neutral vertex đạt, không tam giác lật; bracer/palm cứng và grip khớp. Cạnh vải trong khoảng 0,63153–1,35698 lần cạnh nguồn, dịch chuyển khỏi phép quay cứng tối đa 0,76612 đơn vị native. Đây là giới hạn biến dạng 2D, không phải đo vật lý vải.

Chụp lại 752 framebuffer chu kỳ: 144 combat, 352 action, 256 motion/turn/gameplay/vertical; thêm 21 overlay khớp, 22 still, 8 ảnh chi tiết và 11 sheet S/N. UI có 11 trạng thái tại ba viewport, 16 probe GPU đạt. Các ảnh do renderer cuối cùng tạo sau sửa cache; không dùng ảnh thử để chứng nhận bản cuối.

Chrome Windows giải mã 165 ảnh combat/overlay và 352 ảnh action; controls, scrub/play, keyboard, body/direction và responsive đạt, 0 page error. Bảy clip đối chiếu đủ 400 frame RGB với PNG native, 0 mismatch. Hai trang inspector được server local trả HTTP 200.

Kết quả cuối được ghi tại [regression](../../artifacts/concept34_tests.log), [vải tay áo](../../artifacts/concept34_sleeve_deformation.json), [combat](../../artifacts/concept34_combat_constraints.json), [lòng bàn tay](../../artifacts/concept34_palm_constraints.json), [tay đỡ](../../artifacts/concept34_support_arm.json), [stance rig](../../artifacts/concept34_geometry_review.json) và [stance world](../../artifacts/concept34_actor_stance.json).

[Inspector so 0.33 → 0.34](../../artifacts/concept34_combat_review.html) có kiếm/thương/tay không, 48 pha, nam/nữ × tám hướng và overlay khớp. [Inspector 11 action](../../artifacts/concept34_frame_review.html) có 352 framebuffer và các sheet S/N. [Ảnh chi tiết](../../artifacts/concept34_detail_attack_03.png) render native ở display height 192, không phóng PNG.

[Clip kiếm](../../artifacts/concept34_combat_sword.webp) · [thương](../../artifacts/concept34_combat_spear.webp) · [tay không](../../artifacts/concept34_combat_unarmed.webp) · [đi/chạy lên xuống](../../artifacts/concept34_vertical.webp). Các clip dùng nguyên framebuffer, kiểm RGB lossless tại [combat](../../artifacts/concept34_combat_clip_validation.json) và [motion](../../artifacts/concept34_clip_validation.json).

[Native smoke](../../artifacts/concept34_native.log), [pigment biên](../../artifacts/concept34_edge_filter.json), [lõi ink](../../artifacts/concept34_ink_core.json) và [UI smoke](../../artifacts/concept34_ui.log) kiểm cùng renderer world/F3/F6. [Studio native](../../artifacts/concept34_ui/studio_1280.png). [Browser combat](../../artifacts/concept34_combat_review_browser.json) và [browser action](../../artifacts/concept34_frame_review_browser.json) kiểm ảnh, controls, keyboard và responsive.

PNG SHA-256 giữ nguyên: original `20432dfcdff4b38f93c5ddd55649e6c5de0d68c56bee2d963d16a2747d80d7ce`; directions `29dfab20fc6eda61bcca24f09f255e515a1d34711b602d019f67561f712ef6e7`.

## Giới hạn

Uốn vải giúp giảm cảm giác cutout cứng; đây chưa phải mô phỏng vải hoặc bộ drawing action mới. Các nếp đứng trong PNG, vùng áo bị che được bổ sung bằng vector, kiểu nắm và foreshortening mạnh vẫn cần art review. Góc guard và cuff landmark kế thừa 0.33. Không xác nhận toàn bộ animation đủ chất lượng phát hành.

Native capture chạy Godot Linux/X11/Mesa llvmpipe; inspector kiểm Chrome Windows. Chưa kiểm engine Windows hoặc benchmark FPS trong pass này.

## Chạy lại

```bash
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_combat_review.gd -- --test-mode --capture-prefix=concept34 --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_action_frame_review.gd -- --test-mode --capture-prefix=concept34 --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_character_visual_smoke.gd -- --test-mode --capture-prefix=concept34 --capture-offscreen
python tools/build_concept_combat_review.py concept34
python tools/build_concept_frame_review.py concept34
python tools/render_concept_combat_preview.py concept34
node tools/verify_concept_combat_review.cjs concept34
node tools/verify_concept_frame_review.cjs concept34
```
