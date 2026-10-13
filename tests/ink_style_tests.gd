extends RefCounted
## Stable ink geometry and readable reaction beats, independent of draw clocks.

static func run(check: Callable) -> void:
	var look := GuCharacterAppearance.default_data()
	var expressions := true
	var anticipation := true
	for d in range(8):
		var hit := GuIllustratedCharacterArt.sample("hit",.12,d,look)
		var strike := GuIllustratedCharacterArt.sample("attack",.12,d,look)
		expressions = expressions and hit["blink"]>.5 and strike["blink"]>.5 and GuIllustratedCharacterArt.sample("hit",.45,d,look)["blink"]==0.0 and GuIllustratedCharacterArt.sample("attack",.40,d,look)["blink"]==0.0 and GuIllustratedCharacterArt.sample("hit",.12,d,look,true)["blink"]==0.0
		var loaded := GuIllustratedCharacterArt.sample("attack",.16,d,look)
		var held := GuIllustratedCharacterArt.sample("attack",.18,d,look)
		anticipation = anticipation and absf(float(loaded["weapon_angle"])-float(held["weapon_angle"]))<.0001 and Vector2(loaded["arm_R"][2]).is_equal_approx(held["arm_R"][2])
	check.call(expressions,"Attack windup and damage briefly close the original eyes, reopen before release/recovery, and respect reduced motion")
	check.call(anticipation,"Sword windup holds its grip and angle briefly before the faster release instead of swinging at constant speed")
	var endpoints := true
	var pressure := true
	var stable := true
	for points in [PackedVector2Array([Vector2(-12,0),Vector2(12,0)]),GuVectorEffectsArt._arc(Vector2(24,29),-.9,.8)]:
		for width in [.65,1.4,3.8]:
			var outline := GuVectorEffectsArt.ink_stroke(points,width)
			var n := outline.size()/2
			endpoints = endpoints and ((outline[0]+outline[2*n-1])*.5).is_equal_approx(points[0]) and ((outline[n-1]+outline[n])*.5).is_equal_approx(points[points.size()-1])
			var low := INF
			var high := 0.0
			for i in range(n):
				var span := outline[i].distance_to(outline[2*n-1-i])
				low = minf(low,span)
				high = maxf(high,span)
				pressure = pressure and outline[i].is_finite() and span>width*.35 and span<=width*1.05
			pressure = pressure and high-low>width*.30
			stable = stable and outline==GuVectorEffectsArt.ink_stroke(points,width)
	check.call(endpoints,"Ink pressure strokes keep authored endpoints attached to projectile paths and impact accents")
	check.call(pressure,"Straight and curved pen marks retain finite connected widths with visible pressure variation")
	check.call(stable and GuVectorEffectsArt.ink_stroke(PackedVector2Array(),1).is_empty(),"Ink geometry is deterministic for repeated samples and safely handles an empty mark")
