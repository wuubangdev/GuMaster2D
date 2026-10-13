class_name GuWolfPainter
extends RefCounted
## Original vector artwork, drawn inside ActorView's existing facing/bob transform.
## Leg articulation follows the actor's travelled-distance stride; no gameplay state.

static func draw(canvas: CanvasItem, coat: Color, leg: float = 0.0, stride: float = 0.0, motion: float = 1.0, windup: float = 0.0) -> void:
	var gait := clampf(leg, -5.0, 5.0)
	var near_lift := maxf(0.0, cos(stride)) * 2.5 * motion
	var far_lift := maxf(0.0, -cos(stride)) * 2.5 * motion
	var crouch := clampf(windup, 0.0, 1.0)
	var shadow := coat.darkened(0.34)
	var middle := coat.darkened(0.15)
	var highlight := coat.lightened(0.19)
	# Far limbs first. Diagonal front/rear pairs alternate instead of sliding the
	# whole creature, with separate knee/hock flex and lifted swing-phase paws.
	_leg(canvas, Vector2(-11, -14), -gait, far_lift, shadow, true, true, crouch)
	_leg(canvas, Vector2(10, -17), gait, near_lift, shadow, false, true, crouch)
	_tail(canvas, coat, sin(stride + 0.5) * motion, crouch)
	var body := [Vector2(-18, -18), Vector2(-15, -24), Vector2(-7, -26), Vector2(2, -25), Vector2(10, -23), Vector2(14, -18), Vector2(12, -11), Vector2(5, -9), Vector2(-4, -10), Vector2(-13, -12)]
	_fill(canvas, body, coat)
	_fill(canvas, [Vector2(-16, -20), Vector2(-13, -24), Vector2(-5, -25.3), Vector2(4, -24.0), Vector2(11, -22), Vector2(9, -18), Vector2(2, -17), Vector2(-6, -19)], middle)
	_fill(canvas, [Vector2(-12, -16), Vector2(-4, -15), Vector2(5, -14), Vector2(12, -16), Vector2(11, -11), Vector2(4, -9.4), Vector2(-6, -11)], coat.lightened(0.12))
	_fill(canvas, [Vector2(-15, -18), Vector2(-12, -22), Vector2(-7, -23), Vector2(-6, -17), Vector2(-10, -12.5), Vector2(-15, -14)], coat.lightened(0.07))
	# Subtle fur strokes follow anatomy rather than forming a uniform hatch.
	_fur(canvas, [Vector2(-13, -21), Vector2(-9, -23), Vector2(-4, -23.8), Vector2(1, -23), Vector2(6, -22)], Vector2(-3, 1.2), Color(highlight, 0.55))
	_fur(canvas, [Vector2(-13, -17), Vector2(-11, -15), Vector2(-8, -14)], Vector2(-2.4, 2), Color(highlight, 0.25))
	_leg(canvas, Vector2(-13, -14), gait, near_lift, middle, true, false, crouch)
	_leg(canvas, Vector2(8, -17), -gait, far_lift, middle, false, false, crouch)
	# Overlapping shoulder/chest hides the leg joint and forms a distinct neck.
	_fill(canvas, [Vector2(5, -23), Vector2(10, -27), Vector2(16, -27), Vector2(20, -22), Vector2(17, -16), Vector2(13, -11), Vector2(7, -13), Vector2(6, -18)], coat.lightened(0.05))
	_fill(canvas, [Vector2(14, -23), Vector2(17, -21), Vector2(16, -16), Vector2(12, -11.6), Vector2(9, -13), Vector2(11, -17)], coat.lightened(0.22))
	_fur(canvas, [Vector2(11, -18), Vector2(12, -15), Vector2(15, -20)], Vector2(-1.6, 2.1), Color(highlight, 0.6))
	_head(canvas, coat, crouch)

static func _leg(canvas: CanvasItem, hip: Vector2, swing: float, lift: float, color: Color, hind: bool, far: bool, crouch: float) -> void:
	var knee: Vector2
	var ankle: Vector2
	var paw: Vector2
	if hind:
		knee = hip + Vector2(4.2 + swing * 0.27, 5.6 + crouch)
		ankle = Vector2(hip.x - 2.9 + swing * 0.65, -3.0 - lift * 0.36)
		paw = Vector2(hip.x + 0.8 + swing, 0.4 - lift)
	else:
		knee = hip + Vector2(1.2 + swing * 0.19, 7.0 + crouch)
		ankle = Vector2(hip.x + swing * 0.64, -3.0 - lift * 0.45)
		paw = Vector2(hip.x + 2.8 + swing, 0.4 - lift)
	if far:
		paw.y -= 1.2
	var width := 3.4 if far else 4.0
	canvas.draw_line(hip, knee, color, width + 1.1, true)
	canvas.draw_circle(knee, width * 0.52, color)
	canvas.draw_line(knee, ankle, color, width * 0.77, true)
	canvas.draw_circle(ankle, width * 0.39, color)
	canvas.draw_line(ankle, paw + Vector2(-0.7, -0.6), color, width * 0.70, true)
	_fill(canvas, [paw + Vector2(-2.7, -1.5), paw + Vector2(0.2, -2), paw + Vector2(3.7, -0.8), paw + Vector2(3.6, 1), paw + Vector2(-2.3, 1)], color.lightened(0.055))
	if not far:
		canvas.draw_line(knee + Vector2(-0.7, -2), ankle + Vector2(-0.5, -0.7), Color(color.lightened(0.23), 0.55), 0.7, true)
		for toe in range(2):
			var start := paw + Vector2(1.5 + toe * 1.1, -0.7)
			canvas.draw_line(start, start + Vector2(-0.2, 1), Color(color.darkened(0.45), 0.55), 0.55, true)

