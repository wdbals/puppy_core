class_name AudioEnums
## Enums para Estandar del Audio Manager

enum AudioBehavior {
	KEEP_AUDIO = 0,      # No cambiar nada
	STOP_MUSIC = 1,      # Solo detener música  
	STOP_ALL = 2,        # Detener todo el audio
	SCENE_AUTO = 3       # Comportamiento automático por escena
}

enum BusName {
	MASTER = 0,
	SFX = 1, 
	MUSIC = 2,
	VOICE = 3
}

enum SoundType {
	UI,
	GAMEPLAY,
	AMBIENT,
	VOICE,
	MUSIC
}

enum SoundPriority {
	LOW = 0,
	NORMAL = 1,
	HIGH = 2,
	CRITICAL = 3
}
