class_name IrieBuildUtil
extends Object

static func get_child_of_type(node:Node, type:Variant) -> Node:
	var children = get_children_of_type(node, type)
	prints('found children of type', type, children)
	if children.size() == 0:
		return null
	else:
		return children[0]
		
static func get_children_of_type(node:Node, type:Variant) -> Array[Node]:
	return node.get_children().filter(
		func (value:Node): 
			return is_instance_of(value, type)
	)

static func has_child_of_type(node:Node, type:Variant) -> bool:
	for child:Node in node.get_children():
		if is_instance_of(child, type):
			return true
	return false
	
static func get_descendants_of_type(node:Node, type:Variant) -> Array[Node]:
	prints('get_descendants_of_type', node, type)
	var descendants:Array[Node] = node.get_children().filter(
		func (value:Node): 
			return is_instance_of(value, type)
	)
	prints('  descendants', descendants)
	for child:Node in node.get_children():
		descendants.append_array(get_descendants_of_type(child, type))
		prints('  appended descendants', descendants)
	return descendants

static func add_scene_child(parent:Node, child:Node):
	parent.add_child(child)
	var owner = parent.get_tree().edited_scene_root
	set_owner_recursively(child, owner)

static func set_owner_recursively(node:Node, owner:Node):
	node.owner = owner
	node.scene_file_path = ''
	for child:Node in node.get_children():
		set_owner_recursively(child, owner)
