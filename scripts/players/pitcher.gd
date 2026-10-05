class_name Pitcher
extends Node2D

signal pitch_started(pitch_type: int)
signal pitch_released(pitch_type: int, start_pos: Vector2, target_pos: Vector2)
signal pitch_type_changed(pitch_type: int)

enum PitchType {
	FASTBALL = 1,
	CURVEBALL = 2,
	CHANGEUP = 3
}

enum State {
	READY,
	WINDUP,
	RELEASE,
	COOLDOWN
}

@export var selected_pitch: PitchType = PitchType.FASTBALL
@export var mound_position: Vector2 = Vector2(640, 480)
@export var target_plate_position: Vector2 = Vector2(640, 620)

var current_state: State = State.READY
var anim_timer: float = 0.0
var arm_angle: float = 0.0

# Cores do uniforme
const COLOR_JERSEY = Color(0.18, 0.38, 0.72) # Azul do time
const COLOR_PANTS = Color(0.92, 0.92, 0.92)  # Branco
const COLOR_CAP = Color(0.12, 0.25, 0.55)
const COLOR_SKIN = Color(0.94, 0.76, 0.62)
const COLOR_GLOVE = Color(0.48, 0.28, 0.15)

func _ready() -> void:
	position = mound_position

func _unhandled_input(event: InputEvent) -> void:
	if current_state != State.READY:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				set_pitch_type(PitchType.FASTBALL)
			KEY_2:
				set_pitch_type(PitchType.CURVEBALL)
			KEY_3:
				set_pitch_type(PitchType.CHANGEUP)
			KEY_P:
				throw_pitch()

func set_pitch_type(type: PitchType) -> void:
	selected_pitch = type
	pitch_type_changed.emit(int(selected_pitch))
	queue_redraw()

func throw_pitch() -> void:
	if current_state != State.READY:
		return
	current_state = State.WINDUP
	anim_timer = 0.0
	pitch_started.emit(int(selected_pitch))

func reset_ready() -> void:
	current_state = State.READY
	anim_timer = 0.0
	arm_angle = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	match current_state:
		State.WINDUP:
			anim_timer += delta
			arm_angle = lerpf(0.0, -PI * 0.75, anim_timer / 0.25)
			if anim_timer >= 0.25:
				current_state = State.RELEASE
				anim_timer = 0.0
			queue_redraw()

		State.RELEASE:
			anim_timer += delta
			arm_angle = lerpf(-PI * 0.75, PI * 0.5, anim_timer / 0.12)
			if anim_timer >= 0.06 and arm_angle >= 0.0:
				# Ponto de soltura da bola
				pass
			if anim_timer >= 0.12:
				# Dispara a bola
				var release_pos = global_position + Vector2(10, 10)
				# Variação leve no alvo para naturalidade
				var variance = Vector2(randf_range(-14, 14), randf_range(-8, 8))
				pitch_released.emit(int(selected_pitch), release_pos, target_plate_position + variance)
				current_state = State.COOLDOWN
				anim_timer = 0.0
			queue_redraw()

		State.COOLDOWN:
			anim_timer += delta
			arm_angle = lerpf(PI * 0.5, 0.0, anim_timer / 0.3)
			if anim_timer >= 0.3:
				arm_angle = 0.0
			queue_redraw()

func _draw() -> void:
	# 1. Sombra no chão
	draw_custom_ellipse(Vector2(0, 10), 18.0, 8.0, Color(0.1, 0.15, 0.1, 0.3))

	# 2. Pernas / Calça
	draw_rect(Rect2(-8, -2, 7, 14), COLOR_PANTS)
	draw_rect(Rect2(1, -2, 7, 14), COLOR_PANTS)
	# Chuteiras
	draw_rect(Rect2(-9, 10, 8, 4), Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(1, 10, 8, 4), Color(0.1, 0.1, 0.1))

	# 3. Tronco / Jersey
	draw_rect(Rect2(-11, -20, 22, 18), COLOR_JERSEY)
	# Faixa central da camisa
	draw_line(Vector2(0, -20), Vector2(0, -2), Color(0.9, 0.9, 0.9), 2.0)

	# 4. Braço esquerdo (com a luva para frente)
	draw_line(Vector2(-10, -16), Vector2(-16, -6), COLOR_JERSEY, 5.0)
	draw_circle(Vector2(-16, -6), 6.0, COLOR_GLOVE)

	# 5. Cabeça e Boné
	draw_circle(Vector2(0, -26), 9.0, COLOR_SKIN)
	# Boné com aba para frente (para baixo na tela)
	draw_circle(Vector2(0, -28), 9.0, COLOR_CAP)
	draw_rect(Rect2(-7, -23, 14, 4), COLOR_CAP)

	# 6. Braço direito de arremesso (rotaciona durante o pitch)
	var shoulder = Vector2(10, -16)
	var arm_length = 16.0
	var hand_pos = shoulder + Vector2(sin(arm_angle), cos(arm_angle)) * arm_length
	draw_line(shoulder, hand_pos, COLOR_SKIN, 5.0)
	draw_circle(hand_pos, 4.0, COLOR_SKIN)

	# Se estiver pronto para arremessar e com a bola na mão, desenha a bola na mão
	if current_state == State.READY or (current_state == State.WINDUP and anim_timer < 0.2):
		draw_circle(hand_pos, 5.0, Color.WHITE)

func draw_custom_ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(14):
		var a = i * TAU / 14
		points.append(center + Vector2(cos(a) * radius_x, sin(a) * radius_y))
	draw_colored_polygon(points, color)
