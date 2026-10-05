class_name BaseballField
extends Node2D

# Dimensões e pontos de referência oficiais proporcionais do campo (viewport 1280x720)
const HOME_PLATE_POS = Vector2(640, 620)
const PITCHER_MOUND_POS = Vector2(640, 480)
const FIRST_BASE_POS = Vector2(780, 490)
const SECOND_BASE_POS = Vector2(640, 360)
const THIRD_BASE_POS = Vector2(500, 490)

# Foul poles no fundo do Outfield
const LEFT_FOUL_POLE = Vector2(80, 80)
const RIGHT_FOUL_POLE = Vector2(1200, 80)

# Cores
const COLOR_GRASS_LIGHT = Color(0.28, 0.62, 0.28)
const COLOR_GRASS_DARK = Color(0.25, 0.56, 0.25)
const COLOR_DIRT = Color(0.76, 0.56, 0.38)
const COLOR_DIRT_BORDER = Color(0.68, 0.48, 0.30)
const COLOR_CHALK = Color(0.95, 0.95, 0.95, 0.95)
const COLOR_FENCE = Color(0.18, 0.35, 0.22)
const COLOR_BASE = Color(0.96, 0.96, 0.94)

var show_strike_zone: bool = true

func _draw() -> void:
	# 1. Fundo do gramado completo com faixas horizontais de corte
	draw_rect(Rect2(0, 0, 1280, 720), COLOR_GRASS_LIGHT)
	for i in range(12):
		if i % 2 == 0:
			draw_rect(Rect2(0, i * 60, 1280, 60), COLOR_GRASS_DARK)

	# 2. Outfield Wall / Cerca curva ampla ao fundo
	var fence_points = PackedVector2Array([
		Vector2(50, 10),
		Vector2(1230, 10),
		Vector2(1200, 80),
		Vector2(640, 95),
		Vector2(80, 80)
	])
	draw_polygon(fence_points, [COLOR_FENCE])
	draw_polyline(fence_points, Color(0.9, 0.75, 0.2), 4.0)

	# 3. Arco da terra batida do Infield (dirt track)
	var dirt_arc_center = PITCHER_MOUND_POS + Vector2(0, 10)
	draw_circle(dirt_arc_center, 195.0, COLOR_DIRT)

	# Diamante de grama dentro do infield
	var infield_grass = PackedVector2Array([
		HOME_PLATE_POS + Vector2(0, -30),
		FIRST_BASE_POS + Vector2(-25, 0),
		SECOND_BASE_POS + Vector2(0, 25),
		THIRD_BASE_POS + Vector2(25, 0)
	])
	draw_polygon(infield_grass, [COLOR_GRASS_LIGHT])

	# Caminhos de terra entre as bases (base paths)
	draw_line(HOME_PLATE_POS, FIRST_BASE_POS, COLOR_DIRT, 24.0)
	draw_line(FIRST_BASE_POS, SECOND_BASE_POS, COLOR_DIRT, 24.0)
	draw_line(SECOND_BASE_POS, THIRD_BASE_POS, COLOR_DIRT, 24.0)
	draw_line(THIRD_BASE_POS, HOME_PLATE_POS, COLOR_DIRT, 24.0)

	# Círculos de terra nas bases
	draw_circle(FIRST_BASE_POS, 22.0, COLOR_DIRT)
	draw_circle(SECOND_BASE_POS, 22.0, COLOR_DIRT)
	draw_circle(THIRD_BASE_POS, 22.0, COLOR_DIRT)
	draw_circle(HOME_PLATE_POS, 36.0, COLOR_DIRT)

	# 4. Linhas de giz branco (Foul lines)
	draw_line(HOME_PLATE_POS, RIGHT_FOUL_POLE, COLOR_CHALK, 3.0)
	draw_line(HOME_PLATE_POS, LEFT_FOUL_POLE, COLOR_CHALK, 3.0)

	# Foul Poles (postes amarelos ao fundo)
	draw_line(LEFT_FOUL_POLE, LEFT_FOUL_POLE + Vector2(0, -45), Color(0.95, 0.85, 0.1), 5.0)
	draw_line(RIGHT_FOUL_POLE, RIGHT_FOUL_POLE + Vector2(0, -45), Color(0.95, 0.85, 0.1), 5.0)

	# 5. Pitcher's Mound (Montinho no centro do Infield, entre Home e 2B)
	draw_circle(PITCHER_MOUND_POS, 32.0, COLOR_DIRT_BORDER)
	draw_circle(PITCHER_MOUND_POS, 28.0, COLOR_DIRT)
	# Pitcher Rubber (placa de borracha branca do arremessador)
	draw_rect(Rect2(PITCHER_MOUND_POS.x - 14, PITCHER_MOUND_POS.y - 3, 28, 6), COLOR_CHALK)

	# 6. Batter's Boxes (caixas do rebatedor ao lado do home plate)
	draw_rect(Rect2(HOME_PLATE_POS.x - 62, HOME_PLATE_POS.y - 30, 32, 60), COLOR_CHALK, false, 2.0)
	draw_rect(Rect2(HOME_PLATE_POS.x + 30, HOME_PLATE_POS.y - 30, 32, 60), COLOR_CHALK, false, 2.0)
	# Catcher's Box
	draw_rect(Rect2(HOME_PLATE_POS.x - 26, HOME_PLATE_POS.y + 18, 52, 42), COLOR_CHALK, false, 2.0)

	# 7. Bases (losangos brancos)
	_draw_base(FIRST_BASE_POS)
	_draw_base(SECOND_BASE_POS)
	_draw_base(THIRD_BASE_POS)

	# 8. Home Plate (pentágono oficial)
	var hp_size = 16.0
	var hp_points = PackedVector2Array([
		Vector2(HOME_PLATE_POS.x - hp_size, HOME_PLATE_POS.y - hp_size * 0.5),
		Vector2(HOME_PLATE_POS.x + hp_size, HOME_PLATE_POS.y - hp_size * 0.5),
		Vector2(HOME_PLATE_POS.x + hp_size, HOME_PLATE_POS.y + hp_size * 0.2),
		Vector2(HOME_PLATE_POS.x, HOME_PLATE_POS.y + hp_size * 0.8),
		Vector2(HOME_PLATE_POS.x - hp_size, HOME_PLATE_POS.y + hp_size * 0.2)
	])
	draw_polygon(hp_points, [COLOR_BASE])
	draw_polyline(hp_points, Color(0.2, 0.2, 0.2), 1.5)

	# 9. Strike Zone visual (guia sobre o home plate)
	if show_strike_zone:
		var sz_rect = Rect2(HOME_PLATE_POS.x - 26, HOME_PLATE_POS.y - 36, 52, 42)
		draw_rect(sz_rect, Color(0.9, 0.9, 0.2, 0.14))
		draw_rect(sz_rect, Color(0.9, 0.9, 0.2, 0.55), false, 1.5)

