# FSD — nhân vật mực/giấy, trang phục và kỹ năng

Runtime hiện hành: [thân sạch và asset vải modular 0.37](../../../concept-character-modular-cloth-0.37.md). 112 SVG riêng theo 16 view; torso không giữ pigment ngoài silhouette và đường ráp tay. Năm điểm điều khiển vải mỗi tay; cổ tay/palm/weapon giữ binding hiện hành. Regression 613/613, 2.194 pixel ngoài mask tay cũ được chuyển khỏi thân; 5.808 pose thân, 11.616 pose tay và 2.992 pose asset mới. PNG nguồn giữ nguyên; ngón tay/nếp gập mạnh cần drawing chuyên biệt.

Ngày: 12/10/2026. Trạng thái: **đã bắt đầu pilot runtime ink20-character theo yêu cầu triển khai**. Phạm vi hiện thực đầu tiên: thêm slot giày/nón, asset SVG 8 hướng, xưởng F6 và save tương thích; các hạng mục art/animation còn lại vẫn theo WBS. Tài liệu này bổ sung thiết kế 2D hiện hành; không sửa nội dung nghiệm thu pipeline 3D cũ.

Slice UI/art 0.22 đã đưa mảng áo gần bản concept hơn: 48 hướng thân áo có gấu xòe, ve giao lĩnh, đai/khóa, bùa treo và nét cọ cố định; điểm gốc, chiều cao renderer, 8 hướng mặt, rig liên tục và các lớp phụ kiện vẫn giữ hợp đồng hiện hành. Đây là nâng cấp asset nguồn, chưa thay thế việc review đủ hành động/8 hướng ở kích thước world.

Mốc 0.24 thay đầu/thân/tay/chân pilot bằng màu trực tiếp từ concept 01 và bảng hướng 02: hai body × tám hướng, mỗi view có sáu mask nguồn cùng joint. World/HUD/F6 và các preview động dùng cùng renderer nguồn; F3 mặc định giữ chân dung nguyên bản 0.23. Hình nguồn không sửa màu; opacity riêng loại giấy nền. Animation tiếp tục nội suy, phụ kiện và form outfit riêng còn cần artwork tương ứng. Xem [hợp đồng và kiểm chứng 0.24](../../../concept-character-runtime-0.24.md).

## 1. Mục tiêu và phạm vi

