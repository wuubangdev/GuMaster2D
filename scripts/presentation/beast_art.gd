class_name BeastArt
extends RefCounted
## Original ink-cutout bestiary: upright projection, articulated limbs and an
## individual silhouette for every family. Geometry is shared with authority.
const INK := Color("302d29")
const LIGHT := Color("e6d6ae")
const Motion = preload("res://scripts/presentation/beast_motion.gd")
const Footprint = preload("res://scripts/core/beast_attack_geometry.gd")

static func draw(c: CanvasItem, state: Dictionary, phase: float, stride: float, motion: float, reduced: bool, flash: float, selected: bool, fallen: bool = false, death_age: float = .4) -> void:
	var species: String = state.get("species","wolf")
	var spec := Bestiary.species(species)
	var elite: bool = spec.get("elite",false)
	var pose := Motion.pose(state,phase,stride,motion,reduced,flash,fallen,death_age)
	var tint := Color(spec["color"]).darkened(.04)
	if flash > .07 and not reduced: tint=tint.lightened(.32)
	if fallen: tint=tint.lerp(Color("777065"),float(pose["death"])*.4)
	if state.get("state","") == "windup" and not fallen: telegraph(c,state,spec)
	var scale_value := Motion.body_scale(state)
	c.draw_set_transform(Vector2.ZERO,0,Vector2.ONE*scale_value)
	var far := -1.0 if Vector2(pose["side"]).y >=0 else 1.0
	_draw_tail(c,pose,tint)
	_draw_legs(c,pose,tint,far)
	# The head is behind the torso for a back view; never pasted above the body.
	var back: bool = Vector2(pose["facing"]).y < -.3
	if back: _draw_head(c,pose,tint,elite)
	_draw_body(c,pose,tint,elite)
	_draw_legs(c,pose,tint,-far)
	if not back: _draw_head(c,pose,tint,elite)
	if spec["shape"] == "hornet": _draw_wings(c,pose,tint)
	c.draw_set_transform(Vector2.ZERO)
	if not fallen and not state.get("presentation_hide_label",false) and (selected or float(state.get("hp",1)) < float(state.get("max_hp",1)) or elite):
		var width := 54.0 if elite else 44.0
		var at := Vector2(-width*.5,-70 if elite else -42)
		c.draw_style_box(_health_style(),Rect2(at,Vector2(width,5)))
		c.draw_rect(Rect2(at+Vector2(1,1),Vector2((width-2)*clampf(float(state.get("hp",1))/maxf(1,float(state.get("max_hp",1))),0,1),3)),Color("bc8c61"))
		c.draw_string(GuPixelUI.HAND_FONT,at+Vector2(-30,-4),"Lv.%d %s" % [spec["level"],spec["name"]],HORIZONTAL_ALIGNMENT_CENTER,110,9,LIGHT)

static var _health: StyleBoxFlat
static func _health_style() -> StyleBoxFlat:
	if _health==null:
		_health=StyleBoxFlat.new(); _health.bg_color=INK
		_health.set_corner_radius_all(2)
	return _health

static func _p(point: Vector3, pose: Dictionary) -> Vector2: return Motion.point(point,pose)

static func _curve(points: PackedVector2Array, closed: bool = true, divisions: int = 5) -> PackedVector2Array:
	var result := PackedVector2Array()
	var n := points.size()
	if n<3: return points
	for i in range(n if closed else n-1):
		var a := points[(i-1+n)%n] if closed else points[maxi(0,i-1)]
		var b := points[i]
		var d := points[(i+1)%n]
		var e := points[(i+2)%n] if closed else points[mini(n-1,i+2)]
		for j in range(divisions):
			var t := float(j)/divisions
			result.append(.5*((2*b)+(-a+d)*t+(2*a-5*b+4*d-e)*t*t+(-a+3*b-3*d+e)*t*t*t))
	result.append(result[0] if closed else points[n-1])
	return result

