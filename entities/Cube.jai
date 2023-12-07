Cube :: struct {
  #as using entity : Entity;
  
  entity.init = (using self: *Entity) {
    positions : [..]v3; defer array_free(positions);
    add_cube_triangles(*positions);
    
    tex_coords : [..]v2; defer array_free(tex_coords);
    
    for positions {
      array_add(*tex_coords, it.xy);
    }
    
    for * positions {
      it.xy -= .{0.5, 0.5};
    }
    
    add_vertices(*renderable, positions, tex_coords=tex_coords, color=color_yellow, texture="rendered_texture_rwtodo");
  };
}
