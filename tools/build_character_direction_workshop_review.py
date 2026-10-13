"""Publish direction-first review from native Godot captures and source SVGs."""
from pathlib import Path
import json
import shutil
import hashlib

ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / "artifacts"
DIRECTIONS = ["Xuống", "Xuống trái", "Trái", "Lên trái", "Lên", "Lên phải", "Phải", "Xuống phải"]
HTML = r'''<!doctype html>
<html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Cổ Sư · Xưởng từng hướng 0.46</title>
<style>
:root{color-scheme:dark;--bg:#17221e;--panel:#23312a;--line:#435147;--ink:#f1e8d4;--muted:#b3b9aa;--gold:#d9b477}*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.5 system-ui,sans-serif}button,select,input{font:inherit}button,select{border:1px solid var(--line);border-radius:6px;padding:8px 12px;background:#29392f;color:var(--ink)}button{cursor:pointer}button:hover,button:focus-visible,select:focus-visible{border-color:var(--gold)}button:disabled{opacity:.42;cursor:default}a{color:var(--gold);text-underline-offset:3px}main{max-width:1260px;margin:auto;padding:36px 28px 70px}header{max-width:860px}.eyebrow{color:var(--gold);font-size:13px;letter-spacing:.12em;text-transform:uppercase}h1{font-family:Georgia,serif;font-size:clamp(28px,4vw,44px);font-weight:500;line-height:1.1;margin:10px 0 18px}header p{color:var(--muted);max-width:750px;margin:0 0 22px}nav{display:flex;flex-wrap:wrap;gap:8px;border-block:1px solid var(--line);padding:16px 0;margin:24px 0}nav button{background:transparent}nav button[aria-pressed=true]{color:#17221e;background:var(--gold);border-color:var(--gold)}.step{font-size:12px;display:block;opacity:.7}.controls{display:flex;align-items:end;gap:16px;flex-wrap:wrap;margin:20px 0}label{display:flex;flex-direction:column;gap:6px;color:var(--muted);font-size:13px}select{min-width:155px}.workspace{background:#303a34;border:1px solid var(--line);border-radius:8px;overflow:hidden}.native{display:block;width:100%;height:auto}.caption{padding:14px 18px;margin:0;background:#202e26;color:var(--muted);font-size:13px}.metadata{display:flex;justify-content:space-between;gap:12px;flex-wrap:wrap;color:var(--muted);font-size:14px;margin:16px 0 10px}h2{font-size:21px;margin:0;color:var(--ink);font-weight:500}.playback{display:flex;gap:10px;align-items:center;flex-wrap:wrap;padding:16px 0}.playback input{flex:1;min-width:130px;accent-color:var(--gold)}output{font-variant-numeric:tabular-nums;min-width:65px;color:var(--muted)}.compare{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin:24px 0}.compare p{font-size:14px;color:var(--muted)}.compare img{width:100%;display:block}.assets{display:grid;grid-template-columns:repeat(auto-fill,minmax(135px,1fr));gap:12px}.asset{border:1px solid var(--line);padding:14px;background:#303a34;border-radius:5px}.asset img{display:block;width:100%;height:110px;object-fit:contain;image-rendering:auto}.asset p{margin:10px 0 0;font-size:13px}.asset small{font-size:11px;color:var(--muted);overflow-wrap:anywhere}.legend{color:var(--muted);font-size:13px;max-width:910px}.legend strong{color:#cfdbc7}.world-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-top:20px}.world-grid img{display:block;width:100%}.world-grid p{color:var(--muted);font-size:13px;margin:8px 0}.world-grid figure{margin:0}details{margin-top:24px;border-top:1px solid var(--line);padding-top:14px}summary{cursor:pointer;color:var(--gold)}footer{margin-top:32px;border-top:1px solid var(--line);padding-top:16px;color:var(--muted);font-size:13px}footer a{margin-right:16px}.warning{border-left:3px solid var(--gold);padding:8px 15px;color:var(--muted);background:#29362c}[hidden]{display:none!important}@media(max-width:600px){main{padding:22px 16px 48px}.controls{gap:10px}select{min-width:140px;max-width:100%}.compare{grid-template-columns:1fr}.playback{gap:8px}nav button{padding:8px 10px}.workspace{margin-inline:-8px}.metadata{align-items:start}.assets{grid-template-columns:repeat(2,minmax(0,1fr))}.world-grid{grid-template-columns:1fr}}
</style></head><body><main><header><span class="eyebrow">Cổ Sư · Xưởng nhân vật · 0.46</span><h1>Làm từng hướng.<br>Kiểm từng điểm nối.</h1><p>Bắt đầu bằng tư thế đứng hướng xuống: khung xương, asset gắn khớp, rồi nhân vật hoàn chỉnh. Giữ hướng đó để kiểm tấn công, đỡ, thu thập và bước chân trước khi chuyển sang hướng kế tiếp.</p></header>
<nav id="directions" aria-label="Chọn hướng nhân vật"></nav><p id="availability" class="warning" hidden></p>
<div class="controls"><label>Giai đoạn<select id="mode"><option value="poses">Tư thế chuẩn</option><option value="motion">Chuyển động</option><option value="equipment">Điểm bám vũ khí</option><option value="assets">Asset riêng theo hướng</option></select></label><label id="poseField">Tư thế<select id="pose"></select></label><label id="actionField" hidden>Động tác<select id="action"><option value="attack">Tấn công</option><option value="defend">Phòng thủ</option><option value="gather">Hái lượm</option><option value="mine">Khai khoáng</option><option value="walk">Đi bộ</option><option value="run">Chạy</option></select></label><label id="weaponField" hidden>Trang bị<select id="weapon"><option value="sword">Kiếm</option><option value="spear">Thương</option><option value="unarmed">Tay không</option></select></label><label id="bodyField" hidden>Giới tính<select id="body"><option value="male">Nam</option><option value="female">Nữ</option></select></label><label id="speedField" hidden>Tốc độ<select id="speed"><option value="1">Trong game · 1×</option><option value=".5">Chậm · ½×</option><option value=".25">Rất chậm · ¼×</option></select></label></div>
<div class="metadata"><h2 id="heading"></h2><span id="status" role="status"></span></div>
<div class="playback" id="playback" hidden><button id="prev" aria-label="Frame trước">←</button><button id="play" disabled>Phát</button><button id="next" aria-label="Frame sau">→</button><input id="slider" type="range" min="0" max="23" value="0" aria-label="Chọn frame"><output id="count"></output></div>
<section id="nativePanel" class="workspace"><img id="native" class="native" alt="Hai giới tính với xương, asset gắn xương và nhân vật hoàn chỉnh"><p class="caption">Ba lớp dùng cùng một snapshot của nhân vật trong Godot. Xanh: bên trái nhân vật. Cam: bên phải. Vòng tròn: cổ tay, điểm cầm và điểm chạm đất.</p></section>
<section id="assets" class="assets" hidden></section><p class="legend" id="assetNote" hidden>SVG nguồn riêng của hướng đang chọn. <strong>Hình trưng bày giữ nguyên asset đã vẽ</strong>; chuyển động và biến dạng chỉ được đánh giá trong các ảnh Godot phía trên. Điểm neo và xương chủ quản đọc trực tiếp từ manifest.</p>
<details id="comparePanel"><summary>Đối chiếu 0.44 → 0.46 ở cùng hướng và cùng pha</summary><p class="legend">Bản trước dùng rig, manifest và atlas 0.44 đã đóng băng. Bản sau dùng rig và asset hiện tại. Hai bản cùng thời điểm trong động tác; vị trí khớp có thể đổi khi sửa tư thế. <a id="baselineReport" href="concept46_before_d0_native.json">Dữ liệu tham chiếu 0.44</a>.</p><div class="compare"><div><p>Trước · 0.44</p><img id="before" alt="Tư thế trước sửa"></div><div><p>Sau · 0.46</p><img id="after" alt="Tư thế sau sửa"></div></div></details>
<p class="legend">Khung hình được chụp bằng renderer thật, gồm cả lớp xương. Trang này phát lại các PNG theo thời lượng clip; không nội suy ảnh, không tạo chuyển động bằng CSS. Kiểm cả thời điểm lấy đà, chạm mục tiêu và thu tay. Chỉ số tự động là bằng chứng kỹ thuật; chất lượng hình vẫn cần nhìn từng tư thế.</p>
<details id="worldPanel" hidden><summary>Nhân vật ở kích thước trong game</summary><div class="world-grid" id="world"></div></details><footer><a id="nativeReport" href="concept46_d0_native.json">Dữ liệu xương và ảnh gốc</a><a href="concept46_workshop.json">Danh mục review</a><a href="concept44_character_review.html">Review 0.44</a></footer>
</main><script>
const data=__DATA__, $=id=>document.getElementById(id), names=__DIRECTIONS__, poseLabels=['Đứng · gắn khớp','Tấn công · lấy đà','Tấn công · ra đòn','Tấn công · thu tay','Đỡ · khuỷu gập','Hái lượm · tiếp xúc','Khai khoáng · giơ cuốc','Đi bộ · chân trụ','Chạy · chuyển trọng tâm'];
let direction=Number(Object.keys(data.directions)[0]||0),frame=0,playing=false,playEpoch=0,startFrame=0,raf=0,loadGeneration=0;const cache=new Map();
names.forEach((name,index)=>{const button=document.createElement('button');button.type='button';button.dataset.direction=index;button.innerHTML=`<span class="step">${String(index+1).padStart(2,'0')}</span>${name}`;button.disabled=!data.directions[index];button.onclick=()=>{stop();direction=index;frame=0;if(report().poses_only&&['motion','equipment'].includes($('mode').value))$('mode').value='poses';update();safePrepare()};$('directions').append(button)});
poseLabels.forEach((name,index)=>$('pose').add(new Option(name,String(index))));
function report(){return data.directions[direction]}function clip(){return report().clips[$('action').value]}function png(n){return `${clip().folder}/frame${String(n).padStart(3,'0')}.png`}function stop(){playing=false;cancelAnimationFrame(raf);$('play').textContent='Phát'}
function update(){const mode=$('mode').value,r=report(),isMotion=mode==='motion',isAsset=mode==='assets',pose=+$('pose').value;for(const button of $('directions').children)button.setAttribute('aria-pressed',String(+button.dataset.direction===direction));$('heading').textContent=`${String(direction+1).padStart(2,'0')} · Hướng ${names[direction].toLowerCase()}`;$('poseField').hidden=mode!=='poses';$('actionField').hidden=!isMotion;$('weaponField').hidden=mode!=='equipment';$('bodyField').hidden=!isAsset;$('speedField').hidden=!isMotion;$('playback').hidden=!isMotion;$('assets').hidden=!isAsset;$('assetNote').hidden=!isAsset;$('nativePanel').hidden=isAsset;$('nativeReport').href=r.report;$('baselineReport').href=`concept46_before_d${direction}_native.json`;const notices=[];if(r.poses_only)notices.push('Hướng này hiện có tư thế tĩnh để kiểm trước. Chuyển động sẽ chỉ mở khi đã có ảnh native thực tế.');if(!r.source_current)notices.push('Ảnh này được chụp trước lần sửa nguồn gần nhất; cần chụp lại để đối chiếu bản hiện tại.');if(r.baseline&&!r.baseline_source_current)notices.push('Nguồn đóng băng của ảnh 0.44 đã thay đổi; cần kiểm lại bộ tham chiếu.');$('availability').hidden=notices.length===0;$('availability').textContent=notices.join(' ');$('mode').querySelector('[value="motion"]').disabled=r.poses_only;$('mode').querySelector('[value="equipment"]').disabled=r.poses_only;let source;
if(mode==='poses'){source=`concept46/d${direction}/pose${String(pose).padStart(2,'0')}.png`;$('status').textContent=poseLabels[pose]}
else if(isMotion){const c=clip();frame=Math.min(frame,c.frames-1);source=png(frame);$('slider').max=c.frames-1;$('slider').value=frame;$('count').textContent=`${frame+1} / ${c.frames}`;$('status').textContent=`${$('action').selectedOptions[0].text} · ${((frame+(c.sample_offset_frames||0))*c.duration/c.frames).toFixed(3)} s`}
else if(mode==='equipment'){source=`concept46/d${direction}/weapon_${$('weapon').value}.png`;$('status').textContent=$('weapon').selectedOptions[0].text+' · pha tấn công 0.34'}
else {showAssets();$('status').textContent='Asset nguồn · '+$('body').selectedOptions[0].text}
if(source)$('native').src=source;const before=r.baseline&&mode==='poses';$('comparePanel').hidden=!before;if(before){$('before').src=`concept46_before/d${direction}/pose${String(pose).padStart(2,'0')}.png`;$('after').src=source}}
function showAssets(){$('assets').replaceChildren();for(const asset of data.assets[`${$('body').value}_${direction}`]||[]){const figure=document.createElement('div');figure.className='asset';const img=document.createElement('img');img.src=asset.url;img.alt=asset.label;const caption=document.createElement('p');caption.textContent=asset.label;const detail=document.createElement('small');detail.textContent=`${asset.bone} · ${asset.side} · neo ${JSON.stringify(asset.anchors)}`;figure.append(img,caption,detail);$('assets').append(figure)}}
async function prepare(){if($('mode').value!=='motion')return;const c=clip(),key=c.folder,generation=++loadGeneration;$('play').disabled=true;if(!cache.has(key)){const images=await Promise.all(Array.from({length:c.frames},(_,i)=>new Promise((resolve,reject)=>{const image=new Image();image.onload=()=>resolve(image);image.onerror=()=>reject(new Error('Không tải được '+image.src));image.src=`${c.folder}/frame${String(i).padStart(3,'0')}.png`})));cache.set(key,images);while(cache.size>2)cache.delete(cache.keys().next().value)}if(generation===loadGeneration)$('play').disabled=false}
function safePrepare(){prepare().catch(error=>{$('status').textContent=error.message;stop()})}function step(amount){stop();const c=clip();frame=(frame+amount+c.frames)%c.frames;update()}
function tick(now){if(!playing)return;const c=clip(),elapsed=(now-playEpoch)*+$('speed').value/1000;frame=(startFrame+Math.floor(elapsed/c.duration*c.frames))%c.frames;update();raf=requestAnimationFrame(tick)}
$('play').onclick=()=>{if(playing){stop();return}playing=true;startFrame=frame;playEpoch=performance.now();$('play').textContent='Dừng';raf=requestAnimationFrame(tick)};$('prev').onclick=()=>step(-1);$('next').onclick=()=>step(1);$('slider').oninput=()=>{stop();frame=+$('slider').value;update()};
for(const id of ['mode','pose','action','weapon','body'])$(id).onchange=()=>{stop();frame=0;update();safePrepare()};$('speed').onchange=()=>{if(playing){startFrame=frame;playEpoch=performance.now()}};
document.addEventListener('keydown',event=>{if($('mode').value!=='motion'||['SELECT','INPUT'].includes(event.target.tagName))return;if(event.key==='ArrowLeft'){event.preventDefault();step(-1)}if(event.key==='ArrowRight'){event.preventDefault();step(1)}if(event.code==='Space'&&!$('play').disabled){event.preventDefault();$('play').click()}});
if(data.world?.length){$('worldPanel').hidden=false;for(const shot of data.world){const figure=document.createElement('figure'),image=document.createElement('img'),caption=document.createElement('p');image.src=shot.file;image.alt=shot.label;image.loading='lazy';caption.textContent=shot.label;figure.append(image,caption);$('world').append(figure)}}
update();
</script></body></html>'''


