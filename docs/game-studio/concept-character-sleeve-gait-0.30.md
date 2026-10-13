# Tay áo, nhịp tay và bước chân — 0.30

Yêu cầu: dọn chi tiết nhiễu ở tay áo, chân bước có trọng lượng và cánh tay bớt cứng. Giữ concept đã duyệt, hai body, tám hướng và các slot trang phục/vũ khí. Hai PNG màu giữ nguyên byte.

## Lỗi xác nhận và thay đổi

| Vấn đề | Thay đổi |
|---|---|
| Underpainting vẽ cả đoạn xương thành dải xanh dài, chấm tròn và nét nối; một số dải nhô khỏi sleeve | Bỏ tube/chấm/nét phụ. Chỉ bù vùng hở tại khuỷu bằng sector theo giao điểm contour nguồn và hai góc xương; nối mép bằng cung mực ngắn |
| Viền tay áo tô lại đường cắt ownership giáp thân/đầu | Bỏ các cạnh chung khỏi viền sleeve; pixel màu gốc và matte giữ nguyên |
| Sketch nhỏ bị alias khi atlas thu xuống kích thước world | Shader lấy bốn mẫu theo footprint màn hình khi minify, loại giấy/owner khác trước lọc. Kích thước nguồn và viền vector giữ contract hiện hành |
| Vai và cẳng tay quay gần đồng thời | Vai đối trọng theo travel của chân cùng bên; forearm theo sau 0,075 chu kỳ, flex khác giữa đi/chạy. S/N có key riêng; nội suy khép vòng |
| Góc sau lưng che forearm/wrist vào áo | Trong walk/run phía sau, upper arm và forearm dùng hai pass quanh torso; mỗi tam giác màu nguồn vẽ một lần, tránh tăng opacity |
| Kiếm nam N neo vào vùng đã bị mask xóa vũ khí cũ | Grip chuyển từ (1401,401) về bàn tay còn hiển thị (1393,399); joint metadata và script authoring cùng cập nhật |
| Chân thiếu đối trọng/clearance và lớp sâu | Pelvis chuyển theo chân đỡ/contact; knee S/N theo bên hông của view; profile tăng lift, giày chỉ roll trong swing. Chân xa vẽ trước; quần có mảng sáng/tối theo trục chân |

Hai bone sleeve vẫn giữ form bàn tay, UV và grip kỹ năng. Vùng bù khuỷu là geometry tại khớp, không làm méo toàn bộ forearm. Source revision `concept-sleeve-gait-30`; ownership/contour tiếp tục từ 0.29.

## Kiểm chứng

- **581/581** Linux/Godot 4.7.2, log cuối không có runtime/script error. Bốn assertion mới so với 0.29: sole khi contact, phân vùng upper/forearm, elbow flex/loop tám hướng, grip N nằm trên pixel bàn tay. [Log](../../artifacts/concept30_tests.log).
- **5.808 pose**, 11.616 silhouette quần và **1.328 cặp stance**; drift model lớn nhất 0,00000191. [Geometry](../../artifacts/concept30_geometry_review.json).
- **7.780 cặp stance qua ActorView**; drift world lớn nhất 0,00116 pixel ở tốc độ ổn định. Đây là kiểm contact, không kết luận mọi nhịp bước đã tự nhiên. [Actor](../../artifacts/concept30_actor_stance.json).
- Native: **352 frame action × 16 view**, 11 bảng S/N; **256 frame** motion/quay/gameplay/W-S và 22 ảnh review. Thêm **32 ảnh chi tiết** render trực tiếp ở kích thước lớn, không phóng PNG. [Action metadata](../../artifacts/concept30_action_review.json), [native metadata](../../artifacts/concept30_capture.json).
- GPU: bốn probe atlas màu/ownership và 12 probe lõi mực trên nền đen/trắng, opacity/subpixel. Probe kiểm contract biên/màu; minify được đối chiếu bằng capture world. [Biên](../../artifacts/concept30_edge_filter.json), [lõi mực](../../artifacts/concept30_ink_core.json).
- UI: 11 trạng thái HUD/F3/F6/túi/nhiệm vụ/pause ở ba kích thước. [Log](../../artifacts/concept30_ui.log).
- Inspector trước/sau cùng body/hướng/pha, playback/scrubber/phím và 352 PNG native. [Inspector](../../artifacts/concept30_frame_review.html), [browser](../../artifacts/concept30_frame_review_browser.json).
- Bốn WebP lossless giải mã và so RGB với từng PNG native. [Kết quả](../../artifacts/concept30_clip_validation.json).

## Xem kết quả

![Chi tiết chạy hiện hành](../../artifacts/concept30_detail_run_02.png)

[Chi tiết trước sửa cùng pha](../../artifacts/concept29_detail_run_02.png), [clip walk/run](../../artifacts/concept30_motion.webp), [W — Shift W — Shift S — dừng](../../artifacts/concept30_vertical.webp), [quay/đánh](../../artifacts/concept30_turn.webp), [gameplay bốn Cổ](../../artifacts/concept30_gameplay.webp), [nền trắng](../../artifacts/concept30_outline_light.png).

## Phạm vi nghiệm thu

Đã sửa dải áo thừa ở baseline và lỗi contact/layer/grip vừa xác định. Mỹ thuật tổng thể vẫn cần đánh giá bằng clip: nét/màu bên trong còn từ PNG đứng; nếp gập mạnh chưa có drawing riêng từng action. Chưa xác nhận toàn bộ nhân vật đạt chất lượng phát hành, chưa benchmark FPS hay chạy lại Godot Windows. Native evidence dùng X11/Mesa llvmpipe; browser kiểm bằng Chrome Windows.

## Chạy lại

```bash
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_character_visual_smoke.gd -- --test-mode --capture-prefix=concept30 --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_action_frame_review.gd -- --test-mode --capture-prefix=concept30 --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_locomotion_detail.gd -- --test-mode --capture-prefix=concept30 --capture-offscreen
python3 tools/build_concept_frame_review.py concept30
```

Encoder/validator dùng Python có Pillow: `tools/render_concept_motion_preview.py concept30 <motion|turn|gameplay|vertical>` rồi `tools/verify_concept_motion_previews.py concept30`. Backup renderer/grip trước sửa ở `artifacts/concept30_baseline/`; capture 0.29 giữ để so sánh.
