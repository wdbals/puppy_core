class_name InputEnums
## Shared types for InputManager.

enum InputDevice {
	KEYBOARD,
	GAMEPAD,
	TOUCH,
}

enum GamepadType {
	UNKNOWN,
	XBOX,
	PLAYSTATION,
	NINTENDO,
	GENERIC,
}

enum InputContext {
	GAMEPLAY,
	UI,
	MENU,
	DEFAULT,
}


static func get_device_name(device: InputDevice) -> String:
	match device:
		InputDevice.KEYBOARD: return "Keyboard/Mouse"
		InputDevice.GAMEPAD: return "Gamepad"
		InputDevice.TOUCH: return "Touchscreen"
		_: return "Unknown"


static func get_gamepad_type_name(gamepad_type: GamepadType) -> String:
	match gamepad_type:
		GamepadType.XBOX: return "Xbox"
		GamepadType.PLAYSTATION: return "PlayStation"
		GamepadType.NINTENDO: return "Nintendo"
		InputEnums.GamepadType.GENERIC: return "Generic"
		_: return "Unknown"
