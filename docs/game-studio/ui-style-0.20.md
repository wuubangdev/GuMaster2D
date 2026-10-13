# UI mực trên giấy — 0.20

Nhân vật dùng chung world/F6/diện mạo động F3 hiện theo [thân sạch và asset vải modular 0.37](concept-character-modular-cloth-0.37.md). Các mục dưới giữ lịch sử UI và nguồn concept; capture UI 0.37 lưu riêng tại `artifacts/concept37_ui/`.

Baseline nhân vật 0.30 dùng [tay áo và nhịp bước 0.30](concept-character-sleeve-gait-0.30.md), tiếp nối contour 0.28, tay áo/phòng thủ 0.27 và xương nguồn 0.25. Các mục dưới đây giữ lịch sử thay đổi UI và nguồn concept.

Ngày 11/10/2026. Hướng UI được chọn theo yêu cầu áp dụng concept mới trong game. Mốc thị giác là [UI concept 01](concepts/ink20/ui-concept-01.png); ảnh chỉ dùng làm tham chiếu phong cách và bố cục, không được đưa vào runtime như một màn hình phẳng.

## Hướng mỹ thuật

| Thành phần | Quy ước |
|---|---|
| Bảng nền | Giấy ngà ấm `#e8d3ad`, vùng sáng `#f1e1c2`, bóng giấy `#c5a879`; thớ giấy thưa và cố định, không nhấp nháy |
| Nét | Mực nâu than `#302923`, viền 1–2 px, góc vẽ tay và một vài nét khô; tránh góc kim loại đối xứng và viền phát sáng |
| Nhấn | Ngọc trầm `#3e6550` cho trạng thái chọn/sẵn sàng; đỏ đất `#a24d3a` cho nguy hiểm/thiếu điều kiện; đồng nâu `#9a7040` dùng cho phần thưởng và điểm phụ |
| Chữ | Chữ chính màu mực, mô tả màu nâu xám; cỡ nhỏ vẫn phải đọc ở 960×640. Màu chỉ bổ sung trạng thái, không thay cho nhãn |
| Cửa sổ | HUD, hành trang, nhân vật, nhiệm vụ, thiết lập và xưởng cùng dùng nền giấy, bóng ngắn, hạt giấy xác định và viền mực |
| Dock Cổ | Giữ vùng tối gọn để tách khỏi bản đồ; viền giấy/mực, phím tắt sáng, icon và trạng thái hồi chiêu đọc rõ |
| Ô trang bị/vật liệu | Lưới 5 cột × 6 hàng như concept, ô giấy vuông gần đúng, icon mực màu đất, trạng thái chọn có viền ngọc |
| Chỉ số | HP đỏ đất, chân nguyên xanh đá, kinh nghiệm ngọc; track màu giấy sẫm với viền mực. Số đọc là giá trị thật, vệt mất máu chỉ là phản hồi |

## Phạm vi triển khai

1. Chuẩn hóa `GuPixelUI` để mọi PanelContainer/Button dùng chung chất giấy, viền, trạng thái hover/pressed/disabled và palette.
2. Đồng bộ HUD và cửa sổ nhiệm vụ, nhân vật, hành trang, pause, xưởng F6; giữ nguyên nội dung, phím tắt, luồng thao tác và dữ liệu runtime.
3. Vẽ lại các control riêng: dock kỹ năng, ô túi, thanh sinh lực/chân nguyên, doll preview, minimap và hàng Cổ đang khảm.
4. Chạy regression test, mở gameplay ở 960×640 và 1280×720, kiểm trạng thái HUD/túi/F3/F6/nhiệm vụ/pause, sau đó lưu ảnh evidence.

## Trạng thái

