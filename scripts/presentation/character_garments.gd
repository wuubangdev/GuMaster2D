class_name GuCharacterGarments
extends RefCounted
## Designed, original garment meshes. Positions use the humanoid's rest space;
## every fold, seam and trim keeps the same weights as its underlying fabric.

const TORSO := [
	Vector4(.963,.150,.117,0), Vector4(1.015,.153,.119,0),
	Vector4(1.085,.156,.120,0), Vector4(1.15,.173,.127,-.001),
	Vector4(1.23,.198,.135,-.002), Vector4(1.32,.220,.141,-.001),
	Vector4(1.395,.228,.133,0), Vector4(1.447,.210,.119,0),
	Vector4(1.480,.164,.100,0), Vector4(1.510,.107,.077,0),
	Vector4(1.539,.060,.066,0)
]

static func build(model) -> void:
	var outfit := str(model.appearance.get("outfit","jade"))
	var female: bool = model.appearance.get("body")=="female"
	var width := .88 if female else 1.0
	_tunic(model,width,female,outfit)
	_cross_collar(model,width,female,outfit)
	_belt(model,width,outfit)
	for side in ["L","R"]:
		_sleeve(model,side,female,outfit)
		_bracer(model,side,outfit)
	_split_robe(model,width,outfit)
	_back_yoke(model,width,outfit)
	if outfit=="crimson":
		_lamellar(model,width,female)
	_accessories(model,width,outfit)

static func _section(y: float, width: float, female: bool) -> Vector4:
	var lo: Vector4 = TORSO[0]
	var hi: Vector4 = TORSO[1]
	for row in range(1,TORSO.size()):
		hi = TORSO[row]
		lo = TORSO[row-1]
		if y<=hi.x:
			break
	var t := smoothstep(lo.x,hi.x,y)
	var r := lo.lerp(hi,t)
	r.y *= width
	# Sculpted bust/pectoral contour is subtle and contained under the robe.
	if female:
		r.z += .009*exp(-pow((y-1.285)/.075,2.0))
	return r

static func _torso_point(y: float, theta: float, width: float, female: bool, outfit: String) -> Vector3:
	var r := _section(y,width,female)
	var waist := exp(-pow((y-1.09)/.17,2.0))
	var shoulder := smoothstep(1.36,1.51,y)
	# Long gravity folds follow the fitted torso, shrinking at the collar.
	var fold := (.0015+.0025*waist)*(1-shoulder)*sin(theta*7.0+.3+y*.9)
	var gather := .0018*sin((y-1.01)*67.0+theta*2.0)*exp(-pow((y-1.055)/.058,2.0))
	if outfit=="crimson":
		fold *= .55
	return Vector3(sin(theta)*(r.y+fold),y,-cos(theta)*(r.z+fold+gather)+r.w)

static func _torso_weights(y: float) -> Dictionary:
	if y<1.18:
		var spine := smoothstep(.978,1.18,y)
		return {"Hips":1-spine,"Spine":spine}
	var chest := smoothstep(1.18,1.415,y)
	return {"Spine":1-chest,"Chest":chest}

static func _tunic(model, width: float, female: bool, outfit: String) -> void:
	var verts := PackedVector3Array()
	var tex := PackedVector2Array()
	var weights: Array[Dictionary] = []
	var rows := 22
	var columns := 32
	for row in range(rows+1):
		var y := lerpf(TORSO[0].x,TORSO[-1].x,float(row)/rows)
		for col in range(columns+1):
			verts.append(_torso_point(y,TAU*col/columns,width,female,outfit))
			tex.append(Vector2(float(col)/columns,float(row)/rows))
			weights.append(_torso_weights(y))
	_append(model,"cloth",verts,tex,_grid(rows,columns),weights)

static func _front(y: float, x: float, width: float, female: bool, outfit: String, relief: float=.003) -> Vector3:
	var r := _section(y,width,female)
	var angle := asin(clampf(x/maxf(r.y,.01),-.995,.995))
	var surface := _torso_point(y,angle,width,female,outfit)
	surface.z -= relief
	return surface

