# Chuyển hướng, vạt áo và vũ khí — 0.26

Runtime hiện hành tiếp tục ở [tay áo và phòng thủ 0.27](concept-character-sleeves-0.27.md). Nội dung và kết quả dưới đây thuộc baseline 0.26.

Ngày 11/10/2026. Tiếp tục sửa nhân vật hiện có từ [0.25](concept-character-articulation-0.25.md), giữ màu/nét của hai ảnh concept và tỷ lệ nguồn.

## Những điểm được sửa

| Phần | Runtime hiện hành |
|---|---|
| Khớp khi chuyển tiếp | Sau blend, cổ/vai/hông được dựng lại từ hierarchy thân. Không nội suy tọa độ tuyệt đối của các điểm gắn khi thân quay |
| Chuyển góc nhìn | Render đi qua các hướng vẽ 45° theo cung ngắn, mỗi bước 26 ms. Hướng điều khiển và xử lý kỹ năng vẫn cập nhật ngay; quay 180° cần tối đa 104 ms tích lũy trong presentation |
| Giữ tỷ lệ | Retarget mang góc động tác tương đối sang bộ xương của view mới, giữ đúng chiều dài xương của hình đang hiển thị. Không pha chiều dài giữa hai silhouette khác nhau |
| Tay trước/sau | Thứ tự che khuất gắn với drawing đang hiển thị, không nội suy để đổi lớp tay áo giữa chừng trong cùng một hướng |
| Frame nhận lệnh | Khi delta bằng 0, giữ nguyên toàn bộ source pose, source view và đầu kiếm đang vẽ; effect origin tiếp tục lấy bàn tay thực |
| Tay áo | Mesh có thêm vertex bên trong để uốn quanh khuỷu, thay vì chỉ kéo các góc ngoài của mảng ảnh |
| Áo | Outline được chia thành ô/strip nhỏ, neo ở đai và cổ. Vạt dưới phản ứng riêng với bước chân; response theo strip tránh tam giác mảnh đảo khi ngã |
| Lệnh vẽ | Sáu phần nguồn dùng sáu indexed mesh cho mỗi pose. Số lệnh canvas không tăng theo số tam giác của áo; các mesh giữ sống đủ frame kể cả canvas vẽ nhiều ghost |
| Kiếm | Contour guard/blade tách khỏi bàn tay. Phần kiếm đã vẽ sẵn trên hình profile/rear bị loại khỏi lớp body để không kéo theo vũ khí thứ hai. Opacity giữ phần màu ngà bên trong lưỡi kiếm có nét mực hở |
| Đòn ngang | Khi phản chiếu hình kiếm sang phía còn lại, phản chiếu cả góc vung. Kiếm đi ra ngoài ở cả profile trái/phải, thay vì profile phải chĩa xuống đất |

Ảnh PNG màu và chân dung F3 mặc định giữ nguyên byte. Đợt này thay geometry, opacity/ownership, chuyển tiếp presentation và cách lấy transform của vũ khí; không thay tốc độ, cell/collision, chi phí Cổ, cooldown, damage hoặc save.

## Mã và tái hiện

- [Native rig/retarget](../../scripts/presentation/concept_character_rig.gd), [playback/chuyển hướng](../../scripts/presentation/illustrated_character_view.gd).
- [Geometry, mesh và kiếm](../../scripts/presentation/concept_character_art.gd), [mask author](../../tools/author_concept_character_masks.py), [opacity/ownership builder](../../tools/build_concept_mattes.gd).
- [Test geometry/transitions](../../tests/concept_articulation_tests.gd), [native capture](../../tests/concept_character_visual_smoke.gd).

```sh
python3 tools/author_concept_character_masks.py
bash tools/run.sh --headless --editor --quit --import
bash tools/run.sh --headless --script res://tools/build_concept_mattes.gd
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
bash tools/run.sh --audio-driver Dummy --script res://tests/concept_character_visual_smoke.gd -- --test-mode --capture-prefix=concept26
bash tools/run.sh --audio-driver Dummy --script res://tests/ui_style_visual_smoke.gd -- --test-mode
python tools/render_concept_motion_preview.py concept26
python tools/render_concept_motion_preview.py concept26 turn
python tools/render_concept_motion_preview.py concept26 gameplay
```

## Giới hạn mỹ thuật

Đầu vẫn dùng tám hình hướng đã vẽ; chuyển hướng là chuyển giữa các drawing, không phải nội suy khuôn mặt 3D. Phần giải phẫu bị che trên concept vẫn dùng underpainting mực/wash. Outfit form riêng, nón/tóc/thương và các key pose vẽ tay chưa hoàn thiện theo mọi hành động. Các clip lấy mẫu xác định trên X11/Mesa llvmpipe, không phải benchmark FPS hay nghiệm thu mỹ thuật phát hành. Foot lock tuyệt đối ở hướng lên/xuống chưa nằm trong kết quả lần này.

## Kiểm chứng

Regression Linux/Godot 4.7.2: **559/559**, không có lỗi runtime. 12 assertion bổ sung trên native source pose/geometry kiểm 128 tổ hợp body/cặp hướng, hierarchy giữa các frame chuyển tiếp, chiều dài xương của view đang vẽ, zero-time pose/view/tip, thứ tự che khuất tay theo view, shadow theo ankle, mesh áo, neutral landmarks, belt/collar pin, triangle winding và sword ownership/profile strike. [Log](../../artifacts/concept26_tests.log), [kết quả](../../artifacts/test_results_linux.json).

Native chụp **16 PNG và 160 frame**: 48 đi/chạy, 48 chuyển góc/ra đòn, 64 gameplay nhận input `D → Shift+S → thả phím` (28 walk, 24 run, 12 idle). Capture kiểm mỗi nhân vật dùng sáu indexed mesh và kiểm 16 đầu khi fade alpha 50%. UI smoke chụp lại 11 trạng thái HUD/F3/F6/hành trang/nhiệm vụ/pause ở 960×640, 1280×720 và 1280×800. Log native/UI không có lỗi.

[Chuyển hướng và đánh](../../artifacts/concept26_turn.webp) · [Gameplay thật](../../artifacts/concept26_gameplay.webp) · [Đi/chạy](../../artifacts/concept26_motion.webp) · [Đánh tám hướng](../../artifacts/concept26_attack.png) · [Tay không](../../artifacts/concept26_unarmed.png) · [Metadata](../../artifacts/concept26_capture.json) · [Native log](../../artifacts/concept26_native.log) · [UI log](../../artifacts/concept26_ui.log).
