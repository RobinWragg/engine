// rwtodo: I wonder if I can statically assert that the type was set?

Curiosity :: struct {
  using entity : Entity;
  
  entity.init = (using self: *Entity) {
    vertices := load_obj_file("meshes_unbaked/curiosity.obj"); defer array_free(vertices);
    add_vertices(*renderable, vertices, color=color_yellow);
  };
}