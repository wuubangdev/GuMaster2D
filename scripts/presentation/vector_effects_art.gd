class_name GuVectorEffectsArt
extends RefCounted
## Original illustrated spell grammar, drawn in native canvas coordinates.
## Continuous curves and broad silhouettes remain readable at gameplay scale.
## No timers, random state, simulation writes or raster atlas dependency.

const KINDS: Array[String] = ["moon_blade", "moon_impact", "ice_shard", "ice_impact", "shield_cast", "shield_loop", "dash_wake", "dash_feather", "cast_spark", "moon_charge", "frost_charge", "hit_spark", "dust", "seal", "reward"]
const INK := Color("302b25")
const JADE := Color("9da97e")
const JADE_LIGHT := Color("e4dfb9")
const JADE_DARK := Color("47594b")
const ICE := Color("9baeb0")
const ICE_LIGHT := Color("e2dfc9")
const GOLD := Color("b59b69")
const GOLD_LIGHT := Color("e3d1a2")

static func draw(canvas: CanvasItem, kind: String, at: Vector2, ratio: float, direction: Vector2 = Vector2.RIGHT, tint: Color = Color.WHITE) -> void:
	if tint.a <= 0.001:
		return
	var progress := clampf(ratio, 0.0, 1.0)
	var angle := direction.angle() if direction.length_squared() > 0.0001 else 0.0
	match kind:
		"moon_blade": _moon_blade(canvas, at, progress, angle, tint)
		"moon_impact": _moon_impact(canvas, at, progress, tint)
		"ice_shard": _ice_shard(canvas, at, progress, angle, tint)
		"ice_impact": _ice_impact(canvas, at, progress, tint)
		"shield_cast": _shield(canvas, at, progress, tint, true)
		"shield_loop": _shield(canvas, at, progress, tint, false)
		"dash_wake": _dash_wake(canvas, at, progress, angle, tint)
		"dash_feather": _feather(canvas, at, progress, angle, tint)
		"cast_spark": _cast_spark(canvas, at, progress, tint)
		"moon_charge": _gu_charge(canvas, at, progress, angle, tint, false)
		"frost_charge": _gu_charge(canvas, at, progress, angle, tint, true)
		"hit_spark": _hit_spark(canvas, at, progress, tint)
		"dust": _dust(canvas, at, progress, tint)
		"seal": _seal(canvas, at, progress, tint)
		"reward": _reward(canvas, at, progress, tint)

static func ground_shadow(canvas: CanvasItem, at: Vector2, width: float, tint: Color) -> void:
	_ellipse(canvas, at, Vector2(width + 3.0, 5.3), tint * Color(1, 1, 1, .15))
	_ellipse(canvas, at, Vector2(width, 3.8), tint * Color(1, 1, 1, .7))

static func _mapped(points: PackedVector2Array, at: Vector2, angle: float = 0.0) -> PackedVector2Array:
	var output := PackedVector2Array()
	for point in points:
		output.append(at + point.rotated(angle))
	return output

static func ink_stroke(points: PackedVector2Array, width: float) -> PackedVector2Array:
	# Pressure and small pen deviations are attached to the stroke geometry,
	# never randomized by the draw clock. Keep its authored endpoints exact.
	var source := points
	if source.size()==2:
		source = PackedVector2Array()
		for i in range(9):
			source.append(points[0].lerp(points[1],float(i)/8))
	var outline := PackedVector2Array()
	if source.size()<2:
		return outline
	for edge in [1.0,-1.0]:
		for step in range(source.size()):
			var i := step if edge>0 else source.size()-1-step
			var t := float(i)/(source.size()-1)
			var previous := maxi(i-1,0)
			var next := mini(i+1,source.size()-1)
			if source[0].is_equal_approx(source[source.size()-1]) and i in [0,source.size()-1]:
				previous = source.size()-2
				next = 1
			var tangent := (source[next]-source[previous]).normalized()
			var normal := Vector2(tangent.y,-tangent.x)
			var pressure := .52+.40*sin(t*PI)+.08*sin(t*PI*5)
			var deviation := sin(t*PI)*sin(t*PI*4.3)*minf(.30,width*.12)
			outline.append(source[i]+normal*(deviation+width*.5*pressure*edge))
	return outline

static func _line(canvas: CanvasItem, points: PackedVector2Array, at: Vector2, angle: float, color: Color, width: float = 1.4) -> void:
	if color.a <= .001 or points.size()<2:
		return
	_paint_stroke(canvas,points,at,angle,INK*Color(1,1,1,color.a*.82),width+1.1)
	_paint_stroke(canvas,points,at,angle,color,width)

