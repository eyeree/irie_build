@tool
class_name IrieBuildItem
extends Node3D

var size: Vector3
var wrapper_node: Node3D
var wrapped_node: Node3D
var snap_points_node: Node3D

@export var tags: PackedStringArray = []

@export var snap_points_visible: bool = true:
	set(value):
		snap_points_visible = value
		_update_snap_point_visibility()

func _ready():
	if Engine.is_editor_hint():
		snap_points_visible = true

func set_content(node: Node3D):
	prints('IrieBuildItem.set_content', node)
	_init_wrapper_and_wrapped(node)
	_init_position_and_rotation()
	_init_collision_shapes()
	_init_snap_points()
	_init_tags()
	add_child(wrapper_node)
	name = wrapper_node.name
	set_display_folded(true)

func _init_tags():
	# capitalize handles "_" and CamelCase
	tags = wrapper_node.name.replace('-', ' ').capitalize().to_lower().split(" ")
	prints("  tags:", wrapper_node.name, '->', tags)
	
func _init_wrapper_and_wrapped(node: Node3D):
	var node3d_children = IrieBuildUtil.get_children_of_type(node, Node3D)
	if node is MeshInstance3D || node3d_children.size() != 1:
		wrapped_node = node
		wrapper_node = Node3D.new()
		wrapper_node.add_child(wrapped_node)
		wrapper_node.name = wrapped_node.name
		wrapper_node.editor_description = wrapped_node.editor_description
	else:
		wrapper_node = node
		wrapped_node = node3d_children[0]

func _init_position_and_rotation():
	var wrapped_bounds: AABB = _calculate_spatial_bounds(wrapped_node, true)
	
	prints('  wrapped_node.position:', wrapped_node.position, '(before)')
	prints('  wrapped_bounds:', wrapped_bounds)
	wrapped_node.position = -(wrapped_bounds.position - -(wrapped_bounds.size / 2))		
	prints('  wrapped_node.position:', wrapped_node.position, '(after)')
	
	prints('  wrapped_bounds:', wrapped_bounds)
	if wrapped_bounds.size.z > wrapped_bounds.size.x:
		wrapper_node.rotation = Vector3(0, PI / 2, 0)
		wrapped_bounds = AABB(
			Vector3(wrapped_bounds.position.z, wrapped_bounds.position.y, wrapped_bounds.position.x),
			Vector3(wrapped_bounds.size.z, wrapped_bounds.size.y, wrapped_bounds.size.x)
		)
		prints('  adjusted wrapped_bounds:', wrapped_bounds)
	else:
		wrapper_node.rotation = Vector3.ZERO
	prints('  wrapper_node.rotation:', wrapped_node.rotation)
	
	size = wrapped_bounds.size

func _init_collision_shapes():
	prints('  _init_collision_shape')
	if wrapped_node is MeshInstance3D:
		_init_collision_shape(wrapped_node)
	else:
		var meshes = IrieBuildUtil.get_descendants_of_type(wrapped_node, MeshInstance3D)
		for mesh: MeshInstance3D in meshes:
			_init_collision_shape(mesh)

func _init_collision_shape(mesh: MeshInstance3D):
	if not IrieBuildUtil.has_child_of_type(mesh, StaticBody3D):
		mesh.create_trimesh_collision()
		var static_body:StaticBody3D = IrieBuildUtil.get_child_of_type(mesh, StaticBody3D)
		static_body.visible = false

func _calculate_spatial_bounds(parent: Node3D, exclude_top_level_transform: bool) -> AABB:
	var bounds: AABB = AABB()
	if parent is VisualInstance3D:
		bounds = parent.get_aabb()

	for i in range(parent.get_child_count()):
		var child: Node3D = parent.get_child(i)
		if child:
			var child_bounds: AABB = _calculate_spatial_bounds(child, false)
			if bounds.size == Vector3.ZERO && parent:
				bounds = child_bounds
			else:
				bounds = bounds.merge(child_bounds)
	if !exclude_top_level_transform:
		bounds = parent.transform * bounds
	return bounds

func _init_snap_points():
	# Clear existing snap points by removing the old container
	if snap_points_node:
		snap_points_node.queue_free()
	
	# Create new container
	snap_points_node = Node3D.new()
	snap_points_node.name = "SnapPoints"
	add_child(snap_points_node)
	
	# Classify object and generate appropriate snap points
	var object_type = _classify_object()
	match object_type:
		"panel":
			_add_panel_snap_points()
		"pole":
			_add_pole_snap_points()
		"box":
			_add_box_snap_points()
	
	_update_snap_point_visibility()