static func _fill(c: CanvasItem, points: PackedVector2Array, fill: Color, width: float = 1.35, smooth: bool = true) -> void:
	if points.size()<3: return
	var path := _curve(points) if smooth else points.duplicate()
	# Canvas polygons close implicitly. Giving them a numerically near-duplicate
	# endpoint creates a tiny degenerate ear and makes triangulation fail.
	while path.size()>2 and path[0].distance_squared_to(path[path.size()-1])<.000001:
		path.remove_at(path.size()-1)
	c.draw_colored_polygon(path,fill)
	if width>0:
		var outline:=path.duplicate()
		outline.append(outline[0])
		c.draw_polyline(outline,INK,width,true)

static func _shape(c: CanvasItem, points: Array, pose: Dictionary, fill: Color, width: float = 1.25, smooth: bool = true) -> void:
	var landmarks := PackedVector2Array()
	for point in points: landmarks.append(_p(point,pose))
	# These are solid anatomical volumes, not flat ribbons. Their visible
	# silhouette is the projected hull of the authored 3-D landmarks. Reusing
	# the landmark order as a 2-D contour folds the face over itself in side views.
	var path := Geometry2D.convex_hull(landmarks)
	while path.size()>2 and path[0].distance_squared_to(path[path.size()-1])<.000001: path.remove_at(path.size()-1)
	if path.size()<3:
		# An exactly edge-on rigid plate is a visible ink edge, not a filled face.
		if path.size()==2 and width>0: c.draw_line(path[0],path[1],INK,width,true)
		return
	if smooth:
		# Bounded corner rounding stays inside the silhouette, including very
		# narrow oblique views; a Catmull spline can loop around short hull edges.
		for iteration in range(2):
			var rounded := PackedVector2Array()
			for i in range(path.size()):
				rounded.append(path[i].lerp(path[(i+1)%path.size()],.18))
				rounded.append(path[i].lerp(path[(i+1)%path.size()],.82))
			path=rounded
	_fill(c,path,fill,width,false)

static func _line(c: CanvasItem, points: Array, pose: Dictionary, tint: Color, width: float = 1) -> void:
	var path := PackedVector2Array()
	for point in points: path.append(_p(point,pose))
	c.draw_polyline(_curve(path,false),tint,width,true)

static func _volume(c: CanvasItem, center: Vector3, size: Vector3, pose: Dictionary, tint: Color, detail: bool = true) -> void:
	# Analytic projection of an ellipsoid: 32 curve vertices, no per-frame hull.
	var facing: Vector2 = pose["facing"]
	var side: Vector2 = pose["side"]
	var xx := facing.x*facing.x*size.x*size.x+side.x*side.x*size.y*size.y
	var yy := facing.y*facing.y*size.x*size.x+side.y*side.y*size.y*size.y+size.z*size.z
	var xy := facing.x*facing.y*size.x*size.x+side.x*side.y*size.y*size.y
	var ellipse_angle := .5*atan2(2*xy,xx-yy)
	var discriminant := sqrt(maxf(0,(xx-yy)*(xx-yy)+4*xy*xy))
	var radii := Vector2(sqrt(maxf(.01,(xx+yy+discriminant)*.5)),sqrt(maxf(.01,(xx+yy-discriminant)*.5)))
	var points := PackedVector2Array()
	var projected := _p(center,pose)
	for i in range(32): points.append(projected+(Vector2.from_angle(i*TAU/32)*radii).rotated(ellipse_angle))
	_fill(c,points,tint,1.45,false)
	if not detail: return
	var patch := PackedVector2Array()
	for i in range(22):
		var angle := -PI*.05-i*PI*.9/21
		patch.append(_p(center+Vector3(cos(angle)*size.x*.83,sin(angle)*size.y*.68,size.z*.52),pose))
	c.draw_polyline(patch,tint.lightened(.22),1.45,true)
	var shade := PackedVector2Array()
	for i in range(16):
		var angle := .08+i*PI*.93/15
		shade.append(_p(center+Vector3(cos(angle)*size.x*.88,sin(angle)*size.y*.65,-size.z*.4),pose))
	c.draw_polyline(shade,tint.darkened(.23),2.6,true)

