# Quality target

Current: first-playable, local single-player PC prototype.
Must boot into actionable play, support WASD/click movement and numeric skills1–4, readable resources/target/cooldowns, capture/feed, death recovery and local progression. UI must consume clicks. No known blocker in exercised scenarios.

Visual target: coherent jade forest/worn stone, readable actor/target, y-sorted depth, restrained effects and distinct warnings. Temporary code-drawn art suits this delivery. Baked sound cues and mute exist; listener evaluation remains pending.

Later alpha: polished-prototype,20Gu/3maps/1boss/4active+2passive/rankI–II/party≤3/opt-in duel. G2 requires online PvE and5Gu; this four-Gu local slice does not passG2. All79formal alpha test rows remain unrun. Hardware performance, load/latency, concurrency/anti-dupe, DB restore, Web/mobile and novice usability remain unverified targets.

Fresh evidence and limitations: quality-report.md. Coding plan: ../implementation/GODOT_IMPLEMENTATION_PLAN.md.

Character asset repair target 0.37: production-feature for clean torso ownership and modular cloth bindings across two bodies, eight directions and eleven actions. The overall game remains the local playable prototype described above. Accept source isolation, full cloth coverage, neutral registration, rigid grip/boots, positive mesh winding and native renderer evidence. Artistic acceptance of every hand shape/deep fold remains partial. [Coverage and limits](concept-character-modular-cloth-0.37.md).

## 0.38 — Vùng, luyện Cổ và bí cảnh
Mục tiêu tính năng: một vòng chơi PC local nối 3 vùng, nâng cấp/hợp thành bốn Cổ, trồng 3 loại cây và nuôi 2 loài để tạo tài nguyên thật. Bắt buộc giao dịch thiếu nguyên liệu không sửa trạng thái, trạng thái cũ/mới tải được, tài nguyên đầy túi không mất, menu không phát input chiến đấu, cảnh vùng mới không còn actor/VFX vùng cũ. Kiểm chứng mô phỏng + tương tác/screenshot native tại1280×800 và960×640; hồi quy character0.37. Game tổng thể vẫn là prototype, chưa kiểm chứng cân bằng dài hạn/đồng thời nhiều người/Web/mobile.


## 0.39 — NPC, nhiệm vụ và môi trường

Mục tiêu tính năng: 4 NPC có hội thoại lựa chọn/animation và 6 quest nhập môn nối vòng chơi 0.38. Nghiệm thu: đúng người giao/trả, thưởng một lần, lưu/migration nguyên tử, cửa sổ chặn input, dấu nhiệm vụ rõ, vị trí NPC có đường đến, giao diện đọc được ở 960×640, reduced motion, hồi quy gameplay/rig. Chưa yêu cầu lồng tiếng/cutscene/lịch NPC; game tổng thể tiếp tục là prototype PC local. [Kết quả](quality-report.md).


## 0.40 — Map rộng, bãi farm và tuyến truyền thừa
Phạm vi production-feature trong prototype PC: ba map 96×96, 16 bãi/8 loại quái, 18 quest/7 NPC, 32 nguồn tài nguyên và 9 trạm. Chuỗi quest phải hoàn thành được bằng lệnh thật; thưởng mở chức năng phải dùng được, giao vật liệu không nhận lặp; mọi mục tiêu đi đến được. Cần kiểm va chạm/safe zone/né đòn, native T/E/R/H/F11 và lưu tương thích. Art quái code-native là bản phát triển; chưa cam kết cân bằng, asset mỹ thuật phát hành, MMO hay hỗ trợ thiết bị khác. [Chi tiết](world-expansion-0.40.md).


## 0.41 — Chi tiết hướng và liên kết khung xương

Production-feature trong prototype: tạo và kiểm chi tiết độc lập cho 16 body/view trước khi ghép, hoàn thiện phần khuất, bỏ limb source cũ khỏi đường render mới, kiểm điểm nối/grip, occlusion phía sau, atlas GPU và các động tác trong renderer thật. Bảo toàn PNG nhận diện và API appearance. Bộ phần thân/đầu giữ chi tiết concept; 352 SVG là các biến thể theo công thức art và tỷ lệ từng hướng, không đồng nghĩa 352 tranh vẽ tay hoặc mọi frame đã đạt chất lượng phát hành. [Phạm vi và kiểm chứng](concept-directional-parts-0.41.md).
