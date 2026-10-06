class_name Pitcher
extends Node2D

signal pitch_started(pitch_type: int)
signal pitch_released(pitch_type: int, start_pos: Vector2, target_pos: Vector2, speed: float)
signal pitch_type_changed(pitch_type: int)
signal charge_updated(power: float)

enum PitchType {
	FASTBALL = 1,
	CURVEBALL = 2,
	CHANGEUP = 3
}

enum State {
	READY,
	CHARGING,
	WINDUP,
	RELEASE,
	COOLDOWN
}

@export_group("Pitching Speeds & Charge")
## Tempo máximo em segundos para atingir 100% de força no arremesso
@export_range(0.5, 3.0, 0.1) var max_charge_time: float = 1.2

@export_subgroup("Fastball Speeds (px/s)")
## Velocidade mínima da Fastball (ao dar apenas um toque rápido)
@export var fastball_speed_min: float = 270.0
## Velocidade máxima da Fastball (ao segurar até a carga máxima)
@export var fastball_speed_max: float = 400.0

@export_subgroup("Curveball Speeds (px/s)")
## Velocidade mínima da Curveball (ao dar apenas um toque rápido)
@export var curveball_speed_min: float = 200.0
## Velocidade máxima da Curveball (ao segurar até a carga máxima)
@export var curveball_speed_max: float = 290.0

@export_subgroup("Changeup Speeds (px/s)")
## Velocidade mínima do Changeup (ao dar apenas um toque rápido)
@export var changeup_speed_min: float = 140.0
## Velocidade máxima do Changeup (ao segurar até a carga máxima)
@export var changeup_speed_max: float = 210.0

@export_group("Positions")
@export var selected_pitch: PitchType = PitchType.FASTBALL
@export var mound_position: Vector2 = Vector2(640, 480)
@export var target_plate_position: Vector2 = Vector2(640, 620)
@export var is_player_controlled: bool = true

var current_state: State = State.READY
var anim_timer: float = 0.0
var arm_angle: float = 0.0
var charge_timer: float = 0.0
var current_charge_power: float = 0.0
var cached_release_speed: float = 0.0

# Cores do uniforme
const COLOR_JERSEY = Color(0.18, 0.38, 0.72) # Azul do time
const COLOR_PANTS = Color(0.92, 0.92, 0.92)  # Branco
const COLOR_CAP = Color(0.12, 0.25, 0.55)
const COLOR_SKIN = Color(0.94, 0.76, 0.62)
const COLOR_GLOVE = Color(0.48, 0.28, 0.15)

func _ready() -> void:
	position = mound_position

func _unhandled_input(event: InputEvent) -> void:
	if not is_player_controlled:
		return

	# 1. Seleção do Tipo de Arremesso (Teclas 1, 2, 3)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				set_pitch_type(PitchType.FASTBALL)
			KEY_2:
				set_pitch_type(PitchType.CURVEBALL)
			KEY_3:
				set_pitch_type(PitchType.CHANGEUP)

	# 2. Mecânica de Força Hold to Pitch (Tecla P)
	if event is InputEventKey and event.keycode == KEY_P:
		if event.pressed and not event.echo:
			if current_state == State.READY:
				start_charging()
		elif not event.pressed:
			# just_released: solta o botão P para disparar o arremesso
			if current_state == State.CHARGING:
				release_pitch()

func set_pitch_type(type: PitchType) -> void:
	selected_pitch = type
	pitch_type_changed.emit(int(selected_pitch))
	queue_redraw()

func get_speed_for_pitch(type: PitchType, power: float) -> float:
	match type:
		PitchType.FASTBALL:
			return lerpf(fastball_speed_min, fastball_speed_max, power)
		PitchType.CURVEBALL:
			return lerpf(curveball_speed_min, curveball_speed_max, power)
		PitchType.CHANGEUP:
			return lerpf(changeup_speed_min, changeup_speed_max, power)
		_:
			return lerpf(fastball_speed_min, fastball_speed_max, power)

func start_charging() -> void:
	if current_state != State.READY:
		return
	current_state = State.CHARGING
	charge_timer = 0.0
	current_charge_power = 0.0
	pitch_started.emit(int(selected_pitch))
	charge_updated.emit(0.0)
	queue_redraw()

func release_pitch() -> void:
	if current_state != State.CHARGING:
		return
	current_charge_power = clampf(charge_timer / max_charge_time, 0.0, 1.0)
	cached_release_speed = get_speed_for_pitch(selected_pitch, current_charge_power)
	current_state = State.RELEASE
	anim_timer = 0.0
	queue_redraw()

func throw_pitch() -> void:
	# Disparo direto (compatibilidade)
	if current_state != State.READY:
		return
	start_charging()
	release_pitch()

