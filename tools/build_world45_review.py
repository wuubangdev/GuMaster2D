"""Native review gallery: all images are actual Godot framebuffer captures."""
import html,json
from pathlib import Path
R=Path(__file__).resolve().parents[1]; A=R/'artifacts'
world=json.loads((R/'data/world_content.json').read_text())
names={c['id']:c['name'] for v in world['regions'].values() for c in v['camps']}
titles={'village':'Trại nhập môn · quái và thanh Cổ mới','gu_board':'Bảng Cổ · minh họa đồng bộ','forest_atlas':'Địa đồ Thanh Mao Sơn','ruins_atlas':'Địa đồ Tam Vương Cổ Địa','realm_atlas':'Địa đồ Thanh Nang Phúc Địa','atlas_960':'Địa đồ ở cửa sổ 960 × 640'}
art_titles={'beast45_idle':'Quần thể dị thú · tám loại, tám hướng','gu45_icons':'Bốn linh Cổ · hình lớn và biểu tượng trong game','gu45_fx_board':'Cổ thuật · chuẩn bị, phóng và va chạm','gu45_gu_board':'Bảng Cổ · tranh và thông tin tu luyện'}
for skill,label in {'moon':'Nguyệt Quang Cổ','shield':'Bạch Ngọc Cổ','dash':'Bạch Hạc Cổ','frost':'Băng Tằm Cổ'}.items():
    for beat,description in {'windup':'chuẩn bị','release':'thi triển','contact':'va chạm / hoàn tất'}.items():
        art_titles[f'gu45_world_{skill}_{beat}']=f'{label} · {description}'
items=[]
priority=['village','forest_atlas','ruins_atlas','realm_atlas','gu_board','atlas_960']
def world_order(p):
    key=p.stem.removeprefix('world45_')
    return (priority.index(key) if key in priority else len(priority),key)
for p in sorted(A.glob('world45_*.png'),key=world_order):
    key=p.stem.removeprefix('world45_');group='maps'
    if key in titles or key in names: items.append((p.name,titles.get(key,names.get(key,key)),group))
for pat,group in [('beast45_*.png','beasts'),('gu45_*.png','gu')]:
    for p in sorted(A.glob(pat)):
        if 'frame' in p.stem or 'browser' in p.stem: continue
        # The other whole-species plates predate the final toad anatomy fix.
        # The interactive inspector composes those with the corrected toad row.
        if group == 'beasts' and p.stem != 'beast45_idle': continue
        items.append((p.name,art_titles.get(p.stem,p.stem.replace('_',' ')),group))
figures='\n'.join(f'<figure data-group="{g}"><a href="{f}" target="_blank"><img src="{f}" loading="lazy" alt="{html.escape(n)}"></a><figcaption>{html.escape(n)}</figcaption></figure>' for f,n,g in items)
page='''<!doctype html><html lang="vi"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Cổ Giới · Đại vực 0.45</title><style>
*{box-sizing:border-box}body{margin:0;background:#202722;color:#e9dbba;font:16px/1.6 system-ui,sans-serif}main{max-width:1440px;margin:auto;padding:36px 24px}h1{font:clamp(34px,5vw,64px)/1.08 Georgia,serif;margin:12px 0 20px}.eyebrow{color:#aabf9c;letter-spacing:.18em}p{max-width:850px;color:#c8c8ad}.stats{display:flex;flex-wrap:wrap;gap:30px;border-top:1px solid #66705b;border-bottom:1px solid #66705b;padding:20px 0;margin:28px 0}.stats strong{font:36px Georgia,serif;display:block}button{background:#343e32;color:#eadfc5;border:1px solid #758167;border-radius:3px;padding:10px 18px;font:inherit;cursor:pointer}button[aria-pressed=true]{background:#dfc998;color:#253526}nav{display:flex;gap:8px;flex-wrap:wrap;margin:24px 0}#gallery{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}figure{margin:0}img{width:100%;height:auto;display:block;background:#171f1b}figcaption{padding:10px 0 20px;color:#cdd2b9}a{color:#c4d4b7}[hidden]{display:none!important}.motion{margin:30px 0}input{accent-color:#c3ba8c}footer{margin-top:40px;border-top:1px solid #66705b;padding-top:20px;color:#a8b29b}@media(max-width:760px){main{padding:24px 14px}#gallery{grid-template-columns:1fr}.stats{gap:20px}.stats strong{font-size:28px}}
</style><main><div class="eyebrow">CỔ GIỚI / BẢN KIỂM CHẠY 0.45</div><h1>Đại vực & dị thú.</h1><p>Ba vùng mở rộng, những đường vòng qua bãi quái và trạm nghỉ. Hình Cổ mới và sinh vật có khớp chuyển động theo góc nhìn. Các ảnh dưới đây chụp trực tiếp từ Godot, bấm ảnh để xem kích thước gốc.</p><div class="stats"><div><strong>256 × 256</strong>ô mỗi vùng · 7,11× diện tích</div><div><strong>64</strong>bãi farm</div><div><strong>351</strong>cá thể quái</div><div><strong>33 / 176</strong>trạm / nguồn tài nguyên</div></div><p class="motion"><a href="beast45_review.html">▶ Xem chuyển động quái · 8 hướng, phát chậm, từng frame</a><br><a href="gu45_review.html">▶ Xem Cổ thuật · minh họa và nhịp thi triển</a></p><nav><button data-filter="all" aria-pressed="true">Tất cả</button><button data-filter="maps" aria-pressed="false">Bản đồ & trong game</button><button data-filter="beasts" aria-pressed="false">Quái & động tác</button><button data-filter="gu" aria-pressed="false">Cổ thuật & hiệu ứng</button></nav><section id="gallery">'''+figures+'''</section><footer>T trong game: địa đồ, chọn bãi để dẫn đường. G: bảng Cổ. WASD di chuyển · Shift chạy · 1–4 thi triển Cổ. Ảnh review dùng dữ liệu test, không thay đổi hồ sơ chơi.<p>Các thông số quái và mật độ bãi cần playtest cân bằng dài hơn; đây là bản triển khai kiểm được, chưa là nghiệm thu mỹ thuật phát hành.</p><a href="world45_native.json">Kết quả scene/input</a> · <a href="world45_map_tests.json">Kết quả địa lý</a> · <a href="world45_mechanics.json">Hồi quy thế giới</a></footer></main><script>document.querySelectorAll('[data-filter]').forEach(b=>b.onclick=()=>{document.querySelectorAll('[data-filter]').forEach(x=>x.setAttribute('aria-pressed',x===b));document.querySelectorAll('figure').forEach(f=>f.hidden=b.dataset.filter!=='all'&&f.dataset.group!==b.dataset.filter)});</script></html>'''
(A/'world45_review.html').write_text(page)
print('world45_review.html:',len(items),'native captures')
