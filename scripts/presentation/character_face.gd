class_name GuCharacterFace
extends RefCounted
## Continuous contoured face and fitted hair shells, with recessed almond eyes.
## Original authoring geometry; immutable baked meshes are used in the live game.

static func build(model: GuCharacterModel) -> void:
	var female := str(model.appearance["body"])=="female"
	_head(model,female)
	for side in [-1.0,1.0]:
		_eye(model,side,female)
		var width := .111 if female else .119
		model._ellipsoid("Head","skin",Vector3(side*width,-.013,.003),Vector3(.016,.033,.015),16,10)
		model._ellipsoid("Head","shadow_skin",Vector3(side*(width+.009),-.013,-.002),Vector3(.004,.021,.008),12,8)
		var brow: Array[Vector3] = []
		for sample in range(7):
			var x: float = side*(.022+sample*.008)
			var y := .050+.007*sin(float(sample)/6*PI)
			brow.append(Vector3(x,y,_front_z(x,y,female)-.0025))
		model._tube("Head","hair",brow,.0028 if female else .0037,8)
		var nostril_x: float = side*.014
		model._ellipsoid("Head","shadow_skin",Vector3(nostril_x,-.048,_front_z(nostril_x,-.048,female)-.002),Vector3(.0045,.002,.002),10,6)
	var upper: Array[Vector3] = []
	var lower: Array[Vector3] = []
	for sample in range(13):
		var x := (float(sample)/12*2-1)*(.024 if female else .027)
		var bow := exp(-pow((absf(x)-.008)/.005,2))*.003
		var top_y := -.085+bow
		var lower_y := -.090-sin(float(sample)/12*PI)*.002
		upper.append(Vector3(x,top_y,_front_z(x,top_y,female)-.002))
		lower.append(Vector3(x,lower_y,_front_z(x,lower_y,female)-.0028))
	model._tube("Head","lip",upper,.0019,8)
	model._tube("Head","lip",lower,.0024,8)
	_hair(model,female)

static func _profile(y: float, female: bool) -> Vector3:
	var rows := [Vector4(-.158,.025,.038,-.018),Vector4(-.135,.060,.064,-.012),Vector4(-.105,.083,.078,-.007),Vector4(-.070,.104,.090,.002),Vector4(-.028,.114,.102,.006),Vector4(.018,.115,.106,.008),Vector4(.067,.114,.108,.008),Vector4(.112,.096,.092,.015),Vector4(.153,.054,.061,.018),Vector4(.177,.011,.016,.019)]
	var index := 0
	while index<rows.size()-2 and y>Vector4(rows[index+1]).x:
		index += 1
	var a: Vector4 = rows[maxi(0,index-1)]
	var b: Vector4 = rows[index]
	var c: Vector4 = rows[index+1]
	var d: Vector4 = rows[mini(rows.size()-1,index+2)]
	var t := clampf((y-b.x)/(c.x-b.x),0,1)
	var radius := Vector3(b.y,b.z,b.w).cubic_interpolate(Vector3(c.y,c.z,c.w),Vector3(a.y,a.z,a.w),Vector3(d.y,d.z,d.w),t)
	radius.x *= .92 if female else 1.0
	return radius

static func _point(theta: float, y: float, female: bool) -> Vector3:
	var profile := _profile(y,female)
	var x := sin(theta)*profile.x
	var z := cos(theta)*profile.y+profile.z
	var frontal := pow(maxf(0,-cos(theta)),7)
	if frontal>0:
		# A shallow facial plane supports cheeks; nasal/brow relief is continuous.
		z = lerpf(z,profile.z-profile.y*(1-.055*pow(x/maxf(profile.x,.01),2)),frontal)
		var bridge := exp(-pow(x/.018,2)-pow((y+.006)/.042,2))*.014
		var nose := exp(-pow(x/(.015 if female else .018),2)-pow((y+.038)/.019,2))*(.021 if female else .025)
		var brow := exp(-pow((absf(x)-.045)/.037,2)-pow((y-.044)/.015,2))*.008
		var cheek := exp(-pow((absf(x)-.074)/.029,2)-pow((y+.036)/.027,2))*.007
		var socket := exp(-pow((absf(x)-.047)/.027,2)-pow((y-.014)/.016,2))*.007
		z -= frontal*(bridge+nose+brow+cheek-socket)
	return Vector3(x,y,z)