static func _bone(c: CanvasItem, a: Vector3, b: Vector3, pose: Dictionary, tint: Color, width: float) -> void:
	var from := _p(a,pose); var to := _p(b,pose)
	c.draw_line(from,to,INK,width+2.2,true)
	c.draw_circle(from,(width+2.2)*.5,INK,true,-1,true)
	c.draw_circle(to,(width+2.2)*.5,INK,true,-1,true)
	c.draw_line(from,to,tint,width,true)
	c.draw_circle(from,width*.5,tint,true,-1,true)
	c.draw_circle(to,width*.5,tint,true,-1,true)

static func _tapered_bone(c: CanvasItem, a: Vector3, b: Vector3, pose: Dictionary, tint: Color, start_width: float, end_width: float) -> void:
	var from := _p(a, pose)
	var to := _p(b, pose)
	var direction := (to - from).normalized()
	if direction.length_squared() < .001: direction = Vector2.UP
	var normal := direction.orthogonal()
	_fill(c, PackedVector2Array([from + normal * start_width * .5, to + normal * end_width * .5, to - normal * end_width * .5, from - normal * start_width * .5]), tint, 1.15, false)

static func _draw_legs(c: CanvasItem, pose: Dictionary, tint: Color, side: float) -> void:
	var shape: String = pose["shape"]
	var insect := shape in ["spider","hornet","beetle"]
	var count := 4 if shape == "spider" else (3 if insect else 2)
	for i in range(count):
		var x := lerpf(-11,11,float(i)/maxf(1,count-1))
		var joints := Motion.leg(pose,x,side,i,count)
		var near: bool = side*Vector2(pose["side"]).y>=0
		var color := tint if near else tint.darkened(.2)
		var upper := 4.5 if not insect else 2.4
		var lower := 2.8 if not insect else 1.5
		if shape=="boar": upper=5.3;lower=3.0
		if shape=="toad": upper=6.2 if i==0 else 3.5;lower=2.7
		if shape=="hornet": upper=1.5;lower=1.0
		if insect:
			_bone(c,joints[0],joints[1],pose,color.darkened(.09),upper)
			_bone(c,joints[1],joints[2],pose,color,lower)
			c.draw_circle(_p(joints[1],pose),upper*.42,color,true,-1,true)
		else:
			_tapered_bone(c,joints[0],joints[1],pose,color.darkened(.1),upper,lower)
			_tapered_bone(c,joints[1],joints[2],pose,color,lower,lower*.72)
			c.draw_circle(_p(joints[1],pose),lower*.34,color,true,-1,true)
		if not insect:
			var foot: Vector3 = joints[2]
			if shape=="toad":
				_shape(c,[foot+Vector3(-1,-2,.5),foot+Vector3(4,-3,.5),foot+Vector3(5,0,.5),foot+Vector3(4,3,.5),foot+Vector3(-1,2,.5)],pose,color.lightened(.12),.8)
				for toe in [-1,1]: _line(c,[foot+Vector3(0,0,1),foot+Vector3(4,toe*2,1)],pose,color.darkened(.3),.7)
			else:
				_volume(c,foot+Vector3(1.0,0,.4),Vector3(3.0,2.1,1.5),pose,color,false)
				for toe in [-1,1]: _line(c,[foot+Vector3(2,1.1*toe,1.8),foot+Vector3(3.5,1.1*toe,.8)],pose,INK,.6)
		else:
			_line(c,[joints[1].lerp(joints[2],.84),joints[2],joints[2]+Vector3(1.6,side*1.4,-.5)],pose,INK,1.15)

