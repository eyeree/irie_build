@tool
class_name ReplExt
extends Object

var ep = EditorPlugin.new()
var ei = ep.get_editor_interface()

## The currently selected nodes in the editor.
var SELECTED_NODES:
    get():
        return ei.get_selection().get_selected_nodes()

## The first (or only) of the currently selected nodes in the editor.
var SELECTED_NODE:
    get():
        var selected_nodes = SELECTED_NODES
        var selected_node 
        if selected_nodes.size() == 0:
            return null
        else:
            return selected_nodes[0]

