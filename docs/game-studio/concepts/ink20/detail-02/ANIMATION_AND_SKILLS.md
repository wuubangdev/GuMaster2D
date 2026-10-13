# Animation và kỹ năng — thiết kế chi tiết

Ngày 11/10/2026. **Đề xuất chưa triển khai**. Ảnh đi/chạy/đánh/thủ là chuỗi keyframe tham khảo, không chứng minh nội suy, grip hoặc foot contact trong Godot.

## Hướng nhìn

Mapping hiện tại đọc từ `GuPixelCharacterView.direction_for()` và `GuIllustratedCharacterArt.sample()`. Hệ màn hình +Y đi xuống. Giữ mapping này để không làm sai hướng di chuyển/cast đã hoạt động:

| Index | ID hiện tại | Tên art | Vector màn hình |
|---|---|---|---|
| 0 | down | S | (0, 1) |
| 1 | down_left | SW | (-1, 1) chuẩn hóa |
| 2 | left | W | (-1, 0) |
| 3 | up_left | NW | (-1, -1) chuẩn hóa |
| 4 | up | N | (0, -1) |
| 5 | up_right | NE | (1, -1) chuẩn hóa |
| 6 | right | E | (1, 0) |
| 7 | down_right | SE | (1, 1) chuẩn hóa |

Đầu/mặt là 8 hình author riêng. Blend thân/tay/chân khi quay khoảng 80–120 ms là mục tiêu để review; không morph hai mặt thành mặt méo hoặc crossfade hai cặp mắt. Khóa hướng của accepted cast/attack tới marker recovery; chân có thể vẫn theo hướng di chuyển nếu state cho phép. Tất cả số timing đề xuất cần tuning bằng footage game thật.

## Thư viện và thời gian

Ưu tiên giữ clip duration hiện hành để hạn chế thay selector. Giá trị dưới đây đọc từ `GuCharacterAnimations.CLIP_DURATIONS/WEAPON_DURATIONS`. Không lấy thời gian từ animation của Klei và không chỉnh authority bằng clip.

| Nhóm | Thời gian hiện hành | Thiết kế pose cần bổ sung | Kết thúc |
|---|---|---|---|
| idle | sword 3.2 s; spear 3.5; unarmed 2.8 | 4 pose thở rất nhỏ, blink shape, bàn tay giữ relaxed grip | Loop khi state đứng |
| walk | 1.05 s nominal | 8 pose stride, gót → cả bàn → mũi, tay đối chân, áo lag | Phase theo quãng đường khi chạy thật |
| run | 0.68 s nominal | 8 pose stride, có flight ngắn, người nghiêng vừa phải, tay gập hơn | Giữ phase khi Shift đổi walk/run |
| attack | sword .86 s; spear .94; unarmed .62 | Ready → windup → held load → release → follow-through → recover | One-shot, không tự phát damage |
| defend | sword 2.0 s; spear 2.6; unarmed 1.8 | Entry → hold trọng tâm → phản lực nhỏ → exit | Hold/loop theo state |
| cast | .90 s | Chuẩn bị bàn tay → tập trung → thả Cổ → thu tay | One-shot/event |
| channel | 2.4 s | Thu tay trước ngực, hơi thở nhỏ, tóc đứng yên hơn | Loop đến accepted end/cancel |
| dash | .42 s | Hạ trọng tâm → lướt → đặt chân → settle | Endpoint do authority quyết định |
| hit | .38 s | Phản lực ở torso, tay giữ vũ khí, chân chống | Không ghi đè death; không spam reset |
| death | 1.15 s | Mất lực → khuỵu → nằm/gục, áo/vũ khí settle | Giữ cuối đến respawn |
| respawn | 1.0 s | Từ pose an toàn → đứng → idle | Xóa action/VFX cũ |

Giá trị nominal phục vụ preview. Trong world, gait phải gắn với quãng đường ground actor đã đi, như cơ chế hiện tại; không chạy loop 1.05 s bất kể tốc độ. Sau khi duyệt tỷ lệ mới, hiệu chỉnh stride/leg length ở presentation; không tăng tốc WASD để che foot sliding. Nguồn animation giữ key chính ở 8 pose nhưng nội suy transforms/mesh ổn định theo frame update. Nét vẽ được giữ nguyên giữa frame, không random nét để giả animation vẽ tay.

## Đi và chạy

| Phase stride | Đi bộ | Chạy |
|---|---|---|
| 0.000 | Chân A đặt gót trước; chân B đẩy mũi | Chân A tiếp đất; người nghiêng về hướng đi |
| 0.125 | Hạ trọng tâm, A tải lực | A nén; gối/chân tải trọng rõ |
| 0.250 | B đi qua chân A; A chống | B đi qua; A đẩy mạnh hơn |
| 0.375 | B vung tới, A nhấc gót | Flight ngắn, B vung tới, tóc/tà đi sau |
| 0.500 | B chạm gót, A đẩy mũi | B tiếp đất |
| 0.625 | B tải lực, người thấp hơn một chút | B nén |
| 0.750 | A đi qua chân B | A đi qua; B đẩy |
| 0.875 | A vung tới, B nhấc gót | Flight ngắn rồi A trở lại contact |

Keyframe board chỉ gợi ý silhouette. Foot plant thực tế cần phase stance/swing và tốc độ phù hợp: walk luôn có chân chống; run có flight ngắn, không bay dài. Chân ở stance phải bù travel của actor; chân swing dùng đường cong lift có vận tốc liên tục khi hạ. Hai chân cùng hướng giải phẫu với gối gập về phía trước cơ thể; dấu gập không cố định screen-left. Hạn chế head bob, giữ eye line ổn định. Khăn/tóc/tà có độ trễ 1–2 pose chính, biên độ vừa đủ và bị clamp; không cho vải xuyên gối hay làm cổ áo kéo theo chân.

