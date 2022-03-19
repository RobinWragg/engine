out vec2 tex_coord;

void main() {
  gl_Position = vec4(vert_pos_in, 1.0) * matrix;
  tex_coord = vert_tex_coord_in;
}