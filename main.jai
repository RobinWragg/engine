
// rwtodo: windowed mode should always be 16:9. Fullscreen mode may or may not enforce aspect ratio, depending on the game.

vsync := true;

window : struct {
  sdl_handle : *SDL_Window;
  width  : u16;
  height : u16;
  aspect_ratio : f32 = 1.777778;
}

main :: () {
  print("\nEntering main()\n");
  
  init_flags := SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_EVENTS | SDL_INIT_GAMECONTROLLER;
  
  if SDL_Init(init_flags) != 0 {
    print("%\n", to_string(SDL_GetError()));
    return;
  }
  
  display_mode : SDL_DisplayMode;
  SDL_GetDesktopDisplayMode(0, *display_mode);
  
  display_fraction : f32 = 0.9;
  max_window_width := display_mode.w * display_fraction;
  max_window_height := display_mode.h * display_fraction;
  
  if max_window_width < max_window_height / window.aspect_ratio {
    window.width = cast(u16) (max_window_height * window.aspect_ratio);
    window.height = cast(u16) max_window_height;
  } else {
    window.width = cast(u16) max_window_width;
    window.height = cast(u16) (max_window_width / window.aspect_ratio);
  }
  
  print("%x%\n", window.width, window.height);
  
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, cast(s32) SDL_GL_CONTEXT_PROFILE_CORE);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
  
  window_flags := SDL_WINDOW_OPENGL;
  window.sdl_handle = SDL_CreateWindow(
    to_c_string("rwtodo"),
    SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
    window.width, window.height,
    window_flags);
  
  if window.sdl_handle == null {
    print("%\n", to_string(SDL_GetError()));
    return;
  }
  
  gl_context := SDL_GL_CreateContext(window.sdl_handle);
  if !gl_context {
    print("%\n", to_string(SDL_GetError()));
    return;
  }
  
  render_init();
  
  // This is done after render_init() to ensure the user sees a cleared render buffer ASAP.
  if vsync SDL_GL_SetSwapInterval(1);
  else SDL_GL_SetSwapInterval(0);
  SDL_GL_SwapWindow(window.sdl_handle);
  
  editor_init();
  
  should_quit := false;
  
  time_previous : f64;
  
  while !should_quit {
    // Time
    time := get_time();
    time_delta := cast(f32) (time - time_previous);
    
    delta_max :: 0.05;
    if time_delta > delta_max {
      print(
        "Frame delta is %ms, slowdown imposed.\n",
        floor(time_delta * 1000));
      
      time_delta = delta_max;
    }
    
    time_previous = time;
    
    process_input_from_platform(*should_quit);
    
    editor_update(time_delta);
    editor_render();
    
    SDL_GL_SwapWindow(window.sdl_handle);
    
    reset_temporary_storage();
  }
  
  print("\nExiting main()\n");
}

#scope_file

// Imports apparently shouldn't be accessible from other files, but they are, because beta.
#import "Basic";
#import "SDL";









