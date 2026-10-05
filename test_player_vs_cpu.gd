extends SceneTree

func _init() -> void:
	print("--- INICIANDO TESTES DO BASEBALL 2D (PLAYER VS CPU & REGRAS) ---")
	
	var main_scene_res = load("res://scenes/game/main.tscn")
	if not main_scene_res:
		printerr("FALHA: Nao foi possivel carregar main.tscn")
		quit(1)
		return
	
	var main = main_scene_res.instantiate()
	root.add_child(main)
	
	# Aguardar inicializacao
	print("[1] Testando Posicionamento dos Jogadores e do Campo...")
	assert(main.pitcher != null, "Pitcher deve existir")
	assert(main.catcher != null, "Catcher deve existir")
	assert(main.batter != null, "Batter deve existir")
	assert(main.ball != null, "Ball deve existir")
	assert(main.defense_manager != null, "DefenseManager deve existir")
	assert(main.game_camera != null, "GameCamera deve existir")
	assert(main.display_settings != null, "DisplaySettings deve existir")
	
	# Verificar posicoes
	var pitcher_pos = main.pitcher.position
	var catcher_pos = main.catcher.position
	var batter_pos = main.batter.position
	print("  -> Pitcher Mound: ", pitcher_pos, " (esperado ~ Vector2(640, 480))")
	print("  -> Catcher: ", catcher_pos, " (esperado ~ Vector2(640, 655))")
	print("  -> Batter: ", batter_pos, " (esperado ~ Vector2(595, 615))")
	
	assert(abs(pitcher_pos.x - 640.0) < 5.0 and abs(pitcher_pos.y - 480.0) < 5.0, "Pitcher deve estar no Mound (640, 480)")
	assert(catcher_pos.y > 640.0, "Catcher deve estar atras do Home Plate (y > 640)")
	assert(pitcher_pos.y < 500.0 and pitcher_pos.y > 360.0, "Pitcher deve estar entre 2B (360) e Home Plate (620)")
	
	# Verificar Outfielders
	var lf = main.defense_manager.left_fielder
	var cf = main.defense_manager.center_fielder
	var rf = main.defense_manager.right_fielder
	assert(lf != null and cf != null and rf != null, "Outfielders LF, CF, RF devem existir")
	print("  -> LF pos: ", lf.position, " CF pos: ", cf.position, " RF pos: ", rf.position)
	assert(cf.position.y < 200.0, "Center Fielder deve estar no Outfield profundo (y < 200)")
	assert(lf.position.x < 400.0, "Left Fielder deve estar na ala esquerda (x < 400)")
	assert(rf.position.x > 800.0, "Right Fielder deve estar na ala direita (x > 800)")
	print("  [OK] Posicionamento validado com sucesso!")
	
	print("[2] Testando Pitching e Trajetória...")
	# Arremesso da bola
	main.pitcher.start_pitch(main.pitcher.PitchType.FASTBALL)
	var ball_vel = main.ball.velocity
	print("  -> Velocidade inicial do arremesso: ", ball_vel)
	assert(ball_vel.y > 0, "A bola arremessada deve viajar na direcao Y positiva (para baixo, rumo ao Home Plate)")
	print("  [OK] Pitch direcionado corretamente para o Home Plate!")
	
	print("[3] Testando Camera2D e DisplaySettings...")
	var cam = main.game_camera
	print("  -> Camera Zoom: ", cam.zoom, " Camera Pos: ", cam.position)
	assert(cam.zoom.x <= 1.0 and cam.zoom.y <= 1.0, "Camera deve estar afastada (zoom <= 1.0)")
	assert(cam.is_camera_wide(), "Camera deve estar em modo amplo")
	
	var disp = main.display_settings
	var initial_mode = disp.is_fullscreen()
	print("  -> Modo de exibição inicial: ", "Fullscreen" if initial_mode else "Windowed")
	disp.set_display_mode(true)
	assert(disp.is_fullscreen() == true, "DisplaySettings deve alternar para Fullscreen")
	disp.set_display_mode(false)
	assert(disp.is_fullscreen() == false, "DisplaySettings deve alternar para Windowed")
	print("  [OK] Camera e DisplaySettings funcionando perfeitamente!")
	
	print("[4] Testando Estrutura PLAYER VS CPU e Alternância de Lados...")
	# Início da partida: Inning 1 TOP -> CPU Atacando, Player Defendendo
	print("  -> Inning atual: ", main.current_inning, " Top?: ", main.is_top_inning)
	print("  -> Player atacando?: ", main.is_player_batting())
	assert(main.is_top_inning == true, "Deve iniciar no TOP do Inning 1")
	assert(main.is_player_batting() == false, "No TOP do inning, a CPU ataca e o Player defende")
	
	# Simular 3 outs para forçar troca de lado
	main.outs_count = 2
	main._register_out("Teste 3rd Out")
	
	# Apos 3 outs, troca de lados: deve ir para Inning 1 BOTTOM
	print("  -> Apos 3 outs: Inning ", main.current_inning, " Top?: ", main.is_top_inning)
	print("  -> Player atacando?: ", main.is_player_batting())
	assert(main.is_top_inning == false, "Apos 3 outs, deve ir para o BOTTOM do inning")
	assert(main.is_player_batting() == true, "No BOTTOM do inning, o Player ataca e a CPU defende")
	assert(main.outs_count == 0, "Outs devem ser resetados para 0 ao trocar de lado")
	assert(main.strikes_count == 0 and main.balls_count == 0, "Contagem de strikes e balls deve ser resetada")
	
	# Simular mais 3 outs para avançar de inning
	main.outs_count = 2
	main._register_out("Teste Inning 2 Switch")
	print("  -> Apos novo turno de 3 outs: Inning ", main.current_inning, " Top?: ", main.is_top_inning)
	print("  -> Player atacando?: ", main.is_player_batting())
	assert(main.current_inning == 2, "Deve ter avancado para o Inning 2")
	assert(main.is_top_inning == true, "Deve retornar para TOP do Inning 2")
	assert(main.is_player_batting() == false, "No TOP do Inning 2, a CPU ataca novamente")
	print("  [OK] Alternância automática de turnos e innings validada com sucesso!")
	
	print("[5] Testando IA de Defesa no Outfield...")
	# Simular uma rebatida fly ball para o Center Field
	main.ball.position = Vector2(640, 200)
	main.ball.is_in_flight = true
	main.defense_manager.on_ball_hit(Vector2(640, 200), true)
	var active_fielder = main.defense_manager.active_fielder
	assert(active_fielder != null, "DefenseManager deve selecionar um defensor ativo")
	print("  -> Fielder selecionado para bola em (640, 200): ", active_fielder.player_name)
	assert(active_fielder.player_name == "CF", "O Center Fielder deve ser escolhido para bola no centro do outfield")
	assert(active_fielder.current_state == active_fielder.FielderState.CHASING, "Fielder deve estar em estado CHASING")
	print("  [OK] IA defensiva dos Outfielders validada com sucesso!")
	
	print("[6] Testando IA da CPU Rebatedora...")
	# Testar calculo de probabilidade de swing da CPU
	var swing_prob_fb = main._calculate_cpu_swing_probability(main.pitcher.PitchType.FASTBALL)
	var swing_prob_cb = main._calculate_cpu_swing_probability(main.pitcher.PitchType.CURVEBALL)
	var swing_prob_ch = main._calculate_cpu_swing_probability(main.pitcher.PitchType.CHANGEUP)
	print("  -> Probabilidade de Swing CPU: Fastball=", swing_prob_fb, " Curveball=", swing_prob_cb, " Changeup=", swing_prob_ch)
	assert(swing_prob_fb > swing_prob_cb, "Fastball deve ter maior probabilidade de swing que Curveball")
	assert(swing_prob_ch < swing_prob_fb, "Changeup deve ter variacao de timing/probabilidade")
	print("  [OK] IA da CPU Rebatedora validada com sucesso!")
	
	print("[7] Testando HUD e Botão Display Mode...")
	assert(main.hud != null, "HUD deve existir")
	var btn_disp = main.hud.btn_display_mode
	assert(btn_disp != null, "Botão Display Mode deve existir no HUD")
	print("  -> Texto do Botão Display Mode: ", btn_disp.text)
	assert(main.hud.turn_banner != null, "TurnBanner deve existir no HUD")
	print("  [OK] HUD e controles visuais validados com sucesso!")
	
	print("\n*** TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! ***\n")
	quit(0)
