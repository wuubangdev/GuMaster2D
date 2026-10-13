"""Summarize verified local evidence; never reads or modifies a player's save."""
from pathlib import Path
import json, hashlib
root=Path(__file__).resolve().parents[1]
art=root/'artifacts'
reports={k:json.loads((art/f'world40_{k}.json').read_text()) for k in ['mechanics','native','quests','cultivation','regression']}
for key,report in reports.items():
 assert report['failed']==0,(key,report['failed'])
 log=(art/f'world40_{key}.log').read_text()
 assert not any(word in log for word in ['SCRIPT ERROR','ERROR:','FAIL:']),key
assert reports['native']['passed']==49,'Latest water/native pass required'
assert json.loads((art/'world40_browser.json').read_text())['passed']
counts={k:r['passed'] for k,r in reports.items()}
total=sum(counts.values())
concepts={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [root/'assets/characters/concept-rig/character-concept-01.png',root/'assets/characters/concept-rig/character-directions-02.png']}
assert list(concepts.values())==['20432dfcdff4b38f93c5ddd55649e6c5de0d68c56bee2d963d16a2747d80d7ce','29dfab20fc6eda61bcca24f09f255e515a1d34711b602d019f67561f712ef6e7']
changed=[]
for p in (art/'world40_baseline').rglob('*'):
 if p.is_file():
  rel=p.relative_to(art/'world40_baseline');current=root/rel
  if current.is_file() and p.read_bytes()!=current.read_bytes():changed.append(str(rel))
