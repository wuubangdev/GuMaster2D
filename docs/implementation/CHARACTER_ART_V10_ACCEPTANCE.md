# Nghiệm thu hình ảnh — đợt 0.10

Ngày bắt đầu: 08/10/2026. Người dùng đánh giá hình ảnh 0.9 vẫn sơ sài và yêu cầu chất lượng nhìn gần production hơn. Đây là yêu cầu nâng chất lượng hình ảnh thực tế. Số lượng test và việc có nguồn Blender không xác nhận model đã đạt chất lượng phát hành.

## Baseline được xem trực tiếp

Ảnh native 0.9 đã xem trước khi cập nhật: `character_studio_male.png`, `wardrobe_weapon_rear.png`, `windows_first_playable.png`. Bản baseline được giữ riêng tại `artifacts/baseline_v09/character.png`, `rear.png` và `gameplay.png`; các đường dẫn capture chính được cập nhật cho lượt 0.10.

| Vấn đề nhìn thấy | Ưu tiên sửa | Điều kiện review lại |
|---|---|---|
| Tay áo gần hình trụ, vai và cổ như các bộ phận ghép rời | Cao | Vai/tay áo nối tự nhiên; chuyển tiếp dưới nách không có khối nổi hoặc lỗ khi đứng, chạy, đánh và thủ |
| Mặt có cảm giác mặt nạ: ít cấu trúc ổ mắt, mũi và miệng | Cao | Kiểm góc thẳng, nghiêng và ngang dưới cùng ánh sáng; không dùng vật liệu tối để che lỗi hình khối |
| Tóc là mũ chụp với đuôi chữ nhật | Cao | Có phân mảng tóc, đường tóc và độ cong, silhouette đọc được từ phía sau và hai bên |
| Áo choàng gần tấm bảng, hoa văn và viền không tạo chiều sâu vải | Cao | Vạt có nếp và độ cong lớn; viền theo cùng biến dạng; không xuyên chân trong pose tiêu biểu |
| Cây hình nón lặp lại, mặt đất lộ lưới ô đều và đá/đèn như khối dựng tạm | Cao | Ground/props dùng art có sắc độ, bề mặt, biến thể và bóng tiếp đất; hero không bị nuốt vào nền |
| Sói là polygon nhỏ rất đơn giản | Trung bình | Cần được ghi là hạn chế còn lại nếu chưa nâng cấp trong đợt này; không gọi toàn bộ đồ họa là production |
| Cận cảnh F6 khá rõ nhưng chi tiết nhỏ mất ở gameplay | Cao | Xem cả F6 và gameplay ở độ phân giải thực, cùng camera/zoom để đánh giá tương quan nhân vật/nền |

## Gate tích hợp

| Gate | Cách kiểm | Giới hạn |
|---|---|---|
| Dữ liệu mesh/material | UV, normal, tangent và skin weight hữu hạn, đúng kích thước; index và bind hợp lệ; texture có dữ liệu biến thiên thật | Không thay thế review silhouette hoặc bake/sculpt của artist |
| Asset chạy thật | Baked asset được nạp vào model đang dùng; bộ xương và thư viện đúng vũ khí; animation vẫn chạy; fallback vẫn hoạt động | Chỉ giao GLB trong thư mục chưa đủ đạt gate |
| An toàn tích hợp | Model đổi ngoại hình không đổi vị trí/stats/inventory/progression; profile round-trip giữ đúng cosmetic; input WASD và dãy số không đổi | Chạy isolated test-mode; không chạm profile người chơi |
| World art thật | Runtime prop/ground có texture hoặc atlas thật, alpha hợp lệ và biến thiên màu; Y-sort, pivot và che khuất cây vẫn đúng | Không lấy file tồn tại thay cho scene wiring/render thật |
| Native review | F6 thẳng/chéo/ngang/sau; sword/spear/unarmed, nam/nữ; gameplay và chuyển động | Root capture tuần tự; không mở cửa sổ native cạnh tranh focus |

## Trạng thái

