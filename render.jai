
color_white   :: v4.{1, 1, 1, 1};
color_black   :: v4.{0, 0, 0, 1};
color_red     :: v4.{1, 0, 0, 1};
color_orange  :: v4.{1, 0.5, 0, 1};
color_yellow  :: v4.{1, 1, 0, 1};
color_green   :: v4.{0, 1, 0, 1};
color_cyan    :: v4.{0, 1, 1, 1};
color_blue    :: v4.{0, 0, 1, 1};
color_magenta :: v4.{1, 0, 1, 1};

Renderable :: struct {
    buffers : [..]Vertex_Buffer;
}

Render_Mode :: enum {
    LIT_COLOR;
    LIT_TEXTURE;
    UNLIT_COLOR;
    UNLIT_TEXTURE;
    WIREFRAME;
}

Camera :: struct {
    using pos : v3;
    
    pitch, yaw, roll : f32;
    
    fov : f32 = 1.4;
    mode : Render_Mode = .UNLIT_COLOR;
    depth_test : bool = true;
    cull_backfaces : bool = false;
}

Image :: struct {
    pixels : []v4;
    width, height : int;
}

render_init :: () {
    render_platform_init();
    set_output_to_display();
    
    camera : Camera; // Default camera values
    render_set_camera(*camera);
    
    render_clear_all(.{});
    
    // rwtodo: this would fail if we didn't set output to display beforehand, which is odd.
    immediate_vbuffer.platform_buffer = make_vertex_buffer(.[.{}, .{}, .{}]);
    
    placeholder_image := make_placeholder_image(); defer free(*placeholder_image);
    load_texture(placeholder_image, "placeholder");
}

load_texture :: (image: Image, name: string) {
    id := render_platform_load_texture(image.width, image.height, image.pixels);
    add_texture(name, id);
}

make_texture :: (width: int, height: int, name: string) {
    id := render_platform_make_texture(width, height);
    assert(id != INVALID_TEXTURE, tprint("Unable to create %x% texture: '%'", width, height, name));
    add_texture(name, id);
}

set_output_to_display :: () {
    render_platform_set_output_to_display(window.width, window.height);
}

set_output_to_texture :: (texture: string) {
    id := get_texture_id(texture);
    assert(id != INVALID_TEXTURE, tprint("Texture not found in VRAM: '%'", texture));
    render_platform_set_output_to_texture(id);
}

// rwtodo: if normals or tex_coords aren't specified, we still currently create GPU buffers for those. Probably reduces complexity overall but is obviously memory-inefficient.
add_vertices :: (
    renderable: *Renderable,
    positions: []v3,
    normals: []v3 = .[],
    tex_coords: []v2 = .[],
    texture: string = "",
    color: v4 = color_white) {
    vbuffer := make_vertex_buffer(positions, normals, tex_coords, texture, color);
    array_add(*renderable.buffers, vbuffer);
}

render_clear_all :: (clear_color: v3) {
    render_platform_clear_all(clear_color);
    clockwise_flasher_loop += 1;
    enable_clockwise_culling(clockwise_culling_enabled);
}

render_clear_depth_buffer :: () {
    render_platform_clear_depth_buffer();
}

render_delete_vertex_buffer :: (buffer: Vertex_Buffer) {
    render_platform_delete_vertex_buffer(buffer);
}

render :: (renderable: Renderable, matrix_nullable: *m4 = null) {
    matrix : m4 = ---;
    
    if matrix_nullable {
        matrix = <<matrix_nullable;
    } else {
        matrix = Matrix4_Identity();
    }
    
    for renderable.buffers {
        render(it, matrix);
    }
}

render_triangles_slow :: (vertex_positions: []v3, color: v4, matrix: *m4 = null) {
    normals := alloc_default_vertex_normals(vertex_positions); defer array_free(normals);
    tex_coords := alloc_default_vertex_tex_coords(vertex_positions.count); defer array_free(tex_coords);
    
    render_platform_set_vertices(*immediate_vbuffer, vertex_positions, normals, tex_coords);
    
    immediate_vbuffer.color = color;
    
    if matrix {
        render(immediate_vbuffer, <<matrix);
    } else {
        render(immediate_vbuffer, matrix4_identity());
    }
}

render_line_slow :: (start: v3, end: v3, color: v4 = color_white) {
    vertices := NewArray(3, v3, initialized=false, allocator=__temporary_allocator);
    vertices[0] = start;
    vertices[1] = start;
    vertices[2] = end;
    
    initial_mode := active_camera.mode;
    
    set_render_mode(.WIREFRAME);
    render_triangles_slow(vertices, color);
    set_render_mode(initial_mode);
}

