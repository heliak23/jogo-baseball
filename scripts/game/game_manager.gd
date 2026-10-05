extends Node2D

const FieldScript = preload("res://scripts/field/field.gd")
const PitcherScript = preload("res://scripts/players/pitcher.gd")
const BatterScript = preload("res://scripts/players/batter.gd")
const CatcherScript = preload("res://scripts/players/catcher.gd")
const BallScript = preload("res://scripts/ball/ball.gd")
const HUDScript = preload("res://scripts/ui/hud.gd")
const BaseManagerScript = preload("res://scripts/game/base_manager.gd")
const DefenseManagerScript = preload("res://scripts/game/defense_manager.gd")
const DisplaySettingsScript = preload("res://scripts/game/display_settings.gd")
const GameCameraScript = preload("res://scripts/game/game_camera.gd")

enum MatchState {
	AT_BAT,
	PITCH,
	BALL_IN_PLAY,
	PLAY_RESULT,
	NEXT_BATTER,
	THREE_OUTS,
	CHANGE_SIDES,
	NEXT_INNING,
	GAME_OVER
}

@export var total_innings: int = 3 # Configurável para 3 ou 9 innings

@export var field: Node2D
@export var pitcher: Node2D
@export var batter: Node2D
@export var catcher: Node2D
@export var ball: Node2D
@export var hud: CanvasLayer
@export var base_manager: Node2D
@export var defense_manager: Node2D
@export var display_settings: Node
@export var game_camera: Camera2D

var current_state: MatchState = MatchState.AT_BAT

# Contadores da partida
var balls_count: int = 0
var strikes_count: int = 0
var outs_count: int = 0
var away_score: int = 0 # Time Visitante (CPU)
var home_score: int = 0 # Time da Casa (PLAYER)
var current_inning: int = 1
var is_top_inning: bool = true # TOP: CPU Ataca / PLAYER Defende; BOT: PLAYER Ataca / CPU Defende

# Controle da jogada atual
var has_swung: bool = false
var has_hit: bool = false
var play_resolved: bool = false
var current_contact_quality: String = ""
var current_hit_type: String = ""
var current_timing_ms: int = 0

# Timers de IA
var cpu_pitch_timer: SceneTreeTimer = null
var cpu_swing_timer: SceneTreeTimer = null

func _ready() -> void:
	_connect_signals()
	start_new_match()

func start_new_match() -> void:
	away_score = 0
	home_score = 0
	current_inning = 1
	is_top_inning = true # Inicia com CPU Atacando e Player Defendendo
	outs_count = 0
	balls_count = 0
	strikes_count = 0
	
	if base_manager:
		base_manager.clear_all_bases()
	if hud:
		hud.hide_game_over()
	if game_camera and game_camera.has_method("reset_camera"):
		game_camera.reset_camera()

	_update_hud()
	set_state(MatchState.AT_BAT)

func set_state(new_state: MatchState) -> void:
	current_state = new_state
	match current_state:
		MatchState.AT_BAT:
			_enter_at_bat()
		MatchState.PITCH:
			pass
		MatchState.BALL_IN_PLAY:
			pass
		MatchState.PLAY_RESULT:
			pass
		MatchState.NEXT_BATTER:
			_enter_next_batter()
		MatchState.THREE_OUTS:
			_enter_three_outs()
		MatchState.CHANGE_SIDES:
			_enter_change_sides()
		MatchState.NEXT_INNING:
			_enter_next_inning()
		MatchState.GAME_OVER:
			_enter_game_over()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			if current_state == MatchState.GAME_OVER:
				start_new_match()
			else:
				reset_pitch_play()
		
		# Controles de Pitch pelo PLAYER (somente quando estiver na DEFESA)
		if is_top_inning and current_state == MatchState.AT_BAT:
			match event.keycode:
				KEY_1:
					if pitcher: pitcher.set_pitch_type(1)
				KEY_2:
					if pitcher: pitcher.set_pitch_type(2)
				KEY_3:
					if pitcher: pitcher.set_pitch_type(3)
				KEY_P:
					_on_hud_pitch_pressed()

		# Controle de Swing pelo PLAYER (somente quando estiver no ATAQUE)
		if not is_top_inning and (current_state == MatchState.PITCH or current_state == MatchState.BALL_IN_PLAY):
			if event.keycode == KEY_SPACE:
				_on_hud_swing_pressed()