static func _paint_stroke(canvas: CanvasItem, points: PackedVector2Array, at: Vector2, angle: float, color: Color, width: float) -> void:
	var ribbon := _mapped(ink_stroke(points,width),at,angle)
	var feather := _mapped(ink_stroke(points,width+1.4),at,angle)
	var n: int = ribbon.size()/2
	var vertices := ribbon.duplicate()
	vertices.append_array(feather)
	var colors := PackedColorArray()
	for i in range(2*n):
		colors.append(color)
	for i in range(2*n):
		colors.append(Color(color,0))
	var indices := PackedInt32Array()
	for i in range(n-1):
		var opposite := 2*n-1-i
		# Core and two continuous feather strips share their vertices.
		# Submit one triangle array per stroke instead of hundreds of tiny
		# native primitives. Alpha edges remain smooth at gameplay zoom.
		for quad in [[i,i+1,opposite-1,opposite], [2*n+i,2*n+i+1,i+1,i], [opposite,opposite-1,2*n+opposite-1,2*n+opposite]]:
			indices.append_array(PackedInt32Array([quad[0],quad[1],quad[2],quad[0],quad[2],quad[3]]))
	RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(),indices,vertices,colors)

static func _shape(canvas: CanvasItem, points: PackedVector2Array, at: Vector2, angle: float, fill: Color, outline: Color = Color.TRANSPARENT, width: float = 1.0) -> void:
	if points.size() < 3 or fill.a <= .001:
		return
	var mapped := _mapped(points, at, angle)
	canvas.draw_colored_polygon(mapped, fill)
	mapped.append(mapped[0])
	# A subtle matching edge also antialiases filled silhouettes.
	var closed := points.duplicate()
	closed.append(points[0])
	_paint_stroke(canvas,closed,at,angle,INK*Color(1,1,1,fill.a*.90),width+.65)
	if outline.a>.001:
		_line(canvas,closed,at,angle,outline,width*.45)

static func _ellipse_points(radii: Vector2, samples: int = 36) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(samples):
		var angle := TAU * float(i) / float(samples)
		var uneven := 1+.028*sin(angle*3+.4)+.018*sin(angle*7-.3)
		points.append(Vector2(cos(angle) * radii.x, sin(angle) * radii.y)*uneven)
	return points

static func _ellipse(canvas: CanvasItem, at: Vector2, radii: Vector2, color: Color, angle: float = 0.0) -> void:
	_shape(canvas, _ellipse_points(radii), at, angle, color, Color.TRANSPARENT, .65)

