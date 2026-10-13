> Cập nhật 0.11: tài liệu này mô tả pipeline 0.10 trước khi chuyển sang pixel 2D. Runtime hiện tại theo [PIXEL_2D_MIGRATION_PLAN.md](PIXEL_2D_MIGRATION_PLAN.md).

# Pipeline model và texture nhân vật

Ngày cập nhật: 08/10/2026. Phạm vi: nguồn nhân vật có thể chỉnh sửa bằng Blender, xuất từ đúng bộ model và animation Godot đang kiểm chứng.

## Các nguồn có thể mở và sửa

Sau khi chạy pipeline, `assets/characters/source/` có sáu file:

| Cơ thể | Kiếm | Thương | Tay không |
|---|---|---|---|
| Nam | `gu_male_sword.blend` | `gu_male_spear.blend` | `gu_male_unarmed.blend` |
| Nữ | `gu_female_sword.blend` | `gu_female_spear.blend` | `gu_female_unarmed.blend` |

Đây là mesh nguyên bản của dự án, được dựng bằng code Godot rồi đưa vào Blender để chỉnh hình, UV, material, skin weight và animation. Texture albedo/normal đã có trong GLB được đóng gói vào file `.blend`, không cần liên kết máy của người tạo. Các phần dùng material màu đơn có thể được thêm UV phục vụ texture paint; UV đã có được giữ nguyên.

Thư mục nguồn có `.gdignore` để Godot không tự mở Blender khi import dự án; các GLB/scene xuất cho game vẫn ở thư mục `assets/characters/` bên ngoài thư mục nguồn.

**Trạng thái mỹ thuật:** nguồn model stylized có thể chỉnh sửa. Pipeline không biến mesh hiện tại thành bản sculpt hoàn thiện bằng thao tác tự động. Sculpt nét mặt, topology phục vụ chuyển động phức tạp, texture vẽ tay và kiểm soát va chạm áo/tóc theo từng động tác vẫn là công việc mỹ thuật cần thực hiện và review hình ảnh.

## Tổ chức file Blender

- `00_RIG`: một armature, 22 bone giữ nguyên tên và quan hệ cha/con.
- `01_BODY`: da, khuôn mặt và bàn tay.
- `02_OUTFIT`: áo, lớp lót, viền, giày, đai và phụ kiện.
- `03_HAIR`: tóc và các sợi/túm tóc.
- `04_WEAPON`: lưỡi, cán, tay cầm và bộ phận bảo vệ tay; tay không không có mesh vũ khí.
- `90_STUDIO`: camera orthographic và đèn preview; không đưa vào file xuất cho game.
- Text block `START_HERE — Character editing contract`: nguồn GLB, hash, clip và quy tắc chỉnh sửa.

Godot gộp mesh theo material để giảm số draw call. Pipeline tách phần kim loại/da của vũ khí khỏi trang phục dựa trên weight bone `Hand_R`. Việc tách giữ nguyên polygon, deform weight, UV và armature modifier. Không remesh, apply skinning hoặc chia nhỏ toàn bộ model.

## Cách tạo lại nguồn

Blender portable đặt trong `.tools/`, không nằm trong gói source và không cài vào hệ điều hành. Script tải bản Linux x64 **4.5.14 LTS** từ máy chủ Blender chính thức; checksum SHA256 được đối chiếu với file release và giá trị đã pin. Trên WSL thiếu `libSM`/`libICE`, hai gói thư viện Ubuntu chỉ được tải và giải nén vào `.tools/blender/shared`, không cài bằng apt.

```bash
bash tools/fetch_blender.sh

# Chỉ chạy sau khi sáu GLB mới đã được xuất và kiểm chứng.
.tools/blender/blender --background --factory-startup --python-exit-code 1 \
  --python tools/author_character_assets.py --

# Mở lại các nguồn và kiểm tra chúng khớp với hash GLB hiện tại.
.tools/blender/blender --background --factory-startup --python-exit-code 1 \
  --python tools/author_character_assets.py -- --validate-only \
  --roundtrip-dir artifacts/character_authoring_roundtrip
```

Có thể dùng Blender 4.5 LTS cài sẵn trên Windows để mở các `.blend`. Đường dẫn engine portable trong ví dụ là dành cho WSL; file model không phụ thuộc hệ điều hành.

`tools/author_character_assets.py` nhận thêm `--inputs` và `--output-dir` để tạo bản thử ở thư mục khác. Khi chạy chế độ tạo, script sẽ ghi lại các `.blend` đích từ GLB: **lưu bản chỉnh tay bằng tên khác trước khi tạo lại**.

## Vòng chỉnh sửa cho artist

