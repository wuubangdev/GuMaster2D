class_name GuHumanoidArt
extends RefCounted
## Original layered vector costume. Shared by world, paper doll and motion review.

const INK := Color("101e27")
const ROBE := Color("294957")
const JADE := Color("487f7b")
const SILK := Color("d9d6ba")
const GOLD := Color("bea16a")
const SKIN := Color("d7ae86")
const HAIR := Color("16232c")

static func draw_ghost(c: CanvasItem, p: Dictionary, offset: Vector2, color: Color) -> void:
	var b: Vector2 = p["belt"]
	var points := PackedVector2Array([p["shoulder_l"], p["shoulder_r"], p["hand_r"], at(p, b, 9, 2), at(p, b, 13, 25), at(p, b, -13, 25), at(p, b, -9, 2), p["hand_l"]])
	for i in range(points.size()):
		points[i] += offset
	c.draw_colored_polygon(points, color)
	c.draw_circle(offset + Vector2(p["head"]), 5.5, color)

static func draw_body(c: CanvasItem, p: Dictionary, flash: float = 0.0) -> void:
	var far := "l" if not p["back"] else "r"
	var near := "r" if not p["back"] else "l"
	var robe := ROBE.lerp(Color("c3ded1"), minf(flash / 0.19, 1.0) * 0.65)
	var silk := SILK.lerp(Color.WHITE, minf(flash / 0.19, 1.0) * 0.65)
	# Ribbon and rear arm sit behind the shoulder; soles stay at the ground anchor.
	var h: Vector2 = p["head"]
	var wind: float = p["cloth"] * p["flip"]
	_ribbon(c, h + Vector2(-2 * p["flip"], -5), h + Vector2(-8 * p["flip"] + wind * 0.7, 8), h + Vector2(-4 * p["flip"] + wind, 26), 2.3, JADE)
	for side in [far, near]:
		_leg(c, p, side)
	_arm(c, p, far, silk.darkened(0.22))
	# Split outer robe, ivory underlayer and contrasting jade lapel.
	var b: Vector2 = p["belt"]
	var chest: Vector2 = p["chest"]
	var hem := Vector2(b.x + wind, -7)
	_poly(c, [at(p, chest, -8, -2), at(p, chest, 8, -2), at(p, b, 8, 2), at(p, hem, 15, 0), at(p, hem, 8, 5), at(p, hem, 1, 1), at(p, hem, -8, 4), at(p, hem, -15, 1), at(p, b, -8, 1)], robe)
	_poly(c, [at(p, b, -4, -1), at(p, b, 5, -1), at(p, hem, 7, 1), at(p, hem, 0, -1), at(p, hem, -7, 1)], silk.darkened(0.13), 0.6)
	_poly(c, [at(p, chest, -6, -2), at(p, chest, 5, -2), at(p, b, 6, -1), at(p, b, -5, -1)], JADE)
	if not p["back"]:
		_poly(c, [at(p, chest, -5, -3), at(p, chest, 4, 2), at(p, b, -3, -1), at(p, b, -6, -1)], silk, 0.5)
		_poly(c, [at(p, chest, 5, -3), at(p, chest, 8, 0), at(p, b, 0, 0), at(p, b, -3, -1)], JADE.lightened(0.13), 0.5)
		_line(c, [at(p, chest, 5, -3), at(p, chest, 6, 1), at(p, b, -2, -1)], GOLD, 0.9)
	else:
		_line(c, [at(p, chest, -6, 0), at(p, chest, 0, 3), at(p, chest, 6, 0)], GOLD.darkened(0.19), 0.8)
		# Woven seal on the rear of the robe; no text or borrowed insignia.
		var seal: Vector2 = chest + Vector2(0, 8)
		_line(c, [seal + Vector2(0, -3), seal + Vector2(3, 0), seal + Vector2(0, 4), seal + Vector2(-3, 0), seal + Vector2(0, -3)], GOLD, 0.8)
	# Long outer panels expose the gait without sliding the entire garment.
	_poly(c, [at(p, b, -8, 0), at(p, b, -3, 0), at(p, hem, -5, 2), at(p, hem, -14, 1)], robe.lightened(0.07), 0.6)
	_poly(c, [at(p, b, 4, 0), at(p, b, 8, 0), at(p, hem, 14, 0), at(p, hem, 8, 4)], robe.darkened(0.08), 0.6)
	_line(c, [at(p, b, -7, 4), at(p, hem, -12, -1), at(p, hem, -7, 2)], GOLD.darkened(0.19), 0.9)
	_line(c, [at(p, b, 7, 5), at(p, hem, 11, 0)], JADE.lightened(0.19), 0.8)
	_line(c, [at(p, b, -1, 5), at(p, hem, -2, -1)], Color("939e90"), 0.7)
	# Sash, buckle, jade pendant and a small leather pouch.
	_poly(c, [at(p, b, -9, -3), at(p, b, 8, -3), at(p, b, 9, 1), at(p, b, -8, 2)], INK, 0.7)
	_line(c, [at(p, b, -8, -2), at(p, b, 8, -2)], GOLD, 0.9)
	_poly(c, [at(p, b, -1, -3), at(p, b, 3, -3), at(p, b, 3, 1), at(p, b, -1, 1)], GOLD, 0.5)
	_ribbon(c, at(p, b, 4, 1), at(p, b, 8, 10) + Vector2(wind * 0.5, 0), at(p, hem, 11, -4) + Vector2(wind * 0.3, 0), 2.2, JADE.lightened(0.15))
	var pendant := at(p, b, -5, 9)
	c.draw_line(at(p, b, -5, 1), pendant, GOLD, 0.7, true)
	_poly(c, [pendant + Vector2(0, -2), pendant + Vector2(2, 0), pendant + Vector2(0, 3), pendant + Vector2(-2, 0)], Color("89c3ae"), 0.5)
	var pouch := at(p, b, 8, 3)
	_poly(c, [pouch + Vector2(-2, 0), pouch + Vector2(2, 0), pouch + Vector2(3, 5), pouch + Vector2(-2, 6)], Color("6f5947"), 0.7)
	_arm(c, p, near, silk)
	# Neck sits inside the collar; head proportions remain human at 1x world scale.
	var neck: Vector2 = p["neck"]
	_poly(c, [neck + Vector2(-2.2, -1), neck + Vector2(2.2, -1), neck + Vector2(2.8, 5), neck + Vector2(0, 7), neck + Vector2(-2.8, 4)], SKIN.darkened(0.12), 0.5)
	_head(c, p)