Transition mục tiêu: idle→walk 80–120 ms, walk↔run 100–160 ms giữ gait phase, stop 100–180 ms về chân chống gần nhất; hit/death ưu tiên theo state. Mọi giá trị là tuning đề xuất, không phải phép đo của bản chạy.

## Vũ khí và hành động

- **Kiếm:** bàn tay phải giữ chuôi, blade là rigid transform từ grip; tay trái giữ thăng bằng/phòng thủ. Windup có đoạn giữ ngắn để đọc ý định, release nhanh hơn recovery. Tà áo đi theo torso, không phủ mất chuôi.
- **Thương:** cả hai bàn tay bám hai grip trên cùng shaft. Solve bàn tay phụ theo shaft pose, không tween độc lập gây xuyên cán. Body bước/tải trọng khi đâm; thương giữ đủ chiều dài ở cả world và preview.
- **Tay không:** gỡ weapon layers và hiệu ứng chém kiếm; đôi tay dùng nắm mở/nắm kín theo action. Không giữ lại stance hai tay thương.
- **Defend:** có tư thế khác idle, gối chùng vừa đủ và hướng block rõ. Chỉ dựng pose/phản hồi theo state; không tự thêm giảm damage.
- **Cast/channel:** bàn tay và hướng VFX rõ; vũ khí nghỉ an toàn bên hông. Cast khi đang đi dùng gait chân + upper-body action, tránh chạy tại chỗ hoặc giật chân về rest.
- **Death/respawn:** ràng buộc với state thật; preview không được kích hoạt hồi sinh hay sửa máu.

Không dùng marker trong library 3D cũ làm nguồn sự thật cho projectile 2D. Với 4 Cổ, accepted event/contact của authority quyết định khi nào effect xuất hiện và khi nào HP/status đổi. Render animation có thể nén/điều chỉnh để bám event, không trì hoãn damage cho hợp hình.

## Kỹ năng cùng phong cách

4 Cổ dưới đây lấy tên/cơ chế/thông số từ `data/gu_catalog.json`. Bản concept dùng hình icon/VFX mới nhưng không đổi cân bằng.

| Phím / Cổ | Icon và hình effect đề xuất | Luồng hình | Thông số hiện hành |
|---|---|---|---|
| 1 / Nguyệt Quang | Trăng khuyết ngọc lì, mép mực đậm; một nguyệt nhận rõ hướng | Gather ngắn → lưỡi cong travel → nét mực vỡ tại contact | Power 35; mana 8; CD 2 s; range 6 ô; enemy/LOS |
| 2 / Bạch Ngọc | Phiến ngọc ngà và nét giáp; vòng khiên rỗng giữa | Raise → ring giữ quanh thân → 3 mảnh giấy/ngọc tan | Power catalog 70; mana 12; CD 12 s; self; khiên 5 s, tối đa 40% HP |
| 3 / Bạch Hạc | Lông hạc màu ngà, gân đá xanh | Feather gather → 2 nét tốc độ/thưa lông → puff nhỏ đúng endpoint | Mana 10; CD 8 s; tối đa 3 ô; ground; không xuyên tường/cắt góc |
| 4 / Băng Tằm | Tằm ngà bên tinh thể góc cạnh xanh đá | Curl → shard travel → 3 mảnh băng và dấu lạnh dưới chân | Power 20; mana 10; CD 8 s; range 5 ô; slow 30% trong 3 s |

### Recipe VFX

Một silhouette chính + tối đa vài stroke hỗ trợ; width pressure ở nét, alpha fade cuối, hatching/stipple rất ít. Dùng jade/ivory/slate/ochre chung với áo/giấy UI. Vòng bảo vệ rỗng để không phủ mặt và chân. Bạch Hạc không tạo hàng loạt bản sao nhân vật. Băng Tằm khác Bạch Hạc bằng góc tinh thể và tằm, không chỉ đổi màu. Nguyệt Quang không là cục sáng tròn. Không bloom/neon/gradient bóng hoặc emitter che kín nhân vật.

Icon có shape đọc được trong ô 32/48/64 px, outline rộng đủ, nền giấy riêng khỏi glyph. Trạng thái UI: available là màu gốc, cooldown có wipe và số thời gian từ state, thiếu mana có độ tương phản giảm + phản hồi ngắn rõ, selected có vạch mực/viền đồng. Trạng thái không chỉ dựa vào màu. World effect và icon dùng chung recipe, không bắt buộc dùng nguyên PNG icon làm projectile.

Reduced motion bỏ rung/ghost/đám hạt phụ, vẫn giữ travel direction, contact hit, vòng khiên và slow state. Nhiều skill chồng nhau ưu tiên telegraph nguy hiểm/contact; giới hạn số nét phụ theo budget đo thật, không cam kết FPS khi chưa có benchmark.

## Asset coverage

11 nhóm hành động × 8 hướng = 88 ô cần kiểm cho mỗi body/weapon profile. Timeline và rig được dùng chung, body/outfit/hat/boots thay layer; **không cần 216 × 88 clip riêng**. Các pose đặc biệt cần replacement art ở mặt/tay/áo khi transform hiện tại không thể vẽ đẹp. Ít nhất phải có contact sheets 2 body × 8 hướng và 3 vũ khí ở windup/release/guard, thêm walk/run stance và passing. Chỉ các board pose hiện có không đủ nghiệm thu 11 nhóm.
