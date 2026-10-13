class_name GuCharacterHeldProp
extends RefCounted
## One visible implement at a time. Clip envelopes hide the swap while the
## hand prepares/returns; interruptions finish a short visual handoff only.
## No gameplay state, equipment mutation or delay of an accepted action.

const HIDE_SECONDS := .045
const SHOW_SECONDS := .060
var shown := "none"
var opacity := 0.0

static func desired(action: String, phase: float, equipped: String) -> Dictionary:
	var weapon := "none" if equipped=="unarmed" else equipped
	if not GuCharacterActionMotion.harvesting(action):
		return {"kind":weapon,"opacity":1.0}
	if phase<.08:
		return {"kind":weapon,"opacity":1-GuCharacterActionMotion.phase_ease(0,.08,phase)}
	if phase>=.92:
		return {"kind":weapon,"opacity":GuCharacterActionMotion.phase_ease(.92,1,phase)}
	var amount := GuCharacterActionMotion.phase_ease(.08,.18,phase)*(1-GuCharacterActionMotion.phase_ease(.80,.92,phase))
	return {"kind":"pick" if action=="mine" else "none","opacity":amount}

func reset(request: Dictionary) -> Dictionary:
	shown=request["kind"]
	opacity=request["opacity"]
	return _value()

func advance(request: Dictionary, delta: float) -> Dictionary:
	var remaining := maxf(0,delta)
	if remaining<=0: return _value()
	if request["kind"]!=shown:
		var spent := minf(remaining,opacity*HIDE_SECONDS)
		opacity=maxf(0,opacity-spent/HIDE_SECONDS)
		remaining-=spent
		if opacity<=.00001:
			shown=request["kind"]
			opacity=0
	if request["kind"]==shown:
		opacity=move_toward(opacity,float(request["opacity"]),remaining/SHOW_SECONDS)
	return _value()

func _value() -> Dictionary:
	return {"kind":shown,"opacity":opacity}
