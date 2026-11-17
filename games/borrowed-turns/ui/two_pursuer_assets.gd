extends RefCounted
## Immutable standee sources and puppet textures.

static func standees() -> Dictionary:
	var textures := {}
	var assembly := {}
	var files := {"player": "player", "A": "enemy-a", "B": "enemy-b"}
	var baselines := {"player": 1406.0, "A": 1432.0, "B": 1420.0}
	print("Borrowed Turns two-pursuers: loading approved standee sources")
	for id in files:
		var texture = load("res://assets/standees/two-pursuers/%s.png" % files[id])
		if not texture is Texture2D or texture.get_size() != Vector2(1024, 1536):
			return {"error": "Approved standee source could not be loaded: " + id}
		textures[id] = texture
		assembly[id] = {"canvas": Vector2(1024, 1536), "foot": Vector2(512, baselines[id]),
			"height_fraction": 0.28}
	print("Borrowed Turns two-pursuers: all three original standees loaded")
	return {"textures": textures, "assembly": assembly}

static func puppets(directory: String) -> Dictionary:
	print("Borrowed Turns two-pursuers: loading puppet pack: ", directory)
	var result := {}
	for name in ["a-body", "a-hands", "b-body", "b-hands", "p-lantern"]:
		var path := directory.path_join(name + ".png")
		var texture: Texture2D
		var image: Image
		if path.begins_with("res://"):
			if ResourceLoader.exists(path, "Texture2D"):
				var resource = load(path)
				if resource is Texture2D:
					texture = resource
					image = texture.get_image()
		elif FileAccess.file_exists(path):
			image = Image.load_from_file(path)
			if image != null and not image.is_empty():
				texture = ImageTexture.create_from_image(image)
		if image == null:
			return {"error": "Puppet pack is missing or cannot load %s. Supply --puppet-pack=<prepared-directory>. No substitute art will be used." % path}
		var expected := Vector2i(145, 145) if name == "p-lantern" else Vector2i(290, 145)
		if image == null or image.is_empty() or image.get_size() != expected or image.detect_alpha() == Image.ALPHA_NONE:
			return {"error": "Puppet image needs its native RGBA canvas: " + path}
		result[name.replace("-", "_")] = texture
	print("Borrowed Turns two-pursuers: five native puppet textures loaded")
	return {"textures": result}
