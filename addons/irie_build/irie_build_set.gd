@tool
class_name IrieBuildSet
extends Node

signal item_imported(path: String, item: IrieBuildItem)
signal item_added(item: IrieBuildItem)
signal item_removed(item: IrieBuildItem)

const SEPARATION_DISTANCE:float = 0.5

@export var show_snap_points: bool = true:
	set(value):
		show_snap_points = value
		_update_snap_point_visibility()

@export var reset_layout:bool = false:
	set(value):
		reset_layout = false
		_reset_layout()
		_layout_items()

var _items_by_group: Dictionary = {}
	
func _ready() -> void:
	prints('IrieBuildSet._ready')
	child_entered_tree.connect(_on_child_entered_tree)

func _on_child_entered_tree(node: Node) -> void:
	prints('IrieBuildSet._on_child_entered_tree', node)
	if node is Node3D and not node is IrieBuildItem:
		call_deferred('import_node', node)

func import_node(node:Node):
	prints('IrieBuildSet.import_node', node)
	if node.is_inside_tree():
		node.get_parent().remove_child(node)
	if node is Node3D:
		var item = IrieBuildItem.new()
		item.set_content(node)
		var path = "/"  # Root path since we're not organizing in subfolders anymore
		item_imported.emit(path, item)
		add_item(path.substr(1), item)
	else:
		push_error('Cannot import item of type %s' % node.get_class())
		node.queue_free()

func add_item(path: String, item: IrieBuildItem):
	# Add to scene directly (no Items node anymore)
	IrieBuildUtil.add_scene_child(self, item)
	
	# Add to snap build group
	item.add_to_group("irie_build_items")
	
	# Index by snap groups
	for point in item.get_snap_points():
		if not point.group in _items_by_group:
			_items_by_group[point.group] = []
		if not item in _items_by_group[point.group]:
			_items_by_group[point.group].append(item)
	
	# Set snap point visibility
	item.snap_points_visible = show_snap_points
	
	# Layout the items
	_layout_items()
	
	item_added.emit(item)

func remove_item(item: IrieBuildItem):
	# Remove from scene
	if item.get_parent():
		item.get_parent().remove_child(item)
	
	# Remove from snap build group
	item.remove_from_group("irie_build_items")
	
	# Remove from group index
	for group in _items_by_group.keys():
		_items_by_group[group].erase(item)
		if _items_by_group[group].is_empty():
			_items_by_group.erase(group)
	
	item_removed.emit(item)

func get_items() -> Array[IrieBuildItem]:
	var items: Array[IrieBuildItem] = []
	for node in get_tree().get_nodes_in_group("irie_build_items"):
		if node is IrieBuildItem:
			items.append(node)
	return items

func get_items_in_group(group: String) -> Array[IrieBuildItem]:
	if group in _items_by_group:
		return _items_by_group[group]
	return []

func get_snap_groups() -> Array[String]:
	return _items_by_group.keys()

func _update_snap_point_visibility():
	for item in get_items():
		item.snap_points_visible = show_snap_points

func _reset_layout():
	for item:IrieBuildItem in get_items():
		item.position = Vector3.ZERO		
		
func _layout_items():
	var x:float = 0.0
	for item:IrieBuildItem in get_items():
		item.position = Vector3(x + item.size.x / 2, item.size.y / 2, 0.0)
		x += item.size.x
		x += SEPARATION_DISTANCE

func _exit_tree():
	# Clean up all items
	for item in get_items():
		remove_item(item)
