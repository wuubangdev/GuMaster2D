# Sửa tách lớp và chuyển động nhân vật — 0.25

Runtime mới hơn: [chuyển hướng, vạt áo và vũ khí 0.26](concept-character-motion-0.26.md). Các kết quả dưới đây giữ baseline 0.25.

Ngày 11/10/2026. Yêu cầu: bỏ chi tiết thừa dính vào nhân vật và sửa cảm giác cả khối bị dịch chuyển thay cho vận động có khớp.

## Nguyên nhân ở 0.24

Rig trước cộng offset source vào joint của hình cũ, rồi scale chiều dài từng đoạn khi biến dạng. Bàn chân có thể kéo dài và tách khỏi gấu áo. Các mask chồng nhau cùng chứa pixel áo/cổ tay, khiến một chi tiết bị vẽ hoặc kéo theo nhiều lớp. Hình SE nam lấy từ minh họa lớn khác tỷ lệ/chất nét với bộ turnaround. Nét đất quanh đế giày cũng nằm trong vùng cắt.

## Sửa trong runtime

| Phần | Hành vi mới |
|---|---|
| Tách lớp | Hai atlas có thêm resource ownership. Mỗi pixel thuộc một lớp rõ ràng; shader chỉ cho đúng lớp vẽ pixel đó. Cẳng tay/bàn tay đang nằm trên áo thuộc về tay, phần vai bị che thuộc thân |
| Đầu/thân | Thân có pivot tại đai; cổ nằm trong hierarchy thân. Đầu quay quanh cổ, vai và hông theo thân. Bỏ scale toàn thân/áo trong renderer nguồn |
| Tay | Nhận nhịp/góc động tác từ control pose, xoay các đoạn theo độ dài xương nguồn. Không cộng offset đầu cuối rồi kéo giãn ảnh để tới vị trí cũ |
| Chân | IK hai đoạn dùng chiều dài đùi/cẳng chân nguồn và giới hạn tầm với. Hông hạ nhẹ khi đi/chạy để gối có thể gập; screen depth và lift tách riêng |
| Giày | Toàn bộ vùng giày giữ kích thước, chỉ đổi vị trí và góc cổ chân. Vùng quần bị che trên concept được nối bằng mảng mực/wash nằm dưới hình nguồn |
| Vùng bị che | Mảng mực/wash nhỏ nối vai–khuỷu, hông–gối–giày khi động tác làm lộ vùng trước đó không có trên concept. Nét tay áo, cổ tay, bàn tay và giày vẫn lấy từ ảnh gốc |
| Dọn chi tiết | Siết contour giày profile nam, bỏ nét đất mảnh quanh sole bằng opacity. SE nam dùng hình tương ứng trên bảng hướng 02 để cùng tỷ lệ/chất nét với các view còn lại |
| Chuyển tiếp | Native pose được pha bằng góc/độ dài đoạn xương; đồng bộ zero-delta giữ bàn tay đang vẽ khi nhận cast. VFX/kiếm/ghost lấy native grip |
| Độ trong suốt | ID lớp đi cùng UV page, độc lập với alpha/modulate. UI fade, death và ghost không được làm shader nhầm một đầu thành lớp khác |

PNG nguồn và chân dung F3 mặc định không sửa. Các view S/N/E nam vẫn dùng turnaround của concept 01; các view còn lại và nữ dùng bảng hướng 02. Di chuyển/cell/collision, chi phí kỹ năng, cooldown và damage vẫn do hệ gameplay hiện hành sở hữu.

## Mã và tạo lại

- [Rig tỷ lệ nguồn](../../scripts/presentation/concept_character_rig.gd): hierarchy, FK tay, IK chân và blend native pose.
- [Renderer nguồn](../../scripts/presentation/concept_character_art.gd): geometry thực dùng để vẽ, giày rigid, nối vùng bị che và native hand.
- [Character view](../../scripts/presentation/illustrated_character_view.gd): timeline/transitions, cache material và snapshot.
- [Mask author](../../tools/author_concept_character_masks.py), [opacity/ownership builder](../../tools/build_concept_mattes.gd), [shader](../../assets/shaders/concept_cutout.gdshader).

```sh
python3 tools/author_concept_character_masks.py
bash tools/run.sh --headless --editor --quit --import
bash tools/run.sh --headless --script res://tools/build_concept_mattes.gd
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
bash tools/run.sh --audio-driver Dummy --script res://tests/concept_character_visual_smoke.gd -- --test-mode --capture-prefix=concept25
python tools/render_concept_motion_preview.py concept25
python tools/render_concept_motion_preview.py concept25 gameplay
```

## Kiểm chứng

Regression Linux/Godot 4.7.2 đạt **547/547**, gồm tám assertion mới trên geometry đang dùng trong renderer: độ dài xương qua hai body × tám hướng × 11 hành động, liên kết cổ/vai/hông, kích thước giày, stance ngang bù đúng quãng di chuyển, ownership của đầu, loại nét đất dưới chân và zero-delta cast grip. [Kết quả](../../artifacts/test_results_linux.json), [log](../../artifacts/concept25_tests.log), [test native geometry](../../tests/concept_articulation_tests.gd).

Native review gồm 48 frame hai body/tám hướng và 64 frame input thật `D → Shift+S → thả phím`, có 28 mẫu walk, 24 run và 12 idle. Thêm 15 ảnh world/kỹ năng/hướng/động tác/trang bị/opacity; capture opacity kiểm 16 đầu vẫn hiện đúng nguồn ở alpha 50%. HUD/F3/F6/túi/nhiệm vụ/pause cũng được chụp lại 11 trạng thái ở ba kích thước cửa sổ.

[Gameplay](../../artifacts/concept25_gameplay.webp) · [Đi/chạy tám hướng](../../artifacts/concept25_motion.webp) · [Đánh](../../artifacts/concept25_attack.png) · [8 hướng](../../artifacts/concept25_directions.png) · [Opacity 50%](../../artifacts/concept25_opacity_half.png) · [Metadata input/pose](../../artifacts/concept25_capture.json) · [Log native](../../artifacts/concept25_native.log) · [Log UI](../../artifacts/concept25_ui.log).

Capture dùng X11/Mesa llvmpipe, lấy mẫu xác định 24 Hz để review; chưa phải benchmark máy PC mục tiêu. Hướng đi lên/xuống dùng foreshortening chiều sâu, không được coi là foot lock tuyệt đối trên mọi hướng. Form trang phục riêng, nón/tóc/thương và toàn bộ key pose vẽ tay vẫn còn trong scope art tiếp theo; đợt này nghiệm thu sửa tách lớp và hợp đồng xương, chưa nghiệm thu mỹ thuật phát hành.
