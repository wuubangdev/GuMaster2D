# Cổ sư — bộ concept chi tiết 02

Ngày 11/10/2026. **Người dùng đã yêu cầu bắt đầu đưa thiết kế vào game.** Pilot runtime `ink20-character` hiện thêm nón/giày 8 hướng, sáu slot ở xưởng F6 và lưu save tương thích; các phần còn lại ở [WBS](WBS.md) vẫn đang triển khai. Bộ concept dùng hướng nét mực/màu lì/giấy, lấy cảm hứng từ [Don’t Starve Together của Klei](https://www.klei.com/games/dont-starve-together).

Mở [REVIEW.html](REVIEW.html) để xem lần lượt 5 bảng chính, phóng lớn và đối chiếu ghi chú. Hai bảng phụ mới nằm tại [bộ bổ sung 03](REVIEW_SUPPLEMENT_03.md). Có thể mở file trực tiếp bằng trình duyệt, không cần cài thư viện. Các trang này chỉ trình bày concept; không phải giao diện game mới.

## 5 bảng chính để duyệt

Hai phần [bổ sung 03](REVIEW_SUPPLEMENT_03.md) và [bổ sung 04](REVIEW_SUPPLEMENT_04.md) thêm năm bảng concept chuyên biệt cho vật liệu, gait, grip, state transition và skill beats. Đây là tài liệu review, không thay thế các board action chính.

| Bảng chọn | Nội dung | Điểm cần duyệt |
|---|---|---|
| [Nhân vật nam/nữ, 8 hướng](character-directions-02.png) | 16 view, mặt trước/ngang/chéo/sau | Giữ identity, tỷ lệ và khuôn mặt; hướng chéo cần khóa rõ khi author source |
| [Thay đồ và tách lớp](wardrobe-modular-02-refined.png) | 6 look + lớp tóc/nón/áo/tay/giày/vũ khí | 3 bộ áo, 2 giày, 3 lựa chọn nón; tóc nằm dưới nón |
| [Đi bộ và chạy](locomotion-keyframes-02-refined.png) | 8 pose walk + 8 pose run | Profile mắt, bước contact/passing, tay và cloth lag |
| [Đánh / thương / cast / thủ](combat-keyframes-02.png) | 4 nhóm × 4 phase | Windup/release/recovery, cầm kiếm/thương, pose phòng thủ |
| [4 Cổ, icon và hiệu ứng](skills-ink-02.png) | Icon → cast → effect → end | Nét/màu và shape khác biệt; không còn neon xanh như bản UI trước |

Hai bảng phụ: [cận cảnh vật liệu/điểm ghép](character-material-study-03.png) và [chu kỳ walk/run](walk-run-cycle-study-03.png).

## Thiết kế áp dụng cho pilot runtime

Bổ sung 03: [cận cảnh vật liệu](character-material-study-03.png), [chu kỳ walk/run](walk-run-cycle-study-03.png). Bổ sung 04: [grip tám hướng](weapon-grip-directions-04.png), [state transitions](action-states-04.png), [skill beats](skill-vfx-breakdown-04.png).

- [FSD nhân vật modular](FSD_MODULAR_CHARACTER.md): 14 yêu cầu, lớp/khớp, nón che tóc, đổi hình đồng bộ, save migration.
- [Animation và kỹ năng](ANIMATION_AND_SKILLS.md): mapping 8 hướng hiện hành, 11 nhóm action, bước đi/chạy, grip, 4 Cổ không đổi cân bằng.
- [WBS nhóm 4 người](WBS.md): 12 gói việc, phụ thuộc, vai trò, mốc và đầu ra nghiệm thu.
- [Timeline pose/VFX 04](ACTION_TIMELINE_04.md): phase theo state, clip danh nghĩa và event gameplay.

- [Ma trận sản xuất chi tiết 03](PRODUCTION_MATRIX_03.md): action coverage, key pose, hướng, layer/manifest, 216 look và cổng review.
- [Cổng duyệt/kiểm chứng](ACCEPTANCE.md): phân biệt concept với animation đã chạy; native evidence và giới hạn.
- [Hợp đồng art đề xuất](art-contract.proposed.json), [appearance v2 mẫu](appearance-v2.example.json): 216 tổ hợp; pilot runtime đã đưa 6 slot vào appearance và giữ profile cũ đọc được qua `appearance_v2`.

Hai body dùng chung tên khớp/timeline nhưng có hình đầu/mặt/thân/fit riêng. Outfit là set thân/tay áo/tà/đai; giày và nón là slot độc lập; vũ khí có grip và upper-body profile riêng. Vì vậy thêm trang phục không phải vẽ lại mọi animation. Item trang bị về sau tham chiếu visual ID; cosmetic không tự tăng chỉ số.

## Trạng thái thực tế

Ảnh vẫn là **concept và chuỗi keyframe**, chưa phải source final. Pilot game có 155 SVG part (gồm 24 layer phụ kiện mới), 216 tổ hợp catalog, hai kiểu nón và giày ở 8 hướng, F6 preview/apply và save tương thích. Quy mô 216 là coverage tổ hợp, không phải 216 bộ asset riêng; form outfit, mask tóc và art review còn lại nằm trong WBS.

Ảnh gốc `wardrobe-modular-02.png`, `locomotion-keyframes-02.png`, `combat-keyframes-02.png` giữ để so sánh vòng review; dùng bản `-refined` ở bảng duyệt. Vòng chỉnh nhắm vào tóc xuyên nón, walk thiếu passing pose và tay phụ của thương. Những khác biệt pose/source còn lại được ghi ở ACCEPTANCE, phải sửa bằng authoring/rig thật trước nghiệm thu.

## Nguồn tạo ảnh và tính toàn vẹn

Tạo bằng **built-in `image_gen.imagegen`**, không dùng CLI/API runner. Reference identity: [character-concept-01](../character-concept-01.png), thêm bảng directions mới để giữ cả nam/nữ. Hình gốc do công cụ lưu trong `.codex/generated_images`; bản dùng trong dự án đã copy vào thư mục này, không ghi đè asset game.

Prompt đầy đủ: [5 prompt ban đầu](prompts.json), [3 prompt có reference bổ sung](prompts-continuation.json), [chỉnh wardrobe/walk](prompts-refinement.json), [chỉnh grip thương](prompt-combat-refinement.json).

Kết quả kiểm baseline ban đầu ở [baseline.json](baseline.json). Pilot runtime dùng cùng renderer 2D và có test/screenshot riêng; ảnh concept không được nhập làm sprite. Build phát hành vẫn cần cổng PORT-20 ở [ACCEPTANCE.md](ACCEPTANCE.md).