1. Mở nguồn đúng cơ thể/vũ khí và lưu một bản có tên riêng, ví dụ `artist/gu_female_spear_v02.blend`.
2. Chọn mesh trong collection tương ứng. Có thể chỉnh vertex ở Edit Mode và dùng Sculpt Mode cho chỉnh khối vừa phải; giữ topology nếu chưa có kế hoạch retopology/rebind.
3. Chỉnh texture đã đóng gói hoặc tạo texture mới trong UV Editing/Texture Paint. Giữ không gian màu: albedo dùng sRGB, normal dùng Non-Color.
4. Kiểm tra pose và các animation action/NLA đã nhập. Giữ 22 tên bone, hierarchy, armature modifier và deform groups; không áp dụng armature modifier lên mesh.
5. Chọn rig và các mesh nhân vật, xuất bản thử GLB với `Selected Objects`, skinning, material và animation bật; chọn Animation Mode `Actions` để giữ toàn bộ clip. Loại camera/đèn collection `90_STUDIO`. Đường xuất này đã được kiểm tra giữ đủ 22 bone và 12 clip từ file `.blend`.
6. Import bản thử vào scene kiểm chứng riêng trong Godot, xem từ trước/sau/trái/phải và góc chéo, kiểm tra nhịp đi/chạy, tay giữ vũ khí, mép áo, tóc, điểm đặt chân và silhouette ở kích thước chơi thật.

Godot dùng trục +Y lên; Blender dùng +Z lên và glTF tự đổi trục khi nhập/xuất. Không xoay toàn bộ model thủ công để bù trục. Pivot ở mặt đất giữa hai bàn chân. Chiều cao cơ thể xấp xỉ 2 đơn vị; kiểm tra phụ kiện/vũ khí nằm trong framing của renderer và không bị cắt.

Runtime 0.10 nạp `GuCharacterMeshAsset` theo body/outfit/hair/weapon tại `assets/characters/runtime/`, gắn các mesh thật vào shared Skin/22 bone rồi phát clip hiện có. Generator chỉ phục vụ authoring/fallback; sửa `.blend` cần xuất GLB và bake đúng appearance để đưa thay đổi vào game.

```bash
# Authoring: tạo lại cả 36 appearance từ generator (ghi đè các bản artist).
.tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path . \
  --script res://tools/bake_character_runtime.gd

# Artist: thay duy nhất một appearance bằng geometry/material từ GLB.
.tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path . \
  --script res://tools/bake_character_runtime.gd -- \
  --from-glb res://artist/gu_male_jade_v02.glb \
  --body male --outfit jade --hair topknot --weapon sword
```

Baker đối chiếu 22 bone name và rest origin/unit, remap skin bind về live rig, đưa mesh về model space, giữ UV/material và tạo UV-derived tangents. Bốn influence được chuẩn hóa/phân bổ UNORM16. Surface thiếu normal/UV/skin hoặc mirrored transform bị từ chối. Giữ rest pose và đơn vị của nguồn; không thay bone vị trí. Thay đổi mesh không đổi `LocalAuthority` hay sát thương.

Restart game sau bake để bỏ cache cũ. Manifest ghi path/SHA/triangles/layers và provenance. `assets/characters/artist_roundtrip_male_sword.glb` là mẫu Blender re-export đã thực sự được bake vào `male_jade_topknot_sword.res`, kiểm qua actor live. Đây là chứng minh vòng authoring → runtime, không phải tuyên bố mẫu đã được sculpt thủ công. File `.res` chứa mesh/material cần dùng, không phụ thuộc thư mục artifacts. Giữ bản artist có tên riêng trước khi chạy lệnh tạo toàn bộ 36 resource.

## Cổng kiểm chứng

Pipeline dừng nếu mất armature, thay tên bone, mất action, vertex không hữu hạn, weight không chuẩn hóa hoặc số triangle thay đổi khi tách mesh. Fingerprint của vị trí, weight và UV giữ nguyên; hướng corner normal được kiểm tra sau khi tách. Mỗi file được lưu, mở lại và kiểm tra stats; image phải được packed. `assets/characters/source/source_manifest.json` ghi hash GLB và `.blend`, số mesh/triangle/bone/action, UV, texture và kết quả mở lại. `--validate-only` kiểm tra cả hash `.blend` để phát hiện nguồn đã sửa từ lần tạo; bản chỉnh của artist lưu bằng tên riêng.

Những kiểm tra này chứng minh khả năng mở/chỉnh sửa và tính nhất quán dữ liệu. Chúng không thay cho review mỹ thuật bằng hình ảnh, kiểm tra clipping trong game hoặc đo hiệu năng trên PC mục tiêu.

## Nguồn và quyền sử dụng

Geometry, trang phục, vũ khí và texture của nhân vật do dự án tạo nguyên bản; không trích model từ Võ Lâm Truyền Kỳ hay nhân vật của game khác. Blender chỉ là công cụ authoring, không phải nguồn model của bên thứ ba.

Nguồn kỹ thuật chính thức: [Blender 4.5 LTS](https://www.blender.org/releases/4-5/), [release archive và checksum](https://download.blender.org/release/Blender4.5/), [glTF 2.0 trong Blender](https://docs.blender.org/manual/en/4.5/addons/import_export/scene_gltf2.html).