func _draw_base(pos: Vector2) -> void:
	var base_size = 12.0
	var points = PackedVector2Array([
		pos + Vector2(0, -base_size),
		pos + Vector2(base_size, 0),
		pos + Vector2(0, base_size),
		pos + Vector2(-base_size, 0)
	])
	draw_polygon(points, [COLOR_BASE])
	draw_polyline(points, Color(0.3, 0.3, 0.3), 1.5)

# Verifica se um ponto no campo está dentro das foul lines (Fair ball)
func is_fair_ball(pos: Vector2) -> bool:
	var to_point = pos - HOME_PLATE_POS
	if to_point.y > 10.0:
		return false
	
	var right_foul_vec = RIGHT_FOUL_POLE - HOME_PLATE_POS
	var left_foul_vec = LEFT_FOUL_POLE - HOME_PLATE_POS

	var cross_right = right_foul_vec.x * to_point.y - right_foul_vec.y * to_point.x
	var cross_left = left_foul_vec.x * to_point.y - left_foul_vec.y * to_point.x

	return cross_right <= 0.0 and cross_left >= 0.0

# Verifica se a rebatida foi Home Run (passou da cerca no outfield em território fair)
func is_home_run(pos: Vector2) -> bool:
	if not is_fair_ball(pos):
		return false
	return pos.y <= 95.0
