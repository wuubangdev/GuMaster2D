# Review và kết quả kiểm thử

Thư mục này nhận kết quả khi chạy các script trong `tests/`. Git giữ bộ review UI 0.54, ảnh và báo cáo tương ứng, cùng các fixture nhỏ dùng để so sánh nhân vật 0.44/0.46/0.47. Các file `gu52_*.png` đi kèm là ảnh bảng Cổ được chụp lại trong đợt kiểm 0.54; tên file do script `tests/gu52_review.gd` tạo.

Chạy từ thư mục gốc:

```sh
python3 -m http.server 8879 --directory artifacts
```

Mở `http://localhost:8879/hud54_review.html` hoặc `http://localhost:8879/inventory51_review.html`. Báo cáo `hud54_delivery.json` ghi hash các nguồn runtime và bằng chứng ở thời điểm hoàn tất UI 0.54.

Ảnh/video lịch sử và bản sao nguồn không dùng bởi test không được đưa vào Git. Các script dựng trang review cũ trong `tools/` có thể cần chạy script capture tương ứng trong `tests/` trước. Game và bộ hồi quy `tests/test_runner.gd` không phụ thuộc các capture lịch sử.
