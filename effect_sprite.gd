extends Sprite2D
class_name EffectSprite

@export var spritesheet_texture: Texture2D
@export var spritesheet_data_path: String
@export var fps: float = 20.0
@export var loop: bool = false

var frames: Array[Rect2] = []
var current_frame_index: float = 0.0
signal animation_finished

func _ready() -> void:
	if not texture and spritesheet_texture:
		texture = spritesheet_texture
	if not spritesheet_data_path.is_empty() and frames.is_empty():
		load_frames(spritesheet_data_path)

func setup(tex: Texture2D, data_path: String, anim_fps: float = 20.0, is_loop: bool = false) -> void:
	texture = tex
	fps = anim_fps
	loop = is_loop
	load_frames(data_path)

func load_frames(path: String) -> void:
	frames.clear()
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("=")
		if parts.size() == 2:
			var coords = parts[1].strip_edges().split(" ")
			if coords.size() >= 4:
				var r = Rect2(float(coords[0]), float(coords[1]), float(coords[2]), float(coords[3]))
				frames.append(r)
	if not frames.is_empty():
		region_enabled = true
		region_rect = frames[0]

func _process(delta: float) -> void:
	if frames.is_empty():
		return
	current_frame_index += fps * delta
	if current_frame_index >= frames.size():
		animation_finished.emit()
		if loop:
			current_frame_index = fmod(current_frame_index, float(frames.size()))
		else:
			queue_free()
			return
	region_rect = frames[int(current_frame_index)]
