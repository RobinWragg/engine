in vec3 normal;
out vec4 color_out;

void main() {
  vec3 light_dir = normalize(vec3(0.8, 0.9, 1));
  color_out = vertex_buffer_color;
  color_out.xyz *= dot(normal, light_dir) * 0.5 + 0.5;
}