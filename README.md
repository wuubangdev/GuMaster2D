# GuMaster2D — Cổ Sư

Game nhập vai 2D bằng Godot, gồm thế giới Cổ Giới, nhiệm vụ, chiến đấu, hành trang và hệ thống nuôi/nâng cấp Cổ. Bản mã nguồn hiện tại: **0.54**.

## Clone và chạy

```sh
git clone https://github.com/wuubangdev/GuMaster2D.git
cd GuMaster2D
```

Dùng **Godot 4.7.2 stable**, renderer **Compatibility**. Import `project.godot` trong editor, chờ nhập tài nguyên rồi nhấn **F5**. Engine không nằm trong repo; mã nguồn và tài nguyên chạy game đã được đưa vào Git, không cần Git LFS.

Nếu Godot có trong `PATH`, có thể import và kiểm thử bằng:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/test_runner.gd -- --test-mode
```

Windows có thể dùng `RunGame.bat` khi đã cài Godot vào `PATH`, hoặc đặt bản portable tại đường dẫn ghi trong file. Trên Linux, dùng `GODOT_BIN=/duong/dan/godot bash tools/run.sh`; thêm các tham số test ở trên để chạy bộ kiểm thử. `--test-mode` dùng hồ sơ riêng, không ghi đè save người chơi.

- [FSD](docs/planning/GuMaster2D_FSD.md), [WBS](docs/planning/GuMaster2D_WBS.md), [kế hoạch dự án](docs/planning/GuMaster2D_Project_Plan.md), [bảng kế hoạch Excel](docs/planning/GuMaster2D_FSD_WBS_Plan.xlsx).
- [Kiểm chứng UI 0.54](docs/game-studio/hud-text-0.54.md) và [phạm vi sẵn sàng production](docs/game-studio/production-audit-0.49.md).
- Xem ảnh review mới nhất: chạy `python3 -m http.server 8879 --directory artifacts`, rồi mở [HUD 0.54](http://localhost:8879/hud54_review.html). Xem [phạm vi ảnh và fixture được lưu trong Git](artifacts/README.md).

Các bản ZIP đóng gói, engine portable, cache và ảnh/video kiểm thử lịch sử được giữ ngoài Git. Những liên kết localhost và ảnh lịch sử ở changelog phía dưới là ghi chép của quá trình phát triển; chỉ bộ review 0.54 cùng các fixture cần thiết được kèm trong repo.

## Cập nhật 0.54 — Chữ trong ô vật phẩm và bảng Cổ

Tách số lượng đồ khỏi hình và viền chọn; thay chữ tọa độ cố định bằng nhãn có lề trong ô kỹ năng và danh sách Cổ. Nới lề nút, khung giấy và cỡ chữ lọc hành trang. Trang hành trang cũ đã trỏ sang ảnh UI 0.54.

Kiểm **78/78 bố cục**, **632/632 vùng chữ/trạng thái**, **49/49 hành trang**, **63/63 bảng Cổ**, **911/911 hồi quy** và **60/60 browser**. [Hành trang hiện tại](http://localhost:8879/inventory51_review.html?v=54) · [So sánh HUD](http://localhost:8879/hud54_review.html) · [Chi tiết](docs/game-studio/hud-text-0.54.md).

## Cập nhật 0.53 — Khoảng đệm chữ và viền HUD

Nút đo chữ và giữ lề 12×6 px; khung giấy chừa 16 px cho nội dung. Sửa nút lọc túi bị co sát chữ, tăng khoảng trống thanh HP/chân nguyên và dòng trạng thái kỹ năng, cho thông báo dài xuống dòng. Hành trang và bảng nhân vật giữ khoảng cách với thanh kỹ năng.

Kiểm **78/78 UI native Windows**, **49/49 hành trang**, **63/63 bảng Cổ**, **911/911 hồi quy game** và **31/31 trang review**. Có 24 ảnh tại ba độ phân giải từ 960×640 đến 1920×1080.

[Xem HUD và ảnh trước/sau](http://localhost:8879/hud53_review.html) · [Thay đổi và kiểm chứng](docs/game-studio/hud-spacing-0.53.md).

## Cập nhật 0.52 — Giao diện cường hóa và nâng bậc Cổ

**G → chọn Cổ → Cường hóa / Nâng bậc**. Danh sách có Cổ trang bị và dự trữ, tranh riêng cho bốn loại Cổ; xem chỉ số hiện tại → kết quả, nguyên liệu có/cần và lý do khóa nút. Cường hóa mức 1–5; nâng bậc I → II → III chọn rõ phôi và xác nhận giá tiêu hao, giữ Cổ chính/ô kỹ năng.

Chỉ số dùng chung phép tính với skill thật, có giới hạn khiên và hồi chiêu. Kiểm **25/25 logic trên mỗi nền tảng Linux/Windows**, **120 cast thật trên mỗi nền tảng**, **63/63 UI native Windows**, **911/911 hồi quy toàn game** và **19/19 trang review**.

[Xem giao diện và ảnh trước/sau](http://localhost:8879/gu52_review.html) · [Thiết kế, công thức và kiểm chứng](docs/game-studio/gu-upgrade-0.52.md).

## Cập nhật 0.51 — Bảng thao tác hành trang

**Tab/F4 → chọn vật phẩm hoặc chuột phải** để xem thông tin, dùng, chế tạo và xóa. Thức ăn cho chọn Cổ cần nuôi; nâng/hợp Cổ mở đúng Cổ đã chọn. Ba công thức vật phẩm có nguyên liệu, bạc, số lượt và sản phẩm thật.

Kéo vào ô trống hoặc lên vật phẩm khác để đổi chỗ, có lưu bố cục. Xóa xác nhận tên/số lượng, bảo vệ Cổ đang khảm và từ chối nếu túi đã thay đổi. Kiểm **40/40** logic trên mỗi nền tảng Linux/Windows, **49/49** UI native Windows, **911/911** hồi quy toàn game và **19/19** trang review.

[Xem UI hành trang](http://localhost:8879/inventory51_review.html) · [Thiết kế, công thức và kiểm chứng](docs/game-studio/inventory-0.51.md).

## Cập nhật 0.50 — Minimap gọn và địa đồ lớn

Bỏ khung giấy dài quanh minimap; viền chỉ ôm địa hình, đường/nước và dấu vị trí rõ hơn. Tọa độ **X/Y** và **tám hướng nhìn** hiện riêng phía dưới. Nhân vật giữ giữa bản đồ khi di chuyển.

**Bấm minimap, nút ↗ hoặc F2** mở địa đồ lớn; **Esc/F2** đóng. Chọn bãi/trạm/NPC rồi **T** để xem dẫn đường và dịch chuyển. Mở map dừng đường đi cũ.

[Ảnh trước/sau và bản đồ lớn](http://localhost:8879/minimap50_review.html) · [Thiết kế và kiểm chứng](docs/game-studio/minimap-0.50.md). **68/68** kiểm native Windows, **911/911** hồi quy toàn game và **12/12** kiểm trang review.

## Cập nhật 0.49 — Quái, minimap, hành trang và thiết lập

Quái thường gọn hơn khi đứng cạnh nhân vật; khớp gối, bàn chân và bóng được chỉnh theo từng loài. Minimap hiện tọa độ/hướng, bấm để mở địa đồ lớn. Hành trang hỗ trợ chuột phải, cho Cổ ăn, mở bảng nâng cấp, xác nhận xóa và kéo đổi thứ tự có lưu. Menu Esc có âm lượng, độ phân giải và chế độ cửa sổ/toàn màn hình; bố cục đã kiểm ở 960×640 và 1280×800.

[Rà soát mức sẵn sàng production](docs/game-studio/production-audit-0.49.md) · [Ảnh so tỷ lệ 8 loài × 8 hướng](artifacts/production49_beast_idle.png) · [Minimap 960×640](artifacts/production49_hud_960.png) · [Settings 960×640](artifacts/production49_settings_960.png).

Kiểm: **911/911** hồi quy Linux sau phần UI/túi; **170/170** logic/quỹ đạo chân quái trên Linux và Windows; **29/29** tương tác/bố cục mới trên mỗi nền tảng. Các việc ô Cổ 5–8, duyệt nhân vật nữ và xây dựng bí cảnh còn trong danh sách ưu tiên của báo cáo.

## Cập nhật 0.48 — Tay, chân và nhịp chuyển động

Mở tư thế lấy đà kiếm/cuốc, sửa khuỷu tay nhảy khi thi triển và trục thương đổi góc đột ngột. Chân hướng trước/sau co theo chiều sâu; quần bám đúng đầu gối và cổ giày. Chân trụ giữ theo khoảng di chuyển thật của nhân vật, đổi đi/chạy/dừng có bước thu chân riêng.

Kiểm **911/911** hồi quy, **76.800** mẫu điểm nối kín trên Windows và **766/766** kiểm trang review; 2.494 frame native.

[So sánh chuyển động và soi từng frame](http://localhost:8879/concept48_character_review.html) · [Thiết kế và cách kiểm](docs/game-studio/character-motion-0.48.md) · [Bằng chứng cuối](artifacts/concept48_delivery.json).

## Cập nhật 0.47 — Nét vẽ nhân vật

Tay áo, băng cổ tay, quần và giày có mảng sáng–tối và nét gấp thuôn, đồng bộ hơn với đầu và áo thân theo concept. Viền ở mép khuất đậm hơn, các nét quấn cong theo bề mặt; áp dụng cho cả nam/nữ và tám hướng. Giữ điểm nối và đường co vải của bản 0.46.

Bộ lọc theo kích thước pixel giảm lấp nhấp ở tóc và chi tiết nhỏ, chặn lem màu giữa các ô atlas. Trang mới đối chiếu **0.46 / 0.47 ở cùng pose**, có cận cảnh và cỡ cấu hình trong game, xem được từng frame chuyển động Godot.

[So sánh nét vẽ và chuyển động](http://localhost:8879/concept47_character_review.html) · [Thiết kế và kiểm chứng](docs/game-studio/character-ink-0.47.md) · [Kết quả cuối](artifacts/concept47_delivery.json).

## Cập nhật 0.46 — Gắn nhân vật theo từng hướng

Làm hướng xuống trước, sau đó lần lượt kiểm bảy hướng còn lại, cả nam và nữ. Bộ chi tiết có xương tư thế gốc, điểm may vai và đường co vải riêng cho từng góc; tay áo bo gọn, co theo khuỷu, bàn tay và vũ khí giữ cùng điểm bám. Đầu và hoa văn áo giữ nguyên concept.

Kiếm, hái lượm và khai khoáng có mốc tay/thân riêng theo hướng. Thế đỡ gạt kiếm ra ngoài để tránh che mặt; tư thế cúi được giới hạn theo chiều dài chân thật. Xưởng xem mới tách ba lớp **xương → asset trên xương → hình hoàn chỉnh**, có đối chiếu trước/sau và dừng từng frame Godot.

[Xưởng xem tám hướng](http://localhost:8879/concept46_character_workshop.html) · [Thiết kế và cách kiểm](docs/game-studio/character-direction-fitting-0.46.md).

Kiểm **906/906 hồi quy**, **124/124 chuyển động trên Linux và Windows**, **248/248 thu thập**; đủ 1.248 ảnh/frame native. [Kết quả chi tiết](artifacts/concept46_delivery.json).

## Cập nhật 0.45 — Đại vực, Cổ thuật và dị thú

- **Ba map 256×256 ô**, mỗi vùng 8.192×8.192 đơn vị, diện tích **7,11 lần bản 0.44**. Có **64 bãi farm, 351 quái, 33 trạm và 176 nguồn tài nguyên**, đường vòng và cầu qua sông; giữ khu nhập môn và nhiệm vụ cũ.
- **Bốn tranh Cổ mới** dùng chung trên thanh skill, túi và bảng **G**; hiệu ứng cánh nguyệt điệp, giáp cánh ngọc, lông hạc và kén tằm theo đúng nhịp thi triển.
- **Tám loại quái** có khớp chân, dáng trước/sau/ngang, lấy đà, ra đòn, hồi thế và gục; mỗi loại có hai đòn luân phiên với vùng báo nguy. Sói nhập môn dùng hình mới, giữ luật chơi cũ.
- Địa hình/cây/đá/nước chỉ dựng gần camera. **T** chọn bãi để dẫn đường; khám phá trạm xa trước khi dùng dịch chuyển. Hồi sinh xa đưa camera về trại ngay.

[Ảnh game và địa đồ](http://localhost:8879/world45_review.html) · [Chuyển động quái](http://localhost:8879/beast45_review.html) · [Hình Cổ và hiệu ứng](http://localhost:8879/gu45_review.html) · [Phạm vi, thiết kế và kiểm chứng](docs/game-studio/world45-expansion.md).

Kiểm Linux: **906/906 hồi quy**, **151/151 scene map**, **437/437 địa lý**, **887/887 cơ chế thế giới**; các bộ quái, Cổ, quest và điền viên đều đạt. [Báo cáo đầy đủ](artifacts/world45_delivery.json). Mật độ farm và phần thưởng còn cần playtest cân bằng dài hơn.

## Cập nhật 0.44 — Vải liền khớp và tỷ lệ nhân vật

Vẽ lại 352 chi tiết tay áo, quấn tay, bàn tay, quần và giày theo tỷ lệ đầy đặn hơn của concept. Vải có mesh biến dạng quanh khớp; cẳng tay tách lớp dưới cửa tay áo / trước tay áo khi gập, bàn tay và giày giữ cứng. Đầu và hoa văn thân giữ bản gốc.

[So sánh trước/sau cùng tư thế và xem sáu animation](http://localhost:8879/concept44_character_review.html) · [Kiểm chứng](docs/game-studio/quality-report.md). **714/714** hồi quy và **19/19** input E/F6. Skill `godot-2d-animation` đã được cài vào thư viện skill của máy.

## Cập nhật 0.43 — Chuyển động tác và giữ chân trụ

Sửa chân trượt khi thu tay, giải lại gối theo đúng góc đang vẽ khi xoay người. Kiếm/cuốc chuyển ở nhịp chuẩn bị và thu tay; ngắt khai khoáng vẫn giữ cuốc bám bàn tay trong lúc chuyển, không bật lớp tay lên mặt.

[Xem bốn chuỗi chuyển động, nam/nữ và tám hướng](http://localhost:8879/concept43_transition_review.html) · [Kiểm chứng và giới hạn](docs/game-studio/quality-report.md). Có phát chậm, kéo từng frame và mốc xương; hình được chụp từ renderer Godot thật.

## Cập nhật 0.42 — Nhịp kiếm và thu thập

Kiếm dùng cùng nhịp lấy đà/ra đòn/thu tay trong game và F6; Nguyệt Nhận phóng từ bàn tay ở mốc vung kiếm. Phím **E** bên cạnh tài nguyên chạy **Hái lượm / Khai khoáng**, cuốc bám grip, chân trụ ổn định; đi lại hoặc bị đánh ngắt động tác. F6 thêm hai động tác mới.

[Xem chậm từng góc và từng frame](http://localhost:8879/concept42_action_review.html) · [Nguồn Klei, thiết kế và kiểm chứng](docs/game-studio/character-action-motion-0.42.md). Đạt **693/693** hồi quy, **19/19** kiểm native E/F6, 9.312 pose thu thập, 115 ảnh Godot và 48 trạng thái browser. Nhân vật tiếp tục dùng rig/art concept hiện hành; chưa nghiệm thu mỹ thuật hoặc FPS Windows ở mức phát hành.


## Cập nhật 0.41 — Chi tiết nhân vật theo hướng

Tạo riêng **352 SVG cho nam/nữ × 8 hướng**, rồi liên kết với khung xương: vai nối, tay áo xòe, cẳng tay, bốn trạng thái bàn tay, đùi/cẳng chân và giày. Phần khuất ở các khớp được vẽ kín; cửa tay đi theo áo, lớp quấn cẳng tay nằm dưới. Vai nối đo đến thân theo từng hướng; cẳng tay nhìn từ sau không hiện xuyên lên lưng. Đầu và trang trí thân giữ concept gốc.

[Xem asset → ghép xương → từng frame](http://localhost:8879/concept41_character_review.html) · [Hợp đồng asset, kiểm chứng và giới hạn](docs/game-studio/concept-directional-parts-0.41.md). Kiểm **636/636** hồi quy, 12.512 pose và 198 ảnh native. Hoạt ảnh vẫn dùng rig; độ đồng nhất mỹ thuật cần tiếp tục duyệt.


## Cập nhật 0.40 — Ba đại vực và tuyến truyền thừa

- **Ba map 96×96 ô**: Thanh Mao Sơn, Tam Vương Cổ Địa, Thanh Nang Phúc Địa; mỗi vùng rộng **11,76 lần diện tích cũ**. Đường nối bãi, trúc/cột vỡ, sông–đầm có cầu, 32 điểm tài nguyên và 9 trạm khám phá.
- **16 bãi farm / 8 loại quái / 93 cá thể**: sói, lợn, nhện, ong, cóc, giáp trùng và hai loại đầu lĩnh. Ba cách đánh có báo trước: cận chiến, lao, phun vùng; loot và thời gian hồi riêng.
- **18 quest (10 chính, 8 phụ), 7 NPC**: tông tộc → lang triều → truyền thừa → khôi phục linh mạch. Quest giao đồ tiêu hao thật; thưởng mở trạm nội vùng, dược phương **R** và tưới toàn bộ ruộng **H**.
- **T** xem bản đồ trong vùng / sang vùng khác; chọn bãi xem loot và dẫn đường. **F11** lọc chính/phụ, **E** NPC hoặc tài nguyên. Nhân vật concept hiện hành giữ nguyên, save cũ được hỗ trợ.

Bắt đầu bằng **Lời dặn dưới đèn** tại Lâm An, sau đó **Đường qua rừng trúc**. Bãi phía đông nam có đầu lĩnh; nâng Cổ và quan sát vùng báo đòn trước khi tới.

[Ảnh ba map và 18 quest](http://localhost:8879/world40_review.html) · [FSD, WBS, cốt truyện và giới hạn](docs/game-studio/world-expansion-0.40.md). Kiểm Linux: **1211/1211**, gồm 413 thế giới, 76 quest, 60 điền viên, 49 native và 613 hồi quy. Game vẫn là prototype PC, chưa nghiệm thu cân bằng/mỹ thuật phát hành.

## Cập nhật 0.39 — Người giữ trại và nhiệm vụ đầu

- **4 NPC có hội thoại lựa chọn**: Lâm An, Yên Chi, Thẩm Nghi, Mộc Miên. Nhấn **E** khi gần hoặc click NPC; xem lời khuyên, nhận/trả quest, **Esc** tạm biệt. NPC đứng, chớp mắt, quay về người chơi và cử chỉ bằng rig hiện hành.
- **6 nhiệm vụ** nối làm quen trại → chiến đấu/nuôi Cổ → mở Thanh Nang → vụ mùa đầu → chăn nuôi/nâng Cổ. **F11** chuyển tab nhiệm vụ NPC/khảo nghiệm, xem mục tiêu, thưởng và tìm người cần gặp. Dấu **! / ? / …** báo nhận, trả, đang làm.
- **Môi trường**: mái che ở trại, bàn dược thảo, biển chỉ lối, bàn khảo cổ, cờ cổ trận, ao sen và kho nông cụ. Trang trí có chuyển động nhẹ, vật cản che người chơi tự mờ; ao có va chạm.
- Quest lưu cùng nhân vật, hỗ trợ hồ sơ cũ, trả thưởng một lần; túi đầy giữ vật liệu trong hàng chờ.

Chơi thử: ở Vạn Thú Sơn, tìm **Lâm An phía tây trại ngọc** có dấu **!**, lại gần nhấn **E**. Nếu đang ở vùng khác, dùng **T** tại cổng để trở về.

[Kế hoạch và nghiệm thu 0.39](docs/game-studio/quests-environment-0.39.md) · [Ảnh và animation native](http://localhost:8879/quests39_review.html). Kiểm Linux: **613/613 hồi quy, 70/70 quest, 60/60 điền viên, 48/48 native**. Đây vẫn là prototype PC; chưa có lồng tiếng/lịch sinh hoạt NPC hoặc playtest cân bằng dài hạn.

## Cập nhật 0.38 — Cổ giới và điền viên

- **T**: Địa đồ; 3 vùng Vạn Thú Sơn, Tàn Tích Cổ Trận, Thanh Nang Bí Cảnh. Dịch chuyển ở trại/cổ trận, ngoài giao chiến.
- **G**: Bảng Cổ, tu luyện mức1–5 và hợp thành bậcI–III. Công thức hiển thị có/cần, phôi Cổ sẽ tiêu hao; bậc/mức tăng sức mạnh thực chiến.
- **H**: Bí cảnh; 6 đất, linh thảo/linh hoa/linh quả, 2 chuồng linh tằm/linh kê. **E** tương tác gần cổng, tưới/thu cây và chăm vật nuôi.
- Mở Tàn Tích sau1 lần hạ sói. Gom2 cổ tinh ở Tàn Tích, hạ tổng3 sói, đến cổ trận trung tâm rồi phục hồi ấn trong Địa đồ. Nhận hạt khởi đầu, vào bí cảnh qua T.
- Cây cần tưới; thú cần linh quả. Thời gian phát triển chạy khi chơi, dừng khi pause/thoát. Túi đầy giữ sản vật trong hàng chờ. Tiến độ hỗ trợ hồ sơ cũ.

[Yêu cầu, kế hoạch và WBS0.38](docs/game-studio/expansion-0.38.md) · [Ảnh chạy native](http://localhost:8879/expansion38_review.html).


Prototype Godot 2D từ trên xuống, PC trước, cho nhóm 4 người tự phát triển. Bản đầu chơi đơn: di chuyển, chiến đấu bằng 4 Cổ, bắt/nuôi Cổ, khảo nghiệm và lưu tiến độ.

**Nhân vật hiện hành 0.37:** thân sạch theo 16 góc nam/nữ; tách nét tay áo ngoài mask cũ, không giữ tay/chân đứng trên thân. 112 SVG riêng cho thân/vải tay khuất và nếp co/duỗi; năm điểm điều khiển vải mỗi tay, cẳng tay/palm/boots giữ form. [Asset, plan và bằng chứng](docs/game-studio/concept-character-modular-cloth-0.37.md). Regression Linux **613/613**; 2.194 pixel tay áo từng nằm ngoài mask cũ được chuyển sang tay chuyển động, không mất pigment trong vùng kiểm. Concept nguồn giữ nguyên; drawing ngón tay và nếp gập mạnh vẫn cần art review.

**Baseline 0.36:** khép thân dưới tay tới đai/vạt áo, bỏ viền lỗ của tay đứng; tiếp nối đai bị bàn tay che. Tay cầm duỗi qua mục tiêu khi chém ngang; khuỷu ở pha chạm đòn giảm từ khoảng 38° xuống tối đa 13,5°. Lattice tam giác giữ vạt không lật và vẫn theo đúng chân. [So sánh và bằng chứng](docs/game-studio/concept-character-complete-coat-0.36.md). Regression Linux **607/607**; phủ 10.791 pixel nội bộ bị tay che, 0 khe còn hở. PNG nguồn giữ nguyên; nếp gập sâu và phần tay khuất vẫn cần art review.

**Baseline 0.35:** tách vai/tay áo khỏi thân theo 16 hình nam/nữ ở tám hướng; bổ sung phần ngực dưới tay trong đúng biên áo. Hai bên vạt theo hip/stride/lift của chân tương ứng; cổ/đai và grip giữ đúng điểm nối. [So sánh và bằng chứng](docs/game-studio/concept-character-body-panels-0.35.md). Regression Linux **605/605**; 12.529 pixel tách sang tay áo, không mất pixel hoặc còn giữ trên thân trong vùng đã tách. PNG gốc giữ nguyên; nếp gấp sâu và phần vẽ bị che vẫn cần art review.

**Baseline 0.34:** vải tay áo uốn cục bộ theo khuỷu; contour và bridge theo cùng biến dạng, phần áo bổ sung bắt đầu dưới vai. Bracer/palm giữ form, vũ khí/VFX bám grip cũ; mesh và contour được cache. [So sánh, clip và bằng chứng](docs/game-studio/concept-character-soft-sleeve-0.34.md). Regression Linux **600/600**; 11.616 pose tay không lật mesh. PNG gốc giữ nguyên; nếp gập mạnh và kiểu nắm còn cần art review.

**Baseline 0.33:** tay đỡ theo đà kiếm, thu chậm hơn tay cầm và có góc cổ tay riêng; khi đấm, tay còn lại giữ gần ngực. Nối khuỷu chỉ bù phía áo mở, bỏ viền cap phía chồng; màu nối theo pigment tay áo gốc. [Inspector, clip và bằng chứng](docs/game-studio/concept-character-support-0.33.md). Regression Linux **598/598**. Giữ concept gốc; nếp gập mạnh, foreshortening và drawing ngón tay còn cần artwork riêng.

**Baseline 0.32:** palm có khớp riêng tại cuff, grip vũ khí/VFX theo điểm nắm thực, chém liên tục qua contact và bridge hẹp cho source forearm bị thiếu. [Phạm vi và bằng chứng](docs/game-studio/concept-character-palm-0.32.md). Regression Linux **593/593**.

**Baseline 0.31:** ra đòn theo xương native; nội suy vai/góc khuỷu cục bộ, kiếm bám forearm và cổ tay, thương hai tay cùng cán. Sửa khuỷu đảo/kiếm giật góc, bổ sung sleeve bị che khi giơ tay và lớp sau lưng. [So sánh, overlay khớp và clip](docs/game-studio/concept-character-combat-0.31.md). Regression Linux **589/589**; 4.656 combat pose, 976 smooth pose; 144 frame combat × 16 view cùng 352 frame/11 action. PNG concept giữ nguyên; bàn tay/foreshortening vẫn có giới hạn của cutout.

**Baseline 0.30:** bỏ dải/chấm/nét thừa ở sleeve, lọc chi tiết áo khi thu nhỏ; vai dẫn và forearm theo sau. Chân có chuyển trọng lượng/clearance/roll trong swing và lớp xa–gần; sửa grip kiếm nam N bị neo vào pixel đã xóa. [So sánh trước/sau và clip](docs/game-studio/concept-character-sleeve-gait-0.30.md). Regression Linux **581/581**, 352 frame action × 16 view, 256 frame motion/gameplay, 32 ảnh chi tiết và UI 11 trạng thái. PNG concept giữ nguyên; chất lượng toàn bộ animation chưa được nghiệm thu phát hành.

**Baseline 0.29:** lõi viền vector rõ hơn, quần nối theo knee/cuff của từng pose, giày S/N giữ đúng hướng; tay đi/chạy có key riêng. Stride/pelvis sửa để chân đỡ không trượt ở hướng lên/xuống/chéo; vận công và guard sửa grip/layer. [Inspector từng frame, clip và giới hạn](docs/game-studio/concept-character-frame-review-0.29.md). Regression Linux **577/577**, 352 frame của 11 action × 16 view, 11 bảng S/N, 22 ảnh review và 256 frame gameplay/motion; GPU 16 mẫu, UI 11 trạng thái. PNG concept giữ nguyên; chưa phải toàn bộ animation vẽ mới từng frame.

**Baseline 0.28:** contour vector AA, lọc màu theo alpha/ownership trước nội suy, sửa vùng cắt bàn tay/gấu áo và mảnh thừa giày. [Kiểm chứng 0.28](docs/game-studio/concept-character-contours-0.28.md). Regression Linux 569/569.

**Baseline 0.27:** sửa mesh tay áo bị gập ngược; cánh tay trên/cẳng tay quay riêng quanh khuỷu, giữ form bàn tay và grip kỹ năng. Phòng thủ co tay trước ngực, dựng kiếm/thương thay cho dang tay rộng. [Kiểm chứng 0.27](docs/game-studio/concept-character-sleeves-0.27.md). Regression Linux 565/565.

**Baseline 0.26:** cổ/vai/hông bám hierarchy cả khi chuyển tiếp; chuyển hướng qua các drawing 45°, retarget giữ tỷ lệ xương view đang vẽ. Vạt áo neo cổ/đai và không đảo tam giác khi ngã. Kiếm tách đầy đủ khỏi tay/body và phản chiếu góc vung khi đổi bên. [Kiểm chứng 0.26](docs/game-studio/concept-character-motion-0.26.md). Regression Linux 559/559.

**Baseline 0.25:** ownership tách pixel từng bộ phận, dọn nét đất quanh giày; đầu/vai/hông gắn hierarchy, tay/chân dùng độ dài xương nguồn, giày giữ form khi bước. Thêm phần nối nằm dưới tay áo/quần cho vùng bị che trên concept; native grip tiếp tục điều khiển kỹ năng và ghost. [Clip input thật, geometry và giới hạn](docs/game-studio/concept-character-articulation-0.25.md). Regression Linux 547/547.

**Baseline 0.24:** world/HUD/F6 vẽ trực tiếp các phần từ concept 01 và bảng hướng 02 đã duyệt, có hai body × tám hướng. PNG màu giữ nguyên; opacity riêng bỏ giấy nền. F3 mặc định dùng chân dung concept nguyên bản. Đi/chạy/đánh/phòng thủ tiếp tục qua rig liên tục; nón/tóc/thương giữ lớp vector. [Ảnh gameplay, clip và hợp đồng](docs/game-studio/concept-character-runtime-0.24.md). Regression Linux 539/539; chưa nghiệm thu mọi frame hoạt ảnh hoặc phụ kiện giống concept 1:1.

**Điều khiển 0.19:** giữ **W/A/S/D** để đi theo hướng màn hình, thả phím để dừng; **1–4** thi triển bốn Cổ đang khảm (hàng số hoặc numpad). Bấm WASD thay cho đường click; click nền mới thay cho hướng bàn phím đang giữ. Đi chéo cùng tốc độ thế giới, va chạm có trượt theo cạnh trống. Mở cửa sổ, pause, mất focus hoặc chết sẽ xóa trạng thái phím giữ. Các số 5–0 chưa có Cổ gán; bảng phím hỗ trợ đến 10 slot khi mở rộng nội dung.

**Đồ họa 0.19 — Nét mực và màu giấy:** giữ nhân vật chibi cũ, 131 silhouette SVG và bộ khớp. Phong cách tham khảo [Don’t Starve Together / Klei](https://www.klei.com/games/dont-starve-together): viền đen ấm có nhịp dày–mỏng, màu đất/ngà, bóng thành mảng và nét gạch bên trong hình cũ. Shader grain neo texel từng phần để hình đứng yên ổn định. Kiếm có nhịp giữ lấy đà trước ra đòn; mắt phản ứng ngắn khi đánh/trúng đòn; thân/vạt áo chuyển trọng tâm rõ hơn. 13 VFX dùng nét bút có lực, mảnh giấy sắc và vòng khiên trống, giảm cảm giác neon/bloom. F6 có nền giấy; renderer chung world/HUD/F3/F6, 36 diện mạo, 8 hướng, 11 trạng thái.

**Nhận diện và môi trường:** alpha/kích thước 131 SVG tiếp tục đối chiếu baseline 0.15. Nền/props/sói được grade ấm và nét mép trong; map vẫn atlas pixel gốc. [Quyết định mỹ thuật](docs/game-studio/art-direction-0.19.md), [phản hồi](docs/game-studio/feedback-design-0.19.md) và [kiểm chứng](docs/game-studio/quality-report.md). Đây là pass làm đẹp prototype, chưa phải xác nhận mỹ thuật phát hành.

**Chuyển động liên tục:** nối tư thế đứng–đi–chạy–đổi hướng–ra đòn từ pose đang hiển thị, tăng/giảm biên độ theo tốc độ thực. Chân có pha tiếp đất và nhấc chân, thân chuyển trọng tâm, đầu giữ thăng bằng; tóc/vũ khí dùng spring có giảm chấn và ổn định khi dừng. Tay và bóng lướt lấy đúng pose đã pha trộn. Camera theo từng pixel màn hình ở zoom nguyên để giảm bước giật. F6 dùng cùng chuyển tiếp khi bấm nút; dừng giữ nguyên pose, lấy mẫu/seek vẫn chính xác.

**F6 mở Xưởng nhân vật:** phóng lớn sprite, 8 nút hướng/bước xoay 45°, chọn động tác, dừng/phát lại/tốc độ, chọn giới tính/trang phục/vũ khí/tóc và Áp dụng. 36 tổ hợp diện mạo; đổi cosmetic và lưu profile, không đổi chỉ số. World/HUD/F3 cùng rig SVG. **Shift + WASD chạy**, **Alt xem trước đường lướt**, **1–4** dùng Cổ. Vũ khí đổi hình và animation; damage cận chiến/combo chưa bổ sung.

Xem [kế hoạch/FSD/WBS đồ họa](docs/implementation/PIXEL_2D_MIGRATION_PLAN.md) và [kiểm chứng bản hiện tại](docs/game-studio/quality-report.md). Nguồn Blender/mesh 0.10 và atlas nhân vật/kỹ năng 0.12 giữ làm lịch sử và regression; gameplay/HUD/F3/F6 hiện dùng rig SVG. Tạo lại các lớp vector bằng `python tools/generate_vector_characters.py` (Python standard library). Map/sói dùng `tools/generate_pixel_environment.py` và `tools/generate_pixel_wolves.py` (Python/Pillow). Không cần Python khi chơi.

UI 0.13 là baseline cũ: icon Cổ/vật liệu vector, viền ngọc/đồng và dock kỹ năng 352×104px. Hướng này được giữ làm mốc hồi quy; style hiện hành chuyển sang mực trên giấy theo concept UI 01.

**UI ink20 — mực trên giấy:** panel giấy ngà có viền mực đôi, wash/thớ ổn định, tab vẽ tay và font Patrick Hand tiếng Việt; HUD, hành trang 5×6, F3/F6, nhiệm vụ và pause vẫn giữ trạng thái/luồng thao tác. Rig nhân vật SVG 8 hướng có áo giao lĩnh xòe hơn, cổ ngà, đai/bùa và nét cọ/nếp vải cố định. Xem [art direction và ảnh native](docs/game-studio/ui-style-0.20.md). UI smoke đã chụp 11 trạng thái ở 960×640, 1280×720 và 1280×800; regression đạt 531/531.

**F3** mở bảng nhân vật với chỉ số thật và bốn Cổ khảm; click một Cổ để xem nó trong túi. **F4 / Tab / I** mở hành trang **30 ô**, hiển thị mỗi chồng vật liệu tối đa 99, lọc Tất cả/Cổ trùng/Vật liệu và sắp tên A–Z. Chọn ô Cổ để xem mô tả, no đủ, thức ăn và nút cho ăn. **F11 / J** mở bảng nhiệm vụ có tiến độ, hướng dẫn, trạng thái thưởng và bật/tắt theo dõi. Có thể mở nhân vật và túi cùng lúc ở hai bên; Esc đóng cửa sổ mở gần nhất trước khi mở menu tạm dừng.

Các nút Nhân vật/Hành trang/Nhiệm vụ/Thiết lập ở góc dưới phải vẫn dùng được khi xem cửa sổ. Click khoảng trống ngoài cửa sổ đóng cửa sổ gần nhất, không gửi lệnh di chuyển. Cửa sổ đang mở chặn thi triển kỹ năng; thế giới vẫn chạy cho đến khi tạm dừng bằng Esc. Khung và icon hiện tại dùng chung `scripts/ui/pixel_ui.gd`; thanh HP là `GuVitalBar`. Vật phẩm được chọn và nút Cho ăn nằm trên lưới để đọc được ở 960×640. Xem [hướng UI và nguồn tham khảo](docs/game-studio/feedback-style.md).

Hiệu ứng 0.19 có 13 kiểu vẽ vector trực tiếp: nguyệt nhận màu ngà/xanh đất, mảnh băng xám lạnh, khiên vàng giấy và lông/vệt Bạch Hạc với nét mực thuôn. Hiệu ứng lấy khớp tay liên tục sau chuẩn bị; projectile tiếp xúc ở 0,28s rồi nổ/victim flash/chữ sát thương. Lướt giữ bản sao pose SVG chính xác. HP, mana và thưởng vẫn cập nhật ngay trong authority; animation không gây thêm damage. Giảm chuyển động giữ silhouette ổn định và tắt ghost/flight/shake. Hotbar/HP/túi lấy dữ liệu thật, Cổ được chọn và nút Cho ăn luôn nằm trên lưới.

Rê chuột lên một Cổ để xem tầm, chi phí, mô tả và lý do chưa dùng được. Bảng thông tin ở cột trái để giữ điểm ngắm và mục tiêu trong vùng chơi. **Giữ Alt trên bản đồ** để xem trước đường lướt, điểm dừng và phần đường bị vật cản chặn. **F** chuyển giữa các sói còn sống trong màn hình, cách tối đa 8 ô. Mục tiêu có dấu chọn và phản hồi khi rê chuột.

Trong menu **Esc**, chọn **Giảm chuyển động** để tắt rung camera, giảm chuyển động phụ/VFX và bỏ hiệu ứng trượt menu. Tùy chọn này và tắt âm được lưu vào `settings.cfg` cùng thư mục save. Pause dừng cả mô phỏng lẫn animation trong thế giới; mở túi vẫn để thời gian game chạy.

## Chạy ngay trên Windows

Double-click **RunGame.bat**. Workspace hiện có Godot portable 4.7.2 dưới `.tools/godot`.

Để sửa code: import `project.godot` trong Godot **4.7.2 stable**, chọn Compatibility, nhấn **F5**. Không cần plugin, package manager hay máy chủ. `.tools` và `.godot` không đưa vào Git; máy mới tải Godot cùng phiên bản. Lần đầu mở project trong editor để import assets trước khi chạy bằng dòng lệnh.

Linux: `bash tools/run.sh`. Có thể đặt `GODOT_BIN=/đường/dẫn/godot` nếu dùng engine khác vị trí.

## Điều khiển và thử vòng chơi

| Thao tác | Chức năng |
|---|---|
| W / A / S / D | Giữ để đi lên / trái / xuống / phải theo màn hình; thả để dừng |
| Click nền / chuột phải | Đi đến vị trí theo A* |
| Click sói | Chọn mục tiêu; không tự đi/đánh |
| F | Chuyển mục tiêu gần trong màn hình, tối đa 8 ô |
| Shift + WASD | Chạy theo hướng màn hình |
| Giữ Alt | Xem trước đường lướt; thả để ẩn, bấm 3 để thi triển |
| Rê chuột lên Cổ | Xem thông tin, tầm và điều kiện dùng kỹ năng |
| 1 | Nguyệt Quang: công kích có LOS |
| 2 | Bạch Ngọc: khiên 5 giây |
| 3 | Bạch Hạc: lướt về con trỏ, tối đa 3 ô |
| 4 | Băng Tằm: sát thương + chậm 30% trong 3 giây |
| C | Bắt sói HP ≤30%, tầm 3 ô; channel 2 giây, xác suất 70% |
| F6 | Xưởng sprite, ngoại hình và animation |
| F3 | Nhân vật và bốn Cổ đang khảm |
| F4 / Tab / I | Hành trang 30 ô, lọc/sắp xếp, chi tiết và cho ăn |
| F11 / J | Nhật ký NPC/khảo nghiệm, tiến độ, thưởng và dẫn đường |
| E / click NPC gần | Trò chuyện, chọn lời thoại, nhận/trả nhiệm vụ |
| Nút −/+ trên nhiệm vụ | Thu gọn/mở lại mục tiêu, giữ nguyên tiến độ |
| Esc | Đóng cửa sổ gần nhất; khi hết cửa sổ thì tạm dừng |
| M / lăn chuột | Tắt âm / thu phóng |

Khi bấm nút 3 trên hotbar, hướng lướt dùng điểm ngắm cuối trên bản đồ. Nếu chưa ngắm lần nào, nhân vật lướt theo hướng đang nhìn. Xem trước dùng chung truy vấn với lệnh thi triển, không tiêu chân nguyên hoặc bắt đầu hồi chiêu. Rời cửa sổ game tự xóa trạng thái giữ WASD/Shift/Alt.

Rời vòng trại an toàn trước khi dùng Cổ công kích. Click chọn sói rồi 1; 2 đỡ đòn, WASD/click nền/3 tránh vùng báo trước của sói. Để bắt: 2 lần 1 + 1 lần 4 đưa sói đầy HP xuống ngưỡng bắt; giữ khoảng cách gần 3 ô rồi C. Bị đánh, di chuyển hoặc dùng kỹ năng sẽ ngắt phong ấn, mất seal đã tiêu. Xác suất có thể thất bại; hạ sói để nhận thêm seal/thức ăn.

Mở Tab cho Nguyệt Quang khởi đầu ăn thịt. Cổ này có sẵn 82 no đủ để thử feeding; Cổ mới bắt bắt đầu 100. Hoàn thành 3 kill + 1 capture + 1 feed nhận 200 ngân lượng một lần. Trở về trại để hồi HP; mana tự hồi. Sói hồi sinh sau 20 giây, nhân vật sau 5 giây. Đầy túi thì vật liệu thưởng được giữ chờ và tự nhận khi có chỗ.

## Lưu và kiểm tra

Tự lưu mỗi 10 giây, lúc thay đổi tài sản, pause và đóng cửa sổ. Windows: `%APPDATA%\Godot\app_userdata\GuMaster2D — Vạn Thú Sơn\gu_master_profile.json`; Linux: `~/.local/share/godot/app_userdata/GuMaster2D — Vạn Thú Sơn/`. Có `.bak` để phục hồi bản trước nếu bản chính không hợp lệ. Muốn thử profile mới: sao lưu rồi xóa hai file này khi game đã đóng.

Windows: `RunTests.bat`. Linux: `bash tools/run.sh --headless --script tests/test_runner.gd -- --test-mode`. Kết quả ghi `artifacts/test_results_windows.json` hoặc `test_results_linux.json`. Test không đụng save thật. Mã nguồn âm thanh gốc ở `tools/generate_audio.py`, chạy bằng Python stdlib nếu cần tạo lại WAV.

Native capture: chạy tuần tự Godot `--path <project> --script res://tests/vector_visual_smoke.gd -- --test-mode` , `res://tests/pixel_motion_smoke.gd` và `res://tests/vector_studio_motion_smoke.gd`; ảnh/frame/metadata ghi vào `artifacts/`. Chạy `tools/render_vector_preview.py` để tạo GIF gameplay và F6 từ frame thật. Capture chọn thời gian mẫu cố định để review animation, không dùng làm benchmark FPS. Các harness pixel/3D cũ giữ cho baseline tương ứng.


## Kế hoạch

- [Kế hoạch code Godot](docs/implementation/GODOT_IMPLEMENTATION_PLAN.md): kiến trúc, phân việc 4 người, giờ công, gate và trace vào FSD/WBS.
- [Backlog code cho 4 người](docs/implementation/Godot_Coding_Backlog.xlsx):11task,100,8h gồm dự phòng.
- [FSD/WBS Excel](docs/planning/GuMaster2D_FSD_WBS_Plan.xlsx) và [kế hoạch tổng](docs/planning/GuMaster2D_Project_Plan.md).
- [Báo cáo kiểm chứng](docs/game-studio/quality-report.md).

Chưa triển khai multiplayer/server/database, luyện chế, đổi Cổ hotbar, rank II/passive, NPC/shop, dungeon/party/PvP/GM hoặc Web export. JSON save là tiện ích prototype local; không phải bảo đảm transaction/recovery của FSD online. Prototype chưa hoàn thành các gate alpha.
