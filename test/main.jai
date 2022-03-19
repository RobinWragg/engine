print_stack :: () {
  assert(context.stack_trace != null, "nostack");
  assert(context.stack_trace.info != null, "noinfo");
  assert(context.stack_trace.info.name.count > 0, "noname");
  print("stack: %\n", context.stack_trace.info.name);
}

func2 :: () {
}

Gff :: struct {
  x: int;
}

func :: (using g: Gff) {
  print("hello from func %\n", x);
  func2();
}

main :: () {
  print("entered main\n");
  
  g : Gff;
  g.x = 42;
  func(g);
  
  print("exiting main\n");
}

#import "Basic";