static func _tail(canvas: CanvasItem, coat: Color, sway: float, crouch: float) -> void:
	var tip := Vector2(-30.5, -20 + sway * 1.2 + crouch)
	_fill(canvas, [Vector2(-15.5, -20), Vector2(-20, -22), Vector2(-24, -23.2 + sway), tip, Vector2(-28, -15.5 + sway), Vector2(-24, -13.7), Vector2(-18, -14)], coat.darkened(0.20))
	_fill(canvas, [Vector2(-18, -20), Vector2(-23, -22.2 + sway), tip + Vector2(0.8, 0.8), Vector2(-25, -18.8 + sway), Vector2(-20, -17.5)], coat.lightened(0.03))
	_fur(canvas, [Vector2(-21, -18), Vector2(-24, -18.5 + sway), Vector2(-26, -19.4 + sway)], Vector2(-2.7, 1.2), Color(coat.lightened(0.19), 0.35))

static func _head(canvas: CanvasItem, coat: Color, crouch: float) -> void:
	var dip := Vector2(crouch * 1.2, crouch * 1.3)
	# Back ear, elongated canine muzzle and larger near ear are separate shapes.
	_fill(canvas, [Vector2(13, -27), Vector2(11.4, -32.8), Vector2(15.2, -31), Vector2(18, -27.5)], coat.darkened(0.26))
	_fill(canvas, [Vector2(14, -28) + dip, Vector2(19, -30) + dip, Vector2(24, -26) + dip, Vector2(26, -23) + dip, Vector2(31, -21.5) + dip, Vector2(30.7, -18.7) + dip, Vector2(25, -17.5) + dip, Vector2(19, -16) + dip, Vector2(14, -20) + dip], coat.lightened(0.1))
	_fill(canvas, [Vector2(15, -28), Vector2(16.3, -34), Vector2(19.5, -30.1), Vector2(19, -25.8)], coat.lightened(0.13))
	_fill(canvas, [Vector2(16.4, -29.3), Vector2(16.7, -32.3), Vector2(18.3, -29), Vector2(17.9, -27.6)], coat.darkened(0.32))
	_fill(canvas, [Vector2(21, -22) + dip, Vector2(26, -22.9) + dip, Vector2(30.9, -21.3) + dip, Vector2(30.3, -19) + dip, Vector2(25, -17.7) + dip, Vector2(20.5, -18.5) + dip], coat.lightened(0.25))
	_fill(canvas, [Vector2(29.6, -21.8) + dip, Vector2(31.6, -21.2) + dip, Vector2(31.1, -19.5) + dip, Vector2(29.8, -19.5) + dip], Color("26352e"))
	canvas.draw_polyline(PackedVector2Array([Vector2(21.3, -19) + dip, Vector2(25, -18.7) + dip, Vector2(29.8, -19.5) + dip]), Color(0.15, 0.20, 0.16, 0.8), 0.75, true)
	var eye := Vector2(23, -24.9) + dip
	canvas.draw_line(eye + Vector2(-1.5, -0.3), eye + Vector2(1.1, 0.2), coat.darkened(0.48), 1.8, true)
	canvas.draw_circle(eye, 0.92, Color("c7b873"))
	canvas.draw_circle(eye + Vector2(0.35, 0), 0.42, Color("293b32"))
	canvas.draw_circle(eye + Vector2(-0.24, -0.26), 0.23, Color("efe9c1"))
	_fur(canvas, [Vector2(16, -25) + dip, Vector2(17, -23) + dip, Vector2(18, -20.5) + dip], Vector2(-2.5, 1.4), Color(coat.lightened(0.29), 0.5))
	canvas.draw_line(Vector2(20, -27.2) + dip, Vector2(23, -26.4) + dip, Color(coat.lightened(0.29), 0.7), 0.7, true)

static func _fur(canvas: CanvasItem, origins: Array, direction: Vector2, color: Color) -> void:
	for index in range(origins.size()):
		var start: Vector2 = origins[index]
		var curve := PackedVector2Array([start, start + direction * 0.5 + Vector2(0.3, -0.3), start + direction])
		canvas.draw_polyline(curve, color, 0.65, true)

static func _fill(canvas: CanvasItem, control: Array, color: Color) -> void:
	var points := smooth_outline(control)
	canvas.draw_colored_polygon(points, color)

static func smooth_outline(control: Array, subdivisions: int = 5) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(control.size()):
		var a: Vector2 = control[posmod(index - 1, control.size())]
		var b: Vector2 = control[index]
		var c: Vector2 = control[(index + 1) % control.size()]
		var d: Vector2 = control[(index + 2) % control.size()]
		for step in range(subdivisions):
			var t := float(step) / float(subdivisions)
			var t2 := t * t
			var t3 := t2 * t
			points.append(0.5 * ((2.0 * b) + (-a + c) * t + (2.0 * a - 5.0 * b + 4.0 * c - d) * t2 + (-a + 3.0 * b - 3.0 * c + d) * t3))
	return points
