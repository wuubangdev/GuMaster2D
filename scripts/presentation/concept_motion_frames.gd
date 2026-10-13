class_name GuConceptMotionFrames
extends RefCounted
## Authored front/rear sleeve poses. These are pose keys for the current art,
## not claims of newly drawn bitmap frames. Interpolation stays continuous.

const DEPTH := .55
const SLEEVE_KEYS := [Vector2(.015,.04),Vector2(.075,.15),Vector2(.11,.27),Vector2(.065,.20),Vector2(-.02,.04),Vector2(-.07,-.10),Vector2(-.11,-.14),Vector2(-.065,-.08)]

static func stride(action: String, facing: Vector2) -> float:
	return (GuIllustratedCharacterArt.RUN_STRIDE if action=="run" else GuIllustratedCharacterArt.WALK_STRIDE)*projection(facing)

static func projection(facing: Vector2) -> float:
	var aim := facing.normalized()
	return Vector2(aim.x,aim.y*DEPTH).length()

static func sleeve(phase: float, side: String, running: bool, back: bool) -> Vector2:
	var sample := fposmod(phase+(.5 if side=="L" else 0),1)*SLEEVE_KEYS.size()
	var first := floori(sample)
	var before: Vector2 = SLEEVE_KEYS[posmod(first-1,SLEEVE_KEYS.size())]
	var a: Vector2 = SLEEVE_KEYS[first]
	var b: Vector2 = SLEEVE_KEYS[(first+1)%SLEEVE_KEYS.size()]
	var after: Vector2 = SLEEVE_KEYS[(first+2)%SLEEVE_KEYS.size()]
	var angles := a.cubic_interpolate(b,before,after,sample-first)
	return angles*(1.3 if running else 1)*(-1 if side=="L" else 1)*(-1 if back else 1)

static func arm_angles(phase: float, side: String, running: bool, facing: Vector2) -> Vector2:
	# Shoulder leads; the forearm follows a little later. The arm on the
	# same side counterbalances the actual foot, including its stance hold.
	var offset := .5 if side=="L" else 0.0
	var stance := .46 if running else .60
	var stride_length := GuIllustratedCharacterArt.RUN_STRIDE if running else GuIllustratedCharacterArt.WALK_STRIDE
	var range_length := stride_length*stance*.5
	var first := float(GuIllustratedCharacterArt.gait_foot(phase+offset,running)["travel"])/range_length
	var follow := float(GuIllustratedCharacterArt.gait_foot(phase+offset-.075,running)["travel"])/range_length
	var profile := facing.x*Vector2(first*(.38 if running else .24),follow*(.40 if running else .25)-(.32 if running else .10))
	var frontal := sleeve(phase,side,running,facing.y<0)*absf(facing.y)
	return profile+frontal

static func toe_roll(phase: float, side: String, running: bool, facing: Vector2) -> float:
	var t := fposmod(phase+(.5 if side=="L" else 0),1)
	var stance := .46 if running else .60
	if t<=stance: return 0.0
	var swing := (t-stance)/(1-stance)
	# Dorsiflex on clearance, then relax before contact. Both ends have zero
	# angular velocity; a planted sole never rotates or scrapes the floor.
	return -facing.x*sin(swing*PI)*sin(swing*PI)*sin(swing*TAU)*(.30 if running else .22)
