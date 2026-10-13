# Nghiệm thu nâng chất lượng nhân vật — đợt 0.9

Ngày kiểm: 08/10/2026. Người dùng đã yêu cầu tiếp tục chặng sculpt/texture và animation riêng theo vũ khí sau khi nhận nền model 0.8. Mục tiêu là **polished prototype** chạy trong Godot; chưa gọi là asset nhân vật production.

## Nhận xét bản trước để định hướng sửa

Ảnh native `character_studio_male.png`, `character_studio_female_spear.png`, `character_studio_rear.png`, `character_studio_side.png` của bản 0.8 cho thấy rig hoạt động và UI dễ đọc, nhưng vai/tay áo còn như các khối tròn ghép, tà áo/cape gần phẳng, mặt thiếu cấu trúc mí/má/cằm. Ba trang phục chỉ đổi palette; thương có tay trái rời cán; kiếm/thương/tay không chưa có đường chuyển động riêng. Các điểm này là thiếu chất lượng hình ảnh thật, không thể nghiệm thu bằng số assertion của gameplay.

## Gate độc lập

| Gate | Yêu cầu | Bằng chứng và giới hạn |
|---|---|---|
| G1 — kiểu cắt áo | Thanh Ngọc, Xích Vân, Bạch Vũ khác hình học và silhouette, không chỉ màu | Fingerprint vertices độc lập với material; thêm ảnh trước/sau/chéo cùng pose để review |
| G2 — bề mặt | Vải, lớp lót, da, tóc có albedo texture; UV hợp lệ, repeat, tangent và normal map thật | Test resource/array; native close-up kiểm tần suất texture, seam và phản xạ. Test này không xác nhận chất lượng sculpt artist |
| G3 — motion theo vũ khí | Attack/defend/run khác đường tay và torso cho kiếm, thương, tay không | Sample FK actual Skeleton3D; ba thư viện đủ 11 action + RESET; không có method-track gameplay |
| G4 — grip thương | Tay trái tiếp xúc vị trí support của shaft trong idle/walk/run/attack/defend | FK tại 41 điểm mỗi clip; tolerance 8 mm để bao gồm nội suy giữa key. Contact đúng tâm cổ tay cần được kiểm thêm bằng hình bàn tay/fingers |
| G5 — đủ góc và không crop | Toàn bộ model/vũ khí giữ trong texture ở 8 hướng và 11 action | CPU skin toàn bộ vertices; 6 mốc thời gian × 8 hướng × 11 action × 3 trường hợp đại diện = 1.584 view. Bộ test geometry hiện có vẫn kiểm đủ 36 tổ hợp cosmetic |
| G6 — tích hợp | Save cũ, pause, portrait, F6, input, VFX và authority không bị đổi bởi clip | Bộ regression hiện có và native smoke; animation presentation không gây damage hoặc root motion gameplay |
| G7 — source tiếp tục sửa được | Blender/source geometry và clip xuất lại GLB/scene có provenance rõ | Import lại trong Godot; ghi source, model revision, tool và giới hạn topology/weights trong manifest |
| G8 — chất lượng nhìn thực tế | Mặt, vai, tay áo, robe và grip ít thô hơn 0.8, silhouette đọc được ở gameplay | Review native sau khi đổi model; chưa có ảnh mới thì ghi **chưa kiểm**, không lấy logic test thay review |

## Trạng thái kiểm chứng

Probe độc lập trên implementation mới đạt **15/15** kiểm tra, không có parse/runtime error hay leak khi thoát. Kiểm actual FK ghi sai số grip thương lớn nhất **2,0 mm** trên 205 mẫu nội suy. Envelope geometry đầy đủ qua 1.584 view, camera orthographic `size=3.6`, có khoảng trống như sau:

