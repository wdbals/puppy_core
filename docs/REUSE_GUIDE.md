# Guia De Reutilizacion

Esta guia ayuda a mantener `puppies_engine` como una base copiable entre juegos.

## Que Mantener Generico

Deja en `puppies_engine` solo sistemas transversales:

- Audio global.
- Estado de juego y transiciones.
- Input y rebinding.
- Video y ventana.
- Guardado modular.
- Enums y configuracion compartida.

Evita meter aqui logica especifica de un juego, como combate, inventario concreto,
enemigos, dialogos de una historia o rutas de escenas particulares.

## Donde Personalizar Por Juego

Puntos esperados de personalizacion:

- `EngineConfig`: valores por defecto, resoluciones, audio, input y save.
- `GameEnums`: estados, equipos, direcciones o idiomas propios del proyecto.
- `AudioEnums`: nuevos tipos de audio o prioridades si el juego lo necesita.
- Modulos que extiendan `SaveModule`.
- Escenas y scripts del juego fuera de `puppies_engine`.

## Contratos Publicos

Trata como API publica:

- Nombres de autoload: `GameManager`, `AudioManager`, `InputManager`,
  `SaveManager`, `VideoManager`.
- Senales documentadas en `API_REFERENCE.md`.
- Metodos publicos de managers.
- `SaveModule` como clase base.
- Enums en `data/`.

Antes de cambiar firmas publicas, revisa juegos existentes que ya dependan del
engine.

## Convenciones De Escenas

El estado de juego se infiere por nombre de archivo:

```text
menu      -> MAIN_MENU
level     -> PLAYING
gameplay  -> PLAYING
cutscene  -> CUTSCENE
```

Para reutilizacion en muchos juegos, una mejora recomendable es crear una tabla:

```gdscript
const SCENE_STATES := {
	"res://scenes/main_menu.tscn": GameEnums.GameState.MAIN_MENU,
	"res://scenes/level_01.tscn": GameEnums.GameState.PLAYING
}
```

Eso evita depender de nombres de archivo.

## Convenciones De Audio

Usa estos buses como base:

- `Master`: volumen global.
- `SFX`: efectos de gameplay y UI.
- `Music`: musica.
- `Voice`: voces o dialogos.

Si un juego necesita mas buses, agregalos en `EngineConfig.DEFAULT_AUDIO_BUSES` y
extiende `AudioEnums.BusName` junto con el mapeo privado de `AudioManager`.

## Convenciones De Input

Define acciones semanticas, no teclas concretas:

```text
move_left
move_right
jump
attack
pause
ui_accept
ui_cancel
```

El codigo del juego deberia consultar acciones, no eventos fisicos. Eso permite
soportar teclado, mouse, gamepad y rebinding sin cambiar gameplay.

## Convenciones De Guardado

Modela el save como un conjunto de modulos independientes:

```text
player
inventory
world
settings
quests
```

Cada modulo debe poder validar y restaurar su propia seccion. El manager solo
orquesta lectura/escritura.

## Checklist Para Copiar A Un Juego Nuevo

- Copiar `puppies_engine/`.
- Registrar autoloads en el orden documentado.
- Ajustar `EngineConfig`.
- Crear acciones en `InputMap`.
- Crear modulos de guardado necesarios.
- Revisar nombres de escenas o reemplazar la heuristica de estado.
- Probar pausa, cambio de escena, musica, SFX, resolucion y save/load.

## Mejoras Recomendadas

Estas mejoras harian la base mas robusta sin romper su filosofia:

- Separar `EngineConfig` base de una configuracion por juego.
- Implementar restauracion de bindings por defecto en `InputManager`.
- Persistir configuracion de video/audio/input usando `SaveModule`.
- Reemplazar deteccion de estado por nombre de escena con metadata explicita.
- Versionar modulos de guardado dentro del archivo.
- Mover la clave de encriptacion a una estrategia configurable.