Implementation và ảnh native 0.10: **đã kiểm độc lập sau lượt asset/capture cuối**. Baseline 0.9 chưa đáp ứng mong muốn mỹ thuật của người dùng dù suite cũ đạt 430/430; lượt 0.10 có cải thiện hình ảnh rõ ràng và được chấp nhận là art candidate nâng cấp. Đây chưa phải nghiệm thu final art production.

Test mới: `tests/production_art_tests.gd`, gồm 19 gate và một guard xác nhận đủ gate chạy hết. Lời gọi từ runner: `await preload("res://tests/production_art_tests.gd").run(self, check)`. Test kiểm trực tiếp 36 resource runtime và từng `MeshInstance3D.mesh` đang dùng đúng mesh trong resource; không chỉ dựa vào trường ghi tên đường dẫn. Fallback authoring được kiểm riêng. Quy trình không ép asset artist phải có cùng geometry với generator. Triangle không suy biến phải có winding mặt trước cùng hướng với normal shading theo quy ước clockwise của Godot.

Probe sơ bộ trước khi bake mới: 6 gate dữ liệu mesh/material và 4 gate cosmetic/profile/authority đạt; gate actor dùng baked asset chưa đạt vì bộ resource 0.10 đang được xây dựng. Đây chưa phải kết quả cuối. Image sampling dùng stride nguyên tố để không vô tình chỉ lấy một pha của vân vải lặp. Độ biến thiên pixel ở đây là kiểm dữ liệu đọc được, không phải thang điểm chất lượng texture.

Sau khi resource runtime và PNG environment được đưa vào project, probe độc lập đạt **20/20** (19 gate + completion guard), không có parse/runtime error hoặc leak khi thoát. Bản bake và capture còn được cập nhật theo review mỹ thuật; kết quả này phải chạy lại trong suite đầy đủ sau lần sửa cuối.

Nguồn cây/đá PNG đã xem: hình khối và bề mặt có chi tiết hơn đáng kể. Các vệt RGB đỏ ở nền trong suốt khi xem ảnh có alpha tối đa 4/255, không có pixel đỏ opaque, nên phải đánh giá halo trong render native. Lỗi cần sửa thật là tán cây vượt đường chia 2×2 atlas, gây cắt canopy khi runtime lấy từng quadrant. Suite environment có gate khoảng trống giữa các cell để bắt lỗi này.

## Review các capture đang phát triển

Lượt F6 đầu 0.10: đường tóc và tay áo có độ cong tốt hơn, nhưng áo bị các mảng trắng răng cưa, mặt sáng như mặt nạ, cape sau phẳng và vài khe giữa vai/cổ. Kiểm source cho thấy torso cũ màu ivory rộng hơn tunic mới và có envelope skinning khác, nên xuyên qua áo. Một lỗi khác là tâm nắp UpperArm không dùng độ dịch vai cùng với vòng vertices, có thể tạo tam giác da kéo dài lộ ở vai nữ.

Lượt `wardrobe_weapon_idle.png` sau sửa winding và thu nhỏ inner anatomy: màu và shading vải rõ hơn; các mảng trắng ở thân biến mất. Ba kiểu áo nhìn phân biệt được, đường chéo lapel và tấm giáp nhỏ bớt cảm giác các khối ghép. Vai nữ vẫn còn vài mảng da lộ cần sửa thêm; mặt và cape cần review sau khi có vật liệu và geometry cuối. Không nghiệm thu mức production chỉ từ lượt ảnh này.

Probe geometry độc lập đã bắt sai số UNORM16: tổng skin weight tại cloth_dark vertex 878 (nam Thanh Ngọc) là 0,99996948079206, lệch hơi vượt ngưỡng 2/65535. Generator đã phân bổ rounding residual theo tổng 65535 đơn vị; toàn bộ 36 tổ hợp qua gate geometry cũ mà không nới tolerance.

## Nghiệm thu lượt cuối

