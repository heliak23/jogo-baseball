class_name Batter
extends Node2D

signal swing_started()
signal contact_made(quality: String, hit_type: String, exit_vel: float, launch_angle: float, dir_deg: float, timing_ms: int)
signal swing_missed(reason: String)

const BallScript = preload("res://scripts/ball/ball.gd")

enum State {
	STANCE,
	SWINGING,
	FOLLOW_THROUGH,
	RECOVERING
}

@export var batter_pos: Vector2 = Vector2(595, 615)
@export var ball_ref: Node2D

var current_state: State = State.STANCE
var swing_timer: float = 0.0
var bat_angle: float = -0.7 # Ângulo de preparação do taco
var has_hit_this_swing: bool = false
var missed_reported: bool = false

# Efeito visual de impacto no contato
var spark_timer: float = 0.0
var spark_pos: Vector2 = Vector2.ZERO
var spark_color: Color = Color.WHITE
var spark_is_perfect: bool = false

# Cores do uniforme do time atacante (vermelho/branco)
const COLOR_JERSEY = Color(0.85, 0.22, 0.22) # Vermelho
const COLOR_PANTS = Color(0.94, 0.94, 0.94)  # Branco
const COLOR_HELMET = Color(0.75, 0.15, 0.15) # Capacete vermelho com aba
const COLOR_SKIN = Color(0.94, 0.76, 0.62)
const COLOR_BAT = Color(0.82, 0.64, 0.42)    # Madeira de freixo clara
const COLOR_BAT_HANDLE = Color(0.2, 0.2, 0.2)

const SWING_DURATION = 0.22 # Swing ágil e responsivo
const SWEET_SPOT_TIME = 0.10 # Momento ápice do swing (quando cruza o centro do plate)

func _ready() -> void:
	position = batter_pos

func _unhandled_input(event: InputEvent) -> void:
	if current_state != State.STANCE:
		return

	if (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE) or event.is_action_pressed("swing"):
		start_swing()

func start_swing() -> void:
	if current_state != State.STANCE:
		return
	current_state = State.SWINGING
	swing_timer = 0.0
	has_hit_this_swing = false
	missed_reported = false
	swing_started.emit()

func become_runner() -> void:
	visible = false

func reset_stance() -> void:
	visible = true
	current_state = State.STANCE
	swing_timer = 0.0
	bat_angle = -0.7
	has_hit_this_swing = false
	missed_reported = false
	spark_timer = 0.0
	queue_redraw()

func _physics_process(delta: float) -> void:
	# Atualiza efeito de faíscas de contato
	if spark_timer > 0.0:
		spark_timer -= delta
		queue_redraw()

	match current_state:
		State.SWINGING:
			swing_timer += delta
			var t = clampf(swing_timer / SWING_DURATION, 0.0, 1.0)
			# Rotação rápida do taco em arco: de -0.7 rad (~ -40°) até 2.4 rad (~ 140°)
			bat_angle = lerpf(-0.7, 2.4, t)
			
			# Janela de checagem de impacto ativo: t entre 0.30 e 0.78
			if not has_hit_this_swing and t >= 0.30 and t <= 0.78:
				_check_ball_contact()

			if t >= 1.0:
				current_state = State.FOLLOW_THROUGH
				swing_timer = 0.0
				if not has_hit_this_swing and not missed_reported:
					missed_reported = true
					swing_missed.emit("SWING & MISS")
			queue_redraw()

		State.FOLLOW_THROUGH:
			swing_timer += delta
			if swing_timer >= 0.22:
				current_state = State.RECOVERING
				swing_timer = 0.0
			queue_redraw()

		State.RECOVERING:
			swing_timer += delta
			var t = clampf(swing_timer / 0.18, 0.0, 1.0)
			bat_angle = lerpf(2.4, -0.7, t)
			if t >= 1.0:
				current_state = State.STANCE
			queue_redraw()

