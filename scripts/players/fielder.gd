class_name Fielder
extends Node2D

signal ball_caught_air(fielder: Node2D)
signal ball_fielded_ground(fielder: Node2D)
signal throw_completed(target_pos: Vector2)

enum FielderState {
	IDLE,
	CHASING,
	CATCHING,
	THROWING,
	RETURNING
}

@export var fielder_name: String = "Fielder"
@export var base_position: Vector2 = Vector2.ZERO
@export var move_speed: float = 275.0

var current_state: FielderState = FielderState.IDLE
var target_destination: Vector2 = Vector2.ZERO
var leg_cycle: float = 0.0
var throw_timer: float = 0.0
var throw_target_pos: Vector2 = Vector2.ZERO

# Cores do time defensivo (azul e branco)
const COLOR_JERSEY = Color(0.18, 0.38, 0.72)
const COLOR_PANTS = Color(0.92, 0.92, 0.92)
const COLOR_CAP = Color(0.12, 0.25, 0.55)
const COLOR_SKIN = Color(0.94, 0.76, 0.62)
const COLOR_GLOVE = Color(0.48, 0.28, 0.15)

func _ready() -> void:
	if base_position == Vector2.ZERO:
		base_position = position
	else:
		position = base_position

func reset_position() -> void:
	current_state = FielderState.IDLE
	target_destination = base_position
	position = base_position
	leg_cycle = 0.0
	throw_timer = 0.0
	queue_redraw()

func chase_ball(target_pos: Vector2) -> void:
	target_destination = target_pos
	current_state = FielderState.CHASING

func catch_air() -> void:
	current_state = FielderState.CATCHING
	ball_caught_air.emit(self)
	queue_redraw()

func field_ground() -> void:
	current_state = FielderState.CATCHING
	ball_fielded_ground.emit(self)
	queue_redraw()

func throw_to(target_pos: Vector2) -> void:
	current_state = FielderState.THROWING
	throw_target_pos = target_pos
	throw_timer = 0.0
	queue_redraw()

func return_to_base() -> void:
	target_destination = base_position
	current_state = FielderState.RETURNING

func _process(delta: float) -> void:
	match current_state:
		FielderState.CHASING, FielderState.RETURNING:
			var step = move_speed * delta
			var dist = position.distance_to(target_destination)
			leg_cycle += delta * 16.0

			if dist <= step or dist < 4.0:
				position = target_destination
				if current_state == FielderState.RETURNING:
					current_state = FielderState.IDLE
			else:
				var dir = (target_destination - position).normalized()
				position += dir * step
			queue_redraw()

		FielderState.THROWING:
			throw_timer += delta
			if throw_timer >= 0.22:
				current_state = FielderState.RETURNING
				target_destination = base_position
				throw_completed.emit(throw_target_pos)
			queue_redraw()

		FielderState.IDLE, FielderState.CATCHING:
			pass

func _draw() -> void:
	# 1. Sombra no chão
	draw_custom_ellipse(Vector2(0, 8), 14.0, 7.0, Color(0.1, 0.15, 0.1, 0.3))

	# 2. Pernas / Calça
	var is_running = (current_state == FielderState.CHASING or current_state == FielderState.RETURNING)
	var leg_offset = sin(leg_cycle) * 5.0 if is_running else 0.0
	draw_line(Vector2(-4, -2), Vector2(-4 - leg_offset * 0.5, 9 + leg_offset * 0.2), COLOR_PANTS, 4.0)
	draw_line(Vector2(4, -2), Vector2(4 + leg_offset * 0.5, 9 - leg_offset * 0.2), COLOR_PANTS, 4.0)
	# Chuteiras
	draw_rect(Rect2(-6 - leg_offset * 0.5, 9 + leg_offset * 0.2, 5, 3), Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(2 + leg_offset * 0.5, 9 - leg_offset * 0.2, 5, 3), Color(0.1, 0.1, 0.1))

	# 3. Tronco / Camisa do time de defesa
	draw_rect(Rect2(-8, -17, 16, 15), COLOR_JERSEY)
	draw_line(Vector2(0, -17), Vector2(0, -2), Color(0.85, 0.85, 0.85), 1.5)

	# 4. Braço com Luva (estendida para cima se pegando no ar, ou para baixo se IDLE/correndo)
	var glove_offset = Vector2(-12, -18) if current_state == FielderState.CATCHING else Vector2(-11, -8)
	draw_line(Vector2(-7, -13), glove_offset, COLOR_JERSEY, 4.0)
	draw_circle(glove_offset, 5.5, COLOR_GLOVE)

	# 5. Braço de arremesso
	var arm_offset = Vector2(10, -16) if current_state == FielderState.THROWING else Vector2(8, -6)
	draw_line(Vector2(7, -13), arm_offset, COLOR_SKIN, 3.5)
	draw_circle(arm_offset, 3.5, COLOR_SKIN)

	# 6. Cabeça e Boné com aba
	draw_circle(Vector2(0, -22), 7.5, COLOR_SKIN)
	draw_circle(Vector2(0, -24), 8.0, COLOR_CAP)
	draw_rect(Rect2(-5, -23, 10, 3), COLOR_CAP)

	# 7. Nome abreviado do defensor acima da cabeça para fácil identificação
	var font = ThemeDB.fallback_font
	var font_size = 11
	var short_name = _get_short_name()
	var text_size = font.get_string_size(short_name, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, Vector2(-text_size.x * 0.5, -30), short_name, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.95, 0.95, 0.95, 0.85))

func _get_short_name() -> String:
	match fielder_name:
		"First Baseman": return "1B"
		"Second Baseman": return "2B"
		"Shortstop": return "SS"
		"Third Baseman": return "3B"
		"Left Fielder": return "LF"
		"Center Fielder": return "CF"
		"Right Fielder": return "RF"
		"Pitcher": return "P"
		"Catcher": return "C"
		_: return fielder_name.left(2)

func draw_custom_ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(12):
		var a = i * TAU / 12
		points.append(center + Vector2(cos(a) * radius_x, sin(a) * radius_y))
	draw_colored_polygon(points, color)
