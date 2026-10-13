# Tay áo và tư thế phòng thủ — 0.27

Runtime hiện hành tiếp tục ở [viền mực/tách chi tiết 0.28](concept-character-contours-0.28.md). Nội dung và kết quả dưới đây thuộc baseline 0.27.

Ngày 11/10/2026. Tiếp tục tối ưu nhân vật concept đang dùng trong game từ [0.26](concept-character-motion-0.26.md).

## Lỗi và thay đổi

Kiểm tra geometry tay nguồn phát hiện các tam giác bị đảo khi hai transform xương được pha trộn qua khuỷu. Trên hai body × tám hướng × hai tay × 11 hành động × 33 thời điểm, bản trước có **12.171 mẫu tam giác đảo**, kể cả đi/chạy; bản mới không còn mẫu đảo. Đây là số lần lỗi geometry, không phải số frame lỗi hoặc số pixel nhìn thấy; một phần mesh có thể bị mask hoặc thân che. [Số liệu trước/sau](../../artifacts/concept27_sleeve_audit.json).

Renderer hiện cắt UV theo đường qua khuỷu nguồn, tạo hai vùng độc lập cho cánh tay trên và cẳng tay. Mỗi tam giác quay theo đúng một xương, không bị kéo giữa hai transform. Bàn tay đi cùng cẳng tay, giữ hình và khớp grip dùng cho kiếm/thương/hiệu ứng. Hai vùng vẫn nằm trong một indexed mesh của mỗi tay; sáu bộ phận tiếp tục dùng sáu mesh/pose. Phần nối mực/wash dưới khớp được giữ; lần này không vẽ lại artwork.

Phòng thủ dùng đích tay gần ngực trong hệ tọa độ thân, giải IK với chiều dài xương của hướng đang hiển thị. Khuỷu co về tư thế giữ đòn, hai bàn tay ở trên đai; kiếm/thương dựng lên và nghiêng ra ngoài để giảm che khuôn mặt. Chuyển vào/ra phòng thủ tiếp tục qua transition và spring hiện có. [Ảnh phòng thủ thật](../../artifacts/concept27_defend.png).

Hai PNG màu và ownership/opacity 0.26 giữ nguyên. Tốc độ, vị trí/collision, cooldown, damage và save giữ hợp đồng hiện có. Mã: [mesh tay](../../scripts/presentation/concept_character_art.gd), [rig/IK](../../scripts/presentation/concept_character_rig.gd), [regression geometry](../../tests/concept_articulation_tests.gd).

## Kiểm chứng

Linux/Godot 4.7.2: **565/565 assertion**. Sáu assertion mới kiểm diện tích UV nguồn không thiếu/chồng ở tư thế gốc, winding và cạnh tam giác tay qua toàn bộ ma trận trên, bàn tay thực bám grip, phòng thủ gọn và vũ khí hướng lên cho nam/nữ, tám hướng, ba lựa chọn vũ khí. Các kiểm tra hierarchy, chuyển hướng, zero-time effect origin, gameplay và save cũ tiếp tục đạt. [Log](../../artifacts/concept27_tests.log).

Native X11/Mesa llvmpipe: **18 PNG, 160 frame** (48 đi/chạy, 48 quay/đánh, 64 gameplay nhận WASD/Shift/thả phím), bốn Cổ được nhận trong game, sáu mesh/pose và opacity 50% kiểm trên 16 đầu. Thêm ảnh cast/channel để review tay co mạnh. [Metadata](../../artifacts/concept27_capture.json), [native log](../../artifacts/concept27_native.log).

Ba clip WebP lossless đã đối chiếu đủ 160 frame với PNG framebuffer tương ứng, không crop hoặc tạo frame trung gian. [Kết quả đối chiếu](../../artifacts/concept27_clip_validation.json).

UI smoke chụp 11 trạng thái ở 960×640, 1280×720 và 1280×800. [UI log](../../artifacts/concept27_ui.log), [metadata UI](../../artifacts/ink20_ui_visual_capture.json). Không lỗi script/runtime; driver X11 có cảnh báo không hỗ trợ đổi V-Sync. Windows chưa chạy lại ở mốc này.

[Gameplay](../../artifacts/concept27_gameplay.webp) · [Đi/chạy](../../artifacts/concept27_motion.webp) · [Quay/đánh](../../artifacts/concept27_turn.webp) · [Đánh](../../artifacts/concept27_attack.png) · [Phòng thủ](../../artifacts/concept27_defend.png) · [Cast](../../artifacts/concept27_cast.png) · [Channel](../../artifacts/concept27_channel.png).

## Tái hiện

```sh
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
bash tools/run.sh --audio-driver Dummy --script res://tests/concept_character_visual_smoke.gd -- --test-mode --capture-prefix=concept27
bash tools/run.sh --audio-driver Dummy --script res://tests/ui_style_visual_smoke.gd -- --test-mode
python tools/render_concept_motion_preview.py concept27 motion
python tools/render_concept_motion_preview.py concept27 turn
python tools/render_concept_motion_preview.py concept27 gameplay
```

## Giới hạn

Đây là cải thiện mesh và pose của nhân vật hiện có. Khớp dùng phần nối dưới artwork khi co mạnh; chưa có toàn bộ key pose vẽ tay, artwork riêng cho mọi outfit/phụ kiện hoặc foot lock tuyệt đối ở hướng lên/xuống. Tám hình hướng vẫn chuyển theo drawing; không nội suy mặt 3D. Native capture dùng thời gian mẫu xác định, không phải benchmark hoặc xác nhận mỹ thuật phát hành.