func _check_ball_contact() -> void:
	if not is_instance_valid(ball_ref):
		return
	
	# Só pode rebater se a bola estiver arremessada
	if ball_ref.current_state != BallScript.State.PITCHING:
		return

	var ball_pos = ball_ref.ground_pos
	var target_plate_y = 620.0
	var dy = ball_pos.y - target_plate_y
	var dx = ball_pos.x - 640.0 # Desvio lateral do centro do plate

	# A bola viaja a uma velocidade em Y determinada pelo tipo de pitch
	# Estimamos o erro de timing em segundos: quanto tempo a bola está adiantada/atrasada em relação ao ápice do swing
	var pitch_speed_y = (target_plate_y - ball_ref.pitch_start.y) / maxf(ball_ref.pitch_duration, 0.1)
	var time_to_plate = (target_plate_y - ball_pos.y) / pitch_speed_y
	var time_to_sweet_spot = SWEET_SPOT_TIME - swing_timer
	
	# timing_diff: positivo = swing cedo (taco chegou antes da bola), negativo = swing atrasado (bola passou antes)
	var timing_diff = time_to_sweet_spot - time_to_plate

	# Janela de contato válida: distância vertical <= 65px e lateral <= 48px
	if abs(dy) <= 65.0 and abs(dx) <= 48.0:
		has_hit_this_swing = true
		_calculate_hit(dy, dx, timing_diff)
	elif abs(dy) > 75.0 and not missed_reported:
		# Swing muito fora da janela
		pass

func _calculate_hit(dy: float, dx: float, timing_diff: float) -> void:
	var quality = "GOOD"
	var hit_type = "Line Drive"
	var exit_vel = 750.0
	var launch_angle = 22.0
	var dir_deg = 0.0 # 0° = Campo central
	var timing_ms = int(timing_diff * 1000.0)

	var abs_dy = abs(dy)
	var abs_timing = abs(timing_diff)

	# 1. Avaliação do Timing / Qualidade
	if abs_dy <= 14.0 or abs_timing <= 0.034:
		# PERFECT: contato sólido no ponto ideal
		quality = "PERFECT"
		spark_is_perfect = true
		spark_color = Color(1.0, 0.9, 0.2) # Dourado
		exit_vel = randf_range(900.0, 1060.0)
		dir_deg = randf_range(-10.0, 10.0) + (dx * 0.2)
		
		# Tipos de rebatida no Perfect: Line Drive rasante veloz ou Deep Fly Ball com chance de Home Run!
		if randf() < 0.60:
			hit_type = "Line Drive"
			launch_angle = randf_range(16.0, 24.0)
		else:
			hit_type = "Deep Fly Ball"
			launch_angle = randf_range(26.0, 32.0)

	elif abs_dy <= 30.0 or abs_timing <= 0.075:
		# GOOD: bom contato dentro da janela
		quality = "GOOD"
		spark_is_perfect = false
		spark_color = Color(0.3, 0.8, 1.0) # Azul ciano
		exit_vel = randf_range(720.0, 870.0)
		dir_deg = randf_range(-22.0, 22.0) + (dx * 0.3)
		
		var roll = randf()
		if roll < 0.45:
			hit_type = "Line Drive"
			launch_angle = randf_range(17.0, 25.0)
		elif roll < 0.80:
			hit_type = "Fly Ball"
			launch_angle = randf_range(26.0, 36.0)
		else:
			hit_type = "Ground Ball"
			launch_angle = randf_range(8.0, 14.0)

	elif dy < -30.0 or timing_diff > 0.075:
		# EARLY: swing adiantado -> taco puxa a bola para o campo esquerdo (Left field / Pull side)
		quality = "EARLY"
		spark_is_perfect = false
		spark_color = Color(1.0, 0.65, 0.15) # Laranja
		exit_vel = randf_range(560.0, 750.0)
		# Direção puxada para a esquerda
		dir_deg = randf_range(-36.0, -68.0)
		
		var roll = randf()
		if roll < 0.55:
			hit_type = "Ground Ball (Pulled)"
			launch_angle = randf_range(6.0, 16.0)
		elif roll < 0.85:
			hit_type = "Foul Ball (Left)"
			launch_angle = randf_range(12.0, 28.0)
			dir_deg = randf_range(-48.0, -72.0) # Fora da linha de foul
		else:
			hit_type = "Line Drive (Pulled)"
			launch_angle = randf_range(16.0, 24.0)

	else:
		# LATE: swing atrasado -> taco empurra a bola para o campo direito (Right field / Opposite side)
		quality = "LATE"
		spark_is_perfect = false
		spark_color = Color(1.0, 0.55, 0.2) # Âmbar
		exit_vel = randf_range(520.0, 710.0)
		# Direção empurrada para a direita
		dir_deg = randf_range(36.0, 68.0)
		
		var roll = randf()
		if roll < 0.50:
			hit_type = "Fly Ball / Pop-up"
			launch_angle = randf_range(32.0, 52.0)
		elif roll < 0.82:
			hit_type = "Foul Ball (Right)"
			launch_angle = randf_range(18.0, 36.0)
			dir_deg = randf_range(48.0, 72.0) # Fora da linha de foul
		else:
			hit_type = "Ground Ball (Pushed)"
			launch_angle = randf_range(8.0, 16.0)

	# Ponto do impacto visual
	spark_pos = ball_ref.ground_pos - global_position
	spark_timer = 0.25

	# Dispara a bola na física
	ball_ref.launch_hit(exit_vel, launch_angle, dir_deg)
	contact_made.emit(quality, hit_type, exit_vel, launch_angle, dir_deg, timing_ms)

