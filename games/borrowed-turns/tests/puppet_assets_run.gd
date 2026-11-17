extends SceneTree
## Controlled external-pack loader tests. Source pixels belong to this test.

const Assets = preload("res://ui/two_pursuer_assets.gd")
const NAMES = ["a-body", "a-hands", "b-body", "b-hands", "p-lantern"]
var failures := 0
var directory := ""

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("Puppet assets: " + message)

func write_image(name: String, size: Vector2i, transparent: bool) -> void:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.4, 0.6, 1.0))
	if transparent: image.set_pixel(0, 0, Color(0.0, 0.0, 0.0, 0.0))
	check(image.save_png(directory.path_join(name + ".png")) == OK, "write fixture " + name)

func _initialize() -> void:
	directory = "user://puppet-assets-test-%d" % Time.get_ticks_usec()
	check(DirAccess.make_dir_recursive_absolute(directory) == OK, "create fixture directory")
	for name in NAMES:
		write_image(name, Vector2i(145, 145) if name == "p-lantern" else Vector2i(290, 145), true)
	var loaded: Dictionary = Assets.puppets(directory)
	check(not loaded.has("error"), "valid external pack loads")
	if loaded.has("textures"):
		for name in NAMES:
			var texture = loaded.textures.get(name.replace("-", "_"))
			check(texture is Texture2D, "texture exists: " + name)
			if texture is Texture2D:
				var source := Image.load_from_file(directory.path_join(name + ".png"))
				check(texture.get_image().get_data() == source.get_data(), "source pixels preserved: " + name)
	DirAccess.remove_absolute(directory.path_join("a-body.png"))
	check(Assets.puppets(directory).has("error"), "missing file rejected")
	write_image("a-body", Vector2i(1, 1), true)
	check(Assets.puppets(directory).has("error"), "wrong dimensions rejected")
	write_image("a-body", Vector2i(290, 145), false)
	check(Assets.puppets(directory).has("error"), "opaque image rejected")
	for name in NAMES:
		check(DirAccess.remove_absolute(directory.path_join(name + ".png")) == OK, "remove fixture " + name)
	check(DirAccess.remove_absolute(directory) == OK, "remove fixture directory")
	print("Puppet assets controlled loader: %d failures" % failures)
	quit(1 if failures else 0)
