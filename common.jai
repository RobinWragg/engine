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

allocation_printer :: () -> Context {
  allocation_printer : Context;
  allocation_printer.allocator = allocation_printer_allocator;
  allocation_printer.allocator_data = null;
  return allocation_printer;
}

contains :: (array: []$T, element: T) -> bool {
  for array {
    if it == element {
      return true;
    }
  }
  
  return false;
}

copy :: (input: string, allocator: Allocator = null) -> string {
  output : string = ---;
  output.count = input.count;
  output.data = alloc(input.count, allocator=allocator);
  memcpy(output.data, input.data, output.count);
  return output;
}

t_copy :: (input: string) -> string {
  return copy(input, __temporary_allocator);
}

#scope_file ////////////////////////////////////////////////////////////////////////////////////////

allocation_printer_allocator :: (mode: Allocator_Mode, size: s64, old_size: s64, old_memory_pointer: *void, allocator_data: *void) -> *void {
  
  if mode == .ALLOCATE {
    inner_context := context;
    inner_context.allocator = context.default_allocator;
    push_context inner_context {
      if context.stack_trace && context.stack_trace.next {
        node := context.stack_trace.next;
        
        builder : String_Builder;
        // rwsubltodo: append() didn't autocomplete. Because it's 'inline'?
        print_to_builder(*builder, "alloc:\n");
        
        while node && node.info {
          print_to_builder(*builder,
            "%:%: %\n",
            node.info.location.fully_pathed_filename,
            node.line_number,
            node.info.name);
          
          node = node.next;
        }
        
        print("%\n", builder_to_string(*builder));
        free_buffers(*builder);
      } else {
        print("\t<stacktrace is null!>\n\n");
      }
      
    } // pop context
  }

  return context.default_allocator(mode, size, old_size, old_memory_pointer, allocator_data);
}

#import "File";