func _connect_signals() -> void:
	if pitcher:
		pitcher.pitch_started.connect(_on_pitch_started)
		pitcher.pitch_released.connect(_on_pitch_released)
		pitcher.pitch_type_changed.connect(_on_pitch_type_changed)

	if batter:
		batter.swing_started.connect(_on_batter_swing_started)
		batter.contact_made.connect(_on_batter_contact_made)
		batter.swing_missed.connect(_on_batter_swing_missed)

	if ball:
		ball.pitch_crossed_zone.connect(_on_ball_crossed_zone)
		ball.ball_landed.connect(_on_ball_landed)
		ball.ball_stopped.connect(_on_ball_stopped)

	if hud:
		hud.pitch_button_pressed.connect(_on_hud_pitch_pressed)
		hud.swing_button_pressed.connect(_on_hud_swing_pressed)
		hud.reset_button_pressed.connect(reset_pitch_play)
		hud.pitch_selected.connect(_on_hud_pitch_selected)
		hud.restart_game_pressed.connect(start_new_match)
		hud.display_mode_toggled.connect(_on_display_mode_toggled)

	if display_settings:
		display_settings.display_mode_changed.connect(_on_display_mode_changed)

	if base_manager:
		base_manager.bases_updated.connect(_on_bases_updated)
		base_manager.run_scored.connect(_on_base_run_scored)

	if defense_manager:
		defense_manager.out_recorded.connect(_on_defense_out_recorded)
		defense_manager.safe_recorded.connect(_on_defense_safe_recorded)

func _on_display_mode_toggled() -> void:
	if display_settings:
		display_settings.toggle_fullscreen()

func _on_display_mode_changed(is_full: bool) -> void:
	if hud:
		hud.update_display_mode_button(is_full)

# --- MÁQUINA DE ESTADOS E CONTROLE PLAYER VS CPU ---

func _enter_at_bat() -> void:
	has_swung = false
	has_hit = false
	play_resolved = false
	current_contact_quality = ""
	current_hit_type = ""
	current_timing_ms = 0

	if ball:
		ball.reset_to_pos(Vector2(640, 480))
	if pitcher:
		pitcher.reset_ready()
	if batter:
		batter.reset_stance()
	if defense_manager:
		defense_manager.reset_defense()
	if game_camera and game_camera.has_method("reset_camera"):
		game_camera.reset_camera()

	# Atualiza o indicador de turno no HUD (PLAYER Atacando = true quando not is_top_inning)
	if hud:
		hud.update_turn(not is_top_inning)

	# Se for a CPU defendendo (PLAYER no ATAQUE), a CPU arremessa automaticamente após 1.3s
	if not is_top_inning:
		cpu_pitch_timer = get_tree().create_timer(1.3)
		cpu_pitch_timer.timeout.connect(_on_cpu_auto_pitch)

func _on_cpu_auto_pitch() -> void:
	if current_state != MatchState.AT_BAT or is_top_inning:
		return
	
	# CPU escolhe o pitch de forma variada e arremessa
	var roll = randf()
	var pitch_choice = 1 # Fastball
	if roll < 0.50:
		pitch_choice = 1 # Fastball
	elif roll < 0.80:
		pitch_choice = 2 # Curveball
	else:
		pitch_choice = 3 # Changeup
	
	if pitcher:
		pitcher.set_pitch_type(pitch_choice)
		set_state(MatchState.PITCH)
		pitcher.throw_pitch()

func _on_pitch_released(type: int, start_pos: Vector2, target_pos: Vector2) -> void:
	if ball:
		ball.start_pitch(start_pos, target_pos, type)

	# Se for a CPU no ATAQUE (PLAYER no montinho arremessando), a CPU decide se vai rebater
	if is_top_inning:
		_plan_cpu_swing(type, target_pos)

