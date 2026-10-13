# Nhân vật 0.35 — thân, tay áo và vạt áo theo từng hướng

Ngày: 12/10/2026. Revision: `concept-native-body-panels-35`. Sửa mảng tay áo vẫn nằm trên thân khi tay đã chuyển động, các chỗ hở sau khi tách, và vạt áo phản ứng sai bên chân. Giữ hai PNG concept đã duyệt, hai giới tính, tám hướng, trang bị và rig hiện hành.

## Thay đổi trong game

Mỗi hình nam/nữ có đường may riêng từ vai tới cuff. Pipeline ownership chuyển phần màu phía tay áo sang đúng arm layer, cắt trong polygon thực sự được mesh của tay vẽ và giữ head priority. Không để phần màu đó ở cả thân lẫn tay. Kiểm tra so với fixture ownership 0.34: **12.529 pixel nguồn chuyển sang tay áo, 0 pixel của vùng đã tách còn trên thân, 0 pixel bị mất**. Fixture nằm trong `tests/fixtures/concept34_owners/`, độc lập với thư mục capture.

Thân có phần ngực nằm dưới tay áo. Biên phần này theo đường may của chính hướng vẽ, được cắt tiếp theo torso polygon và opacity của hình nguồn. Màu vùng bị che lấy từ màu vải xanh của cùng view; collar, skin, belt và mực tay áo không dùng làm chi tiết ngực mới. Phần bổ sung ở dưới lớp màu nguồn và không giữ nguyên silhouette tay áo đứng. Viền cắt bên trong giữa torso/sleeve được bỏ khỏi lượt vẽ mực; viền ngoài và landmark còn giữ đúng nguồn.

Hai bên vạt áo dùng vị trí hip nguồn để xác định trọng số L/R. Góc sau lưng đảo bên trên màn hình; góc nghiêng có khoảng cách hip khác hình chính diện. Mỗi bên nhận lift và một phần stride của chân tương ứng, giới hạn dịch ngang riêng ở ±1,4 đơn vị native; collar/belt vẫn neo vào thân. Mesh và viền cùng dùng biến dạng này.

Phần ngực bổ sung dùng một indexed mesh, được cache topology/pigment theo view. Cùng sáu source part, renderer hiện có bảy mesh trong tư thế đứng; native smoke kiểm số này theo manifest thay cho kỳ vọng cố định sáu mesh của phiên bản cũ. Chưa benchmark FPS.

## Kiểm chứng

**605/605 kiểm thử Linux/Godot 4.7.2 đạt, không lỗi runtime/script trong log cuối.** [Regression](../../artifacts/concept35_tests.log), [tách thân và vạt áo](../../artifacts/concept35_body_panels.json).

Kiểm mesh ngực và neo collar/belt ở 5.808 pose: hai body × tám hướng × 11 action × 33 pha. Kiểm độc lập lift L/R ở từng view; mesh không lật, neutral giữ tọa độ nguồn. Bộ kiểm tay tiếp tục bao phủ 11.616 pose, UV coverage, winding, strain vải và bracer/palm cứng: [vải tay áo](../../artifacts/concept35_sleeve_deformation.json).

Grip, xương và gameplay kế thừa hợp đồng hiện hành: [combat](../../artifacts/concept35_combat_constraints.json), [palm](../../artifacts/concept35_palm_constraints.json), [tay đỡ](../../artifacts/concept35_support_arm.json), [stance rig](../../artifacts/concept35_geometry_review.json), [stance world](../../artifacts/concept35_actor_stance.json).

[Inspector so 0.34 → 0.35](../../artifacts/concept35_combat_review.html) có ba vũ khí × 48 pha × 16 view và 21 overlay khớp. [Inspector 11 action](../../artifacts/concept35_frame_review.html) có 352 framebuffer và 11 bảng pha trước/sau. [Chi tiết tấn công](../../artifacts/concept35_detail_attack_03.png) render native ở display height 192; [chạy tám hướng](../../artifacts/concept35_actions/run/frame008.png), [phòng thủ](../../artifacts/concept35_actions/defend/frame010.png).

Chụp đủ **752 framebuffer chu kỳ**: 144 combat, 352 action và 256 motion/turn/gameplay/vertical; thêm 21 overlay, 22 still, 40 ảnh chi tiết và 11 bảng pha S/N. [Native smoke](../../artifacts/concept35_native.log), [viền/pigment](../../artifacts/concept35_edge_filter.json), [lõi ink](../../artifacts/concept35_ink_core.json). UI có 11 trạng thái ở 1280×800, 1280×720 và 960×640: [UI log](../../artifacts/concept35_ui.log), [studio native](../../artifacts/concept35_ui/studio_1280.png).

Chrome Windows giải mã 165 PNG combat/overlay và 352 PNG action; lựa chọn body/hướng/vũ khí, scrub/play, keyboard và responsive đều đạt, 0 page error: [combat browser](../../artifacts/concept35_combat_review_browser.json), [action browser](../../artifacts/concept35_frame_review_browser.json). Hai trang local trả HTTP 200.

Bảy clip giữ nguyên toàn bộ framebuffer; đối chiếu đủ **400 frame RGB, 0 mismatch**: [combat](../../artifacts/concept35_combat_clip_validation.json), [motion](../../artifacts/concept35_clip_validation.json). [Kiếm](../../artifacts/concept35_combat_sword.webp) · [thương](../../artifacts/concept35_combat_spear.webp) · [tay không](../../artifacts/concept35_combat_unarmed.webp) · [đi/chạy](../../artifacts/concept35_motion.webp) · [đổi hướng](../../artifacts/concept35_turn.webp) · [gameplay](../../artifacts/concept35_gameplay.webp) · [lên/xuống](../../artifacts/concept35_vertical.webp).

PNG SHA-256 giữ nguyên: original `20432dfcdff4b38f93c5ddd55649e6c5de0d68c56bee2d963d16a2747d80d7ce`; directions `29dfab20fc6eda61bcca24f09f255e515a1d34711b602d019f67561f712ef6e7`.

## Giới hạn

Đường may, ownership và vạt áo được sửa bằng renderer/rig. Phần ngực bị che là màu vải bổ sung theo biên nguồn, chưa có drawing nếp gập mới theo từng hành động. Foreshortening mạnh, nếp gấp sâu, vùng tay bị che và kiểu nắm vẫn cần art review; kiểm hình học không thay cho nghiệm thu độ tự nhiên của toàn bộ animation. Chưa xác nhận toàn bộ mỹ thuật đạt chất lượng phát hành.

Native capture dùng Linux/X11/Mesa llvmpipe. Chưa kiểm lại engine Windows hoặc benchmark FPS trong lượt này.

## Chạy lại

```bash
python3 tools/author_concept_character_masks.py
bash tools/run.sh --headless --script res://tools/build_concept_mattes.gd
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_combat_review.gd -- --test-mode --capture-prefix=concept35 --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_action_frame_review.gd -- --test-mode --capture-prefix=concept35 --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_character_visual_smoke.gd -- --test-mode --capture-prefix=concept35 --capture-offscreen
python3 tools/build_concept_combat_review.py concept35
python3 tools/build_concept_frame_review.py concept35
```
