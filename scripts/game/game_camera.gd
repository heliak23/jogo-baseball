class_name GameCamera
extends Camera2D

@export var ball_ref: Node2D
@export var base_camera_pos: Vector2 = Vector2(640, 360)
@export var default_zoom: Vector2 = Vector2(0.96, 0.96)

var is_following_ball: bool = false
var target_pos: Vector2 = Vector2(640, 360)

func _ready() -> void:
	position = base_camera_pos
	zoom = default_zoom

func reset_camera() -> void:
	is_following_ball = false
	target_pos = base_camera_pos

func follow_play(ball: Node2D) -> void:
	ball_ref = ball
	is_following_ball = true

func _process(delta: float) -> void:
	if is_following_ball and is_instance_valid(ball_ref):
		# Se a bola estiver em jogo no outfield, desloca a câmera suavemente para dar visibilidade total
		if ball_ref.current_state == 2 or ball_ref.current_state == 3: # HIT ou GROUND_ROLL
			var ball_y = ball_ref.ground_pos.y
			if ball_y < 260.0:
				# Suave deslocamento vertical para o outfield
				var offset_y = clampf((ball_y - 260.0) * 0.35, -70.0, 0.0)
				target_pos = base_camera_pos + Vector2(0, offset_y)
			else:
				target_pos = base_camera_pos
		else:
			target_pos = base_camera_pos
	else:
		target_pos = base_camera_pos

	# Interpolação suave e estável (sem solavancos)
	position = position.lerp(target_pos, delta * 3.5)
