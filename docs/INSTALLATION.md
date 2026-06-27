# Instalacion

Esta guia cubre como copiar `puppies_engine` a un proyecto Godot y dejarlo listo
para uso.

## 1. Copiar La Carpeta

Copia `puppies_engine/` a la raiz del proyecto:

```text
res://puppies_engine/
```

No muevas los scripts internos sin actualizar las rutas de autoload y referencias.

## 2. Registrar Autoloads

En `Project Settings > Autoload`, registra:

| Orden | Nombre | Script |
| --- | --- | --- |
| 1 | `GameManager` | `res://puppies_engine/core/autoload/game_manager.gd` |
| 2 | `AudioManager` | `res://puppies_engine/core/autoload/audio_manager.gd` |
| 3 | `InputManager` | `res://puppies_engine/core/autoload/input_manager.gd` |
| 4 | `SaveManager` | `res://puppies_engine/core/autoload/save_manager.gd` |
| 5 | `VideoManager` | `res://puppies_engine/core/autoload/video_manager.gd` |

El orden importa porque `AudioManager` se conecta a senales de `GameManager` en
`_ready()`.

## 3. Configurar El Proyecto

Revisa `res://puppies_engine/data/engine_config.gd`:

- Audio: buses, volumenes iniciales, tamano del pool de sonidos y fades.
- Video: resoluciones disponibles, modo de ventana y VSync inicial.
- Input: deadzone, buffer, sensibilidad del mouse y rebinding.
- Save: cantidad de slots, intervalo de autosave y encriptacion.
- Game: velocidad, FPS fisico y escala de tiempo.

## 4. Configurar Input Map

`InputManager` lee las acciones existentes en `InputMap` al iniciar. Define tus
acciones antes de depender de:

```gdscript
InputManager.is_action_pressed("move_left")
InputManager.is_action_just_pressed("jump")
InputManager.get_action_strength("aim_x")
```

Si agregas acciones en runtime, considera reinicializar estados o extender el
manager para registrar acciones nuevas.

## 5. Audio Buses

`AudioManager.setup_audio_buses()` crea si faltan estos buses:

- `Master`
- `SFX`
- `Music`
- `Voice`

Tambien aplica los volumenes iniciales declarados en `EngineConfig.DEFAULT_AUDIO_BUSES`.

## 6. Verificacion Manual

Al ejecutar el juego deberias ver logs similares:

```text
GameManager iniciado - Puppies Engine v1.0.0
AudioManager iniciado
InputManager iniciado
VideoManager iniciado - Resoluciones disponibles: ...
```

Si hay errores de autoload, revisa nombres exactos, orden y rutas.