- Đã áp dụng palette và trạng thái khung dùng chung; panel có grain ổn định và nét góc mực.
- Đã restyle action dock, thanh chỉ số, minimap tròn, preview nhân vật, ô hành trang và hàng thức ăn; grid đổi sang 5×6 với ô gần vuông.
- Native review đã chụp HUD, túi, nhân vật, nhiệm vụ, pause và xưởng tại 1280×800; HUD, túi và xưởng cũng được chụp tại 1280×720; HUD/túi ở 960×640. Ở 960×640, nội dung hành trang cuộn dọc để giữ nguyên vùng hiển thị các nút điều hướng.
- Regression suite: 531/531 đạt. Screenshot native dùng Mesa llvmpipe để kiểm tra bố cục, không dùng làm benchmark hiệu năng máy người chơi. Chưa gọi production-ready.

Evidence: [HUD 1280×800](../../artifacts/ink20_ui_hud_1280.png), [hành trang 1280×800](../../artifacts/ink20_ui_inventory_1280.png), [HUD 1280×720](../../artifacts/ink20_ui_hud_1280x720.png), [hành trang 1280×720](../../artifacts/ink20_ui_inventory_1280x720.png), [xưởng 1280×720](../../artifacts/ink20_ui_studio_1280x720.png), [hành trang 960×640](../../artifacts/ink20_ui_inventory_960.png), [nhân vật](../../artifacts/ink20_ui_character_1280.png), [nhiệm vụ](../../artifacts/ink20_ui_journal_1280.png), [pause](../../artifacts/ink20_ui_pause_1280.png), [xưởng 1280×800](../../artifacts/ink20_ui_studio_1280.png), [metadata](../../artifacts/ink20_ui_visual_capture.json).

## Nghiệm thu

- Nội dung game và hitbox tương tác không thay đổi; button hover/pressed/disabled vẫn phân biệt được.
- Chữ chính và số HP/khí tương phản rõ ở 960×640; các cửa sổ có thể cuộn nếu không đủ chiều cao.
- HUD không che tâm giao chiến; minimap và mục tiêu vẫn đọc được; lưới hành trang có đủ 30 ô.
- Panel/hạt giấy đứng yên không rung; reduced motion, pause và thao tác modal giữ đúng hành vi.

Mã dùng chung: [pixel_ui.gd](../../scripts/ui/pixel_ui.gd), [game_hud.gd](../../scripts/ui/game_hud.gd); harness chụp màn hình: [ui_style_visual_smoke.gd](../../tests/ui_style_visual_smoke.gd). Quy ước nhân vật mực/giấy: [art direction 0.19](art-direction-0.19.md).

## Tinh chỉnh theo ảnh concept — 0.21

Sau khi đối chiếu trực tiếp [UI concept 01](concepts/ink20/ui-concept-01.png) và [character concept 01](concepts/ink20/character-concept-01.png), phần runtime được tăng chất liệu để gần với hình đã vẽ hơn: giấy ngà pha wash loang và sợi giấy ổn định; viền panel/ô đồ/dock dùng nét cọ có độ lệch nhỏ thay cho khung hình học; huy hiệu chân dung chuyển sang vòng giấy–đồng–mực; màu đỏ đất, xanh ngọc trầm và nâu được hiệu chỉnh ấm hơn. Thanh sinh lực/khí có nét khô nhỏ nhưng số liệu thật và trạng thái hồi chiêu vẫn rõ.

Ảnh concept là tham chiếu art direction, không được nhúng làm texture màn hình; các chi tiết mới được vẽ bằng Godot để UI còn co giãn và tương tác. Hạt giấy/loang màu dùng seed cố định nên không nhấp nháy. Sau tinh chỉnh đã chụp lại 11 trạng thái UI trên 960×640, 1280×720 và 1280×800; smoke UI không ghi nhận lỗi vẽ, regression 531/531 đạt. Đây là lượt polish theo concept, vẫn cần review trên PC mục tiêu trước khi gọi production-ready.

Evidence được cập nhật: [HUD 1280×720](../../artifacts/ink20_ui_hud_1280x720.png), [hành trang 1280×720](../../artifacts/ink20_ui_inventory_1280x720.png), [xưởng 1280×720](../../artifacts/ink20_ui_studio_1280x720.png), [hành trang 960×640](../../artifacts/ink20_ui_inventory_960.png), [metadata](../../artifacts/ink20_ui_visual_capture.json).

