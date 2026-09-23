# Installation

Puppy Core supports Godot 4 and later. Add the complete repository to the project,
then enable only the services the game uses.

## Add the files

As a Git submodule:

```bash
git submodule add https://github.com/wdbals/puppy_core.git puppy_core
git submodule update --init
```

After cloning a game that already contains the submodule:

```bash
git clone --recurse-submodules <game-repository-url>
```

Keeping Puppy Core at `res://puppy_core/` preserves the paths used throughout this
documentation.

## Register optional autoloads

Open `Project > Project Settings > Globals > Autoload` and register the services
required by the game:

| Name | Script | Required dependencies |
| --- | --- | --- |
| `AudioManager` | `res://puppy_core/autoloads/audio_manager.gd` | None |
| `PauseManager` | `res://puppy_core/autoloads/pause_manager.gd` | None |
| `SceneManager` | `res://puppy_core/autoloads/scene_manager.gd` | None |
| `UISoundManager` | `res://puppy_core/autoloads/ui_sound_manager.gd` | `AudioManager` |
| `InputManager` | `res://puppy_core/autoloads/input_manager.gd` | None |
| `SaveManager` | `res://puppy_core/autoloads/save_manager.gd` | None |
| `VideoManager` | `res://puppy_core/autoloads/video_manager.gd` | None |

Do not register an unused service. Files present in the repository do not become
singletons automatically.

If project code connects two services, register that project coordinator after the
services it references.

Register `AudioManager` before `UISoundManager`. The UI service verifies this
dependency at startup and reports a descriptive error instead of connecting any
buttons when it is missing.

Create a project-owned `UISoundProfile` resource and assign it before the main
scene starts, typically from a project coordinator registered after both services:

```gdscript
const UI_SOUNDS := preload("res://game_content/config/ui_sounds.tres")

func _ready() -> void:
	UISoundManager.set_profile(UI_SOUNDS)
```

## Configure the project

Review `res://puppy_core/data/engine_config.gd`. It contains default audio buses,
pool size, fades, display resolutions, save behavior, and input settings.

Define the actions used by the game in `Project Settings > Input Map`. The optional
`InputManager` reads actions that exist when it starts.

`AudioManager.setup_audio_buses()` creates missing `Master`, `SFX`, `UI`, `Music`,
and `Voice` buses. Projects with custom audio layouts can extend the defaults or
use Godot's audio bus layout resource.

## Verify the installation

Run an editor import from the project root:

```bash
godot --headless --path . --editor --quit
```

Then run the project's main scene and check that registered autoloads appear below
`/root` in the remote scene tree.

## Update a pinned version

Each consuming repository stores an exact Puppy Core commit:

```bash
git -C puppy_core fetch --tags
git -C puppy_core checkout v0.2.0
git add puppy_core
git commit -m "build: update puppy_core to v0.2.0"
```

Make library changes on short-lived feature branches in the Puppy Core repository.
Keep project-specific changes in the consuming game instead of maintaining a branch
of Puppy Core for every game.