| Vũ khí / trường hợp đại diện | X trong texture | Y trong texture | Kết quả |
|---|---|---|---|
| Kiếm · nam Thanh Ngọc | 8,53% → 91,47% | 8,28% → 86,49% | Không crop |
| Thương · nữ Bạch Vũ | 5,81% → 94,19% | 14,21% → 86,49% | Không crop |
| Tay không · nam Xích Vân | 22,70% → 77,30% | 23,55% → 86,49% | Không crop |

Đã sửa một lỗi được probe bắt: camera `size=2.95` cắt mép kiếm ở attack khoảng 18% clip; camera 3.6 giữ đủ mesh ở phạm vi mẫu trên. Thay đổi camera phải giữ ground pivot và chiều cao nhân vật khi ghép vào world bằng adapter.

**G1–G7: đạt phạm vi prototype đã kiểm; G8: có cải thiện hình ảnh native, chưa đạt premium/final art.** Suite tích hợp đạt 430/430 trên Windows và Linux, log sạch. Sáu GLB/tscn giữ rig/clip, embedded albedo/normal và tangent qua import; sáu nguồn Blender giữ geometry/weights/UV/normals, packed texture và reopen. Blender xuất lại sáu GLB, Godot đọc giữ 22 bone và 12 clip, helper camera/light đã loại. Albedo/normal resources, UV và tangent hữu hạn/orthogonal đã được kiểm; tangent runtime được tích lũy từ đạo hàm UV theo triangle rồi Gram–Schmidt với normal và handedness; đây chưa phải MikkTSpace bake hoặc sculpt high-poly. FK grip kiểm tâm cổ tay, chưa thay review fingers nắm cán. Ảnh 0.8 chỉ là baseline. Bản mới đã capture native toàn bộ visual/motion/character/studio và 4 ảnh + 96 frame wardrobe/weapon; evidence nằm trong docs/game-studio/evidence sau khi đóng gói.

Các giới hạn phải ghi rõ ở lần bàn giao: chưa có benchmark nhiều hero/Web; texture vector theo quy trình hiện tại không tự tạo bake từ sculpt high-poly; topology procedural và weight chung vẫn cần artist review trước production; wardrobe/vũ khí vẫn cosmetic nếu combat authority chưa có melee rules riêng.

Test dành riêng cho đợt này: `tests/character_polish_tests.gd`. Chạy cùng runner bằng chế độ `--test-mode`, rồi kiểm native một lượt duy nhất để tránh các cửa sổ game tranh focus.

Kiểm projection/tangent/repeat đối chiếu API chính thức của [Camera3D](https://docs.godotengine.org/en/stable/classes/class_camera3d.html), [Mesh arrays](https://docs.godotengine.org/en/stable/classes/class_mesh.html) và [BaseMaterial3D](https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html). Envelope test tính projection orthographic với viewport vuông, không thay cho việc xem clip native.

## Nhận xét ảnh native cuối

Vai/tay áo đã được hạ và tạo đường cong nối vào thân; sleeve và da dùng blend Chest ở đoạn trên, giảm cảm giác hai khối đặt rời. Ba kiểu áo nhận biết qua chiều dài vạt và giáp nhẹ; thương có tay phụ trên cán, kiếm và quyền có pose attack/defend khác. Mặt/cằm/mí mắt có cấu trúc hơn bản 0.8 nhưng vẫn stylized và đơn giản. Ánh sáng và màu ổn định, vân vải/normal khá nhẹ ở zoom game; cape đã có mép cong, hoa văn mây và trim dùng cùng skin weights; nếp vải lớn/texture paint vẫn cần artist review. Tóc sau đầu có shell theo occiput/temples và sợi sáng, bỏ phần da lộ như đầu cạo ở bản trước.

Đã xem ảnh F6 1280×800 và 960×640, front/rear/side và bản gameplay. Ảnh dùng chung runtime model; contact sheet/clip sampling là evidence hình ảnh, không phải playtest người mới hoặc số đo FPS. Chi tiết fingers/anatomy, nếp áo/cape, curve chuyển động và skin cực trị tiếp tục là các đầu việc mỹ thuật trong WBS.