static func _leg(c: CanvasItem, p: Dictionary, side: String) -> void:
	var hip: Vector2 = p["hip_" + side]
	var knee: Vector2 = p["knee_" + side]
	var foot: Vector2 = p["foot_" + side]
	_limb(c, hip, knee, foot + Vector2(0, -3), 3.1, 2.7, 2.1, Color("707e7a"))
	var toe := Vector2(p["flip"] * (3.5 if p["profile"] else 2.5), 0.8)
	_poly(c, [foot + Vector2(-2.5, -7), foot + Vector2(2.5, -7), foot + Vector2(2.7, -1), foot + toe + Vector2(2.4, 0.5), foot + toe + Vector2(-2.8, 1), foot + Vector2(-2.8, -1)], INK, 0.7)
	c.draw_line(foot + Vector2(-2, -5), foot + Vector2(2, -5), GOLD.darkened(0.2), 0.7, true)
	c.draw_line(foot + toe + Vector2(-2, 0.5), foot + toe + Vector2(2, 0), Color("91998b"), 0.8, true)

static func _arm(c: CanvasItem, p: Dictionary, side: String, silk: Color) -> void:
	var shoulder: Vector2 = p["shoulder_" + side]
	var elbow: Vector2 = p["elbow_" + side]
	var hand: Vector2 = p["hand_" + side]
	var axis := (hand - elbow).normalized()
	var wrist := hand - axis * 2.5
	_limb(c, shoulder, elbow, wrist, 4.7, 4.9, 3.0, silk)
	c.draw_line(shoulder + Vector2(-p["flip"], 2), elbow, silk.darkened(0.3), 0.7, true)
	var cuff := wrist - axis * 1.6
	var across := axis.orthogonal() * 3.0
	_poly(c, [cuff + across - axis * 1.7, cuff - across - axis * 1.7, wrist - across, wrist + across], JADE, 0.6)
	c.draw_line(wrist - across, wrist + across, GOLD, 0.85, true)
	_limb(c, wrist + axis, hand, hand + axis * 2, 1.65, 1.9, 1.1, SKIN)

