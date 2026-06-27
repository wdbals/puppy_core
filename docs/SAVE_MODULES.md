# Guardado Modular

El sistema de guardado se basa en modulos. Cada modulo conoce como capturar,
validar y restaurar una parte del estado del juego.

## Contrato Base

Todo modulo debe extender `SaveModule`:

```gdscript
extends SaveModule

var coins: int = 0
var position: Vector2 = Vector2.ZERO

func get_module_name() -> String:
	return "player"

func capture_snapshot() -> Dictionary:
	return {
		"coins": coins,
		"position": position
	}

func restore_snapshot(data: Dictionary) -> bool:
	coins = data.get("coins", 0)
	position = data.get("position", Vector2.ZERO)
	return true

func validate_data(data: Dictionary) -> bool:
	return data.has("coins") and data.has("position")
```

## Ciclo De Escritura

```gdscript
SaveManager.write_module("slot_1", player_module)
```

Flujo interno:

1. Emite `saving(slot_name)`.
2. Carga el archivo existente del slot, si existe.
3. Llama `module.pre_save()`.
4. Llama `module.capture_snapshot()`.
5. Escribe los datos en la seccion `module.get_module_name()`.
6. Actualiza `meta.last_updated`.
7. Guarda en disco.
8. Emite `save_completed(slot_name, success)`.

## Ciclo De Lectura

```gdscript
var ok := SaveManager.read_module("slot_1", player_module)
```

Flujo interno:

1. Emite `loading(slot_name)`.
2. Carga el archivo del slot.
3. Busca una seccion con `module.get_module_name()`.
4. Construye un `Dictionary` con las claves de esa seccion.
5. Llama `module.validate_data(data)`.
6. Si es valido, llama `module.restore_snapshot(data)`.
7. Llama `module.post_load()`.
8. Emite `load_completed(slot_name, success)`.

## Guardar Varios Modulos

```gdscript
SaveManager.write_modules_batch("slot_1", [
	player_save,
	inventory_save,
	world_save
])
```

Usa batch cuando varias partes del estado deben quedar sincronizadas en el mismo
archivo.

## Nombres De Modulo

`get_module_name()` debe ser unico por slot. Ejemplos:

- `player`
- `inventory`
- `world`
- `settings`
- `quest_state`

Evita nombres derivados de escenas temporales si el estado debe sobrevivir a
renombres.

## Versionado

`SaveModule.get_module_version()` existe para compatibilidad, pero `SaveManager`
todavia no escribe ni valida versiones automaticamente. Patron recomendado:

```gdscript
func capture_snapshot() -> Dictionary:
	return {
		"version": get_module_version(),
		"coins": coins
	}

func validate_data(data: Dictionary) -> bool:
	return data.get("version", "0.0.0") == get_module_version()
```

Para proyectos con saves persistentes entre versiones, agrega migraciones dentro
del modulo antes de restaurar.

## Encriptacion

Si `EngineConfig.SAVE_USE_ENCRYPTION` es `true`, `SaveManager` usa
`ConfigFile.load_encrypted_pass()` y `save_encrypted_pass()`.

La clave actual esta definida dentro de `SaveManager`:

```gdscript
const _SECRET_KEY: String = "puppies-x7z-secure"
```

Para juegos publicados conviene mover esta decision a configuracion por proyecto
o a una estrategia mas robusta.

## Buenas Practicas

- Mantener cada modulo pequeno y con una responsabilidad clara.
- Validar datos antes de restaurar.
- Usar valores por defecto al leer claves opcionales.
- Guardar identificadores estables, no referencias directas a nodos.
- Evitar guardar estado derivado que pueda recalcularse.
- Usar batch para checkpoints o guardados manuales completos.