static func _cross_collar(model, width: float, female: bool, outfit: String) -> void:
	# The long crossing panels are conformed to the torso rather than floating
	# straight ribbons. They widen at the shoulder and settle into the belt.
	for side: float in [-1.0,1.0]:
		var vertices := PackedVector3Array()
		var uv := PackedVector2Array()
		var weights: Array[Dictionary] = []
		var rows := 24
		var cols := 4
		for row in range(rows+1):
			var t := float(row)/rows
			var y := lerpf(1.529,1.023,t)
			var x := side*(.038+.078*sin(PI*t*.95)-.165*pow(t,2.0))*width
			var half := lerpf(.017,.025,sin(PI*t))
			for col in range(cols+1):
				var across := float(col)/cols*2-1
				var p := _front(y,x+across*half,width,female,outfit,.0035 if side<0 else .006)
				# Rolled lapel edges form a fine rounded highlight.
				p.z -= .0015*sin(PI*float(col)/cols)
				vertices.append(p)
				uv.append(Vector2(float(col)/cols,t))
				weights.append(_torso_weights(y))
		_append(model,"ivory" if side<0 else "cloth_dark",vertices,uv,_grid(rows,cols),weights)
		var edge := PackedVector3Array()
		var edge_weights: Array[Dictionary] = []
		for row in range(rows+1):
			var t := float(row)/rows
			var y := lerpf(1.529,1.023,t)
			var x := side*(.038+.078*sin(PI*t*.95)-.165*pow(t,2.0))*width+side*lerpf(.017,.025,sin(PI*t))
			edge.append(_front(y,x,width,female,outfit,.006 if side<0 else .008))
			edge_weights.append(_torso_weights(y))
		_weighted_tube(model,"gold",edge,edge_weights,.0016,4)

static func _belt(model, width: float, outfit: String) -> void:
	var rows := 4
	var columns := 32
	var verts := PackedVector3Array()
	var uv := PackedVector2Array()
	var weights: Array[Dictionary] = []
	for row in range(rows+1):
		var t := float(row)/rows
		var y := lerpf(.981,1.058,t)
		for col in range(columns+1):
			var angle := TAU*float(col)/columns
			var wrinkle := .0017*sin(t*TAU*2+angle*3)*sin(PI*t)
			verts.append(Vector3(sin(angle)*(.164*width+wrinkle),y,-cos(angle)*(.133+wrinkle)))
			uv.append(Vector2(float(col)/columns,t))
			weights.append({"Hips":1.0})
	_append(model,"leather" if outfit=="crimson" else "cloth_dark",verts,uv,_grid(rows,columns),weights)
	# Thin sewn piping is seated on the belt edges, not oversized metal rings.
	for y in [.986,1.053]:
		var points := PackedVector3Array()
		var point_weights: Array[Dictionary] = []
		for i in range(25):
			var angle := TAU*float(i)/24
			points.append(Vector3(sin(angle)*.165*width,y,-cos(angle)*.134))
			point_weights.append({"Hips":1.0})
		_weighted_tube(model,"gold",points,point_weights,.0018,4)
	model._ellipsoid("Hips","gold",Vector3(0,.039,-.140),Vector3(.031,.024,.006),16,8)
	model._ellipsoid("Hips","jade",Vector3(0,.039,-.147),Vector3(.015,.017,.0035),14,8)

static func _sleeve_center(t: float, sign_x: float) -> Vector3:
	var path := [Vector3(.118,1.480,0),Vector3(.217,1.473,0),Vector3(.265,1.445,0),Vector3(.299,1.404,0),Vector3(.310,1.332,0),Vector3(.310,1.235,0),Vector3(.310,1.130,0),Vector3(.310,1.026,0)]
	var scaled := clampf(t,0,1)*(path.size()-1)
	var row := mini(int(scaled),path.size()-2)
	var v: Vector3 = path[row].lerp(path[row+1],scaled-row)
	v.x *= sign_x
	return v

