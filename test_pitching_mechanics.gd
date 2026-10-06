extends SceneTree

func _init() -> void:
	print("--- TESTANDO MECÂNICAS DE ARREMESSO (CHARGE, TIPOS E VELOCIDADES) ---")
	
	var main_scene_res = load("res://scenes/game/main.tscn")
	if not main_scene_res:
		printerr("FALHA: Não foi possível carregar main.tscn")
		quit(1)
		return
	
	var main = main_scene_res.instantiate()
	root.add_child(main)
	
	var pitcher = main.pitcher
	var ball = main.ball
	
	print("[1] Validando Variáveis Exportadas no Pitcher...")
	assert(pitcher != null, "Pitcher deve existir na cena")
	assert(pitcher.max_charge_time > 0.0, "max_charge_time deve ser maior que 0")
	assert(pitcher.fastball_speed_min > 0.0 and pitcher.fastball_speed_max > pitcher.fastball_speed_min, "Fastball max deve ser maior que min")
	assert(pitcher.curveball_speed_min > 0.0 and pitcher.curveball_speed_max > pitcher.curveball_speed_min, "Curveball max deve ser maior que min")
	assert(pitcher.changeup_speed_min > 0.0 and pitcher.changeup_speed_max > pitcher.changeup_speed_min, "Changeup max deve ser maior que min")
	
	print("  -> max_charge_time: ", pitcher.max_charge_time)
	print("  -> Fastball: [", pitcher.fastball_speed_min, ", ", pitcher.fastball_speed_max, "]")
	print("  -> Curveball: [", pitcher.curveball_speed_min, ", ", pitcher.curveball_speed_max, "]")
	print("  -> Changeup: [", pitcher.changeup_speed_min, ", ", pitcher.changeup_speed_max, "]")
	print("  [OK] Variáveis exportadas validadas com sucesso!")
	
	print("[2] Validando Seleção dos Tipos de Arremesso (1, 2, 3)...")
	pitcher.set_pitch_type(pitcher.PitchType.FASTBALL)
	assert(pitcher.selected_pitch == pitcher.PitchType.FASTBALL, "Deve ser FASTBALL")
	pitcher.set_pitch_type(pitcher.PitchType.CURVEBALL)
	assert(pitcher.selected_pitch == pitcher.PitchType.CURVEBALL, "Deve ser CURVEBALL")
	pitcher.set_pitch_type(pitcher.PitchType.CHANGEUP)
	assert(pitcher.selected_pitch == pitcher.PitchType.CHANGEUP, "Deve ser CHANGEUP")
	print("  [OK] Seleção de tipos 1, 2 e 3 validada com sucesso!")
	
	print("[3] Validando Cálculo de Velocidade e Mecânica de Charge...")
	# 3.1 Fastball carga mínima (toque rápido = power 0.0)
	var spd_fb_min = pitcher.get_speed_for_pitch(pitcher.PitchType.FASTBALL, 0.0)
	assert(abs(spd_fb_min - pitcher.fastball_speed_min) < 0.01, "Carga 0 deve retornar fastball_speed_min")
	
	# 3.2 Fastball carga máxima (hold total = power 1.0)
	var spd_fb_max = pitcher.get_speed_for_pitch(pitcher.PitchType.FASTBALL, 1.0)
	assert(abs(spd_fb_max - pitcher.fastball_speed_max) < 0.01, "Carga 1.0 deve retornar fastball_speed_max")
	
	# 3.3 Curveball carga intermediária (power 0.5)
	var spd_cb_mid = pitcher.get_speed_for_pitch(pitcher.PitchType.CURVEBALL, 0.5)
	var expected_cb_mid = lerpf(pitcher.curveball_speed_min, pitcher.curveball_speed_max, 0.5)
	assert(abs(spd_cb_mid - expected_cb_mid) < 0.01, "Carga 0.5 deve retornar média linear")
	
	# 3.4 Changeup carga máxima
	var spd_ch_max = pitcher.get_speed_for_pitch(pitcher.PitchType.CHANGEUP, 1.0)
	assert(abs(spd_ch_max - pitcher.changeup_speed_max) < 0.01, "Carga 1.0 deve retornar changeup_speed_max")
	print("  -> Velocidade Fastball Min: ", spd_fb_min, " Max: ", spd_fb_max)
	print("  -> Velocidade Curveball Mid: ", spd_cb_mid)
	print("  -> Velocidade Changeup Max: ", spd_ch_max)
	print("  [OK] Cálculo proporcional de velocidades validado!")
	
	print("[4] Validando Disparo da Bola e Curvaturas Físicas...")
	# 4.1 Fastball
	ball.start_pitch(Vector2(640, 480), Vector2(640, 620), ball.PitchType.FASTBALL, spd_fb_max)
	assert(ball.pitch_curve_strength == 0.0, "Fastball deve ter trajetória reta (curve_strength == 0)")
	assert(ball.pitch_duration < 0.45, "Fastball no máximo deve ter duração menor que 0.45s")
	print("  -> Fastball duração: ", ball.pitch_duration, " curva: ", ball.pitch_curve_strength)
	
	# 4.2 Curveball
	ball.start_pitch(Vector2(640, 480), Vector2(640, 620), ball.PitchType.CURVEBALL, spd_cb_mid)
	assert(ball.pitch_curve_strength > 0.0, "Curveball deve ter curva positiva")
	print("  -> Curveball duração: ", ball.pitch_duration, " curva: ", ball.pitch_curve_strength)
	
	# 4.3 Changeup
	ball.start_pitch(Vector2(640, 480), Vector2(640, 620), ball.PitchType.CHANGEUP, pitcher.changeup_speed_min)
	assert(ball.pitch_curve_strength < 0.0, "Changeup deve ter leve curva negativa")
	assert(ball.pitch_duration > 0.80, "Changeup com velocidade mínima deve demorar > 0.8s")
	print("  -> Changeup duração: ", ball.pitch_duration, " curva: ", ball.pitch_curve_strength)
	print("  [OK] Trajetórias e durações da bola validadas!")
	
	print("[5] Validando Regra da CPU para Arremesso...")
	# Forçar turno de ataque do Player para testar arremesso da CPU
	main.is_top_inning = false
	main.set_state(main.MatchState.AT_BAT)
	pitcher.reset_ready()
	main._on_cpu_auto_pitch()
	assert(pitcher.current_state == pitcher.State.CHARGING, "CPU deve colocar o Pitcher em CHARGING")
	print("  -> CPU iniciou charging com sucesso no arremesso!")
	
	print("\n*** TODOS OS TESTES DE PITCHING PASSARAM COM SUCESSO! ***\n")
	quit(0)