static func _front_z(x: float, y: float, female: bool) -> float:
	var radius := _profile(y,female).x
	return _point(PI-asin(clampf(x/maxf(radius,.001),-.99,.99)),y,female).z

static func _head(model: GuCharacterModel, female: bool) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	var columns := 64
	var rows := 38
	for row in range(rows+1):
		var v := float(row)/rows
		var y := lerpf(-.158,.177,v)
		for col in range(columns+1):
			var theta := TAU*col/columns
			var point := _point(theta,y,female)
			var tangent := _point(theta+.001,y,female)-_point(theta-.001,y,female)
			var vertical := _point(theta,minf(y+.001,.177),female)-_point(theta,maxf(y-.001,-.158),female)
			vertices.append(point)
			normals.append(tangent.cross(vertical).normalized())
			uv.append(Vector2(float(col)/columns,v))
	for row in range(rows):
		for col in range(columns):
			var a := row*(columns+1)+col
			var b := a+columns+1
			indices.append_array(PackedInt32Array([a,b,a+1,a+1,b,b+1]))
	model._store("Head","face_skin",vertices,normals,uv,indices)

static func _eye(model: GuCharacterModel, side: float, female: bool) -> void:
	var center := Vector2(side*.047,.014)
	var width := .0255
	var height := .0085 if female else .0076
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	var lid_top: Array[Vector3] = []
	var lid_bottom: Array[Vector3] = []
	for row in range(5):
		var r := float(row)/2-1
		for col in range(19):
			var u := float(col)/18
			var x := center.x+(u*2-1)*width
			var edge := sin(u*PI)
			var y := center.y+r*height*edge+side*(u-.5)*.001
			var z := _front_z(x,y,female)-.0008-(1-r*r)*edge*.0015
			var point := Vector3(x,y,z)
			vertices.append(point)
			normals.append(Vector3(0,0,-1))
			uv.append(Vector2(u,float(row)/4))
			if row==4:
				lid_top.append(point+Vector3(0,0,-.0005))
			elif row==0:
				lid_bottom.append(point+Vector3(0,0,-.0003))
	for row in range(4):
		for col in range(18):
			var a := row*19+col
			indices.append_array(PackedInt32Array([a,a+19,a+1,a+1,a+19,a+20]))
	model._store("Head","eye_white",vertices,normals,uv,indices)
	model._tube("Head","shadow_skin",lid_top,.0019,8)
	model._tube("Head","skin",lid_bottom,.0013,8)
	_disk(model,"iris",center,.0068,_front_z(center.x,center.y,female)-.0025)
	_disk(model,"eye",center,.0032,_front_z(center.x,center.y,female)-.0031)
	model._ellipsoid("Head","eye_white",Vector3(center.x-.002,center.y+.002,_front_z(center.x,center.y,female)-.0037),Vector3(.0012,.0012,.0007),8,6)

static func _disk(model: GuCharacterModel, material: String, center: Vector2, radius: float, z: float) -> void:
	var vertices := PackedVector3Array([Vector3(center.x,center.y,z)])
	var normals := PackedVector3Array([Vector3(0,0,-1)])
	var uv := PackedVector2Array([Vector2(.5,.5)])
	var indices := PackedInt32Array()
	for col in range(25):
		var angle := TAU*col/24
		vertices.append(Vector3(center.x+cos(angle)*radius,center.y+sin(angle)*radius,z))
		normals.append(Vector3(0,0,-1))
		uv.append(Vector2(.5,.5)+Vector2(cos(angle),sin(angle))*.5)
	for col in range(24):
		indices.append_array(PackedInt32Array([0,col+1,col+2]))
	model._store("Head",material,vertices,normals,uv,indices)