new=[str(p.relative_to(root)) for folder in ['scripts/core','scripts/presentation','scripts/ui','data'] for p in (root/folder).glob('*') if p.suffix in ['.gd','.json'] and not (art/'world40_baseline'/p.relative_to(root)).exists()]
delivery={'version':'0.40','scope':{'regions':3,'size':[96,96],'area_multiplier':round(96**2/28**2,4),'farm_camps':16,'species':8,'base_shapes':6,'elite_species':2,'total_population':93,'quests':18,'main_quests':10,'side_quests':8,'npcs':7,'gather_nodes':32,'waypoints':9,'utility_rewards':['waygates','field_medicine','irrigation']},'verification':counts,'passed':total,'failed':0,'browser':'world40_browser.json','review':'http://localhost:8879/world40_review.html','native_screenshots':len(reports['native']['shots']),'review_screenshots':23,'concept_sha256':concepts,'data_authoring_idempotent':True,'modified_baseline_files':changed,'added_content_files':new,'platform':'Godot 4.7.2 Linux / X11 / Mesa llvmpipe','limits':['Local single-player prototype; no Windows hardware or Web/mobile performance certification.','Native fixtures skip travel/combat duration; authority suite executes all eighteen quest objectives and payouts.','Enemy population persists between regions within a session, resets on profile reload; active-play resource and medicine cooldowns persist.','Visual art and balance are development quality; not release approval.','Regression passed before the final cosmetic water overlay; native checks were repeated after that overlay.']}
(art/'world40_delivery.json').write_text(json.dumps(delivery,ensure_ascii=False,indent=2)+'\n')
readme=root/'README.md';text=readme.read_text();section=f'''## Cập nhật 0.40 — Ba đại vực và tuyến truyền thừa

- **Ba map 96×96 ô**: Thanh Mao Sơn, Tam Vương Cổ Địa, Thanh Nang Phúc Địa; mỗi vùng rộng **11,76 lần diện tích cũ**. Đường nối bãi, trúc/cột vỡ, sông–đầm có cầu, 32 điểm tài nguyên và 9 trạm khám phá.
- **16 bãi farm / 8 loại quái / 93 cá thể**: sói, lợn, nhện, ong, cóc, giáp trùng và hai loại đầu lĩnh. Ba cách đánh có báo trước: cận chiến, lao, phun vùng; loot và thời gian hồi riêng.
- **18 quest (10 chính, 8 phụ), 7 NPC**: tông tộc → lang triều → truyền thừa → khôi phục linh mạch. Quest giao đồ tiêu hao thật; thưởng mở trạm nội vùng, dược phương **R** và tưới toàn bộ ruộng **H**.
- **T** xem bản đồ trong vùng / sang vùng khác; chọn bãi xem loot và dẫn đường. **F11** lọc chính/phụ, **E** NPC hoặc tài nguyên. Nhân vật concept hiện hành giữ nguyên, save cũ được hỗ trợ.

Bắt đầu bằng **Lời dặn dưới đèn** tại Lâm An, sau đó **Đường qua rừng trúc**. Bãi phía đông nam có đầu lĩnh; nâng Cổ và quan sát vùng báo đòn trước khi tới.

[Ảnh ba map và 18 quest](http://localhost:8879/world40_review.html) · [FSD, WBS, cốt truyện và giới hạn](docs/game-studio/world-expansion-0.40.md). Kiểm Linux: **{total}/{total}**, gồm {counts['mechanics']} thế giới, {counts['quests']} quest, {counts['cultivation']} điền viên, {counts['native']} native và {counts['regression']} hồi quy. Game vẫn là prototype PC, chưa nghiệm thu cân bằng/mỹ thuật phát hành.

'''
if '## Cập nhật 0.40' not in text:text=text.replace('## Cập nhật 0.39',section+'## Cập nhật 0.39',1)
readme.write_text(text)
quality=root/'docs/game-studio/quality-report.md';text=quality.read_text();section=f'''# Ba đại vực và truyền thừa 0.40

Đã triển khai ba map 96×96, 16 bãi/8 loài/93 cá thể, 18 quest/7 NPC, 32 nguồn tài nguyên, 9 trạm và 3 phần thưởng chức năng. [Phạm vi, WBS, nguồn truyện và cách chơi](world-expansion-0.40.md).

| Kiểm tra | Kết quả | Bằng chứng |
|---|---|---|
| World, bãi, AI, giao dịch và lưu | Pass {counts['mechanics']}: mọi bãi/node/spawn có đường; chuỗi 18 quest, loot, hồi sinh, aim/dodge/LOS/safe zone, functional rewards, save cũ/hỏng | [Mô phỏng](../../artifacts/world40_mechanics.json) |
| NPC/quest nền | Pass {counts['quests']}: chuỗi nhập môn, đúng giver/turn-in, chống lặp, NPC mới đi tới được | [Quest](../../artifacts/world40_quests.json) |
| Điền viên / nâng Cổ | Pass {counts['cultivation']}: farm, hợp thành, chi phí, save, vùng ruộng an toàn và vùng hoang có quái | [Cultivation](../../artifacts/world40_cultivation.json) |
| Native PC input / render | Pass {counts['native']}: T/E/R/H/F11, click camp/numeric skill, NPC/quest, dẫn đường, dịch chuyển, minimum viewport, culling/wakeup; {len(reports['native']['shots'])} ảnh | [Native](../../artifacts/world40_native.json) |
| Hồi quy nhân vật / UI / combat | Pass {counts['regression']}; giữ source PNG, rig và gameplay cũ; cập nhật assertion số lượng và renderer theo nội dung mới | [Regression](../../artifacts/world40_regression.json) |
| Trang review | Pass: 23 PNG decode, 5 nhóm ảnh, 18 quest/3 bộ lọc, rộng 1360/960/390, không page error | [Browser](../../artifacts/world40_browser.json) |
| Chất lượng phát hành | Partial: quái mới dùng art vector code-native; chưa benchmark Windows/Web/mobile hoặc playtest cân bằng dài hạn | [Giới hạn](world-expansion-0.40.md) |

Tổng **{total}/{total}** lượt kiểm; các suite có giao nhau. Regression chạy trước lớp nước liên tục cuối; native chạy lại sau lớp nước. Không coi kiểm framebuffer hay benchmark headless là FPS thiết bị người dùng. Fixture native có đặt vị trí/tiến độ để bỏ thời gian di chuyển/chiến đấu; mô phỏng thực thi đủ 18 mục tiêu và claim. Không sửa save thật. Hai PNG concept giữ SHA-256, recorded trong [delivery](../../artifacts/world40_delivery.json). Blueprint map cache độc lập mỗi authority; đo {reports['mechanics']['metrics']['idle_600_steps_ms']}ms cho 600 bước mô phỏng đứng ở trại chỉ là phép đo cục bộ.

'''
if not text.startswith('# Ba đại vực'):quality.write_text(section+text)
p=root/'docs/game-studio/world-expansion-0.40.md';text=p.read_text();text+=f'''\n\n## Kết quả nghiệm thu 2026-10-12\nWBS 1–5 đã triển khai và kiểm trong bản PC local: **{total}/{total}** lượt kiểm, 0 failure; {counts['mechanics']} world, {counts['quests']} quest, {counts['cultivation']} cultivation, {counts['native']} native, {counts['regression']} regression. Hai PNG concept giữ nguyên hash. [Bảng bằng chứng](quality-report.md), [delivery JSON](../../artifacts/world40_delivery.json), [23 ảnh native và danh mục 18 quest](http://localhost:8879/world40_review.html). Art và cân bằng phát hành tiếp tục là phần chưa nghiệm thu.\n'''
if '## Kết quả nghiệm thu 2026-10-12' not in p.read_text():p.write_text(text)
print('WORLD40_DELIVERY',total,'checks,',len(reports['native']['shots']),'native captures,',len(changed),'modified baseline files')