static func _draw_tail(c: CanvasItem, pose: Dictionary, tint: Color) -> void:
	var h: float = pose["height"]
	var swing := 0.0 if pose["reduced"] else sin(float(pose["phase"])*2.4)*2+sin(float(pose["stride"]))*float(pose["gait"])*2
	if pose["shape"] == "wolf":
		_shape(c,[Vector3(-15,0,h+1),Vector3(-27,swing,h-1),Vector3(-32,swing+1,h+5),Vector3(-30,swing-3,h-5),Vector3(-22,-4,h-6),Vector3(-15,-3,h-2)],pose,tint.darkened(.08),1.35,false)
		_line(c,[Vector3(-21,0,h),Vector3(-26,swing,h-1),Vector3(-29,swing,h+1)],pose,tint.lightened(.28),1.5)
	elif pose["shape"] == "boar":
		_line(c,[Vector3(-20,0,h),Vector3(-29,0,h+2),Vector3(-31,2,h+5),Vector3(-28,4,h+6),Vector3(-27,2,h+3)],pose,INK,2.2)

static func _draw_body(c: CanvasItem, pose: Dictionary, tint: Color, elite: bool) -> void:
	var h: float = pose["height"]
	match pose["shape"]:
		"wolf":
			_volume(c,Vector3(-3,0,h),Vector3(20,8.7,9.5),pose,tint)
			# Chest ruff joins the shoulder, with deliberate tapered fur instead of noise.
			_shape(c,[Vector3(2,-7,h+5),Vector3(10,-8,h+9),Vector3(17,-6,h+8),Vector3(14,0,h+1),Vector3(16,6,h-4),Vector3(9,8,h-6),Vector3(8,4,h-2),Vector3(2,6,h-5),Vector3(3,2,h+1)],pose,tint.darkened(.22),.8,false)
			_line(c,[Vector3(-17,-3,h+4),Vector3(-9,-4,h+9),Vector3(0,-4,h+9),Vector3(5,-3,h+7)],pose,tint.lightened(.2),1.2)
			if elite:
				for side in [-1,1]: _line(c,[Vector3(-15,side*5,h+6),Vector3(-8,side*7,h+8),Vector3(-10,side*4,h+10),Vector3(1,side*5,h+8)],pose,Color("e4e2bd"),1.6)
		"boar":
			_volume(c,Vector3(-3,0,h),Vector3(22,12,13),pose,tint)
			# Raised ridge gives the boar a different profile from the wolf.
			_shape(c,[Vector3(-19,-2,h+8),Vector3(-13,-3,h+16),Vector3(-11,0,h+13),Vector3(-7,0,h+17),Vector3(-4,1,h+14),Vector3(2,0,h+17),Vector3(8,2,h+12),Vector3(13,2,h+10),Vector3(5,-3,h+10)],pose,tint.darkened(.32),.8,false)
			for x in [-12,-3,6]: _line(c,[Vector3(x,5,h+9),Vector3(x+1,9,h+4),Vector3(x-1,10,h)],pose,tint.darkened(.22),1)
		"spider":
			_volume(c,Vector3(-11,0,h+2),Vector3(16,12,11),pose,tint)
			_shape(c,[Vector3(-23,0,h+9),Vector3(-13,-6,h+12),Vector3(-9,0,h+13),Vector3(-3,5,h+10),Vector3(-14,4,h+12)],pose,tint.lightened(.3),.7,false)
			_volume(c,Vector3(6,0,h),Vector3(9,7.5,7),pose,tint.darkened(.12))
			for side in [-1,1]: _line(c,[Vector3(-23,side*2,h+8),Vector3(-20,side*8,h+7),Vector3(-13,side*11,h+4)],pose,tint.darkened(.2),1.4)
		"hornet":
			_volume(c,Vector3(-13,0,h),Vector3(17,8,8),pose,tint)
			for x in [-23,-15,-7]:
				_line(c,[Vector3(x,-6,h+1),Vector3(x-1,-4,h+6),Vector3(x,0,h+8),Vector3(x+1,5,h+5),Vector3(x,7,h-1)],pose,INK,3.5)
			_shape(c,[Vector3(-28,-2,h),Vector3(-37,0,h-2),Vector3(-28,2,h-2)],pose,LIGHT,1,false)
			_volume(c,Vector3(5,0,h),Vector3(8,7,8),pose,tint.darkened(.15))
		"toad":
			_volume(c,Vector3(-5,0,h),Vector3(21,14,11),pose,tint)
			for i in range(7):
				var x := -18+(i%3)*8
				var side := -7+(i/3)*6
				_volume(c,Vector3(x,side,h+8),Vector3(2.7,2.1,1.8),pose,tint.darkened(.13),false)
			_line(c,[Vector3(-18,0,h+10),Vector3(-8,0,h+11),Vector3(1,0,h+9)],pose,tint.lightened(.28),2)
		"beetle":
			_volume(c,Vector3(-5,0,h),Vector3(23,15,13),pose,tint.darkened(.2))
			for side in [-1,1]:
				_shape(c,[Vector3(-27,0,h+4),Vector3(-19,side*11,h+10),Vector3(-7,side*14,h+12),Vector3(6,side*10,h+10),Vector3(12,side*2,h+7),Vector3(6,0,h+13),Vector3(-12,0,h+14)],pose,tint.lightened(.08 if side<0 else -.04),1.3)
				_line(c,[Vector3(-22,side*5,h+8),Vector3(-12,side*10,h+12),Vector3(1,side*8,h+12)],pose,tint.lightened(.3),1.3)
				for x in [-15,-6,3]: _line(c,[Vector3(x,side*2,h+13),Vector3(x-2,side*6,h+12),Vector3(x-1,side*10,h+9)],pose,tint.darkened(.26),.8)
			if elite:
				for side in [-1,1]:
					_shape(c,[Vector3(-15,side*8,h+13),Vector3(-8,side*11,h+17),Vector3(0,side*7,h+17),Vector3(1,side*3,h+14),Vector3(-7,side*4,h+15)],pose,Color("b8c1af"),1.2,false)
				_line(c,[Vector3(-14,0,h+15),Vector3(-10,0,h+19),Vector3(-5,0,h+16),Vector3(0,0,h+17)],pose,Color("d7e0bc"),2)

