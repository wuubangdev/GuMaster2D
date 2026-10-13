class_name GuIllustratedCharacterArt
extends RefCounted
## Original SVG cutout art and a deterministic, continuous presentation rig.
## Model coordinates are relative to the planted feet, never authority cells.

const MANIFEST_PATH := "res://assets/vector/characters/manifest.json"
const OUTFIT_COLORS := {"jade": Color("657a61"), "crimson": Color("8e615c"), "ivory": Color("bdb394")}
const INK_SHADER := preload("res://assets/shaders/ink_cutout.gdshader")
const WALK_STRIDE := 20.0
const RUN_STRIDE := 28.0
const WALK_LIFT := 3.0
const RUN_LIFT := 4.2
const LEG_SEGMENT := 8.0
static var _manifest: Dictionary = {}
static var _textures: Dictionary = {}
static var _ink_material: ShaderMaterial

static func ink_material() -> ShaderMaterial:
	if _ink_material==null:
		_ink_material = ShaderMaterial.new()
		_ink_material.shader = INK_SHADER
	return _ink_material

static func manifest() -> Dictionary:
	if _manifest.is_empty():
		var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
		if value is Dictionary:
			_manifest = value
	return _manifest

static func part_texture(key: String) -> Texture2D:
	if not _textures.has(key):
		var entry: Dictionary = manifest().get("parts", {}).get(key, {})
		if entry.is_empty():
			return null
		_textures[key] = load(str(entry["path"])) as Texture2D
	return _textures[key] as Texture2D

static func _ease(a: float, b: float, t: float) -> float:
	var x := clampf((t-a)/maxf(.001,b-a),0,1)
	return x*x*(3-2*x)

static func gait_foot(phase: float, running: bool = false) -> Dictionary:
	# Linear stance cancels the actor's distance-driven travel. The Hermite
	# return matches that velocity at both contacts; squared-sine lift has no
	# vertical velocity discontinuity at takeoff or landing.
	var t := fposmod(phase,1.0)
	var stance := .46 if running else .60
	var stride_length := RUN_STRIDE if running else WALK_STRIDE
	var half_span := stride_length*stance*.5
	if t < stance:
		return {"travel":half_span-stride_length*t,"lift":0.0,"roll":sin(t/stance*PI)*.055,"contact":1.0}
	var u := (t-stance)/(1-stance)
	var tangent := -stride_length*(1-stance)
	var travel := (2*u*u*u-3*u*u+1)*(-half_span) + (-2*u*u*u+3*u*u)*half_span + (2*u*u*u-3*u*u+u)*tangent
	var arch := pow(sin(u*PI),2)
	return {"travel":travel,"lift":arch*(RUN_LIFT if running else WALK_LIFT),"roll":-sin(u*TAU)*arch*.10,"contact":1-arch}

static func connect_arms(pose: Dictionary) -> void:
	# The anatomical bend is projected from facing, not a fixed screen-side.
	# Interpolate that projection with the endpoints during interrupted turns.
	for side in ["L","R"]:
		var arm: Array = pose["arm_"+side]
		var reach: Vector2 = Vector2(arm[2])-Vector2(arm[0])
		if reach.length_squared() < 1.0:
			reach = Vector2(0,1)
			arm[2] = Vector2(arm[0])+reach
		var normal := Vector2(reach.y,-reach.x).normalized()
		arm[1] = Vector2(arm[0]).lerp(arm[2],.54)+normal*float(pose["arm_bend_"+side])

static func blend_poses(from: Dictionary, to: Dictionary, weight: float) -> Dictionary:
	var w := clampf(weight,0,1)
	if w <= 0:
		return from.duplicate(true)
	if w >= 1:
		return to.duplicate(true)
	var pose := to.duplicate(true)
	for key: String in to:
		if not from.has(key):
			continue
		if to[key] is Vector2:
			pose[key] = Vector2(from[key]).lerp(to[key],w)
		elif to[key] is float:
			pose[key] = lerp_angle(float(from[key]),float(to[key]),w) if "rotation" in key or key=="weapon_angle" else lerpf(float(from[key]),float(to[key]),w)
		elif to[key] is Array:
			for i in range(to[key].size()):
				pose[key][i] = Vector2(from[key][i]).lerp(to[key][i],w)
	connect_arms(pose)
	return pose

