"""Local review of untouched native framebuffers, including genuine bone captures."""
from pathlib import Path
import json
import sys

root = Path(__file__).resolve().parents[1]
prefix = sys.argv[1] if len(sys.argv) > 1 else "concept36"
data = json.loads((root / "artifacts" / f"{prefix}_combat_review.json").read_text())
for weapon, frames in data["weapons"].items():
    assert len(frames) == 48
    for frame in frames:
        assert (root / "artifacts" / f"{prefix}_combat" / weapon / f"frame{frame['frame']:03}.png").is_file()

page = '''<!doctype html><html lang="vi"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Cổ Sư · Tay, khớp và vũ khí 0.31</title><style>
*{box-sizing:border-box}body{margin:0;background:#252c28;color:#ece1c9;font:16px/1.5 system-ui,sans-serif}main{max-width:1330px;margin:auto;padding:28px}h1{font-size:25px;margin:0 0 8px}p{color:#c9c7b8;margin:0 0 18px}a{color:#e7c996}
.controls{display:flex;gap:14px;flex-wrap:wrap;align-items:end;padding:18px 0;border-block:1px solid #616a5c}label{display:grid;gap:4px;font-size:13px}select,button{font:inherit;color:#ece1c9;background:#354139;border:1px solid #8d957e;border-radius:3px;padding:8px 12px;min-height:40px}button{cursor:pointer}button:hover{background:#495542}:focus-visible{outline:2px solid #e6c889;outline-offset:3px}
.scrub{display:flex;gap:18px;padding:18px 0}input[type=range]{width:100%;accent-color:#dbc18c}output{white-space:nowrap;font-variant-numeric:tabular-nums}.detail{display:flex;align-items:center;gap:22px;flex-wrap:wrap}.crop{position:relative;width:160px;height:220px;overflow:hidden;background:#354139;border:1px solid #6b7564}.crop img{position:absolute;width:1280px;height:800px;max-width:none}.info{max-width:520px}.info strong{display:block;font-size:20px;margin-bottom:8px}.frame{width:100%;height:auto;border:1px solid #616a5c;margin-top:20px}details{margin-top:18px}summary{cursor:pointer;padding:8px 0}.compare label{margin-bottom:6px}@media(max-width:650px){main{padding:16px}.detail{gap:12px}}
</style><main><h1>Tay, khớp và vũ khí · bản 0.31</h1>
<p>Kiếm chém, thương đâm, tay không · 48 thời điểm · 8 hướng · 2 giới tính. So cùng pha với 0.30; ảnh do Godot render, ô chi tiết giữ pixel 1:1.</p>
<div class="controls"><label>Vũ khí<select id="weapon"><option value="sword">Kiếm</option><option value="spear">Thương</option><option value="unarmed">Tay không</option></select></label><label>Giới tính<select id="body"><option value="0">Nam</option><option value="1">Nữ</option></select></label><label>Hướng<select id="direction"></select></label><label>Tốc độ xem<select id="speed"><option value="8">Chậm · 8 frame/s</option><option value="24">24 frame/s</option><option value="56">56 frame/s</option></select></label><label>Khớp<select id="bones"><option value="0">Hình trong game</option><option value="1">Vai / khuỷu / cổ tay / bàn tay</option></select></label><button id="prev">←</button><button id="play">Phát</button><button id="next">→</button></div>
<div class="scrub"><input id="slider" aria-label="Chọn frame" type="range" min="0" max="47" value="16"><output id="count"></output></div>
<div class="detail"><div class="compare"><label>0.30 · trước sửa</label><div class="crop"><img id="baseline" alt="Bản trước ở cùng pha"></div></div><div class="compare"><label>0.31 · hiện tại</label><div class="crop"><img id="focus" alt="Tư thế hiện tại"></div></div><div class="info"><strong id="name"></strong><p id="pose"></p><p>Overlay cam: tay cầm, xanh: tay đỡ, trắng: cổ tay và lòng bàn tay, vàng: trục vũ khí. Có 7 pha overlay thực; khi bật, thanh frame chọn đúng các ảnh đã chụp.</p><a id="original">Mở ảnh native đầy đủ</a> · <a href="concept31_frame_review.html">11 động tác khác</a></div></div>
<img id="full" class="frame" alt="Hai body và tám hướng"><details><summary>Clip toàn bộ chu kỳ tấn công</summary><img id="clip" class="frame" alt="Clip từ nguyên frame Godot"></details><p style="margin-top:18px">Màu concept gốc được giữ lại. Đây là chuyển động bằng rig và pose key; tay áo lộ ra được nối bằng đường cong vector; bàn tay xoay riêng ở cổ tay, chuôi kiếm và hiệu ứng bám cùng điểm nắm.</p></main>
<script>const prefix=__PREFIX__,data=__DATA__,dirs=['S · xuống','SW · xuống trái','W · trái','NW · lên trái','N · lên','NE · lên phải','E · phải','SE · xuống phải'],labels={sword:'Kiếm',spear:'Thương',unarmed:'Tay không'},boneFrames=[0,8,12,16,23,32,47],$=id=>document.getElementById(id);let timer=null;
dirs.forEach((d,i)=>$('direction').add(new Option(d,i)));$('direction').value='6';
function url(p,w,n,b){return b?`${p}_combat_${w}_bones_${String(n).padStart(2,'0')}.png`:`${p}_combat/${w}/frame${String(n).padStart(3,'0')}.png`}
function update(){const w=$('weapon').value,d=+$('direction').value,b=+$('body').value,overlay=$('bones').value==='1';let n=+$('slider').value;if(overlay){n=boneFrames.reduce((a,c)=>Math.abs(c-n)<Math.abs(a-n)?c:a);$('slider').value=n}const frame=data.weapons[w][n];$('count').textContent=`${String(n).padStart(2,'0')} / 47`;
 $('full').src=$('focus').src=$('original').href=url(prefix,w,n,overlay);$('baseline').src=url('concept30',w,n,overlay);$('clip').src=`${prefix}_combat_${w}.webp`;
 for(const id of ['focus','baseline']){$(id).style.left=`${-d*160}px`;$(id).style.top=`${-(b*320+130)}px`}
 $('name').textContent=`${labels[w]} · ${b?'Nữ':'Nam'} · ${dirs[d]}`;const pose=frame.samples[b*8+d];$('pose').textContent=`Pha ${frame.phase.toFixed(3)} · cổ tay ${(pose.wrist*180/Math.PI).toFixed(1)}° · ${n<9?'Lấy đà':n<16?'Ra đòn':n<28?'Theo đà':'Thu tay'}`;}
function stop(){clearInterval(timer);timer=null;$('play').textContent='Phát'}function step(delta){let n=+$('slider').value;if($('bones').value==='1')n=boneFrames[(boneFrames.indexOf(n)+delta+boneFrames.length)%boneFrames.length];else n=(n+delta+48)%48;$('slider').value=n;update()}
function play(){if(timer){stop();return}timer=setInterval(()=>step(1),1000/+$('speed').value);$('play').textContent='Dừng'}$('play').onclick=play;$('prev').onclick=()=>{stop();step(-1)};$('next').onclick=()=>{stop();step(1)};$('slider').oninput=()=>{stop();update()};for(const id of ['weapon','body','direction','bones'])$(id).onchange=()=>{stop();update()};$('speed').onchange=()=>{if(timer){stop();play()}};
document.addEventListener('keydown',e=>{if(['SELECT','INPUT'].includes(e.target.tagName))return;if(e.key==='ArrowLeft'){e.preventDefault();stop();step(-1)}if(e.key==='ArrowRight'){e.preventDefault();stop();step(1)}if(e.code==='Space'){e.preventDefault();play()}});update();
</script></html>'''
version = '0.' + prefix.removeprefix('concept')
baseline = 'concept' + str(int(prefix.removeprefix('concept')) - 1)
old_version = '0.' + baseline.removeprefix('concept')
page = page.replace('0.30', '__OLD_VERSION__').replace('0.31', version).replace('__OLD_VERSION__', old_version).replace("url('concept30',", f"url('{baseline}',").replace('concept31_frame_review.html', f'{prefix}_frame_review.html')
page = page.replace('__PREFIX__', json.dumps(prefix)).replace('__DATA__', json.dumps(data, ensure_ascii=False))
if int(prefix.removeprefix('concept')) >= 33:
    page = page.replace('· cổ tay ${(pose.wrist*180/Math.PI).toFixed(1)}°', '· tay cầm ${(pose.hand_rotation*180/Math.PI).toFixed(1)}° / tay đỡ ${((pose.support_rotation||0)*180/Math.PI).toFixed(1)}°')
    page = page.replace('Màu concept gốc được giữ lại. Đây là chuyển động bằng rig và pose key; tay áo lộ ra được nối bằng đường cong vector; bàn tay xoay riêng ở cổ tay, chuôi kiếm và hiệu ứng bám cùng điểm nắm.', 'Tay đỡ theo đà kiếm, thu chậm hơn tay cầm và có góc cổ tay riêng; khi đấm, tay còn lại giữ gần ngực. Khuỷu chỉ nối phía áo mở, màu nối lấy từ pigment tay áo gốc. Màu bên trong vẫn từ concept PNG; chưa có drawing nếp gập/ngón tay mới theo từng pha.')
