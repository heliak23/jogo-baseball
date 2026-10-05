class_name DefenseManager
extends Node2D

signal out_recorded(reason: String, fielder_name: String)
signal safe_recorded(hit_name: String)

const FIRST_BASE_POS = Vector2(780, 490)
const SECOND_BASE_POS = Vector2(640, 360)
const THIRD_BASE_POS = Vector2(500, 490)
const HOME_PLATE_POS = Vector2(640, 620)

const FielderScript = preload("res://scripts/players/fielder.gd")

@export var ball_ref: Node2D
@export var pitcher_ref: Node2D
@export var catcher_ref: Node2D

var fielders: Array[Node2D] = []
var active_fielder: Node2D = null
var is_defense_active: bool = false
var ball_caught: bool = false
var ball_fielded: bool = false
var throw_in_progress: bool = false
var throw_start_pos: Vector2 = Vector2.ZERO
var throw_target_pos: Vector2 = Vector2.ZERO
var throw_timer: float = 0.0
var throw_duration: float = 0.40

# Tempo decorrido desde o contato para comparar com a velocidade do corredor até 1B
var time_since_hit: float = 0.0
const RUNNER_TIME_TO_FIRST = 0.88 # Tempo em segundos que o corredor leva para chegar à 1B

func _ready() -> void:
	_collect_fielders()
	reset_defense()

func _collect_fielders() -> void:
	fielders.clear()
	for child in get_children():
		if child is FielderScript or child.has_method("chase_ball"):
			fielders.append(child)
			child.ball_caught_air.connect(_on_fielder_caught_air)
			child.ball_fielded_ground.connect(_on_fielder_fielded_ground)
			child.throw_completed.connect(_on_throw_completed)

func reset_defense() -> void:
	is_defense_active = false
	active_fielder = null
	ball_caught = false
	ball_fielded = false
	throw_in_progress = false
	time_since_hit = 0.0
	
	for f in fielders:
		f.reset_position()

func on_ball_hit(ball: Node2D) -> void:
	ball_ref = ball
	is_defense_active = true
	ball_caught = false
	ball_fielded = false
	throw_in_progress = false
	time_since_hit = 0.0

	# 1. Identifica o defensor mais adequado
	# Estima o ponto de interceptação projetando a velocidade da bola
	var target_spot = ball.ground_pos + (ball.velocity_ground * 0.45)
	active_fielder = _find_best_fielder(target_spot)

	if active_fielder:
		active_fielder.chase_ball(target_spot)

func _find_best_fielder(target_pos: Vector2) -> Node2D:
	var best_fielder: Node2D = null
	var min_dist: float = 999999.0

	for f in fielders:
		var d = f.position.distance_to(target_pos)
		if d < min_dist:
			min_dist = d
			best_fielder = f

	return best_fielder

func _physics_process(delta: float) -> void:
	if not is_defense_active or not is_instance_valid(ball_ref):
		return

	time_since_hit += delta

	# Processa arremesso da bola do defensor para a 1ª base
	if throw_in_progress:
		_process_throw(delta)
		return

	if ball_caught or ball_fielded:
		return

	# Só atua se a bola estiver em jogo (HIT ou GROUND_ROLL)
	if ball_ref.current_state != 2 and ball_ref.current_state != 3: # HIT or GROUND_ROLL
		return

	# Atualiza a perseguição do defensor em direção à posição atual da bola
	if active_fielder:
		active_fielder.chase_ball(ball_ref.ground_pos)

		var dist_to_ball = active_fielder.position.distance_to(ball_ref.ground_pos)

		# 2. Tentativa de Catch no Ar (Fly Out)
		if ball_ref.current_state == 2 and ball_ref.height > 0.0: # HIT no ar
			if dist_to_ball <= 36.0 and ball_ref.height <= 55.0:
				_execute_fly_catch()
				return

		# 3. Pegar bola no chão (Fielding Grounder)
		if ball_ref.height <= 6.0:
			if dist_to_ball <= 30.0:
				_execute_ground_fielding()
				return

func _execute_fly_catch() -> void:
	ball_caught = true
	is_defense_active = false
	active_fielder.catch_air()
	
	# Prende a bola na luva do defensor
	ball_ref.current_state = 4 # STOPPED
	ball_ref.velocity_ground = Vector2.ZERO
	ball_ref.velocity_z = 0.0
	ball_ref.height = 16.0
	ball_ref.ground_pos = active_fielder.position
	
	out_recorded.emit("FLY OUT", active_fielder.fielder_name)

func _execute_ground_fielding() -> void:
	ball_fielded = true
	active_fielder.field_ground()
	
	# Bola para nas mãos do defensor
	ball_ref.current_state = 4 # STOPPED
	ball_ref.velocity_ground = Vector2.ZERO
	ball_ref.velocity_z = 0.0
	ball_ref.height = 10.0
	ball_ref.ground_pos = active_fielder.position

	# Defensor lança para a 1ª Base para eliminar o rebatedor
	active_fielder.throw_to(FIRST_BASE_POS)

func _on_fielder_caught_air(_f: Node2D) -> void:
	pass

func _on_fielder_fielded_ground(_f: Node2D) -> void:
	pass

func _on_throw_completed(target_pos: Vector2) -> void:
	# Inicia o voo do lançamento até a base
	throw_in_progress = true
	throw_start_pos = active_fielder.position
	throw_target_pos = target_pos
	throw_timer = 0.0
	
	# Duração baseada na distância do lançamento
	var dist = throw_start_pos.distance_to(throw_target_pos)
	throw_duration = clampf(dist / 680.0, 0.22, 0.55)

func _process_throw(delta: float) -> void:
	throw_timer += delta
	var t = clampf(throw_timer / throw_duration, 0.0, 1.0)
	
	# Trajetória do lançamento
	ball_ref.ground_pos = throw_start_pos.lerp(throw_target_pos, t)
	ball_ref.height = sin(t * PI) * 28.0 # Pequeno arco no lançamento
	ball_ref.position = ball_ref.ground_pos + Vector2(0, -ball_ref.height)
	ball_ref.queue_redraw()

	if t >= 1.0:
		throw_in_progress = false
		is_defense_active = false
		ball_ref.height = 0.0

		# 4. Avalia se o lançamento chegou antes do corredor na 1ª base
		var total_time = time_since_hit
		if total_time <= RUNNER_TIME_TO_FIRST:
			# OUT na 1B!
			out_recorded.emit("GROUND OUT", active_fielder.fielder_name)
		else:
			# SAFE na 1B! Corredor foi mais rápido
			safe_recorded.emit("SINGLE")
