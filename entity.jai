#run build_entities();

Entity :: struct {
  pos : v3;
  renderable : Renderable;
  
  init : (self: *Entity) -> ();
  update : (self: *Entity, dt: f32) -> ();
  
  // Derived entities should not set this.
  initial_pos : v3;
}

init :: (entity: *Entity) {
  entity.pos = entity.initial_pos;
  
  if entity.init {
    entity.init(entity);
  }
}

deinit :: (entity: *Entity) {
  // rwtodo: this definitely leaks.
}

update :: (entity: *Entity, dt: f32) {
  if entity.update {
    entity.update(entity, dt);
  }
}

render :: (entity: *Entity) {
  matrix := get_matrix(entity);
  render(entity.renderable, *matrix);
}

t_apply_entity_transform :: (vertices: []v3, entity: *Entity) -> []v3 #must {
  transformed_vertices : [..]v3;
  transformed_vertices.allocator = __temporary_allocator;
  
  array_copy(*transformed_vertices, vertices);
  
  matrix := get_matrix(entity);
  
  for transformed_vertices {
    transformed_vertices[it_index] = (matrix * make_vector4(it, 1.0)).xyz;
  }
  
  return transformed_vertices;
}

#scope_file ////////////////////////////////////////////////////////////////////////////////////////

get_matrix :: (using entity: *Entity) -> m4 #must {
  return make_translation_matrix4(pos);
}

// compile-time ////////////////////////////////////////////////////////////////////////////////////

entities_directory :: "entities";
file_extension :: ".jai";

build_entities :: () {
  entity_files := file_list(entities_directory);
  
  for entity_files {
    if ends_with_nocase(it, file_extension) {
      print("Adding %\n", it);
      add_build_file(it);
    }
  }
}

#import "File_Utilities";
#import "Compiler";







