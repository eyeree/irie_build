@tool
class_name IrieBuildSnapPoint
extends Node3D

const GROUP_COLORS = {
	"default": Color(1, 1, 1),  # White
	"surface": Color(0, 1, 0),  # Green
	"wall": Color(1, 0, 0),     # Red
	"floor": Color(0, 0, 1),    # Blue
}

const SPHERE_SIZE = 0.06
const SPHERE_SEGMENTS = 16

var group: String
var is_surface: bool

var _sphere: CSGSphere3D

static var _materials: Dictionary = {}

func _init(pos: Vector3 = Vector3.ZERO, grp: String = "default", surface: bool = false):
	position = pos
	group = grp
	is_surface = surface
	_create_visual()

static func _get_material(group: String) -> StandardMaterial3D:
	if not group in _materials:
		var material = StandardMaterial3D.new()
		material.albedo_color = GROUP_COLORS.get(group, GROUP_COLORS["default"])
		material.emission_enabled = true
		material.emission = material.albedo_color
		material.emission_energy_multiplier = 1.0
		_materials[group] = material
	return _materials[group]

func _create_visual():
	_sphere = CSGSphere3D.new()
	_sphere.radius = SPHERE_SIZE
	_sphere.radial_segments = SPHERE_SEGMENTS
	_sphere.rings = SPHERE_SEGMENTS / 2
	_sphere.material = _get_material(group)
	add_child(_sphere)

func set_visible(value: bool):
	visible = value