static func _head(c: CanvasItem, p: Dictionary) -> void:
	var h: Vector2 = p["head"]
	var f: float = p["flip"]
	var profile: bool = p["profile"]
	var back: bool = p["back"]
	_poly(c, [h + Vector2(-4.4, -4), h + Vector2(2.8, -5.3), h + Vector2(4.5, -2), h + Vector2(4.3, 3), h + Vector2(1.5, 6), h + Vector2(-2.3, 5), h + Vector2(-4.2, 1)], SKIN, 0.8)
	if profile:
		_poly(c, [h + Vector2(f * 3, -2), h + Vector2(f * 6, 0.5), h + Vector2(f * 3.7, 1.5), h + Vector2(f * 3, 4)], SKIN, 0.5)
	# Hair cap, temple locks and small tied topknot.
	_poly(c, [h + Vector2(-5, 1), h + Vector2(-5.5, -4), h + Vector2(-3.3, -7), h + Vector2(1.5, -7.5), h + Vector2(5, -5), h + Vector2(5, -1), h + Vector2(1.5, -4), h + Vector2(-2, -3)], HAIR, 0.8)
	if back:
		_poly(c, [h + Vector2(-4.8, -2), h + Vector2(4.8, -2), h + Vector2(4, 6), h + Vector2(0, 9), h + Vector2(-4.5, 5)], HAIR, 0.6)
		_ribbon(c, h + Vector2(0, 3), h + Vector2(p["cloth"] * f * 0.3, 13), h + Vector2(p["cloth"] * f * 0.65, 20), 2.6, HAIR)
		c.draw_line(h + Vector2(-2, 0), h + Vector2(-1, 7), Color("364b53"), 0.7, true)
	else:
		var eye := h + Vector2(f * 2.5, 0)
		c.draw_line(eye - Vector2(1.2, 0.4), eye + Vector2(0.9, -0.2), INK, 0.8, true)
		if not profile:
			c.draw_line(h + Vector2(-f * 3.2, -0.2), h + Vector2(-f * 1.3, 0.1), INK, 0.7, true)
			c.draw_line(h + Vector2(f * 0.5, 1), h + Vector2(f * 1.2, 2.4), SKIN.darkened(0.28), 0.65, true)
		c.draw_line(h + Vector2(f * 1, 3.7), h + Vector2(f * 2.6, 3.4), Color("8e695c"), 0.65, true)
		c.draw_line(h + Vector2(-f * 4.5, -1), h + Vector2(-f * 3.6, 5), HAIR, 1.5, true)
	_poly(c, [h + Vector2(-3, -7), h + Vector2(-3, -10), h + Vector2(-1, -12), h + Vector2(2, -11.5), h + Vector2(3, -9), h + Vector2(2, -7)], HAIR, 0.8)
	c.draw_line(h + Vector2(-3, -8), h + Vector2(3, -8), GOLD, 1.0, true)
	c.draw_line(h + Vector2(-5, -9), h + Vector2(5.5, -9.5), Color("b6cbc0"), 0.8, true)
	c.draw_circle(h + Vector2(5.5, -9.5), 1.0, Color("79b3a4"))
	c.draw_line(h + Vector2(-3, -5), h + Vector2(0, -6), Color("445861"), 0.8, true)

static func at(p: Dictionary, origin: Vector2, x: float, y: float) -> Vector2:
	return origin + Vector2(x * p["width"] * p["flip"], y)

static func _poly(c: CanvasItem, vertices: Array, color: Color, outline: float = 0.8) -> void:
	var points := PackedVector2Array(vertices)
	c.draw_colored_polygon(points, color)
	points.append(points[0])
	c.draw_polyline(points, INK, outline, true)

static func _line(c: CanvasItem, vertices: Array, color: Color, thickness: float) -> void:
	c.draw_polyline(PackedVector2Array(vertices), color, thickness, true)

static func _limb(c: CanvasItem, a: Vector2, b: Vector2, end: Vector2, wa: float, wb: float, wc: float, color: Color) -> void:
	var na := (b - a).normalized().orthogonal()
	var nc := (end - b).normalized().orthogonal()
	var nb := (na + nc).normalized()
	_poly(c, [a + na * wa, b + nb * wb, end + nc * wc, end - nc * wc, b - nb * wb, a - na * wa], color, 0.7)

static func _ribbon(c: CanvasItem, a: Vector2, b: Vector2, end: Vector2, width: float, color: Color) -> void:
	var left: Array = []
	var right: Array = []
	for i in range(9):
		var t := i / 8.0
		var point := a.lerp(b, t).lerp(b.lerp(end, t), t)
		var normal := (b - a).lerp(end - b, t).normalized().orthogonal()
		var w := width * lerpf(1, 0.35, t)
		left.append(point + normal * w)
		right.push_front(point - normal * w)
	_poly(c, left + right, color, 0.6)
