# Tay đỡ và đường nối áo — 0.33

Ngày: 12/10/2026. Tiếp nối [0.32](concept-character-palm-0.32.md). Revision: `concept-native-cloth-counterbalance-33`.

Tay đỡ trước đây giữ gần như cùng một tư thế ngang bên hông trong nhát chém. Nay tay này theo đà kiếm: ở góc ngang nó lùi sau đường ra đòn, ở góc trước/sau nó mở nhẹ khỏi hông. Tư thế lấy đà giảm độ co để tránh nhấc mép tay áo thành góc nhọn. Khi đấm, tay còn lại giữ gần ngực thay vì dùng động tác đỡ của kiếm.

Tay đỡ có nhịp riêng: tới key contact ở pha 0,38, bắt đầu thu ở 0,62; tay kiếm vẫn dùng 0,34/0,56. Cổ tay đỡ xoay quanh cuff, giới hạn 0,22 rad, góc thực lớn nhất khoảng 10,3°. Điểm nắm và mesh palm dùng cùng phép gắn sau blend/turn; không thay đổi tỷ lệ xương. Curve Hermite giữ vận tốc liên tục ở các mốc và hai endpoint trả về drawing trung tính. Duration và contact gameplay kế thừa 0.32.

Phần nối khuỷu chỉ vẽ ở phía hai mảnh áo mở ra. Phía đang chồng lên nhau không thêm sector hoặc viền cap. Đường cong nối thu nhẹ về khuỷu, hai đầu trùng mép cutout nguồn, không rộng hơn source cut. Màu upper sleeve/bridge lấy mẫu pigment có đúng owner ở tay áo, loại mực tối, cuff ngà và da; phần nguồn bị che hoàn toàn dùng wash dự phòng `696e58`. Cache theo view, không thay đổi màu theo từng frame.

Các wedge rất nhỏ ở ảnh dư lướt được vẽ bằng triangle fan trực tiếp. Tránh lỗi triangulation khi tọa độ world làm cạnh subpixel mất độ chính xác; không bỏ toàn bộ tay áo hoặc thêm disk ở khuỷu. Viền vẫn dùng `GuConceptInkStroke` cùng renderer world/F3/F6.

## Kiểm chứng bản cuối

**598/598 Linux/Godot 4.7.2, 0 failure; không có runtime/script error trong log cuối.** [Regression](../../artifacts/concept33_tests.log).

| Phạm vi | Bằng chứng |
|---|---|
| Khớp tay và vũ khí | [4.656 native pose + 976 smooth playback pose](../../artifacts/concept33_combat_constraints.json): elbow ≈135° tối đa; bước tay cầm 2,3655, tay đỡ 1,8627 native unit / 1⁄96 chu kỳ; bước blade 15,228°; lệch grip thương tối đa 0,00000728 native unit. |
| Palm và nhịp tay đỡ | [1.552 pose / 16 view](../../artifacts/concept33_support_arm.json): mesh palm thực theo cuff roll, counterbalance góc ngang, neutral endpoints và đạo hàm tại các mốc đạt. [784 pose palm tay kiếm](../../artifacts/concept33_palm_constraints.json) giữ attachment 0.32. |
| Nối khuỷu | 7.717 bridge được kiểm tra: chỉ sector mở, polygon hợp lệ, hai đầu trùng source cut và radius nằm trong source width. Source UV, winding và cạnh các mảnh rigid vẫn qua regression. |
| Combat | [Inspector 0.32 → 0.33](../../artifacts/concept33_combat_review.html): 144 PNG, 21 overlay khớp; 2 body × 8 hướng × 3 vũ khí. Readout có cả góc cổ tay cầm và tay đỡ. [Chi tiết native](../../artifacts/concept33_detail_attack_03.png): 8 pha render trực tiếp ở display height 192. |
| Các action khác | [11 action / 352 framebuffer](../../artifacts/concept33_frame_review.html) cùng 11 sheet S/N. [Geometry](../../artifacts/concept33_geometry_review.json): 5.808 pose và 1.328 stance pairs; [ActorView](../../artifacts/concept33_actor_stance.json): 7.780 pairs, world drift tối đa 0,00116 pixel. |
| Gameplay và viền | [Native smoke](../../artifacts/concept33_native.log): 256 frame bước/đổi hướng/input thật, 22 still. [4 probe pigment](../../artifacts/concept33_edge_filter.json) và [12 probe ink](../../artifacts/concept33_ink_core.json) đạt trên nền sáng/tối. |
| Nhân vật trong UI | [11 trạng thái / 3 viewport](../../artifacts/concept33_ui.log), lưu PNG riêng tại `artifacts/concept33_ui/`. [F6](../../artifacts/concept33_ui/studio_1280.png) dùng cùng renderer nhân vật. |
| Inspector và clip | Chrome Windows giải mã [165 ảnh combat](../../artifacts/concept33_combat_review_browser.json) và [352 ảnh action](../../artifacts/concept33_frame_review_browser.json); controls, keyboard, scrub/play và responsive đạt, 0 page error. [144 frame combat](../../artifacts/concept33_combat_clip_validation.json) + [256 frame motion](../../artifacts/concept33_clip_validation.json) được đối chiếu RGB lossless từ nguyên framebuffer. |

[Clip kiếm](../../artifacts/concept33_combat_sword.webp) · [thương](../../artifacts/concept33_combat_spear.webp) · [tay không](../../artifacts/concept33_combat_unarmed.webp) · [bước lên/xuống](../../artifacts/concept33_vertical.webp).

PNG concept giữ nguyên SHA-256: original `20432dfcdff4b38f93c5ddd55649e6c5de0d68c56bee2d963d16a2747d80d7ce`; directions `29dfab20fc6eda61bcca24f09f255e515a1d34711b602d019f67561f712ef6e7`. Không sửa bitmap hoặc nội suy ảnh để tạo tư thế.

## Giới hạn và lượt tiếp theo

Kết quả khớp/attachment có evidence code + runtime, độ tin cậy cao. Nhận xét tay đỡ bớt cứng dựa trên ảnh native và nhịp pose, chưa thay cho nghiệm thu mỹ thuật. Nếp áo bên trong và kiểu nắm vẫn dùng drawing tư thế đứng; bridge sửa silhouette/gap, chưa tạo biến thể nếp gập hoặc foreshortening theo action. Cuff là landmark suy ra, không phải landmark họa sĩ đặt riêng. Giới hạn guard kế thừa 0.32.

Ưu tiên tiếp: nếp áo gập ở W/N, hình tay/vũ khí hướng N/S và drawing kiểu nắm theo hành động, đối chiếu với concept gốc. Chưa xác nhận chất lượng mỹ thuật phát hành. Runtime/capture chạy Linux X11/Mesa llvmpipe; Chrome chạy Windows cho inspector, chưa chạy lại engine Windows. Capture không phải benchmark FPS.

## Chạy lại

```bash
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_combat_review.gd -- --test-mode --capture-prefix=concept33 --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_action_frame_review.gd -- --test-mode --capture-prefix=concept33 --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_character_visual_smoke.gd -- --test-mode --capture-prefix=concept33 --capture-offscreen
python tools/build_concept_combat_review.py concept33
python tools/build_concept_frame_review.py concept33
python tools/render_concept_combat_preview.py concept33
node tools/verify_concept_combat_review.cjs concept33
node tools/verify_concept_frame_review.cjs concept33
```