static func sample(action: String, phase: float, direction_index: int, appearance: Dictionary, reduced: bool = false) -> Dictionary:
	var t := phase
	if reduced and action in ["idle","walk","run","defend","channel"]:
		t = 0.0
	var aim := Vector2.DOWN.rotated(direction_index*PI/4)
	var sign_x := -1.0 if aim.x < -.1 else 1.0
	var swing := sin(t*TAU)
	var breath := sin(t*TAU)*.4 if not reduced else 0.0
	var torso := Vector2(0,-21+breath*.25)
	var head := Vector2(0,-43+breath)
	# Screen-space depth is perpendicular to travel. A profile has two legs
	# in one sagittal plane, rather than the frontal ten-pixel-wide stance.
	var lateral := Vector2(aim.y*5.2+aim.x, -aim.x*1.1)
	var foot_l := Vector2(0,-2)-lateral
	var foot_r := Vector2(0,-2)+lateral
	# Rotate both shoulders and resting hands through the same body frame.
	# Profile arms occupy one travel plane; the forward wrist lies ahead of
	# the elbow on both sides, and the near arm swaps when facing reverses.
	var shoulder_span := Vector2(aim.y*8.5,-aim.x*1.3)
	var wrist_span := Vector2(aim.y*11.5,-aim.x*1.4)
	var shoulder_l := Vector2(0,-28)+shoulder_span
	var shoulder_r := Vector2(0,-28)-shoulder_span
	var wrist_forward := Vector2(aim.x*3.2,0)
	var hand_l := Vector2(0,-14)+wrist_span+wrist_forward
	var hand_r := Vector2(0,-14)-wrist_span+wrist_forward
	var bend_l := aim.y*1.6-aim.x*2.6
	var bend_r := -aim.y*1.6-aim.x*2.6
	var torso_rotation := 0.0
	var head_rotation := 0.0
	var foot_rotation_l := 0.0
	var foot_rotation_r := 0.0
	# Rest the blade outside the silhouette on the anatomical weapon side.
	# A frontal fixed angle hid the whole sword behind the head in back views.
	var weapon_angle := (1.0 if hand_r.x>=0 else -1.0)*clampf(absf(hand_r.x)*.052,.48,.64)
	var tail_rotation := swing*.06 if not reduced else 0.0
	var squash := Vector2.ONE
	var alpha := 1.0
	var lift_l := 0.0
	var lift_r := 0.0
	var contact_l := 1.0
	var contact_r := 1.0
	match action:
		"walk", "run":
			var running := action=="run"
			var pace := 1.45 if running else 1.0
			var left := gait_foot(t+.5,running)
			var right := gait_foot(t,running)
			lift_l = float(left["lift"])
			lift_r = float(right["lift"])
			contact_l = float(left["contact"])
			contact_r = float(right["contact"])
			foot_l += aim*float(left["travel"])-Vector2(0,lift_l)
			foot_r += aim*float(right["travel"])-Vector2(0,lift_r)
			foot_rotation_l = float(left["roll"])*sign_x
			foot_rotation_r = float(right["roll"])*sign_x
			var rise := (.5-.5*cos(t*TAU*2))*pace
			var balance := cos(t*TAU)*.45*aim.y
			torso = Vector2(balance,-21-rise*.60)
			head = Vector2(balance*.3,-43-(.5-.5*cos(t*TAU*2-.28))*pace*.28)
			torso_rotation = swing*.035*pace
			head_rotation = -torso_rotation*.25
			squash = Vector2(1-rise*.012,1+rise*.014)
			# Counterbalance each leg's actual travel, including the shorter
			# run stance; an independent sine can swing the wrong way at contact.
			var arm_weight := .43 if running else .35
			hand_r -= aim*float(right["travel"])*arm_weight
			hand_l -= aim*float(left["travel"])*arm_weight
			hand_r.y -= (.5-.5*cos(t*TAU))*pace*.65
			hand_l.y -= (.5+.5*cos(t*TAU))*pace*.65
			bend_l -= aim.x*(.5-.5*cos(t*TAU))*pace*.7
			bend_r -= aim.x*(.5+.5*cos(t*TAU))*pace*.7
			weapon_angle += sin(t*TAU-.25)*.045*pace
			tail_rotation = sin(t*TAU-.7)*.075*pace if not reduced else 0
			if running:
				torso.x += aim.x*1.4
				head.x += aim.x*1.2
				torso_rotation += aim.x*.04
		"attack":
			# A long curved windup, fast release, short overshoot and soft settle.
			# Resting breath must not move the shoulders through a held grip.
			torso = Vector2(0,-21)
			head = Vector2(0,-43)
			var load_up := _ease(0,.16,t)
			var strike := _ease(.18,.34,t)
			var settle := _ease(.58,1,t)
			var beat := sin(clampf((t-.21)/.37,0,1)*PI)
			var weapon := str(appearance.get("weapon","sword"))
			var recover := 1-settle
			if weapon == "spear":
				var grip := _ease(0,.17,t)*recover
				weapon_angle = lerp_angle(weapon_angle,aim.angle()+PI/2,grip)+sin(t*PI)*.035
				hand_r += aim*((-4*load_up+14*strike)*recover)
				hand_l = hand_l.lerp(hand_r-aim*9,grip)
			elif weapon == "unarmed":
				hand_r += (aim*11*strike + Vector2(0,-6*load_up))*recover
				hand_l += Vector2(-sign_x*4,-7)*load_up*recover
			else:
				weapon_angle += (-1.7*load_up+3.0*strike-.35*_ease(.38,.55,t))*recover
				hand_r += (Vector2(-sign_x*3,-14)*load_up + aim*9*strike)*recover
				hand_l += Vector2(sign_x*2,-3)*beat
			torso += aim*beat*2.3
			torso_rotation = sign_x*(-.10*load_up+.19*strike)*recover
			head_rotation = -torso_rotation*.45
			head += aim*beat*1.4
			squash = Vector2(1+beat*.025,1-beat*.025)
			foot_r += aim*beat*1.6
			tail_rotation = -torso_rotation*.9
			if weapon=="sword":
				# Body and source arm now share the same load/contact/follow keys.
				# Counter-rotation of the head keeps the eyes aimed at the target.
				var shift := GuCharacterActionMotion.track(Vector2.ZERO,Vector2(-.65,.35),Vector2(1.35,.65),Vector2(.8,.45),t)
				torso=Vector2(aim.x*shift.x,-21+shift.y)
				torso_rotation=GuCharacterActionMotion.track(Vector2.ZERO,Vector2(-.085,0),Vector2(.105,0),Vector2(.06,0),t).x*sign_x
				head_rotation=-torso_rotation*.32
				foot_r=Vector2(0,-2)+lateral
				tail_rotation=-torso_rotation*.55
		"gather", "mine":
			var weight := GuCharacterActionMotion.harvest_weight(action,t)
			var contact := float(GuCharacterActionMotion.HARVEST_CONTACT[action])
			var push := GuCharacterActionMotion.track(Vector2.ZERO,Vector2(-.25,.3),Vector2(1,1),Vector2(.6,.7),t,contact,.64,.28 if action=="mine" else .16,.30 if action=="mine" else .18)
			torso=Vector2(aim.x*push.x,-21+weight*(2.8 if action=="gather" else .8))
			torso_rotation=aim.x*weight*(.22 if action=="gather" else .055)
			head_rotation=aim.x*weight*.10
			tail_rotation=-torso_rotation*.5
		"cast":
			var charge := _ease(0,.14,t)
			var release := _ease(.14,.36,t)
			var recover := 1-_ease(.64,1,t)
			hand_r += (Vector2(-sign_x*2,-15)*charge+aim*12*release)*recover
			hand_l += Vector2(-sign_x*6,-6)*charge*recover
			torso_rotation = -sign_x*.07*charge*recover
			head_rotation = sign_x*.03*release*recover
			tail_rotation = sin(t*PI)*.15
		"defend":
			var guard := 1.0 if reduced else .93+sin(t*TAU)*.07
			torso.y += 1.3*guard
			head.y += .8*guard
			hand_r += Vector2(sign_x*5,-8)*guard
			hand_l += Vector2(-sign_x*6,-9)*guard
			weapon_angle = -.3
			foot_l.x -= 1.6
			foot_r.x += 1.6
		"channel":
			hand_r = Vector2(-5,-22+breath*.5)
			hand_l = Vector2(5,-22+breath*.5)
			weapon_angle = -.8
			squash = Vector2(1,1+breath*.012)
		"dash":
			var burst := sin(clampf(t,0,1)*PI)
			torso += aim*burst*2
			head += aim*burst*4
			torso_rotation = aim.x*burst*.20
			head_rotation = -torso_rotation*.25
			hand_r -= aim*burst*6
			hand_l -= aim*burst*6
			foot_l += aim*burst*2
			foot_r -= aim*burst*3
			tail_rotation = -aim.x*burst*.35
		"hit":
			var recoil := sin(clampf(t,0,1)*PI)*pow(1-t, .5)
			torso -= aim*recoil*2
			head -= aim*recoil*3
			head_rotation = sign_x*recoil*.12
			torso_rotation = -sign_x*recoil*.1
			hand_r -= aim*recoil*2
			hand_l -= aim*recoil*2
			squash = Vector2(1+recoil*.06,1-recoil*.06)
		"death":
			var fall := _ease(.05,.8,t)
			torso.y += fall*12
			head += Vector2(sign_x*7,fall*20)*fall
			torso_rotation = sign_x*fall*.5
			head_rotation = sign_x*fall*.65
			hand_r += Vector2(-4,8)*fall
			hand_l += Vector2(4,8)*fall
			alpha = 1-_ease(.8,1,t)*.3
		"respawn":
			var rise := 1-_ease(0,.65,t)
			torso.y += rise*8
			head.y += rise*8
			squash = Vector2(1+rise*.06,1-rise*.06)
			alpha = .4+.6*_ease(0,.4,t)
	# Arm bends stay attached to the actual drawn hands, at arbitrary times.
	shoulder_l = torso+(shoulder_l-Vector2(0,-21)).rotated(torso_rotation)
	shoulder_r = torso+(shoulder_r-Vector2(0,-21)).rotated(torso_rotation)
	var blink := _ease(.87,.89,t)*(1-_ease(.905,.93,t)) if action=="idle" and not reduced else 0.0
	if action=="hit" and not reduced:
		blink = _ease(.02,.07,t)*(1-_ease(.28,.40,t))
	elif action=="attack" and not reduced:
		blink = _ease(.04,.10,t)*(1-_ease(.16,.24,t))*.75
	var pose := {"head":head,"head_rotation":head_rotation,"torso":torso,"torso_rotation":torso_rotation,"torso_scale":squash,"foot_L":foot_l,"foot_R":foot_r,"foot_ground_L":foot_l+Vector2(0,lift_l),"foot_ground_R":foot_r+Vector2(0,lift_r),"foot_lift_L":lift_l,"foot_lift_R":lift_r,"foot_contact_L":contact_l,"foot_contact_R":contact_r,"foot_rotation_L":foot_rotation_l,"foot_rotation_R":foot_rotation_r,"arm_L":[shoulder_l,shoulder_l,hand_l],"arm_R":[shoulder_r,shoulder_r,hand_r],"arm_bend_L":bend_l,"arm_bend_R":bend_r,"weapon_angle":weapon_angle,"tail_rotation":tail_rotation,"alpha":alpha,"blink":blink}
	connect_arms(pose)
	var hip_lateral := Vector2(aim.y*4.2+aim.x*.55,-aim.x*.8)
	pose["hip_L"] = torso+(Vector2(0,6)-hip_lateral).rotated(torso_rotation)
	pose["hip_R"] = torso+(Vector2(0,6)+hip_lateral).rotated(torso_rotation)
	pose["leg_forward"] = aim
	# The belt remains attached to the torso. Only the cloth below it reacts
	# to the returning knees and a delayed lateral swing, in model units.
	pose["cloth_sway"] = -torso_rotation*3.0
	pose["cloth_lift_L"] = lift_l*.34
	pose["cloth_lift_R"] = lift_r*.34
	if action in ["walk","run"] and not reduced:
		pose["cloth_sway"] += aim.x*sin(t*TAU-.45)*(1.25 if action=="run" else .85)
	# Screen-y shoulder sway is not camera depth. Keep that distinction so
	# front walk/run does not alternate the arm layers on every body roll.
	pose["arm_depth_L"] = -aim.x
	pose["arm_depth_R"] = aim.x
	if reduced and action in ["walk","run"]:
		# A neutral planted pose, rather than a frozen mid-stride split.
		return sample("idle",0,direction_index,appearance,true)
	return pose