render_set_camera :: (using camera: *Camera) {
    assert(
        abs(yaw) < TAU*2 && abs(pitch) < TAU*2 && abs(roll) < TAU*2,
        "Camera orientation floats aren't being correctly limited.");
    
    while yaw > TAU { yaw -= TAU; }
    while yaw < 0 { yaw += TAU; }
    if pitch > PI/2 { pitch = PI/2; }
    if pitch < -PI/2 { pitch = -PI/2; }
    while roll > TAU { roll -= TAU; }
    while roll < 0 { roll += TAU; }
    
    set_render_mode(mode);
    render_platform_enable_depth_testing(depth_test);
    enable_clockwise_culling(cull_backfaces);
    
    active_camera = <<camera;
    
    projection_matrix := make_perspective_projection(fov, pitch, roll, yaw);
    scene_matrix := make_translation_matrix4(-pos);
    active_camera_matrix = projection_matrix * scene_matrix;
}

scene_pos_to_window_pos :: (pos: v3) -> v2 #must {
    // scene coord to normalised device coord
    pos4 := make_vector4(pos, 1); // w=1 to enable translation, same as the vert shader
    normalised_device_coord := active_camera_matrix * pos4;
    normalised_device_coord.xyz /= normalised_device_coord.w; // The perspective divide
    
    // normalised device coord to window coord
    window_coord := normalised_device_coord.xy;
    window_coord.x = (window_coord.x + 1) * (window.aspect_ratio / 2);
    window_coord.y = (window_coord.y + 1) / 2;
    
    return window_coord;
}

// rwsubltodo: unable to goto reference.
window_pos_to_scene_direction :: (pos: v2) -> v3 #must {
    // window coord to normalised device coord
    normalised_device_coord := make_vector4(pos, 0, 1);
    normalised_device_coord.xy *= 2;
    normalised_device_coord.x /= window.aspect_ratio;
    normalised_device_coord.x -= 1;
    normalised_device_coord.y -= 1;
    
    // normalised device coord to scene coord
    camera_inverse, success := inverse(active_camera_matrix);
    assert(success); // rwtodo: ensure this is a no-op in release builds
    
    scene_coord := camera_inverse * normalised_device_coord;
    scene_coord.xyz /= scene_coord.w;
    
    return normalize(scene_coord.xyz - active_camera.pos);
}

#scope_file ////////////////////////////////////////////////////////////////////////////////////////

Vertex_Buffer :: struct {
    #as using platform_buffer : Platform_Vertex_Buffer = ---;
}

Texture :: struct {
    name: string;
    id: u32;
}

textures : [..]Texture;

add_texture :: (name: string, id: u32) {
    assert(name.count > 0, "Attempted to add a texture with a zero-length name.");
    assert(!texture_exists(name), tprint("Texture name collision: '%'", name));
    
    texture : Texture = ---;
    texture.name = copy_string(name);
    texture.id = id;
    
    array_add(*textures, texture);
}

get_texture_id :: (name: string) -> u32 #must {
    for textures {
        if it.name == name return it.id;
    }
    
    return INVALID_TEXTURE;
}

texture_exists :: (name: string) -> bool #must {
    return get_texture_id(name) != INVALID_TEXTURE;
}

render :: (buffer: Vertex_Buffer, matrix: m4) {
    render_platform_vertex_buffer(buffer, active_camera_matrix * matrix);
}

alloc_default_vertex_normals :: (positions: []v3) -> []v3 {
    normals := NewArray(positions.count, v3, initialized=false);
    
    for 0..positions.count / 3 - 1 {
        index := it * 3;
        a := positions[index+1] - positions[index];
        b := positions[index+2] - positions[index];
        normal := cross(a, b);
        normalize(*normal); // rwtodo specify zero fallback?
        normals[index] = normal;
        normals[index+1] = normal;
        normals[index+2] = normal;
        
        // rwsubltodo: could only autocomplete v2 version of normalize_or_zero().
    }
    
    assert(normals.count == positions.count);
    return normals;
}

alloc_default_vertex_tex_coords :: (vertex_count: int) -> []v2 {
    return NewArray(vertex_count, v2, initialized=true);
}

make_quaternion_around_x :: (radians: f32) -> Quaternion #must {
    radians_half := radians / 2;
    return make_quaternion(sin(radians_half), 0, 0, cos(radians_half));
}

make_quaternion_around_y :: (radians: f32) -> Quaternion #must {
    radians_half := radians / 2;
    return make_quaternion(0, sin(radians_half), 0, cos(radians_half));
}

make_quaternion_around_z :: (radians: f32) -> Quaternion #must {
    radians_half := radians / 2;
    return make_quaternion(0, 0, sin(radians_half), cos(radians_half));
}

set_render_mode :: (mode: Render_Mode) {
    if mode == {
        case .LIT_COLOR;
            render_platform_set_shader(Render_Platform_Shader.LIT_COLOR);
            render_platform_enable_wireframe(false);
        case .LIT_TEXTURE;
            render_platform_set_shader(Render_Platform_Shader.LIT_TEXTURE);
            render_platform_enable_wireframe(false);
        case .UNLIT_COLOR;
            render_platform_set_shader(Render_Platform_Shader.UNLIT_COLOR);
            render_platform_enable_wireframe(false);
        case .UNLIT_TEXTURE;
            render_platform_set_shader(Render_Platform_Shader.UNLIT_TEXTURE);
            render_platform_enable_wireframe(false);
        case .WIREFRAME;
            render_platform_set_shader(Render_Platform_Shader.UNLIT_COLOR);
            render_platform_enable_wireframe(true);
        case;
            assert(false, "Unhandled Render_Mode.");
    }
}