static func _sleeve_weights(t: float, side: String) -> Dictionary:
	if t<.43:
		var arm := smoothstep(.02,.40,t)
		return {"Chest":1-arm,"UpperArm_"+side:arm}
	var fore := smoothstep(.64,.81,t)
	return {"UpperArm_"+side:1-fore,"Forearm_"+side:fore}

static func _sleeve_point(t: float, theta: float, sign_x: float, female: bool, outfit: String) -> Vector3:
	var center := _sleeve_center(t,sign_x)
	var tangent := (_sleeve_center(minf(1,t+.012),sign_x)-_sleeve_center(maxf(0,t-.012),sign_x)).normalized()
	var normal_axis := Vector3(-tangent.y,tangent.x,0).normalized()
	var radius := lerpf(.052,.066,smoothstep(0,.29,t))
	radius *= .95 if female else 1.0
	var depth := radius*1.08
	var lower := smoothstep(.51,1,t)
	if outfit=="ivory":
		radius += .049*pow(lower,1.4)
		depth += .052*pow(lower,1.4)
	elif outfit=="jade":
		radius -= .010*lower
		depth -= .008*lower
	else:
		radius -= .012*lower
		depth -= .014*lower
	var fold := (.002+.0025*lower)*sin(theta*5.0+t*3.0)
	var elbow_wrinkle := .0024*sin(t*99+theta*1.4)*exp(-pow((t-.71)/.095,2.0))
	var point := center+normal_axis*cos(theta)*(radius+fold+elbow_wrinkle)+Vector3.BACK*sin(theta)*(depth+fold)
	# Seat the open armhole on the existing torso surface. A tube whose first
	# loop merely ends beside the shirt creates a visible gap at the neck-side
	# shoulder, particularly once the arm rotates. The inset loop is Chest
	# weighted and the gusset expands continuously into the arm sweep.
	var armhole := 1-smoothstep(0.0,.25,t)
	if armhole>0:
		var width := .88 if female else 1.0
		var section := _section(point.y,width,female)
		var side_surface := section.y*sqrt(maxf(.015,1-pow(point.z/maxf(section.z,.01),2.0)))*.968
		point.x = lerpf(point.x,sign_x*side_surface,armhole)
	# Free sleeve bells fall behind and below the forearm in the rest pose.
	if outfit=="ivory":
		point.z += .016*pow(lower,2.0)
		point.y -= .026*pow(lower,2.0)*pow(maxf(0,sin(theta)),2.0)
	return point

static func _sleeve(model, side: String, female: bool, outfit: String) -> void:
	var sign_x := -1.0 if side=="L" else 1.0
	var end := .72 if outfit=="crimson" else (.86 if outfit=="jade" else 1.0)
	var rows := 16
	var columns := 20
	var verts := PackedVector3Array()
	var uv := PackedVector2Array()
	var weights: Array[Dictionary] = []
	for row in range(rows+1):
		var t := end*float(row)/rows
		for col in range(columns+1):
			verts.append(_sleeve_point(t,TAU*float(col)/columns,sign_x,female,outfit))
			uv.append(Vector2(float(col)/columns,float(row)/rows))
			weights.append(_sleeve_weights(t,side))
	_append(model,"cloth",verts,uv,_grid(rows,columns,true),weights)
	# Conformed cuff with the same elbow weights, preventing rigid detached cuffs.
	var cuff := PackedVector3Array()
	var cuff_uv := PackedVector2Array()
	var cuff_weights: Array[Dictionary] = []
	for row in range(3):
		var t := end-.037+float(row)/2*.038
		for col in range(columns+1):
			var theta := TAU*float(col)/columns
			var p := _sleeve_point(t,theta,sign_x,female,outfit)
			var center := _sleeve_center(t,sign_x)
			p += (p-center).normalized()*.0015
			cuff.append(p)
			cuff_uv.append(Vector2(float(col)/columns,float(row)/2))
			cuff_weights.append(_sleeve_weights(t,side))
	_append(model,"ivory" if outfit=="ivory" else "cloth_dark",cuff,cuff_uv,_grid(2,columns,true),cuff_weights)
	var edge := PackedVector3Array()
	var edge_weights: Array[Dictionary] = []
	for col in range(columns+1):
		var p := _sleeve_point(end,TAU*float(col)/columns,sign_x,female,outfit)
		p += (p-_sleeve_center(end,sign_x)).normalized()*.0020
		edge.append(p)
		edge_weights.append(_sleeve_weights(end,side))
	_weighted_tube(model,"gold",edge,edge_weights,.0018,4)