static func _piece(canvas: CanvasItem, key: String, position: Vector2, rotation: float, scale: Vector2, tint: Color) -> void:
	var texture := part_texture(key)
	if texture == null:
		return
	var r: Array = manifest()["parts"][key]["rect"]
	canvas.draw_set_transform(position,rotation,scale)
	canvas.draw_texture_rect(texture,Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3])),false,tint)

static func _arm(canvas: CanvasItem, joints: Array, appearance: Dictionary, origin: Vector2, factor: float, tint: Color) -> void:
	var shoulder: Vector2 = joints[0]
	var elbow: Vector2 = joints[1]
	var hand: Vector2 = joints[2]
	var delta := elbow-shoulder
	canvas.draw_set_transform(origin,0,Vector2.ONE*factor)
	# A curved, tapered cloth surface replaces the rigid line and elbow ball.
	# Draw under the original sleeve cuff so the two pieces form one joint.
	_ribbon(canvas,forearm_curve(joints),2.45,1.55,OUTFIT_COLORS[appearance["outfit"]],tint)
	_piece(canvas,"sleeve_"+str(appearance["outfit"]),origin+shoulder*factor,Vector2.DOWN.angle_to(delta),Vector2(factor,factor*delta.length()/12),tint)
	_piece(canvas,"hand_"+str(appearance["body"]),origin+hand*factor,_hand_rotation(joints),Vector2.ONE*factor,tint)

