# Puppies Engine

Base reutilizable para juegos en Godot 4. Centraliza servicios comunes en autoloads:
audio, ciclo de vida del juego, input, video y guardado modular.

## Objetivo

`puppies_engine` no pretende ser un framework cerrado. Es una capa pequena y
copiable que deja resueltas las necesidades repetidas de un juego:

- Estados globales del juego y cambios de escena.
- Transiciones de escena con eventos sincronizables.
- Audio por buses, musica, efectos y comportamiento durante pausas/transiciones.
- Input unificado para teclado, mouse y gamepad, con deadzones y buffer.
- Configuracion de resolucion, pantalla completa y VSync.
- Guardado por modulos independientes.
- Enums y constantes compartidas para evitar strings magicos.

## Estructura

```text
puppies_engine/
  core/
    autoload/
      audio_manager.gd
      game_manager.gd
      input_manager.gd
      save_manager.gd
      video_manager.gd
    modules/
      save_module.gd
  data/
    audio_enums.gd
    engine_config.gd
    game_enums.gd
    input_enums.gd
    save_enums.gd
```

## Requisitos

- Godot 4.2 o 4.3, segun `EngineConfig.ENGINE_SUPPORTED_GODOT_VERSIONS`.
- Registrar los managers como autoloads.
- Mantener los `class_name` de enums y configuracion disponibles globalmente.

## Instalacion En Otro Juego

1. Copia la carpeta `puppies_engine/` al proyecto Godot.
2. Registra estos autoloads en `Project Settings > Autoload`, en este orden:

| Nombre | Script |
| --- | --- |
| `GameManager` | `res://puppies_engine/core/autoload/game_manager.gd` |
| `AudioManager` | `res://puppies_engine/core/autoload/audio_manager.gd` |
| `InputManager` | `res://puppies_engine/core/autoload/input_manager.gd` |
| `SaveManager` | `res://puppies_engine/core/autoload/save_manager.gd` |
| `VideoManager` | `res://puppies_engine/core/autoload/video_manager.gd` |

3. Ajusta constantes del proyecto en `data/engine_config.gd`.
4. Define las acciones de input del juego en `Project Settings > Input Map`.
5. Usa los managers desde cualquier script mediante sus nombres de autoload.

## Uso Rapido

```gdscript
# Cambiar escena con transicion y apagar musica.
GameManager.change_scene_styled(
	"res://scenes/level_01.tscn",
	AudioEnums.AudioBehavior.STOP_MUSIC
)

# Reproducir audio.
AudioManager.play_music(preload("res://audio/theme.ogg"), "theme")
AudioManager.play_sound(preload("res://audio/jump.wav"), AudioEnums.BusName.SFX)

# Leer input con deadzone aplicada.
if InputManager.is_action_just_pressed("jump"):
	jump()

# Alternar pantalla completa.
VideoManager.toggle_fullscreen()
```

## Documentacion

- [Instalacion](docs/INSTALLATION.md)
- [Referencia de API](docs/API_REFERENCE.md)
- [Guardado modular](docs/SAVE_MODULES.md)
- [Guia de reutilizacion](docs/REUSE_GUIDE.md)

## Convenciones

- Los managers son singletons/autoloads y forman la API publica principal.
- `EngineConfig` contiene valores por defecto modificables por juego.
- Los enums de `data/` son contratos compartidos entre managers y codigo de juego.
- Las escenas de menu, nivel y cutscene se detectan actualmente por nombre de archivo.
  Ver `GameManager._update_game_state_from_scene()`.

## Estado Actual

Esta documentacion describe la API existente. Algunas areas son intencionalmente
minimas o pendientes:

- `InputManager.restore_default_binding()` todavia no restaura bindings por defecto.
- `VideoManager.setup_viewport_scaling()` es un placeholder.
- `SaveManager` guarda en `user://saves/<slot>.cfg` y usa una clave interna fija si
  `SAVE_USE_ENCRYPTION` esta activo.
