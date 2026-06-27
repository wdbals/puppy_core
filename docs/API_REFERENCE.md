# Referencia De API

Los managers registrados como autoloads son la API publica principal.

## GameManager

Gestiona estado global, pausa, cambios de escena y transiciones.

### Senales

| Senal | Cuando ocurre |
| --- | --- |
| `game_paused` | Al pausar el juego. |
| `game_resumed` | Al reanudar el juego. |
| `game_ready_finished` | Despues de inicializar managers con `call_deferred`. |
| `game_state_changed(new_state)` | Cuando cambia `GameEnums.GameState`. |
| `close_game_requested` | Solicitud de cierre del juego. |
| `language_changed(new_language)` | Cambio de idioma. |
| `scene_loaded(scene_name)` | Despues de cambiar escena. |
| `transition_started(to_scene_path, duration, audio_behavior)` | Inicio de transicion. |
| `screen_covered` | La pantalla ya esta cubierta; momento seguro para cargar/preparar. |
| `transition_finished` | La transicion termino. |

### Metodos Principales

```gdscript
GameManager.change_scene("res://scenes/menu.tscn")
```

Cambia escena sin transicion visual. Emite `transition_started` con duracion `0.0`.

```gdscript
GameManager.change_scene_styled(
	"res://scenes/level_01.tscn",
	AudioEnums.AudioBehavior.SCENE_AUTO,
	Color("080d1c"),
	0.6
)
```

Cambia escena con cobertura visual y eventos de transicion.

```gdscript
GameManager.pause_game([pause_menu])
GameManager.resume_game()
GameManager.toggle_pause([pause_menu])
```

Pausa usando `get_tree().paused`. Los nodos excluidos pasan temporalmente a
`Node.PROCESS_MODE_ALWAYS`.

```gdscript
GameManager.change_game_state(GameEnums.GameState.PLAYING)
GameManager.get_playtime()
GameManager.is_in_gameplay()
```

### Deteccion De Estado Por Escena

`GameManager` infiere estado desde el nombre del archivo:

- Contiene `menu`: `MAIN_MENU`
- Contiene `level` o `gameplay`: `PLAYING`
- Contiene `cutscene`: `CUTSCENE`

Para juegos grandes conviene reemplazar esta heuristica por metadata de escena o
una tabla explicita.

## AudioManager

Gestiona musica, sonidos, buses y comportamiento ante pausa/transicion.

### Senales

| Senal | Cuando ocurre |
| --- | --- |
| `bus_volume_changed(bus_name, volume)` | Cambio de volumen de bus. |
| `sound_played(sound_name, sound_type)` | Reproduccion de efecto. |
| `music_changed(music_name)` | Cambio de musica actual. |
| `music_stoped` | Musica detenida. |
| `music_finished` | El stream de musica termino. |

### Musica

```gdscript
AudioManager.play_music(music_stream, "battle_theme", 1.0)
AudioManager.stop_music(0.5)
AudioManager.get_current_music_name()
AudioManager.is_music_playing()
```

Si `fade_duration` es `-1.0`, usa `EngineConfig.AUDIO_DEFAULT_MUSIC_FADE`.

### Sonidos

```gdscript
AudioManager.play_sound(jump_sfx, AudioEnums.BusName.SFX)
AudioManager.stop_all_sounds()
```

Los sonidos usan un pool inicial definido por `EngineConfig.AUDIO_SOUND_POOL_SIZE`.
Si el pool se llena, se crea un player adicional.

### Volumen Y Mute

```gdscript
AudioManager.set_bus_volume(AudioEnums.BusName.MUSIC, 0.5)
var volume := AudioManager.get_bus_volume(AudioEnums.BusName.MUSIC)
AudioManager.mute_bus(AudioEnums.BusName.SFX)
AudioManager.unmute_bus(AudioEnums.BusName.SFX)
var muted := AudioManager.toggle_bus_mute(AudioEnums.BusName.SFX)
```

El volumen se limita a `0.0..1.0` y se convierte a decibeles.

### Transiciones Y Pausa

`AudioManager` escucha:

- `GameManager.game_paused`
- `GameManager.game_resumed`
- `GameManager.transition_started`

Durante pausa baja el volumen master y pausa sonidos en buses `SFX` y `Voice`.

## InputManager

