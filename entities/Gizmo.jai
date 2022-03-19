// rwtodo: I wonder if I can statically assert that the type was set?

Gizmo :: struct {
  using entity : Entity;
  
  entity.init = (self: *Entity) {
    using cast(*Gizmo) self; // rwsubltodo
    
    if cube.data {
      array_reset(*cube);
    }
    
    add_cube_triangles(*cube, cube_size);
    
    add_vertices(*renderable, cube, color=color_white);
    add_vertices(*renderable, arrow_x, color=color_red);
    add_vertices(*renderable, arrow_y, color=color_green);
    add_vertices(*renderable, arrow_z, color=color_blue);
    add_vertices(*renderable, plane_xy, color=color_yellow);
    add_vertices(*renderable, plane_yz, color=color_cyan);
    add_vertices(*renderable, plane_zx, color=color_magenta);
  };
  
  entity.update = (self: *Entity, dt: f32) { // rwsubltodo
    using cast(*Gizmo) self;
    
    scene_dir := window_pos_to_scene_direction(cursor_window_pos);
    
    transformed_cube := t_apply_entity_transform(cube, self);
    
    // rwtodo: this produces true when triangles align behind the 'camera'.
    
    for 0..(transformed_cube.count-1)/3 {
      tri_vert_0 := transformed_cube[it * 3];
      tri_vert_1 := transformed_cube[it * 3 + 1];
      tri_vert_2 := transformed_cube[it * 3 + 2];
      
      tri_edge_0 := normalize(tri_vert_1 - tri_vert_0);
      assert(is_unit(tri_edge_0));
      tri_edge_1 := normalize(tri_vert_2 - tri_vert_1);
      assert(is_unit(tri_edge_1));
      
      tri_normal := normalize(cross(tri_edge_0, tri_edge_1));
      assert(is_unit(tri_normal));
      
      edge_0_right_angle := cross(tri_edge_0, tri_normal);
      assert(is_unit(edge_0_right_angle));
      
      tri_vert_0_2d := project_onto_plane(tri_vert_0, tri_edge_0, edge_0_right_angle);
      tri_vert_1_2d := project_onto_plane(tri_vert_1, tri_edge_0, edge_0_right_angle);
      tri_vert_2_2d := project_onto_plane(tri_vert_2, tri_edge_0, edge_0_right_angle);
      
      success, cursor_on_tri_plane := intersect_line_and_plane(
        camera_pos,
        scene_dir,
        tri_vert_0,
        tri_normal);
      
      if success {
        cursor_2d := project_onto_plane(cursor_on_tri_plane, tri_edge_0, edge_0_right_angle);
        result := point_is_in_triangle(cursor_2d, tri_vert_0_2d, tri_vert_1_2d, tri_vert_2_2d);
        
        if result {
          print("This is a temporary CPU implementation of entity-under-mouse detection. ");
          break;
        }
      }
    }
  };
  
  cube_size :: 0.25;
  arrow_size :: 0.75;
  plane_outer :: 1.0;
  plane_inner :: 0.5;
  
  cube : [..]v3;
  arrow_x :: v3.[
    .{1, 0, 0}, .{1-arrow_size, 0, 0}, .{1-arrow_size, cube_size, 0},
    .{1, 0, 0}, .{1-arrow_size, 0, cube_size}, .{1-arrow_size, 0, 0},
    .{1, 0, 0}, .{1-arrow_size, cube_size, 0}, .{1-arrow_size, 0, cube_size}
  ];
  arrow_y :: v3.[
    .{0, 1, 0}, .{cube_size, 1-arrow_size, 0}, .{0, 1-arrow_size, 0},
    .{0, 1, 0}, .{0, 1-arrow_size, 0}, .{0, 1-arrow_size, cube_size},
    .{0, 1, 0}, .{0, 1-arrow_size, cube_size}, .{cube_size, 1-arrow_size, 0}
  ];
  arrow_z :: v3.[
    .{0, 0, 1}, .{0, 0, 1-arrow_size}, .{cube_size, 0, 1-arrow_size},
    .{0, 0, 1}, .{0, cube_size, 1-arrow_size}, .{0, 0, 1-arrow_size},
    .{0, 0, 1}, .{cube_size, 0, 1-arrow_size}, .{0, cube_size, 1-arrow_size}
  ];
  plane_xy :: v3.[
    .{plane_inner, plane_inner, 0}, .{plane_outer, plane_inner, 0}, .{plane_outer, plane_outer, 0},
    .{plane_inner, plane_outer, 0}, .{plane_inner, plane_inner, 0}, .{plane_outer, plane_outer, 0},
  ];
  plane_yz :: v3.[
    .{plane_inner, 0, plane_inner}, .{plane_outer, 0, plane_inner}, .{plane_outer, 0, plane_outer},
    .{plane_inner, 0, plane_outer}, .{plane_inner, 0, plane_inner}, .{plane_outer, 0, plane_outer},
  ];
  plane_zx :: v3.[
    .{0, plane_inner, plane_inner}, .{0, plane_outer, plane_inner}, .{0, plane_outer, plane_outer},
    .{0, plane_inner, plane_outer}, .{0, plane_inner, plane_inner}, .{0, plane_outer, plane_outer},
  ];
  
  camera_pos : v3;
  cursor_window_pos : v2;
}
