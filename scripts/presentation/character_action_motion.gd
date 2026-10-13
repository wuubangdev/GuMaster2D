class_name GuCharacterActionMotion
extends RefCounted
## Authored timing for the illustrated actor. These are our game's beats,
## inspired by Klei's pose/symbol workflow, not extracted DST frame data.
const SWORD_SECONDS := .64
const CONTACT := .34
const FOLLOW := .56
const HARVEST_DURATIONS := {"gather":.88, "mine":.96}
const HARVEST_CONTACT := {"gather":.50, "mine":.48}

static func harvesting(action: String) -> bool:
	return HARVEST_DURATIONS.has(action)

static func phase_ease(a: float, b: float, phase: float) -> float:
	var t := clampf((phase-a)/maxf(.00001,b-a),0,1)
	return t*t*(3-2*t)

static func track(neutral: Vector2, load: Vector2, strike: Vector2, follow: Vector2, phase: float, contact: float = CONTACT, recovery: float = FOLLOW, load_end: float = .16, release: float = .18) -> Vector2:
	if phase<load_end: return neutral.lerp(load,phase_ease(0,load_end,phase))
	if phase<release: return load
	var before := (strike-load)/(contact-release)
	var after := (follow-strike)/(recovery-contact)
	var tangent := Vector2(_tangent(before.x,after.x),_tangent(before.y,after.y))
	if phase<contact: return _hermite(load,strike,Vector2.ZERO,tangent*(contact-release),clampf((phase-release)/(contact-release),0,1))
	if phase<recovery: return _hermite(strike,follow,tangent*(recovery-contact),Vector2.ZERO,clampf((phase-contact)/(recovery-contact),0,1))
	return follow.lerp(neutral,phase_ease(recovery,1,phase))

static func _tangent(before: float, after: float) -> float:
	return 2*before*after/(before+after) if before*after>0 else 0.0

static func _hermite(a: Vector2, b: Vector2, start: Vector2, end: Vector2, t: float) -> Vector2:
	var t2 := t*t
	var t3 := t2*t
	return a*(2*t3-3*t2+1)+start*(t3-2*t2+t)+b*(-2*t3+3*t2)+end*(t3-t2)

static func harvest_weight(action: String, phase: float) -> float:
	# Lower the hips before reaching; stay down through contact, then rise.
	return phase_ease(0,.30,phase)*(1-phase_ease(.66,1,phase)) if action=="gather" else phase_ease(0,.18,phase)*(1-phase_ease(.64,1,phase))

static func release_seconds(weapon: String) -> float:
	return SWORD_SECONDS*CONTACT if weapon=="sword" else .08