static func _bracer(model, side: String, outfit: String) -> void:
	if outfit=="ivory":
		return
	model._shape("Forearm_"+side,"leather" if outfit=="crimson" else "cloth_dark",[
		Vector4(-.060,.053,.055,0),Vector4(-.090,.057,.058,0),
		Vector4(-.145,.054,.056,0),Vector4(-.205,.047,.050,0),Vector4(-.233,.045,.048,0)
	],24,.0008)
	for y in [-.078,-.209]:
		model._shape("Forearm_"+side,"gold",[Vector4(y,.058 if y>-.1 else .049,.059 if y>-.1 else .052,0),Vector4(y-.004,.058 if y>-.1 else .049,.059 if y>-.1 else .052,0)],24)

static func _robe_point(t: float, theta: float, width: float, outfit: String, rear: bool=false) -> Vector3:
	var hem := .588 if outfit=="crimson" else (.202 if outfit=="ivory" else .394)
	if rear and outfit=="ivory":
		hem -= .018
	var y := lerpf(.988,hem,t)
	var radius_x := lerpf(.159,.219 if outfit=="jade" else (.277 if outfit=="ivory" else .203),smoothstep(0,1,t))*width
	var radius_z := lerpf(.126,.139 if outfit=="jade" else (.165 if outfit=="ivory" else .134),smoothstep(0,1,t))
	var wave := sin(theta*10.0+.2)*(.002+.007*pow(t,.68))+sin(theta*21+.6)*.0012*t
	# Cloth follows a hanging curve with tension at the waist and heavier folds
	# at the hem, rather than a rigid rectangular board or straight cone.
	radius_x += .009*sin(PI*t)*width
	var p := Vector3(sin(theta)*(radius_x+wave),y,-cos(theta)*(radius_z+wave))
	p.y += .017*pow(t,5.0)*(sin(theta*3+.5)*.5+.5)
	return p

static func _robe_weights(p: Vector3, t: float, outfit: String) -> Dictionary:
	var follow := smoothstep(.055,.58,t)*.87
	var right := smoothstep(-.06,.06,p.x)
	var shin := smoothstep(.82,1.0,t)*(.18 if outfit=="ivory" else .06)
	return {"Hips":1-follow,"Thigh_L":follow*(1-right)*(1-shin),"Thigh_R":follow*right*(1-shin),"Shin_L":follow*(1-right)*shin,"Shin_R":follow*right*shin}

