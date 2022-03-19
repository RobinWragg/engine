in vec3 normal;
in vec2 tex_coord;

out vec4 color_out;

void main() {
  color_out = texture(color_texture, tex_coord);
  vec3 light_dir = normalize(vec3(0.8, 0.9, 1));
  color_out.xyz *= dot(normal, light_dir) * 0.5 + 0.5;
}