func _plan_cpu_swing(pitch_type: int, target_pos: Vector2) -> void:
	# Verifica se a bola vai cruzar a strike zone
	var is_in_zone = Baseball.STRIKE_ZONE_RECT.has_point(target_pos)
	
	# Probabilidade da CPU dar swing
	var swing_prob = 0.84 if is_in_zone else 0.26
	if randf() > swing_prob:
		# CPU decidiu deixar passar (esperando Ball ou Called Strike)
		return

	# Tempo estimado do arremesso
	var pitch_duration = 0.46
	if pitch_type == 2: pitch_duration = 0.62
	elif pitch_type == 3: pitch_duration = 0.72

	# Momento ideal do swing do taco: 0.10s antes da bola cruzar o plate
	var ideal_swing_delay = maxf(pitch_duration - 0.10, 0.05)
	
	# Ruído humano na IA da CPU
	var noise = 0.0
	if pitch_type == 1: # Fastball
		noise = randf_range(-0.025, 0.025)
	elif pitch_type == 2: # Curveball
		noise = randf_range(-0.05, 0.05)
	elif pitch_type == 3: # Changeup (tende a adiantar o swing)
		noise = randf_range(0.04, 0.09)

	var actual_delay = maxf(ideal_swing_delay - noise, 0.02)
	cpu_swing_timer = get_tree().create_timer(actual_delay)
	cpu_swing_timer.timeout.connect(func():
		if current_state == MatchState.PITCH and not has_swung and batter:
			batter.start_swing()
	)

func _enter_next_batter() -> void:
	balls_count = 0
	strikes_count = 0
	_update_hud()
	
	var timer = get_tree().create_timer(1.2)
	timer.timeout.connect(func():
		if current_state == MatchState.NEXT_BATTER:
			set_state(MatchState.AT_BAT)
	)

func _enter_three_outs() -> void:
	play_resolved = true
	var team_batting = "CPU (AWAY)" if is_top_inning else "VOCÊ (HOME)"
	hud.show_feedback("3 OUTS!", "Fim do turno de ataque de %s!" % team_batting, Color(0.95, 0.7, 0.15))
	
	var timer = get_tree().create_timer(2.2)
	timer.timeout.connect(func():
		if current_state == MatchState.THREE_OUTS:
			set_state(MatchState.CHANGE_SIDES)
	)

func _enter_change_sides() -> void:
	if base_manager:
		base_manager.clear_all_bases()
	outs_count = 0
	balls_count = 0
	strikes_count = 0

	if is_top_inning:
		# Concluiu o TOP: passa para o BOTTOM do mesmo inning (PLAYER vem ao bastão!)
		is_top_inning = false
		hud.show_feedback("TROCA DE LADOS!", "Fim do TOP! SUA VEZ NO BASTÃO (ATAQUE)!", Color(1.0, 0.9, 0.25))
		_update_hud()
		
		var timer = get_tree().create_timer(2.4)
		timer.timeout.connect(func():
			if current_state == MatchState.CHANGE_SIDES:
				set_state(MatchState.AT_BAT)
		)
	else:
		# Concluiu o BOTTOM: passa para o próximo inning
		set_state(MatchState.NEXT_INNING)

func _enter_next_inning() -> void:
	current_inning += 1
	is_top_inning = true

	if current_inning > total_innings:
		set_state(MatchState.GAME_OVER)
	else:
		hud.show_feedback("INNING %d!" % current_inning, "Início do %dº Inning! CPU vem ao bastão!" % current_inning, Color(0.2, 0.95, 0.35))
		_update_hud()
		
		var timer = get_tree().create_timer(2.4)
		timer.timeout.connect(func():
			if current_state == MatchState.NEXT_INNING:
				set_state(MatchState.AT_BAT)
		)

func _enter_game_over() -> void:
	play_resolved = true
	var winner_text = ""
	if away_score > home_score:
		winner_text = "CPU (AWAY) VENCEU A PARTIDA!"
	elif home_score > away_score:
		winner_text = "VOCÊ (HOME) VENCEU A PARTIDA! PARABÉNS! 🏆"
	else:
		winner_text = "PARTIDA EMPATADA!"

	var final_score_text = "Placar Final: CPU %d  -  VOCÊ %d" % [away_score, home_score]
	hud.show_game_over(winner_text, final_score_text)
	hud.show_feedback("FIM DE PARTIDA!", winner_text, Color(1.0, 0.85, 0.2))

# --- DISPARO DE AÇÕES PELO PLAYER ---

func _on_hud_pitch_pressed() -> void:
	# O Player só arremessa quando estiver na DEFESA (TOP)
	if is_top_inning and current_state == MatchState.AT_BAT and pitcher:
		set_state(MatchState.PITCH)
		pitcher.throw_pitch()

func _on_hud_swing_pressed() -> void:
	# O Player só rebate quando estiver no ATAQUE (BOT)
	if not is_top_inning and batter and (current_state == MatchState.PITCH or current_state == MatchState.BALL_IN_PLAY):
		batter.start_swing()

