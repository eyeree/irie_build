@tool
class_name IrieBuildSnapPoint
extends Node3D

const GROUP_COLORS = {
	"default": Color.PURPLE,
	"surface": Color.GREEN,
	"wall": Color.RED,
	"floor": Color.BLUE,
}

const SPHERE_SIZE = 0.04
const SPHERE_SEGMENTS = 16

static var _visual_mesh:SphereMesh = _create_visual_mesh()

static func _create_visual_mesh():
	var mesh:SphereMesh = SphereMesh.new()
	mesh.radius = SPHERE_SIZE
	mesh.height = SPHERE_SIZE * 2
	mesh.radial_segments = SPHERE_SEGMENTS
	mesh.rings = SPHERE_SEGMENTS
	return mesh

@export var group: String:
	set(value):
		group = value
		_create_visual()

var is_surface: bool

static var _materials: Dictionary = {}

func _ready():
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

	if not is_inside_tree():
		return

	var visual:MeshInstance3D = IrieBuildUtil.get_child_of_type(self, MeshInstance3D)
	if not visual:		
		visual = MeshInstance3D.new()
		visual.mesh = _visual_mesh
		add_child(visual)

	visual.material_override = _get_material(group)

func set_visible(value: bool):
	visible = value
