# Viền mực sạch và tách chi tiết — 0.28

Ngày 11/10/2026. Sửa theo phản hồi: viền nhòe/nhiễu trắng, chi tiết quần/chân và ngón tay còn dính vào thân. Tiếp nối [0.27](concept-character-sleeves-0.27.md).

Baseline lịch sử. Runtime hiện hành dùng [frame/hướng/viền 0.29](concept-character-frame-review-0.29.md).

## Những lỗi đã xác định

Shader cũ lọc RGB của ảnh có nền giấy rồi mới áp opacity/ownership. Pixel giấy và bộ phận bên cạnh vì vậy có thể tham gia vào màu tại mép bán trong suốt. Mặt nạ theo mẫu chung còn đặt lệch một số bàn tay ở góc nghiêng; ngón tay nằm ngoài mask tay và thuộc về thân áo. Gấu áo nữ/profile cắt xuống vùng quần; một số mảnh rời quanh giày tồn tại sau khi bỏ nền.

Ảnh tách lớp đã xác nhận chi tiết tay/quần trên thân; đây không chỉ là vấn đề tốc độ animation. [Thân và giày đã tách sau sửa](../../artifacts/concept28_isolated_parts.png).

## Runtime mới

| Phần | Thay đổi |
|---|---|
| Lọc màu ở mép | Bốn tap đọc texel màu/owner/opacity. Mỗi tap loại pixel không thuộc bộ phận trước khi nội suy màu premultiplied, rồi chuẩn hóa RGB theo alpha. Không lấy màu nền giấy hoặc tay/chân khác vào mép |
| Viền | Trace silhouette đã làm sạch thành contour nguồn; RDP 0,8 pixel nguồn và bo góc tối đa 2 pixel nguồn. Godot vẽ polyline có khử răng cưa, màu mực `#332c24`, rộng 0,36–0,44 đơn vị nhân vật |
| Bám animation | Contour đầu bám cổ/đầu, áo bám warp vạt, giày quay theo chân. Viền tay chia ở khuỷu và đi cùng hai vùng rigid của tay áo; không nối đường chéo qua hai transform khác nhau |
| Tay | Tâm bàn tay riêng cho nam/nữ và từng hướng theo drawing thực; sửa contour bàn tay gần ở profile gốc. Ngón tay thuộc lớp tay, không nằm trên áo |
| Gấu áo | Thu vùng cắt nữ/profile lên đúng gấu, loại quần phía dưới khỏi lớp thân đang chuyển động |
| Giày/quần | Giữ component liền lớn nhất cho mỗi giày; bỏ các mảnh rời. Phần nối quần dưới áo mảnh hơn, bỏ nét phụ/cap thừa ở cẳng chân |

Pipeline contour dùng [BitMap/marching squares và RDP của Godot](https://docs.godotengine.org/en/stable/classes/class_bitmap.html#class-bitmap-method-opaque-to-polygons). Hai PNG màu vẫn trùng SHA-256 concept; không chỉnh bitmap, không tạo nhân vật mới. Geometry/ownership và đường viền thay đổi; tọa độ tay hiệu ứng theo grip đã chỉnh, gameplay/save/cooldown/damage giữ hợp đồng cũ.

Sáu phần vẫn dùng sáu indexed mesh cho lớp màu. Có thêm lệnh vẽ đường viền vector; số mesh không đại diện tổng số lệnh canvas. Chưa đo FPS trên PC mục tiêu.

## Kiểm chứng

**569/569** Linux/Godot 4.7.2. Bốn assertion mới kiểm contour của 96 phần, 32 giày có silhouette liền, ngón tay thật ở các profile được chuyển vào tay và vùng quần không còn thuộc gấu áo nữ. Kiểm xương, mesh winding, chuyển hướng, zero-time skill grip và hệ thống game cũ tiếp tục đạt. [Log](../../artifacts/concept28_tests.log).

GPU/native kiểm bốn mẫu biên 50% alpha: hai atlas × nền đen/trắng. Sai lệch RGB so với màu foreground đúng tối đa **0,00278**, dưới ngưỡng 0,025; không có màu của pixel bị loại pha vào biên. [Phép đo](../../artifacts/concept28_edge_filter.json), [framebuffer probe](../../artifacts/concept28_edge_filter.png).

Native chụp **21 PNG và 160 frame**, gồm nền sáng/tối, tám hướng/hai body, walk/run/attack/defend/cast/channel, trang bị, opacity, bốn Cổ và gameplay WASD/Shift/thả phím. UI smoke chụp 11 trạng thái ở 960×640, 1280×720 và 1280×800. [Native metadata](../../artifacts/concept28_capture.json), [native log](../../artifacts/concept28_native.log), [UI log](../../artifacts/concept28_ui.log).

Ba clip WebP lossless đã được giải mã và so RGB với toàn bộ 160 PNG framebuffer tương ứng: **0 frame khác**, đủ 48 đi/chạy, 48 quay/đánh và 64 gameplay. Không crop, vẽ lại hoặc nội suy frame. [Đối chiếu clip](../../artifacts/concept28_clip_validation.json).

[Nền sáng](../../artifacts/concept28_outline_light.png) · [Nền tối](../../artifacts/concept28_outline_dark.png) · [Đi/chạy](../../artifacts/concept28_motion.webp) · [Quay/đánh](../../artifacts/concept28_turn.webp) · [Gameplay](../../artifacts/concept28_gameplay.webp).

## Mã và tái tạo

- [Shader](../../assets/shaders/concept_cutout.gdshader), [renderer/contour](../../scripts/presentation/concept_character_art.gd).
- [Author vùng cắt](../../tools/author_concept_character_masks.py), [ownership/trace builder](../../tools/build_concept_mattes.gd), [contour nguồn](../../assets/characters/concept-rig/contours.json).
- [Regression](../../tests/concept_character_tests.gd), [native/GPU probe](../../tests/concept_character_visual_smoke.gd).

```sh
python3 tools/author_concept_character_masks.py
bash tools/run.sh --headless --script res://tools/build_concept_mattes.gd
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
bash tools/run.sh --audio-driver Dummy --script res://tests/concept_character_visual_smoke.gd -- --test-mode --capture-prefix=concept28 --capture-offscreen
bash tools/run.sh --audio-driver Dummy --script res://tests/ui_style_visual_smoke.gd -- --test-mode
python tools/render_concept_motion_preview.py concept28 motion
python tools/render_concept_motion_preview.py concept28 turn
python tools/render_concept_motion_preview.py concept28 gameplay
```

`--capture-offscreen` đặt cửa sổ X11 ngoài vùng màn hình trong lúc chụp tự động; framebuffer vẫn được render ở 1280×800. Bỏ cờ này để quan sát cửa sổ review.

## Giới hạn

Đường viền là geometry vector có khử răng cưa; phần màu, mắt và các nét bên trong vẫn lấy từ ảnh concept, chưa chuyển thành SVG toàn bộ. Đây là cải thiện nét và tách lớp của nhân vật đang dùng, không xác nhận mọi frame/trang bị đạt mỹ thuật phát hành. Khớp bị che vẫn dùng underpainting; key pose vẽ tay và foot lock lên/xuống chưa hoàn thiện. Map vẫn dùng atlas pixel cũ. Capture X11/Mesa llvmpipe dùng review; Windows chưa chạy lại ở mốc này.
