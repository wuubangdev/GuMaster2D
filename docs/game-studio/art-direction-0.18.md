# Dáng bước và trang phục — 0.18

Phạm vi: tối ưu nhân vật chibi đang có. Không đổi mẫu đầu, mặt, tóc, thân, vũ khí hay giới tính/trang phục đã hỗ trợ. Nâng cấp motion và cách phân khối trên bộ hình gốc; alpha/kích thước 131 SVG phải khớp golden baseline 0.15.

## Tham khảo và cách áp dụng

| Nguồn chính thức | Điều tham khảo | Quyết định cho nhân vật hiện tại |
|---|---|---|
| [Hero’s Adventure: Road to Passion](https://store.steampowered.com/app/1948980/Heros_Adventure_Road_to_Passion/) | Bối cảnh võ hiệp, nhân vật nhỏ trong cảnh đông; trang phục cần đọc thành khối | Ưu tiên tóc/mặt/áo/đai/giày thành các khối rõ; giảm họa tiết sáng tranh với mặt |
| [Moonlighter](https://store.steampowered.com/app/606150/Moonlighter/) | Nhân vật nhỏ trong góc nhìn từ trên xuống, silhouette chiến đấu gọn | Chọn bước ngắn hợp chân chibi, rõ chân tì/nhấc; tránh cẳng chân kéo dài khi đi xuống |
| [Nobody Saves the World](https://store.steampowered.com/app/1432050/Nobody_Saves_the_World/) | Khối hình minh họa 2D và nét bao đọc được ở kích thước chơi | Giữ chất liệu vector của mẫu cũ, giảm chi tiết kiểu dây nổi; nếp vải là mặt sáng/tối và biến dạng thật |

Các lựa chọn trên là suy luận mỹ thuật cho dự án từ nguồn cửa hàng/ảnh được lập chỉ mục, không phải số đo animation của các game tham khảo. Không nhập/copy tài nguyên bên ngoài. Trình duyệt computer-use không khởi tạo được trong môi trường WSL hiện tại; chưa kiểm chứng video/frame-by-frame của các game này.

## Chuyển động

Gait đi/chạy dùng bước 20/28 đơn vị và lift 3/4.2 thay cho 32/44 và 4.5/6.5. Pha vẫn tích lũy từ quãng đường thật, stance tuyến tính hủy quãng đường thân và đường trả chân Hermite nối vận tốc tại tiếp đất. Các thông số nằm cùng sampler mà world và F6 sử dụng.

Khớp gối giải bằng hai đoạn tám đơn vị. Góc ngang cho thấy chiều dài cố định; các góc trước/sau có foreshortening của hướng gập. Không tăng độ dài đùi/cẳng chân để nối một endpoint quá xa. Test kiểm tra cả ba vũ khí, tám hướng, 11 hành động, kể cả death/respawn.

Áo dùng mesh UV 4×8 trên chính SVG gốc. Cổ và vùng đai giữ nguyên; chỉ phần dưới đai biến dạng theo chân nhấc và sway trễ của thân. Pose lưu tham số vải để blend/interrupt không nhảy về áo cứng. Moving cast chuyển cả gait vải với chân; reduced motion trả áo về hình nghỉ.

## Chất liệu và nghiệm thu

Da giảm chênh lệch mảng sáng, thêu cùng sắc vải, vạt đai chuyển sắc vải thay vì vàng chói. Thêm nếp gấp dạng mảng, bóng sát đai, đường chỉ mảnh và chi tiết bàn tay trong vùng alpha cũ. Những chi tiết này phải đọc được ở 48 px và không gây vụn khi phóng lên 128 px.

Review ảnh native phải xem trước/sau, góc ngang, góc chéo và back view; tiếp tục bảo vệ lớp tay/vũ khí, tay phóng và các cửa sổ F3/F6. Tám view đầu/áo tác giả hóa vẫn có đổi silhouette khi qua mốc hướng; blend khớp không biến chúng thành bộ frame vẽ tay đầy đủ. Hoàn thành pass này không đồng nghĩa đạt mỹ thuật phát hành.