Giữ nhân vật Cổ sư hiện có: tóc đen mái lệch, búi tóc/đuôi ngựa, mắt mực, áo giao lĩnh xanh ngọc, cổ áo ngà, đai vải và vũ khí tu tiên. Phát triển cách vẽ cắt lớp với nét mực có chủ ý, màu lì và chi tiết vải. Hướng tham khảo là [Don’t Starve Together của Klei](https://www.klei.com/games/dont-starve-together); tỷ lệ, trang phục, nhân vật và bộ Cổ vẫn thuộc thiết kế riêng của dự án. Nét mực, giấy, màu lì và nhịp pose trong tài liệu là quyết định mỹ thuật đề xuất, không phải mô tả kỹ thuật engine của Klei.

Mẫu phát triển sau duyệt gồm 2 body × 3 áo × 3 vũ khí × 2 tóc × 2 giày × 3 nón = **216 tổ hợp**. Đây là ma trận cần hỗ trợ, không phải 216 bộ asset đã được vẽ. Mỗi nhân vật phải đọc được ở 8 hướng và 11 nhóm hành động. Chia theo bộ phận và dùng chung timeline để tránh nhân số tổ hợp thành hàng nghìn sheet riêng.

| Nhóm | ID trong thiết kế | Nội dung |
|---|---|---|
| Cơ thể | `male`, `female` | Hai bộ hình đầu/mặt/vai/thân riêng, cùng hợp đồng khớp |
| Áo | `jade`, `crimson`, `ivory` | Thanh Ngọc, Xích Vân, Bạch Vũ; khác cổ/viền/tà, không chỉ đổi màu |
| Vũ khí | `sword`, `spear`, `unarmed` | Kiếm, thương, tay không; khác grip và upper-body pose |
| Tóc | `topknot`, `ponytail` | Tóc trước và sau tách khỏi mặt |
| Giày | `cloth`, `leather` | Giày vải thấp và ủng da; mỗi kiểu đủ hướng, cùng điểm chạm đất |
| Nón | `none`, `bamboo`, `sect` | Không nón, nón lá, quan mây; lớp SVG riêng từng hướng phủ lên phần tóc |

World, ảnh chân dung HUD, F3 và F6 cùng dùng một bộ giải ngoại hình. Trong đợt đầu, đổi ngoại hình vẫn là cosmetic giống chức năng hiện tại. Khi thêm trang bị gameplay, item phải tham chiếu `visual_id` để đi qua bộ giải này; thông số chiến đấu vẫn do hệ trang bị/authority sở hữu.

## 2. Quy chuẩn hình ảnh

| Thành phần | Quy chuẩn đề xuất | Cách nghiệm thu |
|---|---|---|
| Tỷ lệ | Khoảng 3 đầu cao; chân/tay có chiều dài đọc được; hai body cùng chiều cao chuẩn | So sánh silhouette ở world 48 px và preview lớn; chỉ chốt thay tỷ lệ sau duyệt |
| Nét | Viền ngoài đậm hơn nét mặt/nếp vải; độ dày tính ở kích thước hiển thị | Không đen bệt mắt/cổ áo ở 48 px; đường viền không nhấp nháy |
| Mặt ngang | Một mắt nhìn thấy, mũi và tai đúng profile; mắt xa bị che thật | W/E không có hai mắt chính diện trên mặt nghiêng |
| Mặt sau | Không vẽ mắt/mũi qua tóc; gáy/cổ áo/tóc sau có hình riêng | N/NW/NE kiểm ở idle, run, attack |
| Vải | Mảng lớn, 2–3 nếp chính theo lực kéo; hatching chọn lọc ở bóng khuất | Không phủ texture giả bẩn lên toàn bộ áo |
| Bóng/giấy | Màu lì; grain bám tọa độ asset và dừng khi pause | Cùng một pose phải cho hình ổn định; không dùng noise thời gian |
| Màu | Mực `#29251f`, giấy `#eee0be`, ngọc `#73816c`, đá xanh `#7c8c94`, đồng `#ae8952` | Icon/nhân vật/VFX nhận ra cùng một bộ mỹ thuật |
| Di chuyển | Chân tải trọng, đầu ổn định, tóc/tà áo đi sau thân | Không dùng bụi lớn để che bước chân sai |

Ảnh concept có giấy nền để duyệt. Asset chơi thật phải có alpha sạch. Mốc 0.24 giữ nguyên PNG màu nguồn và vẽ qua mask/UV tách sáu bộ phận; opacity resource riêng bỏ giấy quanh silhouette, giữ mặt/cổ áo/tay kín nét. Các part có pivot/joint theo từng hướng và dùng rig liên tục hiện có. Phụ kiện vector giữ làm lớp bổ sung; không chuyển sang 3D hay pixel atlas trong đợt này.

## 3. Yêu cầu chức năng

| ID | Trigger và kết quả | Tiêu chí chấp nhận |
|---|---|---|
| INK-01 | Chọn nam/nữ → thay body/head/face/fit tương ứng | Giữ cell, hướng, action phase và mọi chỉ số; nữ có hình riêng, không scale bộ nam |
| INK-02 | WASD/chéo/action facing → chọn 1 trong 8 view | Mapping S0/SW1/W2/NW3/N4/NE5/E6/SE7 đúng renderer hiện hành; không mirror làm đổi tay cầm |
| INK-03 | Đứng/đi/chạy/dừng → pose rõ tải trọng | Chân chống ít trượt, chân vung có lift; đầu không xoay như quả bóng; mắt không đổi vị trí tùy frame |
| INK-04 | Action → pose đúng 11 nhóm | Idle, walk, run, attack, defend, cast, channel, dash, hit, death, respawn có entry/hold/recovery theo state |
| INK-05 | Đổi áo → thay thân/tay áo/tà/đai trong một outfit set | Không còn tay áo bộ cũ; cổ/đai cố định, tà không kéo giãn cổ áo |
| INK-06 | Đổi giày → thay trái/phải ở ankle/sole socket | Đổi giữa bước chạy không làm bàn chân nổi hoặc đổi chiều dài chân gameplay |
| INK-07 | Đội nón → thay hat front/back + che phần tóc cần thiết | Tóc mái còn đọc được; búi tóc không xuyên nón; nón không bay ngoài đầu khi quay |
| INK-08 | Đổi vũ khí → hình + grip + pose profile tương ứng | Kiếm một tay; thương hai tay với support grip; tay không gỡ toàn bộ mesh/layer vũ khí cũ |
| INK-09 | Đổi tóc → cập nhật hair front/back, mask theo nón | Tóc không nằm trước mặt ở view sau; tóc đuôi ngựa không biến mất khi đổi hướng |
| INK-10 | Preview/chọn Apply/Hủy → commit qua authority | Preview chưa Apply không đổi người trong world; Hủy giữ bản đã lưu; Apply cập nhật world/HUD/F3/F6 |
| INK-11 | Bấm 1–4 → icon và VFX tương ứng 4 Cổ hiện có | Hình thống nhất nét mực; mana/cooldown/power/range/status lấy dữ liệu hiện hành, không hard-code vào art |
| INK-12 | Save/load → ngoại hình có nón/giày hợp lệ | Migration giữ 4 field cũ; thiếu nón/giày dùng mặc định; dữ liệu bất thường không mutate nửa state |
| INK-13 | Pause/ẩn preview/reduced motion → giảm hoạt ảnh phụ | Pause dừng pose và VFX; preview ẩn không chạy render; giữ telegraph/contact cần thiết khi giảm chuyển động |
| INK-14 | Nguồn asset sai/missing → báo rõ + fallback cùng slot | Không crash/null; không reset toàn bộ ngoại hình vì thiếu một cái nón |

## 4. Hợp đồng lớp và khớp

Hệ 2D cắt lớp dùng tên khớp chung cho cả hai body. Điểm gốc actor tại mặt đất giữa hai chân. Pose điều khiển presentation, không thay cell, navmesh, hitbox hoặc sát thương. Godot hiện đã có renderer cắt lớp `GuIllustratedCharacterArt`; mở rộng cấu trúc này từng bước thay vì dựng một renderer song song.

| Khối | Source/layer cần vẽ | Socket và yêu cầu |
|---|---|---|
| Mặt | head/ears/eyes/brows/mouth, trước/ngang/sau | `head`, `face`; eye blink là shape thay thế, không kéo giãn mắt |
| Tóc | front fringe, crown, back tail | `head`, `hair_back`; mặt và tóc tách để nón che crown |
| Nón | back rim/crown/front rim, mỗi facing | `hat`; `hair_mask` và `hide_crown` theo nón/hair/facing |
| Thân/áo | torso, collar, belt, front/back flaps | `torso`, `hip`, `cloth_front/back`; collar/belt không biến dạng theo gối |
| Tay | upper sleeve, fore sleeve, hand L/R | shoulder/elbow/wrist L/R; có vùng overlap khớp, không gãy mép |
| Chân | trousers thigh/shin, boot L/R | hip/knee/ankle L/R; sole contact chung giữa hai loại giày |
| Vũ khí | sword/spear, bàn tay grip thay thế nếu cần | `hand_R`, `weapon_grip`, `weapon_tip`, `support_grip` |
| Phụ kiện | ngọc/đai dây/tóc tà | attachment của áo/tóc, secondary motion có giới hạn |

Không phải mọi thứ đều cần một Sprite2D: giữ mesh biến dạng hiện tại cho tà áo và vẽ tách layer theo manifest. Những layer che nhau phải có overlap an toàn, không dùng stretch toàn bộ áo để giả bước chạy.

### Thứ tự lớp theo hướng

Độ sâu lấy từ facing + pose, không từ một danh sách trước/sau cố định cho mọi hướng. Thứ tự cơ sở: tóc/nón sau → tay xa/vũ khí nếu ở phía xa → chân xa → chân gần → tà sau/thân → đầu/mặt/tóc trước → tay gần/vũ khí phía gần → nón trước. Ở N/NW/NE, thân/đầu che phần tay đang nằm sau cơ thể; tóc đuôi ngựa sau có thể phủ lên lưng. Vũ khí dài phải tách phần occluded khi xuyên qua silhouette, hoặc dùng clip mask rõ ràng.

`near_arm`/`far_arm` và dấu gập khuỷu phải tính lại theo hướng. Với góc quay gấp, blend endpoint và dấu bend cùng nhau; tránh tay vẫn cong theo screen-left khi đang đi screen-right. Không mirror toàn bộ nhân vật để tạo W từ E vì sẽ đảo tay cầm và chi tiết đai bất đối xứng.

### Thiết kế hai giới tính

Hai body dùng chung tên/ý nghĩa socket, nhưng có bộ offset và hình vẽ riêng cho đầu, mặt, vai, cổ áo, torso và bàn tay. Giữ chiều cao và điểm chân chuẩn; không quy định tốc độ hay stats khác theo body. Kiểu tóc là lựa chọn độc lập, nam/nữ đều dùng được cả hai kiểu. Outfit có fit nam/nữ ở phần cần thay, phần dùng chung vẫn tham chiếu cùng resource. Vẽ một chiều nhìn không chứng minh đủ 8 hướng.

## 5. Ngoại hình và trang bị

Renderer hiện dùng 6 field `body/outfit/weapon/hair/boots/hat`. Đợt pilot tạo asset độc lập cho 2 kiểu giày và 2 kiểu nón có hình (thêm `none` cho nón), đủ 8 hướng. Ba bộ outfit hiện dùng cùng form cắt lớp với palette khác nhau; thay đổi form/fit từng bộ vẫn thuộc W06. 11 action và rig 2D tiếp tục dùng pipeline hiện có.

Appearance runtime có 6 ID: `body`, `outfit`, `weapon`, `hair`, `boots`, `hat`. Để bản game cũ vẫn đọc được profile schema 1, writer giữ `appearance` bốn field gốc và lưu hai slot mới trong object tùy chọn `appearance_v2`. Loader ghép hai phần trước khi commit; các profile cũ không có object phụ nhận `boots: cloth`, `hat: none`. ID cosmetic chưa có trong catalog rơi về mặc định riêng slot; kiểu dữ liệu hoặc object không hợp lệ làm toàn bộ load thất bại nguyên tử.

Luồng đổi hình: lựa chọn preview hoặc trang bị hợp lệ → resolve từng slot/fit/mask → appearance snapshot bất biến → renderer world/portrait/F3/F6. Không render trực tiếp từ button label. Catalog cosmetic độc lập với item catalog; một item trang bị về sau tham chiếu `visual_id`, `slot`, `weapon_family` để đổi hình. Item hiện không tồn tại phải được thiết kế gameplay riêng, không tự cấp chỉ số khi đổi kiểu áo/nón.

Migration đề xuất:

1. Đọc profile schema 1 cùng appearance và `appearance_v2` vào vùng tạm.
2. Giữ nguyên bốn field cũ; nếu thiếu hai slot mới thì dùng `cloth`/`none`; ID lạ fallback riêng slot.
3. Validate inventory/progress/position và kiểu dữ liệu trước khi commit state một lần.
4. Writer lưu bốn field trong `appearance` như cũ và chỉ thêm object phụ `appearance_v2` cho phụ kiện. Build cũ bỏ qua key phụ và vẫn đọc được phần hồ sơ chính.
5. Regression dùng profile fixture riêng: legacy 4 field, đủ 6 field, thiếu slot mới, ID lạ và sai kiểu dữ liệu.

## 6. Pipeline asset sau duyệt

1. Dùng concept 01 và bảng hướng 02 làm cả nguồn màu và chuẩn soát ở world/preview. Manifest 0.24 bổ sung mask/pivot/joint cho các part trên bảng nguồn. Riêng F3, diện mạo mặc định giữ crop minh họa lớn làm chân dung tĩnh nguyên bản; appearance khác dùng rig động. Các bộ đồ mới cần concept riêng để khớp hình; animation nội suy không thay thế artwork key pose đầy đủ.
2. Pilot đầu đã nối male/female, các lớp đầu/thân/tay/chân/vũ khí và phụ kiện vector vào renderer hiện hữu; manifest lưu pivot/bounds và giữ đủ 8 view. Soát lại profile khi chỉnh asset tiếp.
3. Author bộ mặt/tóc tách lớp, vùng nón che tóc; làm cloth/leather soles cùng contact anchor.
4. Thêm female fit, outfit/sword/spear/unarmed theo từng set; resource theo phần, không bake 216 animation atlas.
5. Với mỗi phần: ID → body/facing → source path → pivot → bounds → mask → palette/material. Validator kiểm path, số view, socket, finite coordinates, alpha và bounds.
6. Bake/import SVG ở chất lượng đủ cho preview lớn, sampling phù hợp renderer; so world 48 px để giảm nét vụn. Grain chỉ thêm sau khi silhouette/face đúng.
7. Gắn 4 icon và world VFX từ cùng recipe nét/màu. Xuất native contact sheets ở 8 hướng và các key action.
8. Review mỹ thuật ở world/HUD/F3/F6; chạy regression phù hợp trước khi đổi mặc định và đóng gói build.

## 7. Phạm vi còn cần triển khai và duyệt

Phạm vi còn lại: hoàn thiện silhouette 8 hướng, form riêng cho ba outfit, hair-mask tinh hơn, polish 11 action/4 skill, fallback asset thiếu và native review ở world/HUD/F3/F6. Pilot chưa chứng minh production readiness. Xem [ANIMATION_AND_SKILLS.md](ANIMATION_AND_SKILLS.md), [WBS.md](WBS.md) và [ACCEPTANCE.md](ACCEPTANCE.md).
