# Nhân vật 0.37 — asset thân sạch và tay áo theo từng góc

Ngày: 12/10/2026. Revision: `concept-modular-cloth-37`.

## Lỗi và cách sửa

Ảnh thân đứng chứa một phần tay áo, bàn tay và vùng giáp chân. Rig ghép thêm chi tiết chuyển động, nhưng pigment ngoài polygon tay cũ vẫn nằm trên thân. Bản 0.36 chỉ bổ sung vải bên dưới: điều đó không loại được nét tay đứng còn trong lớp PNG.

Bản này tách ownership theo đường ráp áo của từng view, không cắt đường ráp bằng polygon tay cũ. Mép ngoài vùng áo được giới hạn theo hình tay thực tế để tránh lấy nhầm tóc đuôi và nét tai ở góc nghiêng. Lớp torso chỉ giữ pigment trong silhouette thân sạch. Mesh tay lấy các contour thực sự có pigment, không kéo theo một vùng UV trống lớn.

Có **112 SVG riêng**: 16 thân áo; 32 tay áo khuất; 32 lớp nếp co và 32 lớp nếp duỗi. Mỗi view có tọa độ, pivot, UV và biên riêng. Một SVG atlas tổng hợp phục vụ shader; các SVG gốc vẫn chỉnh riêng được. Mesh thân có đầy đủ bề mặt, không dùng alpha của ảnh đứng để định hình thân. Cổ áo, đai, khóa, ngọc bội và màu vạt hiện có tiếp tục nằm trên lớp PNG đã cô lập; mặt và tóc giữ nguồn concept đã duyệt.

Tay áo có năm điểm điều khiển: vai, ba điểm giữa cánh tay trên và khuỷu. Các điểm giữa tạo độ cong nhỏ theo độ gập, không thay chiều dài xương giải phẫu. Cẳng tay và lòng bàn tay tiếp tục là hai vùng cứng riêng, với cổ tay và điểm nắm riêng. Nếp co/duỗi được phối liên tục theo góc khuỷu, không đổi asset đột ngột. Viền, mesh và nối khuỷu dùng cùng biến dạng; nối khuỷu đi qua đúng hai mép vải đã biến dạng.

Xương vai–khuỷu và hip–gối–cổ chân giữ nguyên tỷ lệ nguồn và constraint hiện hành. Thêm khớp giải phẫu giả giữa cẳng tay sẽ làm bracer gãy; vì vậy các khớp mới chỉ điều khiển vải. Vạt vẫn theo từng chân, cổ/đai giữ neo trên thân. World, F6, chân dung động và afterimage dùng chung renderer; gameplay/save/input giữ hợp đồng hiện hành.

## Phạm vi asset hiện hành

| Chi tiết | Nam/nữ × 8 hướng | Theo hành động |
|---|---|---|
| Thân sạch | 16 SVG và lớp chi tiết nguồn cô lập | Mesh vạt theo chân; ngực/cổ/đai neo theo thân |
| Tay áo khuất | 32 SVG base | 64 lớp nếp co/duỗi phối theo khớp cho 11 action |
| Tay áo nhìn thấy | Pigment nguồn tách toàn bộ đường ráp | Lattice mềm và năm điểm điều khiển |
| Cẳng tay / bàn tay | 32 + 32 vùng UV riêng | Cẳng tay cứng; palm xoay ở wrist, weapon/VFX theo grip |
| Quần / giày | Quần theo gối; 32 vùng UV boot | Giày giữ form, contact/toe roll hiện hành |
| Đầu / tóc | 16 vùng UV concept gốc | Head/neck và trang bị theo renderer chung |

Đây là asset modular và animation bằng rig, chưa phải toàn bộ bộ tranh vẽ lại từng frame. Ngón tay cho từng kiểu nắm, foreshortening mạnh và nếp áo cho từng đòn vẫn cần artwork chuyên biệt để nghiệm thu mỹ thuật phát hành.

## Kế hoạch mở rộng

1. **Đã triển khai:** cô lập thân/tay/chân; vẽ bổ sung vải bị che theo 16 view; gắn guide vải; kiểm mesh, ownership, grip và capture trong renderer thật.
2. Vẽ palm cho kiếm/thương/tay không và forearm/cuff cho tư thế co mạnh; dùng cùng pivot cổ tay và điểm nắm, không sửa gameplay khi đổi drawing.
3. Bổ sung chest/shoulder/skirt pose riêng cho phòng thủ, lấy đà và đòn xoay lớn khi biến dạng vượt envelope vải. Blend qua mốc pose; giữ lớp trước/sau theo hướng.
4. Tách từng bộ trang phục, giày, nón và vũ khí vào catalog cùng schema. Dye hiện hành đã dùng được; thay hình trang phục mới cần asset/atlas của bộ đó, không chỉ đổi màu.

## Kiểm chứng

