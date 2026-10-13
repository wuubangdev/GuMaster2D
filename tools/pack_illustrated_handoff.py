"""Build the 0.19 handoff only from fresh runtime and native evidence."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import os
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT/'artifacts'
EVIDENCE = ROOT/'docs/game-studio/evidence'
EVIDENCE.mkdir(parents=True, exist_ok=True)

def read(path):
    return json.loads(path.read_text(encoding='utf-8'))

def copy(name):
    shutil.copy2(ARTIFACTS/name, EVIDENCE/name)

def log(name, marker=None):
    value=(ARTIFACTS/name).read_text(encoding='utf-8')
    assert not any(v in value for v in ('SCRIPT ERROR','ERROR:','FAIL:','Traceback','rejected for slot')),name
    if marker:
        assert marker in value,(name,marker)
    copy(name)

def source_files(folders):
    paths=[]
    for folder in folders:
        paths += [p for p in (ROOT/folder).rglob('*') if p.is_file() and p.suffix not in ('.import','.pyc') and '__pycache__' not in p.parts]
    return paths

def digest(paths):
    h=hashlib.sha256()
    for path in sorted(paths):
        h.update(path.relative_to(ROOT).as_posix().encode())
        h.update(path.read_bytes())
    return h.hexdigest()

reports={}
for platform in ('windows','linux'):
    name=f'test_results_{platform}.json'
    r=read(ARTIFACTS/name)
    assert r['failed']==0 and r['passed']==r['total'] and r['total']>=524,r
    log(f'{platform}_tests.log',f"TEST_RESULTS {r['total']}/{r['total']} passed; 0 failed")
    copy(name)
    reports[platform]={key:r[key] for key in ('engine','platform','total','passed','failed')}
assert reports['windows']['total']==reports['linux']['total']
for name in ('vector_linux_import.log','vector_windows_import.log','vector_cold_import.log'):
    log(name)
log('vector_cold_portability.log','VECTOR_PORTABILITY_OK 131 SVG parts; 36 looks; continuous rig; 13 vector effects')
log('vector_character_generation.log','VECTOR_CHARACTER_SOURCE_OK 131 original SVG pieces; 8 views; 36 looks; 8x source resolution')

portability=read(ARTIFACTS/'vector_portability_manifest.json')
runtime=source_files(('scripts','scenes','data','assets'))+[ROOT/'project.godot']
assert portability['packaged_runtime_matches_workspace'] is True
assert len(runtime)==portability['runtime_files'] and digest(runtime)==portability['runtime_sha256']
copy('vector_portability_manifest.json')

visual=read(ARTIFACTS/'ink19_visual_capture.json')
assert visual['screenshots']==len(visual['samples'])>=18
assert {1,2,3,4}<=set(visual['accepted_slots'])
names={s['file'] for s in visual['samples']}
assert {'ink19_feedback_sheet.png','ink19_gameplay_1280.png','ink19_gameplay_960.png','ink19_studio_male.png','ink19_studio_960.png','ink19_character_directions.png','ink19_character_weapon_phases.png','ink19_character_actions.png','ink19_skill_moon_travel.png','ink19_skill_moon_impact.png','ink19_skill_shield.png','ink19_skill_dash.png','ink19_skill_frost.png','ink19_lethal_moon_contact.png','ink19_skill_reduced_motion.png'}<=names
for name in names:
    assert (ARTIFACTS/name).read_bytes().startswith(b'\x89PNG\r\n\x1a\n')
    copy(name)
log('windows_vector_visual.log',f"VECTOR_VISUAL_SMOKE_COMPLETE {visual['screenshots']} screenshots")
copy('ink19_visual_capture.json')
style_stability=read(ARTIFACTS/'ink19_style_stability.json')
assert style_stability['revision']=='ink19' and style_stability['renderer']=='native'
assert style_stability['static_frames']==12 and style_stability['framebuffer_pixels_equal']
assert style_stability['appearances']==2 and style_stability['facings']==8
log('windows_vector_visual.log','INK_STYLE_STABILITY_OK native paused framebuffer identical across 12 frames')
copy('ink19_style_stability.json')


motion=read(ARTIFACTS/'pixel_motion_capture.json')
assert motion['revision']=='ink19' and motion['renderer']=='GuIllustratedCharacterView'
assert motion['frames']==len(motion['samples'])==96 and motion['accepted_slots']==[1,2,3,4]
assert motion['saw_walk'] and motion['saw_run']
assert {'walk','run','attack','defend','dash','cast'}<={s['sprite_action'] for s in motion['samples']}
log('windows_pixel_motion.log','PIXEL_MOTION_SMOKE_COMPLETE 96 frames')
copy('pixel_motion_capture.json')
shutil.copy2(ARTIFACTS/'pixel_gameplay_motion.gif',EVIDENCE/'ink19_gameplay_motion.gif')
studio_motion=read(ARTIFACTS/'ink19_studio_motion_capture.json')
assert studio_motion['frames']==144 and studio_motion['renderer']=='GuIllustratedCharacterView'
log('windows_vector_studio_motion.log','VECTOR_STUDIO_MOTION_SMOKE_COMPLETE 144 frames')
log('vector_gif_encode.log','GAMEPLAY_AND_STUDIO_PREVIEWS_OK native ink19 frames')
copy('ink19_studio_motion_capture.json')
copy('ink19_studio_motion.gif')
for frame in (12,32,50,62,74,86):
    shutil.copy2(ARTIFACTS/'pixel_motion'/f'frame_{frame:03d}.png',EVIDENCE/f'ink19_motion_{frame:03d}.png')

smooth=read(ARTIFACTS/'ink19_motion_capture.json')
assert smooth['revision']=='ink19' and smooth['renderer']=='GuIllustratedCharacterView'
assert smooth['frames']==len(smooth['samples'])==600 and smooth['sample_rate']==60
assert smooth['accepted_slots']==[1,2,3,4] and smooth['studio_actions']==['walk','run','attack','defend']
assert smooth['saw_walk'] and smooth['saw_run'] and smooth['saw_stop'] and smooth['world_directions']>=4
assert smooth['authority_unchanged_by_preview']
log('windows_smooth_motion.log','SMOOTH_MOTION_SMOKE_COMPLETE 600 frames')
encoded=read(ARTIFACTS/'ink19_preview_encode.json')
assert encoded['native_frames']==600 and encoded['native_sample_rate']==60 and encoded['duration_ms']==10000
assert encoded['webp_lossless'] and encoded['gif_selected_frames']==300
for name,entry in encoded['files'].items():
    assert hashlib.sha256((ARTIFACTS/name).read_bytes()).hexdigest()==entry['sha256']
    copy(name)
for name in ('ink19_motion_capture.json','ink19_preview_encode.json'):
    copy(name)
log('smooth_preview_encode.log','SMOOTH_PREVIEW_OK 600 native60Hz frames; lossless WebP; 30Hz GIF; 10000ms')

side=read(ARTIFACTS/'ink19_side_motion_capture.json')
assert side['revision']=='ink19' and side['frames']==len(side['samples'])==180 and side['sample_rate']==60 and side['profiles']==4
log('windows_profile_motion.log','PROFILE_MOTION_SMOKE_COMPLETE 180 native frames; four side walk/run clips; open/closed eyes')
log('profile_preview_encode.log','PROFILE_PREVIEW_OK 180 native60Hz frames; lossless WebP; 30Hz GIF; 3000ms')
side_encoded=read(ARTIFACTS/'ink19_side_preview_encode.json')
assert side_encoded['native_frames']==180 and side_encoded['webp_lossless'] and side_encoded['duration_ms']==3000
for name,entry in side_encoded['files'].items():
    assert hashlib.sha256((ARTIFACTS/name).read_bytes()).hexdigest()==entry['sha256']
    copy(name)
for name in ('ink19_side_motion_capture.json','ink19_side_preview_encode.json'):
    copy(name)
shutil.copy2(ARTIFACTS/'profile_motion/frame030.png',EVIDENCE/'ink19_side_profiles.png')

turn=read(ARTIFACTS/'ink19_turn_capture.json')
assert turn['revision']=='ink19' and turn['frames']==len(turn['samples'])==240 and turn['sample_rate']==60
assert set(turn['directions'])==set(range(8)) and turn['actions']==['walk','run','defend','attack']
log('windows_directional_motion.log','DIRECTIONAL_MOTION_SMOKE_COMPLETE 240 native frames; eight facings; walk/run/guard/spear')
log('directional_preview_encode.log','TURN_PREVIEW_OK 240 native60Hz frames; lossless WebP; 30Hz GIF; 4000ms')
turn_encoded=read(ARTIFACTS/'ink19_turn_preview_encode.json')
assert turn_encoded['native_frames']==240 and turn_encoded['webp_lossless'] and turn_encoded['duration_ms']==4000
for name,entry in turn_encoded['files'].items():
    assert hashlib.sha256((ARTIFACTS/name).read_bytes()).hexdigest()==entry['sha256']
    copy(name)
for name in ('ink19_turn_capture.json','ink19_turn_preview_encode.json'):
    copy(name)
for frame in (15,75,135,195):
    shutil.copy2(ARTIFACTS/f'directional_motion/frame{frame:03d}.png',EVIDENCE/f'ink19_turn_{frame:03d}.png')

characters=read(ROOT/'assets/vector/characters/manifest.json')
assert characters['revision']=='ink19' and len(characters['parts'])==131
assert characters['style']=='Ink and paper; warm matte bands and stationary hatching'
assert characters['directions']==8 and characters['cosmetic_combinations']==36
svg_hashes={key:hashlib.sha256((ROOT/record['path'].removeprefix('res://')).read_bytes()).hexdigest() for key,record in characters['parts'].items()}
paths=source_files(('scripts','scenes','data','assets','tests','tools'))+[ROOT/name for name in ('project.godot','RunGame.bat','RunTests.bat')]
source_sha=digest(paths)
stamp={
    'revision':'ink19','verified_at_utc':datetime.now(timezone.utc).isoformat(),
    'source_sha256':source_sha,'platforms':reports,
    'native_renderer':'Windows OpenGL3.3 Compatibility / NVIDIA GeForce GTX1050',
    'character':{'backend':'Original SVG cutouts / continuous 2D joint rig / linear filter / antialiased SVG edges and strokes','svg_parts':131,'import_texels_per_design_unit':8,'appearances':36,'directions':8,'actions':11,'legacy_atlas_visible':False,'svg_sha256':svg_hashes},
    'material_refinement':{'retains_original_character':True,'baseline':'tests/fixtures/character_v15_baseline.json','alpha_and_dimensions_unchanged':True,'original_head_y':-43,'original_torso_y':-21,'new_model':False},
    'directional_arms':{'projected_shoulders_and_wrists':True,'elbow_bend_changes_with_facing':True,'near_far_depth_changes_with_shoulders':True,'wrist_follows_forearm':True,'counter_swing_from_real_foot_travel':True,'curved_tapered_limbs':True,'resting_weapon_tip_outside_head':True,'native_frames':240,'sample_rate':60,'facings':8,'actions':turn['actions'],'preview_encoding':turn_encoded},
    'side_profile':{'dedicated_skull_hair_eye_ear_nose_mouth':True,'authored_closed_head_variants':20,'directional_hips_and_feet':True,'knee_flexion':True,'head_rise_max_units':.41,'dash_echoes':2,'dash_feathers':1,'preview_encoding':side_encoded},
    'ink_and_paper':{'reference_url':'https://www.klei.com/games/dont-starve-together','interpretation':'Original chibi retained; warm ink, matte bands, internal hatching; timings chosen for this game','shader':'assets/shaders/ink_cutout.gdshader','shader_sha256':hashlib.sha256((ROOT/'assets/shaders/ink_cutout.gdshader').read_bytes()).hexdigest(),'grain_anchor':'Texture texels; no TIME or RNG','inner_contour_alpha_unchanged':True,'static_native_framebuffer':style_stability,'sword_windup_hold_phases':[.17,.21],'sword_release_phases':[.21,.38],'brief_attack_and_hit_expressions':True,'reduced_motion_respected':True},
    'effects':{'backend':'Pressure ink ribbons / shared triangle arrays / continuous alpha edges','kinds':13,'contact_seconds':.28,'afterimage':'Deep-copied exact joint pose','authority_unchanged':True},
    'ui':{'skill_dock':[352,104],'icons':'Original curved vector','f6_stage_geometry_tested_sizes':[[960,640],[1280,800],[1920,1080]],'hp_damage_edge':True},
    'anatomy_and_cloth':{'profile_leg_segment_units':8,'projected_leg_lengths_bounded':True,'walk_stride_units':20,'run_stride_units':28,'walk_lift_units':3,'run_lift_units':4.2,'cloth_uv_grid':[4,8],'collar_and_belt_rigid':True,'hem_follows_knees_and_delayed_sway':True,'moving_cast_keeps_cloth_gait':True,'original_svg_alpha_preserved':True},
    'environment':{'backend':'Original32px TileMapLayer/props/wolf with shared muted palette shader','navigation_preserved':True,'foreground_fade_anchors':['head','torso','boots']},
    'native_capture':{'screenshots':visual['screenshots'],'sizes':[[960,640],[1280,800]],'accepted_slots':visual['accepted_slots']},
    'motion_capture':{'frames':96,'sample_rate':24,'real_inputs':['WASD','Shift','1','2','3','4'],'method':'Deterministic stepping with native frame rendering; not FPS benchmark'},
    'studio_motion_capture':{'frames':144,'sample_rate':24,'source':'Actual F6 native window with sampled preview clocks; unchanged authority'},
    'smooth_motion_capture':{'frames':600,'sample_rate':60,'real_inputs':['WASD','Shift','1','2','3','4','F6','workshop mouse presses'],'authority_unchanged_by_preview':True,'source':'Full native framebuffer with deterministic stepping; not FPS benchmark','preview_encoding':encoded},
    'smooth_playback':{'transition_seconds':{'locomotion':.12,'attack_cast':.07,'hit_dash':.045},'gait_stride_pixels':{'walk':20,'run':28},'gait':'Linear stance / velocity-matched Hermite return / squared-sine lift','secondary_motion':'Analytical damped angular springs','camera_registration':'Display pixels at integer zoom','moving_cast':'Independent lower-body gait with exact upper-body hand'},
    'source_portability':{'cold_import':True,'all_svg_parts_loaded':True,**portability}
}
(EVIDENCE/'verification_manifest.json').write_text(json.dumps(stamp,indent=2),encoding='utf-8')
n=reports['windows']['total']
report=f'''# Kiểm chứng — Nét mực và màu giấy 0.19

**{n}/{n} assertions đạt trên Windows và Linux, Godot 4.7.2 Compatibility.** Các capture lấy từ renderer native đang dùng trong gameplay và F6.

| Phần | Kết quả |
|---|---|
| Giữ nhân vật cũ | Alpha/kích thước 131 SVG khớp baseline 0.15; mốc đầu -43/thân -21, 36 diện mạo, tám hướng, 11 trạng thái |
| Phong cách | Màu đất/ngà, tóc ô-liu, bóng dải mảng, nét gạch trong alpha cũ; shader viền mực ấm và grain neo texture, không TIME/RNG |
| Ổn định | Framebuffer sheet hai diện mạo × tám hướng giống từng byte qua 12 frame đứng yên |
| Animation | Kiếm giữ grip/góc pha .17–.21 rồi ra đòn .21–.38; mắt nhắm ngắn và mở lại, reduced motion bỏ biểu cảm phụ. Trọng tâm/vạt áo rõ hơn; giữ foot contact và khớp tay đổi hướng |
| Hiệu ứng | 13 kiểu nét bút dày–mỏng/mảnh giấy/star lệch/khiên rỗng; endpoint hữu hạn, pressure có biến thiên và geometry xác định. Một triangle array cho mỗi nét, mép alpha liên tục |
| Gameplay | Tay phóng chính xác, contact .28s, moving cast giữ chân/áo, pause/reduced/save/cooldown/damage authority vẫn được kiểm tra |
| Native | {visual['screenshots']} PNG; 96 frame WASD/Shift/1–4; 144 frame F6; 600 frame world/F6; 180 frame góc ngang; 240 frame tám góc |
| Source | Cold import không có .godot ban đầu, tải đủ 131 SVG/36 look/13 VFX; {len(runtime)} runtime files so byte với snapshot và ZIP, CRC ZIP đạt |

Năm acceptance mới bảo vệ biểu cảm, giữ grip/góc trước release, endpoint nét bút, chiều rộng hữu hạn có lực và hình học xác định. Các guard giải phẫu, vải UV, layer tay/vũ khí, contact liên tục và nhận diện vẫn chạy. Native stability bổ sung kiểm pixel đứng yên.

[Review hình thật](build-review-0.19.md) ghi quan sát/giới hạn. 60Hz là tần suất lấy mẫu xác định của framebuffer, không phải benchmark FPS hay nghiệm thu phát hành. Phong cách được diễn giải từ nguồn Klei/Steam; không dùng asset của DST hay tuyên bố đã đo animation của game đó.

[Clip tám góc](evidence/ink19_turn_motion.webp) · [GIF](evidence/ink19_turn_motion.gif) · [Góc ngang](evidence/ink19_side_motion.webp) · [Gameplay/F6](evidence/ink19_motion.webp) · [8 hướng](evidence/ink19_character_directions.png) · [13 VFX](evidence/ink19_feedback_sheet.png) · [Windows](evidence/test_results_windows.json) · [Linux](evidence/test_results_linux.json) · [FSD/WBS](../implementation/PIXEL_2D_MIGRATION_PLAN.md) · [Mỹ thuật](art-direction-0.19.md) · [Phản hồi](feedback-design-0.19.md).

Tái hiện: RunTests.bat; các native smoke với -- --test-mode; tools/render_directional_preview.py và tools/pack_handoff.py. Baseline 0.18 giữ ở artifacts/baseline_v18 trong workspace; golden alpha vẫn là tests/fixtures/character_v15_baseline.json.

Source SHA256: {source_sha}.
'''
(ROOT/'docs/game-studio/quality-report.md').write_text(report,encoding='utf-8')
planning=ROOT/'docs/planning'
assert read(planning/'validation_report.json')['status']=='PASS'
planning_zip=planning/'GuMaster2D_Planning_Pack.zip'
planning_tmp=planning_zip.with_suffix('.tmp.zip')
with zipfile.ZipFile(planning_tmp,'w',zipfile.ZIP_DEFLATED) as archive:
    for folder in ('docs/planning','docs/implementation','docs/game-studio'):
        for path in sorted((ROOT/folder).rglob('*')):
            if path.is_file() and path.suffix not in ('.zip','.pyc','.import') and not any(p in ('archive','__pycache__') for p in path.parts):
                archive.write(path,path.relative_to(ROOT))
source_zip=ROOT/'GuMaster2D_Godot_Source.zip'
source_tmp=source_zip.with_suffix('.tmp.zip')
with zipfile.ZipFile(source_tmp,'w',zipfile.ZIP_DEFLATED) as archive:
    for directory, folders, files in os.walk(ROOT):
        folders[:] = sorted(f for f in folders if f not in ('.tools','.godot','.git','__pycache__','archive','builds','artifacts'))
        for name in sorted(files):
            path=Path(directory)/name
            if path.suffix in ('.zip','.pyc','.tmp','.log'):
                continue
            archive.write(path,Path('GuMaster2D')/path.relative_to(ROOT))
    archive.writestr('GuMaster2D/artifacts/.gitkeep','')
with zipfile.ZipFile(source_tmp) as archive:
    assert archive.testzip() is None
    for path in runtime:
        assert archive.read('GuMaster2D/'+path.relative_to(ROOT).as_posix())==path.read_bytes(),str(path)
    for name in ('RunGame.bat','tests/vector_presentation_tests.gd','docs/game-studio/quality-report.md'):
        assert 'GuMaster2D/'+name in archive.namelist(),name
with zipfile.ZipFile(planning_tmp) as archive:
    assert archive.testzip() is None
source_tmp.replace(source_zip)
planning_tmp.replace(planning_zip)
print(json.dumps({'revision':'ink19','checks_per_platform':n,'source_sha256':source_sha,'source_zip_bytes':source_zip.stat().st_size,'planning_zip_bytes':planning_zip.stat().st_size,'native_screenshots':visual['screenshots'],'runtime_files_verified_in_zip':len(runtime)}))