static func _draw_head(c: CanvasItem, pose: Dictionary, tint: Color, elite: bool) -> void:
	var h: float = pose["height"]+float(pose["head_lift"])
	var x: float = pose["head_shift"]
	var front: bool = Vector2(pose["facing"]).y > -.42
	var jaw: float = pose["jaw"]
	var near := 1.0 if Vector2(pose["side"]).y >=0 else -1.0
	match pose["shape"]:
		"wolf":
			_volume(c,Vector3(12+x,0,h+3),Vector3(9,7,10),pose,tint.darkened(.08))
			_volume(c,Vector3(19+x,0,h+8),Vector3(11,8,9),pose,tint.lightened(.04))
			for side in [-near,near]:
				_shape(c,[Vector3(12+x,side*7,h+12),Vector3(15+x,side*9,h+24),Vector3(22+x,side*5,h+15)],pose,tint,1.2,false)
				_shape(c,[Vector3(15+x,side*7,h+15),Vector3(16+x,side*8,h+20),Vector3(19+x,side*5,h+16)],pose,tint.darkened(.32),.0,false)
			_volume(c,Vector3(29+x,0,h+3-jaw),Vector3(8,4.4,2.7),pose,tint.lightened(.23),false)
			_volume(c,Vector3(30+x,0,h+7),Vector3(9,5.2,4.1),pose,tint.lightened(.19),false)
			_volume(c,Vector3(37+x,0,h+7),Vector3(2.8,3.4,2.7),pose,INK,false)
			if front:
				for side in [-near,near]:
					if side*Vector2(pose["side"]).y < -.68: continue
					_eye(c,Vector3(23+x,side*6.5,h+12),pose,1.45,Color("d4af64"))
					_line(c,[Vector3(19+x,side*6,h+15),Vector3(23+x,side*6.5,h+14),Vector3(25+x,side*5,h+13)],pose,INK,1.3)
					_line(c,[Vector3(27+x,side*4.5,h+4),Vector3(32+x,side*3.9,h+4),Vector3(36+x,side*2,h+5)],pose,INK,.9)
					if jaw>.5: _shape(c,[Vector3(28+x,side*4.5,h+5),Vector3(29+x,side*4.5,h+1-jaw),Vector3(30+x,side*4.5,h+5)],pose,LIGHT,.45,false)
			if elite:
				_shape(c,[Vector3(17+x,-2,h+17),Vector3(19+x,0,h+21),Vector3(24+x,0,h+16),Vector3(22+x,2,h+16)],pose,Color("e2dec2"),.65,false)
		"boar":
			_volume(c,Vector3(17+x,0,h+1),Vector3(13,10,10),pose,tint.lightened(.1))
			for side in [-near,near]:
				_shape(c,[Vector3(10+x,side*8,h+6),Vector3(13+x,side*16,h+14),Vector3(21+x,side*11,h+5)],pose,tint.darkened(.09),1.2)
			_volume(c,Vector3(29+x,0,h-1),Vector3(9,8,5),pose,tint.lightened(.23))
			for side in [-1,1]:
				if front: _volume(c,Vector3(35+x,side*3,h),Vector3(1.2,1.4,1.4),pose,INK,false)
				_shape(c,[Vector3(25+x,side*7,h-4),Vector3(31+x,side*13,h-2),Vector3(34+x,side*12,h+8),Vector3(30+x,side*10,h+1),Vector3(26+x,side*8,h)],pose,LIGHT,1.0)
				if front and side*Vector2(pose["side"]).y>-.7: _eye(c,Vector3(23+x,side*8,h+6),pose,1.3,Color("c89152"))
		"spider":
			_volume(c,Vector3(15+x,0,h),Vector3(8,7,6),pose,tint.darkened(.22))
			for side in [-1,1]:
				_shape(c,[Vector3(19+x,side*4,h+1),Vector3(27+x,side*(7+jaw),h-1),Vector3(26+x,side*3,h-6),Vector3(23+x,side*4,h-3),Vector3(21+x,side*2,h)],pose,LIGHT.darkened(.18),1.05)
				if front:
					_eye(c,Vector3(20+x,side*3,h+4),pose,1.8,Color("c9a085"))
					_eye(c,Vector3(17+x,side*5.5,h+5),pose,.9,Color("c9a085"))
		"hornet":
			_volume(c,Vector3(16+x,0,h+2),Vector3(9,8,8),pose,tint.lightened(.1))
			for side in [-near,near]:
				_line(c,[Vector3(20+x,side*3,h+7),Vector3(25+x,side*7,h+12),Vector3(32+x,side*8,h+13)],pose,INK,1.3)
				if front and side*Vector2(pose["side"]).y>-.7:
					_volume(c,Vector3(19+x,side*6,h+4),Vector3(3.5,2.5,4.5),pose,Color("604b3d"),false)
					_eye(c,Vector3(21+x,side*6,h+6),pose,1.2,LIGHT)
				_shape(c,[Vector3(22+x,side*3,h),Vector3(29+x,side*5,h-3),Vector3(25+x,side*1.5,h-4)],pose,LIGHT,.85,false)
		"toad":
			_volume(c,Vector3(14+x,0,h),Vector3(15,14,9),pose,tint.lightened(.12))
			var throat := 3.7+float(pose["load"])*2
			_volume(c,Vector3(18+x,0,h-5),Vector3(10,10,throat),pose,tint.lightened(.3),false)
			for side in [-near,near]:
				_volume(c,Vector3(17+x,side*9,h+7),Vector3(6,5,5),pose,tint.lightened(.18),false)
				if front: _eye(c,Vector3(20+x,side*10,h+9),pose,2.8,Color("ddbf6c"))
			if front: _line(c,[Vector3(23+x,-10,h-1),Vector3(28+x,-5,h-3-jaw),Vector3(29+x,0,h-3-jaw),Vector3(28+x,5,h-3-jaw),Vector3(23+x,10,h-1)],pose,INK,1.4)
		"beetle":
			_volume(c,Vector3(16+x,0,h+1),Vector3(10,10,7),pose,tint.darkened(.12))
			for side in [-near,near]:
				_shape(c,[Vector3(22+x,side*5,h),Vector3(30+x,side*(12+jaw),h+3),Vector3(39+x,side*6,h+5),Vector3(33+x,side*7,h),Vector3(29+x,side*4,h-3),Vector3(24+x,side*3,h-3)],pose,LIGHT.darkened(.12),1.35,false)
				_line(c,[Vector3(21+x,side*8,h+5),Vector3(27+x,side*11,h+9),Vector3(33+x,side*14,h+9)],pose,INK,1.1)
				if front and side*Vector2(pose["side"]).y>-.7: _eye(c,Vector3(22+x,side*6,h+5),pose,1.3,Color("adc3a9"))
			if elite: _shape(c,[Vector3(15+x,-3,h+7),Vector3(20+x,0,h+24),Vector3(23+x,3,h+8)],pose,Color("c4ceb8"),1.4,false)

