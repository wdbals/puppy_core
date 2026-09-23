# Reuse Guide

Puppy Core should contain mechanisms that remain useful when copied into a game
with different rules, scenes, controls, and content.

## Library boundary

Good Puppy Core candidates include:

- Audio playback and bus control.
- Scene transitions and pause primitives.
- Input normalization and rebinding.
- Window and display settings.
- Save-file orchestration.
- Generic health and collision-based combat components.

Keep these in the consuming project:

- Difficulty settings such as one-hit mode.
- Story, menu, cutscene, victory, or game-over states.
- Scene paths and filename conventions.
- Wave, quest, inventory, and character rules.
- Decisions about how two independent services interact.

For example, an Equinoccio coordinator may own both its run settings and the desired
pause/audio relationship:

```gdscript
extends Node

var one_hit_mode := false

func _ready() -> void:
	GameManager.game_paused.connect(AudioManager.set_game_paused.bind(true))
	GameManager.game_resumed.connect(AudioManager.set_game_paused.bind(false))
```

This keeps both reusable services independently installable.

## Public API

Treat these as public contracts:

- Autoload names selected by the consuming project.
- Signals and public methods documented in `API_REFERENCE.md`.
- `class_name` types such as `HitData`, `Hitbox`, `HurtBox`, `Health`, and
  `SaveModule`.
- Exported properties stored in `.tscn` and `.tres` resources.

Renaming an exported property requires updating existing scenes. Changing a signal's
arguments requires updating every connection. During the pre-1.0 phase, group such
changes into intentional minor releases.

## Language and naming

Puppy Core source, public identifiers, diagnostics, and documentation use English.
Consuming games may use any language internally. Keeping the shared module in one
language makes search results and API usage consistent across projects.

## Configuration

`EngineConfig` currently provides library defaults. Avoid editing it for a single
game unless the change is useful to all consumers. When projects need substantially
different defaults, introduce a project-owned configuration resource and pass it to
the relevant service from the game's bootstrap code.

## Audio ownership

Use `AudioManager.play_sound()` for UI and non-spatial sounds. Use
`play_sound_2d()` or `play_sound_3d()` for short world events. A moving or looping
sound belongs to its entity as an `AudioStreamPlayer2D` or `AudioStreamPlayer3D`.

This distinction prevents the global manager from becoming responsible for entity
lifetime and movement.

## Combat payloads

Keep impact information together in `HitData`. Add broadly reusable fields there
only when multiple games need them. Project-specific status effects can subclass or
wrap the payload, or react to `HurtBox.damaged` in game code.

## Versioning

Use one stable `main` branch and short-lived branches per reusable change. Tag
pre-1.0 releases as `v0.1.0`, `v0.2.0`, and so on. Each consuming game pins an exact
submodule commit. Do not maintain a permanent Puppy Core branch per game; place
project adaptations beside the game's content instead.
