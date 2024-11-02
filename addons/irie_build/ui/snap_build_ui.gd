extends Control

@export var enabled:bool = false:
	set(value):
		enabled = value
		_enabled_changed()

func _enabled_changed():
	visible = enabled
	
func _ready() -> void:
	_enabled_changed()
