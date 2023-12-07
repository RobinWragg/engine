#import "Math";

v2 :: Vector2;
v3 :: Vector3;
v4 :: Vector4;
m3 :: Matrix3;
m4 :: Matrix4;
f32 :: float32;
f64 :: float64;

qprint :: (any: Any) {
  print("%\n", any);
}

assert_and_read_entire_file :: (path: string) -> string {
  contents, success := read_entire_file(path);
  assert(success, path);
  return contents;
}

print_from_stack :: () {
  assert(context.stack_trace != null);
  assert(context.stack_trace.next != null);
  assert(context.stack_trace.info != null);
  print("%, %\n", context.stack_trace.info.name, context.stack_trace.next.info.name);
}

contains :: (array: []$T, element: T) -> bool {
  for array {
    if it == element {
      return true;
    }
  }
  
  return false;
}

#scope_file

#import "File";