static func _hand_rotation(joints: Array) -> float:
	return clampf(Vector2.DOWN.angle_to(Vector2(joints[2])-Vector2(joints[1])),-.7,.7)

static func _quadratic(a: Vector2, control: Vector2, b: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(9):
		var t := float(i)/8
		points.append(a.lerp(control,t).lerp(control.lerp(b,t),t))
	return points

static func forearm_curve(joints: Array) -> PackedVector2Array:
	var upper: Vector2 = joints[1]-joints[0]
	var lower: Vector2 = joints[2]-joints[1]
	var normal := Vector2(lower.y,-lower.x).normalized()
	# A midpoint control cannot double back when a raised hand folds tightly.
	var control: Vector2 = joints[1].lerp(joints[2],.5)+normal*clampf(upper.cross(lower)*.018,-.65,.65)
	return _quadratic(joints[1],control,joints[2])

static func ribbon_outline(points: PackedVector2Array, start_width: float, end_width: float) -> PackedVector2Array:
	var outline := PackedVector2Array()
	for edge in [1.0,-1.0]:
		for step in range(points.size()):
			var i := step if edge>0 else points.size()-1-step
			var tangent := (points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)]).normalized()
			var normal := Vector2(tangent.y,-tangent.x)
			var width := lerpf(start_width,end_width,float(i)/(points.size()-1))
			outline.append(points[i]+normal*width*edge)
	return outline

