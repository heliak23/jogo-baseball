class_name Runner
extends Node2D

signal reached_base(base_index: int)
signal scored_run(runner: Node2D)

# Posições padrão das bases (iguais ao BaseballField)
const HOME_POS = Vector2(640, 620)
const FIRST_POS = Vector2(780, 490)
const SECOND_POS = Vector2(640, 360)
const THIRD_POS = Vector2(500, 490)

# Mapeamento do caminho circular das bases
const BASE_POSITIONS: Array[Vector2] = [
	HOME_POS,   # 0: Home
	FIRST_POS,  # 1: 1B
	SECOND_POS, # 2: 2B
	THIRD_POS,  # 3: 3B
	HOME_POS    # 4: Home (Run marcado!)
]

@export var run_speed: float = 340.0

var current_base_index: int = 0
var target_base_index: int = 0
var is_running: bool = false
var waypoints: Array[Vector2] = []
var current_waypoint_idx: int = 0

# Animação de corrida
var leg_cycle: float = 0.0

# Cores do uniforme de ataque (idêntico ao batter)
const COLOR_JERSEY = Color(0.85, 0.22, 0.22)
const COLOR_PANTS = Color(0.94, 0.94, 0.94)
const COLOR_HELMET = Color(0.75, 0.15, 0.15)
const COLOR_SKIN = Color(0.94, 0.76, 0.62)

func _ready() -> void:
	position = BASE_POSITIONS[current_base_index]

func set_initial_base(base_idx: int) -> void:
	current_base_index = clampi(base_idx, 0, 3)
	target_base_index = current_base_index
	position = BASE_POSITIONS[current_base_index]
	is_running = false
	waypoints.clear()
	queue_redraw()

func advance_to_base(new_target_idx: int) -> void:
	target_base_index = new_target_idx
	waypoints.clear()
	
	# Constrói o caminho passando por cada base sequencialmente
	for b in range(current_base_index + 1, target_base_index + 1):
		var pos_idx = clampi(b, 0, 4)
		waypoints.append(BASE_POSITIONS[pos_idx])
	
	if waypoints.size() > 0:
		is_running = true
		current_waypoint_idx = 0
	else:
		is_running = false

func _process(delta: float) -> void:
	if not is_running:
		return

	leg_cycle += delta * 18.0 # Ciclo de passada

	if current_waypoint_idx < waypoints.size():
		var target_pos = waypoints[current_waypoint_idx]
		var step = run_speed * delta
		var dist = position.distance_to(target_pos)

		if dist <= step:
			position = target_pos
			current_waypoint_idx += 1
			
			# Chegou ao ponto intermediário ou final
			if current_waypoint_idx >= waypoints.size():
				# Chegou ao destino final
				is_running = false
				current_base_index = target_base_index
				queue_redraw()
				
				if current_base_index >= 4:
					# Cruzou o Home Plate e marcou RUN!
					scored_run.emit(self)
					_play_score_celebration()
				else:
					reached_base.emit(current_base_index)
		else:
			var dir = (target_pos - position).normalized()
			position += dir * step
	
	queue_redraw()

func _play_score_celebration() -> void:
	# Animação de comemoração e fade out suave ao marcar o ponto
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(queue_free)

func _draw() -> void:
	# 1. Sombra no solo
	draw_custom_ellipse(Vector2(0, 8), 12.0, 6.0, Color(0.1, 0.15, 0.1, 0.35))

	# 2. Pernas com animação de corrida
	var leg_offset = sin(leg_cycle) * 7.0 if is_running else 0.0
	draw_line(Vector2(-4, -2), Vector2(-4 - leg_offset * 0.6, 10 + leg_offset * 0.3), COLOR_PANTS, 4.0)
	draw_line(Vector2(4, -2), Vector2(4 + leg_offset * 0.6, 10 - leg_offset * 0.3), COLOR_PANTS, 4.0)
	# Chuteiras
	draw_rect(Rect2(-6 - leg_offset * 0.6, 10 + leg_offset * 0.3, 5, 3), Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(2 + leg_offset * 0.6, 10 - leg_offset * 0.3, 5, 3), Color(0.1, 0.1, 0.1))

	# 3. Tronco (camisa vermelha do time de rebatida)
	draw_rect(Rect2(-8, -16, 16, 14), COLOR_JERSEY)

	# 4. Cabeça e capacete de corrida com aba
	draw_circle(Vector2(0, -21), 7.0, COLOR_SKIN)
	draw_circle(Vector2(0, -23), 7.5, COLOR_HELMET)
	# Aba do capacete
	var facing_dir = 1.0 if (is_running and waypoints.size() > 0 and waypoints[clampi(current_waypoint_idx, 0, waypoints.size() - 1)].x > position.x) else -1.0
	draw_rect(Rect2(-2 + (facing_dir * 3), -26, 6, 3), COLOR_HELMET)

func draw_custom_ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(12):
		var a = i * TAU / 12
		points.append(center + Vector2(cos(a) * radius_x, sin(a) * radius_y))
	draw_colored_polygon(points, color)