func _on_hud_pitch_selected(type: int) -> void:
	if is_top_inning and pitcher and current_state == MatchState.AT_BAT:
		pitcher.set_pitch_type(type)

func _on_pitch_type_changed(type: int) -> void:
	if hud:
		hud.update_pitch_selection(type)

func _on_pitch_started(_type: int) -> void:
	set_state(MatchState.PITCH)
	has_swung = false
	has_hit = false
	play_resolved = false

func _on_batter_swing_started() -> void:
	has_swung = true

func _on_batter_contact_made(quality: String, hit_type: String, _exit_vel: float, _launch_angle: float, _dir_deg: float, timing_ms: int) -> void:
	has_hit = true
	set_state(MatchState.BALL_IN_PLAY)
	current_contact_quality = quality
	current_hit_type = hit_type
	current_timing_ms = timing_ms

	var timing_text = ""
	if abs(timing_ms) <= 15:
		timing_text = "Timing: %dms [No Ponto Exato!]" % timing_ms
	elif timing_ms > 0:
		timing_text = "Timing: +%dms [Swing Cedo]" % timing_ms
	else:
		timing_text = "Timing: %dms [Swing Atrasado]" % timing_ms

	var color = Color(1.0, 0.88, 0.15)
	if quality == "GOOD":
		color = Color(0.25, 0.8, 1.0)
	elif quality == "EARLY":
		color = Color(1.0, 0.62, 0.15)
	elif quality == "LATE":
		color = Color(1.0, 0.45, 0.2)

	hud.show_feedback("%s CONTACT!" % quality, hit_type, color, timing_text)

	if defense_manager:
		defense_manager.on_ball_hit(ball)
	if game_camera and game_camera.has_method("follow_play"):
		game_camera.follow_play(ball)

func _on_batter_swing_missed(_reason: String = "SWING & MISS") -> void:
	if not has_hit and not play_resolved:
		_register_strike("MISS! STRIKE!", "Swing sem contato no vazio", Color(0.95, 0.25, 0.25))

func _on_ball_crossed_zone(_pos: Vector2, _height: float, is_in_strike_zone: bool) -> void:
	if has_hit:
		return

	if not has_swung and not play_resolved:
		if is_in_strike_zone:
			if catcher:
				catcher.catch_ball(true)
			_register_strike("CALLED STRIKE!", "Bola na Strike Zone sem swing!", Color(0.95, 0.3, 0.3))
		else:
			if catcher:
				catcher.catch_ball(false)
			_register_ball()

func _on_ball_landed(ground_position: Vector2) -> void:
	if play_resolved:
		return

	var is_fair = field.is_fair_ball(ground_position) if field else true
	var is_hr = field.is_home_run(ground_position) if field else false

	if is_hr:
		_register_home_run()
	elif not is_fair:
		_register_foul_ball()

func _on_ball_stopped(ground_position: Vector2) -> void:
	if not play_resolved:
		if current_state == MatchState.PITCH and not has_swung:
			_register_strike("PITCH COMPLETE", "Sem swing")
		elif current_state == MatchState.BALL_IN_PLAY:
			var is_fair = field.is_fair_ball(ground_position) if field else true
			if is_fair:
				_register_fair_hit(ground_position)
			else:
				_register_foul_ball()

func _on_defense_out_recorded(reason: String, fielder_name: String) -> void:
	if play_resolved:
		return
	_register_out("%s!" % reason, "Eliminação por %s" % fielder_name)

func _on_defense_safe_recorded(hit_name: String) -> void:
	if play_resolved:
		return
	_register_fair_hit(ball.ground_pos, hit_name)

# --- REGRAS DO BASEBALL ---

func _register_strike(title: String, subtitle: String, color: Color = Color(0.95, 0.25, 0.25)) -> void:
	play_resolved = true
	set_state(MatchState.PLAY_RESULT)
	strikes_count += 1
	hud.show_feedback(title, subtitle, color)

	if strikes_count >= 3:
		_register_out("STRIKEOUT!", "3 Strikes - Batedor eliminado!")
	else:
		_update_hud()
		_schedule_auto_at_bat(1.6)

