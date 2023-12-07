
load_obj_file :: (file_path: string) -> []v3 {
  // SLOW: this allocs and frees several arrays per triangle, such as split_line.

  file_contents, success := read_entire_file(file_path);
  assert(success, "File path doesn't exist.");
  
  vertices : [..]v3; defer array_free(vertices);
  indices : [..]u32; defer array_free(indices);
  
  for 0..file_contents.count-1 {
    buf : string = ---;
    buf.count = 3;
    buf.data = *file_contents[it];
    
    if buf == "\nv " {
      while !ends_with(buf, "\n") {
        buf.count += 1;
      }
      
      split_line := split(buf, " "); defer array_free(split_line);
      assert(split_line.count == 4);
      
      vertex := make_vector3(
        string_to_float(split_line[1]),
        string_to_float(split_line[2]),
        string_to_float(split_line[3]));
      array_add(*vertices, vertex);
      
    } else if buf == "\nf " {
      while !ends_with(buf, "\n") {
        buf.count += 1;
      }
      
      // remove trailing whitespace
      while ends_with(buf, "\r") || ends_with(buf, "\n") || ends_with(buf, " ") {
        buf.count -= 1;
      }
      
      split_line := split(buf, " "); defer array_free(split_line);
      
      assert(split_line.count == 4);
      
      for 1..split_line.count-1 {
        str := split_line[it];
        
        if contains(str, "/") {
          while !contains(str, "/") {
            str.count += 1;
          }
        }
        
        vertex_index, success := to_integer(str);
        assert(success);
        assert(vertex_index >= 1); // Not handling negative indices.
        vertex_index -= 1; // OBJ stores indices starting at 1, not 0.
        array_add(*indices, cast(u32) vertex_index);
      }
      
    }
  }
  
  ordered_vertices := NewArray(indices.count, v3); // rwtodo ctrl+R displays this!?
  
  for indices {
    ordered_vertices[it_index] = vertices[it];
  }
  
  return ordered_vertices;
}

#scope_file

#import "File";