class_name Baseball
extends Node2D

signal pitch_crossed_zone(pos: Vector2, height: float, is_in_strike_zone: bool)
signal ball_landed(ground_position: Vector2)
signal ball_stopped(ground_position: Vector2)

enum State {
	IDLE,
	PITCHING,
	HIT,
	GROUND_ROLL,
	STOPPED
}

enum PitchType {
	FASTBALL = 1,
	CURVEBALL = 2,
	CHANGEUP = 3
}

# Propriedades de física 2.5D
@export var ball_radius: float = 7.0
@export var gravity: float = 780.0

var current_state: State = State.IDLE
var ground_pos: Vector2 = Vector2.ZERO
var height: float = 0.0 # Altura visual (eixo Z)
var velocity_ground: Vector2 = Vector2.ZERO
var velocity_z: float = 0.0

# Parâmetros de Arremesso
var pitch_start: Vector2 = Vector2.ZERO
var pitch_target: Vector2 = Vector2.ZERO
var pitch_duration: float = 0.5
var pitch_timer: float = 0.0
var pitch_type: PitchType = PitchType.FASTBALL
var pitch_curve_strength: float = 0.0
var crossed_plate: bool = false

# Limites do campo para reflexão/quique
var bounce_dampening: float = 0.50
var ground_friction: float = 0.94
var bounces_count: int = 0
var max_bounces: int = 4

# Strike zone (definida ao redor de 640, 620)
const STRIKE_ZONE_RECT = Rect2(640 - 28, 620 - 38, 56, 44)

func _ready() -> void:
	reset_to_pos(Vector2(640, 480))

func reset_to_pos(new_pos: Vector2) -> void:
	current_state = State.IDLE
	ground_pos = new_pos
	height = 20.0
	velocity_ground = Vector2.ZERO
	velocity_z = 0.0
	pitch_timer = 0.0
	crossed_plate = false
	bounces_count = 0
	position = ground_pos + Vector2(0, -height)
	queue_redraw()

func start_pitch(start_pos: Vector2, target_pos: Vector2, type: PitchType) -> void:
	current_state = State.PITCHING
	ground_pos = start_pos
	pitch_start = start_pos
	pitch_target = target_pos
	pitch_type = type
	pitch_timer = 0.0
	crossed_plate = false
	height = 24.0 # Altura de lançamento das mãos do pitcher
	
	match pitch_type:
		PitchType.FASTBALL:
			pitch_duration = 0.46 # Rápida, direta
			pitch_curve_strength = 0.0
		PitchType.CURVEBALL:
			pitch_duration = 0.62 # Mais lenta com curva acentuada
			pitch_curve_strength = 48.0
		PitchType.CHANGEUP:
			pitch_duration = 0.72 # Bem mais lenta, quebra o timing
			pitch_curve_strength = -18.0

	position = ground_pos + Vector2(0, -height)
	queue_redraw()

func launch_hit(exit_velocity: float, launch_angle_deg: float, dir_deg: float) -> void:
	current_state = State.HIT
	# Converte ângulo horizontal em vetor no solo (0 graus = para cima/campo central, -45 = esquerda, +45 = direita)
	var rad_dir = deg_to_rad(dir_deg - 90.0) # -90 graus aponta para cima no Godot
	var rad_launch = deg_to_rad(launch_angle_deg)

	# Decomposição da velocidade em plano 2D de solo e componente vertical Z
	var speed_ground = exit_velocity * cos(rad_launch)
	velocity_ground = Vector2(cos(rad_dir), sin(rad_dir)) * speed_ground
	velocity_z = exit_velocity * sin(rad_launch) * 1.15
	bounces_count = 0
	queue_redraw()

func _physics_process(delta: float) -> void:
	match current_state:
		State.PITCHING:
			_process_pitch(delta)
		State.HIT:
			_process_hit(delta)
		State.GROUND_ROLL:
			_process_ground_roll(delta)
		State.IDLE, State.STOPPED:
			pass
	
	# Atualiza a posição visual no Godot (sombra fica no solo, bola sobe no eixo Y)
	position = ground_pos + Vector2(0, -height)
	queue_redraw()

