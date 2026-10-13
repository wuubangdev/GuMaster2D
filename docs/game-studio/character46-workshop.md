# Xưởng nhân vật theo hướng · 0.46

Yêu cầu lần này là sửa nhân vật theo từng hướng: đứng và gắn xương trước, kiểm asset ở điểm nối, rồi mới chuyển sang tấn công, phòng thủ, thu thập và di chuyển. Trang review mở ở hướng xuống; các hướng còn lại đi theo thứ tự vòng quay của rig: xuống trái, trái, lên trái, lên, lên phải, phải, xuống phải.

## Bằng chứng hình ảnh

`tests/character_direction_workshop_review.gd` chụp bằng renderer Godot thật. Mỗi ảnh 960 × 640 chứa hai giới tính. Ba cột dùng cùng snapshot của `GuIllustratedCharacterView`:

1. Khung xương, cổ tay, điểm cầm và vị trí chân tiếp đất.
2. Asset của renderer hiện tại, kèm chính các khớp đó.
3. Nhân vật hoàn chỉnh.

Màu xanh đánh dấu phía trái của nhân vật; màu cam đánh dấu phía phải. Vạch ở bàn chân dùng trọng số tiếp đất từ pose. Đây là bằng chứng về vị trí khớp hiển thị, không phải phép chứng minh tự động rằng silhouette đã đẹp.

Mỗi hướng có 9 tư thế tĩnh: đứng; kiếm lấy đà, ra đòn và thu tay; đỡ; hái lượm; giơ cuốc; đi bộ; chạy. Sau kiểm tĩnh, sáu clip được chụp 24 frame: tấn công, phòng thủ, hái lượm, khai khoáng, đi bộ và chạy. Mỗi frame chạy bốn bước cập nhật của API `present_smooth`; JSON ghi phase và tọa độ khớp đã được vẽ. Kiếm, thương và tay không có thêm ảnh điểm bám ở pha tấn công 0.34; ảnh này không thay cho việc kiểm cả chu kỳ của từng vũ khí.

Baseline đủ tám hướng dùng manifest, atlas và bản rig 0.44 đã đóng băng trong fixture, ở đúng các pha tương ứng. Bản sau dùng rig và asset hiện tại; cả hai cùng pha nhưng tọa độ khớp được phép thay đổi khi sửa tư thế.

## Trang xem

`tools/build_character_direction_workshop_review.py` chỉ xuất các hướng đã có report native hoàn chỉnh và đủ file ảnh. Hướng chưa có dữ liệu bị vô hiệu hóa. Bộ SVG được sao chép nguyên trạng từ đường dẫn trong manifest, hiển thị kèm xương chủ quản và điểm neo. Các SVG này là asset nguồn, không được mô tả thành frame chuyển động.

Trang `artifacts/concept46_character_workshop.html` phát PNG thật theo thời lượng clip, cho phép dừng và bước từng frame. Không dùng biến đổi CSS hoặc nội suy ảnh để giả lập kết quả của renderer. Cache trình duyệt giữ tối đa hai clip nhằm giới hạn bộ nhớ.

Mỗi đợt chụp ghi SHA256 của rig, bảng tư thế, renderer, fitting, manifest và atlas. Nếu nguồn thay đổi trong lúc chụp, fixture dừng với mã lỗi 1. Khi dựng trang, builder so sánh các hash đó với nguồn hiện tại; ảnh từ lần sửa trước được ghi chú rõ và browser verifier không coi bộ bằng chứng đó là bản cuối.

Chế độ baseline theo dõi ba file đã đóng băng trong `concept46_baseline` và fixture rig, không so sánh chúng với rig/atlas đang phát triển. Các ảnh cảnh game `concept46_world_front`, `concept46_world_gather_17/30/45`, `concept46_world_mine_17/30/45` và `concept46_studio_mine` được đưa vào phần đối chiếu kích thước game khi có thật trên đĩa. Các hậu tố 17/30/45 là frame của chu kỳ 60 bước, không phải số giây.

Hai ảnh `concept46_north_world_gather_30` và `concept46_north_world_mine_30` bổ sung góc nhìn hướng lên ở đúng tài nguyên trong game. Chúng giúp phân biệt việc bàn tay bị che bởi góc camera với việc nhân vật thực sự thao tác sai chỗ.

## Lệnh dựng bằng chứng

```bash
# Chỉ chạy một renderer native tại một thời điểm.
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy \
  --script res://tests/character_direction_workshop_review.gd \
  -- --test-mode --directions=0 --poses-only

# Chụp clip sau khi đã kiểm ảnh tĩnh. Bỏ --directions để chụp đủ 8 hướng.
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy \
  --script res://tests/character_direction_workshop_review.gd \
  -- --test-mode --directions=0

python3 tools/build_character_direction_workshop_review.py
```

Browser verifier `tools/verify_character_direction_workshop_review.cjs` kiểm nguồn ảnh theo hướng và tư thế, tải clip, chạy/dừng phát, trang bị, asset nam/nữ và tràn chiều ngang ở 1440/960/390 px. Kết quả được ghi ở `artifacts/concept46_browser.json`; số lượng kiểm thay đổi theo số hướng thực sự đã chụp.

## Kết quả kiểm cuối

Đợt chụp cuối sau khi sửa điểm tiếp xúc hướng lên trái có 1.248 ảnh native: 1.152 frame chuyển động, 72 tư thế tĩnh và 24 ảnh trang bị. Cả tám report có cùng bộ hash nguồn; builder xác nhận nguồn hiện tại và baseline đóng băng đều hợp lệ ở tám hướng. Trang còn chứa 72 ảnh baseline, 352 SVG nguồn và 10 ảnh cảnh game.

Browser verifier đạt 324/324 kiểm, không có lỗi JavaScript hay tải tài nguyên. Bằng chứng ở `artifacts/concept46_browser.json`; ảnh trang ở `artifacts/concept46_browser.png` và `artifacts/concept46_browser_mobile.png`. Kiểm browser chứng minh dữ liệu, điều khiển phát và bố cục hoạt động; không thay cho đánh giá hình vẽ.

## Giới hạn

Ảnh xưởng phóng lớn giúp kiểm đường nối và thứ tự lớp. Cần đối chiếu thêm cảnh game và các bài kiểm gameplay trước khi kết luận thay đổi không ảnh hưởng hệ thống hiện có. Trang review không tự đánh dấu hướng đạt chất lượng mỹ thuật chỉ vì file ảnh tồn tại.