## Bám sát bản vẽ đã duyệt — 0.22

Đợt này chuyển phần chất liệu thành hình dạng đọc được ở gameplay: panel giấy có bóng lệch, hai nét viền mực rung nhẹ, nét khô và móc góc; tab/nút có trạng thái vẽ tay thay cho khung mặc định. Chữ UI chuyển sang Patrick Hand cho cả tiếng Việt, giữ font/body size theo control và vùng hiển thị để không làm thay đổi nội dung hoặc luồng thao tác. Font được lấy từ Google Fonts, có hỗ trợ tiếng Việt và đi kèm SIL Open Font License trong `assets/fonts`.

Renderer nhân vật vẫn là rig SVG lắp ghép 8 hướng. Áo jade pilot có gấu rộng hơn, ve giao lĩnh ngà, đai/khóa, bùa treo, sắc độ mềm và các nét cọ/nếp vải cố định theo texture; giữ nguyên pivot, chiều cao chuẩn và các part khác ngoài 48 view thân áo. Đây là cải tiến art-direction cho asset, chưa thay thế đánh giá animation, độ đọc ở PC mục tiêu hoặc production sign-off.

Evidence được chụp lại sau thay đổi: [HUD 1280×720](../../artifacts/ink20_ui_hud_1280x720.png), [hành trang 1280×720](../../artifacts/ink20_ui_inventory_1280x720.png), [nhân vật 1280×800](../../artifacts/ink20_ui_character_1280.png), [HUD 960×640](../../artifacts/ink20_ui_hud_960.png), [hành trang 960×640](../../artifacts/ink20_ui_inventory_960.png). UI smoke đạt 11/11 captures, không có lỗi vẽ; regression đạt 531/531.

## Chân dung F3 bám concept — 0.23

Modal nhân vật F3 dùng đúng vùng minh họa lớn bên trái của [character concept 01](concepts/ink20/character-concept-01.png) cho diện mạo mặc định. Runtime dùng `AtlasTexture` để cắt ảnh, không vẽ lại hay sinh biến thể; bản trong [assets/characters/character-concept-01.png](../../assets/characters/character-concept-01.png) có SHA-256 trùng khớp ảnh concept nguồn. Vùng hiển thị là `(8, 126, 500, 842)`.

Chân dung nguyên bản chỉ áp dụng khi appearance đúng mặc định nam/áo jade/tóc búi/kiếm/giày vải/không nón. Đổi bất kỳ slot nào thì F3 chuyển về renderer ngoại hình động; rig gameplay và các animation không đổi. Vì concept hiện chỉ có một minh họa lớn, các giới tính, trang phục và vũ khí khác chưa thể cam kết giống concept 1:1 nếu chưa có ảnh concept tương ứng.

UI smoke kiểm tra đúng atlas, vùng cắt, chuyển qua lại giữa chân dung concept và appearance khác; 11/11 trạng thái native được chụp lại. [Modal nhân vật F3](../../artifacts/ink20_ui_character_1280.png).

## Nhân vật ngoài bản đồ bám concept — 0.24

World, chân dung HUD và xưởng F6 đã chuyển sang vẽ trực tiếp các phần từ concept 01/bảng hướng 02, với mask opacity để bỏ giấy và joint riêng từng view. Hai PNG màu khớp byte với bản đã duyệt; F3 mặc định vẫn giữ crop nguyên bản. Renderer có hai body × tám hướng và nối các hành động qua rig hiện hành. Kỹ năng, tay cầm và ghost lướt dùng snapshot của hình nguồn.

Regression Linux đạt 539/539. Native review gồm 12 ảnh và 48 frame đi/chạy; UI được chụp lại 11 trạng thái. Xem [world](../../artifacts/concept24_world_quarter.png), [8 hướng](../../artifacts/concept24_directions.png) và [hợp đồng/giới hạn 0.24](concept-character-runtime-0.24.md). Animation nội suy và phụ kiện chưa có source concept riêng không được coi là bản sao 1:1 của mọi pose/trang bị.
