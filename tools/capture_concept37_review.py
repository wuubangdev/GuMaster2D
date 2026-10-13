"""Serial native captures, with a stop on script errors or failed assertions."""
from pathlib import Path
import os, subprocess, time, json
ROOT=Path(__file__).resolve().parents[1]
log=ROOT/'artifacts/concept37_tests.log'
start=time.monotonic()
while True:
    text=log.read_text() if log.exists() else ''
    if 'FAIL:' in text or 'SCRIPT ERROR' in text or 'ERROR:' in text:
        raise SystemExit('Regression failed; native capture stopped.')
    if 'TEST_RESULTS 613/613 passed; 0 failed' in text: break
    if time.monotonic()-start>600: raise SystemExit('Regression did not complete in time.')
    time.sleep(1)
jobs=[('parts','concept_modular_parts_review.gd',[]),('detail_attack','concept_locomotion_detail.gd',['--combat-detail']),('detail_motion','concept_locomotion_detail.gd',[]),('combat','concept_combat_review.gd',[]),('actions','concept_action_frame_review.gd',[]),('native','concept_character_visual_smoke.gd',[]),('ui','ui_style_visual_smoke.gd',[])]
env=os.environ.copy();env['DISPLAY']=':0'
report=[]
for label,script,extra in jobs:
    target=ROOT/f'artifacts/concept37_{label}_capture.log'
    command=['bash','tools/run.sh','--audio-driver','Dummy']
    if label=='ui': command+=['--position','-1800,-1200']
    command+=['--script','res://tests/'+script,'--','--test-mode','--capture-prefix=concept37','--capture-offscreen']+extra
    begun=time.monotonic()
    with target.open('w') as output:
        process=subprocess.Popen(command,cwd=ROOT,env=env,stdout=output,stderr=subprocess.STDOUT)
        while process.poll() is None:
            errors=target.read_text()
            if 'SCRIPT ERROR' in errors or 'ERROR:' in errors or 'Assertion failed' in errors or time.monotonic()-begun>600:
                process.terminate();process.wait(timeout=10)
                raise SystemExit('Capture failed: '+label+'; inspect '+str(target))
            time.sleep(1)
    if process.returncode: raise SystemExit('Capture exited nonzero: '+label)
    report.append({'label':label,'script':script,'seconds':round(time.monotonic()-begun,2),'exit_code':process.returncode})
    print('Captured '+label,flush=True)
    if label=='ui':
        import shutil
        out=ROOT/'artifacts/concept37_ui';out.mkdir(exist_ok=True)
        for file in (ROOT/'artifacts').glob('ink20_ui_*.png'):
            shutil.copyfile(file,out/file.name.removeprefix('ink20_ui_'))
(ROOT/'artifacts/concept37_native_delivery.json').write_text(json.dumps({'passed':True,'jobs':report},indent=2))
