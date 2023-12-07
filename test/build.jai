#run build();

#scope_file

#import "Basic";
#import "String";
#import "Compiler";

build :: () {
  build_opts := get_build_options();
  build_opts.output_type = .NO_OUTPUT;
  set_build_options(build_opts);
  
  main_workspace := compiler_create_workspace("main");
  
  build_opts = get_build_options(main_workspace);
  build_opts.output_type = .EXECUTABLE;
  build_opts.output_executable_name = "main";
  set_build_options(build_opts, main_workspace);
  
  compiler_begin_intercept(main_workspace);
  
  set_working_directory(#filepath);
  add_build_file("main.jai", main_workspace);
  
  while true {
    msg := compiler_wait_for_message();
    
    if msg.workspace != main_workspace {
      continue;
    }
    
    inject_code(msg, main_workspace);
    
    if msg.kind == .COMPLETE break;
  }
  
  compiler_end_intercept(main_workspace);
}

inject_code :: (msg: *Message, main_workspace: Workspace) {
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
          
          if !contains(file_path, "/jai/") && proc_body.header.name != "print_stack" {
            // print("% %\n", proc_body.header.name, file_path);
            
            print("adding...\n");
            
            // my_code := #code print("%\n", context.stack_trace.info.name);
            my_code := #code print_stack();
            
            my_code_root, my_code_expressions := compiler_get_nodes(my_code);
            
            // All this is doing right now is copying the statements to a new array, setting the statements to the new array, and calling compiler_modify_procedure. It should not affect the final program, but it does.
            
            new_statements : [..] *Code_Node;
            
            // array_add(*new_statements, my_code_root);
            
            for proc_body.block.statements {
              array_add(*new_statements, it);
            }
            

            proc_body.block.statements = new_statements;
            
            for proc_body.block.statements {
              print("%\n", it.kind);
            }
            
            compiler_modify_procedure(msg.workspace, it);
            print("added\n");
          }
        }
      }
    }
  }
}