func _classify_object() -> String:
	# Calculate ratios relative to the largest dimension
	var max_dim = max(size.x, max(size.y, size.z))
	var ratios = Vector3(
		size.x / max_dim,
		size.y / max_dim,
		size.z / max_dim
	)
	
	# Count how many dimensions are "short" (20% or less of the longest dimension)
	var short_count = 0
	if ratios.x <= 0.2: short_count += 1
	if ratios.y <= 0.2: short_count += 1
	if ratios.z <= 0.2: short_count += 1
	
	# Classify based on number of short dimensions
	match short_count:
		1: return "panel"
		2: return "pole"
		_: return "box"

func _add_panel_snap_points():
	var half_size = size / 2
	prints('  _add_panel_snap_points', size, half_size)
	
	# Find which dimension is short
	var short_axis = ""
	var short_value = 0
	var long_axes = []
	
	if size.x <= 0.2 * max(size.y, size.z):
		short_axis = "x"
		short_value = 0 # half_size.x
		long_axes = ["y", "z"]
	elif size.y <= 0.2 * max(size.x, size.z):
		short_axis = "y"
		short_value = 0 # half_size.y
		long_axes = ["x", "z"]
	elif size.z <= 0.2 * max(size.x, size.y):
		short_axis = "z"
		short_value = 0 # half_size.z
		long_axes = ["x", "y"]
	
	# Add snap points at corners
	for i in [-1, 1]:
		for j in [-1, 1]:
			var pos = Vector3.ZERO
			var normal = Vector3.ZERO
			
			match short_axis:
				"x":
					pos = Vector3(short_value, i * half_size.y, j * half_size.z)
					normal = Vector3.RIGHT if short_value > 0 else Vector3.LEFT
				"y":
					pos = Vector3(i * half_size.x, short_value, j * half_size.z)
					normal = Vector3.UP if short_value > 0 else Vector3.DOWN
				"z":
					pos = Vector3(i * half_size.x, j * half_size.y, short_value)
					normal = Vector3.BACK if short_value > 0 else Vector3.FORWARD
			
			add_snap_point(pos, normal)

func _add_pole_snap_points():
	var half_size = size / 2
	prints('  _add_pole_snap_points', size, half_size)
	
	# Find which dimension is long
	var long_axis = ""
	var long_value = 0
	
	if size.x > 0.2 * max(size.y, size.z):
		long_axis = "x"
		long_value = half_size.x
	elif size.y > 0.2 * max(size.x, size.z):
		long_axis = "y"
		long_value = half_size.y
	elif size.z > 0.2 * max(size.x, size.y):
		long_axis = "z"
		long_value = half_size.z
	
	# Add snap points at ends
	match long_axis:
		"x":
			add_snap_point(Vector3(long_value, 0, 0), Vector3.RIGHT)
			add_snap_point(Vector3(-long_value, 0, 0), Vector3.LEFT)
		"y":
			add_snap_point(Vector3(0, long_value, 0), Vector3.UP)
			add_snap_point(Vector3(0, -long_value, 0), Vector3.DOWN)
		"z":
			add_snap_point(Vector3(0, 0, long_value), Vector3.BACK)
			add_snap_point(Vector3(0, 0, -long_value), Vector3.FORWARD)

func _add_box_snap_points():
	var half_size = size / 2
	prints('  _add_box_snap_points', size, half_size)
	
	# Add snap points at all corners
	for x in [-1, 1]:
		for y in [-1, 1]:
			for z in [-1, 1]:
				var pos = Vector3(
					x * half_size.x,
					y * half_size.y,
					z * half_size.z
				)
				# Use the corner's position normalized as the normal
				var normal = pos.normalized()
				add_snap_point(pos, normal)

func add_snap_point(position: Vector3, normal: Vector3, group: String = "default"):
	prints('      add_snap_point', position)
	var snap_point = IrieBuildSnapPoint.new(position, normal, group)
	snap_points_node.add_child(snap_point)

func get_snap_points() -> Array[IrieBuildSnapPoint]:
	var children:Array[Node] = snap_points_node.get_children()
	var as_snap_points:Array[IrieBuildSnapPoint]
	as_snap_points.assign(children)
	return as_snap_points

func get_snap_points_in_group(group: String) -> Array[IrieBuildSnapPoint]:
	return get_snap_points().filter(func(point): return point.group == group)

func _update_snap_point_visibility():
	if snap_points_node:
		snap_points_node.visible = snap_points_visible and Engine.is_editor_hint()
