# Vùng chữ và viền HUD 0.54

Chữ số lượng đồ có vùng riêng cách đáy 10 px; danh sách Cổ và phím/tên/trạng thái kỹ năng dùng Label có lề. Lề khung 20 px, nút 12×8 px, kiểm cả chồng 99 món và trạng thái lỗi. URL hành trang người dùng đang xem được cập nhật bộ ảnh mới. **78/78 bố cục**, **632/632 vùng chữ**, **49/49 hành trang**, **63/63 bảng Cổ**, **911/911 hồi quy Linux**, **60/60 browser**. [Ảnh và phạm vi kiểm chứng](hud-text-0.54.md).

# Chữ và viền HUD 0.53

Sửa nút mất content margin, dùng native text shaping với lề 12×6 px; panel giấy chừa 16 px, HP/chân nguyên cao 28 px, tên/trạng thái Cổ tách dòng. Thông báo tự xuống dòng và bảng bên giữ khoảng cách với thanh kỹ năng ở 960×640. Kiểm **78/78 native HUD**, **49/49 hành trang**, **63/63 bảng Cổ**, **911/911 hồi quy** và **31/31 browser**. [24 ảnh native và so sánh](http://localhost:8879/hud53_review.html) · [Phạm vi và bằng chứng](hud-spacing-0.53.md).

# Cường hóa và nâng bậc Cổ 0.52

Xưởng luyện Cổ trong G có danh sách trang bị/dự trữ, tranh Cổ, hai tab Cường hóa/Nâng bậc, so sánh chỉ số thật và nguyên liệu có/cần. Nâng bậc chọn rõ phôi; xác nhận tên/mức và giá, giữ Cổ chính cùng phím kỹ năng. Snapshot có phiên bản túi chống tiêu hao từ xác nhận cũ; dữ liệu/schema và quest nâng Cổ hiện có giữ tương thích.

Kiểm **25/25 trên Linux và Windows**, đối chiếu **120 cast thật trên mỗi nền tảng**, **60/60 cơ chế tu luyện có sẵn**, **63/63 UI native Windows**, **911/911 hồi quy toàn game Linux** và **19/19 trang review**. Bố cục/nút chính kiểm ở ba độ phân giải; đã sửa co chữ ở nguyên liệu/phôi, tự cuộn Cổ cuối danh sách và cập nhật khi capture kết thúc. [Ảnh trước/sau](http://localhost:8879/gu52_review.html) · [Thiết kế và kiểm](gu-upgrade-0.52.md).

# Hành trang và thao tác vật phẩm 0.51

Bảng thông tin/dùng/chế tạo/xóa tích hợp vào túi hiện có, menu chuột phải cùng phong cách giấy/mực. Kéo vào ô trống và đổi chỗ có lưu; chọn rõ Cổ cần nuôi, mở đúng Cổ để nâng/hợp, xác nhận xóa có phiên bản dữ liệu. Ba công thức thực hiện giao dịch nguyên liệu/bạc thật và chống xử lý lặp.

Kiểm **40/40 trên mỗi nền tảng Linux/Windows**, gồm lưu thật và nạp lại biên nhận; **49/49 native Windows**, đủ ba độ phân giải; **911/911 hồi quy toàn game Linux** và **19/19 trang review**. [Ảnh và cách dùng](http://localhost:8879/inventory51_review.html) · [Phạm vi/công thức/kiểm chứng](inventory-0.51.md). Cân bằng công thức cần playtest cùng hệ kinh tế; vòng này hoàn thiện thao tác hành trang.

# Minimap và địa đồ lớn 0.50

Khung minimap ôm địa hình; tọa độ X/Y và tám hướng nhìn hiển thị riêng. Bấm map/nút ↗/F2 mở địa đồ lớn, Esc/F2 đóng; T chuyển điểm đã chọn vào bảng dẫn đường. Kiểm native Windows **68/68**, đủ 960×640, 1280×800 và 1920×1080; hồi quy toàn game Linux **911/911**; trang so sánh **12/12**. [Ảnh trước/sau](http://localhost:8879/minimap50_review.html) · [Thiết kế và bằng chứng](minimap-0.50.md).

# Nhịp chuyển động nhân vật 0.48

Sửa trực tiếp rig và phối hợp chuyển động: mở lấy đà kiếm/cuốc, bỏ cú lật khớp khi thi triển, giữ vận công trước ngực với khuỷu ≤135°, ổn định trục thương và chiếu chiều sâu cho chân trước/sau. Quần bám vào các khớp sau khi chiếu; chân trụ theo khoảng dịch chuyển thật của ActorView khi bắt đầu, đổi đi/chạy và dừng.

| Kiểm chứng | Kết quả |
| --- | --- |
| Hồi quy toàn game | **911/911**, không lỗi, sau sửa vị trí tay vận công |
| Tay/chân | **12/12**, 75.504 pose: 13 động tác × 8 hướng × 2 giới tính × 3 vũ khí × 121 pha |
| Vận công | **60/60**, gồm 11.568 pose và kiểm cũ giữ tay trên thắt lưng; khuỷu ≤135°, không nới tiêu chí |
| Chân trụ trong ActorView | **5/5**, 27.566 cặp tiếp đất ở 30/60/120 FPS; bước trượt lớn nhất 2,990 px trước sửa → 0,461 px sau sửa |
| Độ kín native trên Windows/NVIDIA | **76.800 mẫu alpha**, không hở ở các điểm vai, khuỷu, cổ tay, gối và bàn chân; gồm cả cast/channel mới |
| Gameplay Windows | **20/20**: E, nhận thưởng một lần, ngắt thao tác, trả về đứng và F6; tám ảnh game thật |
| Mesh và các điểm bám | **28/28**; thử đúng đỉnh được renderer vẽ, hai đầu quần bám vào khớp chiếu, tay/giày giữ hình cứng |
| Audit độc lập | 50.128 pose và tám chuỗi Actor; nguồn ổn định, có đối chiếu số đo với project 0.47 đóng băng |
| Review native và browser | **2.494 frame / 98 clip**, 585 frame baseline, 22 SHA nguồn cuối thống nhất; **766/766** kiểm browser, không lỗi JS/tài nguyên |

Lỗi hồi quy vận công được phát hiện khi chạy toàn game: chặn góc gập bằng kéo tay theo tia cũ làm tay rơi xuống dưới vùng ngực. Đã sửa bằng tìm điểm tay vào trong trên đường ngang ngực, giữ nguyên giới hạn khuỷu và kiểm tra cũ. Bộ hồi quy sau sửa đạt đủ 911 kiểm tra.

Chân nhấc ở hai hướng chéo lên còn thu khá nhanh tại cỡ soi 256 px. Đo với bước thời gian giảm dần và xem frame native xác nhận đường đi liên tục, cổ giày/đầu gối giữ kín; hiệu ứng nhỏ ở cỡ game 48 px. Đây là sửa lỗi và hoàn thiện rig cutout hiện có, không phải xác nhận mọi hoạt ảnh đã đạt chất lượng mỹ thuật cuối.

[Review chuyển động](http://localhost:8879/concept48_character_review.html) · [Thiết kế](character-motion-0.48.md) · [Phạm vi ảnh và cách chụp](character48-review.md) · [Bằng chứng cuối](../../artifacts/concept48_delivery.json).

# Nét vẽ nhân vật 0.47

Tinh chỉnh 352 chi tiết vector của cả nam/nữ, tám hướng: mảng màu đất, nếp vải thuôn, băng quấn cong và nét mực đậm hơn ở mép khuất. Giữ nguyên hai PNG concept, điểm bám và fitting 0.46. Bộ lọc đầu/atlas giảm lấp nhấp khi thu nhỏ; các mẫu atlas được giới hạn trong ô của chính chi tiết để tránh lem màu.

| Kiểm chứng | Kết quả |
| --- | --- |
| Hồi quy toàn game | **906/906**, không lỗi |
| Asset | **352 SVG hợp lệ**, 354 file tái tạo giống từng byte; bounds, anchors, rest chains, fitting và rect atlas giữ nguyên |
| Shader native | Qua trên **Linux/Mesa và Windows/NVIDIA**; kiểm nét mực, màu giấy, alpha, minification và chặn màu ô bên cạnh |
| Điểm nối khi phát chuyển động | **61.440 mẫu alpha**, không có khe hở tại các điểm đã lấy mẫu, đủ tám hướng |
| Game trên Windows | **20/20**, gồm tương tác E, chống nhận thưởng lặp và F6; tám ảnh game thật trên GTX 1050 |
| Đối chiếu native | **1.224 framebuffer**, xuất 2.448 ảnh nam/nữ; 4.896 lần xác nhận cùng pose trước/sau; 31 SHA nguồn cuối thống nhất |
| Browser | **621/621**, không lỗi JS/tài nguyên; tư thế, clip, bước frame, desktop/mobile và ảnh trong game |

Review ảnh ở cỡ 200 và 48 px cho thấy viền và mảng vải liền với concept hơn; không thấy viền đôi, chi tiết rời, nhiễu trắng hoặc mất nhận diện mặt trong các mẫu đã xem. Cải thiện rõ hơn ở cận cảnh. Đây là lượt tinh chỉnh nét/tô màu, chưa phải nghiệm thu mỹ thuật cho phát hành.

[So sánh trực tiếp](http://localhost:8879/concept47_character_review.html) · [Thiết kế](character-ink-0.47.md) · [Cách chụp](character47-review.md) · [Bằng chứng cuối](../../artifacts/concept47_delivery.json).

# Nhân vật theo từng hướng 0.46

Hướng xuống được làm và kiểm trước, sau đó mới mở sang bảy hướng còn lại. Giữ nguyên hai PNG concept đầu/thân; 16 bộ giới tính/hướng có chuỗi xương gốc, điểm may vai, điểm bám bàn tay và đường co vải riêng. Cùng một tay áo biến dạng theo khuỷu và độ nâng tay, không để lại tay áo ở vị trí cũ. Mép sáng được bo và thu gọn để không giống ngón tay thừa.

Kiếm, hái lượm và khai khoáng có mốc tay/thân theo từng hướng. Thế đỡ cho phép gạt kiếm chéo ra ngoài để tránh cắt ngang mặt, giữ khuỷu ≤135° và góc cổ tay ≤0,85 radian. Khi xem clip, hướng lên trái còn bị đầu che tay ở pha chạm; đã hạ và mở điểm chạm ra ngoài đường bao áo, không đổi thứ tự lớp hoặc kéo dài xương.

| Kiểm chứng | Kết quả |
| --- | --- |
| Hồi quy toàn game | **906/906**, 0 lỗi, chạy lại sau sửa điểm chạm hướng lên trái |
| Chuyển động | **124/124 trên Linux và Windows**; 4.656 pose vũ khí, 976 mẫu phát mượt, 1.936 frame kiểm kiếm–mặt, điểm chạm đủ tám hướng |
| Thu thập và ngắt động tác | **248/248**; 9.312 pose, giữ thời điểm chạm, phần thưởng và ngắt thao tác |
| Lưới vải thực tế | **20/20**, 14.144 mesh ở 13 động tác; diện tích tam giác 0,532–1,402 lần gốc, không lật lưới; điểm neo giữ nguyên |
| Độ kín khi chuyển động | **61.440 mẫu alpha**, không hở tại các điểm vai/khuỷu/cổ tay/gối/cổ chân đã lấy mẫu, đủ tám hướng |
| Game và input | **20/20** ở hướng ngang, **20/20** ở hướng lên; phím E, thưởng một lần, chặn bấm lặp, về đứng và F6 |
| Concept gốc | SHA-256 hai PNG trùng bản trước; chín ảnh baseline hướng xuống chụp lại giống byte với ảnh trước sửa |
| Ảnh native | **1.248 PNG**: 1.152 frame phát mượt, 72 tư thế và 24 ảnh vũ khí; cùng một bộ SHA source cuối. Thêm 72 ảnh baseline và 16 ảnh game/F6 ở hai hướng thu thập |
| Browser | **324/324**; chọn tám hướng, tư thế, clip và vũ khí; phát/dừng/bước frame, đối chiếu baseline, ảnh game và layout 1440/960/390 px; không lỗi JS |

Khoảng cách kiếm–vùng mặt nhỏ nhất bằng 1,097 lần bán kính ellipse kiểm. Chân trụ giữ sai số khoảng 0,000101 đơn vị nguồn; sai số chiều dài xương dưới 0,000002. Bài kiểm mới đo đường bao đầu/áo tại điểm chạm lên trái, tránh việc xương hợp lệ nhưng tay lại khuất hoàn toàn trong hình hoàn chỉnh.

[Xưởng tám hướng, xương → asset → hình hoàn chỉnh](http://localhost:8879/concept46_character_workshop.html) · [Thiết kế](character-direction-fitting-0.46.md) · [Cách chụp và provenance](character46-workshop.md) · [Báo cáo kết quả](../../artifacts/concept46_delivery.json).

Sáu clip chính được xem bằng frame Godot thật; các động tác thi triển, vận công, lướt, trúng đòn, gục và hồi sinh được bổ sung trong kiểm hình học. Đây là cập nhật rig và asset gắn xương; không phải bộ ảnh vẽ tay lại cho từng frame. Đánh giá độ kín tại các điểm lấy mẫu đi cùng xem silhouette và cảnh tài nguyên trong game.

# Đại vực, Cổ thuật và quái 0.45

Ba map 256×256 ô, 64 bãi farm, 351 cá thể, 33 trạm và 176 nguồn tài nguyên. Các vùng mới có sông/hồ, cầu và vòng đường nối địa khu; giữ tuyến quest nhập môn, ruộng và save schema hiện hành. Hình Cổ vẽ mới bằng SVG, dùng chung trong UI và hiệu ứng. Tám loại quái có đầu/thân/chân theo hướng, chân giải IK và hai đòn luân phiên mỗi loại.

| Kiểm chứng | Kết quả |
| --- | --- |
| Hồi quy toàn game | **906/906**, 0 lỗi; gồm input, UI và toàn bộ kiểm rig/skin/chuyển động nhân vật cũ |
| Bản đồ | **437/437**; toàn bộ điểm nội dung có đường tới, 21.322 ô cũ còn đi được, props/surface truy vấn đúng |
| Cơ chế thế giới | **887/887**, gồm bãi, AI, nguyên liệu, quest và save |
| Quest / điền viên | **76/76**, **60/60** |
| Quái | **170/170**; 51.984 mẫu hình học, 10.752 chân; tám hướng, chân trụ giữ vị trí khi lấy đà/trúng đòn |
| Cổ | **21/21**; SVG alpha sạch, origin ở tay, nhịp release/contact đúng, sự kiện không bị sửa |
| Scene map | **151/151**, 18 ảnh native; T dẫn đường xa, khám phá trạm, dịch chuyển/hồi sinh, culling và giảm chuyển động |
| Scene Cổ | **17/17**, 13 ảnh trong game; phím 1–4 và G; khiên chỉ có một lớp chủ quản |
| Ảnh quái | 54 bảng toàn bộ loài, 54 dải cóc sau sửa chân, 1 bảng idle cuối; không lỗi triangulation trong log |
| Browser | Quái **59/59**, Cổ **9/9**; trang tổng hợp 34 ảnh / 4 bộ lọc / 3 kích thước, không lỗi JS hoặc tràn ngang |
| Concept nhân vật | Hai PNG đầu/thân và góc gốc giữ nguyên SHA-256 |

Vùng báo nguy và kiểm đòn dùng chung `BeastAttackGeometry`; sát thương còn kiểm vật cản và vùng an toàn. Các effect chỉ đọc sự kiện đã chấp nhận. Elite sử dụng cùng hệ số 1,34× cho hình và stride, tránh trượt chân khi đổi kích thước. Đa giác chiếu dùng đường bao hợp lệ; chi tiết bị nhìn ngang thành cạnh vẫn có nét vẽ, không xóa chi để né lỗi renderer.

Scene chỉ giữ 61–90 props quanh camera trong ba vị trí kiểm, tổng dữ liệu mỗi vùng 4.363–6.000 props; sáu actor hiển thị đang cập nhật trong số 105–123 quái. 180 bước authority mất 486–756 ms dưới tải kiểm đồng thời. Đo trên Linux/Mesa phần mềm, không dùng các số này để tuyên bố FPS Windows. Khởi tạo scene test 11,7 giây; cần profile bản export/GPU thật trước khi chốt hiệu năng.

Đã xem ảnh atlas, bãi xa, bốn tranh Cổ, khiên trong game và bảng tám hướng. Sửa chân cóc bị thân che, lỗ mũi heo nhìn từ sau, hình khiên trùng lớp, camera hồi sinh và cỏ không vẽ lại khi giảm chuyển động. Chất lượng hình/nhịp chơi cần người dùng đối chiếu trên bản review; cân bằng bãi farm và phần thưởng cần playtest dài hơn. Phạm vi này chưa thêm quest mới, MMO hoặc cam kết kích thước đúng bằng Võ Lâm Truyền Kỳ II.

[Map và ảnh trong game](http://localhost:8879/world45_review.html) · [Animation quái](http://localhost:8879/beast45_review.html) · [Cổ thuật](http://localhost:8879/gu45_review.html) · [Thiết kế và lệnh kiểm](world45-expansion.md) · [Báo cáo bàn giao](../../artifacts/world45_delivery.json).

---

# Nhân vật liền khớp 0.44

Sửa trực tiếp hình chi tiết và cách render: tay áo rộng hơn, cẳng tay có thể tích và lớp quấn rõ, bàn tay/giày đủ khối theo concept. Bộ 352 SVG vẫn tách theo nam/nữ và tám hướng. Giảm nét chia mảnh ở vai; nếp vải dùng mảng màu gọn thay các đường thẳng song song.

Vải trên bắp tay, cẳng tay, đùi và cẳng chân được đặt lên mesh 65 đỉnh / 96 tam giác mỗi mảnh. Tiết diện uốn có giới hạn quanh khớp và giữ nguyên trục xương, không kéo dài chi. Lưới/UV được cache, mỗi mảnh một lệnh vẽ. Cẳng tay chia tại cửa tay áo: phần gốc nằm dưới, phần tới cổ tay nằm trên để không bị mất khi gập. Hai nửa dùng đúng chung đỉnh/UV ở đường nối. Bàn tay, vũ khí và đế giày vẫn cứng. Đây là skin trên rig procedural hiện hữu, không thay bằng một hệ Skeleton2D khác trong vòng sửa này.

Đã cài [godot-2d-animation](https://github.com/thedivergentai/GD-Agentic-Skills/tree/main/skills/godot-2d-animation) tại `/mnt/c/Users/Admin/.codex/skills/godot-2d-animation`; đọc phần cutout/rig trước khi áp dụng. Đối chiếu hướng dẫn [Godot 2D skeletons](https://docs.godotengine.org/en/stable/tutorials/animation/2d_skeletons.html) về đỉnh nội bộ/biến dạng và [RenderingServer](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html#class-renderingserver-method-canvas-item-add-triangle-array) về batch tam giác. Không đưa script ví dụ của skill vào runtime.

| Kiểm chứng | Kết quả |
| --- | --- |
| Hồi quy | **714/714**, 0 lỗi; 709 cũ + 5 kiểm mesh/đường nối |
| Mesh | 1.728 pose của 12 action, hai giới tính, tám hướng; 13.824 mesh kiểm; không tam giác lật, tỷ lệ diện tích 0,501–1,476 |
| Điểm khớp | Sai lệch do skin nhỏ hơn 0,000001 native unit; toàn bộ grip, vai/hông và chiều dài xương tiếp tục qua bộ kiểm cũ |
| Alpha native | **8.192 mẫu quanh khuỷu/cổ tay/gối/cổ chân**, không mẫu dưới alpha 0,95; render thật trong SubViewport nền trong suốt |
| Lớp cẳng tay | 32 cánh tay có đường nối mesh và UV khít; ảnh phòng thủ/giơ cuốc kiểm phần khuất và phần nổi |
| Native review | 16 ảnh so sánh đúng cùng pose trước/sau + 144 frame sáu animation + 24 bảng xương = **184 ảnh** |
| Trong game | **19/19** E/F6, phần thưởng một lần và trả về idle; 7 ảnh mới |
| Browser | **104 trạng thái** gồm tám tư thế so sánh và 96 tổ hợp action/body/hướng; playback, xương, 390 px; không lỗi tải/JS hoặc tràn ngang |
| Concept | PNG đầu/thân và sheet góc gốc giữ SHA-256 |

[So sánh và playback 0.44](http://localhost:8879/concept44_character_review.html) · [Báo cáo dữ liệu](../../artifacts/concept44_delivery.json). Bản 0.42/0.43 giữ nguyên để đối chiếu và có liên kết sang bản mới.

Kiểm alpha dùng đúng vị trí cổ tay/cổ chân, không dùng đầu palm/điểm chạm đế giày làm khớp. Kiểm RGB trên nền xanh ban đầu đã được thay bằng alpha vì vải tối trùng màu nền có thể bị nhận nhầm là khe hở. Ảnh trước/sau dùng chung rig/pose hiện tại và atlas/metadata riêng của hai bản.

Đã xác nhận nối khớp, không lật mesh, input và render Linux/Mesa. Phần đầu/áo gốc vẫn là sketch, các chi tiết mới là SVG; độ đồng nhất mỹ thuật toàn thân cần người dùng duyệt trên bản so sánh. Chưa tuyên bố chất lượng phát hành hoặc hiệu năng GPU Windows. Handoff dụng cụ 0.43 và nhịp tấn công 0.42 tiếp tục được giữ.

Chạy lại:

```sh
python3 tools/author_directional_character_parts.py
bash tools/run.sh --headless --editor --import --quit
bash tools/run.sh --headless --script res://tests/character_joint_skin_runner.gd -- --test-mode
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/character_joint_skin_review.gd -- --test-mode --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/character_action_ingame_review.gd -- --test-mode --capture-offscreen --capture-prefix=concept44
python3 tools/build_character_joint_review.py
```

---

# Chuyển động tác và chân trụ 0.43

Sửa chân trượt ở đoạn pha từ thao tác sang đứng/đi: nội suy điểm đặt chân, giới hạn độ cao hông theo tầm với thực tế, rồi giải lại khớp gối với chiều dài xương gốc. Khi đổi hình chiếu, chuyển độ lệch bàn chân theo điểm gốc của góc mới; hướng gập gối lấy từ góc đang render.

Vật cầm tay có nhịp ẩn/hiện khi chuẩn bị và thu tay, chỉ vẽ một loại mỗi frame. Ngắt khai khoáng giữ socket cuốc và lớp tay sau đầu trong đoạn chuyển tiếp. Handoff dùng fade ngắn 45/60 ms, không chặn input, không thay trang bị hoặc thưởng tài nguyên. Đây chưa phải animation cất vật vào bao được vẽ riêng.

| Kiểm chứng | Kết quả |
| --- | --- |
| Hồi quy | **709/709**, 0 lỗi; 693 kiểm cũ + 16 kiểm chuyển tiếp |
| Chân trước/sau | Cùng probe ngắt action ở 60 FPS: độ trượt tối đa **0,806016 → 0,000101** native unit |
| Chuyển tiếp | 7.680 pose, hai giới tính × tám hướng × 30/60/120 FPS; điểm vai/hông gắn đúng, sai chiều dài xương tối đa 0,00000477 |
| Quay người | Chân remap theo view và gối đúng hướng; bước sync delta=0 giữ nguyên pose/prop đang nhìn thấy |
| Đổi dụng cụ | Đúng kiếm/thương/tay không tại đầu/cuối; cuốc hiện tại nhịp chạm; không đổi hình khi prop cũ còn hiện |
| Native game | **19/19**, E, lặp E, thưởng một lần, kết thúc thao tác và F6; 7 ảnh mới |
| Native review | 156 frame chuỗi + 16 bảng xương; 16 body/view mỗi bảng. Runtime cập nhật 120 Hz, capture 30 FPS |
| Browser | 64 tổ hợp chuỗi/body/hướng; playback, lớp xương, viewport 390 px; không lỗi tải/JS hoặc tràn ngang |
| Concept | Hai PNG gốc giữ SHA-256; không tạo nhân vật mới |

[Xem bản 0.43](http://localhost:8879/concept43_transition_review.html) · [Báo cáo dữ liệu](../../artifacts/concept43_delivery.json) · [Chuyển tiếp](../../artifacts/concept43_transitions.json) · [Hồi quy](../../artifacts/concept43_regression.json).

Phạm vi đã xác nhận: chuyển tiếp rig, vật cầm tay và lớp vẽ, bằng mô phỏng cùng Godot Linux/Mesa thật. Nét vẽ của tay áo SVG và đầu/thân sketch vẫn chưa hoàn toàn đồng nhất; vòng này chưa thay bộ tranh hoặc nghiệm thu mỹ thuật phát hành. Các chuỗi xem dùng vị trí đứng cố định để đọc silhouette, kiểm di chuyển trong world vẫn nằm trong hồi quy ActorView. Chưa benchmark GPU Windows mục tiêu.

Chạy lại:

```sh
bash tools/run.sh --headless --script res://tests/character_transition_runner.gd -- --test-mode
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/character_transition_review.gd -- --test-mode --capture-offscreen
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/character_action_ingame_review.gd -- --test-mode --capture-offscreen --capture-prefix=concept43
python3 tools/build_character_transition_review.py
```

---

# Nhịp kiếm và thu thập 0.42

Đã tham khảo các đoạn gameplay DST và slide kỹ thuật của đội Klei, đồng bộ chuyển động thân/tay/hiệu ứng kiếm, thêm hái lượm và cuốc khoáng vào sự kiện E. [Thiết kế, nguồn và giới hạn](character-action-motion-0.42.md).

| Kiểm chứng | Kết quả |
| --- | --- |
| Hồi quy | 693/693, 0 lỗi; gồm 56 kiểm thu thập mới và kiểm chưa phóng trước mốc kiếm |
| Thu thập | 9.312 pose, 2 giới tính × 8 hướng × 3 vũ khí × 2 action × 97 pha; chân trụ sai lệch tối đa 0,000101 native unit |
| Combat | 4.656 pose; grip gắn đúng; profile khuỷu kiếm tại chạm tối đa 13,5°; bước quay lưỡi tối đa 15,57° / 96 khoảng pha |
| Native game | 19/19 E, lặp E, phần thưởng một lần, kết thúc action, F6; 7 ảnh |
| Native playback | 96 bảng frame + 12 overlay xương, 16 hình chiếu/bảng; dùng renderer Godot thật |
| Browser | 48 tổ hợp action/body/hướng; phát đúng thời lượng, xem chậm, overlay; 390 px không tràn ngang |
| Source art | Hai PNG concept giữ SHA-256 |

[Trang xem 0.42](http://localhost:8879/concept42_action_review.html) · [Báo cáo bàn giao](../../artifacts/concept42_delivery.json). Import, regression và native capture cuối không có SCRIPT ERROR/ERROR/FAIL. Nguồn/thời điểm tham khảo được ghi riêng; không tuyên bố timing trích từ DST hoặc mỹ thuật đã đạt ngang Klei. Linux/Mesa xác nhận chức năng và hình, chưa đo FPS GPU Windows mục tiêu.

---

# Chi tiết hướng và liên kết nhân vật 0.41

Đã thay các mảnh tay/chân cắt từ dáng đứng bằng 352 SVG có hợp đồng góc nhìn và điểm bám. Phần nối vai đo theo thân từng hướng; tay áo xòe, viền cửa tay thuộc áo; cẳng tay nằm dưới; góc sau không vẽ cẳng tay xuyên lưng. Đầu và hoa văn thân tiếp tục dùng concept. [Thiết kế và giới hạn](concept-directional-parts-0.41.md).

| Kiểm chứng | Kết quả |
| --- | --- |
| Hồi quy | 636/636; 0 failed; 613 kiểm cũ + 23 mới |
| Liên kết | 12.000 pose + 512 pose chuyển hướng/blend; sai lệch tối đa 0,0000064 native unit |
| Asset | 352 đường dẫn riêng; đĩa phủ các khớp đục; PNG concept nguyên hash |
| GPU | 352 mẫu màu đạt; sampler atlas thật |
| Native | 198 ảnh Godot Linux/Mesa: đứng, 9 động tác, 3 vũ khí khi đánh, xương, tách lớp, world/F3/F6 |
| Review | 23 trạng thái browser; 352 ảnh SVG tải được; 390 px không tràn ngang |

[Trang xem](http://localhost:8879/concept41_character_review.html) · [Báo cáo dữ liệu](../../artifacts/concept41_delivery.json). Kiểm số không thay cho nghiệm thu mỹ thuật; bộ SVG theo công thức vẫn cần duyệt độ đồng nhất với nét sketch đầu/thân. Chưa xác nhận hiệu năng phần cứng Windows. World/quest 0.40 không đổi trong lượt này.

---

# Ba đại vực và truyền thừa 0.40

Đã triển khai ba map 96×96, 16 bãi/8 loài/93 cá thể, 18 quest/7 NPC, 32 nguồn tài nguyên, 9 trạm và 3 phần thưởng chức năng. [Phạm vi, WBS, nguồn truyện và cách chơi](world-expansion-0.40.md).

| Kiểm tra | Kết quả | Bằng chứng |
|---|---|---|
| World, bãi, AI, giao dịch và lưu | Pass 413: mọi bãi/node/spawn có đường; chuỗi 18 quest, loot, hồi sinh, aim/dodge/LOS/safe zone, functional rewards, save cũ/hỏng | [Mô phỏng](../../artifacts/world40_mechanics.json) |
| NPC/quest nền | Pass 76: chuỗi nhập môn, đúng giver/turn-in, chống lặp, NPC mới đi tới được | [Quest](../../artifacts/world40_quests.json) |
| Điền viên / nâng Cổ | Pass 60: farm, hợp thành, chi phí, save, vùng ruộng an toàn và vùng hoang có quái | [Cultivation](../../artifacts/world40_cultivation.json) |
| Native PC input / render | Pass 49: T/E/R/H/F11, click camp/numeric skill, NPC/quest, dẫn đường, dịch chuyển, minimum viewport, culling/wakeup; 24 ảnh | [Native](../../artifacts/world40_native.json) |
| Hồi quy nhân vật / UI / combat | Pass 613; giữ source PNG, rig và gameplay cũ; cập nhật assertion số lượng và renderer theo nội dung mới | [Regression](../../artifacts/world40_regression.json) |
| Trang review | Pass: 23 PNG decode, 5 nhóm ảnh, 18 quest/3 bộ lọc, rộng 1360/960/390, không page error | [Browser](../../artifacts/world40_browser.json) |
| Chất lượng phát hành | Partial: quái mới dùng art vector code-native; chưa benchmark Windows/Web/mobile hoặc playtest cân bằng dài hạn | [Giới hạn](world-expansion-0.40.md) |

Tổng **1211/1211** lượt kiểm; các suite có giao nhau. Regression chạy trước lớp nước liên tục cuối; native chạy lại sau lớp nước. Không coi kiểm framebuffer hay benchmark headless là FPS thiết bị người dùng. Fixture native có đặt vị trí/tiến độ để bỏ thời gian di chuyển/chiến đấu; mô phỏng thực thi đủ 18 mục tiêu và claim. Không sửa save thật. Hai PNG concept giữ SHA-256, recorded trong [delivery](../../artifacts/world40_delivery.json). Blueprint map cache độc lập mỗi authority; đo 129ms cho 600 bước mô phỏng đứng ở trại chỉ là phép đo cục bộ.

# Môi trường, NPC và nhiệm vụ 0.39

Tính năng đã nối vào game PC local: 4 NPC dùng rig hiện hành, hội thoại lựa chọn, 6 nhiệm vụ có điều kiện/thưởng/lưu, mốc môi trường của 3 vùng. [Phạm vi, WBS và cách chạy lại](quests-environment-0.39.md).

| Kiểm tra | Kết quả | Bằng chứng |
|---|---|---|
| Quest và lưu hồ sơ | Pass 70/70: toàn bộ chuỗi, đúng người giao/trả, chống trả lặp, full bag, migration, hồ sơ hỏng bị từ chối nguyên tử | [Cơ chế](../../artifacts/quests39_mechanics.json) |
| Hội thoại và UI native | Pass 48/48: phím E/click thật, hỏi chuyện, nhận/trả, chặn input, nhật ký/dẫn đường, chuyển vùng, tự đóng khi mất cự ly | [Native](../../artifacts/quests39_native.json) |
| Môi trường và animation | Pass trong mẫu đã kiểm: waypoint/cổng/nông trại vẫn đến được, footprint/ao chặn đường, fade vật che; idle/talk thay đổi pose với pivot cố định, reduced motion dừng | [37 framebuffer](../../artifacts/quests39_review.html) |
| Điền viên và nâng Cổ | Pass 60/60 sau tích hợp counter quest | [Điền viên](../../artifacts/quests39_cultivation.json) |
| Hồi quy gameplay/nhân vật | Pass 613/613, không có script error; lớp mực/trang trí cuối được kiểm lại bằng native | [Regression](../../artifacts/quests39_regression.json) |
| Trình xem | 13 ảnh tĩnh + 24 frame, nút phát/dừng/seek và ba chiều rộng trình duyệt | [Browser](../../artifacts/quests39_browser.json) |
| Nghiệm thu phát hành | Partial: rig/diện mạo tái sử dụng, chưa animation nghề nghiệp riêng, chưa voice/cutscene/lịch NPC hoặc playtest cân bằng dài hạn | [Giới hạn](quests-environment-0.39.md) |

Capture trên Linux/X11/Mesa llvmpipe với Godot 4.7.2; không phải benchmark FPS hay xác nhận engine Windows/Web. Native dùng fixture bỏ qua một phần chiến đấu/mở vùng ở chặng sau; tests cơ chế chạy chuỗi lệnh đầy đủ. Không sửa save thật. Hai PNG concept gốc giữ nguyên SHA-256.

# Baseline — Cổ giới và bí cảnh 0.38

Vòng chơi PC local đã nối 3 vùng, luyện/hợp thành Cổ và điền viên. [Phạm vi/WBS và hướng dẫn kiểm](expansion-0.38.md).

| Kiểm tra | Kết quả | Evidence |
|---|---|---|
| Cơ chế và lưu | 60/60: giao dịch nguyên tử, ba cây/hai thú, mở vùng, sức mạnh thật, migration và full-bag recovery | [Cơ chế](../../artifacts/expansion38_mechanics.json) |
| Tích hợp native | 35/35: phím/nút thật, đổi population/target, nâng/hợp Cổ, tương tác E, pause; 11 screenshot tại960 và1280 | [Native](../../artifacts/expansion38_native.json) |
| VFX | 8 trường hợp được nhận đúng rank, 16 ảnh của 4 Cổ bậcI/II và reduced motion | [FX](../../artifacts/expansion38_fx.json) |
| Hồi quy | 613/613; 0 failure, không có script error | [Regression](../../artifacts/expansion38_regression.json) |
| Thử cân bằng / chất lượng phát hành | Partial: smoke dùng fixture ở một số bước; chưa playtest dài hạn, chưa benchmark thiết bị yếu, chưa Web/mobile/network | [Giới hạn](expansion-0.38.md) |

Ảnh native có thể xem tại [trang review](../../artifacts/expansion38_review.html). Bộ nhân vật0.37 được giữ; đồ điền viên và dấu ấn mới là geometry vector, chưa phải bộ animation nông vụ/linh thú đầy đủ cho phát hành.

# Baseline — thân sạch và asset vải modular 0.37

**613/613 Linux/Godot 4.7.2**, 0 failure. Thân không giữ pigment trong đường ráp tay hoặc ngoài silhouette riêng. 112 SVG cho 16 view; ba điểm uốn giữa vai–khuỷu, cổ tay/palm/boot giữ form. [Phạm vi, asset, kế hoạch và rollback](concept-character-modular-cloth-0.37.md).

| Kiểm tra | Kết quả | Evidence |
|---|---|---|
| Nét tay đứng còn trên thân | Đạt: 2.194 pixel ngoài mask cũ được chuyển sang tay; 0 pixel bị mất trong vùng kiểm; mask không lấy nhầm tóc ở mép ngoài | [Modular parts](../../artifacts/concept37_modular_parts.json), [thân riêng](../../artifacts/concept37_body_only.png) |
| Thân / tay / khớp | Đạt: 5.808 pose thân đầy đủ diện tích, 11.616 pose tay không lật, 2.992 pose asset mới; source UV và grip giữ đăng ký | [Thân](../../artifacts/concept37_body_panels.json), [vải](../../artifacts/concept37_sleeve_deformation.json), [combat](../../artifacts/concept37_combat_constraints.json), [regression](../../artifacts/concept37_tests.log) |
| Pigment SVG thực trong renderer | Đạt: 16 view qua GPU probe, không còn mesh trắng do sampler chưa gắn | [GPU cloth](../../artifacts/concept37_cloth_gpu.json), [các lớp](../../artifacts/concept37_parts_exploded.png) |
| Runtime và review | Đạt: 752 frame, 11 UI state/3 viewport, 165 combat + 352 action qua Chrome; 400 frame clip RGB lossless, 0 mismatch | [Capture](../../artifacts/concept37_native_delivery.json), [UI](../../artifacts/concept37_ui_capture.log), [browser](../../artifacts/concept37_combat_review_browser.json), [RGB](../../artifacts/concept37_clip_validation.json) |
| Nghiệm thu mỹ thuật toàn bộ animation | Partial: ngón tay, foreshortening mạnh và nếp gập sâu vẫn cần drawing riêng theo hành động | [Chi tiết pha chạm đòn](../../artifacts/concept37_detail_attack_03.png), [giới hạn](concept-character-modular-cloth-0.37.md#phạm-vi-asset-hiện-hành) |

Ngưỡng kiểm diện tích thân giờ dựa trên silhouette của asset độc lập, thay cho yêu cầu giữ silhouette có tay đứng của bản cũ. Kiểm ownership ngoài mask 0.36 và toàn bộ đường ráp được thêm để bắt đúng lỗi người dùng báo. Nối khuỷu được kiểm với hai mép vải thực sau biến dạng, vẫn giới hạn sai khác bề rộng; không bỏ kiểm attachment/winding. Chưa benchmark phần cứng hoặc kiểm engine Windows trong pass này.

# Baseline — khép thân dưới tay và duỗi tay kiếm 0.36

**607/607 Linux/Godot 4.7.2**, 0 failure và 0 script/runtime error trong log cuối. [Phạm vi và bằng chứng](concept-character-complete-coat-0.36.md).

| Kiểm tra | Kết quả | Evidence |
|---|---|---|
| Vùng thân dưới tay / đai | Đạt: phủ 10.791 pixel nội bộ bị tay che, 0 khe hở; bỏ viền lỗ tay đứng; không mất pigment nguồn | [Thân](../../artifacts/concept36_body_panels.json), [contact native](../../artifacts/concept36_detail_attack_03.png) |
| Tay cầm ở chạm đòn ngang | Đạt: W/E của hai body, khuỷu tối đa 13,5° thay cho khoảng 38°; grip/xương/timing giữ hợp đồng | [Combat](../../artifacts/concept36_combat_constraints.json) |
| Vạt áo và rig | Đạt: lattice tam giác không lật trong 5.808 body-core pose; 11.616 pose tay và stance giữ hồi quy | [Tests](../../artifacts/concept36_tests.log), [tay áo](../../artifacts/concept36_sleeve_deformation.json) |
| Runtime / UI / trình xem | Đạt: 752 framebuffer chu kỳ; 16 GPU probe; 11 UI state / ba viewport. Chrome giải mã 165 combat/overlay và 352 action, 0 page error | [Native](../../artifacts/concept36_native.log), [UI](../../artifacts/concept36_ui.log), [so sánh](../../artifacts/concept36_combat_review.html) |
| Mỹ thuật toàn bộ animation | Partial: thân không còn vùng rỗng đã báo; nếp gấp sâu, phần tay khuất và kiểu nắm vẫn cần drawing theo hành động | [Giới hạn](concept-character-complete-coat-0.36.md#giới-hạn) |

PNG nguồn giữ nguyên; 400 frame RGB của bảy clip đối chiếu lossless, 0 mismatch. Confidence sửa lỗi hình học/renderer: high (code, tests, runtime); chất lượng mỹ thuật tổng thể: partial (screenshot + review). Chưa kiểm lại engine Windows hoặc benchmark FPS.

# Baseline — thân/tay áo/vạt áo theo hướng 0.35

**605/605 Linux/Godot 4.7.2**, 0 failure; log cuối không có runtime/script error. Ownership theo đường may riêng của 16 view; phần ngực dưới tay có biên và màu bổ sung riêng; vạt L/R dùng hip/stride/lift của chân tương ứng. [Phạm vi, bằng chứng và giới hạn](concept-character-body-panels-0.35.md).

| Kiểm tra | Kết quả | Evidence |
|---|---|---|
| Tách tay áo khỏi thân | Đạt trong các vùng đã tách: 12.529 pixel chuyển sang sleeve, 0 pixel còn trên torso, 0 pixel mất; fixture so với ownership 0.34 | [Tách lớp](../../artifacts/concept35_body_panels.json), [tests](../../artifacts/concept35_tests.log) |
| Ngực dưới tay và vạt áo | Đạt: 5.808 body-core pose; neutral/winding, collar/belt neo; mỗi vạt theo đúng chân trong các view sau/nghiêng | [Body panels](../../artifacts/concept35_body_panels.json) |
| Rig, UV, grip và gameplay | Đạt: 11.616 pose tay; 4.656 combat + 976 smooth, giữ source lengths/UV/palm và stance hiện hành | [Vải](../../artifacts/concept35_sleeve_deformation.json), [combat](../../artifacts/concept35_combat_constraints.json), [stance](../../artifacts/concept35_actor_stance.json) |
| Runtime và UI | Đạt: 752 framebuffer chu kỳ; 16 GPU probe; 11 UI state ở ba viewport. Native kiểm thêm mesh ngực thứ bảy | [Native](../../artifacts/concept35_native.log), [UI](../../artifacts/concept35_ui.log), [so 0.34 → 0.35](../../artifacts/concept35_combat_review.html), [11 action](../../artifacts/concept35_frame_review.html) |
| Mỹ thuật để phát hành | Partial: vùng khuất dùng màu vải bổ sung; nếp gấp sâu, foreshortening và kiểu nắm cần art review | [Chi tiết](../../artifacts/concept35_detail_attack_03.png), [giới hạn](concept-character-body-panels-0.35.md#giới-hạn) |

PNG nguồn giữ hash. Bảy clip kiểm đủ 400 frame RGB, 0 mismatch: [combat](../../artifacts/concept35_combat_clip_validation.json), [motion](../../artifacts/concept35_clip_validation.json). Browser giải mã 165 combat/overlay + 352 action PNG, controls/responsive đạt, 0 page error: [combat](../../artifacts/concept35_combat_review_browser.json), [action](../../artifacts/concept35_frame_review_browser.json). Confidence geometry/ownership: high, code + runtime; mỹ thuật: partial, screenshot review. Native Linux/X11/Mesa llvmpipe; chưa kiểm engine Windows hoặc benchmark FPS.

# Baseline — vải tay áo theo khuỷu 0.34

**600/600 Linux/Godot 4.7.2**, 0 failure, log cuối không có runtime/script error. Vải cánh tay trên có biến dạng cục bộ, mesh theo lưới tam giác và contour theo cùng ô; bracer/palm giữ form, grip vũ khí/VFX kế thừa 0.33. Phần bổ sung ở vai giảm chỗ hở; cache binding/contour giảm tính toán renderer. [Phạm vi, runtime và giới hạn](concept-character-soft-sleeve-0.34.md).

| Kiểm tra | Kết quả | Evidence |
|---|---|---|
| Vải, UV và winding | Đạt: 11.616 pose tay/11 action; không tam giác lật, source UV/neutral giữ nguyên, bracer/palm cứng. Cạnh vải 0,63153–1,35698 lần nguồn | [Vải](../../artifacts/concept34_sleeve_deformation.json), [regression](../../artifacts/concept34_tests.log) |
| Khớp và gameplay | Đạt regression: 4.656 combat + 976 smooth pose; grip/stance/zero-time turn giữ hợp đồng. Fixture dash kiểm cả navigation trace; callback đóng túi kiểm sau process tick | [Combat](../../artifacts/concept34_combat_constraints.json), [stance](../../artifacts/concept34_actor_stance.json) |
| Runtime và UI | Đạt: 752 frame, ba vũ khí, 11 action, hai body × tám hướng; 16 probe GPU và 11 UI state/ba viewport | [So 0.33 → 0.34](../../artifacts/concept34_combat_review.html), [action](../../artifacts/concept34_frame_review.html), [native](../../artifacts/concept34_native.log), [UI](../../artifacts/concept34_ui.log) |
| Chất lượng hình vẽ phát hành | Partial: vải uốn và viền đã chỉnh; nếp gập mạnh, kiểu nắm, foreshortening và vùng vẽ bổ sung vẫn cần art review | [Chi tiết native](../../artifacts/concept34_detail_attack_03.png), [giới hạn](concept-character-soft-sleeve-0.34.md#giới-hạn) |

PNG gốc giữ nguyên hash. Clip dùng nguyên framebuffer lossless; kiểm tra [RGB combat](../../artifacts/concept34_combat_clip_validation.json), [RGB motion](../../artifacts/concept34_clip_validation.json), [browser combat](../../artifacts/concept34_combat_review_browser.json) và [browser action](../../artifacts/concept34_frame_review_browser.json). Evidence geometry/attachment: high, code + runtime. Mỹ thuật: partial, native screenshot review. Chưa kiểm engine Windows hoặc benchmark FPS trong pass này.

# Baseline — tay đỡ và đường nối áo 0.33

**598/598 Linux/Godot 4.7.2**, 0 failure, log cuối không có runtime/script error. Tay đỡ kiếm có counterbalance, cuff roll và nhịp thu riêng; tay còn lại bảo vệ ngực khi đấm. Nối khuỷu chỉ bù phía áo mở, không thêm cap phía chồng; màu nối lấy từ pigment sleeve theo view. [Phạm vi, runtime và giới hạn](concept-character-support-0.33.md).

| Kiểm tra | Kết quả | Evidence |
|---|---|---|
| Khớp, grip, timing | Đạt regression; 4.656 combat + 976 smooth pose; thêm 1.552 pose tay đỡ | [Tests](../../artifacts/concept33_tests.log), [tay đỡ](../../artifacts/concept33_support_arm.json) |
| Runtime, điều khiển và UI | Đạt native smoke: 752 frame, 11 action, 3 vũ khí, 2 body × 8 hướng; 16 GPU probe, 11 UI state / 3 viewport | [Inspector 0.32 → 0.33](../../artifacts/concept33_combat_review.html), [action](../../artifacts/concept33_frame_review.html), [native log](../../artifacts/concept33_native.log), [UI](../../artifacts/concept33_ui.log) |
| Chất lượng hình vẽ phát hành | Partial: tay đỡ và silhouette đã chỉnh; nếp áo gập mạnh, kiểu nắm và foreshortening vẫn dựa trên drawing đứng | [Chi tiết native](../../artifacts/concept33_detail_attack_03.png), [giới hạn](concept-character-support-0.33.md#giới-hạn-và-lượt-tiếp-theo) |

PNG nguồn giữ nguyên hash; 7 clip đối chiếu RGB lossless, hai inspector qua kiểm tra Chrome Windows. Evidence khớp/renderer: high, code + runtime. Đánh giá mỹ thuật: partial, screenshot + pose review. Engine Windows và benchmark FPS chưa được kiểm lại trong pass này.

# Baseline — cổ tay và nhịp chém 0.32

**593/593 Linux/Godot 4.7.2**, 0 failure. Palm mesh xoay riêng tại cuff, grip vũ khí/VFX theo palm; curve đơn điệu liên tục qua contact, upper sleeve thuôn cong, cuff chỉ nối khoảng pigment nguồn bị thiếu. [Phạm vi, runtime và giới hạn](concept-character-palm-0.32.md).

[Inspector 0.31 → 0.32](../../artifacts/concept32_combat_review.html) có ba vũ khí, hai body, tám hướng và overlay wrist/palm; [11 action](../../artifacts/concept32_frame_review.html). Source PNG giữ nguyên; cần thêm drawing ngón tay và nếp gập mạnh để nghiệm thu mỹ thuật phát hành.

# Baseline — khớp tay và vũ khí 0.31

**589/589 Linux/Godot 4.7.2**. Combat dùng pose native, giới hạn elbow và góc cổ tay, blend theo hierarchy; thương hai tay cùng cán. 4.656 pose + 976 playback pose qua kiểm tra attachment/continuity; 144 framebuffer combat và 21 overlay khớp đã chụp. [Phạm vi, bằng chứng và giới hạn](concept-character-combat-0.31.md).

[Inspector trước/sau 0.30–0.31](../../artifacts/concept31_combat_review.html) có kiếm/thương/tay không, hai body, tám hướng; [11 action](../../artifacts/concept31_frame_review.html) có 352 frame. GPU 16 probe, UI 11 trạng thái và gameplay WASD/skill smoke qua. Màu PNG nguồn giữ nguyên; bàn tay chưa có drawing/rig độc lập, foreshortening và nếp gập mạnh cần tiếp tục art review, chưa xác nhận phát hành.

# Baseline — tay áo và nhịp bước 0.30

**581/581 Linux/Godot 4.7.2**, không có runtime/script error trong log cuối. Bỏ tube/chấm/nét thừa ở sleeve; vai/forearm có follow-through, hip theo contact, boot roll trong swing và chân xa–gần; grip kiếm nam N nằm trên pigment bàn tay. [Phạm vi và bằng chứng](concept-character-sleeve-gait-0.30.md).

| Kiểm tra hiện hành | Kết quả | Evidence |
|---|---|---|
| Sleeve/grip | Đạt regression UV/winding/xương và grip; native before/after bỏ dải xanh thừa | [Chi tiết](../../artifacts/concept30_detail_run_02.png), [tests](../../artifacts/concept30_tests.log) |
| Contact và chuyển trọng lượng | Đạt geometry: 5.808 pose, 1.328 stance rig, 7.780 stance ActorView; world drift tối đa 0,00116 pixel ở steady gait | [Geometry](../../artifacts/concept30_geometry_review.json), [Actor](../../artifacts/concept30_actor_stance.json) |
| Viền/ownership | Đạt 16 GPU probe biên/lõi mực; minify đối chiếu capture native | [GPU biên](../../artifacts/concept30_edge_filter.json), [GPU lõi](../../artifacts/concept30_ink_core.json) |
| Native/action review | 352 frame × 16 view, 11 bảng S/N, 256 frame motion/gameplay và 32 ảnh chi tiết | [Inspector trước/sau](../../artifacts/concept30_frame_review.html), [W/S](../../artifacts/concept30_vertical.webp) |
| Inspector/clip | Browser giải mã 352 PNG, điều khiển/responsive; WebP lossless so RGB với PNG | [Browser](../../artifacts/concept30_frame_review_browser.json), [RGB](../../artifacts/concept30_clip_validation.json) |
| HUD/F3/F6/túi/nhiệm vụ/pause | Đạt 11 trạng thái tại ba kích thước | [UI log](../../artifacts/concept30_ui.log) |
| Chất lượng nhân vật để phát hành | Một phần: source PNG và các nếp gập/action mạnh còn cần art review; kiểm contact không thay cho đánh giá độ tự nhiên | [Giới hạn](concept-character-sleeve-gait-0.30.md) |

Native X11/Mesa llvmpipe; không phải benchmark FPS, Godot Windows chưa chạy lại. Các phần dưới là baseline lịch sử.

## Baseline — từng hướng/pha chuyển động 0.29

**577/577 trên Linux/Godot 4.7.2.** Kiểm 5.808 pose, 1.328 cặp stance rig và 7.780 cặp qua ActorView/root interpolation thật; world foot drift lớn nhất 0,00116 pixel ở tốc độ ổn định. PNG màu giữ SHA-256 concept. [Phạm vi và hạn chế](concept-character-frame-review-0.29.md).

| Kiểm tra hiện hành | Kết quả | Evidence |
|---|---|---|
| Viền | Đạt contract lõi opaque + fringe hẹp; GPU 12 mẫu subpixel/fade/đen-trắng, lỗi màu lõi tối đa 0,00481 | [Probe](../../artifacts/concept29_ink_core.json), [nền sáng](../../artifacts/concept29_outline_light.png) |
| Chân/quần | Đạt geometry: cuff không kéo nếp quần đứng; pants silhouette không tự cắt, giày S/N không xoay ngang | [Geometry](../../artifacts/concept29_geometry_review.json), [bảng chạy](../../artifacts/concept29_phases_run.png) |
| Stride S/N/chéo | Đạt ở steady gait qua root actor và native WASD; foot lock khi dừng/đảo hướng còn cần nghiệm thu | [Actor](../../artifacts/concept29_actor_stance.json), [W/S gameplay](../../artifacts/concept29_vertical.webp) |
| Vận công/phòng thủ | Đạt grip theo xương nguồn, hai tay gần ngực; phía trước che khuất đúng theo áo/đầu | [Vận công](../../artifacts/concept29_phases_channel.png), [phòng thủ](../../artifacts/concept29_phases_defend.png) |
| Bao phủ action/hướng | Native 352 frame × 16 view, 11 bảng S/N; inspector giải mã cả 352 frame và kiểm điều khiển | [Inspector](../../artifacts/concept29_frame_review.html), [Browser](../../artifacts/concept29_frame_review_browser.json) |
| HUD/F3/F6/túi/nhiệm vụ/pause | Đạt 11 trạng thái ở ba kích thước | [UI log](../../artifacts/concept29_ui.log) |
| Toàn bộ mỹ thuật/animation phát hành | Một phần: màu/interior source PNG, pose ngã và góc gập mạnh còn cần drawing riêng | [Giới hạn](concept-character-frame-review-0.29.md) |

Native tổng 608 frame runtime và 33 ảnh review; framebuffer X11/Mesa llvmpipe, không phải benchmark FPS PC. Godot Windows chưa chạy lại. Các mục dưới đây là baseline lịch sử.

## Baseline — viền mực và tách chi tiết 0.28

**569/569 trên Linux/Godot 4.7.2.** Bốn assertion mới kiểm 96 contour nguồn theo pose, 32 giày liền, profile fingertips thuộc tay và gấu áo loại vùng quần. GPU probe hai atlas × nền đen/trắng đo biên 50% alpha: sai lệch RGB tối đa 0,00278 với màu foreground đúng, dưới ngưỡng 0,025. PNG màu vẫn trùng SHA-256 concept.

| Kiểm tra hiện hành | Kết quả | Evidence |
|---|---|---|
| Viền/màu mép | Đạt contract: contour vector AA và lọc màu loại pixel không thuộc bộ phận trước nội suy | [Nền sáng](../../artifacts/concept28_outline_light.png), [nền tối](../../artifacts/concept28_outline_dark.png), [GPU probe](../../artifacts/concept28_edge_filter.json) |
| Tách tay/gấu áo/giày | Đạt regression; các chi tiết ngón tay/quần đã xác định không còn trên lớp thân, mỗi boot liền | [Tách lớp](../../artifacts/concept28_isolated_parts.png), [tests](../../tests/concept_character_tests.gd) |
| Animation/gameplay | Đạt: regression xương/mesh/grip/authority và native nhận WASD/Shift/bốn Cổ | [Log](../../artifacts/concept28_tests.log), [quay/đánh](../../artifacts/concept28_turn.webp), [gameplay](../../artifacts/concept28_gameplay.webp) |
| HUD/F3/F6/túi/nhiệm vụ/pause | Đạt: 11 ảnh ở ba kích thước cửa sổ | [UI log](../../artifacts/concept28_ui.log) |
| Toàn bộ nhân vật vector/production | Một phần: viền vector, màu/nét bên trong là PNG; key pose và phụ kiện còn thiếu artwork | [Phạm vi/giới hạn](concept-character-contours-0.28.md) |

Native gồm 21 PNG và 160 frame; capture X11/Mesa llvmpipe dùng review, không phải benchmark. Windows chưa chạy lại ở 0.28. Số liệu dưới đây là baseline lịch sử.

## Baseline — tay áo và phòng thủ 0.27

**565/565 trên Linux/Godot 4.7.2.** Sáu assertion mới bảo vệ diện tích UV tay nguồn, winding/cạnh tam giác thật, bàn tay/grip và phòng thủ gọn với kiếm/thương hướng lên. Kiểm geometry phát hiện 12.171 mẫu tam giác tay đảo ở 0.26; 0.27 không còn mẫu đảo trong hai body × tám hướng × hai tay × 11 hành động × 33 thời điểm. Số liệu này không phải số frame hoặc số pixel nhìn thấy. Hai PNG concept giữ nguyên SHA-256.

| Kiểm tra hiện hành | Kết quả | Evidence |
|---|---|---|
| Boot, di chuyển, bốn Cổ, save | Đạt regression; native nhận input và kỹ năng thật | [Log test](../../artifacts/concept27_tests.log), [gameplay](../../artifacts/concept27_gameplay.webp) |
| Tay áo/bàn tay | Đạt: UV gốc đầy đủ, không đảo/kéo méo tam giác; grip bám bàn tay | [Geometry](../../tests/concept_articulation_tests.gd), [số liệu](../../artifacts/concept27_sleeve_audit.json), [quay/đánh](../../artifacts/concept27_turn.webp) |
| Phòng thủ | Đạt contract: hai tay gần ngực, xương theo source view, kiếm/thương dựng lên | [Ảnh native](../../artifacts/concept27_defend.png) |
| Render/opacity | Đạt native: sáu indexed mesh/pose và fade alpha 50% trên 16 đầu | [Native log](../../artifacts/concept27_native.log), [metadata](../../artifacts/concept27_capture.json) |
| HUD/F3/F6/túi/nhiệm vụ/pause | Đạt: 11 capture ở ba kích thước cửa sổ | [UI log](../../artifacts/concept27_ui.log), [metadata UI](../../artifacts/ink20_ui_visual_capture.json) |
| Mỹ thuật mọi pose/trang phục 1:1 | Một phần: source giữ byte; joint underpainting, key pose/trang bị còn thiếu artwork | [Phạm vi/giới hạn](concept-character-sleeves-0.27.md) |

Native gồm 18 PNG và 160 frame. Log không có lỗi script/runtime; driver báo không hỗ trợ đổi V-Sync. Capture X11/Mesa llvmpipe dùng để review, không phải benchmark PC. Windows chưa được chạy lại ở 0.27. Các kết quả dưới đây là lịch sử từng baseline.

## Baseline — chuyển hướng, vạt áo và vũ khí 0.26

**559/559 trên Linux/Godot 4.7.2.** So với 0.25 có 12 assertion mới: 128 tổ hợp body/cặp hướng, hierarchy xuyên suốt transition, tỷ lệ xương view đang vẽ, frame nhận lệnh giữ cả pose/view/tip, thứ tự che khuất tay theo view, contact shadow, mesh/neo áo/winding và ownership/góc vung kiếm. Hai PNG runtime trùng SHA-256 bản concept đã duyệt.

| Kiểm tra hiện hành | Kết quả | Evidence |
|---|---|---|
| Boot, di chuyển, bốn Cổ | Đạt; native nhận input thật, không lỗi runtime | [Log test](../../artifacts/concept26_tests.log), [gameplay](../../artifacts/concept26_gameplay.webp), [metadata](../../artifacts/concept26_capture.json) |
| Chuyển hướng/hierarchy | Đạt contract trên geometry thực; không kéo root gameplay | [Chuyển hướng/đòn đánh](../../artifacts/concept26_turn.webp), [assertions](../../tests/concept_articulation_tests.gd) |
| Áo/giày/vũ khí | Đạt contract; áo không đảo triangle, giày giữ form, guard tách khỏi fist/body, profile sword đi ra ngoài | [Đòn đánh](../../artifacts/concept26_attack.png), [tay không](../../artifacts/concept26_unarmed.png), [đi/chạy](../../artifacts/concept26_motion.webp) |
| Render/opacity | Đạt native: sáu indexed mesh/pose và 16 đầu fade alpha 50% giữ nguồn đúng | [Native log](../../artifacts/concept26_native.log), [opacity](../../artifacts/concept26_opacity_half.png) |
| HUD/F3/F6/túi/nhiệm vụ/pause | Đạt: 11 ảnh ở ba kích thước cửa sổ | [Log UI](../../artifacts/concept26_ui.log), [metadata UI](../../artifacts/ink20_ui_visual_capture.json) |
| Mỹ thuật mọi pose/trang phục 1:1 | Một phần: source drawing giữ byte, các frame vẫn nội suy và phụ kiện chưa có đủ artwork | [Phạm vi/giới hạn 0.26](concept-character-motion-0.26.md) |

Native gồm 16 PNG và 160 frame: 48 đi/chạy, 48 chuyển hướng/đánh, 64 gameplay WASD/Shift. Capture trên X11/Mesa llvmpipe dùng để review, không phải benchmark PC. Windows chưa được chạy lại ở mốc 0.26; số liệu lịch sử dưới đây thuộc từng baseline.

## Baseline — sửa tách lớp và vận động nhân vật 0.25

**547/547 trên Linux/Godot 4.7.2.** Tám assertion mới kiểm geometry nguồn đang vẽ, độ dài xương, bám cổ/vai/hông, giày giữ kích thước, stance ngang, ownership và cast grip. Native review có 15 PNG, 48 frame tám hướng và 64 frame gameplay nhận input thật; kiểm opacity 50% trên 16 đầu. UI smoke chụp lại 11 trạng thái. Xem [kết quả và giới hạn 0.25](concept-character-articulation-0.25.md).

## Baseline — nhân vật nguồn concept 0.24

Ngày 11/10/2026. **539/539 assertions đạt trên Linux, Godot 4.7.2 Compatibility.** World/HUD/F6 dùng màu trực tiếp từ bản vẽ đã duyệt với mask opacity và joint riêng từng hướng; F3 mặc định giữ chân dung concept nguyên bản.

| Kiểm tra | Kết quả | Evidence |
|---|---|---|
| Runtime / regression | Đạt, không lỗi trong log | [539 assertions](../../artifacts/test_results_linux.json), [log](../../artifacts/concept24_tests.log) |
| Hình nguồn và 8 hướng | Đạt: hai PNG màu trùng SHA-256 bản duyệt, 96 mask triangulate hợp lệ | [World](../../artifacts/concept24_world_quarter.png), [hai body × tám hướng](../../artifacts/concept24_directions.png) |
| Di chuyển / bốn Cổ | Đạt hợp đồng pose/grip/authority; mỹ thuật chuyển động còn cần review | [48 frame đi/chạy](../../artifacts/concept24_motion.webp), [12 capture native](../../artifacts/concept24_capture.json) |
| HUD / F3 / F6 / modal | Đạt: chụp lại 11 trạng thái native ở ba kích thước cửa sổ, log không có lỗi | [Metadata UI](../../artifacts/ink20_ui_visual_capture.json), [log UI](../../artifacts/concept24_ui.log) |
| Khớp mọi pose/trang bị 1:1 | Một phần: animation nội suy; nón/tóc/thương còn dùng lớp vector cũ | [Giới hạn 0.24](concept-character-runtime-0.24.md), [trang bị](../../artifacts/concept24_equipment.png) |

Các capture dùng X11/Mesa llvmpipe, không phải benchmark PC mục tiêu. Windows chưa được chạy lại ở mốc 0.24. Báo cáo dưới đây giữ kết quả baseline 0.19, không áp dụng số liệu source/ZIP/Windows lịch sử cho renderer hiện hành.

## Baseline — Nét mực và màu giấy 0.19

**524/524 assertions đạt trên Windows và Linux, Godot 4.7.2 Compatibility.** Các capture lấy từ renderer native đang dùng trong gameplay và F6.

| Phần | Kết quả |
|---|---|
| Giữ nhân vật cũ | Alpha/kích thước 131 SVG khớp baseline 0.15; mốc đầu -43/thân -21, 36 diện mạo, tám hướng, 11 trạng thái |
| Phong cách | Màu đất/ngà, tóc ô-liu, bóng dải mảng, nét gạch trong alpha cũ; shader viền mực ấm và grain neo texture, không TIME/RNG |
| Ổn định | Framebuffer sheet hai diện mạo × tám hướng giống từng byte qua 12 frame đứng yên |
| Animation | Kiếm giữ grip/góc pha .17–.21 rồi ra đòn .21–.38; mắt nhắm ngắn và mở lại, reduced motion bỏ biểu cảm phụ. Trọng tâm/vạt áo rõ hơn; giữ foot contact và khớp tay đổi hướng |
| Hiệu ứng | 13 kiểu nét bút dày–mỏng/mảnh giấy/star lệch/khiên rỗng; endpoint hữu hạn, pressure có biến thiên và geometry xác định. Một triangle array cho mỗi nét, mép alpha liên tục |
| Gameplay | Tay phóng chính xác, contact .28s, moving cast giữ chân/áo, pause/reduced/save/cooldown/damage authority vẫn được kiểm tra |
| Native | 18 PNG; 96 frame WASD/Shift/1–4; 144 frame F6; 600 frame world/F6; 180 frame góc ngang; 240 frame tám góc |
| Source | Cold import không có .godot ban đầu, tải đủ 131 SVG/36 look/13 VFX; 497 runtime files so byte với snapshot và ZIP, CRC ZIP đạt |

Năm acceptance mới bảo vệ biểu cảm, giữ grip/góc trước release, endpoint nét bút, chiều rộng hữu hạn có lực và hình học xác định. Các guard giải phẫu, vải UV, layer tay/vũ khí, contact liên tục và nhận diện vẫn chạy. Native stability bổ sung kiểm pixel đứng yên.

[Review hình thật](build-review-0.19.md) ghi quan sát/giới hạn. 60Hz là tần suất lấy mẫu xác định của framebuffer, không phải benchmark FPS hay nghiệm thu phát hành. Phong cách được diễn giải từ nguồn Klei/Steam; không dùng asset của DST hay tuyên bố đã đo animation của game đó.

[Clip tám góc](evidence/ink19_turn_motion.webp) · [GIF](evidence/ink19_turn_motion.gif) · [Góc ngang](evidence/ink19_side_motion.webp) · [Gameplay/F6](evidence/ink19_motion.webp) · [8 hướng](evidence/ink19_character_directions.png) · [13 VFX](evidence/ink19_feedback_sheet.png) · [Windows](evidence/test_results_windows.json) · [Linux](evidence/test_results_linux.json) · [FSD/WBS](../implementation/PIXEL_2D_MIGRATION_PLAN.md) · [Mỹ thuật](art-direction-0.19.md) · [Phản hồi](feedback-design-0.19.md).

Tái hiện: RunTests.bat; các native smoke với -- --test-mode; tools/render_directional_preview.py và tools/pack_handoff.py. Baseline 0.18 giữ ở artifacts/baseline_v18 trong workspace; golden alpha vẫn là tests/fixtures/character_v15_baseline.json.

Source SHA256: b1eefd3f88c36a30c04bd38a3f1df89a6c079b6d449d3773bb249d2a7c0dede7.
