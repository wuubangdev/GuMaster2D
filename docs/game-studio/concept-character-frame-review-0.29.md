# Rà soát hướng và từng pha chuyển động — 0.29

## Phạm vi

Giữ nhân vật/concept đang dùng. Ưu tiên bước lên/xuống, nét viền và chi tiết tái sử dụng không còn hợp tư thế. Kiểm hai body × tám hướng × 11 action: idle, walk, run, attack, cast, defend, channel, dash, hit, death, respawn.

## Công việc và tiêu chí

- Đối chiếu stance chân với quãng đường thật trên cả tám hướng; đồng bộ nhịp bước với chiều sâu và envelope của chân ngắn.
- Tư thế lên/xuống có chuyển động tay và giày riêng; tránh xoay nguyên giày theo quy tắc hướng ngang.
- Tách vùng quần khỏi hình giày. Vùng nối bị lộ được vẽ theo đầu gối/cổ chân hiện tại, không kéo lại nét quần của pose đứng.
- Viền có lõi mực và fringe hẹp theo pixel màn hình; không làm dày cả vùng khử răng cưa hoặc tô lại từng chấm rời.
- Capture native dày hơn: 32 thời điểm/action trên 16 nhân vật; bảng tám pha lên/xuống cho từng action. Những ảnh này là frame runtime thật, không phải artwork được tạo mới.
- Kiểm geometry/UV/attachment, foot-contact, vòng lặp và các chuyển tiếp; kiểm gameplay, HUD, hiệu ứng và ownership bằng runtime.

## Những lỗi đã sửa

| Vấn đề xác nhận | Sửa ở runtime |
|---|---|
| Viền dưới một pixel bị fringe AA chiếm phần lớn, thiếu lõi mực rõ | Ribbon mesh có lõi opaque tối thiểu 1,15 pixel màn hình, fringe 0,38 pixel mỗi phía; contour RDP 1,25 pixel nguồn và bo góc tối đa 2,8 pixel nguồn |
| Quần của pose đứng còn đi theo giày khi chân bước | Mask giày bắt đầu ở cuff, tối đa 22 pixel nguồn trên ground. Quần nối được vẽ theo hip/knee/cuff của từng pose, offset/union bo khớp và tránh tự cắt; không tái dùng nếp quần cũ |
| Hướng lên/xuống dùng roll xoay giày kiểu ngang | Giày frontal/rear giữ cuff thẳng; bước thể hiện bằng chiều sâu và lift. Tay đi/chạy S/N có tám key góc riêng, nội suy cubic khép vòng |
| Chân trượt do stride không khớp quãng đường actor | Chiều dài chu kỳ theo hướng: profile ×1, S/N ×0,55, chéo khoảng ×0,807. Giảm độ dài bằng scalar, giữ nguyên hướng WASD; actor và source rig dùng cùng quãng đường |
| IK chạm giới hạn ở source nam S/N/E, gây trượt khi chân đang chạm đất | Chọn pelvis trong giao các khoảng reach hợp lệ của chân đỡ, gồm cả reach tối thiểu của xương không đều. Chân đang bay không đẩy pelvis ra ngoài khoảng của chân đỡ; hem bù theo crouch |
| Quần tự cắt ở một pha chạy SE | Union silhouette bo khớp; knee nằm dưới cuff không được vẽ thành nếp quần lộn ngược |
| Vận công nâng tay chưa rõ, guard frontal che tay phía xa | Grips vận công đặt gần giữa ngực; trong defend/channel phía trước, tay phía xa vẽ sau áo và trước đầu. Phía sau tiếp tục bị thân che đúng hướng |

Sáu indexed mesh màu vẫn giữ; viền và quần có thêm draw commands/mesh riêng. Số mesh màu không đại diện tổng draw calls; chưa benchmark FPS PC. Hai PNG màu còn byte-identical với concept đã duyệt.

## Kiểm chứng

**577/577 trên Linux/Godot 4.7.2.** Tám assertion mới so với 0.28. [Log cuối](../../artifacts/concept29_tests.log).

