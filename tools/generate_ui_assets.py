"""Original bronze frames, material icons and resource gauges. Standard-library only."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "assets" / "ui"
ROOT.mkdir(parents=True, exist_ok=True)
PALETTES = {
    "panel": ("#171e1d", "#282e26", "#9d845b", "#514a36"),
    "slot": ("#131c1c", "#28362e", "#8b7853", "#484a38"),
    "hover": ("#24372f", "#344c3c", "#d0b77c", "#7a714e"),
    "pressed": ("#101915", "#192920", "#ad995e", "#524b32"),
    "disabled": ("#181d1b", "#242b24", "#4e5140", "#383d31"),
}
for name, (body, top, edge, inner) in PALETTES.items():
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
<path d="M5 1H91L95 5V91L91 95H5L1 91V5Z" fill="#080e0d"/>
<path d="M7 3H89L93 7V89L89 93H7L3 89V7Z" fill="{body}" stroke="{edge}"/>
<path d="M8 8H88V18H8Z" fill="{top}"/>
<path d="M8 8H88V88H8Z" fill="none" stroke="{inner}"/>
<path d="M11 11H85V85H11Z" fill="none" stroke="#0c1412"/>
<g fill="none" stroke="{edge}" stroke-width="1">
<path d="M4 17V6H17M7 14V9H14M79 4H90V17M82 7H87V14M92 79V90H79M89 82V87H82M17 92H6V79M14 89H9V82"/>
</g><g fill="{edge}"><path d="M5 5H8V8H5ZM88 5H91V8H88ZM5 88H8V91H5ZM88 88H91V91H88Z"/></g>
</svg>'''
    (ROOT / f"frame_{name}.svg").write_text(svg, encoding="utf-8")
print(f"Generated {len(PALETTES)} UI frames")

ITEMS = {
    "seal": '<path d="M19 6H45V58H19Z" fill="#c8aa65" stroke="#76623e" stroke-width="2"/><path d="M25 17L39 43M39 17L25 43M24 29H40" stroke="#733e30" stroke-width="3"/><path d="M17 6H47M17 58H47" stroke="#e4cb89" stroke-width="4"/>',
    "meat": '<path d="M19 45L45 19" stroke="#ddd0a4" stroke-width="9"/><circle cx="47" cy="17" r="6" fill="#e9ddbb"/><ellipse cx="27" cy="37" rx="18" ry="13" transform="rotate(-40 27 37)" fill="#a5604e" stroke="#d69678" stroke-width="3"/><path d="M18 38Q25 23 36 29" fill="none" stroke="#e6b696" stroke-width="3"/>',
    "stone": '<path d="M32 5L55 28L42 58L12 46L8 25Z" fill="#64828b" stroke="#bbcbd0" stroke-width="2"/><path d="M32 5L34 31L42 58M8 25L34 31L55 28M12 46L34 31" fill="none" stroke="#a2c1c6" stroke-width="2"/>',
    "fruit": '<path d="M31 26Q26 7 45 5Q47 20 31 26Z" fill="#a7bf72"/><circle cx="23" cy="39" r="17" fill="#94a966" stroke="#c6d098" stroke-width="2"/><circle cx="43" cy="42" r="13" fill="#6b8150" stroke="#acbc7b" stroke-width="2"/><path d="M17 33Q21 26 26 29" fill="none" stroke="#d2d9a9" stroke-width="3"/>',
    "nectar": '<path d="M32 4Q20 24 13 36Q7 56 32 60Q57 56 51 36Q44 24 32 4Z" fill="#ad7e35" stroke="#e8c474" stroke-width="2"/><path d="M25 28Q17 39 23 47" fill="none" stroke="#f4d995" stroke-width="4"/>',
}
for name, paths in ITEMS.items():
    (ROOT / f"item_{name}.svg").write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">{paths}</svg>', encoding="utf-8")
for name, colors in {"hp": ("#c97561", "#a54137", "#642d2a"), "mana": ("#7abacf", "#34799e", "#244759")}.items():
    (ROOT / f"gauge_{name}.svg").write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="20"><defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="{colors[0]}"/><stop offset="0.3" stop-color="{colors[1]}"/><stop offset="1" stop-color="{colors[2]}"/></linearGradient></defs><rect x="1" y="1" width="62" height="18" fill="url(#g)"/><path d="M2 2H62" stroke="{colors[0]}"/></svg>', encoding="utf-8")
