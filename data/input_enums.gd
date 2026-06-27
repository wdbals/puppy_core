class_name InputEnums

## Enums para sistema de input

enum InputDevice {
	KEYBOARD = 0,
	GAMEPAD = 1,
	TOUCH = 2
}

enum GamepadType {
	UNKNOWN = 0,
	XBOX = 1,
	PLAYSTATION = 2,
	NINTENDO = 3,
	GENERIC = 4
}

enum InputContext {
	GAMEPLAY = 0,
	UI = 1,
	MENU = 2,
	DEFAULT = 3
}

## MÉTODOS UTILITARIOS

static func get_device_name(device: InputDevice) -> String:
	match device:
		InputDevice.KEYBOARD: return "Teclado/Mouse"
		InputDevice.GAMEPAD: return "Gamepad"
		InputDevice.TOUCH: return "Pantalla táctil"
		_: return "Desconocido"

static func get_gamepad_type_name(gamepad_type: GamepadType) -> String:
	match gamepad_type:
		GamepadType.XBOX: return "Xbox"
		GamepadType.PLAYSTATION: return "PlayStation"
		GamepadType.NINTENDO: return "Nintendo"
		GamepadType.GENERIC: return "Genérico"
		_: return "Desconocido"