static func _ribbon(canvas: CanvasItem, points: PackedVector2Array, start_width: float, end_width: float, material: Color, tint: Color) -> void:
	var outline := ribbon_outline(points,start_width,end_width)
	var colors := PackedColorArray()
	for edge in [1.0,-1.0]:
		for i in range(points.size()):
			colors.append((material.lightened(.16) if edge>0 else material.darkened(.23))*tint)
	# Explicit ribbon quads remain drawable when a lifted knee folds the
	# outline over itself. A single concave polygon can fail triangulation.
	var n := points.size()
	for i in range(n-1):
		canvas.draw_primitive(PackedVector2Array([outline[i],outline[i+1],outline[2*n-2-i],outline[2*n-1-i]]),PackedColorArray([colors[i],colors[i+1],colors[2*n-2-i],colors[2*n-1-i]]),PackedVector2Array())
	var closed := outline.duplicate()
	closed.append(outline[0])
	canvas.draw_polyline(closed,Color("2b2521")*tint,.65,true)

static func _held_arm(canvas: CanvasItem, pose: Dictionary, side: String, look: Dictionary, action: String, origin: Vector2, factor: float, tint: Color) -> void:
	var joints: Array = pose["arm_"+side]
	_arm(canvas,joints,look,origin,factor,tint)
	var weapon := str(look["weapon"])
	if side=="R" and weapon!="unarmed":
		_piece(canvas,"weapon_"+weapon,origin+Vector2(joints[2])*factor,float(pose["weapon_angle"]),Vector2.ONE*factor,tint)
		_piece(canvas,"hand_"+str(look["body"]),origin+Vector2(joints[2])*factor,_hand_rotation(joints),Vector2.ONE*factor,tint)
		if weapon=="spear" and action=="attack":
			var support: Array = pose["arm_L"]
			_piece(canvas,"hand_"+str(look["body"]),origin+Vector2(support[2])*factor,_hand_rotation(support),Vector2.ONE*factor,tint)