Đã xem `windows_first_playable.png`, F6 nam/nữ, rear/side, `wardrobe_weapon_attack.png` và `wardrobe_weapon_defend.png` sau capture tuần tự. Các ảnh là runtime native cùng asset đang dùng trong game, không phải concept art thay cho render.

| Hạng mục | Đánh giá cuối | Giới hạn còn lại |
|---|---|---|
| Forest/ground/props | Cải thiện rõ: cây và đá có bề mặt, đường đá hòa vào đất/cỏ, không còn lưới tile thô hoặc mảng đen ở mép map. Atlas mới có khoảng trống giữa bốn cell, tán cây không còn cắt theo quadrant | Chưa benchmark cảnh lớn hoặc nhiều NPC trên Web/thiết bị yếu |
| Vai/cổ/thân | Vai nối vào thân tự nhiên hơn; các mảng ivory răng cưa ở torso và các mảng da lộ bất thường ở vai đã được xử lý trong ảnh cuối | Pose nâng tay cực trị vẫn cần artist chỉnh weight/corrective shape để giảm cảm giác mặt phẳng gãy |
| Mặt/tóc | Silhouette đầu/tóc rõ hơn; mắt/mũi/mí và đường tóc bớt cảm giác mặt nạ; tóc đuôi ngựa cong theo phía sau đầu | Mặt vẫn stylized và ít chi tiết; chưa có manual sculpt/texture paint hoặc retopology đã được artist duyệt |
| Ba trang phục | Nhận biết được áo gọn Thanh Ngọc, giáp nhẹ Xích Vân và áo dài/tay rộng Bạch Vũ. Cổ áo, viền và nếp/vân vải hỗ trợ hình khối | Nếp cape ở giữa lưng còn nhẹ/phẳng; chi tiết vải khá nhỏ khi thu về gameplay zoom |
| Animation/vũ khí | Attack/defend có pose khác cho kiếm, thương hai tay và tay không; không thấy mất phần body/vũ khí ở các capture đã xem | Skinning/tiếp xúc fingers ở cực trị cần artist review thêm, không suy ra từ việc FK cổ tay đạt tolerance |
| Sói và art consistency | Outline, thân/chân và đuôi cong hơn polygon placeholder cũ; hòa vào cảnh tốt hơn | Quái vẫn có mức chi tiết thấp hơn cây/đá được vẽ, nên chưa gọi toàn bộ art là final production |
| Pipeline thực dùng | Mặc định nam Thanh Ngọc/kiếm dùng resource chuyển từ `artist_roundtrip_male_sword.glb` qua Blender re-export; các tổ hợp khác dùng mesh resource baked. Live actor dùng đúng mesh từ resource, cùng rig/clip | Blender round-trip chứng minh khả năng chỉnh/import source; không chứng minh đã có một sculpt artist hoàn chỉnh |

Probe riêng `production_art_tests.gd` sau asset cuối đạt **20/20**, log sạch, gồm winding và guard đủ 19 gate. Suite đầy đủ đạt **472/472 trên Windows** và **472/472 trên Linux**; log `artifacts/windows_tests.log` và `artifacts/linux_tests.log` đều không có parse/runtime error. Bằng chứng nguồn artist dùng thật: `artifacts/character_artist_integration.log` có `CHARACTER_RUNTIME_ARTIST_OK` cho resource mặc định; direct-resource checks xác nhận cả 36 appearance dùng mesh packaged thực.

**Kết luận review:** đủ để bàn giao đợt nâng chất lượng 0.10 và tiếp tục phát triển trên một pipeline art có thể sửa/import thật. Không có blocker runtime hoặc lỗi atlas/torso đã quan sát còn tồn tại trong capture cuối. Chặng tiếp theo để đạt final art là artist pass về anatomy, topology, corrective weights, nếp cape, texture paint và mức chi tiết đồng đều của quái/cảnh; test count không thay thế chặng mỹ thuật này.

Không tự gắn nhãn “production-ready”. Một bản art candidate cần thêm review anatomy/topology/weight ở pose cực trị, kiểm art consistency với quái vật/cảnh và benchmark trên cấu hình mục tiêu.
