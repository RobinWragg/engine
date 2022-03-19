#version 330 core

in vec3 vert_pos_in;
in vec3 vert_normal_in;
in vec2 vert_tex_coord_in;

uniform mat4 matrix;
uniform vec4 vertex_buffer_color;
uniform sampler2D color_texture;