@tool
class_name IrieBuild
extends Node

signal build_mode_changed(enabled: bool)
signal build_started(item: IrieBuildItem)
signal build_completed(item: IrieBuildItem)
signal build_cancelled()

@export var enabled: bool = false:
	set(value):
		if enabled != value:
			enabled = value
			_enabled_changed()

@export_node_path("Camera3D") var editor_camera_path: NodePath
@export_node_path("Camera3D") var game_camera_path: NodePath

var build_mode: IrieBuildMode
var current_set: IrieBuildSet
var editor_camera: Camera3D
var game_camera: Camera3D

func _ready() -> void:
	# Initialize build mode
	build_mode = IrieBuildMode.new()
	build_mode.name = "BuildMode"
	add_child(build_mode)
	
	# Connect signals
	build_mode.build_started.connect(_on_build_started)
	build_mode.build_completed.connect(_on_build_completed)
	build_mode.build_cancelled.connect(_on_build_cancelled)
	
	# Initial state
	_enabled_changed()
	
	# Get cameras
	if not editor_camera_path.is_empty():
		editor_camera = get_node(editor_camera_path)
	if not game_camera_path.is_empty():
		game_camera = get_node(game_camera_path)

func _enabled_changed():
	if enabled:
		_initialize_build_set()
	if build_mode:
		build_mode.active = enabled
		build_mode_changed.emit(enabled)

func _initialize_build_set():
	if not current_set:
		current_set = IrieBuildSet.new()
		current_set.name = "BuildSet"
		add_child(current_set)

func start_build(item: IrieBuildItem):
	if enabled and build_mode:
		var cam = editor_camera if Engine.is_editor_hint() else game_camera
		build_mode.camera = cam
		build_mode.start_build(item)

func cancel_build():
	if build_mode:
		build_mode.cancel_build()

func complete_build() -> bool:
	if build_mode:
		return build_mode.complete_build()
	return false

func _on_build_started(item: IrieBuildItem):
	build_started.emit(item)

func _on_build_completed(item: IrieBuildItem):
	build_completed.emit(item)

func _on_build_cancelled():
	build_cancelled.emit()

# Editor integration
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if editor_camera_path.is_empty():
		warnings.append("No editor camera assigned")
	if game_camera_path.is_empty():
		warnings.append("No game camera assigned")
	
	return warnings
