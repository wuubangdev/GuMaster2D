"""Create editable Blender sources from the exact baked Godot character variants.

Run with Blender, not the system Python:
  blender --background --factory-startup --python tools/author_character_assets.py --

The script retains topology, skin weights, named bones, imported animation tracks,
and existing UVs. It separates material geometry into meaningful collections and
packs the GLB's embedded textures. It does not perform an artist sculpt or remesh.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import struct
import sys

import bmesh
import bpy
from mathutils import Vector


CATEGORY_NAMES = {
    "BODY": "01_BODY — skin, face, hands",
    "OUTFIT": "02_OUTFIT — cloth, trim, boots, ornaments",
    "HAIR": "03_HAIR — hair cap, strands, ties",
    "WEAPON": "04_WEAPON — blade, shaft, grip, guard",
    "RIG": "00_RIG — shared named skeleton and animation",
    "HELPERS": "90_STUDIO — camera and lights; exclude from export",
}
EXPECTED_BONES = {
    "Hips", "Spine", "Chest", "Neck", "Head", "Shoulder_L", "UpperArm_L",
    "Forearm_L", "Hand_L", "Shoulder_R", "UpperArm_R", "Forearm_R", "Hand_R",
    "Thigh_L", "Shin_L", "Foot_L", "Thigh_R", "Shin_R", "Foot_R", "Hair",
    "Cape", "CapeTip",
}


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--inputs", nargs="+", type=Path, help="Explicit GLB files; default: six weapon/body variants")
    parser.add_argument("--output-dir", type=Path, help="Default: assets/characters/source")
    parser.add_argument("--validate-only", action="store_true", help="Reopen and verify existing .blend outputs")
    parser.add_argument("--roundtrip-dir", type=Path, help="Optional directory for verification GLBs exported from reopened .blend files")
    return parser.parse_args(argv)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def glb_json(path: Path) -> dict:
    content = path.read_bytes()
    magic, version, length = struct.unpack_from("<III", content)
    if magic != 0x46546C67 or version != 2 or length != len(content):
        raise RuntimeError(f"Invalid GLB 2 container: {path}")
    json_length, chunk_kind = struct.unpack_from("<II", content, 12)
    if chunk_kind != 0x4E4F534A:
        raise RuntimeError(f"GLB first chunk is not JSON: {path}")
    return json.loads(content[20:20 + json_length])


def move_collection(obj: bpy.types.Object, target: bpy.types.Collection) -> None:
    for owner in list(obj.users_collection):
        owner.objects.unlink(obj)
    target.objects.link(obj)


def remove_imported_bone_helpers() -> None:
    # Blender's GLTF importer creates an unskinned Icosphere custom shape even
    # in a factory-empty scene. It is an editor helper, not source geometry.
    helpers = set()
    for obj in bpy.data.objects:
        if obj.type == "ARMATURE":
            for bone in obj.pose.bones:
                if bone.custom_shape:
                    helpers.add(bone.custom_shape)
                    bone.custom_shape = None
    for helper in helpers:
        bpy.data.objects.remove(helper, do_unlink=True)


def collection(name: str, parent: bpy.types.Collection) -> bpy.types.Collection:
    result = bpy.data.collections.new(name)
    parent.children.link(result)
    return result


def material_key(obj: bpy.types.Object) -> str:
    material = obj.data.materials[0] if obj.data.materials else None
    name = material.name if material else obj.name
    return name.removeprefix("Gu_").rstrip("0123456789.")


def classify_faces(obj: bpy.types.Object) -> dict[str, set[int]]:
    key = material_key(obj)
    hand_groups = {group.index for group in obj.vertex_groups if group.name == "Hand_R"}
    face_categories: dict[str, set[int]] = {}
    for polygon in obj.data.polygons:
        if key in {"skin", "face_skin", "shadow_skin", "eye", "eye_white", "iris", "eyelid", "lip"}:
            kind = "BODY"
        elif key.startswith("hair"):
            kind = "HAIR"
        elif key.startswith("steel") or key.startswith("weapon"):
            kind = "WEAPON"
        elif key in {"gold", "leather", "jade"}:
            # Godot batches by material. Separate right-hand weapon hardware from
            # costume hardware using existing deform weights, without rebinding.
            weight = sum(
                group.weight
                for vertex_index in polygon.vertices
                for group in obj.data.vertices[vertex_index].groups
                if group.group in hand_groups
            ) / max(1, len(polygon.vertices))
            kind = "WEAPON" if weight > .8 else "OUTFIT"
        else:
            kind = "OUTFIT"
        face_categories.setdefault(kind, set()).add(polygon.index)
    return face_categories


def retain_faces(obj: bpy.types.Object, indices: set[int]) -> float:
    original_normals = {
        face.index: [tuple(obj.data.corner_normals[index].vector) for index in face.loop_indices]
        for face in obj.data.polygons
    }
    mesh = bmesh.new()
    mesh.from_mesh(obj.data)
    mesh.faces.ensure_lookup_table()
    source_layer = mesh.faces.layers.int.new("gu_source_face")
    for face in mesh.faces:
        face[source_layer] = face.index
    discard = [face for face in mesh.faces if face.index not in indices]
    bmesh.ops.delete(mesh, geom=discard, context="FACES_ONLY")
    unused_edges = [edge for edge in mesh.edges if not edge.link_faces]
    if unused_edges:
        bmesh.ops.delete(mesh, geom=unused_edges, context="EDGES")
    unused_vertices = [vertex for vertex in mesh.verts if not vertex.link_faces]
    if unused_vertices:
        bmesh.ops.delete(mesh, geom=unused_vertices, context="VERTS")
    mesh.to_mesh(obj.data)
    mesh.free()
    obj.data.update()
    # Preserve the source split normals at material boundaries. BMesh keeps UV
    # and deform layers but does not retain all custom corner normals by itself.
    source_faces = obj.data.attributes["gu_source_face"]
    normals = [None] * len(obj.data.loops)
    for face in obj.data.polygons:
        source_index = source_faces.data[face.index].value
        for loop_index, normal in zip(face.loop_indices, original_normals[source_index]):
            normals[loop_index] = normal
    obj.data.normals_split_custom_set(normals)
    maximum_error = max(
        (obj.data.corner_normals[index].vector.normalized() - Vector(normal).normalized()).length
        for index, normal in enumerate(normals)
    )
    if maximum_error > .003:
        raise RuntimeError(f"Source split normal directions changed: {obj.name}: {maximum_error}")
    obj.data.attributes.remove(source_faces)
    return maximum_error


def ensure_editable_uv(obj: bpy.types.Object) -> str:
    if obj.data.uv_layers:
        return "preserved"
    # Solid-colored body parts can lack UVs in a GLB. Add an authoring-only UV
    # layer without changing vertex coordinates, polygons, skin or source GLB.
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    obj.data.uv_layers.new(name="AuthoringUV")
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(island_margin=.02, angle_limit=math.radians(66))
    bpy.ops.object.mode_set(mode="OBJECT")
    return "created_for_solid_material"


def organize_meshes(groups: dict[str, bpy.types.Collection]) -> tuple[dict[str, str], float]:
    uv_results = {}
    maximum_normal_error = 0.0
    for original in list(bpy.data.objects):
        if original.type != "MESH":
            continue
        selections = classify_faces(original)
        key = material_key(original)
        if len(selections) == 1:
            kind = next(iter(selections))
            original.name = f"{kind.title()}_{key}"
            original.data.name = f"Mesh_{original.name}"
            move_collection(original, groups[kind])
            uv_results[original.name] = ensure_editable_uv(original)
            continue
        for kind, indices in selections.items():
            duplicate = original.copy()
            duplicate.data = original.data.copy()
            duplicate.name = f"{kind.title()}_{key}"
            duplicate.data.name = f"Mesh_{duplicate.name}"
            groups[kind].objects.link(duplicate)
            maximum_normal_error = max(maximum_normal_error, retain_faces(duplicate, indices))
            uv_results[duplicate.name] = ensure_editable_uv(duplicate)
        bpy.data.objects.remove(original, do_unlink=True)
    return uv_results, maximum_normal_error


def pack_images() -> list[dict]:
    result = []
    for image in bpy.data.images:
        if image.source not in {"FILE", "GENERATED"} or image.size[0] == 0:
            continue
        image.pack()
        if not image.packed_file and not image.packed_files:
            raise RuntimeError(f"Image could not be packed: {image.name}")
        result.append({"name": image.name, "size": list(image.size), "colorspace": image.colorspace_settings.name})
    return result


def studio_setup(group: bpy.types.Collection) -> None:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 1200
    scene.render.resolution_y = 1200
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.fps = 24
    scene.world = bpy.data.worlds.new("CharacterStudio_World")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (.09, .12, .16, 1)
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = .45
    camera_data = bpy.data.cameras.new("Studio_Orthographic")
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 2.85
    camera = bpy.data.objects.new("Studio_Camera", camera_data)
    group.objects.link(camera)
    camera.location = (3.1, -5.0, 3.15)
    camera.rotation_euler = (Vector((0, 0, 1.05)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera
    for name, location, color, energy, size in [
        ("Key_Warm", (2.8, -3.3, 4.8), (1, .84, .68), 500, 3.0),
        ("Fill_Cool", (-3.0, -1.8, 2.5), (.66, .80, 1), 320, 3.2),
        ("Rim", (1.4, 3.0, 3.4), (.72, .94, 1), 700, 2.0),
    ]:
        data = bpy.data.lights.new(name, "AREA")
        data.energy = energy
        data.color = color
        data.shape = "DISK"
        data.size = size
        light = bpy.data.objects.new(name, data)
        group.objects.link(light)
        light.location = location
        light.rotation_euler = (Vector((0, 0, 1)) - light.location).to_track_quat("-Z", "Y").to_euler()
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                space = area.spaces.active
                space.shading.type = "MATERIAL"
                space.overlay.show_floor = False
                space.region_3d.view_distance = 3.8
                space.region_3d.view_location = (0, 0, 1.1)
                space.region_3d.view_rotation = camera.rotation_euler.to_quaternion()


def character_stats() -> dict:
    meshes = [obj for obj in bpy.data.objects if obj.type == "MESH"]
    armatures = [obj for obj in bpy.data.objects if obj.type == "ARMATURE"]
    if len(armatures) != 1:
        raise RuntimeError(f"Expected one character skeleton, found {len(armatures)}")
    rig = armatures[0]
    bones = {bone.name for bone in rig.data.bones}
    if bones != EXPECTED_BONES:
        raise RuntimeError(f"Skeleton contract changed: missing {EXPECTED_BONES - bones}; extra {bones - EXPECTED_BONES}")
    for obj in meshes:
        if not obj.data.vertices or not obj.data.polygons:
            raise RuntimeError(f"Empty mesh: {obj.name}")
        if not any(mod.type == "ARMATURE" and mod.object == rig for mod in obj.modifiers):
            raise RuntimeError(f"Lost armature deformation: {obj.name}")
        for vertex in obj.data.vertices:
            if not all(math.isfinite(value) for value in vertex.co):
                raise RuntimeError(f"Non-finite geometry: {obj.name}")
            total_weight = sum(group.weight for group in vertex.groups)
            if not .99 <= total_weight <= 1.01:
                raise RuntimeError(f"Unnormalized skin weights: {obj.name}: {total_weight}")
    categories = {}
    surface_records = []
    for obj in meshes:
        category = obj.name.split("_", 1)[0].upper()
        categories[category] = categories.get(category, 0) + sum(len(face.vertices) - 2 for face in obj.data.polygons)
        uv_layer = obj.data.uv_layers[0] if obj.data.uv_layers else None
        group_names = {group.index: group.name for group in obj.vertex_groups}
        for face in obj.data.polygons:
            material = obj.data.materials[face.material_index].name
            corners = []
            for loop_index in face.loop_indices:
                vertex = obj.data.vertices[obj.data.loops[loop_index].vertex_index]
                weights = sorted((group_names[group.group], round(group.weight, 6)) for group in vertex.groups)
                uv = tuple(round(value, 6) for value in uv_layer.data[loop_index].uv) if uv_layer else ()
                corners.append((tuple(round(value, 6) for value in vertex.co), weights, uv))
            surface_records.append((material, corners))
    surface_fingerprint = hashlib.sha256(json.dumps(sorted(surface_records), separators=(",", ":")).encode()).hexdigest()
    return {
        "bone_count": len(bones), "bones": sorted(bones),
        "mesh_objects": len(meshes), "vertices": sum(len(obj.data.vertices) for obj in meshes),
        "triangles": sum(sum(len(face.vertices) - 2 for face in obj.data.polygons) for obj in meshes),
        "category_triangles": categories,
        "actions": sorted(action.name for action in bpy.data.actions),
        "materials": sorted(material.name for material in bpy.data.materials),
        "uv_meshes": sum(bool(obj.data.uv_layers) for obj in meshes),
        "surface_skin_uv_fingerprint": surface_fingerprint,
    }


def notes(source: Path, input_hash: str, clip_names: list[str]) -> None:
    text = bpy.data.texts.new("START_HERE — Character editing contract")
    text.write(
        "GuMaster2D original modular character source\n"
        f"Generated from: {source.name}\nSHA256: {input_hash}\n\n"
        "Body/outfit/hair/weapon collections retain the imported polygons, vertex groups, UVs and armature modifiers.\n"
        "Images are packed. Solid material parts may have an extra authoring UV layer.\n"
        "No destructive subdivision, remesh, automatic rebind or hand-sculpt pass was performed.\n"
        "Animation actions and stashed NLA clips are imported from the exact Godot weapon variant.\n"
        f"Clip names in source GLB: {', '.join(clip_names)}\n\n"
        "Keep all 22 bone names and hierarchy; origin is at the feet; do not apply the armature modifier.\n"
        "Export only character meshes plus rig, without 90_STUDIO helpers. glTF uses +Y up automatically.\n"
        "Use GLB, skinning and animations enabled; save edits in a separate .blend before exporting.\n"
        "The running prototype still builds original assets from Godot character_model.gd.\n"
        "A Blender edit is an authoring asset until a dedicated imported-art runtime adapter is adopted.\n"
    )


def make_source(source: Path, output: Path, project: Path) -> dict:
    input_hash = sha256(source)
    gltf = glb_json(source)
    clip_names = [item["name"] for item in gltf.get("animations", [])]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source), import_pack_images=True, bone_heuristic="BLENDER")
    remove_imported_bone_helpers()
    before = character_stats()
    if set(before["actions"]) != set(clip_names):
        raise RuntimeError("Blender did not import every named GLB animation clip")
    top = collection("GU_CHARACTER — editable original asset", bpy.context.scene.collection)
    groups = {key: collection(name, top) for key, name in CATEGORY_NAMES.items()}
    for obj in list(bpy.data.objects):
        if obj.type != "MESH":
            move_collection(obj, groups["RIG"])
            if obj.type == "ARMATURE":
                obj.name = "Gu_SharedRig"
                obj.data.name = "Gu_22BoneSkeleton"
                obj.data.display_type = "STICK"
                obj.show_in_front = False
    uv_results, maximum_normal_error = organize_meshes(groups)
    packed = pack_images()
    for action in bpy.data.actions:
        action.use_fake_user = True
    rig = next(obj for obj in bpy.data.objects if obj.type == "ARMATURE")
    rig.animation_data_create()
    for track in rig.animation_data.nla_tracks:
        track.mute = True
    reset = bpy.data.actions.get("RESET")
    if reset:
        rig.animation_data.action = reset
        if reset.slots:
            rig.animation_data.action_slot = reset.slots[0]
    studio_setup(groups["HELPERS"])
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 48
    bpy.context.scene.frame_set(1)
    bpy.context.scene["source_glb"] = str(source.relative_to(project))
    bpy.context.scene["source_sha256"] = input_hash
    bpy.context.scene["asset_authoring_stage"] = "Editable generated mesh; sculpt and retopology are future art work"
    notes(source, input_hash, clip_names)
    after = character_stats()
    if before["triangles"] != after["triangles"]:
        raise RuntimeError(f"Topology changed during collection split: {before['triangles']} -> {after['triangles']}")
    if len(after["actions"]) != len(before["actions"]):
        raise RuntimeError("Imported animation actions were lost")
    if before["uv_meshes"] == before["mesh_objects"] and before["surface_skin_uv_fingerprint"] != after["surface_skin_uv_fingerprint"]:
        raise RuntimeError("Surface positions, vertex skin weights or existing UVs changed during collection split")
    bpy.ops.object.select_all(action="DESELECT")
    active_mesh = next(obj for obj in bpy.data.objects if obj.type == "MESH" and obj.name.startswith("Outfit_cloth"))
    active_mesh.select_set(True)
    bpy.context.view_layer.objects.active = active_mesh
    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(output), check_existing=False, compress=True)
    # Verify the saved asset, rather than trusting an in-memory scene.
    bpy.ops.wm.open_mainfile(filepath=str(output))
    reopened = character_stats()
    if after != reopened:
        raise RuntimeError(f"Saved Blender source failed reopen validation: {output.name}")
    for image in bpy.data.images:
        if image.size[0] and image.source in {"FILE", "GENERATED"} and not (image.packed_file or image.packed_files):
            raise RuntimeError(f"Saved source has unpacked image: {image.name}")
    return {
        "source_glb": str(source.relative_to(project)), "source_sha256": input_hash,
        "blend": str(output.relative_to(project)), "blend_sha256": sha256(output),
        "clip_names_in_glb": clip_names, "packed_images": packed,
        "uv_authoring": uv_results, "geometry_preserved": True, "reopen_validated": True,
        "maximum_split_normal_direction_error": maximum_normal_error,
        **reopened,
    }


def export_roundtrip(source: Path, output_dir: Path) -> dict:
    output_dir.mkdir(parents=True, exist_ok=True)
    destination = output_dir / source.name
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.data.objects:
        if obj.type in {"ARMATURE", "MESH"}:
            obj.select_set(True)
    bpy.context.view_layer.objects.active = next(obj for obj in bpy.data.objects if obj.type == "ARMATURE")
    bpy.ops.export_scene.gltf(
        filepath=str(destination), export_format="GLB", use_selection=True,
        export_animations=True, export_skins=True, export_animation_mode="ACTIONS",
        export_frame_range=False, export_anim_slide_to_zero=True,
        export_cameras=False, export_lights=False,
    )
    exported = glb_json(destination)
    original = glb_json(source)
    bone_names = {exported["nodes"][index]["name"] for skin in exported.get("skins", []) for index in skin["joints"]}
    clips = {animation["name"] for animation in exported.get("animations", [])}
    if bone_names != EXPECTED_BONES or clips != {animation["name"] for animation in original.get("animations", [])}:
        raise RuntimeError(f"Blender GLB roundtrip lost a bone or animation: {source.name}")
    if exported.get("cameras") or "KHR_lights_punctual" in exported.get("extensions", {}):
        raise RuntimeError(f"Studio helpers leaked into character export: {source.name}")
    original_triangles = sum(original["accessors"][primitive["indices"]]["count"] // 3 for mesh in original["meshes"] for primitive in mesh["primitives"])
    exported_triangles = sum(exported["accessors"][primitive["indices"]]["count"] // 3 for mesh in exported["meshes"] for primitive in mesh["primitives"])
    if original_triangles != exported_triangles:
        raise RuntimeError(f"Blender export changed polygon count: {source.name}")
    report = {"source_glb": source.name, "roundtrip_glb": str(destination), "bones": len(bone_names),
              "clips": sorted(clips), "triangles": exported_triangles, "meshes": len(exported["meshes"]),
              "images": len(exported.get("images", [])), "source_sha256": sha256(source),
              "roundtrip_sha256": sha256(destination), "studio_helpers_excluded": True}
    print("CHARACTER_BLEND_ROUNDTRIP_OK " + json.dumps(report), flush=True)
    return report


def main() -> None:
    args = parse_args()
    project = args.project.resolve()
    output_dir = (args.output_dir or project / "assets/characters/source").resolve()
    inputs = args.inputs or [
        project / "assets/characters" / f"gu_{body}_{weapon}.glb"
        for body in ("male", "female") for weapon in ("sword", "spear", "unarmed")
    ]
    sources = [(path if path.is_absolute() else project / path).resolve() for path in inputs]
    missing = [str(path) for path in sources if not path.is_file()]
    if missing:
        raise SystemExit("Wait for the final Godot export before creating Blender sources. Missing: " + ", ".join(missing))
    output_dir.mkdir(parents=True, exist_ok=True)
    # Blender authoring sources are not runtime resources. Godot would otherwise
    # try to launch a machine-specific Blender installation during project import.
    ignore_file = output_dir / ".gdignore"
    if not ignore_file.exists():
        ignore_file.write_text("", encoding="utf-8")
    existing_records = {}
    if args.validate_only:
        manifest_path = output_dir / "source_manifest.json"
        if not manifest_path.is_file():
            raise RuntimeError("Source manifest is missing; generate the authoring sources first")
        previous = json.loads(manifest_path.read_text(encoding="utf-8"))
        existing_records = {Path(entry["blend"]).name: entry for entry in previous["sources"]}
    result = []
    roundtrips = []
    for source in sources:
        output = output_dir / f"{source.stem}.blend"
        if args.validate_only:
            entry_from_manifest = existing_records.get(output.name)
            if not entry_from_manifest or sha256(output) != entry_from_manifest["blend_sha256"]:
                raise RuntimeError(f"Blender source changed after generation: {output.name}; save artist edits as a separate variant")
            bpy.ops.wm.open_mainfile(filepath=str(output))
            if bpy.context.scene.get("source_sha256") != sha256(source):
                raise RuntimeError(f"Blender source is stale: {output.name}")
            entry = {"blend": str(output.relative_to(project)), "reopen_validated": True, **character_stats()}
        else:
            entry = make_source(source, output, project)
        result.append(entry)
        print("CHARACTER_BLEND_OK " + json.dumps(entry, ensure_ascii=False), flush=True)
        if args.roundtrip_dir:
            roundtrip_dir = (args.roundtrip_dir if args.roundtrip_dir.is_absolute() else project / args.roundtrip_dir).resolve()
            roundtrips.append(export_roundtrip(source, roundtrip_dir))
    if not args.validate_only:
        manifest = {"generator": "tools/author_character_assets.py", "blender": bpy.app.version_string,
                    "origin": "Original Godot-generated characters; Blender organizational authoring sources",
                    "sources": result}
        (output_dir / "source_manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if args.roundtrip_dir:
        (roundtrip_dir / "roundtrip_manifest.json").write_text(json.dumps({"blender": bpy.app.version_string, "results": roundtrips}, indent=2) + "\n", encoding="utf-8")
    print(f"CHARACTER_AUTHORING_OK {len(result)} editable Blender sources", flush=True)


if __name__ == "__main__":
    main()
