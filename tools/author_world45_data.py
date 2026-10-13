"""Extend all three authored regions while preserving pre-0.45 IDs and coordinates.
This script only writes world_content.json; quests, bestiary and saves stay owned
by their own catalogs. Re-running it replaces the explicitly versioned additions.
"""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / 'data/world_content.json'
CAMP_CELLS = [(114,24),(164,26),(212,24),(236,62),(116,78),(162,78),(206,106),(236,130),(26,124),(70,134),(118,132),(160,150),(28,202),(84,218),(148,220),(222,224)]
STOPS = [(110,52),(185,50),(225,92),(212,168),(182,212),(114,190),(56,182),(30,108)]
REGIONS = {
 'forest': {
  'names':['Trúc Hải','Đèo Hắc Nha','Lâm Tuyền','Tổ Kim Châm','Hẻm Ti Nhện','Rừng Tùng Cổ','Dốc Huyết Mao','Đầm Mù Sương','Thung Lũng Bầy Sói','Cốc Mật Ngọt','Bãi Linh Dược','Khe Đá Trắng','Rừng Sương Nam','Cồn Trúc Gió','Đỉnh Vọng Lôi','Hang Lôi Lang'],
  'species':['wolf','boar','wolf','hornet','spider','boar','boar','toad','wolf','hornet','spider','beetle','wolf','hornet','lightning_wolf','lightning_wolf'],
  'stops':['Trạm Trúc Hải','Trạm Lâm Tuyền','Trạm Đông Lĩnh','Trạm Đầm Sương','Trạm Vọng Lôi','Trạm Nam Lâm','Trạm Cồn Trúc','Trạm Nam Khê'],
  'districts':['Trại và lâm địa cũ','Trúc Hải Đông Lĩnh','Nam Khê','Đầm Sương','Nam Lâm','Lôi Lĩnh'],
  'subtitle':'Trại tông tộc • trúc hải • nam lâm • lôi lĩnh',
  'materials':['herb','nectar','fruit'],
  'waterways':[{'kind':'river','axis':'y','start':98,'end':251,'center':95,'amplitude':10,'frequency':.035,'width':3.2},{'kind':'river','axis':'x','start':104,'end':250,'center':178,'amplitude':9,'frequency':.035,'width':3},{'kind':'pond','center':[212,62],'radii':[16,13]},{'kind':'pond','center':[55,226],'radii':[13,9]}]},
 'ruins': {
  'names':['Mỏ Huyền Thạch','Thạch Trụ Bắc','Cổng Thiên Văn','Hành Lang Bạch Cốt','Tàn Điện Tơ','Hố Độc Cổ','Tàng Kinh Đài','Mỏ Tinh Thạch','Bãi Chiến Trường','Điện Hỏa Tàn','Sân Cổ Ấn','Khe Nguyên Tinh','Huyết Thạch Lộ','Phế Đô Nam','Thủ Vệ Ngoại Điện','Đại Điện Tam Vương'],
  'species':['beetle','beetle','spider','boar','spider','toad','beetle','beetle','boar','hornet','beetle','toad','spider','beetle','guardian','guardian'],
  'stops':['Trạm Huyền Thạch','Trạm Thiên Văn','Trạm Đông Điện','Trạm Tàng Kinh','Trạm Tam Vương','Trạm Nam Đô','Trạm Hỏa Tàn','Trạm Cựu Chiến'],
  'districts':['Tiền điện cũ','Bắc Địa Thạch Trụ','Cựu Chiến Trường','Tàng Kinh Ngoại Vi','Phế Đô','Tam Vương Nội Điện'],
  'subtitle':'Tiền điện • thạch trụ • phế đô • nội điện',
  'materials':['ore','stone','herb'],
  'waterways':[{'kind':'river','axis':'y','start':99,'end':251,'center':94,'amplitude':8,'frequency':.04,'width':2.8},{'kind':'river','axis':'x','start':100,'end':251,'center':180,'amplitude':7,'frequency':.028,'width':3.6},{'kind':'pond','center':[182,104],'radii':[14,17]},{'kind':'pond','center':[46,160],'radii':[16,8]}]},
 'realm': {
  'names':['Vườn Linh Hoa Đông','Bãi Linh Thú Bắc','Hoa Hải','Hồ Bích Thiềm','Rừng Cổ Tằm','Bờ Thanh Ngọc','Đồi Linh Quả','Đầm Độc Diệp','Rừng Phúc Mộc','Cốc Ngọc Mật','Bãi Linh Dược Nam','Mạch Địa Tinh','Bờ Nam Liên Trì','Rừng Bách Hoa','Mắt Trận Đông Nam','Nguồn Thanh Nang'],
  'species':['hornet','boar','hornet','toad','spider','toad','boar','spider','boar','hornet','toad','beetle','toad','hornet','guardian','guardian'],
  'stops':['Trạm Đông Vườn','Trạm Hoa Hải','Trạm Bích Hồ','Trạm Linh Quả','Trạm Thanh Nang','Trạm Nam Dược','Trạm Liên Trì','Trạm Phúc Mộc'],
  'districts':['Linh điền và khu hoang cũ','Hoa Hải','Phúc Mộc','Bích Hồ Linh Quả','Liên Trì','Nguồn Linh Mạch'],
  'subtitle':'Linh điền • hoa hải • liên trì • nguồn linh mạch',
  'materials':['herb','fruit','nectar'],
  'waterways':[{'kind':'river','axis':'y','start':98,'end':251,'center':94,'amplitude':10,'frequency':.038,'width':3.4},{'kind':'river','axis':'x','start':102,'end':251,'center':181,'amplitude':11,'frequency':.03,'width':3.3},{'kind':'pond','center':[202,65],'radii':[19,15]},{'kind':'pond','center':[48,223],'radii':[18,13]}]}
}
RECTS = [[1,1,94,94],[96,1,159,95],[1,96,95,80],[96,96,159,80],[1,176,119,79],[120,176,135,79]]
LOOT = {'wolf':'meat','boar':'hide','spider':'silk','hornet':'nectar','toad':'venom','beetle':'ore','lightning_wolf':'fang','guardian':'essence'}
TIPS = {'wolf':'Sói phối hợp cận chiến; giữ khoảng trống để lùi.','boar':'Dụ hướng lao rồi né ngang; tránh kéo cả bầy.','spider':'Giữ chân ngoài vùng phun độc và tách từng con.','hornet':'Ong cơ động; dùng khiên trước khi áp sát.','toad':'Nhìn dấu báo trên đất, đổi vị trí trước khi độc rơi.','beetle':'Giáp trùng chậm và nặng; phản công sau khi nó lao.','lightning_wolf':'Đầu lĩnh ở vùng xa; ghi dấu trạm trước khi giao chiến.','guardian':'Thủ vệ giữ nguồn tài nguyên; rời ấn nổ rồi mới phản công.'}
MATERIAL_NAMES = {'herb':'Dược thảo','nectar':'Cụm linh hoa','fruit':'Bụi linh quả','ore':'Mạch khoáng','stone':'Nguyên thạch thô'}
data = json.loads(PATH.read_text())
data['version'] = 2
data['size'] = 256
for rid, spec in REGIONS.items():
 region = data['regions'][rid]
 # Authored road baseline is retained verbatim on the first run.
 old_roads = region.get('legacy_roads', region['roads'])
 region['legacy_roads'] = old_roads
 region['roads'] = list(old_roads)
 for category in ('camps','waypoints','resources'):
  region[category] = [item for item in region[category] if not item['id'].startswith('w45_')]
 region['subtitle'] = spec['subtitle']
 region['districts'] = [dict(id=f'{rid}_district_{i}',name=name,bounds=bounds) for i,(name,bounds) in enumerate(zip(spec['districts'],RECTS))]
 region['waterways'] = spec['waterways']
 region['roads'].append([[78,66],list(STOPS[0])])
 region['roads'].append([[28,72],list(STOPS[-1])])
 region['roads'].append([list(p) for p in STOPS] + [list(STOPS[0])])
 region['roads'].append([list(STOPS[0]),[126,116],list(STOPS[5])])
 region['roads'].append([list(STOPS[6]),[126,116],list(STOPS[2])])
 for index,(name,coord) in enumerate(zip(spec['stops'],STOPS)):
  region['waypoints'].append(dict(id=f'w45_{rid}_gate_{index:02}',name=name,cell=list(coord),region=rid,kind='waypoint'))
 for index,(name,coord,species) in enumerate(zip(spec['names'],CAMP_CELLS,spec['species'])):
  cid=f'w45_{rid}_camp_{index:02}'
  elite=species in ('guardian','lightning_wolf')
  region['camps'].append(dict(id=cid,name=name,cell=list(coord),species=species,count=1 if elite else 6,resource=LOOT[species],description=TIPS[species],region=rid,radius=6))
  closest = sorted(STOPS,key=lambda p:(p[0]-coord[0])**2+(p[1]-coord[1])**2)[:2]
  # Camps sit on loops, with more than one approach and a clear route back.
  for stop in closest: region['roads'].append([list(stop),list(coord)])
  for j,(dx,dy) in enumerate([(-5,3),(4,-4),(5,3)]):
   kind=spec['materials'][(index+j)%3]
   region['resources'].append(dict(id=f'{cid}_node{j}',name=MATERIAL_NAMES[kind],region=rid,cell=[coord[0]+dx,coord[1]+dy],material=kind,yield_count=2,respawn=75,kind='resource'))
PATH.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({r:{k:len(v[k]) for k in ('camps','waypoints','resources','districts')} for r,v in data['regions'].items()}))
