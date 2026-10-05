class_name DisplaySettings
extends Node

const SETTINGS_FILE_PATH = "user://display_settings.cfg"
const SECTION_DISPLAY = "display"
const KEY_FULLSCREEN = "fullscreen"

signal display_mode_changed(is_fullscreen: bool)

var is_fullscreen: bool = false

func _ready() -> void:
	_force_window_stretch_scaling()
	load_display_settings()
	
	# Escuta mudanças no tamanho da janela (ex: quando o jogador clica em Maximizar no Windows)
	var win = get_window()
	if win:
		win.size_changed.connect(_on_window_size_changed)

	call_deferred("_notify_initial_state")

func _force_window_stretch_scaling() -> void:
	var win = get_window()
	if win:
		# Força programaticamente o redimensionamento do jogo para preencher a tela ao maximizar
		win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		win.content_scale_size = Vector2i(1280, 720)
		win.content_scale_factor = 1.0

	# Garante a persistência também no ProjectSettings
	ProjectSettings.set_setting("display/window/size/viewport_width", 1280)
	ProjectSettings.set_setting("display/window/size/viewport_height", 720)
	ProjectSettings.set_setting("display/window/size/resizable", true)
	ProjectSettings.set_setting("display/window/stretch/mode", "canvas_items")
	ProjectSettings.set_setting("display/window/stretch/aspect", "keep")
	ProjectSettings.set_setting("display/window/stretch/scale_mode", "fractional")
	ProjectSettings.save()

func _on_window_size_changed() -> void:
	var win = get_window()
	if win:
		# Reafirma os parâmetros de escala ao redimensionar ou maximizar
		win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		win.content_scale_size = Vector2i(1280, 720)

	var current_mode = DisplayServer.window_get_mode()
	var is_full = (current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_MAXIMIZED)
	is_fullscreen = is_full
	display_mode_changed.emit(is_fullscreen)

func _notify_initial_state() -> void:
	display_mode_changed.emit(is_fullscreen)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			toggle_fullscreen()
			get_viewport().set_input_as_handled()

func load_display_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE_PATH)
	if err == OK:
		var saved_fullscreen = config.get_value(SECTION_DISPLAY, KEY_FULLSCREEN, false)
		if saved_fullscreen:
			set_fullscreen(true, false)
		else:
			# Se estava em modo janela, aplica janela redimensionável
			set_fullscreen(false, false)
	else:
		# Padrão: inicia respeitando janela maximizada ou tela cheia
		var current_mode = DisplayServer.window_get_mode()
		if current_mode == DisplayServer.WINDOW_MODE_MAXIMIZED or current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			is_fullscreen = true
		else:
			is_fullscreen = false

func save_display_settings() -> void:
	var config = ConfigFile.new()
	config.set_value(SECTION_DISPLAY, KEY_FULLSCREEN, is_fullscreen)
	config.save(SETTINGS_FILE_PATH)

func toggle_fullscreen() -> void:
	var current_mode = DisplayServer.window_get_mode()
	var currently_full = (current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_MAXIMIZED)
	set_fullscreen(not currently_full, true)

func set_fullscreen(enable: bool, save: bool = true) -> void:
	is_fullscreen = enable
	var win = get_window()
	if win:
		win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		win.content_scale_size = Vector2i(1280, 720)

	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var screen_size = DisplayServer.screen_get_size()
		var window_size = Vector2i(1280, 720)
		DisplayServer.window_set_size(window_size)
		var center_pos = Vector2i(int((screen_size.x - window_size.x) * 0.5), int((screen_size.y - window_size.y) * 0.5))
		DisplayServer.window_set_position(center_pos)

	if save:
		save_display_settings()

	display_mode_changed.emit(is_fullscreen)