func start_pitch(type: int = 1) -> void:
	# Método compatível com testes automatizados
	set_pitch_type(type as PitchType)
	throw_pitch()

func reset_ready() -> void:
	current_state = State.READY
	anim_timer = 0.0
	arm_angle = 0.0
	charge_timer = 0.0
	current_charge_power = 0.0
	cached_release_speed = 0.0
	charge_updated.emit(0.0)
	queue_redraw()

func _process(delta: float) -> void:
	match current_state:
		State.CHARGING:
			charge_timer += delta
			current_charge_power = clampf(charge_timer / max_charge_time, 0.0, 1.0)
			charge_updated.emit(current_charge_power)
			
			# O braço recua para trás preparando o lançamento de acordo com a força
			arm_angle = lerpf(0.0, -PI * 0.75, current_charge_power)
			
			# Efeito de tremor sutil quando atinge carga máxima (100%)
			if current_charge_power >= 1.0:
				arm_angle += sin(charge_timer * 35.0) * 0.04
			
			queue_redraw()

		State.WINDUP:
			# Compatibilidade se entrar em WINDUP direto
			anim_timer += delta
			arm_angle = lerpf(0.0, -PI * 0.75, anim_timer / 0.25)
			if anim_timer >= 0.25:
				current_charge_power = 0.5
				cached_release_speed = get_speed_for_pitch(selected_pitch, current_charge_power)
				current_state = State.RELEASE
				anim_timer = 0.0
			queue_redraw()

		State.RELEASE:
			anim_timer += delta
			# Rotação veloz do braço para a frente
			arm_angle = lerpf(-PI * 0.75, PI * 0.5, anim_timer / 0.10)
			
			if anim_timer >= 0.10:
				var release_pos = global_position + Vector2(10, 10)
				# Variação leve no alvo para naturalidade
				var variance = Vector2(randf_range(-14, 14), randf_range(-8, 8))
				if cached_release_speed <= 0.0:
					cached_release_speed = get_speed_for_pitch(selected_pitch, 0.5)
				pitch_released.emit(int(selected_pitch), release_pos, target_plate_position + variance, cached_release_speed)
				current_state = State.COOLDOWN
				anim_timer = 0.0
			queue_redraw()

		State.COOLDOWN:
			anim_timer += delta
			arm_angle = lerpf(PI * 0.5, 0.0, anim_timer / 0.25)
			if anim_timer >= 0.25:
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

	# Se estiver pronto para arremessar ou carregando, desenha a bola na mão
	if current_state == State.READY or current_state == State.CHARGING or (current_state == State.WINDUP and anim_timer < 0.2):
		draw_circle(hand_pos, 5.0, Color.WHITE)

	# 7. Barra visual de Força (Charge Meter) sobre a cabeça do Pitcher
	if current_state == State.CHARGING:
		_draw_charge_meter()

func _draw_charge_meter() -> void:
	var bar_width = 38.0
	var bar_height = 6.0
	var bar_pos = Vector2(-bar_width * 0.5, -44.0)

	# Fundo da barra
	draw_rect(Rect2(bar_pos.x - 1, bar_pos.y - 1, bar_width + 2, bar_height + 2), Color(0.08, 0.1, 0.14, 0.85))
	draw_rect(Rect2(bar_pos.x, bar_pos.y, bar_width, bar_height), Color(0.2, 0.25, 0.3, 0.7))

	# Cor gradiente de acordo com o nível de carga
	var fill_width = bar_width * current_charge_power
	var bar_color: Color
	if current_charge_power < 0.5:
		bar_color = Color(0.2, 0.85, 0.45).lerp(Color(0.95, 0.85, 0.2), current_charge_power * 2.0)
	else:
		bar_color = Color(0.95, 0.85, 0.2).lerp(Color(1.0, 0.25, 0.2), (current_charge_power - 0.5) * 2.0)

	if fill_width > 0.0:
		draw_rect(Rect2(bar_pos.x, bar_pos.y, fill_width, bar_height), bar_color)

	# Borda / Realce quando 100% de carga atingida
	if current_charge_power >= 1.0:
		var pulse = (sin(charge_timer * 20.0) + 1.0) * 0.5
		var glow_color = Color(1.0, 0.9, 0.3, 0.6 + pulse * 0.4)
		draw_rect(Rect2(bar_pos.x - 2, bar_pos.y - 2, bar_width + 4, bar_height + 4), glow_color, false, 1.5)

func draw_custom_ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(14):
		var a = i * TAU / 14
		points.append(center + Vector2(cos(a) * radius_x, sin(a) * radius_y))
	draw_colored_polygon(points, color)

