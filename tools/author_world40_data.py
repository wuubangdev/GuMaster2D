"""Authored content tables for the three-region expansion; no bitmap processing."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
def write(name,data): (root/'data'/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
beasts={
'wolf':dict(name='Sói rừng',shape='wolf',hp=160,speed=1.7,damage=14,style='melee',range=1.15,windup=.7,recovery=1.5,respawn=30,level=2,color='869c73',loot={'meat':2,'seal':1},xp=40,silver=14,gu='GU-01'),
'boar':dict(name='Hắc mao trư',shape='boar',hp=210,speed=1.2,damage=22,style='charge',range=3.2,windup=1.1,recovery=2.2,respawn=38,level=3,color='8e7357',loot={'hide':2,'meat':2},xp=48,silver=17,gu='GU-07'),
'spider':dict(name='Độc ti nhện',shape='spider',hp=145,speed=1.65,damage=18,style='spit',range=3.7,windup=1.0,recovery=2.0,respawn=34,level=3,color='7f6a88',loot={'venom':1,'silk':1},xp=42,silver=16,gu='GU-07'),
'hornet':dict(name='Kim châm phong',shape='hornet',hp=125,speed=2.2,damage=12,style='melee',range=1.2,windup=.55,recovery=1.2,respawn=28,level=2,color='b59c53',loot={'nectar':2,'pollen':1},xp=36,silver=12,gu='GU-05'),
'toad':dict(name='Đầm độc thiềm',shape='toad',hp=240,speed=.95,damage=24,style='spit',range=4.0,windup=1.25,recovery=2.4,respawn=40,level=4,color='719b85',loot={'venom':2,'herb':2},xp=55,silver=20,gu='GU-07'),
'beetle':dict(name='Thạch giáp trùng',shape='beetle',hp=290,speed=1.0,damage=24,style='charge',range=3.0,windup=1.2,recovery=2.5,respawn=45,level=5,color='93896e',loot={'ore':2,'stone':2,'relic':1},xp=65,silver=24,gu='GU-07'),
'lightning_wolf':dict(name='Bách thú vương • Điện lang',shape='wolf',hp=620,speed=2.0,damage=38,style='charge',range=4.2,windup=1.25,recovery=2.2,respawn=120,level=7,color='b4c6b6',loot={'fang':3,'essence':3,'stone':5,'meat':4},xp=180,silver=70,gu='GU-01',elite=True),
'guardian':dict(name='Thủ vệ truyền thừa',shape='beetle',hp=780,speed=1.15,damage=42,style='spit',range=4.5,windup=1.5,recovery=2.6,respawn=150,level=9,color='94a8a0',loot={'relic':3,'essence':4,'ore':4,'silk':2},xp=220,silver=90,gu='GU-03',elite=True),
}
# Use actual equipped catalog IDs for species-specific capture rewards.
slot_ids=['GU-01','GU-03','GU-05','GU-07']
write('bestiary.json',{'version':1,'species':beasts})
regions={
'forest':{'name':'Thanh Mao Sơn','subtitle':'Trại tông tộc • rừng trúc • lang triều','reward':'Thịt, da thú, mật hoa, tơ độc và nanh điện lang','biome':'bamboo','camps':[
('f_bamboo','Rừng trúc đông',[38,20],'wolf',6,'meat','Bãi nhập môn; sói cận chiến, khoảng trống rộng.'),
('f_boars','Dốc Hắc Mao',[62,16],'boar',6,'hide','Quan sát hướng lao rồi né sang bên.'),
('f_spiders','Đầm Tơ Độc',[77,39],'spider',6,'venom','Vùng phun độc báo trên đất; liên tục đổi vị trí.'),
('f_honey','Mật Lâm',[54,55],'hornet',6,'nectar','Ong nhanh, ít máu; nguồn mật và phấn hoa.'),
('f_wolves','Khe Lang',[28,72],'wolf',6,'meat','Bãi sói cách xa trại, thích hợp luyện Cổ.'),
('f_thunder','Đỉnh Lôi Lang',[78,77],'lightning_wolf',1,'fang','Đầu lĩnh; chuẩn bị khiên, lướt và dược liệu.')],
'waypoints':[('f_east','Trạm Trúc Đông',[32,32]),('f_south','Trạm Mật Lâm',[52,67]),('f_peak','Trạm Lôi Sơn',[78,66])],
'roads':[[[12,20],[26,20],[38,20],[62,16]],[[26,20],[32,32],[54,39],[77,39]],[[32,32],[32,52],[28,72]],[[54,39],[54,55],[52,67],[78,66],[78,77]],[[28,72],[52,67]],[[77,39],[78,66]]]},
'ruins':{'name':'Tam Vương Cổ Địa','subtitle':'Di tích truyền thừa • mỏ thạch • độc đàm','reward':'Nguyên thạch, khoáng thạch, tàn quyển và cổ tinh','biome':'ruins','camps':[
('r_mine','Mỏ Nguyên Thạch',[38,18],'beetle',6,'ore','Giáp dày, đòn lao chậm; nguyên liệu luyện Cổ.'),
('r_marsh','Độc Đàm',[67,22],'toad',6,'venom','Phun vào điểm đã ngắm; né ra khỏi vòng báo.'),
('r_silk','Hành Lang Tơ',[78,49],'spider',6,'silk','Nhiều tơ linh, tránh kéo cả đàn.'),
('r_sentinels','Sân Thạch Điện',[49,60],'beetle',6,'relic','Thu tàn quyển từ giáp trùng canh giữ.'),
('r_ash','Bãi Tro Tàn',[27,78],'boar',6,'hide','Da thú và thịt; dùng cột đá chia đàn.'),
('r_guardian','Điện Truyền Thừa',[77,79],'guardian',1,'essence','Thủ vệ dùng đòn nổ báo trước, phần thưởng hiếm.')],
'waypoints':[('r_mine_gate','Trạm Mỏ Cũ',[32,32]),('r_court','Trạm Thạch Điện',[44,48]),('r_depth','Trạm Điện Sâu',[69,69])],
'roads':[[[12,20],[25,20],[38,18],[67,22]],[[25,20],[32,32],[44,48],[49,60],[27,78]],[[44,48],[78,49]],[[49,60],[69,69],[77,79]],[[67,22],[78,49],[69,69]]]},
'realm':{'name':'Thanh Nang Phúc Địa','subtitle':'Điền viên • hồ sen • hoang địa linh mạch','reward':'Cây trồng, chăn nuôi, phấn hoa và nguyên liệu vùng hoang','biome':'wetland','camps':[
('b_flowers','Cốc Linh Hoa',[43,23],'hornet',6,'pollen','Hoa mọc trên linh mạch; ong giữ phấn hoa.'),
('b_marsh','Hồ Thanh Thiềm',[72,37],'toad',6,'herb','Dược liệu và độc nang ven hồ.'),
('b_beasts','Rừng Linh Thú',[48,70],'boar',6,'hide','Nguyên liệu để duy trì vòng nuôi Cổ.'),
('b_core','Trận Nhãn Ô Nhiễm',[78,77],'guardian',1,'essence','Dẹp thủ vệ để khơi lại nước tưới linh điền.')],
'waypoints':[('b_garden','Trạm Linh Hoa',[33,34]),('b_lake','Trạm Hồ Sen',[65,48]),('b_core_gate','Trạm Trận Nhãn',[68,68])],
'roads':[[[12,20],[25,20],[43,23]],[[25,20],[33,34],[48,48],[65,48],[72,37]],[[48,48],[48,70],[68,68],[78,77]],[[65,48],[68,68]]]},
}
for rid,r in regions.items():
 r['camps']=[dict(id=c[0],name=c[1],cell=c[2],species=c[3],count=c[4],resource=c[5],description=c[6],region=rid,radius=6) for c in r['camps']]
 r['waypoints']=[dict(id=c[0],name=c[1],cell=c[2],region=rid,kind='waypoint') for c in r['waypoints']]
 r['resources']=[]
 for i,c in enumerate(r['camps']):
  for j,(dx,dy) in enumerate([(-5,3),(4,-4)]):
   kind={'forest':['herb','nectar','fruit'],'ruins':['ore','stone','herb'],'realm':['herb','fruit','nectar']}[rid][i%3]
   r['resources'].append(dict(id=c['id']+'_node'+str(j),name={'herb':'Dược thảo','nectar':'Cụm linh hoa','fruit':'Bụi linh quả','ore':'Mạch khoáng','stone':'Nguyên thạch thô'}[kind],region=rid,cell=[c['cell'][0]+dx,c['cell'][1]+dy],material=kind,yield_count=2,respawn=75,kind='resource'))
write('world_content.json',{'version':1,'size':96,'regions':regions})
p=root/'data/quest_catalog.json';q=json.loads(p.read_text())
# Idempotent authoring: preserve only the shipped six quests and four NPCs.
q['quests']=q['quests'][:6];q['npcs']={k:v for k,v in q['npcs'].items() if k in ['lam_an','yen_chi','tham_nghi','moc_mien']}
for i,quest in enumerate(q['quests']):quest['category']='side' if quest['id'] in ['first_feed','silk_and_gu'] else 'main';quest['chapter']=1 if i<3 else 2
new_npcs=[
('trac_su','Trác Sơn','Thợ săn của trại','forest',[35,33],'male','jade','sect','Lợi ích của trại nằm trong từng bao lương thực. Sói chiếm đường, lợn phá rẫy, còn điện lang trên đỉnh khiến cả đàn bất an. Ta trả công cho kết quả, không trả công cho lời hứa.',[
('Bãi nào hợp sức của tôi?','Rừng trúc phía đông có sói thường; dốc phía đông bắc có lợn lao thẳng. Điện lang ở tận đông nam là đầu lĩnh. Dùng T xem đường, tài nguyên và điểm dừng trước khi đi.'),
('Vì sao lang triều kéo xuống?','Khi con đầu đàn đổi nơi săn, cả núi chuyển động. Nhưng lần này có vết cổ trận dưới móng chúng. Hạ điện lang rồi đem dấu vết cho Thẩm Nghi; có lẽ cơn đói không phải nguyên nhân duy nhất.')]),
('hac_thuong','Hạc Thương','Chấp sự thương đội','ruins',[41,44],'male','crimson','bamboo','Một tàn quyển không nuôi nổi ai, cho đến khi có người hiểu công thức trong đó. Ta thu khoáng, đổi vật tư và giữ đường rút. Cậu chọn học truyền thừa hay bán chiến lợi phẩm đều được.',[
('Lấy tàn quyển ở đâu?','Giáp trùng ở Mỏ Nguyên Thạch và Sân Thạch Điện giữ mảnh đá khắc chữ. Chúng chậm nhưng giáp dày. Trước khi trả nhiệm vụ giao vật liệu, kiểm tra số sẽ tiêu hao trong nhật ký.'),
('Phúc địa có phải tự tạo ra?','Cổ sư ở đây chỉ mở lại cửa một phúc địa bỏ hoang. Đó là di sản cần nuôi dưỡng, không phải tu vi tiên nhân tự nhiên xuất hiện. Thu hoạch rồi phải gieo lại; rút cạn linh mạch thì cửa cũng tắt.')]),
('linh_nha','Linh Nha','Người giữ linh mạch','realm',[47,48],'female','ivory','none','Ruộng gần cửa vẫn được giữ yên, nhưng vùng hoang đã đổi khác. Nước đi qua trận nhãn mang theo khí đục. Muốn giữ mùa vụ, trước hết phải biết dòng nước đến từ đâu.',[
('Vùng nào còn an toàn?','Khu điền viên quanh cửa và các trạm dừng là vùng an toàn. Qua rừng hoa, hồ sâu và trận nhãn, linh thú vẫn tấn công. Đừng dẫn chúng về ruộng; chúng sẽ quay lại bãi khi chạm ranh giới bảo hộ.'),
('Vì sao cần chăm phúc địa?','Mỗi loại cây và thú lấy một phần linh khí rồi trả lại tài nguyên khác. Ta có thể khơi mương tưới cho cả ruộng khi trận nhãn được thanh lọc. Đó là phần thưởng bền hơn một rương bạc.')])]
for id,name,role,reg,cell,body,outfit,hat,greeting,topics in new_npcs:
 q['npcs'][id]=dict(name=name,role=role,region=reg,cell=cell,facing=[0,1],appearance=dict(body=body,outfit=outfit,weapon='unarmed',hair='topknot',boots='cloth',hat=hat),greeting=greeting,farewell='Giữ lại đường trở về.',topics=[dict(label=a,text=b) for a,b in topics])
def quest(id,title,cat,giver,req,metric,target,goal,desc,offer,complete,reward,unlocks=None,delivery=None):
 d=dict(id=id,title=title,category=cat,chapter=3 if giver=='linh_nha' or id=='flower_keeper' else (2 if giver in ['tham_nghi','hac_thuong'] else 1),giver=giver,turn_in=giver,requires=req,description=desc,objective=desc.split('. ')[0],metric=metric,target=target,goal=goal,destination=giver,offer=offer,complete=complete,reward=reward)
 if unlocks:d['unlocks']=unlocks
 if delivery:d['delivery']=delivery
 q['quests'].append(d)
quest('bamboo_chart','Đường qua rừng trúc','main','lam_an',['arrival'],'discover','f_bamboo',1,'Khám phá Rừng trúc đông. Theo lối ra phía đông trại, dùng T để xem địa đồ và dẫn đường.','Tông tộc không nuôi Cổ bằng danh tiếng. Muốn đi xa, con cần biết nơi có tài nguyên và nơi có thể trở về. Hãy ghi lại bãi rừng trúc phía đông.','Con đã nhìn xa hơn hàng rào. Ta giao quyền dùng các trạm cổ trận nội vùng; trước tiên phải đến trạm để ghi nhận dấu ấn.',{'silver':50,'xp':35,'herb':3},['waygates'])
quest('storm_tracks','Dấu chân trong lang triều','main','trac_su',['path_guard','bamboo_chart'],'camp_kills','f_thunder',1,'Hạ Điện lang tại Đỉnh Lôi Lang. Đầu lĩnh báo hướng trước khi lao; né ngang, dùng khiên và lướt.','Ta cần biết thứ gì đang đẩy đàn sói xuống trại. Con điện lang ở đỉnh đông nam mang một ấn lạ. Chuẩn bị Cổ rồi mới lên núi.','Dấu này giống chữ trên cổ địa. Thẩm Nghi sẽ muốn xem nó. Cầm tài nguyên mà luyện lại Cổ trước khi đi.',{'silver':130,'xp':150,'stone':8,'herb':8,'essence':3})
quest('boar_supply','Lương thực của thương đội','side','trac_su',['arrival'],'deliver','f_boars',4,'Giao 4 da thú từ Dốc Hắc Mao. Da thú sẽ bị tiêu hao khi trả nhiệm vụ.','Đường hàng thiếu người bảo vệ. Ta cần bốn tấm da lành để bọc vật tư; thịt săn được con cứ giữ lại nuôi Cổ.','Thương đội có thể đi tiếp. Phần này là của con — một cuộc đổi chác sòng phẳng.',{'silver':85,'xp':50,'herb_seed':3,'seal':4},delivery={'hide':4})
quest('honey_trade','Bữa ăn cho Cổ trùng','side','yen_chi',['first_feed'],'deliver','f_honey',6,'Giao 6 mật linh hoa từ Mật Lâm. Dùng ong hoặc cụm hoa để tìm mật; giữ lại phần Cổ đang cần.','Mỗi con Cổ có một cái giá để sống. Ta đổi hạt và thảo dược lấy sáu phần mật; đừng mang hết thức ăn của Cổ đến cho ta.','Nguồn thức ăn ổn định mới giúp Cổ sư đi xa. Trồng hạt này để lần sau không phải chỉ dựa vào săn bắt.',{'silver':60,'xp':40,'flower_seed':3,'herb':6},delivery={'nectar':6})
quest('broken_script','Tàn quyển dưới thạch giáp','main','tham_nghi',['storm_tracks'],'deliver','r_sentinels',3,'Giao 3 tàn quyển từ Sân Thạch Điện hoặc Mỏ Nguyên Thạch. Tàn quyển sẽ được tiêu hao để giải ấn.','Dấu trên điện lang là một mảnh lệnh truyền thừa. Giáp trùng trong thạch điện giữ phần chữ còn lại. Đem ba mảnh về, ta sẽ chỉ ra cửa chính.','Những mảnh chữ nói về một thủ vệ giữ kho linh mạch. Qua được nó, con sẽ hiểu vì sao Thanh Nang suy yếu.',{'silver':110,'xp':100,'stone':6,'silk':4},delivery={'relic':3})
quest('king_guard','Giá của truyền thừa','main','tham_nghi',['broken_script'],'camp_kills','r_guardian',1,'Hạ thủ vệ tại Điện Truyền Thừa. Rời vòng báo đòn trước khi ấn nổ.','Người để lại truyền thừa không chọn người chỉ biết nhặt của. Hãy vượt thủ vệ ở điện đông nam. Giữ đủ chân nguyên cho đường rút.','Cửa kho đã mở. Nhưng tài nguyên lớn nhất nằm ở phúc địa mà nó từng cấp dưỡng. Tìm Linh Nha ở vùng hoang Thanh Nang.',{'silver':180,'xp':200,'essence':6,'silk':6,'herb':10})
quest('stone_contract','Nguyên thạch không miễn phí','side','hac_thuong',['path_guard'],'deliver','r_mine',6,'Giao 6 khoáng thạch từ Mỏ Nguyên Thạch. Mỗi giáp trùng hoặc mạch khoáng đều có thể cho nguyên liệu.','Nguyên thạch giữ chân nguyên cũng giữ giá trị của một lời hứa. Mang sáu phần quặng về, ta đổi thành vật liệu dùng ngay.','Khoáng đủ sạch. Ta trả đúng giá, và để dành vài hạt cho người biết nuôi nguồn lợi về sau.',{'silver':90,'xp':60,'stone':8,'fruit_seed':2},delivery={'ore':6})
quest('antidote','Dược phương đường xa','side','hac_thuong',['first_feed'],'deliver','r_marsh',4,'Giao 4 độc nang từ Độc Đàm hoặc nhện. Công thức nhận được dùng linh thảo và mật để hồi phục.','Một thứ độc có thể là đầu vào của một phương thuốc. Ta cần bốn độc nang làm mẫu; đổi lại, con sẽ có cách băng bó ngoài trại.','Công thức đã được kiểm. Ngoài giao chiến, nhấn R: hai linh thảo và một mật giúp hồi bốn phần mười sinh lực.',{'silver':55,'xp':50,'herb':8,'nectar':4},['field_medicine'],{'venom':4})
quest('living_valley','Linh mạch dưới rừng hoa','main','linh_nha',['king_guard','first_harvest'],'discover','b_flowers',1,'Khảo sát Cốc Linh Hoa. Tìm vùng rừng hoa phía đông khu điền viên để lần theo dòng linh khí.','Cậu đã mở kho của người trước; giờ hãy nhìn thứ giữ kho ấy sống. Rừng hoa phía đông là nơi linh khí bắt đầu đổi màu.','Khí đục đi ngược từ trận nhãn. Chúng ta đã biết nơi cần xử lý, không phải chặt sạch cả khu rừng.',{'silver':80,'xp':80,'fruit':6,'herb':6})
quest('seal_breach','Khơi lại dòng Thanh Nang','main','linh_nha',['living_valley'],'camp_kills','b_core',1,'Hạ thủ vệ ở Trận Nhãn Ô Nhiễm. Sau đó trở lại Linh Nha để khơi mương tưới toàn bộ ruộng.','Muốn mùa sau còn thu hoạch, phải trả lại nước sạch cho linh điền. Thủ vệ ở trận nhãn đang giữ khí đục; đừng để đòn ấn giữ chân cậu.','Linh mạch đã thông. Từ nay, mở H để tưới mọi luống đã gieo cùng một lần. Phúc địa sẽ nuôi Cổ sư biết chăm nó.',{'silver':200,'xp':220,'silk':8,'stone':10},['irrigation'])
quest('flower_keeper','Phấn hoa cho mùa sau','side','moc_mien',['first_harvest'],'deliver','b_flowers',4,'Giao 4 phấn linh hoa từ ong ở Cốc Linh Hoa hoặc Mật Lâm. Đây là nguyên liệu sẽ tiêu hao.','Ta giữ hạt, cậu giữ đường. Mang ít phấn hoa về để vườn có mùa tiếp theo; ong trong vùng hoang vẫn giữ những cụm hoa mạnh nhất.','Số phấn này đủ cho một vụ gieo. Nhận hạt và thức ăn, đừng để chuồng trống quá lâu.',{'silver':65,'xp':50,'flower_seed':3,'fruit':5},delivery={'pollen':4})
quest('beast_provision','Da thú đổi tơ linh','side','linh_nha',['living_valley'],'deliver','b_beasts',6,'Giao 6 da thú từ Rừng Linh Thú. Đổi vật tư vùng hoang lấy tơ để hợp thành Cổ.','Bờ mương cần vật liệu để giữ kín. Ta đổi tơ linh lấy da thú; phần thịt cậu giữ nuôi Cổ. Không tài nguyên nào tự xuất hiện mãi.','Đổi chác xong. Tơ này đủ cho một lần thử hợp Cổ; hãy xem công thức và Cổ phôi trước khi luyện.',{'silver':75,'xp':70,'silk':5,'meat':5},delivery={'hide':6})
write('quest_catalog.json',q)
print('Authored 3 regions, 16 camps, 8 species, 18 quests, 7 NPCs')
