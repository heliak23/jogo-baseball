class_name Catcher
extends Node2D

signal ball_received(is_strike: bool)

@export var catcher_pos: Vector2 = Vector2(640, 655)

# Cores
const COLOR_JERSEY = Color(0.18, 0.38, 0.72)
const COLOR_PROTECTOR = Color(0.12, 0.12, 0.14) # Peitoral preto fosco
const COLOR_PANTS = Color(0.92, 0.92, 0.92)
const COLOR_HELMET = Color(0.12, 0.25, 0.55)
const COLOR_SKIN = Color(0.94, 0.76, 0.62)
const COLOR_MITT = Color(0.42, 0.22, 0.12)     # Luva grande de catcher

var is_catching: bool = false
var mitt_offset: Vector2 = Vector2(-8, -24)

func _ready() -> void:
	position = catcher_pos

func catch_ball(is_strike: bool) -> void:
	is_catching = true
	ball_received.emit(is_strike)
	queue_redraw()
	
	# Reseta postura após um instante
	var tween = create_tween()
	tween.tween_interval(0.4)
	tween.tween_callback(func():
		is_catching = false
		queue_redraw()
	)

func _draw() -> void:
	# 1. Sombra larga no chão (agachado)
	draw_custom_ellipse(Vector2(0, 10), 20.0, 9.0, Color(0.1, 0.15, 0.1, 0.35))

	# 2. Joelhos e caneleiras (shin guards)
	draw_rect(Rect2(-12, -2, 9, 14), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(3, -2, 9, 14), Color(0.2, 0.2, 0.2))
	# Fivelas das caneleiras
	draw_line(Vector2(-12, 2), Vector2(-3, 2), Color(0.6, 0.6, 0.6), 1.5)
	draw_line(Vector2(3, 2), Vector2(12, 2), Color(0.6, 0.6, 0.6), 1.5)

	# 3. Tronco com protetor peitoral (chest protector)
	draw_rect(Rect2(-14, -18, 28, 18), COLOR_JERSEY)
	draw_rect(Rect2(-11, -17, 22, 16), COLOR_PROTECTOR)
	# Nervuras do peitoral
	draw_line(Vector2(-11, -11), Vector2(11, -11), Color(0.3, 0.3, 0.3), 1.5)
	draw_line(Vector2(-11, -5), Vector2(11, -5), Color(0.3, 0.3, 0.3), 1.5)

	# 4. Cabeça com capacete e grade de proteção
	draw_circle(Vector2(0, -26), 9.0, COLOR_HELMET)
	# Grade frontal
	draw_line(Vector2(-5, -30), Vector2(-5, -22), Color(0.7, 0.7, 0.7), 1.5)
	draw_line(Vector2(0, -31), Vector2(0, -21), Color(0.7, 0.7, 0.7), 1.5)
	draw_line(Vector2(5, -30), Vector2(5, -22), Color(0.7, 0.7, 0.7), 1.5)
	draw_line(Vector2(-6, -26), Vector2(6, -26), Color(0.7, 0.7, 0.7), 1.5)

	# 5. Luva de recepção (Catcher's Mitt)
	var cur_mitt = mitt_offset
	if is_catching:
		cur_mitt += Vector2(0, 3)
	
	draw_circle(cur_mitt, 8.5, COLOR_MITT)
	draw_circle(cur_mitt + Vector2(1, -2), 3.5, Color(0.3, 0.15, 0.08)) # Bolsão da luva

func draw_custom_ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(14):
		var a = i * TAU / 14
		points.append(center + Vector2(cos(a) * radius_x, sin(a) * radius_y))
	draw_colored_polygon(points, color)
