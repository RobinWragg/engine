// rwtodo: I wonder if I can statically assert that the type was set?

Sphere :: struct {
  #as using entity : Entity;
  
  entity.init = (using self: *Entity) {
    vertices : [..]v3; defer array_free(vertices);
    add_sphere_triangles(*vertices, 16);
    
    add_vertices(*renderable, vertices);
  };
  
  entity.update = (using self: *Entity, dt: f32) {
    pos.x += dt;
  };
}