static func _split_robe(model, width: float, outfit: String) -> void:
	var rows := 22
	var columns := 12
	# Four wrapped panels leave a usable central split at the front and rear.
	var opening := .11 if outfit=="jade" else (.10 if outfit=="ivory" else .15)
	var spans := [Vector2(opening,PI*.50),Vector2(-PI*.50,-opening),Vector2(PI*.50,PI-opening),Vector2(PI+opening,PI*1.5)]
	for panel in range(spans.size()):
		var span: Vector2 = spans[panel]
		var verts := PackedVector3Array()
		var uv := PackedVector2Array()
		var weights: Array[Dictionary] = []
		for row in range(rows+1):
			var t := float(row)/rows
			for col in range(columns+1):
				var theta := lerpf(span.x,span.y,float(col)/columns)
				var p := _robe_point(t,theta,width,outfit,panel>=2)
				verts.append(p)
				uv.append(Vector2(float(col)/columns,t))
				weights.append(_robe_weights(p,t,outfit))
		_append(model,"cloth" if panel<2 else "cloth_dark",verts,uv,_grid(rows,columns,true),weights)
		# A broad hem facing and narrow gold stitching are geometry conforming
		# to the drape; both carry exactly the parent fabric's skin weights.
		for trim in range(2):
			var trim_verts := PackedVector3Array()
			var trim_uv := PackedVector2Array()
			var trim_weights: Array[Dictionary] = []
			for row in range(3):
				var t := lerpf(.953,.995,float(row)/2) if trim==0 else lerpf(.986,.991,float(row)/2)
				for col in range(columns+1):
					var theta := lerpf(span.x,span.y,float(col)/columns)
					var p := _robe_point(t,theta,width,outfit,panel>=2)
					var raw := p
					p += Vector3(sin(theta),0,-cos(theta))*(.0015 if trim==0 else .0024)
					trim_verts.append(p)
					trim_uv.append(Vector2(float(col)/columns,float(row)/2))
					trim_weights.append(_robe_weights(raw,t,outfit))
			_append(model,"cloth_light" if trim==0 else "gold",trim_verts,trim_uv,_grid(2,columns,true),trim_weights)
		for theta in [span.x,span.y]:
			var edge_verts := PackedVector3Array()
			var edge_uv := PackedVector2Array()
			var edge_weights: Array[Dictionary] = []
			for row in range(rows+1):
				var t := float(row)/rows
				for col in range(2):
					var a: float = theta+(float(col)-.5)*.018
					var p := _robe_point(t,a,width,outfit,panel>=2)
					var raw := p
					p += Vector3(sin(a),0,-cos(a))*.002
					edge_verts.append(p)
					edge_uv.append(Vector2(float(col),t))
					edge_weights.append(_robe_weights(raw,t,outfit))
			_append(model,"cloth_light",edge_verts,edge_uv,_grid(rows,1,true),edge_weights)

static func _back_yoke(model, width: float, outfit: String) -> void:
	var rows := 12
	var cols := 24
	var length := .258 if outfit=="crimson" else (.545 if outfit=="ivory" else .413)
	var verts := PackedVector3Array()
	var uv := PackedVector2Array()
	var weights: Array[Dictionary] = []
	for row in range(rows+1):
		var t := float(row)/rows
		for col in range(cols+1):
			var u := float(col)/cols
			var angle := lerpf(PI*.51,PI*1.49,u)
			var across := sin(angle)
			var hem_fold := (.012*sin(angle*5+.4)+.006*sin(angle*11))*pow(t,3.0)
			var y := 1.459-length*t-.022*absf(across)*(1-t)+.024*absf(across)*pow(t,4.0)+hem_fold
			var hem_width := .158 if outfit=="jade" else (.184 if outfit=="ivory" else .172)
			var half_width := (lerpf(.216,hem_width,smoothstep(.22,1,t))+.004*sin(PI*t))*width
			var drape := (.013*sin(angle*7+.15)+.004*sin(angle*15+.6))*smoothstep(.04,.52,t)
			var depth := lerpf(.139,.151,t)+drape
			var p := Vector3(across*(half_width+drape*.35),y,-cos(angle)*depth+.010)
			p.z += .008*sin(t*PI)*cos(angle*5)
			verts.append(p)
			uv.append(Vector2(u,t))
			var cape := smoothstep(.03,.35,t)*.65
			var tip := smoothstep(.36,.94,t)*cape
			weights.append({"Chest":1-cape,"Cape":cape-tip,"CapeTip":tip})
	_append(model,"leather" if outfit=="crimson" else "cloth_dark",verts,uv,_grid(rows,cols,true),weights)
	# Sewn edges use the exact same weight envelope as the mantle surface.
	for col: int in [0,cols]:
		var points := PackedVector3Array()
		var point_weights: Array[Dictionary] = []
		for row in range(rows+1):
			var i := row*(cols+1)+col
			points.append(verts[i]+Vector3(0,0,.0015))
			point_weights.append(weights[i])
		_weighted_tube(model,"cloth_light",points,point_weights,.0025,5)