static func _hair(model: GuCharacterModel, female: bool) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	var columns := 48
	var rows := 10
	for row in range(rows+1):
		for col in range(columns+1):
			var theta := TAU*col/columns
			var front := maxf(0,-cos(theta))
			var hairline := lerpf(-.106,.080,pow(front,1.7))+.008*sin(theta*3)
			var y := lerpf(hairline,.173,float(row)/rows)
			var point := _point(theta,y,female)
			var normal := Vector3(sin(theta),.3,cos(theta)).normalized()
			vertices.append(point+normal*.006)
			normals.append(normal)
			uv.append(Vector2(float(col)/columns,float(row)/rows))
	for row in range(rows):
		for col in range(columns):
			var a := row*(columns+1)+col
			indices.append_array(PackedInt32Array([a,a+columns+1,a+1,a+1,a+columns+1,a+columns+2]))
	model._store("Head","hair",vertices,normals,uv,indices)
	# Swept curved locks break the helmet outline without noisy loose strands.
	for lock in range(10):
		var x := (float(lock)/9*2-1)*.090
		_sweep(model,"Head","hair" if lock%3!=0 else "hair_light",[Vector4(x*.30,.175,-.015,.014),Vector4(x*.72,.146,-.079,.018),Vector4(x,.095,-.105,.015),Vector4(x*.88,.069+float(lock%3)*.005,-.103,.0025)],10)
	for side in [-1.0,1.0]:
		_sweep(model,"Head","hair",[Vector4(side*.095,.081,-.069,.018),Vector4(side*.110,.005,-.064,.016),Vector4(side*.097,-.074,-.034,.002)],10)
	if model.appearance["hair"]=="ponytail":
		# Multiple tapered curved locks replace the straight rectangular ponytail.
		for lock in range(5):
			var sx := (lock-2)*.011
			_sweep(model,"Hair","hair" if lock%2==0 else "hair_light",[Vector4(sx,.022,.035,.021),Vector4(sx*1.7,-.09,.095,.022),Vector4(sx*2.1,-.20,.145,.017),Vector4(sx*1.4,-.32,.130,.012),Vector4(sx*.8,-.41,.087,.002)],10)
		model._ellipsoid("Hair","gold",Vector3(0,-.026,.042),Vector3(.048,.012,.042),20,8)
	else:
		for lock in range(5):
			var angle := TAU*lock/5
			_sweep(model,"Head","hair",[Vector4(cos(angle)*.032,.175,.038+sin(angle)*.030,.025),Vector4(cos(angle)*.028,.230,.04+sin(angle)*.025,.024),Vector4(cos(angle)*.017,.255,.042+sin(angle)*.015,.012)],10)
		model._shape("Head","gold",[Vector4(.179,.054,.049,.036),Vector4(.190,.054,.050,.036)],24)
		model._tube("Head","gold",[Vector3(-.09,.229,.036),Vector3(.10,.229,.036)],.006,10)
		model._ellipsoid("Head","jade",Vector3(.10,.229,.036),Vector3(.019,.015,.012),14,8)

static func _sweep(model: GuCharacterModel, bone: String, material: String, points: Array, columns: int) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	var rows := (points.size()-1)*5
	for row in range(rows+1):
		var phase := float(row)/rows*(points.size()-1)
		var index := mini(int(phase),points.size()-2)
		var t := phase-index
		var p0: Vector4 = points[maxi(index-1,0)]
		var p1: Vector4 = points[index]
		var p2: Vector4 = points[index+1]
		var p3: Vector4 = points[mini(index+2,points.size()-1)]
		var center := Vector3(p1.x,p1.y,p1.z).cubic_interpolate(Vector3(p2.x,p2.y,p2.z),Vector3(p0.x,p0.y,p0.z),Vector3(p3.x,p3.y,p3.z),t)
		var radius := lerpf(p1.w,p2.w,smoothstep(0,1,t))
		var tangent := (Vector3(p2.x,p2.y,p2.z)-Vector3(p1.x,p1.y,p1.z)).normalized()
		var axis := Vector3.RIGHT if absf(tangent.dot(Vector3.UP))>.85 else Vector3.UP
		var right := tangent.cross(axis).normalized()
		var up := tangent.cross(right).normalized()
		for col in range(columns+1):
			var angle := TAU*col/columns
			var normal := right*cos(angle)+up*sin(angle)
			vertices.append(center+normal*radius*(1+.035*cos(angle*5)))
			normals.append(normal)
			uv.append(Vector2(float(col)/columns,float(row)/rows))
	for row in range(rows):
		for col in range(columns):
			var a := row*(columns+1)+col
			indices.append_array(PackedInt32Array([a,a+columns+1,a+1,a+1,a+columns+1,a+columns+2]))
	model._store(bone,material,vertices,normals,uv,indices)