func _draw() -> void:
	# 1. Sombra no chão
	draw_custom_ellipse(Vector2(0, 10), 16.0, 8.0, Color(0.1, 0.15, 0.1, 0.3))

	# 2. Pernas / Calça
	draw_rect(Rect2(-8, -2, 7, 14), COLOR_PANTS)
	draw_rect(Rect2(2, -2, 7, 14), COLOR_PANTS)
	draw_rect(Rect2(-9, 10, 8, 4), Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(2, 10, 8, 4), Color(0.1, 0.1, 0.1))

	# 3. Tronco / Jersey Vermelha
	draw_rect(Rect2(-10, -20, 20, 18), COLOR_JERSEY)
	draw_line(Vector2(0, -20), Vector2(0, -2), Color(0.9, 0.9, 0.9), 2.0)

	# 4. Cabeça com capacete de rebatida (aba voltada para o pitcher)
	draw_circle(Vector2(0, -26), 9.0, COLOR_SKIN)
	draw_circle(Vector2(0, -28), 9.0, COLOR_HELMET)
	draw_rect(Rect2(-3, -33, 10, 5), COLOR_HELMET)

	# 5. Mãos e Taco de Baseball com rotação dinâmica
	var hands_pos = Vector2(4, -14)
	draw_circle(hands_pos, 5.0, COLOR_SKIN)

	# Desenho do taco a partir das mãos com bat_angle
	var bat_len = 38.0
	var bat_dir = Vector2(cos(bat_angle), sin(bat_angle))
	var bat_tip = hands_pos + bat_dir * bat_len
	var handle_end = hands_pos + bat_dir * 12.0

	# Cabo do taco (preto/grip)
	draw_line(hands_pos, handle_end, COLOR_BAT_HANDLE, 4.0)
	# Corpo do taco (madeira mais grossa no barril)
	draw_line(handle_end, bat_tip, COLOR_BAT, 6.0)
	draw_circle(bat_tip, 3.0, COLOR_BAT)

	# 6. Efeito visual de impacto (Flash / Faíscas no contato)
	if spark_timer > 0.0:
		var spark_alpha = clampf(spark_timer / 0.25, 0.0, 1.0)
		var spark_rad = (1.0 - spark_alpha) * (26.0 if spark_is_perfect else 18.0)
		draw_circle(spark_pos, spark_rad * 0.5, Color(1, 1, 1, spark_alpha))
		draw_circle(spark_pos, spark_rad, Color(spark_color.r, spark_color.g, spark_color.b, spark_alpha * 0.6), false, 2.0)
		
		# Linhas radiais de impacto
		var ray_count = 8 if spark_is_perfect else 4
		for i in range(ray_count):
			var a = i * TAU / ray_count + (1.0 - spark_alpha)
			var r1 = spark_rad * 0.4
			var r2 = spark_rad * 1.3
			var p1 = spark_pos + Vector2(cos(a), sin(a)) * r1
			var p2 = spark_pos + Vector2(cos(a), sin(a)) * r2
			draw_line(p1, p2, Color(spark_color.r, spark_color.g, spark_color.b, spark_alpha), 2.0)

func draw_custom_ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(14):
		var a = i * TAU / 14
		points.append(center + Vector2(cos(a) * radius_x, sin(a) * radius_y))
	draw_colored_polygon(points, color)