static func _lamellar(model, width: float, female: bool) -> void:
	# Twenty small curved overlapping lamellae wrap the pectoral surface. The
	# row relief is millimetres; silhouette is still a fitted light martial robe.
	for row in range(4):
		var center_y := 1.243+row*.049
		for col in range(5):
			var center_x := (col-2)*.041*width
			var vertices := PackedVector3Array()
			var uv := PackedVector2Array()
			var weights: Array[Dictionary] = []
			for dy in range(3):
				for dx in range(5):
					var y := center_y+(dy-1)*.027
					var x := center_x+(dx-2)*.0092*width
					var p := _front(y,x,width,female,"crimson",.008+float(row)*.0007)
					p.z -= .002*sin(PI*float(dx)/4)
					vertices.append(p)
					uv.append(Vector2(float(dx)/4,float(dy)/2))
					weights.append(_torso_weights(y))
			_append(model,"leather",vertices,uv,_grid(2,4),weights)
			# A pair of fine rivets anchors each plate, seated on its curved face.
			for sx in [-1.0,1.0]:
				var p := _front(center_y+.018,center_x+sx*.009,width,female,"crimson",.011+float(row)*.0007)
				var rivet := PackedVector3Array([p+Vector3(0,0,-.001)])
				var rivet_uv := PackedVector2Array([Vector2(.5,.5)])
				var rivet_weights: Array[Dictionary] = [_torso_weights(p.y)]
				var rivet_indices := PackedInt32Array()
				for corner in range(6):
					var angle := TAU*float(corner)/6
					rivet.append(p+Vector3(cos(angle),sin(angle),0)*.0023)
					rivet_uv.append(Vector2(cos(angle),sin(angle))*.5+Vector2(.5,.5))
					rivet_weights.append(_torso_weights(p.y))
				for corner in range(6):
					rivet_indices.append_array(PackedInt32Array([0,(corner+1)%6+1,corner+1]))
				_append(model,"gold",rivet,rivet_uv,rivet_indices,rivet_weights)

static func _accessories(model, width: float, outfit: String) -> void:
	var side_x := .163*width
	# A narrow knotted cord and small jade seal give a recognizable wuxia
	# accent without replacing the body silhouette with floating ornaments.
	model._tube("Hips","gold",[Vector3(side_x,.045,-.042),Vector3(side_x+.005,-.045,-.055),Vector3(side_x+.012,-.119,-.055)],.003,6)
	model._ellipsoid("Hips","jade",Vector3(side_x+.012,-.142,-.055),Vector3(.014,.023,.006),14,8)
	for sx in [-1.0,1.0]:
		model._tube("Hips","cloth_light",[Vector3(side_x+.012+sx*.003,-.161,-.055),Vector3(side_x+.012+sx*.004,-.198,-.058)],.002,5)
	if outfit=="jade":
		model._ellipsoid("Hips","leather",Vector3(-.170*width,-.075,.018),Vector3(.033,.047,.030),16,10)
		model._ellipsoid("Hips","gold",Vector3(-.170*width,-.047,-.010),Vector3(.006,.005,.002),10,6)
	if outfit=="ivory":
		# Soft layered front sash rather than a straight rigid hanging rectangle.
		var rows := 20
		var columns := 8
		var verts := PackedVector3Array()
		var uv := PackedVector2Array()
		var weights: Array[Dictionary] = []
		for row in range(rows+1):
			var t := float(row)/rows
			for col in range(columns+1):
				var across := float(col)/columns*2-1
				var p := Vector3(across*lerpf(.025,.043,t),.978-.405*t,-.140-.011*sin(PI*t)-.004*cos(across*PI*2)*t)
				p.y += .012*absf(across)*pow(t,4.0)
				verts.append(p)
				uv.append(Vector2(float(col)/columns,t))
				weights.append({"Hips":1.0})
		_append(model,"ivory",verts,uv,_grid(rows,columns,true),weights)

