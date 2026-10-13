# Pixel 2D từ trên xuống — 0.11

Ngày 10/10/2026. PC trước, Godot4.7.2 Compatibility; nhóm4người tự phát triển. Hướng nhìn đã được người dùng chọn: từ trên xuống, tham khảo Avatar/KPAH cổ điển.

## Hướng hình ảnh

Tham khảo screenshot do TeaMobi đăng trên [Khí Phách Anh Hùng](https://play.google.com/store/apps/details?id=com.teamobi.kpah) và [Avatar DK](https://play.google.com/store/apps/details?id=com.TeaM.AvatarDK). Diễn giải cho dự án: màu cỏ sáng/đất ấm, viền tối mảnh, các cụm pixel rõ, đầu nhân vật lớn và mặt nhà/cây nhìn từ phía trước trên nền ô vuông. Bối cảnh riêng của Cổ Sư giữ đường làng, trại an toàn, rừng sói và tế đàn. Art trong `assets/pixel/` được tạo bằng mã nguồn riêng; không lấy sprite hoặc map từ game tham khảo.

- Tile32×32; nhân vật cao48px trong cell80×80 có padding, pivot(40,68).
- Props96×96, pivot(48,88); sói64×64, pivot(32,52).
- PNG alpha0/255, texture nearest, không mipmaps; phóng theo nấc nguyên.
- Camera1×/2×/3×, tọa độ hiển thị làm tròn; HUD bố trí theo kích thước cửa sổ thật.
- Tám hướng có frame riêng. Animation lấy trạng thái/action từ gameplay; không gây damage hoặc dịch chuyển collision.

## FSD bổ sung

| ID | Chức năng / hành vi | Điều kiện nghiệm thu |
|---|---|---|
| PX-01 | Map vuông32px bằng TileMapLayer; đường làng, nhà, giếng, cây, ruộng, hoa, tế đàn, vũng nước nông | Projection/unprojection chính xác; điểm spawn/tế đàn vẫn đi được; đường đi và collision giữ authority |
| PX-02 | Hero sprite2D8hướng, đứng/đi/chạy/đánh/đỡ/thi triển/phong ấn/lướt/trúng đòn/gục/hồi sinh | Frame thay đổi theo thời gian và hướng thật; death giữ frame cuối; không có renderer3D trong live scene |
| PX-03 | Nam/nữ ×3áo ×2tóc ×3vũ khí =36tổ hợp | Mọi tổ hợp nạp được và có pixel riêng; chọn kiếm/thương/tay không có thế đánh riêng |
| PX-04 | F6 xem sprite lớn, hướng45°, động tác, tốc độ, pause/replay, Apply | Preview không đổi profile trước Apply; Apply lưu cosmetic; HUD/F3/world đồng bộ |
| PX-05 | Sói pixel8hướng, đi/lấy đà/vồ/trúng đòn/gục | Hướng khớp movement; cảnh báo, HP, slow/capture đọc được và lấy dữ liệu thật |
| PX-06 | Anchor tay và ảnh frame cho Cổ/lướt | VFX xuất phát từ tay; ghost dùng frame đang hiển thị; không giữ ViewportTexture3D |
| PX-07 | WASD, Shift chạy,1–4kỹ năng, click A*, lưu cũ | Regression gameplay/input/save không lỗi; numeric skills được chấp nhận trong native capture |
| PX-08 | Minimap, zoom nguyên và giảm chuyển động | Minimap theo map vuông; zoom không tạo scale lẻ; giảm chuyển động giữ pose và đóng băng nước/đèn |

Trang phục/vũ khí hiện là cosmetic. NPC/shop, cận chiến/combo, multiplayer và Web export thuộc backlog riêng.

## WBS cho nhóm4người

| Công việc | Chủ trì | Kết quả | Phụ thuộc |
|---|---|---|---|
| W-PX1: Chốt art bible, ô/pivot/palette | A — gameplay/tech lead | Hợp đồng trong tài liệu này | Hướng nhìn đã chọn |
| W-PX2: Hero, wardrobe và animation | B — character art/animation | Generator,36atlas, manifest, preview | W-PX1 |
| W-PX3: Tile và props làng/rừng | C — environment art | Generator, tile/prop atlas, TileMapLayer | W-PX1 |
| W-PX4: Runtime/camera/input/VFX | A | Sprite adapter, world vuông, hiệu ứng từ frame/anchor | W-PX2/3 |
| W-PX5: HUD/F3/F6/minimap | D — UI/QA | Cùng sprite,45°preview, layout960–1920 | W-PX4 |
| W-PX6: Test, review và handoff | D, cả nhóm review art | Windows/Linux regression, native screenshot/motion, sourceZIP | W-PX2–5 |

Đợt hiện tại thực hiện W-PX1–6 cho prototype đang có. Báo cáo test/hình ảnh và các hạn chế thực tế nằm ở [quality-report](../game-studio/quality-report.md); số assertion không thay thế nghiệm thu mỹ thuật.

Chặng art tiếp theo cho4người: A bổ sung trigger/interaction cho nhà và map transition; B làm thêm tóc/trang phục và sửa silhouette qua review từng hướng; C dựng một map mới có sông/cầu/collision thiết kế cùng nhau; D kiểm đọc HUD/combat và thời gian frame trên máy mục tiêu. Chỉ ước lượng lịch sau khi chốt số map, NPC, outfit và animation mới; không coi ngân sách0 đồng là không cần giờ công.

## Chỉnh và tái tạo

Nguồn pixel: `tools/generate_pixel_characters.py`, `tools/generate_pixel_environment.py`, `tools/generate_pixel_wolves.py` (Python+Pillow). Runtime không cần Python. Sau khi regenerate, import assets bằng Godot, chạy `RunTests.bat`, rồi native `pixel_visual_smoke.gd` và `pixel_motion_smoke.gd` tuần tự. `tools/render_pixel_preview.py` dựng GIF từ framebuffer thật.

Bộ Game Superpowers44skill: thêm33skill còn thiếu, giữ11skill sẵn có và bổ sung76file shared/schema để các đường dẫn tương đối hoạt động. Nguồn [mike007jd/game-superpowers](https://github.com/mike007jd/game-superpowers), commit `3925ffb92d405b34fd1be23fde79fec3f4dc6af0`; biên nhận tại `GAME_SKILLS_INSTALLATION.json`. Skill mới được Codex nạp ở lượt trò chuyện tiếp theo.

Baseline0.10 và sourceZIP trước chuyển đổi giữ tại `artifacts/baseline_v10/`. Các nguồn3D cũ vẫn tồn tại để tham khảo; yêu cầu gameplay/art hiện tại áp dụng theo bảng PX ở trên.

## Lượt hoàn thiện hình ảnh 0.12

Nhóm4người tiếp tục theo phân công A(runtime/VFX), B(char), C(art review), D(UI/QA). Phạm vi lượt này: giữ map/collision/điều khiển, sửa silhouette/material/pose, thu HUD và làm feedback bốn kỹ năng. Art được review bằng framebuffer native, không dùng số assertion làm thang điểm đẹp.

| ID | Thay đổi | Nghiệm thu |
|---|---|---|
| PX-09 | HUD khung mảnh, portrait bust, dock352×104, icon pixel, HP damage edge | Không che skill/menu; góc dưới click map được; bag/filter/Cho ăn vừa960/1280/1920 |
| PX-10 | Mắt/tóc/áo/giày và anticipation/contact/recovery;8hướng |18.432frame giữ margin/alpha;36.864anchor bám pixel; bước đi/chạy và mặt trước đọc được |
| PX-11 |13clip/328frame skill, source tay, projectile/impact, khiên/lướt/băng |1–4 được gameplay chấp nhận; native ghi travel/contact; VFX/flash/fall không gây thêm damage hoặc thay save |
| PX-12 | Giảm chuyển động và regression | Giữ silhouette spell tĩnh; bỏ flight/ghost/shake; Windows/Linux gameplay/input/UI/save đạt, cold source nạp được |

W-PX7(A+B): authord sprite và spell atlas, tích hợp contact/timing. W-PX8(D): HUD/damageedge/inventory. W-PX9(C+D): review native từng skill, lethal contact, F6/8hướng/túi960, sửa trước handoff. Source trước lượt này giữ ở artifacts/baseline_v11. Nguồn FX: tools/generate_pixel_effects.py; runtime: GuPixelEffectsArt/WorldEffects. Các giới hạn nội dung/production của0.11 vẫn áp dụng; lượt polish không bổ sung NPC, map mới, cận chiến hoặc multiplayer.

## Chibi minh họa và chuyển động liên tục — 0.13

Yêu cầu mới: tham khảo tạo hình/nhịp chuyển động Gunny, giảm đường nét thô và cảm giác raster. Hướng thực hiện: mặt/đầu/tóc cong, khớp tay/chân lấy mẫu liên tục, chuẩn bị–ra đòn–vượt đà–thu đòn; icon và VFX vector. Bản đồ vẫn giữ góc nhìn từ trên xuống đã chọn. Nguồn tham khảo: [Gunny/VNG — tạo nhân vật](https://gunnypc.vnggames.com/gioi-thieu/huong-dan-29/tao-nhan-vat.html), [video giới thiệu chính thức](https://www.youtube.com/watch?v=OGSpfvCl5oE). Không đo hay sao chép frame từ Gunny; nhịp động tác và SVG trong dự án được tự tác giả hóa.

| FSD | Triển khai | Điều kiện nghiệm thu |
|---|---|---|
| VX-01 |111 lớp SVG,36 diện mạo,8 hướng,11 trạng thái | Source Bezier gốc; import8texel/đơn vị; world/HUD/F3/F6 dùng cùng renderer minh họa |
| VX-02 | Rig pose liên tục, thở/chớp mắt/tóc phụ, ba kiểu đánh | Hình học thay đổi trong cùng bucket pixel cũ; tay bám khớp thật; không đổi root hay authority |
| VX-03 |13 kiểu VFX vector và icon/UI cong | Cast thật1–4, contact0.28s, dash dùng deep-copy pose; reduced motion ổn định |
| VX-04 | F6 vừa960/1280/1920 | Đầu/vũ khí đủ8hướng không bị cắt; zoom cố định khi phát animation |
| VX-05 | Bàn giao source sạch | Import không có.godot; runtime ZIP trùng byte với source đã kiểm; ảnh native/GIF từ frame thực |

W-VX1(A): SVG/rig và tích hợp ActorView. W-VX2(B): VFX/cast/contact/ghost. W-VX3(D): icon/UI và F3/F6. W-VX4(C): review native/test/biên vũ khí/source lạnh. Baseline0.12 giữ artifacts/baseline_v12. Generator dùng standard-library Python; runtime không cần Python. Phạm vi này không thêm gameplay, NPC/shop, multiplayer hoặc map mới.


## Chuyển động mềm và trọng lượng — 0.14

Mục tiêu lượt này: đi/chạy/đổi hướng/dừng và thi triển nối mượt, có tiếp đất và chuyển trọng tâm phù hợp chibi từ trên xuống. Phần hiển thị giữ độc lập với authority; không đổi save, hitbox, cooldown hay điều khiển.

| FSD | Triển khai | Điều kiện nghiệm thu |
|---|---|---|
| SM-01 | Pha stance tuyến tính, chân trở về bằng Hermite, lift có tiếp tuyến 0; stride theo quãng đường | Hai chân luân phiên; stance bù quãng đường của root, đường cong/velocity nối tại tiếp đất; start/stop giảm biên độ |
| SM-02 | Pha trộn pose từ tư thế hiện tại trong 45–120ms | Đứng/đi/chạy/đổi hướng/cast không nhảy khớp; interruption lấy pose đang vẽ; vị trí root và authority giữ nguyên |
| SM-03 | Chuyển trọng tâm, đầu cân bằng, chân và bóng tiếp đất; spring tóc/vũ khí | Khớp hữu hạn/đúng grip, giảm chấn ổn định khi dừng; angular wrap theo cung ngắn; 30/60Hz hội tụ gần nhau |
| SM-04 | Camera theo pixel màn hình, F6 playback/selection dùng chuyển tiếp | Map zoom nguyên giữ nét; camera bước 1 pixel hiển thị; pause đóng băng đúng pose; reduced motion bỏ blend/spring/gait |
| SM-05 | Chơi và ghi motion native | WASD/Shift/1–4 thật, F6 bấm nút thật, tay phóng/VFX và dash snapshot khớp pose đã blend; Windows/Linux và source sạch đạt |

W-SM1(A, hoàn tất triển khai): rig/gait, pose blend/spring, tích hợp ActorView. W-SM2(B, hoàn tất triển khai): chân/bóng/weight shift và thu đòn thương. W-SM3(D, hoàn tất triển khai): camera/F6, giữ pose khi pause và ẩn toast gameplay trên F6. W-SM4(C+D): test chuyển tiếp/gait/anchor, review framebuffer và GIF, đóng gói source sau kiểm chứng. Chi tiết kết quả ở quality-report.md. Baseline trước lượt này giữ artifacts/baseline_v13.


## Profile 0.15 — Sửa mặt nghiêng và chuyển động ngang

Yêu cầu: khi đi trái/phải, đầu/mắt phải đúng mặt nghiêng và bước chân/VFX gọn, ít lắc hoặc kéo lê. Bản sửa sử dụng cùng rig trong world/HUD/F3/F6.

| FSD | Hành vi / nghiệm thu |
|---|---|
| PF-01 | Đầu nghiêng có silhouette/mái/tai/mũi/miệng riêng; mắt nhỏ hơn, mắt gần/xa bất đối xứng khi nhìn chéo; 20 biến thể nhắm mắt giữ nguyên tóc/tai/da |
| PF-02 | Hông/bàn chân đặt theo hướng nhìn; góc ngang hẹp, có gối gập; sải32/44px, lift4.5/6.5px; chân tiếp đất bù đúng quãng đường nhân vật |
| PF-03 | Giảm nhấp nhô/lắc đầu, swing tay/tóc/vũ khí; thứ tự hai chân lấy ground projection; chân/hông vẫn đi khi tay thi triển |
| PF-04 | Dash2 bóng ngắn theo quãng đường đã đi,1 lông nhỏ/wake hẹp; bụi3 đốm nhỏ; dấu click vòng mảnh; reduced motion và pose deep-copy giữ đúng |

| WBS | Trạng thái | Bằng chứng |
|---|---|---|
| PF-W1 · Vẽ lại profile/eyelids | Đã implement | Generator SVG; 131 phần gốc / 36look / 8hướng |
| PF-W2 · Chân/gối/đầu/secondary motion | Đã implement | Continuous sampler và renderer dùng chung |
| PF-W3 · VFX lướt/di chuyển | Đã implement | WorldEffects / VectorEffectsArt; không đổi authority |
| PF-W4 · Nghiệm thu | Kiểm chứng trong quality-report và manifest cùng revision | 6 acceptance mới về hình học và ảnh SVG import; native180frame riêng cho4clip đi/chạy ngang, thêm gameplay/F6/cast1–4 |

Tái hiện review mặt nghiêng: tests/profile_motion_smoke.gd với native Godot và -- --test-mode; tools/render_profile_preview.py xuất WebP60Hz lossless và GIF30Hz từ ảnh game thật. Sampling rate phục vụ review, không phải FPS benchmark.


## Làm đẹp nhân vật hiện có — 0.16

Người dùng đã làm rõ: giữ nhân vật cũ, tối ưu đồ họa, không tạo lại mẫu nhân vật. Các quyết định ở../game-studio/art-direction-0.16.md.

| FSD | Hành vi / nghiệm thu |
|---|---|
| CR-01 | Giữ silhouette/tỷ lệ chibi0.15,8hướng/11state/36look và mốc rig;131 phần import có alpha/kích thước trùng baseline |
| CR-02 | Tinh chỉnh sắc độ da/tóc/mắt, chuyển sắc vải/giày/kim loại và nếp áo bên trong hình cũ; màu import thực thay đổi |
| CR-03 | World/HUD/F3/F6 cùng asset; kỹ năng giữ tay phóng, contact, pose capture; F6 vừa960/1280/1920 |
| CR-04 | Nền/props/sói giảm bão hòa và foreground fade theo mốc cũ; native review, Windows/Linux, cold source và sourceZIP trùng byte |

| WBS | Công việc / bằng chứng |
|---|---|
| CR-W1 | Khôi phục generator/rig0.15; lưu golden alpha/kích thước/RGBA trước chỉnh |
| CR-W2 | material_finish trên131SVG cũ, kiểm nguyên hình và màu thực |
| CR-W3 | Tích hợp màu môi trường/occlusion; không đổi authority/navigation |
| CR-W4 | Ba acceptance mới về nhận diện/màu/mốc rig, regressionWindows/Linux, native ảnh/clip và cold source |

Baseline trước sửa ởartifacts/baseline_v15; QA cuối tạiquality-report.md. Đây là prototype; test/sampling rate không chứng minh đẹp ngang gameSteam hoặc FPS phát hành.


## Tay và chi tiết chuyển hướng — 0.17

| FSD | Hành vi / nghiệm thu |
|---|---|
| AR-01 | Vai/cổ tay/khuỷu tay đổi theo tám hướng; profile trái/phải đảo hướng gập, back view xoay đúng anatomical side |
| AR-02 | Turn/interrupt blend hướng gập cùng endpoint, không mất khớp; lớp gần/xa và vũ khí theo vai |
| AR-03 | Tay đối trọng theo bước chân thực khi đi/chạy; cổ tay xoay, grip/tay phóng đúng renderer |
| AR-04 | Cẳng tay/chân cong thuôn, chuyển sắc/viền mảnh; tư thế gập không gây lỗi render |
| AR-05 | Giữ mẫu cũ/131 silhouette, 36 look/8 hướng/11 state, pause/reduced/authority/save; native review và ZIP từ source sạch |

| WBS | Công việc / bằng chứng |
|---|---|
| AR-W1 | Snapshot code/ảnh 0.16; xác nhận bend cố định và depth L/R cố định |
| AR-W2 | Projection vai/cổ tay; tham số gập lưu pose và blend; counter-swing theo gait |
| AR-W3 | Ribbons/cổ tay/nhóm weapon grip; chọn depth theo vai |
| AR-W4 | Chín acceptance bổ sung và Windows/Linux regression; native 240 frame/8 hướng/4 động tác ở 128 và 48 px, gameplay/F6/profile |
| AR-W5 | Cold source import/portability; kiểm source ZIP từng byte runtime; cập nhật docs/manifest/ảnh/clip |

Tái hiện: tests/directional_motion_smoke.gd, tools/render_directional_preview.py và RunTests.bat; QA cuối ở ../game-studio/quality-report.md.

Góc vũ khí nghỉ chiếu theo phía bàn tay cầm; tip kiếm nằm ngoài đầu ở cả tám hướng, tránh bị che hết khi quay lưng.


## Dáng bước và trang phục — 0.18

| FSD | Hành vi / nghiệm thu |
|---|---|
| GC-01 | Đùi/cẳng chân góc ngang giữ chiều dài 8 đơn vị; góc khác không vượt giới hạn. Kiểm 8 hướng × 11 trạng thái × 3 vũ khí |
| GC-02 | Bước 20/28 và lift 3/4.2 hợp chân chibi; stance vẫn hủy quãng đường thân, landing/takeoff liên tục; tay đối trọng đúng chân |
| GC-03 | Mesh áo 4×8 dùng texture gốc; cổ/đai cố định, vạt theo chân và sway trễ. Cell luôn convex, moving cast và reduced motion giữ hợp đồng |
| GC-04 | Thêu giảm sáng, nếp vải có mặt sáng/tối, bóng đai và chi tiết bàn tay; 131 alpha/kích thước vẫn khớp baseline |
| GC-05 | Native gameplay/F3/F6, đủ góc/giới tính/vũ khí, regression Windows/Linux và cold source; source ZIP được đối chiếu runtime |

| WBS | Công việc / bằng chứng |
|---|---|
| GC-W1 | Lưu baseline 0.17; nghiên cứu nguồn Steam chính thức, xác định chân kéo dài/áo cứng/đường thêu nổi |
| GC-W2 | Giải gối hai đoạn và chỉnh gait tương thích quãng đường thật |
| GC-W3 | Mesh vải dùng UV gốc và tham số pose có thể blend; tinh chỉnh chất liệu trong alpha cũ |
| GC-W4 | Sáu acceptance mới, regression và framebuffer native ở kích thước chơi/phóng lớn |
| GC-W5 | Cold import, clip từ frame native, review và handoff source/plan |

Mỹ thuật và giới hạn: ../game-studio/art-direction-0.18.md. Review cuối: ../game-studio/build-review-0.18.md.


## Nét mực, màu giấy và nhịp hoạt ảnh — 0.19

Hướng đã duyệt: tham khảo Don’t Starve Together, tiếp tục tối ưu nhân vật cũ. Nguồn/diễn giải/giới hạn ở ../game-studio/art-direction-0.19.md.

| FSD | Hành vi / nghiệm thu |
|---|---|
| IN-01 | 131 phần SVG giữ alpha/kích thước baseline; màu đất/ngà, bóng thành mảng, flick thuôn và viền mực ấm dùng chung world/HUD/F3/F6 |
| IN-02 | Grain neo texel, không TIME/RNG; framebuffer đứng yên giữ nguyên qua 12 frame ở sheet hai diện mạo × tám góc |
| IN-03 | Nhịp lấy đà kiếm giữ grip/góc pha .17–.21, ra đòn .21–.38; biểu cảm lấy đà/trúng đòn mở lại đúng lúc và tuân thủ reduced motion |
| IN-04 | 13 VFX nét bút dày–mỏng giữ endpoint và hình học hữu hạn; không random draw, không neon bloom; shape phân biệt frost/moon/shield/dash |
| IN-05 | Tay phóng/contact/damage/cooldown/save/pause vẫn đúng; full regression Windows/Linux, native ảnh/clip và cold source import |

| WBS | Công việc / bằng chứng |
|---|---|
| IN-W1 | Lưu baseline 0.18; chọn bảng màu/viền/nét/nhịp từ diễn giải nguồn Klei/Steam |
| IN-W2 | Chất liệu SVG và shader grain/mực; grade môi trường/nền giấy F6 |
| IN-W3 | Giữ pose lấy đà, biểu cảm ngắn, trọng tâm/vạt áo; không đổi foot-contact hay authority |
| IN-W4 | Ribbon nét bút, hình burst/mảnh/khiên và tích hợp palette thế giới |
| IN-W5 | Năm acceptance mới + regression; native stability/18 ảnh/clip tám hướng/profile/world/F6; review và ZIP kiểm runtime |

Các thời gian/biên độ là thiết kế cho game này, chưa đo animation DST. Gate kỹ thuật không thay cho art review phát hành/FPS benchmark. QA cuối ghi trong quality-report.md và verification_manifest.json.
