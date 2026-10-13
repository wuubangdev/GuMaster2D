"""Build a local inspector over untouched Godot framebuffer PNGs."""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
prefix = sys.argv[1] if len(sys.argv) > 1 else "concept29"
metadata_path = ROOT / "artifacts" / f"{prefix}_action_review.json"
data = json.loads(metadata_path.read_text(encoding="utf-8"))
assert data["native_png_frames"] == 352 and len(data["actions"]) == 11
for action, frames in data["actions"].items():
    assert len(frames) == 32
    for frame in frames:
        assert (ROOT / "artifacts" / f"{prefix}_actions" / action / f"frame{frame['frame']:03d}.png").is_file()

page = r'''<!doctype html><html lang="vi"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>GuMaster2D · Kiểm từng frame</title>
<style>
:root{color-scheme:dark;--paper:#ece1c9;--ink:#252c28;--line:#8d957e}*{box-sizing:border-box}
body{margin:0;background:var(--ink);color:var(--paper);font:16px/1.5 system-ui,sans-serif}
main{max-width:1330px;margin:auto;padding:28px}h1{font-size:25px;margin:0 0 4px;font-weight:650}p{margin:0 0 18px;color:#c9c7b8}
.controls{display:flex;gap:14px;align-items:end;flex-wrap:wrap;padding:18px 0;border-block:1px solid #616a5c}
label{display:grid;gap:4px;font-size:13px}select,button{font:inherit;color:var(--paper);background:#354139;border:1px solid var(--line);border-radius:3px;padding:8px 12px;min-height:40px}
button{cursor:pointer}button:hover{background:#495542}button:focus-visible,select:focus-visible,input:focus-visible{outline:2px solid #e6c889;outline-offset:3px}
.scrub{display:flex;align-items:center;gap:18px;padding:16px 0}input{width:100%;accent-color:#dbc18c}output{white-space:nowrap;font-variant-numeric:tabular-nums}
.detail{display:flex;gap:22px;align-items:center;padding:18px 0}.crop{position:relative;width:160px;height:220px;overflow:hidden;flex-shrink:0;background:#354139;border:1px solid #6b7564}.crop img{position:absolute;max-width:none;width:1280px;height:800px}
.info{font-size:14px;color:#cecbb9;max-width:560px}.info strong{display:block;color:var(--paper);font-size:20px;margin-bottom:6px}
.frame{display:block;width:100%;height:auto;border:1px solid #616a5c}a{color:#e7c996}details{margin-top:20px}summary{cursor:pointer;padding:8px 0}.sheet{width:100%;height:auto}
@media(max-width:650px){main{padding:16px}.detail{gap:12px}.info{font-size:12px}}
</style><main><h1>Nhân vật · kiểm từng frame và từng hướng</h1>
<p>11 động tác · 32 thời điểm mỗi động tác · 8 hướng · 2 giới tính. Ảnh gốc do Godot render; ô chi tiết giữ pixel 1:1, không phóng PNG gây nhòe.</p>
<div class="controls"><label>Động tác<select id="action"></select></label><label>Giới tính<select id="body"><option value="0">Nam</option><option value="1">Nữ</option></select></label>
<label>Hướng<select id="direction"></select></label><label>Tốc độ xem<select id="speed"><option value="8">Chậm · 8 frame/s</option><option value="16">16 frame/s</option><option value="24">24 frame/s</option></select></label>
<button id="prev">← Frame trước</button><button id="play">Phát</button><button id="next">Frame sau →</button></div>
<div class="scrub"><input id="slider" aria-label="Chọn frame" type="range" min="0" max="31" value="0"><output id="count"></output></div>
<div class="detail"><div class="crop"><img id="focus" alt="Nhân vật đang được kiểm tra"></div><div class="info"><strong id="name"></strong><span id="pose"></span><p>Kiểm gấu áo, hình giày, điểm tiếp đất, cổ tay và viền ở pha đang chọn. Phím ← / → đổi frame; Space phát hoặc dừng.</p><a id="original">Mở framebuffer gốc</a></div></div>
<img id="full" class="frame" alt="Frame native với hai body và tám hướng"><details><summary>Bảng tám pha đi lên / đi xuống của động tác này</summary><img id="sheet" class="sheet" alt="Tám pha ở hướng lên và xuống"></details>
<p style="margin-top:20px">Đây là bộ frame runtime được lấy mẫu dày hơn, cùng pose renderer của game. Màu bên trong vẫn từ concept PNG; các frame này không phải bộ artwork mới vẽ tay.</p></main>
<script>
const data=__DATA__,prefix=__PREFIX__,dirs=['S · xuống','SW · xuống trái','W · trái','NW · lên trái','N · lên','NE · lên phải','E · phải','SE · xuống phải'];
const labels={idle:'Đứng',walk:'Đi',run:'Chạy',attack:'Tấn công',cast:'Thi triển',defend:'Phòng thủ',channel:'Vận công',dash:'Lướt',hit:'Trúng đòn',death:'Gục',respawn:'Hồi sinh'};
const $=id=>document.getElementById(id);let timer=null;
for(const action of Object.keys(data.actions))$('action').add(new Option(labels[action],action));$('action').value='walk';
dirs.forEach((d,i)=>$('direction').add(new Option(d,i)));
function update(){const action=$('action').value,n=+$('slider').value,d=+$('direction').value,b=+$('body').value,frame=data.actions[action][n],url=`${prefix}_actions/${action}/frame${String(n).padStart(3,'0')}.png`;
 $('count').textContent=`${String(n).padStart(2,'0')} / 31`;$('full').src=url;$('focus').src=url;$('original').href=url;$('sheet').src=`${prefix}_phases_${action}.png`;
 $('focus').style.left=`${-(d*160)}px`;$('focus').style.top=`${-(b*320+130)}px`;
 $('name').textContent=`${labels[action]} · ${b?'Nữ':'Nam'} · ${dirs[d]}`;
 const contacts=frame.poses[b*8+d].contacts;$('pose').textContent=`Pha ${frame.phase.toFixed(4)} · tiếp đất trái ${contacts[0].toFixed(2)} / phải ${contacts[1].toFixed(2)}`;}
function step(delta){$('slider').value=(+$('slider').value+delta+32)%32;update()}
function stop(){clearInterval(timer);timer=null;$('play').textContent='Phát'}
function play(){if(timer){stop();return}timer=setInterval(()=>step(1),1000/+$('speed').value);$('play').textContent='Dừng'}
$('play').onclick=play;$('prev').onclick=()=>{stop();step(-1)};$('next').onclick=()=>{stop();step(1)};$('slider').oninput=()=>{stop();update()};
for(const id of ['action','body','direction'])$(id).onchange=update;$('speed').onchange=()=>{if(timer){stop();play()}};
document.addEventListener('keydown',e=>{if(['SELECT','INPUT'].includes(e.target.tagName))return;if(e.key==='ArrowLeft'){e.preventDefault();stop();step(-1)}if(e.key==='ArrowRight'){e.preventDefault();stop();step(1)}if(e.code==='Space'){e.preventDefault();play()}});window.onresize=update;update();
</script></html>'''
page = page.replace("__DATA__", json.dumps(data, ensure_ascii=False)).replace("__PREFIX__", json.dumps(prefix))
if prefix in ("concept30", "concept31", "concept32", "concept33", "concept34", "concept35", "concept36", "concept37"):
    baseline = "concept" + str(int(prefix.removeprefix("concept")) - 1)
    old_version = "0." + baseline.removeprefix("concept")
    new_version = "0." + prefix.removeprefix("concept")
    # The baseline and current PNGs were sampled at identical action phases.
    # Keep both views at their native pixel size for a fair comparison.
    page = page.replace('<div class="detail"><div class="crop">', '<div class="detail"><div class="compare"><label>__OLD__ · trước sửa</label><div class="crop"><img id="baseline" alt="Cùng nhân vật và pha ở bản trước"></div></div><div class="compare"><label>__NEW__ · hiện tại</label><div class="crop">')
    page = page.replace('alt="Nhân vật đang được kiểm tra"></div><div class="info">', 'alt="Nhân vật đang được kiểm tra"></div></div><div class="info">')
    page = page.replace('@media(max-width:650px)', '.detail{flex-wrap:wrap}.compare label{margin-bottom:6px}.compare{flex-shrink:0}@media(max-width:650px)')
    page = page.replace("$('name').textContent=", "$('baseline').src=`__BASE___actions/${action}/frame${String(n).padStart(3,'0')}.png`;$('baseline').style.left=$('focus').style.left;$('baseline').style.top=$('focus').style.top;\n $('name').textContent=")
    page = page.replace('<img id="full"', '<details><summary>Clip bước chân và tay áo trong game</summary><img class="sheet" src="__CURRENT___vertical.webp" alt="Đi lên, chạy lên, chạy xuống và dừng bằng input thật"><img class="sheet" src="__CURRENT___motion.webp" alt="Walk/run: hai body và tám hướng"></details><img id="full"')
    page = page.replace("__OLD__", old_version).replace("__NEW__", new_version).replace("__BASE__", baseline).replace("__CURRENT__", prefix)
if prefix in ("concept31", "concept32", "concept33", "concept34", "concept35", "concept36", "concept37"):
    page = page.replace("value='walk'", "value='attack'")
    page = page.replace('<div class="controls">', '<p><a href="__COMBAT_LINK__">Xem riêng kiếm / thương / tay không và khung xương</a></p><div class="controls">')
page = page.replace("__COMBAT_LINK__", f"{prefix}_combat_review.html")
if prefix == "concept37":
    page = page.replace("Màu bên trong vẫn từ concept PNG; các frame này không phải bộ artwork mới vẽ tay.", "Thân sạch và phần tay áo khuất dùng SVG riêng cho 16 góc nhìn; nếp co/duỗi theo khớp. Các frame là chuyển động rig; ngón tay và nếp gập mạnh chưa có toàn bộ drawing riêng theo hành động.")
output = ROOT / "artifacts" / f"{prefix}_frame_review.html"
output.write_text(page, encoding="utf-8")
print(f"Built {output}; all 352 native frame files exist")
