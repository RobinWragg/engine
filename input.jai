// Contains everything regarding the mouse, keyboard, and game controllers.

// Structure for querying input.
input : struct {
  mouse : struct {
    using window_pos : v2; // Position in window space, not pixel space.
    delta : v2; // Raw mouse data when mouse is in captured state. Delta in pixel space otherwise.
    is_captured : bool;
  }
  
  wasd : v2;
  
  key_state :: (character: s64) -> bool {
    return key_state(cast(SDL_Keycode) character);
  }
  
  key_state :: (keycode: SDL_Keycode) -> bool {
    found, _ := array_find(input.keys_currently_pressed, keycode);
    return found;
  }
  
  key_event :: (character: s64, pressed_vs_released := true) -> bool {
    return key_event(cast(SDL_Keycode) character, pressed_vs_released);
  }
  
  key_event :: (keycode: SDL_Keycode, pressed_vs_released := true) -> bool {
    if pressed_vs_released {
      found, _ := array_find(input.key_press_events, keycode);
      return found;
    } else {
      found, _ := array_find(input.key_release_events, keycode);
      return found;
    }
  }
  
  mouse_press_event :: (is_left_button: bool) -> bool {
    found, _ := array_find(input.mouse_press_events, is_left_button);
    return found;
  }
  
  // Note: You probably want to use key_state() or key_event() instead of accessing these directly.
  keys_currently_pressed : [..]SDL_Keycode;
  key_press_events : [..]SDL_Keycode;
  key_release_events : [..]SDL_Keycode;
  
  mouse_press_events : [..]bool;
}

show_mouse :: (show: bool) {
  SDL_ShowCursor(cast(s32) show);
}

capture_mouse :: (capture: bool) {
  SDL_SetRelativeMouseMode(cast(SDL_bool) capture);
  input.mouse.is_captured = capture;
}

process_input_from_platform :: (should_quit: *bool) {
  <<should_quit = false;
  
  using input;
  
  // Zero the transient input data
  mouse.delta = .{};
  array_reset(*key_press_events);
  array_reset(*key_release_events);
  array_reset(*mouse_press_events);
  
  event : SDL_Event;
  while SDL_PollEvent(*event) {
    if event.type == {
      case SDL_QUIT;
        <<should_quit = true;
        
      case SDL_KEYDOWN;
        if !event.key.repeat {
          key_code := event.key.keysym.sym;
          if key_code == SDLK_ESCAPE { <<should_quit = true; }
          array_add_if_unique(*keys_currently_pressed, key_code);
          array_add_if_unique(*key_press_events, key_code);
        }
        
      case SDL_KEYUP;
        key_code := event.key.keysym.sym;
        array_unordered_remove_by_value(*keys_currently_pressed, key_code);
        array_add_if_unique(*key_release_events, key_code);
      
      case SDL_MOUSEMOTION;
        mouse.x = cast(f32) event.motion.x / window.height;
        mouse.y = (cast(f32) (window.height - event.motion.y)) / window.height;
        
        mouse.delta.x = cast(f32) event.motion.xrel;
        mouse.delta.y = cast(f32) -event.motion.yrel;
        
      case SDL_MOUSEBUTTONDOWN;
        array_add_if_unique(*mouse_press_events, event.button.button == SDL_BUTTON_LEFT);
        
      case SDL_MOUSEBUTTONUP;
        // event.button
      case SDL_MOUSEWHEEL;
        // event.wheel
      
      case SDL_CONTROLLERAXISMOTION;
        print("SDL_CONTROLLERAXISMOTION\n");
        
      case SDL_CONTROLLERBUTTONDOWN;
        print("SDL_CONTROLLERBUTTONDOWN\n");
        
      case SDL_CONTROLLERBUTTONUP;
        print("SDL_CONTROLLERBUTTONUP\n");
        
      case SDL_CONTROLLERDEVICEADDED;
        print("SDL_CONTROLLERDEVICEADDED\n");
        
      case SDL_CONTROLLERDEVICEREMOVED;
        print("SDL_CONTROLLERDEVICEREMOVED\n");
        
      case SDL_CONTROLLERDEVICEREMAPPED;
        print("SDL_CONTROLLERDEVICEREMAPPED\n");
        
      case SDL_JOYDEVICEADDED;
        print("SDL_JOYDEVICEADDED\n");
        
      case SDL_JOYDEVICEREMOVED;
        print("SDL_JOYDEVICEREMOVED\n");
    }
  }
  
  // Build wasd vector
  // rwsubltodo: couldn't use goto definition here for array_find
  w := input.key_state(#char "w");
  a := input.key_state(#char "a");
  s := input.key_state(#char "s");
  d := input.key_state(#char "d");
  
  wasd = v2.{};
  
  if a {
    wasd.x = -1;
  } else if d {
    wasd.x = 1;
  }
  
  if s {
    wasd.y = -1;
  } else if w {
    wasd.y = 1;
  }
  
  normalize_or_zero(*wasd);
}

#scope_file ////////////////////////////////////////////////////////////////////////////////////////

