# Save Modules

`SaveManager` stores independent sections in `user://saves/<slot>.cfg`. Each section
is represented by a `SaveModule` that captures, validates, and restores one part of
game state. Its three required methods provide error-reporting defaults so the API
also works on Godot versions before abstract GDScript classes were introduced.

## Define a module

```gdscript
class_name PlayerSaveModule
extends SaveModule

var player: Player

func _init(player_node: Player) -> void:
	player = player_node

func get_module_name() -> String:
	return "player"

func capture_snapshot() -> Dictionary:
	return {
		"position": player.global_position,
		"health": player.health,
	}

func restore_snapshot(data: Dictionary) -> Error:
	if not data.has("position") or not data.has("health"):
		return ERR_INVALID_DATA
	player.global_position = data.position
	player.health = data.health
	return OK

func validate_data(data: Dictionary) -> bool:
	return data.has("position") and data.has("health")
```

The module name is the ConfigFile section name. Keep it stable after publishing save
files.

## Write data

```gdscript
var result := SaveManager.write_module("slot_1", player_save)
if result != OK:
	push_error("Save failed: %s" % error_string(result))
```

The manager loads the existing slot, calls `pre_save()`, captures each snapshot,
writes the module sections, refreshes the shared timestamp, and saves the file once.

Use the batch method for a complete checkpoint so every module is written from one
logical game state.

## Read data

```gdscript
var result := SaveManager.read_modules_batch(
	"slot_1",
	[player_save, world_save]
)
if result != OK:
	push_error("Load failed: %s" % error_string(result))
```

For each module, the manager reads its section, calls `validate_data()`, restores the
snapshot, and then calls `post_load()`. Missing files return `ERR_FILE_NOT_FOUND`,
missing module sections return `ERR_DOES_NOT_EXIST`, invalid dictionaries return
`ERR_INVALID_DATA`, and `restore_snapshot()` can return a more specific error.

All public read and write methods use Godot's `Error` enum. Batch operations stop at
the first failed module, so callers receive the original error instead of a generic
success flag. The completion signals contain that same result:

```gdscript
SaveManager.save_completed.connect(
	func(slot: String, result: Error) -> void:
		if result != OK:
			push_error("Could not save %s: %s" % [slot, error_string(result)])
)
```

## Versioning save schemas

`SaveModule.get_module_version()` returns a schema version for use by project code.
`SaveManager` does not yet persist or migrate schema versions automatically. A game
that changes published save data should store a version in each module section and
migrate older dictionaries before restoring them.

## Encryption

`EngineConfig.SAVE_USE_ENCRYPTION` selects ConfigFile password encryption. The
current password is an internal development default. Published games should inject
their own key strategy instead of treating a source-code password as secure secret
storage.

## Guidelines

- Give each module one clear responsibility.
- Store stable identifiers instead of node references.
- Validate external data before restoring it.
- Avoid saving values that can be derived safely.
- Keep migration code for every save schema shipped to players.
