@tool
class_name IrieBuildMode
extends Node3D

signal build_started(item: IrieBuildItem)
signal build_completed(item: IrieBuildItem)
signal build_cancelled()
signal snap_point_found(source_point: IrieBuildSnapPoint, target_point: IrieBuildSnapPoint)
signal snap_point_lost()

const SNAP_DISTANCE: float = 1.0
const SURFACE_SNAP_DISTANCE: float = 2.0

var active: bool = false:
	set(value):
		if active != value:
			active = value
			_on_active_changed()

var current_item: IrieBuildItem
var preview_item: IrieBuildItem
var camera: Camera3D
var snap_points_visible: bool = true

# Cache of nearby items for efficient snap point checking
var _nearby_items: Array[IrieBuildItem] = []
var _last_mouse_position: Vector2
var _dragging: bool = false

func _ready():
	set_process_input(false)
	set_process(false)

func start_build(item: IrieBuildItem):
	if active and current_item == null:
		current_item = item
		preview_item = item.duplicate()
		add_child(preview_item)
		_update_nearby_items()
		build_started.emit(item)
		
func cancel_build():
	if current_item:
		if preview_item:
			preview_item.queue_free()
		current_item = null
		preview_item = null
		build_cancelled.emit()

func complete_build() -> bool:
	if current_item and preview_item:
		# Create final item at preview location
		var final_item = current_item.duplicate()
		final_item.global_transform = preview_item.global_transform
		get_parent().add_child(final_item)
		
		# Clean up
		preview_item.queue_free()
		current_item = null
		preview_item = null
		
		build_completed.emit(final_item)
		return true
	return false

func _on_active_changed():
	set_process_input(active)
	set_process(active)
	if not active:
		cancel_build()

func _process(_delta):
	if current_item and preview_item:
		_update_preview_position()

func _update_preview_position():
	if not camera:
		return
		
	# Get mouse position in 3D space
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_from = camera.project_ray_origin(mouse_pos)
	var ray_to = ray_from + camera.project_ray_normal(mouse_pos) * 1000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_point = result.position
		
		# Check for snap points
		var snap_result = _find_nearest_snap_point(hit_point)
		if snap_result.size() > 0:
			var source_point = snap_result[0]
			var target_point = snap_result[1]
			
			# Calculate final position and rotation
			var rotation = _calculate_snap_rotation(source_point, target_point)
			var position = target_point.global_position - source_point.position.rotated(Vector3.UP, rotation.y)
			
			preview_item.global_position = position
			preview_item.global_rotation = rotation
			
			snap_point_found.emit(source_point, target_point)
		else:
			# No snap point found, just place at hit point
			preview_item.global_position = hit_point
			snap_point_lost.emit()

func _find_nearest_snap_point(position: Vector3) -> Array:
	var min_distance = SNAP_DISTANCE
	var nearest_source: IrieBuildSnapPoint
	var nearest_target: IrieBuildSnapPoint
	
	# Check each nearby item
	for item in _nearby_items:
		if item == current_item:
			continue
			
		# Check each combination of snap points
		for target_point in item.get_snap_points():
			var target_pos = target_point.global_position
			
			# Use larger distance for surface snap points
			var max_distance = SNAP_DISTANCE
			if target_point.is_surface:
				max_distance = SURFACE_SNAP_DISTANCE
			
			if target_pos.distance_to(position) > max_distance:
				continue
				
			for source_point in current_item.get_snap_points():
				# Skip incompatible groups
				if source_point.group != target_point.group:
					continue
					
				var distance = target_pos.distance_to(position)
				if distance < min_distance:
					min_distance = distance
					nearest_source = source_point
					nearest_target = target_point
	
	if nearest_source:
		return [nearest_source, nearest_target]
	return []

func _calculate_snap_rotation(source: IrieBuildSnapPoint, target: IrieBuildSnapPoint) -> Vector3:
	# Calculate rotation to align source normal with target normal
	var up = Vector3.UP
	var angle = source.normal.angle_to(target.normal)
	var axis = source.normal.cross(target.normal)
	
	if axis.length() < 0.001:
		# Normals are parallel, no rotation needed
		return Vector3.ZERO
	
	return axis.normalized() * angle

func _update_nearby_items():
	_nearby_items.clear()
	
	if not current_item:
		return
		
	# Get all IrieBuildItems in the scene
	var items = get_tree().get_nodes_in_group("irie_build_items")
	for item in items:
		if item is IrieBuildItem and item != current_item and item != preview_item:
			_nearby_items.append(item)

func _input(event):
	if not current_item or not preview_item:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_last_mouse_position = event.position
			elif _dragging:
				_dragging = false
				if event.position.distance_to(_last_mouse_position) < 2:
					# Click without drag - complete build
					complete_build()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_build()
