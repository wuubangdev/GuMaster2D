class_name GuConceptClothGuides
extends RefCounted
## Five deform controls along a sleeve. They bend cloth, never anatomical IK.
## The shoulder/elbow endpoints stay fixed; a bounded bow relaxes its middle.

static func sample(source: PackedVector2Array, chain: PackedVector2Array) -> PackedVector2Array:
	var upper := (source[1]-source[0]).angle_to(chain[1]-chain[0])
	var lower := (source[2]-source[1]).angle_to(chain[2]-chain[1])
	var turn := wrapf(lower-upper,-PI,PI)
	var axis := (chain[1]-chain[0]).normalized()
	var normal := Vector2(-axis.y,axis.x)
	var controls := PackedVector2Array()
	for i in range(5):
		var t := float(i)/4
		controls.append(chain[0].lerp(chain[1],t)+normal*(.12*sin(turn)*sin(t*PI)))
	return controls

static func offset_at(point: Vector2, source: PackedVector2Array, chain: PackedVector2Array, controls: PackedVector2Array) -> Vector2:
	var axis := source[1]-source[0]
	var t := clampf((point-source[0]).dot(axis)/axis.length_squared(),0,1)*4
	var i := mini(3,floori(t))
	var first := controls[i]-chain[0].lerp(chain[1],float(i)/4)
	var last := controls[i+1]-chain[0].lerp(chain[1],float(i+1)/4)
	return first.lerp(last,t-i)