static func leg_joints(pose: Dictionary, side: String) -> PackedVector2Array:
	var foot: Vector2 = pose["foot_"+side]
	var hip: Vector2 = pose["hip_"+side]
	var ankle := foot+Vector2(0,-5).rotated(float(pose["foot_rotation_"+side]))
	var forward: Vector2 = pose["leg_forward"]
	var reach := ankle-hip
	var length := minf(reach.length(),LEG_SEGMENT*2)
	var normal := Vector2(reach.y,-reach.x).normalized()
	# Two equal anatomical segments flex instead of growing with the stride.
	# Front/back knee flex is foreshortened; profile flex is fully visible.
	var bend := sqrt(maxf(0,LEG_SEGMENT*LEG_SEGMENT-length*length*.25))
	var projection := forward.x if absf(forward.x)>.1 else (-.18 if side=="L" else .18)
	var knee := hip.lerp(ankle,.5)+normal*bend*projection
	return PackedVector2Array([hip,knee,ankle])

static func coat_vertex(pose: Dictionary, point: Vector2) -> Vector2:
	var weight := _ease(3,15,point.y)
	var u := clampf((point.x+12)/24,0,1)
	var facing: Vector2 = pose["leg_forward"]
	if facing.y < 0:
		u = 1-u
	var lift := lerpf(float(pose["cloth_lift_L"]),float(pose["cloth_lift_R"]),u)
	return point+Vector2(float(pose["cloth_sway"])*weight,-lift*weight)

static func _coat(canvas: CanvasItem, key: String, pose: Dictionary, origin: Vector2, factor: float, tint: Color) -> void:
	var texture := part_texture(key)
	if texture==null:
		return
	var entry: Array = manifest()["parts"][key]["rect"]
	var rect := Rect2(float(entry[0]),float(entry[1]),float(entry[2]),float(entry[3]))
	canvas.draw_set_transform(origin+Vector2(pose["torso"])*factor,float(pose["torso_rotation"]),Vector2(pose["torso_scale"])*factor)
	# Each cell is convex, and UVs keep the original painted garment intact.
	# Eight rows localize the deformation below the waist without cut seams.
	for row in range(8):
		for column in range(4):
			var vertices := PackedVector2Array()
			var uvs := PackedVector2Array()
			for corner in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
				var uv: Vector2 = (Vector2(column,row)+corner)/Vector2(4,8)
				vertices.append(coat_vertex(pose,rect.position+rect.size*uv))
				uvs.append(uv)
			canvas.draw_polygon(vertices,PackedColorArray([tint]),uvs,texture)

