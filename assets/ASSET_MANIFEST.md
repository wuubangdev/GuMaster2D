# Asset manifest — modular 3D character / animation 0.9

| Asset | Nguồn | Ghi chú |
|---|---|---|
| Cây/đá/tường/di tích/đèn/nền | `scripts/presentation/prop_view.gd`, `ground_view.gd` | Vector được dựng bằng code trong dự án |
| Cổ sư 3D | `character_model.gd`, `character_animations.gd`, `character_viewport.gd`, `actor_view.gd` | Original generated skinned ArrayMesh; 22 bone, 11 action + RESET trong mỗi weapon family; 13–15 material surfaces; 19.024–19.624 triangles theo body/outfit/weapon; chưa phải sculpt final |
| Model baked/editable | Sáu `assets/characters/gu_<body>_<weapon>.glb`/`.tscn`, `model_manifest.json` | Export bằng `tools/export_character_models.gd`; GLB round-trip bảo toàn22 bone và12 clip; nguồn geometry/animation gốc nằm trong code, không lấy mesh bên ngoài |
| Nguồn Blender | `assets/characters/source/*.blend`, `source_manifest.json`, `tools/author_character_assets.py` | Sáu nguồn editable giữ rig/clip/UV/weights/normals, packed texture và collection body/outfit/hair/weapon; `.gdignore` ngăn tự import source vào Godot |
| Texture nhân vật | `assets/characters/textures/*.svg`, `tools/generate_character_materials.py` | 10 SVG 512 px nguyên bản: ba silk albedo, silk normal, leather/hair/metal albedo và normal; không dùng texture của game khác |
| Appearance/xưởng | `character_appearance.gd`, `character_studio.gd` |36 tổ hợp cosmetic; ba outfit khác geometry; ba weapon family có idle/walk/run/attack/defend riêng; `weapon_rig.gd` khóa grip thương hai tay |
| Legacy rig/vector | `humanoid_rig.gd`, `humanoid_art.gd` | Giữ helper pose và regression cũ; player world/HUD/F3 đã render model 3D |
| Sói | `scripts/presentation/actor_view.gd` | Vector bằng code; gait, windup và strike; chưa phải sprite final alpha |
| Glyph/icon/VFX | `glyphs.gd`, `world_effects.gd`, `assets/icon.svg` | Tự tạo, cùng bảng màu jade/đá/vàng nhạt |
| Khung đồng UI nine-slice | `assets/ui/frame_*.svg`, `tools/generate_ui_assets.py` | SVG tự tạo, 5 trạng thái; góc cố định 16px, không dùng ảnh UI của game tham khảo |
| Thanh đáy / paper doll | `scripts/ui/hud_chrome.gd`, `character_doll.gd` | UI bằng code; paper doll render model 3D cùng world, viewport tĩnh |
| Biểu tượng vật liệu / thanh tài nguyên | `assets/ui/item_*.svg`, `gauge_*.svg`, `tools/generate_ui_assets.py` | SVG tự tạo; grid và thanh HP/mana dùng dữ liệu thật |
| 9 WAV effects | `tools/generate_audio.py` | PCM baked từ script Python stdlib, seed cố định; không dùng bản thu bên ngoài |
| Font fallback | Godot built-in font | Đi cùng engine; khi đổi font cần thêm nguồn/license cụ thể |
| Blender portable | Blender official 4.5.14 LTS | Công cụ authoring dưới `.tools`, SHA256 pin/verify; không thuộc model hoặc source zip |
| Engine portable | Godot official 4.7.2 release | Công cụ local dưới `.tools`, không thuộc asset game hoặc Git; xem license/credits của Godot khi đóng gói phát hành |

Chưa dùng ảnh, nhạc, sprite hay logo từ tác phẩm Cổ Chân Nhân/Võ Lâm. Tên là tham chiếu ý tưởng trong tài liệu, nội dung nghệ thuật prototype do dự án tạo. Chưa lựa chọn license phân phối cho toàn bộ mã nguồn của chủ dự án.
