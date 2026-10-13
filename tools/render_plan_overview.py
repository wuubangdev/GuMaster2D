"""Render the roadmap as a new static planning figure (Pillow, Windows fonts)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
image = Image.new("RGB", (1300, 790), "#F3F5EF")
draw = ImageDraw.Draw(image)

def font(size, bold=False):
    return ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf", size)

draw.rectangle((0, 0, 1300, 112), fill="#173B31")
draw.text((36, 23), "GuMaster2D  /  Godot PC", fill="#E7ECD4", font=font(36, True))
draw.text((38, 73), "Kế hoạch v0.2  •  07/10/2026  •  4 người tự phát triển, chưa có ngân sách", fill="#BED0BC", font=font(20))
for x, title, value in [(38,"NỀN TẢNG","Godot 4.7.2 / GDScript"),(370,"BẢN HIỆN TẠI","4 Cổ / 1 map / chơi đơn"),(710,"SPRINT TIẾP","11 việc / 100,8 giờ*"),(1035,"ALPHA DỰ KIẾN","36 tuần**")]:
    draw.text((x, 139), title, fill="#718175", font=font(14, True))
    draw.text((x, 169), value, fill="#244837", font=font(21, True))
draw.line((36, 217, 1263, 217), fill="#CFD8CC", width=2)
draw.text((38, 239), "Lộ trình alpha — gate online vẫn cần triển khai và kiểm chứng", fill="#244837", font=font(24, True))
left, width = 390, 825
for week in [1, 8, 12, 24, 30, 36]:
    x = left + (week-1)/36*width
    draw.text((x, 285), f"W{week}", fill="#6E8072", font=font(15))
phases = [(1,8,"Nền tảng / 2 client","G1", "#527866"),(9,12,"PvE / 5 Cổ","G2", "#649289"),(13,24,"Vòng Cổ / progression","G3", "#8B9E69"),(25,30,"Party / dungeon / duel","G4", "#B09D6A"),(31,36,"Hardening / closed alpha","G5", "#698A83")]
for i,(start,end,label,gate,color) in enumerate(phases):
    y = 321 + i*52
    draw.text((38,y+7),label,fill="#344D3E",font=font(20))
    draw.rectangle((left,y,left+width,y+36),fill="#E0E6DB")
    x0=left+(start-1)/36*width
    x1=left+end/36*width
    draw.rounded_rectangle((x0,y,x1,y+36),radius=4,fill=color)
    draw.text((x0+10,y+7),gate,fill="white",font=font(18,True))
draw.text((38,609),"Đã có: di chuyển, QWER, sói AI, bắt/nuôi Cổ, túi, khảo nghiệm, chết/hồi sinh, local save.",fill="#33533F",font=font(20))
draw.text((38,650),"Tiếp theo: headless server, protocol hai client, PostgreSQL feed transaction, thử Web export.",fill="#33533F",font=font(20))
draw.text((38,706),"* 84 giờ cơ sở +20% dự phòng; công suất giả định 120 giờ hữu ích / 2 tuần cho cả đội.",fill="#6C7A6D",font=font(17))
draw.text((38,738),"** Forecast cũ 199PD +20%; cần rebaseline sau Godot online/DB spike. Prototype chưa hoàn thành gate alpha.",fill="#6C7A6D",font=font(17))
image.save(ROOT / "docs/planning/plan_overview.png")
print("Roadmap rendered: docs/planning/plan_overview.png")
