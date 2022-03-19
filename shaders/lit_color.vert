out vec3 normal;

void main() {
  gl_Position = vec4(vert_pos_in, 1.0) * matrix;
  normal = vert_normal_in;
}