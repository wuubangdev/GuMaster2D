# Review nhân vật — 0.18

Brief khóa: giữ nhân vật cũ, cải thiện dáng bước và chi tiết theo tham khảo game khác; PC/Godot, tám hướng, đủ động tác, renderer chung world/HUD/F3/F6, cosmetic/save/control giữ nguyên.

## Vấn đề và sửa chữa

| Mức | Bằng chứng 0.17 | Sửa 0.18 / tiêu chí review |
|---|---|---|
| P1 | Walk/run hướng Nam: chân tì kéo dài rõ dưới áo, chân đang nhấc mất trong áo; dáng thân giống treo trên một cẳng chân | Giảm bước/lift, giải gối hai đoạn thay vì tăng đoạn theo endpoint; kiểm cùng pha ở 128 và 48 px |
| P2 | Áo chuyển nguyên mảng với thân, không phản ứng khi chân nhấc | Mesh UV gốc, vùng dưới đai chuyển theo gối và sway trễ; cổ/đai không biến dạng |
| P2 | Hai đường thêu vàng trước vạt và vòng đai cạnh thân nổi như dây; nếp áo chỉ là nét | Thêu cùng sắc vải, đai vải dịu, nếp gấp dạng mặt có bóng sát đai; giữ nguyên hình gốc |
| P2 | Bàn tay chỉ là oval một màu | Thêm nét ngón/đường gấp trong alpha cũ, giữ tâm grip/tay phóng |

Snapshot baseline: artifacts/baseline_v17. Đối chiếu PNG frame065 cùng thời gian/hướng của directional capture, không dùng ảnh minh họa dựng lại. Các log/capture cuối nằm trong evidence sau khi handoff hoàn tất.

## Phạm vi kiểm chứng

Sáu acceptance mới kiểm các giới hạn giải phẫu và mesh vải trên ba vũ khí × tám hướng × 11 hành động × 61 pha. Giữ các guard về khớp tay đổi hướng, depth, contact liên tục, hồi đòn, moving cast, giảm chuyển động, pause và authority. 131 alpha/dim SVG phải khớp baseline 0.15, không sửa golden để hợp kết quả mới.

Duyệt native gồm F6/world/F3 ở 960 và 1280, sheet tám hướng và động tác/vũ khí; 240 frame turn, 180 frame profile, 600 frame world/F6 và các clip gameplay khác. Lấy mẫu 60Hz phục vụ review, không đo FPS.

## Quan sát native bản cuối

Đã xem sheet tám hướng, sheet pha đánh ba vũ khí, F6 nữ/thương, gameplay 1280, profile frame030, turn Tây frame135 và cùng phase Nam frame065 so baseline 0.17. Chân trước ngắn hơn, vạt theo bước giữ liên tục với đai, nét thêu bớt chói và không thấy đường nối mesh trong các ảnh đã xem. Mặt/tóc/áo vẫn nhận ra là mẫu cũ; tay và grip giữ đúng lớp. Ở kích thước 48 px, chi tiết nếp/ngón tay chỉ đóng vai trò sắc độ, không nên xem chúng là chi tiết rõ độc lập.

519/519 assertions đạt trên Windows và Linux. Các harness native hoàn thành đủ 17 ảnh, 96/144/600/180/240 frame; cold import/portability xác nhận đủ asset. Gate kỹ thuật của phạm vi sửa đạt; đánh giá mỹ thuật vẫn có các giới hạn bên dưới.

## Giới hạn cho bản phát hành

Đây là pass làm đẹp mẫu cũ, chưa phải xác nhận đồ họa production. Đầu và áo vẫn có tám view vẽ sẵn: chuyển hướng của khớp liên tục nhưng silhouette mặt/tóc đổi ở mốc góc. Nét outline/họa tiết có thể vẫn dày ở 48 px và cần duyệt thêm trong cảnh đông. Map/props/sói vẫn dùng atlas pixel hiện có. Chưa có đánh giá FPS dài hạn, nhóm người chơi ngoài đội hay duyệt mỹ thuật phát hành.

Tham khảo nguồn cửa hàng Steam được ghi ở art-direction-0.18.md; các lựa chọn tỉ lệ, nếp vải và nhịp chân là thiết kế cho bộ hình hiện tại, không tuyên bố tái tạo animation của game tham khảo.