func _register_ball() -> void:
	play_resolved = true
	set_state(MatchState.PLAY_RESULT)
	balls_count += 1
	hud.show_feedback("BALL!", "Fora da Strike Zone", Color(0.25, 0.85, 0.95))

	if balls_count >= 4:
		hud.show_feedback("WALK! (Base on Balls)", "4 Balls - Batedor avança para 1B!", Color(0.3, 0.95, 0.4))
		if batter:
			batter.become_runner()
		if base_manager:
			base_manager.process_hit("WALK")
		_update_hud()
		set_state(MatchState.NEXT_BATTER)
	else:
		_update_hud()
		_schedule_auto_at_bat(1.6)

func _register_foul_ball() -> void:
	play_resolved = true
	set_state(MatchState.PLAY_RESULT)
	if strikes_count < 2:
		strikes_count += 1
		hud.show_feedback("FOUL BALL!", "Bola fora das linhas - Strike adicionado", Color(0.95, 0.8, 0.2))
	else:
		hud.show_feedback("FOUL BALL!", "Bola fora - Contagem permanece em 2 strikes", Color(0.95, 0.8, 0.2))
	
	_update_hud()
	_schedule_auto_at_bat(1.8)

func _register_fair_hit(pos: Vector2, forced_hit_name: String = "") -> void:
	play_resolved = true
	set_state(MatchState.PLAY_RESULT)

	var hit_name = forced_hit_name
	if hit_name == "":
		var dist = pos.distance_to(Vector2(640, 620))
		hit_name = "SINGLE!"
		if dist > 340.0:
			hit_name = "TRIPLE!"
		elif dist > 230.0:
			hit_name = "DOUBLE!"
	
	var sub = "Rebatida válida em campo! (%s)" % current_hit_type if current_hit_type != "" else "Rebatida válida em campo!"
	hud.show_feedback("BASE HIT! %s" % hit_name, sub, Color(0.2, 0.95, 0.35))
	
	if batter:
		batter.become_runner()

	if base_manager:
		base_manager.process_hit(hit_name)

	_update_hud()
	
	var timer = get_tree().create_timer(2.4)
	timer.timeout.connect(func():
		if current_state == MatchState.PLAY_RESULT:
			set_state(MatchState.NEXT_BATTER)
	)

func _register_home_run() -> void:
	play_resolved = true
	set_state(MatchState.PLAY_RESULT)
	hud.show_feedback("HOME RUN!!!", "A BOLA FOI PARA O OUTRO LADO DO MURO!", Color(1.0, 0.85, 0.1))

	if batter:
		batter.become_runner()

	if base_manager:
		base_manager.process_hit("HOME RUN")

	_update_hud()
	
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(func():
		if current_state == MatchState.PLAY_RESULT:
			set_state(MatchState.NEXT_BATTER)
	)

func _register_out(title: String, subtitle: String) -> void:
	play_resolved = true
	set_state(MatchState.PLAY_RESULT)
	outs_count += 1
	hud.show_feedback(title, subtitle, Color(0.95, 0.2, 0.2))
	_update_hud()

	if outs_count >= 3:
		var timer = get_tree().create_timer(1.8)
		timer.timeout.connect(func():
			if current_state == MatchState.PLAY_RESULT:
				set_state(MatchState.THREE_OUTS)
		)
	else:
		var timer = get_tree().create_timer(1.8)
		timer.timeout.connect(func():
			if current_state == MatchState.PLAY_RESULT:
				set_state(MatchState.NEXT_BATTER)
		)

func _on_bases_updated(has_1b: bool, has_2b: bool, has_3b: bool) -> void:
	if hud:
		hud.update_bases(has_1b, has_2b, has_3b)

func _on_base_run_scored() -> void:
	if is_top_inning:
		away_score += 1
	else:
		home_score += 1
	_update_hud()
	if hud:
		hud.show_feedback("RUN SCORED! 🏆", "Corredor cruzou o Home Plate e marcou corrida!", Color(0.2, 0.95, 0.4))

func reset_pitch_play() -> void:
	if current_state == MatchState.GAME_OVER:
		return
	set_state(MatchState.AT_BAT)

func _schedule_auto_at_bat(delay: float) -> void:
	var timer = get_tree().create_timer(delay)
	timer.timeout.connect(func():
		if current_state == MatchState.PLAY_RESULT:
			set_state(MatchState.AT_BAT)
	)

func _update_hud() -> void:
	if hud:
		hud.update_count(balls_count, strikes_count, outs_count)
		hud.update_score(away_score, home_score, current_inning, is_top_inning, total_innings)
