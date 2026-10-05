class_name BaseManager
extends Node2D

signal bases_updated(has_1b: bool, has_2b: bool, has_3b: bool)
signal run_scored()

const RunnerScene = preload("res://scenes/players/runner.tscn")

# Estrutura de dados das bases
var base_1: Node2D = null
var base_2: Node2D = null
var base_3: Node2D = null

func _ready() -> void:
	emit_bases_state()

func emit_bases_state() -> void:
	bases_updated.emit(base_1 != null, base_2 != null, base_3 != null)

func clear_all_bases() -> void:
	if is_instance_valid(base_1):
		base_1.queue_free()
	if is_instance_valid(base_2):
		base_2.queue_free()
	if is_instance_valid(base_3):
		base_3.queue_free()

	base_1 = null
	base_2 = null
	base_3 = null
	emit_bases_state()

func process_hit(hit_type: String) -> void:
	var advance_count = 1
	var type_upper = hit_type.to_upper()

	if "HOME RUN" in type_upper:
		advance_count = 4
	elif "TRIPLE" in type_upper:
		advance_count = 3
	elif "DOUBLE" in type_upper:
		advance_count = 2
	else: # SINGLE ou WALK
		advance_count = 1

	_advance_runners(advance_count)

func _advance_runners(advance_count: int) -> void:
	# Guarda os corredores antes da jogada
	var r3 = base_3
	var r2 = base_2
	var r1 = base_1

	# Reseta as bases na estrutura de dados temporariamente
	base_3 = null
	base_2 = null
	base_1 = null

	# 1. Avança corredor da 3ª base
	if is_instance_valid(r3):
		var target = 3 + advance_count
		r3.advance_to_base(target)
		if target < 4:
			_place_on_base(r3, target)

	# 2. Avança corredor da 2ª base
	if is_instance_valid(r2):
		var target = 2 + advance_count
		r2.advance_to_base(target)
		if target < 4:
			_place_on_base(r2, target)

	# 3. Avança corredor da 1ª base
	if is_instance_valid(r1):
		var target = 1 + advance_count
		r1.advance_to_base(target)
		if target < 4:
			_place_on_base(r1, target)

	# 4. Rebatedor se torna um novo corredor saindo do Home Plate
	var new_runner = RunnerScene.instantiate()
	add_child(new_runner)
	new_runner.set_initial_base(0) # Inicia no Home Plate
	new_runner.scored_run.connect(_on_runner_scored)

	if advance_count >= 4:
		# Home Run! Percorre todas as bases até o Home Plate
		new_runner.advance_to_base(4)
	else:
		# Ocupa a base correspondente (1, 2 ou 3)
		new_runner.advance_to_base(advance_count)
		_place_on_base(new_runner, advance_count)

	emit_bases_state()

func _place_on_base(runner: Node2D, base_idx: int) -> void:
	match base_idx:
		1:
			base_1 = runner
		2:
			base_2 = runner
		3:
			base_3 = runner

func _on_runner_scored(runner: Node2D) -> void:
	# Desvincula das referências de base caso estivesse em alguma
	if base_1 == runner:
		base_1 = null
	if base_2 == runner:
		base_2 = null
	if base_3 == runner:
		base_3 = null

	run_scored.emit()
	emit_bases_state()
