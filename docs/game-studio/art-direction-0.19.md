# Nét mực và màu giấy — 0.19

Phạm vi người dùng: tối ưu phong cách vẽ, animation và hiệu ứng theo hướng Don’t Starve Together, tiếp tục dùng nhân vật chibi đang có. Giữ 131 silhouette SVG, tám hướng, 11 trạng thái và 36 diện mạo; không nhập tài nguyên của game tham khảo.

## Nguồn và quyết định mỹ thuật

Nguồn chính thức: [Klei — Don’t Starve Together](https://www.klei.com/games/dont-starve-together) và [trang Steam](https://store.steampowered.com/app/322330/Dont_Starve_Together/). Chọn chất minh họa mực, màu đất/giấy, bóng thành mảng, nét gạch, hình hiệu ứng hơi bất đối xứng. Đây là cách diễn giải cho mẫu cũ của dự án. Nhịp animation do dự án thiết kế; chưa đo video/frame-by-frame hay kiểm chứng thời gian animation của DST. Công cụ môi trường hiện đọc được nội dung trang và mô tả ảnh lập chỉ mục, không cung cấp được ảnh/video tham khảo trực tiếp để duyệt từng frame.

| Phần | Quyết định 0.19 |
|---|---|
| Nhân vật | Tóc xám ô-liu, da giấy ấm, áo ngọc trầm/đỏ đất/trắng ngà; chuyển sắc tóc/vải/kim loại thành các dải mảng, giảm cảm giác nhựa bóng |
| Nét | Viền đen ấm dày–mỏng, các flick thuôn trong vùng alpha sẵn có; nét tóc, má, áo, giày và vũ khí cùng bộ màu |
| Shader | Mực bên trong mép SVG, grain nhỏ neo theo texel từng phần. Không dùng TIME/RNG/screen-space; alpha không đổi, đứng yên không nhấp nháy |
| Animation | Tăng nhẹ chuyển trọng tâm và squash thân, tăng độ trễ vạt áo; đầu vẫn ít lắc. Kiếm giữ pose lấy đà từ pha .17 đến .21 rồi ra đòn đến .38; ngắt nhịp thở trong lúc giữ kiếm |
| Biểu cảm | Mắt nhắm ngắn khi lấy đà/trúng đòn, mở lại trước ra đòn/hồi phục. Reduced motion bỏ nhịp biểu cảm phụ |
| Hiệu ứng | 13 kiểu dùng ribbon nét bút có lực, mảng mảnh giấy, ngôi sao lệch bảy cánh, vòng bảo vệ trống giữa; các cung mực mờ thay bloom tròn |
| Môi trường | Grade ấm và nét mép trong trên atlas hiện có; nền F6 màu giấy giúp đọc tóc/viền. Map chưa được vẽ lại thành minh họa |

## Hợp đồng cần giữ

World, HUD, F3 và F6 dùng chung texture/material/rig. Tay phóng, grip vũ khí, contact kỹ năng .28s và phản hồi HP lấy từ pipeline hiện có. Foot contact vẫn hủy quãng đường thân; áo vẫn mesh UV 4×8, cổ/đai cố định. Renderer không thay damage, save, cooldown hay di chuyển.

Grain/viền neo texture tránh nhiễu chạy trên mặt khi camera dịch. Nét VFX neo theo hình học và pha effect, không random trong draw. Viền áp trên alpha sẵn có; không mở rộng silhouette. Ở 48px các nét gạch chỉ đóng vai trò sắc độ; mặt và dáng tổng thể phải đọc được trước chi tiết.

## Giới hạn và hướng kế tiếp

Giữ mặt chibi cũ nên nhận diện vẫn khác các nhân vật dài/góc cạnh của DST. Tám view đầu/tóc còn đổi silhouette ở mốc góc; rig liên tục chưa thành bộ frame vẽ tay đầy đủ. Map/sói vẫn có atlas pixel. Pass này nâng phong cách cho prototype; nghiệm thu phát hành cần art review trong cảnh đông và benchmark máy mục tiêu.

Mã: generator SVG, illustrated_character_art.gd, ink_cutout.gdshader, vector_effects_art.gd và world_effects.gd. Nghiệm thu: [quality-report](quality-report.md), [build review](build-review-0.19.md), [FSD/WBS](../implementation/PIXEL_2D_MIGRATION_PLAN.md).