**613/613 Linux/Godot 4.7.2 đạt, 0 failure, log cuối không có script/runtime error.** [Regression](../../artifacts/concept37_tests.log), [kết quả lưu riêng](../../artifacts/concept37_test_results.json).

[Kiểm modular](../../artifacts/concept37_modular_parts.json): 2.194 pixel tay áo từng nằm ngoài mask tay cũ được chuyển khỏi thân sang lớp tay; 0 pigment mất trong vùng kiểm. Cả 16 silhouette thân không có owner torso trong đường ráp tay hoặc ngoài thân. 112 SVG tải được, 2.992 pose asset mới giữ neutral/winding và neo vai/khuỷu; độ cong giữa tay tối đa 0,12 native.

[Thân](../../artifacts/concept37_body_panels.json): 5.808 pose, diện tích mesh tổng 6.348,60 native² phủ silhouette hoàn chỉnh; 11.260 pixel nội bộ thiếu lớp torso có bề mặt áo bên dưới, 0 khe interior. [Vải tay](../../artifacts/concept37_sleeve_deformation.json): 11.616 pose, cạnh vải 0,71691–1,25662 lần nguồn, không lật tam giác; palm/bracer cứng và UV neutral giữ đăng ký. [Combat](../../artifacts/concept37_combat_constraints.json): 4.656 pose + 976 smooth pose; contact W/E tối đa 13,5°, grip/weapon/stance giữ contract.

Ảnh [thân riêng](../../artifacts/concept37_body_only.png), [vải vector riêng](../../artifacts/concept37_vector_cloth.png) và [các lớp lắp ráp](../../artifacts/concept37_parts_exploded.png) được Godot render. [16 GPU probe cloth](../../artifacts/concept37_cloth_gpu.json) xác nhận shader lấy đúng pigment SVG. 16 probe nguồn/viền hiện hành cũng đạt; lỗi sampler trắng, contour mảnh, mép nối khuỷu và strain quá mức phát hiện ở lượt thử đã được sửa trước lượt capture cuối.

Đã render lại **752 framebuffer chu kỳ**: 144 combat, 352 action, 48 walk/run, 48 turn, 64 gameplay và 96 lên/xuống; thêm 22 still, 40 chi tiết, 21 overlay và 11 phase sheet. [Danh sách capture](../../artifacts/concept37_native_delivery.json), [native renderer/input](../../artifacts/concept37_native_capture.log). [So 0.36 → 0.37](../../artifacts/concept37_combat_review.html) và [11 action](../../artifacts/concept37_frame_review.html) giữ crop pixel 1:1. Chrome Windows kiểm 165 combat/overlay và 352 action, body/hướng/vũ khí, scrub/play/keyboard/responsive, 0 page error: [combat browser](../../artifacts/concept37_combat_review_browser.json), [action browser](../../artifacts/concept37_frame_review_browser.json).

Bảy clip dùng nguyên framebuffer lossless, **400 frame RGB được đối chiếu, 0 mismatch**: [combat](../../artifacts/concept37_combat_clip_validation.json), [motion/turn/gameplay/vertical](../../artifacts/concept37_clip_validation.json). [Kiếm](../../artifacts/concept37_combat_sword.webp), [đi/chạy](../../artifacts/concept37_motion.webp), [lên/xuống](../../artifacts/concept37_vertical.webp). [UI](../../artifacts/concept37_ui_capture.log) chụp 11 trạng thái ở ba viewport, [F6](../../artifacts/concept37_ui/studio_1280.png). Engine kiểm bằng Linux/X11/Mesa llvmpipe; chưa benchmark FPS hoặc kiểm engine Windows.

SHA-256 PNG source giữ nguyên: original `20432dfcdff4b38f93c5ddd55649e6c5de0d68c56bee2d963d16a2747d80d7ce`; directions `29dfab20fc6eda61bcca24f09f255e515a1d34711b602d019f67561f712ef6e7`. Mỹ thuật từng kiểu nắm/nếp sâu vẫn là partial; không suy ra chất lượng phát hành từ số test.

Các log thử nghiệm có hậu tố `before_*` hoặc `parse_attempt` không dùng để nghiệm thu.

## Tái tạo và rollback

```bash
python3 tools/author_concept_character_masks.py
bash tools/run.sh --headless --editor --import
bash tools/run.sh --headless --script res://tools/build_concept_mattes.gd
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_modular_parts_review.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_combat_review.gd -- --test-mode --capture-prefix=concept37 --capture-offscreen
```

Authoring nằm trong `tools/author_concept_modular_parts.py`; không chỉnh PNG gốc. Mọi tọa độ atlas được tạo cùng manifest, không chỉnh atlas UV thủ công. Snapshot 0.36 ở `artifacts/concept37_baseline`; rollback cần phục hồi Art/Rig/shader/author/matte builder/manifest/contours/ownership cùng nhau và import lại. Không thay một resource đơn lẻ vì mesh và ownership phải cùng revision. Fixture ownership 0.34/0.36 trong tests giữ nguyên để phát hiện nét tay bị giữ trên thân.