static func _eye(c: CanvasItem, at: Vector3, pose: Dictionary, radius: float, tint: Color) -> void:
	if float(pose["death"])>.25:
		_line(c,[at+Vector3(-radius,0,0),at+Vector3(radius,0,0)],pose,INK,1.1)
		return
	var p := _p(at,pose)
	c.draw_circle(p,radius+1,INK,true,-1,true)
	c.draw_circle(p+Vector2(.3,-.25),radius,tint,true,-1,true)
	c.draw_circle(p+Vector2(.45,-.15),radius*.43,INK,true,-1,true)
	c.draw_circle(p+Vector2(-.2,-.5),maxf(.35,radius*.21),LIGHT,true,-1,true)

static func _draw_wings(c: CanvasItem, pose: Dictionary, _tint: Color) -> void:
	var h: float = pose["height"]+4
	var flap := 0.0 if pose["reduced"] else sin(float(pose["phase"])*35)*3
	var fold := float(pose["death"])
	for side in [-1,1]:
		var spread := lerpf(21+flap,6,fold)
		_shape(c,[Vector3(4,side*3,h),Vector3(-7,side*spread,h+7),Vector3(-24,side*(spread*.92),h+8),Vector3(-18,side*9,h+4),Vector3(-5,side*5,h+1)],pose,Color(.85,.85,.72,.68),.75)
		_line(c,[Vector3(2,side*4,h+1),Vector3(-8,side*11,h+5),Vector3(-22,side*(spread*.9),h+8)],pose,Color(.35,.38,.30,.65),.65)
		_line(c,[Vector3(-9,side*11,h+5),Vector3(-10,side*(spread*.95),h+7)],pose,Color(.35,.38,.30,.45),.55)

