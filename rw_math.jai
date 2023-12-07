#run unit_tests();

is_unit :: (vector: $T) -> bool #must {
  l := length(vector);
  return l > 0.9999 && l < 1.0001;
}

is_zero :: (vector: $T) -> bool #must {
  l := length(vector);
  return l == 0;
}

intersect_lines :: (line_a_p1: v2, line_a_p2: v2, line_b_p1: v2, line_b_p2: v2) -> bool #must, v2 {
  denominator := (line_a_p1.x - line_a_p2.x) * (line_b_p1.y - line_b_p2.y)
    - (line_a_p1.y - line_a_p2.y) * (line_b_p1.x - line_b_p2.x);
  
  if denominator == 0 {
    return false, .{};
  }
  
  intersection := (line_b_p1 - line_b_p2) * (line_a_p1.x*line_a_p2.y - line_a_p1.y*line_a_p2.x)
    - (line_a_p1 - line_a_p2) * (line_b_p1.x*line_b_p2.y - line_b_p1.y*line_b_p2.x);
  
  intersection /= denominator;
  return true, intersection;
}

intersect_line_and_plane :: (line_point: v3, line_direction: v3, plane_point: v3, plane_normal: v3) -> bool #must, v3 {
  assert(!is_zero(line_point));
  assert(is_unit(plane_normal));
  
  denominator := dot(line_direction, plane_normal);
  
  if denominator == 0 {
    return false, .{};
  }

  d := dot(plane_point - line_point, plane_normal) / denominator;
  intersection := line_point + line_direction * d;
  
  return true, intersection;
}

// This leaves X and Y unchanged and adds a Z value such that it is a unit vector.
clamped_2d_to_unit_3d :: (input: v2) -> v3 #must {
  assert(length(input) <= 1, "Expected a Vector2 of length <=1.");
  return make_vector3(input, sqrt(abs(1 - input.x*input.x - input.y*input.y)));
}

project_onto_plane :: (point: v3, plane_x_axis_in_3d: v3, plane_y_axis_in_3d: v3) -> v2 #must {
  assert(is_unit(plane_x_axis_in_3d));
  assert(is_unit(plane_y_axis_in_3d));
  assert(dot(plane_x_axis_in_3d, plane_y_axis_in_3d) == 0);
  
  right_amount := dot(point, plane_x_axis_in_3d);
  up_amount := dot(point, plane_y_axis_in_3d);
  return make_vector2(right_amount, up_amount);
}

// rwsubltodo: double dot.
point_is_in_triangle :: (point: v2, triangle: ..v2) -> bool #must {
  assert(triangle.count == 3);
  
  edge_0 := triangle[1] - triangle[0];
  edge_1 := triangle[2] - triangle[1];
  edge_2 := triangle[0] - triangle[2];
  
  edge_normal_0 := make_vector2(edge_0.y, -edge_0.x);
  edge_normal_1 := make_vector2(edge_1.y, -edge_1.x);
  edge_normal_2 := make_vector2(edge_2.y, -edge_2.x);
  
  dot_0 := dot(edge_normal_0, point - triangle[0]);
  dot_1 := dot(edge_normal_1, point - triangle[1]);
  dot_2 := dot(edge_normal_2, point - triangle[2]);
  
  return (dot_0 > 0 && dot_1 > 0 && dot_2 > 0) || (dot_0 < 0 && dot_1 < 0 && dot_2 < 0);
}

add_ring_triangles :: (vertices: *[..]v3, face_count: int, bottom_radius: f32, top_radius: f32, height: f32, offset: v3 = .{}) {
  for 0..face_count-1 {
    angle_a := (it / cast(f32) face_count) * TAU;
    v_a := make_vector3(cos(angle_a), sin(angle_a), 0.0);
    v_a.xy *= bottom_radius;
    array_add(vertices, v_a + offset);
    
    angle_b := ((it+1) / cast(f32) face_count) * TAU;
    v_b := make_vector3(cos(angle_b), sin(angle_b), 0.0);
    v_b.xy *= bottom_radius;
    array_add(vertices, v_b + offset);
    
    v_c := make_vector3(cos(angle_a), sin(angle_a), height);
    v_c.xy *= top_radius;
    array_add(vertices, v_c + offset);
    
    array_add(vertices, v_c + offset);
    array_add(vertices, v_b + offset);
    v_d := make_vector3(cos(angle_b), sin(angle_b), height);
    v_d.xy *= top_radius;
    array_add(vertices, v_d + offset);
  }
}

add_sphere_triangles :: (vertices: *[..]v3, resolution: int = 32) {
  for 0..resolution-1 {
    angle_a := (it / cast(f32) resolution) * PI;
    angle_b := ((it+1) / cast(f32) resolution) * PI;
    bottom_radius := sin(angle_b);
    top_radius := sin(angle_a);
    
    bottom_height := cos(angle_b);
    top_height := cos(angle_a);
    offset := make_vector3(0, 0, bottom_height);
    
    add_ring_triangles(
      vertices,
      resolution * 2,
      bottom_radius,
      top_radius,
      top_height - bottom_height,
      offset);
  }
}