if prefix == 'concept34':
    page = page.replace("$('direction').value='6'", "$('direction').value='2'")
    page = page.replace('Tay đỡ theo đà kiếm, thu chậm hơn tay cầm và có góc cổ tay riêng; khi đấm, tay còn lại giữ gần ngực. Khuỷu chỉ nối phía áo mở, màu nối lấy từ pigment tay áo gốc. Màu bên trong vẫn từ concept PNG; chưa có drawing nếp gập/ngón tay mới theo từng pha.', 'Vải cánh tay trên uốn cục bộ gần khuỷu; đường viền theo cùng biến dạng, phần bổ sung ở vai bắt đầu dưới thân áo. Cẳng tay, bàn tay và điểm cầm giữ đúng form. So cùng pha với 0.33; PNG concept gốc giữ nguyên. Nếp gập mạnh và kiểu nắm vẫn cần drawing theo hành động.')
if prefix == 'concept35':
    page = page.replace("$('direction').value='6'", "$('direction').value='4'")
if prefix == 'concept36':
    page = page.replace('Tay đỡ theo đà kiếm, thu chậm hơn tay cầm và có góc cổ tay riêng; khi đấm, tay còn lại giữ gần ngực. Khuỷu chỉ nối phía áo mở, màu nối lấy từ pigment tay áo gốc. Màu bên trong vẫn từ concept PNG; chưa có drawing nếp gập/ngón tay mới theo từng pha.', 'Phần áo dưới tay được hoàn thiện tới đai và vạt áo; viền thân theo silhouette đầy đủ, bỏ viền lỗ tay đứng cũ. Đai da tiếp nối bên dưới bàn tay. Khi chém ngang, tay cầm duỗi qua mục tiêu ở pha chạm đòn. So cùng pha với 0.35; PNG concept gốc giữ nguyên. Nếp gập mạnh và phần tay khuất vẫn cần art review.')
