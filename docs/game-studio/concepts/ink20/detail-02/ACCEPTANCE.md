# Cổng duyệt và kiểm chứng

Ngày 11/10/2026. **Pilot runtime đã tích hợp; chưa nghiệm thu production.** Nón/giày SVG 8 hướng, six-slot F6 và save compatibility đã có test. Bảng ảnh vẫn là concept/keyframe, không phải source final hay bằng chứng production.

## A — duyệt concept hiện tại

| Tài liệu/hình | Cần xem | Không được suy ra từ hình |
|---|---|---|
| character-directions-02 | Nam/nữ giữ identity; đủ 8 góc; mặt ngang/sau hợp lý | Đã có 16 head asset đúng pivot/fit |
| wardrobe-modular-02 | Jade/crimson/ivory; kiểu nón/giày; cách tách lớp | Đã có 216 tổ hợp chơi được hoặc ảnh exploded có alpha sạch |
| locomotion-keyframes-02 | Tư thế đi/chạy, profile mắt, bend tay, cloth lag | Foot plant/phase/interpolation thực tế đã đạt |
| combat-keyframes-02 | Kiếm/thương/cast/guard; pose có ý định rõ | Grip đã solve chính xác hoặc clip gây damage đúng |
| skills-ink-02 | 4 shape phân biệt; icon/VFX cùng nét, màu lì | Icon đã đọc được ở 32 px hay VFX đã nối accepted event |
| REVIEW_SUPPLEMENT_03/04 | cận cảnh, gait, grip, state transition và bốn skill beats | source có pivot/alpha, timing chính xác hoặc solver đã chạy |

Sau duyệt phải vẽ nguồn, đặt socket và sửa sai hình theo từng facing. AI có thể tạo khác biệt nhỏ về mắt/tay/tà/vũ khí giữa keyframes; những khác biệt đó phải được khóa bằng source có rig, không copy chúng thành animation thành phẩm.

## B — nghiệm thu sau triển khai

| Test | Yêu cầu | Evidence cần |
|---|---|---|
| ART-20 | Hai body × 8 hướng ở idle; world/HUD/F3/F6 | Contact sheets + native world 48 px, preview lớn |
| FACE-20 | W/E có một mắt đúng profile; N/NW/NE không có mắt | Crop native các hướng; cả idle/run/release |
| LOC-20 | Walk/run/stop/quay gấp, hai hướng ngang và chéo | Footage native; chân chống không trượt rõ, dấu bend đổi đúng hướng |
| GRIP-20 | Kiếm/thương/tay không × 8 hướng, windup/release/guard | Frozen poses + sai lệch grip đo theo world pixel; mục tiêu ≤1 px ở contact |
| MOD-20 | Tất cả 216 tổ hợp resolve catalog; extreme hats/boots/outfits | Validator 216 look đã chạy; native review extreme fits, outfit form và clipping còn lại |
| FIT-20 | Hat mask/hair crown/pony, boot sole, collar/belt | So sánh trước/sau đổi slot ở run/contact/death |
| UI-20 | Preview/Apply/Hủy; HUD/F3/F6; modal chặn held input | Scenario có keyboard/click; không click xuyên/cast qua cửa sổ |
| SAVE-20 | Legacy profile + `appearance_v2` round-trip, thiếu/ID lạ, malformed state, backup | Suite test profile cô lập đã chạy; còn kiểm đường dẫn save/backup trên build PC |
| VFX-20 | 1–4 icon/cast/travel/contact/end và mana/CD/status đúng | Native accepted/rejected cast; lethal hit/blocked LOS/dash wall/slow expire |
| LIFE-20 | Channel cancel, moving cast, hit, death, respawn | Sequence không old action/VFX; pause/respawn đúng |
| RND-20 | Pause/reduced motion/preview hidden; resource lifecycle | 12 static native frames giống nhau khi pause; ẩn preview dừng updates |
| PERF-20 | Bối cảnh có nhiều actor/effect; PC trước | Máy/GPU/renderer/resolution/frame-time thực đo; chưa cam kết con số |
| PORT-20 | Cold import + source/build assets nhất quán | Import Windows/Linux, hashes, log clean, đường dẫn portable |

Các lỗi nghệ thuật vẫn có thể tồn tại dù validator pass. Gate B cần xem hình chạy ở world, đặc biệt tay gần/xa khi đổi hướng, profile đầu, nón che tóc và thương hai tay. Nếu không đạt, giữ pilot và sửa nguồn/rig; không gọi production-ready.

## Những giới hạn của gói concept

- Bộ directions thể hiện silhouette đủ 8 hướng; một số SW/SE còn gần frontal và khác biệt body nam/nữ khá nhẹ. Khi vẽ source, khóa độ quay đầu/thân 45° rõ hơn và nữ fit/face riêng ở world size.
- Bảng walk đã chỉnh để có pose chịu lực/passing rõ hơn; chuỗi vẫn là nghiên cứu hình, chưa khóa đúng chân A/B và arm opposition bằng rig qua toàn vòng. Khi author source phải theo bảng phase trong ANIMATION_AND_SKILLS, không dùng ảnh để khẳng định loop hoàn chỉnh.
- Ảnh keyframe không chứa duration/pivot/skeleton, không dùng làm phép đo foot sliding hoặc grip error.
- Nón/giày có catalog, layer và fallback ID khi restore profile; missing resource path chưa có diagnostic/fallback mỹ thuật riêng.
- Skill board là shape/color study. Vòng Bạch Ngọc đang thể hiện vòng quanh người; cần dựng depth theo nhân vật trong world. Họa tiết ngọc và mảnh impact phải giản lược khi dùng ở kích thước nhỏ.
- Board bổ sung đã có key pose cho channel/dash/hit/death/respawn và grip tám hướng, nhưng chưa có chu kỳ đủ tám hướng hoặc animation runtime mới.
