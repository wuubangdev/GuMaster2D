extends SceneTree
## Build opacity resources only. The approved color images remain untouched.
## Connected paper outside the ink silhouette becomes transparent in shader;
## enclosed faces, ivory collars and painted highlights retain their pixels.

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/concept-rig/manifest.json"))
	var outlines := {"revision":manifest["revision"],"views":{},"removed_fragments":{},"simplification_source_pixels":1.25}
	for name in ["character-concept-01","character-directions-02"]:
		var path := "res://assets/characters/concept-rig/%s.png" % name
		var source_texture: Texture2D = load(path)
		if source_texture==null:
			quit(1)
			return
		var image := source_texture.get_image()
		if image==null:
			quit(1)
			return
		if image.is_compressed():
			image.decompress()
		image.convert(Image.FORMAT_RGBA8)
		var pixels := image.get_data()
		var width := image.get_width()
		var height := image.get_height()
		var total := width*height
		var paper := PackedByteArray()
		paper.resize(total)
		for index in range(total):
			var red: int=pixels[index*4]
			var green: int=pixels[index*4+1]
			var blue: int=pixels[index*4+2]
			paper[index]=1 if red>=155 and green>=135 and blue>=92 and red>=green-3 and green>=blue+10 and red-green<=64 and red-blue<=112 else 0
		var outside := PackedByteArray()
		outside.resize(total)
		var queue := PackedInt32Array()
		queue.resize(total)
		var tail := 0
		for y in range(height):
			for x in [0,width-1]:
				var index: int = y*width+x
				if paper[index]==1 and outside[index]==0:
					outside[index]=1
					queue[tail]=index
					tail+=1
		for x in range(width):
			for y in [0,height-1]:
				var index: int = y*width+x
				if paper[index]==1 and outside[index]==0:
					outside[index]=1
					queue[tail]=index
					tail+=1
		var head := 0
		while head<tail:
			var index: int=queue[head]
			head+=1
			for delta in [-1,1,-width,width]:
				var next: int=index+delta
				if next<0 or next>=total or (delta==-1 and index%width==0) or (delta==1 and index%width==width-1):
					continue
				if paper[next]==1 and outside[next]==0:
					outside[next]=1
					queue[tail]=next
					tail+=1
		var mask := PackedByteArray()
		mask.resize(total)
		for index in range(total):
			mask[index]=0 if outside[index]==1 else 255
		if name=="character-concept-01":
			# The pale blade has open ink strokes. Paper flood removal otherwise
			# erases its painted interior together with the surrounding backdrop.
			var blade := PackedVector2Array()
			for point: Array in manifest["sword"]["blade_interior"]:
				blade.append(Vector2(float(point[0]),float(point[1])))
			var allowed := PackedByteArray()
			allowed.resize(total)
			allowed.fill(255)
			_paint(mask,allowed,width,height,blade,255)
		var mask_image := Image.create_from_data(width,height,false,Image.FORMAT_L8,mask)
		var texture := ImageTexture.create_from_image(mask_image)
		var output := "res://assets/characters/concept-rig/%s-matte.res" % name
		assert(ResourceSaver.save(texture,output,ResourceSaver.FLAG_COMPRESS)==OK)
		print("CONCEPT_MATTE ",name," ",width,"x",height," outside-paper=",tail," color-source unchanged")
		var source := "original" if name=="character-concept-01" else "directions"
		var ownership := PackedByteArray()
		ownership.resize(total)
		var transferred_paint := PackedByteArray()
		transferred_paint.resize(total)
		# One owner per source pixel. Torso and head hide the original pixels
		# under sleeves, so swinging an arm cannot drag a second belt or face.
		for view: Dictionary in manifest["views"].values():
			if view["source"]!=source: continue
			for part_id in ["leg_L","leg_R","arm_L","arm_R","torso","head"]:
				var polygon := PackedVector2Array()
				var authored: Array = view["parts"][part_id]["polygon"]
				for point: Array in authored:
					polygon.append(Vector2(float(point[0]),float(point[1])))
				_paint(ownership,mask,width,height,polygon,int(manifest["layer_ids"][part_id])*32)
			# Torso priority used to keep green shoulder/cuff paint on the
			# standing chest. Transfer only the authored sleeve side of each
			# view's ink seam, clipped to the mesh that actually renders it.
			for part_id: String in view.get("sleeve_seams",{}):
				var seam := PackedVector2Array()
				for point: Array in view["sleeve_seams"][part_id]: seam.append(Vector2(float(point[0]),float(point[1])))
				# Complete stitch zone: the former arm-polygon intersection left
				# genuine sleeve pigment behind on the standing chest.
				_paint(ownership,mask,width,height,seam,int(manifest["layer_ids"][part_id])*32,false,0,true,transferred_paint)
			# A profile hand can rest across the coat. Its source pixels must
			# leave with the wrist, while the upper sleeve stays under the chest.
			for part_id in ["arm_L","arm_R"]:
				var polygon := PackedVector2Array()
				for point: Array in view["parts"][part_id]["polygon"]:
					polygon.append(Vector2(float(point[0]),float(point[1])))
				var elbow: Array = view["parts"][part_id]["joints"][1]
				_paint(ownership,mask,width,height,polygon,int(manifest["layer_ids"][part_id])*32,false,float(elbow[1])-9)
			var keep := PackedVector2Array()
			for point: Array in view["torso_keep"]: keep.append(Vector2(point[0],point[1]))
			var body_bounds := _part_bounds(view["parts"]["torso"]["polygon"],width,height)
			for y in range(body_bounds.position.y,body_bounds.end.y):
				for x in range(body_bounds.position.x,body_bounds.end.x):
					var index := y*width+x
					if ownership[index]==64 and not Geometry2D.is_point_in_polygon(Vector2(x+.5,y+.5),keep): ownership[index]=0
			_clean_soles(ownership,width,height,view)
			if view.has("baked_weapon"):
				var hidden := PackedVector2Array()
				for point: Array in view["baked_weapon"]:
					hidden.append(Vector2(float(point[0]),float(point[1])))
				_paint(ownership,mask,width,height,hidden,0)
		if source=="original":
			var polygon := PackedVector2Array()
			for point: Array in manifest["sword"]["polygon"]:
				polygon.append(Vector2(float(point[0]),float(point[1])))
			_paint(ownership,mask,width,height,polygon,7*32)
		for view_key: String in manifest["views"]:
			var view: Dictionary = manifest["views"][view_key]
			if view["source"]!=source: continue
			var parts := {}
			var removed := {}
			for part_id: String in view["parts"]:
				var region := _part_bounds(view["parts"][part_id].get("render_polygon",view["parts"][part_id]["polygon"]),width,height)
				removed[part_id]=_clean_fragments(ownership,width,region,int(manifest["layer_ids"][part_id])*32,part_id.begins_with("leg_"),transferred_paint)
				parts[part_id]=_trace_outline(ownership,width,region,int(manifest["layer_ids"][part_id])*32)
			# The completed chest has its own geometric boundary and is
			# clipped to painted silhouette opacity. It must not fill paper
			# outside the coat with a rectangular strip of green underpaint.
			# New, independently drawn SVG cloth owns its whole clean boundary,
			# including regions the standing arm hid in the reference. Never use
			# source opacity (which contains old arm shapes) as its silhouette.
			parts["body_core"]=[view["body_core"]]
			outlines["views"][view_key]=parts
			outlines["removed_fragments"][view_key]=removed
		var layer_image := Image.create_from_data(width,height,false,Image.FORMAT_L8,ownership)
		assert(ResourceSaver.save(ImageTexture.create_from_image(layer_image),"res://assets/characters/concept-rig/%s-layers.res" % name,ResourceSaver.FLAG_COMPRESS)==OK)
		print("CONCEPT_LAYERS ",name," exclusive source-pixel ownership")
	var output := FileAccess.open("res://assets/characters/concept-rig/contours.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(outlines))
	output.close()
	print("CONCEPT_VECTOR_CONTOURS ",outlines["views"].size()," views")
	quit()

func _part_bounds(polygon: Array, width: int, height: int) -> Rect2i:
	var low := Vector2(width,height)
	var high := Vector2.ZERO
	for point: Array in polygon:
		low=low.min(Vector2(float(point[0]),float(point[1])))
		high=high.max(Vector2(float(point[0]),float(point[1])))
	var first := Vector2i(maxi(0,floori(low.x)-2),maxi(0,floori(low.y)-2))
	var last := Vector2i(mini(width,ceili(high.x)+3),mini(height,ceili(high.y)+3))
	return Rect2i(first,last-first)

func _clean_fragments(ownership: PackedByteArray, width: int, region: Rect2i, owner: int, boot: bool, protected: PackedByteArray) -> int:
	var visited := PackedByteArray()
	visited.resize(region.size.x*region.size.y)
	var components: Array[PackedInt32Array] = []
	var largest := 0
	for y in range(region.size.y):
		for x in range(region.size.x):
			var local := y*region.size.x+x
			var global := (y+region.position.y)*width+x+region.position.x
			if visited[local]!=0 or ownership[global]!=owner: continue
			var queue := PackedInt32Array([local])
			visited[local]=1
			var head := 0
			while head<queue.size():
				var at := queue[head]
				head+=1
				var p := Vector2i(at%region.size.x,at/region.size.x)
				for offset: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					var next: Vector2i = p+offset
					if next.x<0 or next.y<0 or next.x>=region.size.x or next.y>=region.size.y: continue
					var id := next.y*region.size.x+next.x
					if visited[id]!=0 or ownership[(next.y+region.position.y)*width+next.x+region.position.x]!=owner: continue
					visited[id]=1
					queue.append(id)
			components.append(queue)
			largest=maxi(largest,queue.size())
	var removed := 0
	for component in components:
		if component.size()==largest or (not boot and component.size()>=8): continue
		var authored := false
		for at in component: authored=authored or protected[(at/region.size.x+region.position.y)*width+at%region.size.x+region.position.x]!=0
		if authored: continue
		for at in component:
			ownership[(at/region.size.x+region.position.y)*width+at%region.size.x+region.position.x]=0
			removed+=1
	return removed

func _trace_outline(ownership: PackedByteArray, width: int, region: Rect2i, owner: int) -> Array:
	var bitmap := BitMap.new()
	bitmap.create(region.size)
	for y in range(region.size.y):
		for x in range(region.size.x):
			if ownership[(y+region.position.y)*width+x+region.position.x]==owner: bitmap.set_bit(x,y,true)
	var contours := []
	for polygon in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO,region.size),1.25):
		if polygon.size()<3: continue
		var points := []
		# Round only two source pixels at each reduced corner. Ink cusps and
		# hair silhouettes stay recognizable; pixel staircase corners disappear.
		for i in range(polygon.size()):
			var previous: Vector2 = polygon[posmod(i-1,polygon.size())]
			var point: Vector2 = polygon[i]
			var next: Vector2 = polygon[(i+1)%polygon.size()]
			var radius := minf(2.8,minf(point.distance_to(previous),point.distance_to(next))*.24)
			var a := point+(previous-point).normalized()*radius
			var b := point+(next-point).normalized()*radius
			for sample in range(4):
				var t := float(sample)/3
				var rounded := (1-t)*(1-t)*a+2*(1-t)*t*point+t*t*b+Vector2(region.position)
				points.append([snappedf(rounded.x,.001),snappedf(rounded.y,.001)])
		contours.append(points)
	return contours