make_perspective_projection :: (fov: f32, pitch: f32, roll: f32, yaw: f32) -> m4 #must {
    projection_matrix := make_projection_matrix(fov, window.aspect_ratio, 0.1, 1000.0);
    
    pitch_quat := make_quaternion_around_x(-pitch - TAU/4); // Make the camera face +Y.
    roll_quat  := make_quaternion_around_y(roll);
    yaw_quat   := make_quaternion_around_z(yaw);
    return rotate(projection_matrix, pitch_quat * roll_quat * yaw_quat);
}

// make_orthographic_projection :: () -> m4 #must {
//   // rwtodo: aspect ratio and origin in lower left corner, same as window coordinate system
//   identity(*projection_matrix);
// }

render_flash_clockwise_triangles := true; // rwtodo: this should be false in release mode.

enable_clockwise_culling :: (cull: bool) {
    clockwise_culling_enabled = cull;
    
    if cull && render_flash_clockwise_triangles {
        // rwtodo: needs to be framerate-independent.
        render_platform_enable_clockwise_culling(clockwise_flasher_loop % 32 < 25);
    } else {
        render_platform_enable_clockwise_culling(cull);
    }
}

make_image :: (width: int, height: int) -> Image {
    image : Image;
    image.width = width;
    image.height = height;
    image.pixels = NewArray(image.width * image.height, v4);
    assert(image.pixels.count == image.width * image.height);
    return image;
}

make_placeholder_image :: () -> Image {
    image := make_image(16, 16);
    
    // rwtodo: This can be done at compile time if it's stored in u8's.
    for x: 0..image.width-1 {
        for y: 0..image.height-1 {
            image.pixels[x + y * image.width] = make_vector4(
                x / cast(f32) image.width,
                y / cast(f32) image.height,
                (x + y) / cast(f32) (image.width + image.height),
                1.0);
            
            if y == 0 && x < image.width/4 {
                image.pixels[x + y * image.width] = color_red; // Red signifies X axis
            }
            
            if x == 0 && y < image.height/4 {
                image.pixels[x + y * image.width] = color_green; // Green signifies Y axis
            }
            
            if x == y {
                image.pixels[x + y * image.width] = color_white;
            }
        }
    }
    
    return image;
}

free :: (image: *Image) {
    image.width = 0;
    image.height = 0;
    array_free(image.pixels);
}

make_vertex_buffer :: (
    positions: []v3,
    normals: []v3 = .[],
    tex_coords: []v2 = .[],
    texture: string = "",
    color: v4 = color_white) -> Vertex_Buffer {
    assert(
        positions.count / 3.0 == floor(positions.count / 3.0),
        "positions count is not divisible by 3.");
    
    // rwtodo: assertion is commented out for now while a proper texture implementation is completed.
    assert(tex_coords.count == 0 || (tex_coords.count == positions.count && texture.count > 0));
    assert(normals.count == positions.count || normals.count == 0);
    
    validated_normals : []v3 = ---;
    
    if normals.count == 0 {
        validated_normals = alloc_default_vertex_normals(positions);
    } else {
        assert(normals.count == positions.count);
        validated_normals = normals;
    }
    
    validated_tex_coords : []v2 = ---;
    
    if tex_coords.count == 0 {
        validated_tex_coords = alloc_default_vertex_tex_coords(positions.count);
        assert(validated_tex_coords.count == positions.count);
    } else {
        assert(tex_coords.count == positions.count);
        validated_tex_coords = tex_coords;
    }
    
    texture_id := INVALID_TEXTURE;
    if texture.count > 0 {
        texture_id = get_texture_id(texture);
        assert(texture_id != INVALID_TEXTURE, tprint("Texture doesn't exist: '%'", texture));
    }
    
    vbuffer : Vertex_Buffer;
    vbuffer.platform_buffer = render_platform_make_vertex_buffer(
        positions,
        validated_normals,
        validated_tex_coords,
        texture_id,
        color);
    
    // rwsubltodo: couldn't do goto symbol ctrl+shift+R for alloc.
    // rwsubltodo: push_context doesn't autocomplete
    
    if normals.count == 0 {
        // This proc allocated its own normals, so we need to free them.
        array_free(validated_normals);
    }
    
    if tex_coords.count == 0 {
        // This proc allocated its own tex_coords, so we need to free them.
        array_free(validated_tex_coords);
    }
    
    return vbuffer;
}

active_camera : Camera;
active_camera_matrix : m4;
clockwise_culling_enabled : bool;
clockwise_flasher_loop : u8;
immediate_vbuffer : Vertex_Buffer;