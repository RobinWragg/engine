
editor_init :: () {
  capture_mouse(should_look);
  camera.pos.z = 1.7;
  camera.mode = .LIT_COLOR;
  
  rendered_texture_name = "rendered_texture_rwtodo";
  make_texture(64, 64, rendered_texture_name);
  
  floor_grid = make_floor_grid();
  
  init(*demo_entity);
  demo_entity.pos.x = -8;
  demo_entity.pos.z = 0.8;
  
  sphere := New(Sphere);
  sphere.initial_pos = .{1, 3, 2};
  array_add(*entities, sphere);
  selected_entity = sphere;
  
  cube := New(Cube);
  cube.initial_pos = .{0, -3, 0};
  array_add(*entities, cube);
  
  for entities {
    init(it);
  }
  
  init(*gizmo);
}

editor_update :: (dt: f32) {
  mouse_sensitivity : f32 = 0.01;
  walk_speed : f32 = 5; // meters per second
  
  if input.key_event(SDLK_SPACE, true) {
    should_look = !should_look;
    capture_mouse(should_look);
  }
  
  if input.key_event(#char "i") {
    for entities {
      deinit(it);
      init(it);
    }
  }
  
  if input.key_event(#char "u") {
    should_update = !should_update;
  }
  
  cursor_window_pos : v2;
  
  if should_look {
    // Mouse delta is per-frame, so the changes to camera.yaw and camera.pitch are framerate-independent.
    camera.yaw += input.mouse.delta.x * mouse_sensitivity;
    camera.pitch += input.mouse.delta.y * mouse_sensitivity;
    
    camera.pos.xy += rotate(input.wasd, -camera.yaw) * dt * walk_speed;
    if input.key_state(#char "q") camera.pos.z -= dt * walk_speed;
    if input.key_state(#char "e") camera.pos.z += dt * walk_speed;
    
    cursor_window_pos = make_vector2(window.aspect_ratio/2, 0.5);
  } else {
    cursor_window_pos = input.mouse;
  }
  
  if should_update {
    for entities {
      update(it, dt);
    }
  }
  
  gizmo.camera_pos = camera.pos;
  gizmo.cursor_window_pos = cursor_window_pos;
  update(*gizmo, dt);
}

editor_render :: () {
  set_output_to_texture(rendered_texture_name);
  render_internal(true);
  set_output_to_display();
  render_internal(false);
}

#scope_file

should_look := false;
should_update := true;

entities : [..]*Entity;
gizmo : Gizmo;
demo_entity : Cube;
selected_entity : *Entity;
camera : Camera;
floor_grid : Renderable = ---;
rendered_texture_name : string = ---;

make_floor_grid :: () -> Renderable {
  dark_verts : [..]v3;
  dark_verts.allocator = __temporary_allocator;
  bright_verts : [..]v3;
  bright_verts.allocator = __temporary_allocator;
  
  for x : 0..9 {
    for y : 0..9 {
      vertices : *[..]v3;
      
      if (x + y) % 2 == 0 vertices = *dark_verts;
      else vertices = *bright_verts;
      
      grid_square_pos : v3;
      grid_square_pos.x = cast(f32) x;
      grid_square_pos.y = cast(f32) y;
      grid_square_pos.z = -0.01;
      array_add(vertices, grid_square_pos);
      
      grid_square_vertex_a := grid_square_pos;
      grid_square_vertex_a.x += 1.0; 
      array_add(vertices, grid_square_vertex_a);
      
      grid_square_vertex_b := grid_square_pos;
      grid_square_vertex_b.y += 1.0;
      array_add(vertices, grid_square_vertex_b);
      
      grid_square_vertex_c := grid_square_pos + v3.{1, 1, 0};
      array_add(vertices, grid_square_vertex_b);
      array_add(vertices, grid_square_vertex_a);
      array_add(vertices, grid_square_vertex_c);
    }
  }
  
  color_dark := v4.{0.0, 0.0, 0.0, 1};
  color_bright := v4.{0.2, 0.2, 0.2, 1};
  
  renderable : Renderable;
  add_vertices(*renderable, dark_verts, color=color_dark);
  add_vertices(*renderable, bright_verts, color=color_bright);
  
  return renderable;
}

render_floor_grid :: () {
  floor_center_x := floor(camera.x / 10) * 10;
  floor_center_y := floor(camera.y / 10) * 10;
  
  for x: -2..2 {
    for y: -2..2 {
      pos := make_vector3(floor_center_x + x * 10.0, floor_center_y + y * 10.0, 0.0);
      matrix := make_translation_matrix4(pos);
      render(floor_grid, *matrix);
    }
  }
}

render_loading_bar :: (pos: v2, width: f32, height: f32, progress: f32) {
  background_color := v4.{0.25, 0.25, 0.25, 1};
  foreground_color := v4.{0.5, 0.5, 0.5, 1};
  
  clamped_progress := clamp(progress, 0, 1);
  
  background : [..]v3;
  background.allocator = __temporary_allocator;
  array_add(*background, make_vector3(pos,                           0));
  array_add(*background, make_vector3(pos.x + width, pos.y,          0));
  array_add(*background, make_vector3(pos.x,         pos.y + height, 0));
  array_add(*background, make_vector3(pos.x,         pos.y + height, 0));
  array_add(*background, make_vector3(pos.x + width, pos.y,          0));
  array_add(*background, make_vector3(pos.x + width, pos.y + height, 0));
  
  render_triangles_slow(background, background_color);
  
  foreground : [..]v3;
  foreground.allocator = __temporary_allocator;
  array_add(*background, make_vector3(pos,                                              0.01));
  array_add(*background, make_vector3(pos.x + width * clamped_progress, pos.y,          0.01));
  array_add(*background, make_vector3(pos.x,                            pos.y + height, 0.01));
  array_add(*background, make_vector3(pos.x,                            pos.y + height, 0.01));
  array_add(*background, make_vector3(pos.x + width * clamped_progress, pos.y,          0.01));
  array_add(*background, make_vector3(pos.x + width * clamped_progress, pos.y + height, 0.01));
  
  render_triangles_slow(background, foreground_color);
}

render_internal :: (to_texture: bool) {
  render_clear_all(v3.{});
  render_set_camera(*camera);
  
  if !to_texture {
    demo_camera := camera;
    demo_camera.cull_backfaces = true;
    initial_demo_cube_pos := demo_entity.pos;
    for type_info(Render_Mode).values {
      demo_camera.mode = cast(Render_Mode) it;
      render_set_camera(*demo_camera);
      
      render(*demo_entity);
      demo_entity.pos.x += 1.5;
    }
    demo_entity.pos = initial_demo_cube_pos;
    
    render_set_camera(*camera);
  }
  
  render_floor_grid();
  
  for entities {
    render(it);
  }
  
  render_line_slow(.{}, .{0, 0, 1});
  
  render_loading_bar(.{}, 3.5, 0.1, 0.3);
  
  // Render selection, or potential selection
  if selected_entity {
    selection_camera := camera;
    selection_camera.mode = .WIREFRAME;
    selection_camera.depth_test = false;
    selection_camera.cull_backfaces = true;
    render_set_camera(*selection_camera);
    render(selected_entity);
    
    // Render gizmo
    render_clear_depth_buffer();
    gizmo_camera := camera;
    gizmo_camera.mode = .UNLIT_COLOR;
    gizmo_camera.depth_test = true;
    render_set_camera(*gizmo_camera);
    gizmo.pos = selected_entity.pos;
    render(*gizmo);
  }
}