func _paint(ownership: PackedByteArray, mask: PackedByteArray, width: int, height: int, polygon: PackedVector2Array, value: int, empty_only: bool=false, min_y: float=0, preserve_head: bool=false, protected: PackedByteArray=PackedByteArray()) -> void:
	var low := polygon[0]
	var high := polygon[0]
	for point in polygon:
		low = low.min(point)
		high = high.max(point)
	for y in range(maxi(0,floori(maxf(low.y,min_y))),mini(height,ceili(high.y)+1)):
		for x in range(maxi(0,floori(low.x)),mini(width,ceili(high.x)+1)):
			var index := y*width+x
			if mask[index]==0 or (empty_only and ownership[index]!=0): continue
			if preserve_head and ownership[index]==32: continue
			if Geometry2D.is_point_in_polygon(Vector2(x+.5,y+.5),polygon):
				if not protected.is_empty() and ownership[index]==64: protected[index]=255
				ownership[index]=value

func _clean_soles(ownership: PackedByteArray, width: int, height: int, view: Dictionary) -> void:
	# Remove narrow ground-ink tendrils that touch a boot in the concept.
	# Opening affects opacity only and is restricted to the sole neighbourhood.
	var original := ownership.duplicate()
	var ground: Array = view["ground"]
	for y in range(int(ground[1])-19,mini(height-2,int(ground[1])+2)):
		for x in range(maxi(2,int(ground[0])-80),mini(width-2,int(ground[0])+81)):
			var index := y*width+x
			var owner: int = original[index]
			if owner!=5*32 and owner!=6*32: continue
			var keep := false
			for dy in [-1,0,1]:
				for dx in [-1,0,1]:
					var solid := true
					for ky in [-1,0,1]:
						for kx in [-1,0,1]:
							solid = solid and original[(y+dy+ky)*width+x+dx+kx]==owner
					keep = keep or solid
			if not keep: ownership[index]=0
