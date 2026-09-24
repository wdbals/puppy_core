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
	PauseManager.game_paused.connect(AudioManager.set_game_paused.bind(true))
	PauseManager.game_resumed.connect(AudioManager.set_game_paused.bind(false))
```

This keeps both reusable services independently installable.

Application lifecycle belongs to the game coordinator as well. A `GameSession`
autoload can intercept operating-system close requests, save project-specific data,
and then exit. Puppy Core does not infer menu, gameplay, or cutscene states from
scene filenames; games that need those states should model them explicitly.

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

Configuration is split by service into `PuppyAudioConfig`, `PuppyInputConfig`,
`PuppySaveConfig`, and `PuppyVideoConfig`. Their class defaults let each manager run
as a direct script autoload. A consuming project that needs different values should
create a `.tres` instance and assign it through a project-owned autoload scene.

Audio bus topology and its authored mix belong to `AudioBusLayout`, rather than
`PuppyAudioConfig`. The audio resource controls runtime behavior and missing-bus
fallback values. Immutable package metadata lives in `PuppyCoreInfo`.

`AudioSettingsModule` provides the reusable serialization mechanism for bus volume
and mute preferences. The consuming project decides when to load or save it and
which controls appear in its settings screen. This keeps menu flow and application
lifecycle out of the shared module.

## Audio ownership

Use `AudioManager.play_sound()` for UI and non-spatial sounds. Use
`play_sound_2d()` or `play_sound_3d()` for short world events. A moving or looping
sound belongs to its entity as an `AudioStreamPlayer2D` or `AudioStreamPlayer3D`.

This distinction prevents the global manager from becoming responsible for entity
lifetime and movement.

`UISoundManager` is an optional adapter with one documented dependency:
`AudioManager` must be registered first. It automatically connects `BaseButton`
nodes and reads sounds from a `UISoundProfile` supplied by the consuming project.
Use the `ui_sound_silent`, `ui_sound_confirm`, and `ui_sound_cancel` node groups to
control individual buttons without attaching scripts.

## Combat payloads

Keep impact information together in `HitData`. Add broadly reusable fields there
only when multiple games need them. Project-specific status effects can subclass or
wrap the payload, or react to `HurtBox.damaged` in game code.

## Versioning

Use one stable `main` branch and short-lived branches per reusable change. Tag
pre-1.0 releases as `v0.1.0`, `v0.2.0`, and so on. Each consuming game pins an exact
submodule commit. Do not maintain a permanent Puppy Core branch per game; place
project adaptations beside the game's content instead.
