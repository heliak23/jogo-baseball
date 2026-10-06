class_name BaseballHUD
extends CanvasLayer

signal pitch_button_pressed()
signal pitch_button_down()
signal pitch_button_up()
signal swing_button_pressed()
signal reset_button_pressed()
signal pitch_selected(type: int)
signal restart_game_pressed()
signal display_mode_toggled()

@onready var label_balls: Label = $TopBar/CountPanel/HBox/BallsLabel
@onready var label_strikes: Label = $TopBar/CountPanel/HBox/StrikesLabel
@onready var label_outs: Label = $TopBar/CountPanel/HBox/OutsLabel
@onready var label_score: Label = $TopBar/ScorePanel/ScoreLabel
@onready var feedback_panel: PanelContainer = $FeedbackPanel
@onready var feedback_title: Label = $FeedbackPanel/VBox/TitleLabel
@onready var feedback_subtitle: Label = $FeedbackPanel/VBox/SubtitleLabel
@onready var feedback_timing: Label = $FeedbackPanel/VBox/TimingLabel

@onready var label_base1: Label = $TopBar/BasesPanel/HBox/Base1Label
@onready var label_base2: Label = $TopBar/BasesPanel/HBox/Base2Label
@onready var label_base3: Label = $TopBar/BasesPanel/HBox/Base3Label

@onready var btn_display_mode: Button = $TopBar/DisplayPanel/BtnDisplayMode
@onready var turn_label: Label = $TurnBanner/TurnLabel

@onready var btn_fastball: Button = $PitchControls/VBox/HBox/BtnFastball
@onready var btn_curveball: Button = $PitchControls/VBox/HBox/BtnCurveball
@onready var btn_changeup: Button = $PitchControls/VBox/HBox/BtnChangeup
@onready var btn_pitch: Button = $ActionButtons/BtnPitch
@onready var btn_swing: Button = $ActionButtons/BtnSwing
@onready var btn_reset: Button = $ActionButtons/BtnReset

@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var winner_label: Label = $GameOverPanel/VBox/WinnerLabel
@onready var final_score_label: Label = $GameOverPanel/VBox/FinalScoreLabel
@onready var btn_restart: Button = $GameOverPanel/VBox/BtnRestart

var feedback_tween: Tween

func _ready() -> void:
	_setup_button_signals()
	feedback_panel.modulate.a = 0.0
	if game_over_panel:
		game_over_panel.visible = false
	update_count(0, 0, 0)
	update_score(0, 0, 1, true, 3)
	update_pitch_selection(1)
	update_bases(false, false, false)
	update_turn(false) # Inicia em DEFESA (TOP 1)

func _setup_button_signals() -> void:
	if btn_fastball:
		btn_fastball.pressed.connect(func(): pitch_selected.emit(1))
	if btn_curveball:
		btn_curveball.pressed.connect(func(): pitch_selected.emit(2))
	if btn_changeup:
		btn_changeup.pressed.connect(func(): pitch_selected.emit(3))
	if btn_pitch:
		btn_pitch.pressed.connect(func(): pitch_button_pressed.emit())
		btn_pitch.button_down.connect(func(): pitch_button_down.emit())
		btn_pitch.button_up.connect(func(): pitch_button_up.emit())
	if btn_swing:
		btn_swing.pressed.connect(func(): swing_button_pressed.emit())
	if btn_reset:
		btn_reset.pressed.connect(func(): reset_button_pressed.emit())
	if btn_restart:
		btn_restart.pressed.connect(func(): restart_game_pressed.emit())
	if btn_display_mode:
		btn_display_mode.pressed.connect(func(): display_mode_toggled.emit())

func update_turn(is_player_batting: bool) -> void:
	if not turn_label:
		return
	if is_player_batting:
		turn_label.text = "SUA VEZ NO BASTÃO (ATAQUE) - Pressione ESPAÇO para Rebater"
		turn_label.modulate = Color(1.0, 0.9, 0.25)
		if btn_pitch: 
			btn_pitch.modulate.a = 0.4
			btn_pitch.text = "ARREMESSAR [P]"
		if btn_swing: btn_swing.modulate.a = 1.0
	else:
		turn_label.text = "SUA VEZ NO MONTINHO (DEFESA) - Segure P para Força | Teclas 1, 2, 3"
		turn_label.modulate = Color(0.3, 0.85, 1.0)
		if btn_pitch: 
			btn_pitch.modulate.a = 1.0
			btn_pitch.text = "ARREMESSAR [P]"
		if btn_swing: btn_swing.modulate.a = 0.4