- **5.808 pose**: hai body × tám hướng × 11 action × 33 thời điểm; kiểm 11.616 silhouette quần, cuff, roll giày S/N, tay vận công, vòng key tay và cấu trúc lõi/fringe của stroke.
- **1.328 cặp stance** trong rig: so với displacement cùng hướng/quãng đường actor; sai lệch lớn nhất khoảng **0,00000191** đơn vị model. [Geometry](../../artifacts/concept29_geometry_review.json).
- **7.780 cặp stance qua ActorView thật**: dùng root interpolation, clock theo quãng đường và present_smooth; hai body × tám hướng × walk/run ở tốc độ ổn định. Sai lệch world lớn nhất **0,00116 pixel**, dưới ngưỡng 0,01. Phép này chưa nghiệm thu foot lock mọi lần dừng/đảo hướng đột ngột. [Actor measurement](../../artifacts/concept29_actor_stance.json).
- **GPU**: 12 mẫu lõi mực ở offset 0,25/0,5/0,75 pixel × opacity 1/0,5 × nền đen/trắng; sai lệch màu lõi tối đa 0,00481, vùng ngoài fringe không đổi màu. Bốn mẫu lọc atlas tại biên 50% alpha tiếp tục đạt, sai lệch tối đa 0,00278. [Stroke](../../artifacts/concept29_ink_core.json), [lọc biên](../../artifacts/concept29_edge_filter.json).
- **Native**: 352 PNG frame action, mỗi frame chứa 16 view; 11 bảng tám pha S/N; 22 ảnh gameplay/pose/nền sáng-tối/equipment/opacity/GPU và 256 frame motion/turn/gameplay/vertical. Tổng **608 frame runtime**, ngoài 33 ảnh review. [Action metadata](../../artifacts/concept29_action_review.json), [native metadata](../../artifacts/concept29_capture.json).
- **UI**: 11 trạng thái HUD/F3/F6/túi/nhiệm vụ/pause ở ba kích thước. [Log](../../artifacts/concept29_ui.log).

Đã xem bảng S/N của 11 action và ảnh tám hướng nền sáng/tối, cùng các pha native được chọn. Capture dày và kiểm geometry tự động bao phủ mọi mẫu; không tuyên bố đã đánh giá mỹ thuật thủ công từng pixel trong toàn bộ frame. Source color/interior vẫn là PNG. Death và các góc gập rất mạnh còn thiếu drawing riêng; các key/ảnh runtime ở đây không phải một bộ bitmap animation mới vẽ tay toàn bộ.

## Xem từng frame

[Mở inspector](../../artifacts/concept29_frame_review.html): chọn action/body/hướng, kéo slider hoặc dùng ←/→; Space phát/dừng. Ô chi tiết giữ pixel 1:1 của cùng PNG framebuffer để không gây nhòe do phóng PNG; không tạo lại nhân vật. Chrome Windows đã giải mã đủ **352 frame**, kiểm selection, scrubber, keyboard và breakpoint 600 px, không có page error. [Browser verification](../../artifacts/concept29_frame_review_browser.json).

[Đi/chạy](../../artifacts/concept29_motion.webp) · [Quay/đánh](../../artifacts/concept29_turn.webp) · [Gameplay](../../artifacts/concept29_gameplay.webp) · [W/S lên-xuống](../../artifacts/concept29_vertical.webp) · [Nền sáng](../../artifacts/concept29_outline_light.png).

Bốn clip lossless đã được giải mã và đối chiếu RGB với đủ **256 PNG gốc: 0 frame khác**. Không crop, tạo lại hoặc nội suy frame trong clip. [Đối chiếu](../../artifacts/concept29_clip_validation.json).

## Tái tạo

```sh
python3 tools/author_concept_character_masks.py
bash tools/run.sh --headless --script res://tools/build_concept_mattes.gd
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_action_frame_review.gd -- --test-mode --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/concept_character_visual_smoke.gd -- --test-mode --capture-prefix=concept29 --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/ui_style_visual_smoke.gd -- --test-mode
python3 tools/build_concept_frame_review.py concept29
python tools/render_concept_motion_preview.py concept29 motion
python tools/render_concept_motion_preview.py concept29 turn
python tools/render_concept_motion_preview.py concept29 gameplay
python tools/render_concept_motion_preview.py concept29 vertical
```

`--capture-offscreen` đặt cửa sổ ngoài màn hình, giữ nguyên renderer/framebuffer X11 1280×800. Có thể bỏ cờ để quan sát trực tiếp. Inspector là HTML local, không cần account/server bên ngoài; mở HTML cạnh các thư mục PNG hoặc chạy `python3 -m http.server 8879 --bind 127.0.0.1 --directory artifacts`.

Godot capture dùng X11/Mesa llvmpipe để review; engine Windows chưa chạy lại ở mốc này. Chrome/Pillow Windows chỉ kiểm inspector và đóng gói clip. Số frame/test không tự chứng minh mỹ thuật phát hành mọi pose/phụ kiện; map vẫn dùng atlas pixel cũ.
