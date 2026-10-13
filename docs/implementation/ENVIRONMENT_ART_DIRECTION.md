> Cập nhật 0.11: tài liệu này mô tả pipeline 0.10 trước khi chuyển sang pixel 2D. Runtime hiện tại theo [PIXEL_2D_MIGRATION_PLAN.md](PIXEL_2D_MIGRATION_PLAN.md).

# Hướng hình ảnh môi trường — 0.10

Mục tiêu của lượt này là thay nền hình thoi và cây ghép đa giác bằng môi trường võ hiệp có vật liệu, khối sáng và đường dẫn rõ tại camera chơi thực tế. Hình ảnh là lớp trình bày; vị trí, vật cản, tìm đường, line-of-sight và vùng an toàn vẫn do `WorldGrid` quyết định.

## Nền liên tục

`GroundView` dựng một hình thoi phủ đúng phạm vi 28 × 28 ô. UV theo tọa độ logic của thế giới, không theo từng ô, nên đường nối hình thoi không còn xuất hiện trong artwork. Atlas raster 2 × 2 gồm cỏ, đá lát, đất và đá/rêu; shader trộn giữa tâm đường lát đá, lề đất và đồng cỏ bằng khoảng cách liên tục. Đường dọc, đường ngang và sân điện giữ vị trí có sẵn. Màu biên rừng tối hơn để nhân vật và hướng di chuyển dễ đọc.

Tám pixel inset ở từng vùng atlas tránh lấy màu sang vùng kế bên. Tọa độ texture được phản chiếu tại ranh giới lặp để hai mép dùng cùng texel, kể cả khi ảnh gốc không phải texture seamless. Những cụm cỏ nhỏ nằm dưới toàn bộ actor, không thêm vật cản. Vòng trại vẫn biểu diễn đúng bán kính logic hai ô.

## Props và độ sâu

`PropView` dùng atlas có alpha thật cho hai loại cây, cụm đá và di tích đá. Mỗi vùng được cắt theo alpha dùng được, không theo khung trắng. Bản sao texture runtime có mipmaps dùng chung để chất lượng scale-down không phụ thuộc file thiết lập import có được đóng gói hay không; cây có biến thể lật ngang và tỉ lệ vừa phải. Kích thước và gốc chân được chuẩn hóa theo camera hiện tại; `position` vẫn là `WorldGrid.project(cell)` để thứ tự Y-sort của actor và props không đổi. Bóng tiếp xúc mềm gồm nhiều ellipse mờ, không thêm node xử lý hay collider.

Cây được vẽ bằng một lệnh texture, nên chế độ che khuất hiện có của `WorldView` làm mờ cả tán và thân cùng lúc. Cây đứng yên không chạy `_process`. Giảm chuyển động vẫn tắt nhấp nháy đèn và hạt di tích.

Tường dùng texture đá thực của atlas nền kèm vát cạnh và khe gạch; cột/di tích dùng artwork raster. Đèn có trụ gỗ, chao lụa đỏ, xương chao và lõi sáng ấm. Vật tương tác giữ glyph để dễ nhận diện tại kích thước gameplay.

## Hợp đồng tài nguyên và kiểm chứng

- Atlas nền: `assets/environment/wuxia_terrain_v10.png`, bốn phần bằng nhau, thứ tự cỏ / đá lát / đất / đá rêu.
- Atlas props: `assets/environment/wuxia_props_v10.png`, bốn phần bằng nhau, thứ tự cây tán rộng / thông / đá / di tích cột.
- `GroundView.terrain_style_at(cell)` cung cấp trọng số grass, stone, dirt, rock hữu hạn, chuẩn hóa về tổng 1.
- `PropView.art_source` là vùng pixel trong atlas; `art_bounds` là khung vẽ địa phương so với gốc chân. `uses_painted_art()` chỉ trả đúng khi tài nguyên đã được nhập và có vùng vẽ thật.

`environment_art_tests.gd` kiểm tra tài nguyên PNG thực, hình thoi liên tục, UV, trọng số vật liệu, lề đường, bốn vùng props, alpha trong suốt, khoảng đệm bên trong mỗi phần atlas để tránh cắt tán cây, mipmaps portable, cache dùng chung, gốc chân, khả năng làm mờ, reduced motion và việc không đổi dữ liệu navigation. Chất lượng hình ảnh cuối phải được xem lại ở game native; số test đạt không tự chứng minh hình ảnh đã đạt chất lượng phát hành.

Artwork raster còn cần được đánh giá về bố cục, tỉ lệ và tính đồng nhất khi có thêm bản đồ. Atlas hiện tại là hướng nghệ thuật có thể dùng và chỉnh tiếp; chưa thay thế một bộ asset phát hành đầy đủ, nhiều biến thể hoặc đo hiệu năng trên mọi thiết bị mục tiêu.

## Sói — vector nguyên bản và gait có khớp

`GuWolfPainter` thay thân/head đa giác cứng bằng silhouette cong được nội suy từ các điểm vẽ nguyên bản. Lưng, bụng, hông, vai, bờm, mõm dài, hai tai, mắt và đuôi có lớp bóng/lông riêng. Màu coat của actor vẫn quyết định toàn bộ bộ lông và hit flash. Hình giữ phạm vi xấp xỉ 63 × 36 pixel thế giới để không thay kích thước tương tác hoặc vị trí thanh HP.

Hàm `draw(canvas, coat, leg, stride, motion, windup)` chạy bên trong transform flip/bob/lunge sẵn có. Bốn chân được vẽ theo thứ tự xa → thân → gần; mỗi chân có hip, knee, hock/ankle và bàn chân. Các cặp chéo trước/sau luân phiên bước, có pha nhấc chân và gập hock. Đuôi cong theo stride; windup làm hạ/chồm đầu nhẹ. Đây là chuyển động các phần cơ thể, không dịch một ảnh tĩnh nguyên khối. Transform actor, telegraph, selection, HP, frost và sát thương tiếp tục thuộc actor/authority.

Helper là artwork vector có thể chỉnh bằng code, chưa phải rig bốn chân 3D hoặc atlas nhiều góc nhìn. Nó cải thiện trực tiếp silhouette ở camera gameplay hiện tại; mô hình sinh vật đa hướng và bộ animation phát hành có thể thay helper sau này mà vẫn giữ hợp đồng actor.