static func _leg(canvas: CanvasItem, pose: Dictionary, side: String, d: int, boots: String, origin: Vector2, factor: float, tint: Color) -> void:
	var foot: Vector2 = pose["foot_"+side]
	var joints := leg_joints(pose,side)
	canvas.draw_set_transform(origin,0,Vector2.ONE*factor)
	_ribbon(canvas,_quadratic(joints[0],joints[1],joints[2]),2.6,1.9,Color("5b6158"),tint)
	var boot_key := "boot_%d" % d if boots == "cloth" else "boot_%s_%d" % [boots,d]
	_piece(canvas,boot_key,origin+foot*factor,float(pose["foot_rotation_"+side]),Vector2.ONE*factor,tint)

static func draw(canvas: CanvasItem, snapshot: Dictionary, offset: Vector2 = Vector2.ZERO, tint: Color = Color.WHITE) -> void:
	if snapshot.is_empty():
		return
	if not GuConceptCharacterArt.view_for(snapshot["appearance"],int(snapshot["direction_index"])).is_empty():
		GuConceptCharacterArt.draw(canvas,snapshot,offset,tint)
		return
	var look: Dictionary = snapshot["appearance"]
	var pose: Dictionary = snapshot["pose"]
	var d := int(snapshot["direction_index"])
	var factor := float(snapshot["scale"])
	var color := tint
	color.a *= float(pose["alpha"])
	var head: Vector2 = pose["head"]
	var is_back := d in [3,4,5]
	var hair := str(look["hair"])
	var boots := str(look.get("boots", "cloth"))
	var hat := str(look.get("hat", "none"))
	var tail_at := head+Vector2(0,-4 if hair=="topknot" else 4)
	if hair=="ponytail" and d in [1,2,6,7]:
		var facing_x := -1.0 if d in [1,2] else 1.0
		tail_at.x -= facing_x*(8.0 if d in [2,6] else 5.0)
	# Contact shadows track the grounded projection, fading under lifted feet.
	for side in ["L","R"]:
		var contact := float(pose.get("foot_contact_"+side,1))
		canvas.draw_set_transform(offset+(Vector2(pose.get("foot_ground_"+side,pose["foot_"+side]))+Vector2(0,3))*factor,0,Vector2(4.3,1.05)*factor)
		canvas.draw_circle(Vector2.ZERO,1,Color(.025,.045,.055,.20*contact*color.a),true,-1,true)
	# Far sleeve/tail sit behind the face and coat. Weapons remain attached.
	_piece(canvas,"tail_%s_%d" % [hair,d],offset+tail_at*factor,float(pose["tail_rotation"]),Vector2.ONE*factor,color)
	var far_arm := "L" if float(pose["arm_depth_L"])<=float(pose["arm_depth_R"])+.001 else "R"
	var near_arm := "R" if far_arm=="L" else "L"
	_held_arm(canvas,pose,far_arm,look,snapshot["action"],offset,factor,color)
	var far_leg := "L" if Vector2(pose["foot_ground_L"]).y < Vector2(pose["foot_ground_R"]).y else "R"
	_leg(canvas,pose,far_leg,d,boots,offset,factor,color)
	_leg(canvas,pose,"R" if far_leg=="L" else "L",d,boots,offset,factor,color)
	if is_back:
		_held_arm(canvas,pose,near_arm,look,snapshot["action"],offset,factor,color)
	_coat(canvas,"torso_%s_%s_%d" % [look["body"],look["outfit"],d],pose,offset,factor,color)
	var head_key := "head_%s_%s_%d" % [look["body"],hair,d]
	if float(pose.get("blink",0)) > .5 and not is_back:
		head_key += "_closed"
	_piece(canvas,head_key,offset+head*factor,float(pose["head_rotation"]),Vector2.ONE*factor,color)
	if not is_back:
		_held_arm(canvas,pose,near_arm,look,snapshot["action"],offset,factor,color)
	if is_back and hair=="ponytail":
		_piece(canvas,"tail_%s_%d" % [hair,d],offset+tail_at*factor,float(pose["tail_rotation"]),Vector2.ONE*factor,color)
	if hat != "none":
		_piece(canvas,"hat_%s_%d" % [hat,d],offset+head*factor,float(pose["head_rotation"]),Vector2.ONE*factor,color)
	canvas.draw_set_transform(Vector2.ZERO)