static func _grid(rows: int, columns: int, reverse: bool=false) -> PackedInt32Array:
	var indices := PackedInt32Array()
	for row in range(rows):
		for col in range(columns):
			var a := row*(columns+1)+col
			var b := a+columns+1
			indices.append_array(PackedInt32Array([a,a+1,b,a+1,b+1,b]) if reverse else PackedInt32Array([a,b,a+1,a+1,b,b+1]))
	return indices

static func _weighted_tube(model, material: String, points: PackedVector3Array, weights: Array[Dictionary], radius: float, segments: int) -> void:
	var verts := PackedVector3Array()
	var uv := PackedVector2Array()
	var skin_weights: Array[Dictionary] = []
	for row in range(points.size()):
		var tangent := (points[mini(row+1,points.size()-1)]-points[maxi(row-1,0)]).normalized()
		var axis := Vector3.RIGHT if absf(tangent.dot(Vector3.UP))>.9 else Vector3.UP
		var right := tangent.cross(axis).normalized()
		var up := tangent.cross(right).normalized()
		for col in range(segments+1):
			var theta := TAU*float(col)/segments
			verts.append(points[row]+radius*(right*cos(theta)+up*sin(theta)))
			uv.append(Vector2(float(col)/segments,float(row)/maxi(points.size()-1,1)))
			skin_weights.append(weights[row])
	_append(model,material,verts,uv,_grid(points.size()-1,segments,true),skin_weights)

static func _append(model, material: String, vertices: PackedVector3Array, uv: PackedVector2Array, indices: PackedInt32Array, weights: Array[Dictionary]) -> void:
	if not model.buckets.has(material):
		model.buckets[material] = {"v":PackedVector3Array(),"n":PackedVector3Array(),"uv":PackedVector2Array(),"i":PackedInt32Array(),"b":PackedInt32Array(),"w":PackedFloat32Array()}
	var bucket: Dictionary = model.buckets[material]
	var base: int = bucket.v.size()
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	for triangle in range(0,indices.size(),3):
		var a: int = indices[triangle]
		var b: int = indices[triangle+1]
		var c: int = indices[triangle+2]
		var face := (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a])
		normals[a] += face
		normals[b] += face
		normals[c] += face
	# A UV seam may duplicate a vertex without creating a hard fabric seam.
	# Average by position within this piece, retaining each vertex's original UV.
	var normal_sums: Dictionary = {}
	for vertex in range(vertices.size()):
		var key := vertices[vertex].snapped(Vector3(.000001,.000001,.000001))
		normal_sums[key] = Vector3(normal_sums.get(key,Vector3.ZERO))+normals[vertex]
	for vertex in range(vertices.size()):
		bucket.v.append(vertices[vertex])
		var key := vertices[vertex].snapped(Vector3(.000001,.000001,.000001))
		var normal: Vector3 = Vector3(normal_sums[key]).normalized()
		if normal.length_squared()<.01:
			normal = Vector3.UP
		bucket.n.append(normal)
		bucket.uv.append(uv[vertex])
		# Four influences are the shipping rig contract. Keep the strongest
		# contributors and normalize after removing the negligible tail.
		var influences: Array = weights[vertex].keys()
		influences.sort_custom(func(a,b): return float(weights[vertex][a])>float(weights[vertex][b]))
		var total := 0.0
		for i in range(mini(4,influences.size())):
			total += maxf(float(weights[vertex][influences[i]]),0)
		for i in range(4):
			var bone := 0
			var weight := 0.0
			if i<influences.size() and i<4:
				bone = model.skeleton.find_bone(str(influences[i]))
				weight = maxf(float(weights[vertex][influences[i]]),0)/maxf(total,.00001)
			bucket.b.append(bone)
			bucket.w.append(weight)
	for index in indices:
		bucket.i.append(base+index)
