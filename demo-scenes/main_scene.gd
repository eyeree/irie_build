extends Node3D
@onready var irie_build: Control = $IrieBuild

func _input(event: InputEvent) -> void:
	if event.is_action('IrieBuild_Activate'):
		irie_build.enabled = true
	if event.is_action('IrieBuild_Deactivate'):
		irie_build.enabled = false