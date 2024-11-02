IrieBuild supports level creation in the Godot editor and in game build systems. Features:

* bulk import objects for automated processing:
    * adjust for origins not at the center of the object
    * normalize rotation so the thin and long edges of walls, etc. are consistent
    * layout objects in the library scene so they don't overlap, for easier editing
    * organize objects into groups based on names
    * add collision shapes if they don't already exist
    * determine default snap points for meshes
* flexible snap configuration
    * create multiple snap groups so objects can only connect in logical ways
    * supports snapping to surfaces (e.g. place table anywhere on a floor and a cup anywhere on a table)
    * supports free placement and grid placement of objects, as configured
    * ability to validate object placement via custom code
* customizable UI
    * provides complete ui for selecting objects
        * ui can be styled to match other game ui
        * individual components can instead be integrated with game ui
    * uses project input map, can be bound to any controls
        * default bindings for keyboard/mouse and game pad are provided
    * provides an optional build mode camera allowing:
        * easy movement in 3 dimensions
        * focus on selected objects
        * jump to top and side views
        * save and restore views
* in editor building
    * places objects in the scene tree, scene can be edited independency as needed
* in game building
    * supports save/load of built content
    * dynamically created or imported meshes can be turned into a build object at runtime
* supports complex builds:
    * undo/redo
    * cut/copy/paste
    * save and edit reusable sub-assemblies (changes can be applied automatically)
    * object replacement (swap an old object for a new one everywhere it is used)
    * layout of multiple objects (grid, array, circle, etc)

