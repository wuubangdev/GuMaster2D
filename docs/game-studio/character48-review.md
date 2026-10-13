# Kiểm chuyển động nhân vật · 0.48

Trang review phục vụ kiểm khớp và phối hợp động tác. Ảnh là framebuffer Godot thật của renderer đang dùng trong game, gồm nam/nữ, cận cảnh 256 px và bản nhỏ 48 px. Nét vẽ và concept giữ theo 0.47; lần này đối chiếu hành vi của rig.

## Phạm vi

- Cả tám hướng: vung kiếm, đỡ, hái lượm, khai khoáng, đi, chạy, thi triển Cổ, vận công.
- Bốn hướng chính: thêm lướt, trúng đòn, gục xuống, hồi sinh.
- Mỗi hướng có 15 tư thế mẫu, gồm tất cả các nhóm hành động kể trên.
- Hướng xuống, lên và phải: đi → chạy → dừng; đi → đánh → đi; ngắt hái lượm để đi, đổi sang cuốc rồi đỡ; quay 90° và 180°.
- Ba hướng đó có thêm clip `actor_walk_run_stop` từ `ActorView` thật. Kịch bản đặt vận tốc state 2 ô/s khi đi và 3,5 ô/s khi chạy. State vị trí thay đổi theo thời gian, `_process` tính quãng đường, stride và move blend; snapshot thực được dùng cho hai kích thước vẽ. Nền mốc chấm dịch theo vị trí root, tương đương camera bám nhân vật. JSON ghi cả root và bàn chân trong tọa độ thế giới để kiểm trượt chân.

Sáu clip chính và hai clip phép dùng `GuIllustratedCharacterView.present_smooth`. Mỗi frame có bốn substep; tốc độ chụp tối thiểu 24 FPS, thời lượng khớp clip thật. Các trạng thái loop dài như đỡ/vận công lấy đoạn đầu 0,9 giây; đây không phải bằng chứng trọn chu kỳ của hai loop đó. Các tư thế tĩnh lấy pha được ghi rõ trong report.

## Đối chiếu 0.47

`artifacts/concept48_baseline/project` là bản project thực thi đóng băng trước thay đổi. Baseline chạy engine riêng với scripts riêng, không gọi rig hiện tại để giả lập bản trước. Asset 0.47 dùng chung qua symlink vì nhiệm vụ này chỉ sửa chuyển động; hash asset được ghi cùng scripts và phải khớp khi xuất review.

Baseline có sáu clip ở ba hướng: kiếm, đi, chạy, đi → chạy → dừng, đi → đánh → đi, và clip `ActorView` thật. Trang chỉ bật so sánh ở nơi có bằng chứng đã chụp. Những hành động/hướng còn lại không được ghi nhận là có A/B.

## Cách chạy

```bash
# Chỉ một native renderer dùng DISPLAY tại một thời điểm.
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy \
  --script res://tests/character48_motion_review.gd \
  -- --test-mode

# Có thể chụp riêng sau khi nguồn đã ổn định.
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy \
  --script res://tests/character48_motion_review.gd \
  -- --test-mode --directions=0,4,6

python3 tools/build_character48_motion_review.py
```

Fixture hỗ trợ `--output=/absolute/folder`, `--label=0.47`, `--clips=attack,walk,...`, `--quick` (bỏ tư thế tĩnh). Dùng chính fixture trong project baseline để chụp trước. Không đổi file giữa lúc đang chụp; fixture so SHA256 đầu/cuối và dừng nếu nguồn thay đổi.

## Xem và kiểm

`http://localhost:8879/concept48_character_review.html` có chọn hướng, giới tính, clip, tốc độ, bước frame, overlay khớp và so sánh trước/sau. Overlay lấy đúng tọa độ của snapshot đã chụp, không dựng một bộ xương riêng. Browser chỉ phát PNG và vẽ đường chỉ dẫn; không nội suy ảnh, không thêm chuyển động CSS. Phần tiêu đề được trình bày lại để mỗi crop nam/nữ đọc được riêng; vùng nhân vật giữ nguyên pixel native.

Builder kiểm đủ PNG, kích thước, danh sách frame và SHA256 current/baseline. Verifier browser kiểm từng clip, đầu/giữa/cuối, phát/dừng, từng pose, hai giới tính, bật tắt khớp, tính khả dụng của A/B và bố cục 1440/960/390 px. Kết quả lưu trong `artifacts/concept48_browser.json`.

Các kiểm này chứng minh nguồn ảnh và điều khiển review hoạt động. Đánh giá tự nhiên, silhouette và độ rõ động tác vẫn cần xem native clip; tính đúng gameplay cần các test simulation và event riêng.

## Kết quả cuối

Nguồn cuối được chụp lại sau khi sửa giới hạn tay vận công. Cả tám report có cùng 22 SHA256 nguồn hiện tại, gồm rig, bảng tư thế, foot plant, renderer, skin, shader và asset. Mã rig bắt đầu `f1b946be6bc1`; builder xác nhận toàn bộ hash và PNG trước khi xuất trang.

- 2.494 framebuffer hiện tại: 98 clip và 120 tư thế tĩnh, mỗi frame chứa hai giới tính ở hai kích thước.
- 585 framebuffer baseline 0.47 thực thi riêng: 18 clip đối chiếu. Builder kiểm từng cặp số frame, thời lượng và thời điểm lấy mẫu.
- Browser đạt 766/766 kiểm, không lỗi JavaScript hoặc tải ảnh. Đã kiểm phát/dừng, bước frame, timeline, các pose, hai giới tính, overlay khớp, A/B và không tràn chiều ngang ở 1440/960/390 px.
- PNG trang cuối: `artifacts/concept48_browser.png` và `artifacts/concept48_browser_mobile.png`.
- Báo cáo máy đọc: `artifacts/concept48_review.json`, `artifacts/concept48_browser.json`, `artifacts/concept48_final_source_audit.json`.

Bộ candidate trước lần sửa vận công cuối được giữ trong `artifacts/concept48_candidate`; trang cuối chỉ đọc `artifacts/concept48`. Ảnh Windows thực trong game được liên kết riêng qua `artifacts/concept48_world_front.png`; kịch bản kiểm chân trụ ActorView 2/3,5 ô/s được ghi rõ ở caption.

Review độc lập xem các hướng S/N/E, các động tác kiếm/cuốc, cast SE, channel S/W/E và chân nhấc NW/NE. Vùng gối đang nhấc ở góc chéo có co nhanh ở cỡ soi 256 px; lấy mẫu dày xác nhận chuyển động liên tục, không đổi nhánh IK đột ngột, và chuỗi native không xuất hiện rời cẳng chân. Đây là giới hạn còn được ghi nhận để theo dõi thẩm mỹ, không được mô tả thành chuyển động hoàn hảo.
