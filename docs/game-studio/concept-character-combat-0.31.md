# Tay, khung xương và vũ khí — 0.31

Ra đòn trước đây lấy góc cánh tay từ rig có tỷ lệ khác, trong khi kiếm quay theo một track độc lập. Tay có thể đi qua vai, khuỷu gập ngược khi blend và góc kiếm giật ở điểm ±180°. Bản này dùng pose key được giải theo chiều dài xương của từng drawing, nội suy vai và góc khuỷu trong hệ cha–con, rồi gắn vũ khí vào cẳng tay với góc cổ tay cục bộ.

PNG concept 01 / bảng hướng 02 giữ nguyên SHA-256. Cùng renderer được dùng trong world, F6, diện mạo thay thế của F3 và VFX. Không đổi input, hitbox, mana, damage, thời gian skill của authority hoặc save.

## Hành vi và giới hạn rig

| Phần | Thay đổi |
|---|---|
| Kiếm | Pose native: lấy đà 0–0,16; giữ 0,16–0,18; chém 0,18–0,34; contact 0,34–0,36; theo đà 0,36–0,52; giữ 0,52–0,58; thu tay đến 1. Góc cổ tay load trung tính, contact/follow có key riêng, giới hạn ±0,85 rad. |
| Khuỷu | Key IK giới hạn gập 135° và giữ một phía pole trong gesture. Nội suy upper-arm + flex cục bộ, không lerp hai góc world độc lập thành khuỷu đảo ngược. Chiều dài source và root vai giữ nguyên. |
| Chuyển tiếp | Native blend dùng góc khuỷu cục bộ. Spring tác động góc cổ tay thay cho góc vũ khí world; sau retarget/blend/spring, attachment được tính lại từ cẳng tay đang hiển thị. Zero-time event tiếp tục giữ nguyên toàn bộ pose/tip. |
| Thương | Hai tay trên cùng cán, cách nhau 5,5 native unit ở pha nắm đủ. Tìm grip chung nằm trong reach envelope của cả hai tay trước khi giải IK. Đầu/cuối chu kỳ trở lại góc cầm đứng, không nhảy ngay sang góc đâm. |
| Tay không | Co tay cân bằng và đưa nắm đấm ra hướng đánh bằng key riêng, tránh đường nội suy cổ tay xuyên qua vai/đầu. |
| Các gesture khác | Giới hạn flex cho cast/dash/hit/death/respawn được retarget từ legacy. Guard/channel giữ pose chuyên biệt. Giới hạn 135° của attack không phải tuyên bố áp dụng cùng một envelope cho mọi tư thế guard/channel. |
| Drawing khi giơ tay | Phần upper sleeve vốn bị coat che ở drawing đứng được bổ sung bằng contour vector thuôn, có wash tối/sáng, dưới pixel áo gốc. Không thêm tube forearm hoặc cap ở bàn tay. |
| Che khuất | Hướng sau lưng chia upper-arm trước coat, forearm sau coat trước head cho locomotion/combat/cast/guard/channel. Head vẫn che vật ở phía trước mặt khi nhìn từ sau. |
| Hình thương | Cán và đầu thương vẽ bằng vector runtime cùng nét mực; bỏ dải trang trí lớn của asset cũ. Tip native −46 dùng chung cho drawing và attachment query. Sword tiếp tục lấy pixel từ concept gốc. |

Code chính: [rig](../../scripts/presentation/concept_character_rig.gd), [renderer/attachment](../../scripts/presentation/concept_character_art.gd), [playback](../../scripts/presentation/illustrated_character_view.gd). Revision manifest: `concept-native-combat-31`; generator dùng cùng revision.

## Bằng chứng

**589/589 regression trên Linux/Godot 4.7.2**, không có script/runtime error trong log cuối. Các assertion mới không thay thế đánh giá độ tự nhiên bằng mắt.

