class_name GuWeaponRig
extends RefCounted
## Shared geometry/animation grip contract, expressed in local Hand_R space.
## Only weapon vertices receive grip_transform. Skin and palms keep their rests.

const FAMILIES: Array[String] = ["sword", "spear", "unarmed"]
const SPEAR_SUPPORT_DISTANCE: float = 0.34


static func family(weapon: String) -> String:
	return weapon if weapon in FAMILIES else "sword"


static func grip_transform(weapon: String) -> Transform3D:
	if family(weapon) == "spear":
		return Transform3D(Basis(Vector3.RIGHT, PI), Vector3.ZERO)
	return Transform3D.IDENTITY


static func support_grip(weapon: String) -> Vector3:
	if family(weapon) == "spear":
		return grip_transform(weapon) * Vector3(0.0, SPEAR_SUPPORT_DISTANCE, -0.025)
	return Vector3.ZERO


static func weapon_tip(weapon: String) -> Vector3:
	match family(weapon):
		"spear":
			return grip_transform(weapon) * Vector3(0.0, 1.0, -0.025)
		"sword":
			return Vector3(0.0, -0.83, -0.034)
	return Vector3(0.0, -0.070, -0.045)


static func support_states(weapon: String) -> Array[String]:
	if family(weapon) == "spear":
		return ["idle", "walk", "run", "attack", "defend"]
	return []
