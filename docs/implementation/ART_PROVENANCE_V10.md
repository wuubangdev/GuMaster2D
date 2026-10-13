# Nguồn artwork 0.10

Ảnh môi trường được tạo bằng công cụ imagegen tích hợp của Codex, không dùng CLI. Các bản gốc được giữ nguyên trong thư mục generated_images; project lưu bản sao tại hai đường dẫn dưới đây. Không trích asset thương mại từ Võ Lâm Truyền Kỳ.

- `assets/environment/wuxia_terrain_v10.png`: atlas opaque 2×2, cỏ / đá lát / đất / đá rêu.
- `assets/environment/wuxia_props_v10.png`: atlas transparent 2×2, cây tán rộng / thông / cụm đá / di tích đá. Bản cuối có khoảng trống rõ giữa các phần, được kiểm alpha tại biên.
- `assets/characters/textures/*.svg`: 11 map vector nguyên bản, tái tạo bằng `tools/generate_character_materials.py`; face tint, satin brocade, weave, leather, hair và metal. Đây là tài nguyên viết bằng code, không phải raster sửa bằng Python.
- `scripts/presentation/wolf_painter.gd`: artwork vector nguyên bản, đường cong và chân khớp độc lập theo stride runtime.

Brief ban đầu cho props: một atlas 2×2 transparent, TL cây tán rộng/TR thông/BL đá rêu/BR di tích; góc isometric 45°, ánh sáng trên trái, forest jade trầm, chi tiết vẽ tay, không chữ/UI/background, không sao chép asset game thương mại. Hai lượt edit dưới đây giữ hướng đó và sửa layout. Renderer lấy đúng từng quadrant, cắt khoảng trống theo alpha và giữ ground pivot.

## Prompt terrain

Create ONE square 2x2 seamless terrain albedo texture atlas for a premium hand-painted isometric Chinese martial arts PC RPG. OPAQUE atlas, four exactly equal edge-to-edge square quadrants, no gutters, labels, borders, text, objects, people, baked directional shadows or perspective. Strict placement: TOP LEFT rich desaturated jade forest grass and tiny clover, subtle earth visible beneath, not individual giant blades; TOP RIGHT ancient worn gray-green limestone paving with irregular believable small stone slabs, hairline cracks, subtle moss in joints, no geometric grid border; BOTTOM LEFT warm muted brown compacted earth footpath, small embedded pebbles and scuffs, earthy sand grain; BOTTOM RIGHT weathered gray-green mountain stone/moss substrate, fine crevices and mineral grains. All four flat orthographic straight-overhead materials under neutral diffuse light, compatible color and detail scale. Painterly semi-realistic texture, nuanced broad surface variation and fine natural detail, restrained contrast suitable underneath readable characters and UI, natural rather than pixel art or low-poly blocks. Each quadrant must be a seamless repeating texture within itself, no vignette, no central focal feature, no heavy black grout or coarse asphalt look. High quality ideally 2048x2048 total. Original art, no extracted commercial game texture.

## Prompt sửa props lần đầu

Edit this original transparent 2x2 environment prop atlas for a Godot game. Keep the same detailed hand-painted jade forest style, top-left broadleaf tree, top-right ancient pine, bottom-left mossy boulders, bottom-right carved stone shrine. CRITICAL LAYOUT: all four objects must fit entirely inside their own equal square quadrant, with at least 12 percent of EACH quadrant width of completely transparent empty space on all four sides; shrink and recenter each object as needed. No leaf, branch, root, rock, base or shadow may touch or cross a quadrant edge or central dividing line. Make all four cutout silhouettes clean with true zero-alpha transparent surrounding pixels. Remove colored red/yellow/green fringe residue. Retain fine natural foliage, bark, carved stone and moss detail, warm upper-left lighting and grounded isometric view, no background, no captions, no added object. Objects remain separate and centered, with ground bases about 85% down their own quadrant. Original assets, no commercial game copying.

## Prompt layout cuối

Correct only the layout of this transparent original game atlas. Render a 1280 by1280 transparent canvas with FOUR much SMALLER cutout props. The entire broadleaf tree MUST fit inside pixel rectangle x100..520,y90..520. The entire pine MUST fit inside x760..1180,y90..520. The entire boulder cluster MUST fit inside x100..520,y760..1180. The entire shrine MUST fit inside x760..1180,y760..1180. Thus a wide EMPTY TRANSPARENT CROSS spanning x540..740 and y540..740 separates them; also a 90px empty outer margin. Scale down ALL objects so they fit these rectangular bounds; keep each whole object intact. Every leaf, root and rock must be fully contained inside these bounds. Keep existing original detailed hand-painted jade-green forest art, warm lighting and carved shrine. True alpha outside silhouettes. No opaque black background, no labels. This is a sprite atlas whose props will be selected using four exact square quadrants, so an object touching a quadrant border makes it unusable.

## Cách kiểm chứng

`environment_art_tests.gd` kiểm PNG được đọc thật, alpha, khoảng trống atlas, mipmap dùng chung, UV và navigation không đổi. Hình ảnh nghiệm thu nằm trong `docs/game-studio/evidence/windows_first_playable.png`; đây là screenshot Godot native, không phải concept/mockup. Chi tiết gốc và mipmap đã nạp qua `GroundView`/`PropView`.
