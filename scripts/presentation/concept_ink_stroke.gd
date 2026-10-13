class_name GuConceptInkStroke
extends RefCounted
## A solid ink core and a narrow alpha fringe in screen pixels. The default
## canvas polyline AA consumed most of a subpixel-wide outline's ink core.

static func geometry(path: PackedVector2Array, width: float, fringe: float, ink: Color) -> Array:
	var points := PackedVector2Array()
	for point in path:
		if points.is_empty() or point.distance_squared_to(points[-1])>.000001: points.append(point)
	if points.size()<2: return []
	var closed := points[0].distance_squared_to(points[-1])<.000001
	if closed: points.remove_at(points.size()-1)
	var vertices := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var half := width*.5
	for i in range(points.size()):
		var before := points[posmod(i-1,points.size())] if closed or i>0 else points[i]
		var after := points[(i+1)%points.size()] if closed or i<points.size()-1 else points[i]
		var incoming := (points[i]-before).normalized()
		var outgoing := (after-points[i]).normalized()
		if incoming==Vector2.ZERO: incoming=outgoing
		if outgoing==Vector2.ZERO: outgoing=incoming
		var normal := Vector2(-outgoing.y,outgoing.x)
		var bisector := Vector2(-incoming.y,incoming.x)+normal
		bisector=bisector.normalized() if bisector.length_squared()>.00001 else normal
		var miter := minf(1.7,1/maxf(.1,absf(bisector.dot(normal))))
		for distance in [-half-fringe,-half,half,half+fringe]:
			vertices.append(points[i]+bisector*distance*miter)
			var color := ink
			if absf(distance)>half+.00001: color.a=0
			colors.append(color)
	for i in range(points.size() if closed else points.size()-1):
		var next := (i+1)%points.size()
		for band in range(3):
			var a := i*4+band
			var b := next*4+band
			indices.append_array(PackedInt32Array([a,b,a+1,a+1,b,b+1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_COLOR]=colors
	arrays[Mesh.ARRAY_INDEX]=indices
	return arrays

static func draw(canvas: CanvasItem, path: PackedVector2Array, width: float, ink: Color) -> void:
	var screen_scale := maxf(.01,canvas.get_global_transform_with_canvas().x.length())
	var arrays := geometry(path,maxf(width,1.15/screen_scale),.38/screen_scale,ink)
	if arrays.is_empty(): return
	var frame := Engine.get_process_frames()
	if int(canvas.get_meta("concept_ink_frame",-1))!=frame:
		canvas.set_meta("concept_ink_frame",frame)
		canvas.set_meta("concept_ink_meshes",[])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	canvas.get_meta("concept_ink_meshes").append(mesh)
	canvas.draw_mesh(mesh,null)