func _process_pitch(delta: float) -> void:
	pitch_timer += delta
	var t = clampf(pitch_timer / pitch_duration, 0.0, 1.0)
	
	# Interpolação linear da trajetória
	var current_p = pitch_start.lerp(pitch_target, t)
	
	# Aplica curva lateral dinâmica de acordo com o tipo de arremesso
	if pitch_curve_strength != 0.0:
		# Efeito curva sinusoidal que se acentua no terço final
		var curve_factor = sin(t * PI) * (0.3 + 0.7 * t)
		current_p.x += pitch_curve_strength * curve_factor

	ground_pos = current_p
	
	# Altura da bola durante o arremesso vai de 24px até ~10px no catcher
	height = lerpf(24.0, 10.0, t)

	# Detecta quando a bola cruza a linha do Home Plate (y >= 580)
	if not crossed_plate and ground_pos.y >= (pitch_target.y - 10.0):
		crossed_plate = true
		var is_strike = STRIKE_ZONE_RECT.has_point(ground_pos)
		pitch_crossed_zone.emit(ground_pos, height, is_strike)

	# Se atingiu o final do trajeto do arremesso (Catcher pegou)
	if t >= 1.0:
		current_state = State.STOPPED
		ball_stopped.emit(ground_pos)

func _process_hit(delta: float) -> void:
	# Movimento no solo
	ground_pos += velocity_ground * delta
	
	# Movimento vertical (gravidade)
	height += velocity_z * delta
	velocity_z -= gravity * delta

	# Verificação de colisão com o solo (queda/quique)
	if height <= 0.0:
		height = 0.0
		bounces_count += 1
		
		# Primeiro impacto no chão emite sinal de pouso
		if bounces_count == 1:
			ball_landed.emit(ground_pos)

		# Quique ou rolamento
		if abs(velocity_z) > 110.0 and bounces_count < max_bounces:
			velocity_z = -velocity_z * bounce_dampening
			velocity_ground *= 0.82
		else:
			# Passa para rolamento no solo
			velocity_z = 0.0
			current_state = State.GROUND_ROLL

func _process_ground_roll(delta: float) -> void:
	ground_pos += velocity_ground * delta
	velocity_ground *= ground_friction
	
	if velocity_ground.length() < 18.0:
		velocity_ground = Vector2.ZERO
		current_state = State.STOPPED
		ball_stopped.emit(ground_pos)

func _draw() -> void:
	# 1. Sombra projetada no chão (abaixo da bola pelo offset da altura)
	var shadow_offset = Vector2(0, height)
	var shadow_scale = clampf(1.0 - (height / 280.0), 0.30, 1.0)
	var shadow_color = Color(0.1, 0.15, 0.1, 0.35 * shadow_scale)
	draw_custom_ellipse(shadow_offset, ball_radius * 1.25 * shadow_scale, ball_radius * 0.65 * shadow_scale, shadow_color)

	# 2. Corpo esférico da bola de beisebol (círculo branco)
	# Leve aumento visual do raio quando a bola está bem alta para sensação de profundidade
	var visual_radius = ball_radius * (1.0 + clampf(height / 350.0, 0.0, 0.4))
	draw_circle(Vector2.ZERO, visual_radius, Color(0.98, 0.98, 0.98))
	draw_circle(Vector2.ZERO, visual_radius, Color(0.25, 0.25, 0.25), false, 1.0)

	# 3. Costuras vermelhas características (red laces)
	var seam_color = Color(0.85, 0.15, 0.15)
	draw_arc(Vector2(-visual_radius * 0.4, 0), visual_radius * 0.6, -PI * 0.6, PI * 0.6, 6, seam_color, 1.2)
	draw_arc(Vector2(visual_radius * 0.4, 0), visual_radius * 0.6, PI * 0.4, PI * 1.6, 6, seam_color, 1.2)

func draw_custom_ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points = PackedVector2Array()
	var num_pts = 16
	for i in range(num_pts):
		var angle = i * TAU / num_pts
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, color)
