@abstract class_name SaveModule
## Clase base abstracta para módulos de guardado
extends RefCounted

## Nombre único del módulo
@abstract func get_module_name() -> String

## Devuelve datos a guardar
@abstract func capture_snapshot() -> Dictionary

## Restaura datos. Retorna true si fue exitoso
@abstract func restore_snapshot(data: Dictionary) -> bool

# Hooks

## Versión del módulo para compatibilidad
func get_module_version() -> String:
	return "1.0.0"

## Validación de datos antes de cargar.
func validate_data(_data: Dictionary) -> bool:
	return true

## Función llamada antes de guardar.
func pre_save() -> void:
	pass

## Función llamada después de cargar.
func post_load() -> void:
	pass
