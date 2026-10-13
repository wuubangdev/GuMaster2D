# Hành trang và thao tác vật phẩm 0.51

Trong túi **Tab/F4**, chọn một ô để xem thông tin và bảng thao tác phía trên lưới. Menu chuột phải dùng cùng các hành động. Bảng này nằm trong cửa sổ hành trang hiện có để vẫn dùng được ở 960×640 và khi mở cùng giao diện nhân vật.

## Hành vi đã triển khai

| Thao tác | Kết quả |
| --- | --- |
| Xem thông tin | Cổ: bậc, mức tu luyện, no đủ và mô tả; vật liệu: số lượng chồng, tổng số và công dụng; hover có tooltip |
| Dùng thức ăn | Chọn rõ Cổ tương thích trong danh sách, dùng một phần và hồi tối đa 40 no đủ; Cổ đã no không dùng thêm |
| Dùng phong ấn | Dùng mục tiêu đã chọn trong thế giới; đủ điều kiện thì trừ đúng một phong ấn, đóng túi và bắt đầu thi triển; lỗi giữ nguyên vật phẩm |
| Dùng hạt giống | Mở bảng gieo trồng; hạt chỉ bị trừ khi gieo thành công trong bí cảnh |
| Nâng / hợp Cổ | Mở bảng G vào đúng instance Cổ đã chọn, gồm cả Cổ dự trữ |
| Chế tạo | Chọn công thức, 1–99 lượt; xem nguyên liệu có/cần, bạc, sản phẩm và lý do chưa thể thực hiện |
| Xóa | Xác nhận tên và số lượng của chồng đang chọn; Esc hoặc “Giữ lại” hủy; Cổ đang khảm không thể xóa |
| Kéo sắp xếp | Kéo vào ô trống hoặc lên ô có vật phẩm để đổi chỗ; lưu cả vị trí trống |
| Lọc / tên A–Z | Là cách xem; kéo lên một vật phẩm đang lọc/sắp tên sẽ đổi chỗ thật và quay về bố cục thủ công |

Vật liệu chưa có công dụng trực tiếp hoặc công thức sẽ khóa nút tương ứng và hiện mô tả. Chế tạo thực hiện tại vùng an toàn (trại, trạm nghỉ, gần NPC hoặc khu điền viên), khi nhân vật còn sống, hết giao chiến và không đang phong ấn. Tooltip/menu nhận tọa độ từ sự kiện chuột; menu tự giới hạn theo kích thước sau khi font/theme được tính xong, kể cả khi đổi độ phân giải.

## Ba công thức đầu tiên

| Công thức | Giá mỗi lượt | Nhận mỗi lượt |
| --- | --- | --- |
| Ép phong ấn | 2 da thú + 1 linh thảo + 1 chân nguyên thạch + 10 bạc | 2 phong ấn |
| Lọc mật linh hoa | 3 phấn linh hoa + 1 linh thảo + 6 bạc | 2 mật linh hoa |
| Chưng chân nguyên thạch | 2 trứng linh kê | 3 chân nguyên thạch |

Các con số là mốc cân bằng ban đầu, sửa trong `data/item_recipes.json`. Cần playtest kinh tế cùng phần thưởng quest và tốc độ thu hoạch trước khi chốt cân bằng phát hành.

## Dữ liệu và ranh giới mã

- `ItemCrafting` đọc/kiểm công thức, tính thử toàn bộ chi phí và chỗ chứa sau khi dùng nguyên liệu; chỉ ghi dữ liệu khi mọi điều kiện đạt. Gọi lặp cùng request trả biên nhận đã lưu, không trừ/nhận lại; request trùng nhưng khác nội dung bị từ chối.
- `GuInventoryActions` trình bày thông tin, chọn Cổ và công thức; gửi yêu cầu qua HUD → GameManager → LocalAuthority. Sự kiện chế tạo thành công đi qua phản hồi âm thanh và lưu tiến độ hiện có.
- Kéo và xóa mang phiên bản túi. Hộp xác nhận giữ snapshot riêng của key, số lượng và phiên bản; loot/chế tạo thay đổi túi sẽ làm xác nhận cũ bị từ chối.
- `InventoryModel.slot_layout` là 30 key, chuỗi rỗng biểu thị ô trống. Giữ schema profile 1 và `display_order` để tương thích; save cũ thiếu layout dùng thứ tự cũ. Layout hỏng/chi tiết đã biến mất được chuẩn hóa mà không bỏ tài sản.
- Đóng túi hoặc pause dọn menu/hộp xóa. Esc đóng popup trước rồi mới đóng túi. Các nút đi đến bảng G/bí cảnh dùng luồng cửa sổ hiện có.

## Kiểm chứng

- Logic và lưu dữ liệu: **40/40 trên Linux và 40/40 trên Windows**. Có kéo/đổi ô, tương thích save cũ, save thật qua SaveStore, nạp lại biên nhận, retry, thiếu nguyên liệu, đầy túi, chết, giao chiến, ngoài vùng an toàn và batch không hợp lệ.
- Native Godot Windows/NVIDIA: **49/49**. Bơm sự kiện chuột/phím qua hệ input thật để chọn vật phẩm, bắt đầu kéo/thả, mở menu và xác nhận xóa; kiểm cùng số lượng sau dùng/chế tạo. Gồm ba độ phân giải 960×640 / 1280×800 / 1920×1080.
- Trang ảnh review: **19/19**; đủ các chế độ và ảnh ba kích thước, không lỗi JavaScript/tải tài nguyên hoặc tràn ngang ở 390 px.
- Hồi quy toàn game Linux: **911/911**, không lỗi; kết quả nguồn cuối trong `artifacts/inventory51_regression_linux.json` và manifest `artifacts/inventory51_delivery.json`.

[Xem ảnh native và đối chiếu trước](http://localhost:8879/inventory51_review.html). Trang review là ảnh từ game thật, không phải game chạy trong trình duyệt.

Chạy lại:

```sh
bash tools/run.sh --headless --script tests/inventory51_tests.gd -- --test-mode
bash tools/run.sh --headless --script tests/test_runner.gd -- --test-mode
.tools/godot/Godot_v4.7.2-stable_win64_console.exe --path 'D:\freelance\gumaster2d' --script res://tests/inventory51_review.gd -- --test-mode
```

Các kiểm tra dùng profile riêng và cờ test-mode. Ảnh native cùng báo cáo nằm trong `artifacts/inventory51_*`; bản mã trước sửa trong `artifacts/inventory51_baseline`.
