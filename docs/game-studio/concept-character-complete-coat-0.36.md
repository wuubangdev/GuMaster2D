# Nhân vật 0.36 — khép thân dưới tay và duỗi tay cầm kiếm

Ngày: 12/10/2026. Revision: `concept-complete-coat-contact-36`.

Ảnh người dùng gửi ở pha kiếm 0,34 cho thấy thân nam hướng E bị một vùng rỗng viền đen, còn tay cầm vũ khí gập ở thời điểm chạm đòn. Phần thân bổ sung 0.35 chỉ che vai/ngực trên, trong khi tay áo và bàn tay đứng vốn che tới đai/vạt áo. Viền của ownership torso tiếp tục bao quanh vùng tay đã tách, tạo cảm giác còn một tay áo đứng trên thân.

## Thay đổi

Hoàn thiện áo dưới tay trong silhouette riêng của cả 16 view. Viền thân lấy từ silhouette hoàn chỉnh, không vẽ lại các đường cắt nội bộ của tay đứng. Phần đai bị bàn tay che được tiếp nối bằng màu da lấy từ đai nguồn; khóa, nút, cổ và màu vải gốc vẫn ở lớp PNG phía trên. Topology và palette được cache theo view, dùng chung cho world, F6 và các chân dung động.

Mở tay cầm ở pha chạm đòn ngang: khuỷu giảm từ 38,1–38,3° xuống tối đa 13,5° ở hai body và hai hướng W/E. Giữ chiều dài xương, điểm vai, palm/cổ tay, chuôi kiếm và nhịp lấy đà/theo đà hiện hành.

Lớp áo dùng lattice tam giác, có thêm đường chia tại hip L/R. Mesh và viền cùng nội suy theo lattice đó, tránh đảo các tam giác mảnh ở vạt khi phối hợp stride/lift. Mỗi pose tính các hệ số vạt một lần cho mesh. Biên phần áo bổ sung chồng thêm 0,65 pixel nguồn, tương đương khoảng 0,13 đơn vị native, rồi cắt trong polygon torso: bù khe nhỏ do giảm điểm/làm tròn contour, giữ biên áo đã định.

## Kiểm chứng

**607/607 Linux/Godot 4.7.2 đạt, 0 failure; log cuối không có lỗi script/runtime.** [Regression](../../artifacts/concept36_tests.log), [kết quả lưu riêng](../../artifacts/concept36_test_results.json).

[Kiểm thân](../../artifacts/concept36_body_panels.json): 10.791 pixel nội bộ bị tay áo/bàn tay đứng che được phủ đủ, 0 khe còn hở; 5.808 pose phần thân giữ neutral/winding và neo cổ/đai. Ownership vẫn giữ 12.529 pixel đã chuyển sang tay áo ở 0.35, không mất pixel nguồn; hai resource ownership giống baseline từng byte.

[Kiểm combat](../../artifacts/concept36_combat_constraints.json): 4.656 pose và 976 smooth pose, profile contact tối đa 13,4975°, xương/grip/continuity/thương hai tay đạt. [Tay áo](../../artifacts/concept36_sleeve_deformation.json): 11.616 pose, không đảo tam giác, UV nguồn và palm/bracer giữ form. [Stance trong game](../../artifacts/concept36_actor_stance.json) giữ mức drift hiện hành.

[So 0.35 → 0.36](../../artifacts/concept36_combat_review.html): 144 framebuffer ba vũ khí, 21 overlay khớp; mở mặc định nam E, frame 16, tương ứng pha 0,3404 của [ảnh báo lỗi](../../artifacts/concept36_reported_issue.png). [11 action](../../artifacts/concept36_frame_review.html): 352 frame và 11 bảng pha S/N. [Chi tiết contact đúng pha 0,34](../../artifacts/concept36_detail_attack_03.png); [lấy đà 0,16](../../artifacts/concept36_detail_attack_01.png). Ảnh chi tiết attack lấy các pha 0 / 0,16 / 0,25 / 0,34 / 0,44 / 0,56 / 0,75 / 1, thay vì bỏ qua contact.

Đã render lại đủ **752 framebuffer chu kỳ**, 22 still, 40 chi tiết, 21 overlay và 11 bảng pha: [native](../../artifacts/concept36_native.log), [combat](../../artifacts/concept36_combat_capture.log), [action](../../artifacts/concept36_action_capture.log). 16 GPU probe viền/pigment/ink đạt. [UI](../../artifacts/concept36_ui.log) chụp 11 trạng thái ở ba viewport; [F6](../../artifacts/concept36_ui/studio_1280.png).

Chrome Windows kiểm body/hướng/vũ khí, scrub/play, keyboard, responsive và giải mã toàn bộ PNG: [165 combat/overlay](../../artifacts/concept36_combat_review_browser.json), [352 action](../../artifacts/concept36_frame_review_browser.json), 0 page error. Hai inspector local trả HTTP 200.

Bảy clip giữ nguyên toàn bộ framebuffer và được đối chiếu đủ **400 frame RGB, 0 mismatch**: [144 combat](../../artifacts/concept36_combat_clip_validation.json), [256 motion/turn/gameplay/vertical](../../artifacts/concept36_clip_validation.json). [Kiếm](../../artifacts/concept36_combat_sword.webp), [đi/chạy](../../artifacts/concept36_motion.webp), [lên/xuống](../../artifacts/concept36_vertical.webp).

SHA-256 PNG nguồn: original `20432dfcdff4b38f93c5ddd55649e6c5de0d68c56bee2d963d16a2747d80d7ce`; directions `29dfab20fc6eda61bcca24f09f255e515a1d34711b602d019f67561f712ef6e7`. Hai lỗi phát hiện trong lượt đầu (winding và 26 khe contour) được sửa trước toàn bộ lượt kiểm/capture cuối; log thử nghiệm không dùng làm bằng chứng đạt.

## Giới hạn

Các vùng trước đây bị tay che được bổ sung bằng màu vải/đai cùng concept. Nếp gập sâu, phần tay khuất và kiểu nắm chưa có drawing riêng cho từng hành động; chưa nghiệm thu toàn bộ animation đạt mỹ thuật phát hành. PNG concept nguồn giữ nguyên. Engine kiểm bằng Linux/X11/Mesa llvmpipe; chưa benchmark FPS hoặc kiểm lại engine Windows.

## Chạy lại

```bash
python3 tools/author_concept_character_masks.py
bash tools/run.sh --headless --script res://tools/build_concept_mattes.gd
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_combat_review.gd -- --test-mode --capture-prefix=concept36 --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_action_frame_review.gd -- --test-mode --capture-prefix=concept36 --capture-offscreen
python3 tools/build_concept_combat_review.py concept36
python3 tools/build_concept_frame_review.py concept36
```