def build():
    directions = {}
    for d in range(8):
        path = ARTIFACTS / f"concept46_d{d}_native.json"
        if not path.exists():
            continue
        report = json.loads(path.read_text())
        for capture in report["captures"]:
            if not (ARTIFACTS / capture).is_file():
                raise FileNotFoundError(capture)
        directions[str(d)] = {key: report[key] for key in ["direction", "label", "clips", "poses", "poses_only"]}
        directions[str(d)]["report"] = path.name
        baseline_path = ARTIFACTS / f"concept46_before_d{d}_native.json"
        directions[str(d)]["baseline"] = baseline_path.exists()
        if baseline_path.exists():
            baseline = json.loads(baseline_path.read_text())
            frozen_hashes = baseline.get("source_sha256", {})
            directions[str(d)]["baseline_source_current"] = bool(frozen_hashes) and all(
                (ROOT / source).is_file()
                and hashlib.sha256((ROOT / source).read_bytes()).hexdigest() == captured_hash
                for source, captured_hash in frozen_hashes.items()
            )
            for capture in baseline["captures"]:
                if not (ARTIFACTS / capture).is_file():
                    raise FileNotFoundError(capture)
        directions[str(d)]["capture_count"] = len(report["captures"])
        directions[str(d)]["source_sha256"] = report.get("source_sha256", {})
        directions[str(d)]["fitting_revisions"] = report.get("fitting_revisions", {})
        changed_sources = []
        for source, captured_hash in report.get("source_sha256", {}).items():
            current = ROOT / source
            if not current.is_file() or hashlib.sha256(current.read_bytes()).hexdigest() != captured_hash:
                changed_sources.append(source)
        directions[str(d)]["source_current"] = bool(report.get("source_sha256")) and not changed_sources
        directions[str(d)]["changed_sources"] = changed_sources
    if not directions:
        raise RuntimeError("No completed concept46 native direction captures")
    manifest = json.loads((ROOT / "assets/characters/concept-rig/manifest.json").read_text())
    assets = {}
    labels = {"shoulder": "Vai", "sleeve": "Tay áo", "forearm": "Cẳng tay", "hand_relaxed": "Tay thả", "hand_grip": "Tay cầm", "hand_fist": "Nắm tay", "hand_cast": "Tay thi triển", "thigh": "Đùi", "shin": "Cẳng chân", "boot_cloth": "Giày vải", "boot_leather": "Giày da"}
    for view_key, view in manifest["views"].items():
        assets[view_key] = []
        for key, part in view["directional_art"]["parts"].items():
            source = ROOT / part["path"].removeprefix("res://")
            target = ARTIFACTS / "concept46_sources" / view_key / source.name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
            stem, side = key.rsplit("_", 1)
            label = f"{labels.get(stem, stem)} · {'trái' if side=='L' else 'phải'}"
            assets[view_key].append({"url": target.relative_to(ARTIFACTS).as_posix(), "label": label, "bone": part["bone"], "side": side, "anchors": part["anchors"]})
    world = []
    for name, label in [
        ("concept46_world_front.png", "Đứng trong thế giới"),
        ("concept46_world_gather_17.png", "Hái lượm · frame 17/60"),
        ("concept46_world_gather_30.png", "Hái lượm · frame 30/60"),
        ("concept46_world_gather_45.png", "Hái lượm · frame 45/60"),
        ("concept46_world_mine_17.png", "Khai khoáng · frame 17/60"),
        ("concept46_world_mine_30.png", "Khai khoáng · frame 30/60"),
        ("concept46_world_mine_45.png", "Khai khoáng · frame 45/60"),
        ("concept46_studio_mine.png", "Xưởng nhân vật trong game"),
        ("concept46_north_world_gather_30.png", "Hướng lên · hái lượm tại tài nguyên"),
        ("concept46_north_world_mine_30.png", "Hướng lên · khai khoáng tại tài nguyên"),
    ]:
        if (ARTIFACTS / name).is_file():
            world.append({"file": name, "label": label})
    data = {"world": world, "version": "0.46", "directions": directions, "assets": assets, "source": "Native Godot PNG frames; unchanged authored SVG assets"}
    (ARTIFACTS / "concept46_workshop.json").write_text(json.dumps(data, ensure_ascii=False, indent=2))
    (ARTIFACTS / "concept46_character_workshop.html").write_text(HTML.replace("__DATA__", json.dumps(data, ensure_ascii=False)).replace("__DIRECTIONS__", json.dumps(DIRECTIONS, ensure_ascii=False)))
    print(json.dumps({"directions": len(directions), "captures": sum(d["capture_count"] for d in directions.values()), "source_assets": sum(len(a) for a in assets.values())}))


if __name__ == "__main__":
    build()