func update_charge_feedback(power: float) -> void:
	if not btn_pitch:
		return
	if power > 0.0:
		btn_pitch.text = "FORÇA: %d%%" % int(power * 100.0)
	else:
		btn_pitch.text = "ARREMESSAR [P]"

func update_display_mode_button(is_fullscreen: bool) -> void:
	if btn_display_mode:
		btn_display_mode.text = "🪟 MODO JANELA (F11)" if is_fullscreen else "🖥️ TELA CHEIA (F11)"

func update_count(balls: int, strikes: int, outs: int) -> void:
	if label_balls:
		label_balls.text = "BALLS: " + _format_dots(balls, 4, Color(0.2, 0.8, 0.3))
	if label_strikes:
		label_strikes.text = "STRIKES: " + _format_dots(strikes, 3, Color(0.95, 0.25, 0.25))
	if label_outs:
		label_outs.text = "OUTS: " + _format_dots(outs, 3, Color(0.95, 0.75, 0.1))

func _format_dots(current: int, total: int, _active_color: Color) -> String:
	var result = ""
	for i in range(total):
		if i < current:
			result += "● "
		else:
			result += "○ "
	return result.strip_edges()

func update_score(away_runs: int, home_runs: int, inning: int, is_top: bool, total_innings: int = 3) -> void:
	if label_score:
		var half = "▲ TOP" if is_top else "▼ BOT"
		label_score.text = "AWAY (CPU) %d  |  HOME (VOCÊ) %d   [%s %d/%d]" % [away_runs, home_runs, half, inning, total_innings]

func update_pitch_selection(pitch_type: int) -> void:
	var normal_color = Color(0.2, 0.25, 0.35, 0.8)
	var active_color = Color(0.15, 0.55, 0.85, 1.0)
	
	if btn_fastball:
		btn_fastball.modulate = active_color if pitch_type == 1 else normal_color
	if btn_curveball:
		btn_curveball.modulate = active_color if pitch_type == 2 else normal_color
	if btn_changeup:
		btn_changeup.modulate = active_color if pitch_type == 3 else normal_color

func show_feedback(title: String, subtitle: String, color: Color = Color.WHITE, timing_text: String = "") -> void:
	if not feedback_panel or not feedback_title or not feedback_subtitle:
		return
	
	feedback_title.text = title
	feedback_title.modulate = color
	feedback_subtitle.text = subtitle
	
	if feedback_timing:
		if timing_text != "":
			feedback_timing.text = timing_text
			feedback_timing.visible = true
		else:
			feedback_timing.visible = false
	
	if feedback_tween and feedback_tween.is_valid():
		feedback_tween.kill()

	feedback_panel.modulate.a = 0.0
	feedback_panel.scale = Vector2(0.85, 0.85)
	feedback_panel.pivot_offset = feedback_panel.size * 0.5

	feedback_tween = create_tween()
	feedback_tween.set_parallel(true)
	feedback_tween.tween_property(feedback_panel, "modulate:a", 1.0, 0.16)
	feedback_tween.tween_property(feedback_panel, "scale", Vector2(1.0, 1.0), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	feedback_tween.chain().tween_interval(2.2)
	feedback_tween.chain().tween_property(feedback_panel, "modulate:a", 0.0, 0.35)

func update_bases(has_1b: bool, has_2b: bool, has_3b: bool) -> void:
	var color_active = Color(1.0, 0.85, 0.2, 1.0)
	var color_empty = Color(0.7, 0.7, 0.7, 0.5)

	if label_base1:
		label_base1.text = "1B ◆" if has_1b else "1B ◇"
		label_base1.modulate = color_active if has_1b else color_empty

	if label_base2:
		label_base2.text = "2B ◆" if has_2b else "2B ◇"
		label_base2.modulate = color_active if has_2b else color_empty

	if label_base3:
		label_base3.text = "3B ◆" if has_3b else "3B ◇"
		label_base3.modulate = color_active if has_3b else color_empty

func show_game_over(winner_text: String, final_score_text: String) -> void:
	if not game_over_panel:
		return
	if winner_label:
		winner_label.text = winner_text
	if final_score_label:
		final_score_label.text = final_score_text
	
	game_over_panel.visible = true
	game_over_panel.modulate.a = 0.0
	game_over_panel.scale = Vector2(0.9, 0.9)
	game_over_panel.pivot_offset = game_over_panel.size * 0.5
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(game_over_panel, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_game_over() -> void:
	if game_over_panel:
		game_over_panel.visible = false