Abstrae input de teclado/mouse y gamepad, con deadzones por accion y buffer.

### Senales

| Senal | Cuando ocurre |
| --- | --- |
| `input_device_changed(device_type)` | Cambia entre teclado/mouse y gamepad. |
| `control_rebound(action, old_event, new_event)` | Se reasigna una accion. |
| `input_buffer_triggered(action)` | Una accion esta dentro del tiempo de buffer. |
| `action_deadzone_changed(action, deadzone)` | Cambio de deadzone. |

### Acciones

```gdscript
InputManager.is_action_pressed("move_left")
InputManager.is_action_just_pressed("jump")
InputManager.is_action_just_released("attack")
InputManager.get_action_strength("move_right")
InputManager.get_action_raw_strength("move_right")
```

Los metodos principales leen el estado cacheado por el manager y aplican deadzone.

### Deadzones

```gdscript
InputManager.set_action_deadzone("aim_x", 0.25)
InputManager.get_action_deadzone("aim_x")
InputManager.set_actions_deadzone(["aim_x", "aim_y"], 0.25)
InputManager.set_gamepad_axes_deadzone(0.3)
InputManager.apply_default_deadzone_to_all_actions()
```

### Buffer

```gdscript
InputManager.input_buffer_triggered.connect(_on_buffered_input)
InputManager.clear_input_buffer("jump")
InputManager.clear_all_input_buffers()
```

El tiempo de buffer viene de `EngineConfig.INPUT_BUFFER_TIME`.

### Rebinding

```gdscript
var ok := InputManager.rebind_action("jump", new_event)
var primary := InputManager.get_action_event("jump")
var all_events := InputManager.get_action_events("jump")
```

El rebinding depende de `EngineConfig.INPUT_ALLOW_INPUT_REBINDING`.

## VideoManager

Gestiona resolucion, modo de pantalla, VSync y refresco de UI.

### Senales

| Senal | Cuando ocurre |
| --- | --- |
| `resolution_changed(new_resolution)` | Cambio de resolucion. |
| `display_mode_changed(new_mode)` | Cambio de modo de ventana. |
| `vsync_mode_changed(new_mode)` | Cambio de VSync. |
| `fullscreen_toggled(is_fullscreen)` | Toggle de pantalla completa. |

### Resolucion

```gdscript
VideoManager.set_resolution(Vector2i(1280, 720))
VideoManager.set_resolution_by_index(0)
VideoManager.set_resolution_smooth(Vector2i(1920, 1080), 0.25)
VideoManager.set_resolution_smooth_by_index(1, 0.25)
VideoManager.get_current_resolution()
VideoManager.get_available_resolutions()
VideoManager.get_current_resolution_index()
```

Las resoluciones se filtran contra el tamano de pantalla y se ordenan de mayor a
menor.

### Pantalla Y VSync

```gdscript
VideoManager.set_display_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
var fullscreen := VideoManager.toggle_fullscreen()
VideoManager.is_fullscreen()
VideoManager.get_current_display_mode()

VideoManager.set_vsync_mode(DisplayServer.VSYNC_ENABLED)
var enabled := VideoManager.toggle_vsync()
VideoManager.is_vsync_enabled()
```

### UI

```gdscript
VideoManager.refresh_ui_after_resolution_change()
VideoManager.center_window()
VideoManager.apply_engine_defaults()
```

`refresh_ui_after_resolution_change()` llama `_on_resolution_changed` en el grupo
`ui_responsive`.

## SaveManager

Lee y escribe modulos de guardado. Ver [Guardado modular](SAVE_MODULES.md) para
el flujo completo.

### Senales

| Senal | Cuando ocurre |
| --- | --- |
| `saving(slot)` | Inicio de escritura. |
| `save_completed(slot, success)` | Escritura completada. |
| `loading(slot)` | Inicio de lectura. |
| `load_completed(slot, success)` | Lectura completada. |

### Escritura Y Lectura

```gdscript
SaveManager.write_module("slot_1", player_save)
SaveManager.write_modules_batch("slot_1", [player_save, world_save])

var ok := SaveManager.read_module("slot_1", player_save)
var all_ok := SaveManager.read_modules_batch("slot_1", [player_save, world_save])
```

Los datos se guardan en:

```text
user://saves/<slot>.cfg
```

Cada modulo se guarda como una seccion del `ConfigFile`.