static func _arc(radii: Vector2, from: float, to: float, count: int = 32) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(count + 1):
		var angle := lerpf(from, to, float(i) / float(count))
		points.append(Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points

static func _curve(a: Vector2, b: Vector2, c: Vector2, d: Vector2, samples: int = 24) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(samples + 1):
		var t := float(i) / float(samples)
		var inverse := 1.0 - t
		points.append(a * inverse * inverse * inverse + b * 3.0 * inverse * inverse * t + c * 3.0 * inverse * t * t + d * t * t * t)
	return points

static func _halo(canvas: CanvasItem, at: Vector2, radii: Vector2, color: Color, angle: float = 0.0) -> void:
	# Broken pen arcs replace concentric bloom discs, leaving the actor clear.
	_line(canvas,_arc(radii*1.08,-2.7,-1.1,12),at,angle,color*Color(1,1,1,.18),.85)
	_line(canvas,_arc(radii,.15,1.15,10),at,angle,color*Color(1,1,1,.16),.65)

static func _spark(canvas: CanvasItem, at: Vector2, radius: float, color: Color, angle: float = 0.0) -> void:
	var points := PackedVector2Array()
	for i in range(14):
		var theta := -PI/2+float(i)*TAU/14
		var span := radius*(1+.13*sin(i*2.4)) if i%2==0 else radius*.28
		points.append(Vector2(cos(theta),sin(theta))*span)
	_shape(canvas, points, at, angle, color, Color.TRANSPARENT, .65)

static func _moon_blade(canvas: CanvasItem, at: Vector2, progress: float, angle: float, tint: Color) -> void:
	# A single hooked wing edge carries the projectile, with two tapering silk
	# strokes; a hollow silhouette leaves the target and environment readable.
	var pulse := 1.0 + .025 * sin(progress * PI)
	var crescent := _curve(Vector2(1,-26),Vector2(31,-19),Vector2(31,19),Vector2(1,26))
	crescent.append_array(_curve(Vector2(1,26),Vector2(17,10),Vector2(17,-10),Vector2(1,-26)))
	for i in range(crescent.size()): crescent[i] *= pulse
	_shape(canvas,crescent,at,angle,JADE*tint,JADE_DARK*tint,1.1)
	_line(canvas,_curve(Vector2(6,-22),Vector2(25,-16),Vector2(25,16),Vector2(6,22)),at,angle,JADE_LIGHT*tint,2.3)
	for side in [-1,1]:
		var trail := _curve(Vector2(6,side*24),Vector2(-8,side*29),Vector2(-31,side*8),Vector2(-46,side*11))
		_line(canvas,trail,at,angle,JADE*Color(1,1,1,.52)*tint,1.7)
		_line(canvas,_curve(Vector2(12,side*15),Vector2(16,side*12),Vector2(17,side*10),Vector2(20,side*8)),at,angle,JADE_DARK*tint,.8)

static func _moon_impact(canvas: CanvasItem, at: Vector2, progress: float, tint: Color) -> void:
	var spread := 1.0-pow(1.0-progress,2.6)
	var color := tint*Color(1,1,1,pow(1.0-progress,1.3))
	for side in [-1,1]:
		var shift := Vector2(side*(3+spread*10),-side*spread*3)
		var slash := _curve(Vector2(-10,-20),Vector2(16,-20),Vector2(23,6),Vector2(-7,21))
		for i in range(slash.size()): slash[i]=slash[i]*Vector2(side,1)*(1-spread*.35)
		_line(canvas,slash,at+shift,side*.16,JADE*color,3.3*(1-progress)+.6)
		_line(canvas,slash,at+shift,side*.16,JADE_LIGHT*color,1.15)
	for i in range(3):
		var angle := -1.8+i*2.1
		var chip_at := at+Vector2.from_angle(angle)*(8+spread*24)
		_shape(canvas,PackedVector2Array([Vector2(-3,0),Vector2(1,-2),Vector2(4,0),Vector2(0,1)]),chip_at,angle,JADE_LIGHT*color,Color.TRANSPARENT,.6)
	if progress<.42:
		_spark(canvas,at,8*(1-progress/.42)+1,JADE_LIGHT*color,.2)

static func _ice_shard(canvas: CanvasItem, at: Vector2, progress: float, angle: float, tint: Color) -> void:
	# The silkworm's frozen cocoon becomes an elongated spindle, wrapped with
	# one continuous filament. Its outline stays unlike the moon's crescent.
	var shell := _curve(Vector2(-22,0),Vector2(-13,-15),Vector2(5,-10),Vector2(29,0))
	shell.append_array(_curve(Vector2(29,0),Vector2(5,10),Vector2(-13,15),Vector2(-22,0)))
	_shape(canvas,shell,at,angle,ICE*tint,Color("536e69")*tint,1.1)
	_shape(canvas,PackedVector2Array([Vector2(-8,-8),Vector2(29,0),Vector2(-3,1),Vector2(-18,0)]),at,angle,ICE_LIGHT*tint)
	for i in range(3):
		var x := -14.0+i*8
		_line(canvas,_curve(Vector2(x,-6),Vector2(x+8,-5),Vector2(x+8,5),Vector2(x,7)),at,angle,Color("506d68")*tint,.9)
	for side in [-1,1]:
		_line(canvas,_curve(Vector2(-17,side*4),Vector2(-29,side*12),Vector2(-40,-side*10),Vector2(-51,side*4)),at,angle,ICE_LIGHT*tint*Color(1,1,1,.48),1.05)

static func _ice_impact(canvas: CanvasItem, at: Vector2, progress: float, tint: Color) -> void:
	var ease := 1.0 - pow(1.0 - progress, 2.4)
	var color := tint * Color(1, 1, 1, pow(1.0 - progress, .8))
	_halo(canvas, at, Vector2.ONE * (15 + ease * 17), ICE * color)
	for i in range(6):
		var angle := -PI * .5 + float(i) * TAU / 6.0
		var shard_at := at + Vector2.RIGHT.rotated(angle) * (5 + ease * 13)
		var length := (11 + (i % 2) * 5) * (1.0 - progress * .4)
		var crystal := PackedVector2Array([Vector2(-length * .4, -3.8), Vector2(length, 0), Vector2(-length * .4, 3.8), Vector2(-length * .75, 0)])
		_shape(canvas, crystal, shard_at, angle, ICE * color, Color("657770") * color, .9)
		_line(canvas, PackedVector2Array([Vector2(-length * .6, 0), Vector2(length, 0)]), shard_at, angle, ICE_LIGHT * color, 1.4)
	_spark(canvas, at, 15 * (1.0 - progress) + 2, ICE_LIGHT * color)
	_line(canvas, _arc(Vector2.ONE * (12 + ease * 22), -.9, .25), at, 0.0, ICE * color * Color(1, 1, 1, .35), 1.3)

static func _shield(canvas: CanvasItem, at: Vector2, progress: float, tint: Color, casting: bool) -> void:
	# Split scarab elytra lock around the body. Never paint a filled disc over
	# the character: center remains transparent throughout guard and casting.
	var unfurl := smoothstep(0.0,.30,progress) if casting else 1.0
	var span := lerpf(12,26,unfurl)
	for side in [-1,1]:
		var plate := _curve(Vector2(side*8,-27),Vector2(side*(span+5),-24),Vector2(side*(span+8),6),Vector2(side*9,29))
		plate.append_array(_curve(Vector2(side*9,29),Vector2(side*(span-7),7),Vector2(side*(span-7),-18),Vector2(side*8,-27)))
		_shape(canvas,plate,at,0,GOLD*tint*Color(1,1,1,.26),GOLD*tint*.9,1.2)
		_line(canvas,_curve(Vector2(side*11,-25),Vector2(side*(span+2),-15),Vector2(side*(span+3),6),Vector2(side*11,24)),at,0,GOLD_LIGHT*tint,1.55)
		for j in range(3):
			var y := -12.0+j*12
			_line(canvas,PackedVector2Array([Vector2(side*(span-2),y),Vector2(side*(span-7),y+4)]),at,0,GOLD*tint,.9)
	var crest := PackedVector2Array([Vector2(0,-35),Vector2(5,-30),Vector2(0,-22),Vector2(-5,-30)])
	_shape(canvas,crest,at,0,GOLD_LIGHT*tint,Color("526654")*tint,1)
	if casting and progress<.4:
		for side in [-1,1]:
			_line(canvas,_curve(Vector2(side*3,-31),Vector2(side*14,-41),Vector2(side*17,-29),Vector2(side*25,-35)),at,0,GOLD_LIGHT*tint*Color(1,1,1,(1-progress/.4)*.65),1.1)

static func _feather(canvas: CanvasItem, at: Vector2, progress: float, angle: float, tint: Color) -> void:
	# Split primary feathers echo the long wing of Bach Hac; their tips curve
	# back with the wake rather than looking like rigid leaf particles.
	var roll := angle + .18*sin(progress*PI)
	var wing := _curve(Vector2(-15,4),Vector2(-7,0),Vector2(-8,-6),Vector2(2,-11))
	wing.append_array(_curve(Vector2(2,-11),Vector2(0,-6),Vector2(1,-6),Vector2(4,-6)))
	wing.append_array(_curve(Vector2(4,-6),Vector2(7,-6),Vector2(9,-9),Vector2(14,-10)))
	wing.append_array(_curve(Vector2(14,-10),Vector2(13,-4),Vector2(7,0),Vector2(4,1)))
	wing.append_array(_curve(Vector2(4,1),Vector2(0,2),Vector2(-8,7),Vector2(-15,4)))
	_shape(canvas,wing,at,roll,Color("dcdcc0")*tint,Color("637c6c")*tint,.70)
	_line(canvas,_curve(Vector2(-14,4),Vector2(-6,1),Vector2(3,-1),Vector2(11,-7)),at,roll,Color("788e7b")*tint,1)
	_line(canvas,_curve(Vector2(-5,2),Vector2(-2,0),Vector2(-1,-5),Vector2(1,-8)),at,roll,Color("afbea4")*tint,.8)
	_line(canvas,_curve(Vector2(0,0),Vector2(4,1),Vector2(7,-2),Vector2(10,-3)),at,roll,Color("f0e7c5")*tint,.75)

static func _dash_wake(canvas: CanvasItem, at: Vector2, progress: float, angle: float, tint: Color) -> void:
	for i in range(2):
		var side := -1.0 if i==0 else 1.0
		var shift := progress*7
		var curve := _curve(Vector2(-23+shift,side*4),Vector2(-14+shift,side*6),Vector2(0,side*2),Vector2(10,side))
		_line(canvas,curve,at,angle,ICE*Color(1,1,1,.16)*tint,2.2)
		_line(canvas,curve,at,angle,ICE_LIGHT*Color(1,1,1,.48)*tint,.9)

static func _gu_charge(canvas: CanvasItem, at: Vector2, progress: float, angle: float, tint: Color, frost: bool) -> void:
	# Two small wings / silk curls converge onto the actual weapon hand.
	var gathering := smoothstep(0.0,1.0,progress)
	var spread := lerpf(12.0,3.0,gathering)
	var color := ICE if frost else JADE
	var light := ICE_LIGHT if frost else JADE_LIGHT
	for side in [-1,1]:
		var wing := _curve(Vector2(-2,side*2),Vector2(-spread,side*(spread+6)),Vector2(spread*.8,side*(spread+6)),Vector2(spread*.5,side*2))
		if frost:
			_line(canvas,wing,at,angle,color*tint,1.2+gathering*.6)
		else:
			wing.append(Vector2(-2,side*2))
			_shape(canvas,wing,at,angle,color*tint*Color(1,1,1,.65),Color.TRANSPARENT,.65)
		_line(canvas,_curve(Vector2(-spread-4,side*5),Vector2(-spread,side*7),Vector2(-3,side*5),Vector2(1,0)),at,angle,light*tint*Color(1,1,1,.65),.85)
	var seed := PackedVector2Array([Vector2(-3,0),Vector2(0,-2-gathering*2),Vector2(5+gathering*2,0),Vector2(0,2+gathering*2)])
	_shape(canvas,seed,at,angle,light*tint,Color.TRANSPARENT,.65)

static func _cast_spark(canvas: CanvasItem, at: Vector2, progress: float, tint: Color) -> void:
	var radius := 3.5 + sin(progress * PI) * 4.5
	_halo(canvas, at, Vector2.ONE * 10, JADE * tint)
	_spark(canvas, at, radius, JADE_LIGHT * tint, .3)
	for i in range(3):
		var angle := float(i) * TAU / 3 + .4
		var distance := 13 * (1.0 - progress) + 3
		_ellipse(canvas, at + Vector2.RIGHT.rotated(angle) * distance, Vector2.ONE * 1.5, JADE * tint)

static func _hit_spark(canvas: CanvasItem, at: Vector2, progress: float, tint: Color) -> void:
	var ease := 1.0 - pow(1.0 - progress, 3.0)
	var color := tint * Color(1, 1, 1, 1.0 - progress * .65)
	_spark(canvas, at, 10 * (1.0 - progress) + 3, GOLD_LIGHT * color, -.3)
	for i in range(5):
		var angle := float(i) * TAU / 5 + .2
		_line(canvas, PackedVector2Array([Vector2(6 + ease * 3, 0), Vector2(11 + ease * 13, 0)]), at, angle, GOLD * color, 1.8 * (1.0 - progress) + .6)

static func _dust(canvas: CanvasItem, at: Vector2, progress: float, tint: Color) -> void:
	var p := clampf(progress,0,1)
	var color := Color("aa9772")*tint*Color(1,1,1,pow(1-p,2)*.30)
	for i in range(3):
		var side := float(i)-1
		var center := at+Vector2(side*(2+p*5),-sin(p*PI)*(1.5+(i%2)))
		_ellipse(canvas,center,Vector2(1.8+p*1.6,.9+p*.8),color)

static func _seal(canvas: CanvasItem, at: Vector2, progress: float, tint: Color) -> void:
	var radii := Vector2(23, 8)
	var circle := _ellipse_points(radii, 48)
	circle.append(circle[0])
	_line(canvas, circle, at, 0.0, GOLD * tint * Color(1, 1, 1, .6), 1.5)
	for i in range(4):
		var angle := float(i) * PI / 2 + PI / 4
		var mark_at := at + Vector2(cos(angle) * 23, sin(angle) * 8)
		_shape(canvas, PackedVector2Array([Vector2(0, -3.5), Vector2(2.3, 0), Vector2(0, 3.5), Vector2(-2.3, 0)]), mark_at, 0.0, GOLD_LIGHT * tint)
	var alpha := .3 + .2 * sin(progress * TAU)
	_line(canvas, PackedVector2Array([Vector2(-8, 0), Vector2(0, -3), Vector2(8, 0), Vector2(0, 3), Vector2(-8, 0)]), at, 0.0, GOLD_LIGHT * tint * Color(1, 1, 1, alpha), 1.0)

static func _reward(canvas: CanvasItem, at: Vector2, progress: float, tint: Color) -> void:
	var lift := 9 * (1.0 - pow(1.0 - progress, 2))
	_halo(canvas, at + Vector2(0, -lift), Vector2(15, 18), GOLD * tint)
	_spark(canvas, at + Vector2(0, -lift), 10 - progress * 3, GOLD_LIGHT * tint)
	for i in range(4):
		var angle := float(i) * TAU / 4 + .5
		var point := at + Vector2(cos(angle) * (12 + progress * 8), sin(angle) * (12 + progress * 8) - lift)
		_spark(canvas, point, 2.8, GOLD_LIGHT * tint, angle)