| Kiểm tra | Kết quả / bằng chứng |
|---|---|
| Combat geometry | 4.656 pose của 2 body × 8 hướng × 3 vũ khí × 97 pha; xương giữ chiều dài, vai bám torso, grip/tip theo cùng attachment. Gập lớn nhất 135,00003° do số thực. [Report](../../artifacts/concept31_combat_constraints.json), [test](../../tests/concept_combat_tests.gd). |
| Continuity | Bước cổ tay lớn nhất 2,366 native unit / 1⁄96 chu kỳ; góc blade kiếm lớn nhất 16,00° / khoảng lấy mẫu. Có check forward contact ở hai profile; không dùng thêm frame để che một cú nhảy pose. |
| Hai tay thương | Sai lệch grip lớn nhất 0,00000575 native unit so với cán chung trong load/contact/follow đủ nắm. Đây là IK 2D, không phải xác nhận biomechanical 3D. |
| Playback | 976 pose qua `present_smooth`, có transition/spring. Kiếm tiếp tục bám forearm; bộ test trước giữ zero-time sync ở 128 cặp body/hướng. |
| Runtime combat | 144 framebuffer nguyên bản (48 / vũ khí), 21 ảnh overlay khớp (7 / vũ khí), mỗi ảnh có đủ 16 view. [Inspector so 0.30 / 0.31](../../artifacts/concept31_combat_review.html), [metadata](../../artifacts/concept31_combat_review.json). |
| Browser | Chrome Windows giải mã đủ 165 ảnh combat, test chọn vũ khí/body/hướng, overlay, keyboard/scrub/play và crop 1:1 tại viewport 600px. [Report](../../artifacts/concept31_combat_review_browser.json). |
| Action / world | 352 frame của 11 action + 11 sheet S/N; 256 frame từ locomotion/turn/input thật, 22 ảnh native. [Action inspector](../../artifacts/concept31_frame_review.html), [native log](../../artifacts/concept31_native.log). |
| UI / GPU | UI smoke 11 trạng thái tại 960×640, 1280×720, 1280×800; 4 probe premultiplied pigment + 12 probe mực. [UI](../../artifacts/concept31_ui.log), [GPU](../../artifacts/concept31_edge_filter.json), [ink](../../artifacts/concept31_ink_core.json). |
| Clip | Toàn bộ PNG được encode lossless, không crop/phóng/interpolate ảnh. RGB roundtrip được kiểm từng frame. [Combat](../../artifacts/concept31_combat_clip_validation.json), [locomotion](../../artifacts/concept31_clip_validation.json). |

Clip kiếm: [chu kỳ native](../../artifacts/concept31_combat_sword.webp). Clip thương: [chu kỳ native](../../artifacts/concept31_combat_spear.webp). Clip tay không: [chu kỳ native](../../artifacts/concept31_combat_unarmed.webp). Thời gian encode lần lượt 18 / 20 / 13 ms cho mỗi mẫu, xấp xỉ duration weapon của game; inspector có tốc độ chậm để kiểm từng pose.

## Phạm vi chất lượng

Đã kiểm các pha load/contact/follow/recovery bằng framebuffer và overlay thực, cả S/N/profile/diagonal. Đây vẫn là nhân vật cutout từ drawing đứng, hai đoạn tay, nội suy pose liên tục; không phải bộ artwork mới vẽ từng frame. Các vùng bàn tay/cuff, foreshortening hướng S/N và nếp áo ở góc gập lớn còn giới hạn của drawing nguồn. Góc cổ tay là góc attachment cục bộ, bàn tay chưa có bộ drawing/rig độc lập để thể hiện mọi kiểu nắm. Chưa nghiệm thu toàn bộ mỹ thuật phát hành.

Native captures chạy X11/Mesa llvmpipe; không dùng làm benchmark FPS. Godot Windows chưa được chạy lại trong pass này; Chrome Windows chỉ kiểm trang review.

## Tái kiểm

```bash
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_combat_review.gd -- --test-mode --capture-prefix=concept31 --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_action_frame_review.gd -- --test-mode --capture-prefix=concept31 --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_character_visual_smoke.gd -- --test-mode --capture-prefix=concept31 --capture-offscreen
python tools/build_concept_combat_review.py concept31
python tools/build_concept_frame_review.py concept31
python tools/render_concept_combat_preview.py concept31
node tools/verify_concept_combat_review.cjs concept31
node tools/verify_concept_frame_review.cjs concept31
```

Encoder cần Pillow; browser verifier dùng Playwright/Chrome của bundled Windows runtime. Người chơi không cần các dependency này.