if prefix == 'concept37':
    page = page.replace('Overlay cam: tay cầm, xanh: tay đỡ, trắng: cổ tay và lòng bàn tay, vàng: trục vũ khí.', 'Overlay cam: tay cầm, xanh: tay đỡ, trắng: cổ tay/bàn tay, xanh lá: 5 điểm điều khiển vải, vàng: trục vũ khí.')
    page = page.replace('Màu bên trong vẫn từ concept PNG; chưa có drawing nếp gập/ngón tay mới theo từng pha.', 'Thân sạch và phần tay áo khuất có asset SVG riêng cho 16 góc nhìn; nếp gập/duỗi phối liên tục theo khớp. Cổ áo, phụ kiện và nét nhận diện vẫn từ concept gốc. Phần ngón tay chưa có drawing riêng cho từng kiểu nắm.')
    page = page.replace('<img id="full"', '<details><summary>Kiểm thân riêng và các lớp lắp ráp</summary><img class="frame" src="concept37_body_only.png" alt="Thân riêng, không có tay và chân"><img class="frame" src="concept37_parts_exploded.png" alt="Các lớp được tách riêng"></details><img id="full"')
output = root / 'artifacts' / f'{prefix}_combat_review.html'
output.write_text(page, encoding='utf-8')
print(f'Built {output}: 144 native frames + 21 bone captures')
