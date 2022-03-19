in vec2 tex_coord;

out vec4 color_out;

void main() {
  color_out = texture(color_texture, tex_coord);
}