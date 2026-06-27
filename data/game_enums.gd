class_name GameEnums
## Enums generales del engine

enum GameLanguage {
	ES = 0,
	EN,
	DE,
	CH
}

enum GameState {
	BOOTING = 0,      # Inicializando el juego
	MAIN_MENU = 1,    # En menú principal
	LOADING = 2,      # Cargando escena
	PLAYING = 3,      # Jugando normalmente
	PAUSED = 4,       # Juego pausado
	GAME_OVER = 5,    # Pantalla de game over
	CUTSCENE = 6,     # En cinemática/cutscene
	CREDITS = 7       # En créditos
}

enum SceneType {
	BOOT = 0,         # Escena de inicialización
	MAIN_MENU = 1,    # Menú principal
	GAMEPLAY = 2,     # Nivel/juego principal
	LOADING = 3,      # Pantalla de carga
	CUTSCENE = 4,     # Cinemática
	CREDITS = 5       # Créditos
}

enum Teams {
	NEUTRAL = 0,      # Equipo neutral
	PLAYER = 1,       # Jugador y aliados
	ENEMY = 2,        # Enemigos
	FRIENDLY = 3,     # NPCs amigables
	ENVIRONMENT = 4   # Elementos del ambiente
}

enum Direction {
	NONE = 0,
	UP = 1,
	DOWN = 2,
	LEFT = 3,
	RIGHT = 4,
	UP_LEFT = 5,
	UP_RIGHT = 6,
	DOWN_LEFT = 7,
	DOWN_RIGHT = 8
}

# MÉTODOS UTILITARIOS

static func get_direction_name(direction: Direction) -> String:
	match direction:
		Direction.UP: return "up"
		Direction.DOWN: return "down"
		Direction.LEFT: return "left"
		Direction.RIGHT: return "right"
		Direction.UP_LEFT: return "up_left"
		Direction.UP_RIGHT: return "up_right"
		Direction.DOWN_LEFT: return "down_left"
		Direction.DOWN_RIGHT: return "down_right"
		_: return "none"

static func is_cardinal(direction: Direction) -> bool:
	return direction in [Direction.UP, Direction.DOWN, Direction.LEFT, Direction.RIGHT]

static func is_diagonal(direction: Direction) -> bool:
	return direction in [Direction.UP_LEFT, Direction.UP_RIGHT, Direction.DOWN_LEFT, Direction.DOWN_RIGHT]
