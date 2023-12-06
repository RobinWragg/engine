#run build();

exe_name :: "engine";

#scope_file ////////////////////////////////////////////////////////////////////////////////////////

build :: () {
  set_build_options_dc(.{do_output=false});
  
  main_workspace := compiler_create_workspace("main");
  
  build_opts := get_build_options(main_workspace);
  build_opts.output_type = .EXECUTABLE;
  build_opts.output_executable_name = exe_name;
  set_build_options(build_opts, main_workspace);
  
  compiler_begin_intercept(main_workspace);
  
  set_working_directory(#filepath);
  root_files := file_list(".");
  
  for root_files {
    if it != "./build.jai" && ends_with_nocase(it, ".jai") {
      print("Adding %\n", it);
      add_build_file(it, main_workspace);
    }
  }
  
  while true {
    msg := compiler_wait_for_message();
    
    if msg.workspace != main_workspace {
      continue;
    }
    
    // inject_profiler_code(msg, main_workspace);
    
    if msg.kind == .COMPLETE break;
  }
  
  compiler_end_intercept(main_workspace);
}

/*
inject_profiler_code :: (msg: *Message, main_workspace: Workspace) {
  // print("msg kind: %\n", msg.kind);
  
  if msg.kind == .COMPILATION_PHASE {
    phase_msg := cast (*Message_Phase) msg;
    // print("phase: %\n", phase_msg.phase);
  }
  
  if msg.kind == .TYPECHECKED {
    code_msg := cast(*Message_Typechecked) msg;
    
    for code_msg.declarations {
      if !(it.flags & .ALREADY_MODIFIED)
        && it.root_expression
        && it.root_expression.kind == .PROCEDURE_BODY {
        
        proc_body := cast(*Code_Procedure_Body) it.root_expression;
        
        if proc_body.enclosing_load && proc_body.header.name {
          file_path := proc_body.header.enclosing_load.fully_pathed_filename;
          
          if !contains(file_path, "/jai/") {
            // print("% %\n", proc_body.header.name, file_path);
            
            if proc_body.header.name != "render" {
              continue;
            }
            
            print("adding to %...\n", proc_body.header.name);
            
            my_code := #code print_from_stack();
            
            my_code_root, my_code_expressions := compiler_get_nodes(my_code);
            
            // All this is doing right now is copying the statements to a new array, setting the statements to the new array, and calling compiler_modify_procedure. It should not affect the final program, but it does.
            
            new_statements : [..] *Code_Node;
            
            // array_add(*new_statements, my_code_root);
            
            added_code := false;
            for proc_body.block.statements {
              array_add(*new_statements, it);
            }

            proc_body.block.statements = new_statements;
            
            for proc_body.block.statements {
              // qprint(it.kind);
            }
            
            compiler_modify_procedure(msg.workspace, it);
            print("added to %\n", proc_body.header.name);
          }
        }
      }
    }
  }
}
*/

#load "common.jai";

#import "File_Utilities";
#import "Compiler";
#import "String";
#import "Basic";