add_cube_triangles :: (vertices: *[..]v3, size: f32 = 1.0) {
  // rwtodo: if the type of the element is inferred, a weird build error occurs. Report.
  array_add(vertices, v3.{0, 0, 0} * size);
  array_add(vertices, v3.{0, 1, 0} * size);
  array_add(vertices, v3.{1, 0, 0} * size);
  array_add(vertices, v3.{1, 0, 0} * size);
  array_add(vertices, v3.{0, 1, 0} * size);
  array_add(vertices, v3.{1, 1, 0} * size);
  
  array_add(vertices, v3.{0, 0, 0} * size);
  array_add(vertices, v3.{0, 0, 1} * size);
  array_add(vertices, v3.{0, 1, 0} * size);
  array_add(vertices, v3.{0, 1, 0} * size);
  array_add(vertices, v3.{0, 0, 1} * size);
  array_add(vertices, v3.{0, 1, 1} * size);
  
  array_add(vertices, v3.{0, 0, 0} * size);
  array_add(vertices, v3.{1, 0, 0} * size);
  array_add(vertices, v3.{0, 0, 1} * size);
  array_add(vertices, v3.{1, 0, 0} * size);
  array_add(vertices, v3.{1, 0, 1} * size);
  array_add(vertices, v3.{0, 0, 1} * size);
  
  array_add(vertices, v3.{0, 1, 1} * size);
  array_add(vertices, v3.{0, 0, 1} * size);
  array_add(vertices, v3.{1, 0, 1} * size);
  array_add(vertices, v3.{0, 1, 1} * size);
  array_add(vertices, v3.{1, 0, 1} * size);
  array_add(vertices, v3.{1, 1, 1} * size);
  
  array_add(vertices, v3.{1, 0, 0} * size);
  array_add(vertices, v3.{1, 1, 0} * size);
  array_add(vertices, v3.{1, 0, 1} * size);
  array_add(vertices, v3.{1, 1, 0} * size);
  array_add(vertices, v3.{1, 1, 1} * size);
  array_add(vertices, v3.{1, 0, 1} * size);
  
  array_add(vertices, v3.{0, 1, 0} * size);
  array_add(vertices, v3.{0, 1, 1} * size);
  array_add(vertices, v3.{1, 1, 0} * size);
  array_add(vertices, v3.{1, 1, 0} * size);
  array_add(vertices, v3.{0, 1, 1} * size);
  array_add(vertices, v3.{1, 1, 1} * size);
}

#scope_file

unit_tests :: () {
  print("Running rw_math unit tests\n");
  
  points :: v3.[
    .{},
    .{1, 0, 0},
    .{1, 2, 3},
    .{2, 3, 4},
    .{3, 4, 5},
    .{5, 4, 3},
  ];
  
  for points {
    point_on_plane : v2 = ---;
    
    failure_msg :: "Unit test failed for project_onto_plane().";
    
    point_on_plane = project_onto_plane(it, .{1, 0, 0}, .{0, 1, 0});
    assert(point_on_plane == it.xy, failure_msg); // rwtodo: make compile time assertions return non zero exit code
    
    point_on_plane = project_onto_plane(it, .{0, 1, 0}, .{0, 0, 1});
    assert(point_on_plane == it.yz, failure_msg);
    
    point_on_plane = project_onto_plane(it, .{-1, 0, 0}, .{0, -1, 0});
    assert(point_on_plane == it.xy * -1, failure_msg); // rwtodo: Can't do '-it.xy'. Discuss with Jon?
    
    point_on_plane = project_onto_plane(it, .{0, -1, 0}, .{0, 0, -1});
    assert(point_on_plane == it.yz * -1, failure_msg);
    
    point_on_plane = project_onto_plane(it, .{1, 0, 0}, .{0, 0, 1});
    assert(point_on_plane.x == it.x && point_on_plane.y == it.z, failure_msg);
  }
  
  triangle :: v2.[
    .{1, 1},
    .{1, 3},
    .{3, 1},
  ];
  
  is_inside : bool = ---;
  
  failure_msg :: "Unit test failed for point_is_in_triangle().";
  assert(point_is_in_triangle(.{1.1, 1.1}, ..triangle), failure_msg);
  assert(point_is_in_triangle(.{2.1, 1.1}, ..triangle), failure_msg);
  assert(point_is_in_triangle(.{1.1, 2.1}, ..triangle), failure_msg);
  assert(!point_is_in_triangle(.{0.9, 0.9}, ..triangle), failure_msg);
  assert(!point_is_in_triangle(.{1.9, 0.9}, ..triangle), failure_msg);
  assert(!point_is_in_triangle(.{0.9, 1.9}, ..triangle), failure_msg);
  assert(point_is_in_triangle(.{1.9, 1.9}, ..triangle), failure_msg);
  assert(!point_is_in_triangle(.{2.1, 2.1}, ..triangle), failure_msg);
  assert(!point_is_in_triangle(.{3.9, 0.9}, ..triangle), failure_msg);
  assert(!point_is_in_triangle(.{0.999, 3.1}, ..triangle), failure_msg);
  assert(!point_is_in_triangle(.{0.999999, 2}, ..triangle), failure_msg);
  assert(point_is_in_triangle(.{1.000001, 2}, ..triangle), failure_msg);
}