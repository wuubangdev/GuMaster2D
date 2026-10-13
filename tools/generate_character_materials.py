"""Original editable SVG material maps. Godot embeds their raster import in GLB exports."""
from pathlib import Path
import math

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/characters/textures'
OUT.mkdir(parents=True, exist_ok=True)

def svg(name, body):
    (OUT / name).write_text('<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">'+body+'</svg>')

weave = '<defs><linearGradient id="silk" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#f9f6ed"/><stop offset=".48" stop-color="#e0dfd5"/><stop offset="1" stop-color="#f9f6ed"/></linearGradient></defs><rect width="512" height="512" fill="url(#silk)"/>'
weave += ''.join(f'<path d="M0 {y}H512" stroke="#fffdfa" stroke-opacity=".5"/>' for y in range(1,512,4))
weave += ''.join(f'<path d="M{x} 0V512" stroke="#adaea7" stroke-opacity=".11"/>' for x in range(1,512,4))

for family in ('jade', 'crimson', 'ivory'):
    motifs = ''
    for y in range(-32, 600, 192):
        for x in range(-32, 600, 192):
            if family == 'jade':
                path = 'M0 24Q-29 12-20-10Q-12-30 0-27Q12-30 20-10Q29 12 0 24M0 24V-20M0 8Q-9-4-18-9M0 0Q9-8 17-15'
            elif family == 'crimson':
                path = 'M-27 13Q-7 15-9-4Q-9-24 7-20Q25-16 15 1Q7 12 0 4M-18 25Q-2 11 24 18M-18-17Q-3-31 22-25'
            else:
                path = 'M-26 20Q-16-8 0-20Q16-8 26 20M-18 20Q-8-2 0-12Q8-2 18 20M-8 20Q0 5 8 20M0-20V-29'
            # Broad satin brocade survives portrait minification. Fine weave
            # remains a separate scale; no fake geometric shadows are painted.
            motifs += f'<g transform="translate({x},{y}) scale(1.9)" fill="none" stroke="#899087" stroke-width="1.7" stroke-opacity=".3"><path d="{path}"/></g>'
            motifs += f'<g transform="translate({x+1},{y-1}) scale(1.9)" fill="none" stroke="#fffdf1" stroke-width=".65" stroke-opacity=".55"><path d="{path}"/></g>'
    svg(f'silk_{family}_albedo.svg', weave+motifs)
svg('silk_normal.svg', '<rect width="512" height="512" fill="#8080ff"/>'+''.join(f'<path d="M{x} 0V512" stroke="{color}" stroke-width="1"/>' for x in range(0,512,4) for color in ['#8d80fc'])+''.join(f'<path d="M0 {y}H512" stroke="#8076fc" stroke-width="1"/>' for y in range(2,512,8)))
leather = '<rect width="512" height="512" fill="#ded5c8"/>'
normal = '<rect width="512" height="512" fill="#8080ff"/>'
for i in range(1300):
    x, y = (i*73+19)%512, (i*137+43)%512
    r = .7+(i%4)*.25
    leather += f'<ellipse cx="{x}" cy="{y}" rx="{r*1.3:.1f}" ry="{r:.1f}" fill="#87786e" opacity=".19"/>'
    normal += f'<ellipse cx="{x}" cy="{y}" rx="{r*1.3:.1f}" ry="{r:.1f}" fill="#927afb"/>'
svg('leather_albedo.svg', leather)
svg('leather_normal.svg', normal)
hair = '<rect width="512" height="512" fill="#ddddd9"/>'
hair_normal = '<rect width="512" height="512" fill="#8080ff"/>'
for i in range(120):
    x = i*512/120
    wave = 2.0*math.sin(i*2.37)
    path = f'M{x:.2f} 0Q{x+wave:.2f} 128 {x:.2f} 256T{x:.2f} 512'
    hair += f'<path d="{path}" stroke="#717980" stroke-width="{.65+(i%3)*.2:.2f}" fill="none" opacity=".38"/>'
    hair_normal += f'<path d="{path}" stroke="#977ffe" stroke-width="1.2" fill="none"/>'
svg('hair_albedo.svg', hair)
svg('hair_normal.svg', hair_normal)
metal = '<rect width="512" height="512" fill="#ebeff1"/>'
for i in range(120):
    x=(i*23)%512
    metal += f'<path d="M{x} 0V512" stroke="#7f95a2" stroke-width=".7" opacity=".13"/>'
svg('metal_albedo.svg', metal)
svg('metal_normal.svg','<rect width="512" height="512" fill="#8080ff"/>'+''.join(f'<path d="M{x} 0V512" stroke="#897ffc" stroke-width=".6"/>' for x in range(0,512,6)))
skin = '''<defs>
<linearGradient id="skin" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#ddd0bf"/><stop offset=".30" stop-color="#f7eee1"/><stop offset=".70" stop-color="#f8eee3"/><stop offset="1" stop-color="#e6d6c8"/></linearGradient>
<radialGradient id="cheek"><stop stop-color="#cc8e85" stop-opacity=".23"/><stop offset="1" stop-color="#d99489" stop-opacity="0"/></radialGradient>
<radialGradient id="socket"><stop stop-color="#967f78" stop-opacity=".16"/><stop offset="1" stop-color="#967f78" stop-opacity="0"/></radialGradient>
</defs><rect width="512" height="512" fill="url(#skin)"/>
<ellipse cx="216" cy="186" rx="24" ry="27" fill="url(#cheek)"/><ellipse cx="296" cy="186" rx="24" ry="27" fill="url(#cheek)"/>
<ellipse cx="222" cy="250" rx="23" ry="12" fill="url(#socket)"/><ellipse cx="290" cy="250" rx="23" ry="12" fill="url(#socket)"/>'''
# Head's spherical UV increases from chin to crown, mapped from image top.
svg('skin_albedo.svg', skin)
print(f'Generated {len(list(OUT.glob("*.svg")))} editable material maps in {OUT}')