static func telegraph(c: CanvasItem, state: Dictionary, spec: Dictionary) -> void:
	var attack := Bestiary.attack(state) if state.has("species") else spec
	var geometry: Dictionary = state.get("attack_geometry",{})
	if geometry.is_empty():
		var copy := state.duplicate()
		if not copy.has("aim"): copy["aim"]=Vector2(state["cell"])+Vector2(state.get("facing",Vector2.RIGHT))*float(attack["range"])
		geometry=Footprint.build(copy,attack)
	var duration: float = state.get("windup_duration",attack["windup"])
	var t := clampf(1-float(state.get("windup_left",duration))/maxf(.001,duration),0,1)
	var at: Vector2 = state["cell"]
	for polygon in Footprint.polygons(geometry):
		var screen := PackedVector2Array()
		for point in polygon: screen.append(WorldGrid.project(point-at))
		c.draw_colored_polygon(screen,Color(.74,.30,.16,.10+.13*t))
		c.draw_polyline(screen,Color("b46039"),1.3,true)
		# Sequentially illuminated perimeter measures the remaining response window.
		var progress := PackedVector2Array()
		for i in range(maxi(2,ceili(screen.size()*t))): progress.append(screen[mini(i,screen.size()-1)])
		c.draw_polyline(progress,Color("f1cf8d"),1.8,true)
	var title: String = attack.get("name","")
	if not title.is_empty():
		c.draw_string(GuPixelUI.HAND_FONT,Vector2(-62,-65 if spec.get("elite",false) else -51),title,HORIZONTAL_ALIGNMENT_CENTER,124,10,Color("eed3a2"))
