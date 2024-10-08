extends Node

signal loading_finished


onready var http_thumbnails = $"%HTTPThumbnails"
export var drag_cursor_path: NodePath
onready var drag_cursor: Area2D = get_node(drag_cursor_path)


onready var list_handler = get_parent()

onready var level_card_scene: PackedScene = preload("res://scenes/menu/levels_list/list_elements/level_card.tscn")
onready var folder_scene: PackedScene = preload("res://scenes/menu/levels_list/list_elements/folder.tscn")
onready var level_load_thread := Thread.new()

func start_level_loading(working_folder: String):
	if level_load_thread.is_active():
		level_load_thread.wait_to_finish()
	
	var err = level_load_thread.start(self, "load_all_levels", working_folder)
	if err != OK:
		push_error("Error starting level loading thread.")

# Thread must be disposed (or "joined"), for portability.
func _exit_tree():
	if level_load_thread.is_active():
		level_load_thread.wait_to_finish()

var last_level_card: Node
func load_all_levels(working_folder: String):
	var sorting: Node = list_handler.sorting
	http_thumbnails.clear_queue()
	
	print("Loading directory " + working_folder + "...")
	for folder in sorting.sort.folders:
		add_folder_button(working_folder + "/" + folder, folder)
	for level in sorting.sort.levels:
		add_level_card(working_folder + "/" + level + ".127level", level, working_folder)
	
	if is_instance_valid(last_level_card):
		last_level_card.connect("ready", http_thumbnails, "load_next_image", [], CONNECT_ONESHOT)
		
		print("Done loading levels in directory.")
	
	emit_signal("loading_finished")

func add_folder_button(file_path: String, folder_name: String, move_to_front: bool = false, is_return: bool = false):
	var level_grid: GridContainer = list_handler.level_grid
	var folders: Node = list_handler.folders
	
	var folder_button: Button = folder_scene.instance()
	folder_button.name = folder_name
	folder_button.get_node("Name").text = folder_name
	level_grid.call_deferred("add_child", folder_button)
	
	if move_to_front:
		level_grid.call_deferred("move_child", folder_button, list_handler.back_buttons)
	
	#warning-ignore:return_value_discarded
	folder_button.call_deferred("connect", "pressed", folders, "change_folder", [file_path, true, is_return])

func add_level_card(file_path: String, level_id: String, working_folder: String, level_code: String = "", move_to_front: bool = false):
	var level_grid: GridContainer = list_handler.level_grid
	
	if level_code == "":
		level_code = saved_levels_util.load_level_code_file(file_path)
	elif not level_code_util.fast_is_valid(level_code):
		level_code = saved_levels_util.load_level_code_file(list_handler.DEFAULT_LEVEL)
	
	var level_info := LevelInfo.new(level_code)
	var level_card: Button = level_card_scene.instance()
	level_card.name = level_id

	# needs some variables now for visual touches
	var styling = level_card.get_node("%Styling")
	styling.level_info = level_info
	styling.http_thumbnails = http_thumbnails

	# load save file
	var save_path: String = saved_levels_util.get_level_save_path(level_id, working_folder)
	if saved_levels_util.file_exists(save_path):
		level_info.load_save_from_dictionary(saved_levels_util.load_level_save_file(save_path))
		styling.is_complete = level_info.is_fully_completed()

	level_card.get_node("%Name").text = level_info.level_name

	level_grid.call_deferred("add_child", level_card)
	if move_to_front:
		var index: int = list_handler.back_buttons + list_handler.folder_buttons
		level_grid.call_deferred("move_child", level_card, index)
	
	## some signal stuff!! the signals tell the level list
	## to transition to another screen, and then tell the
	## level info panel to start loading our level data 

	#warning-ignore:return_value_discarded
	level_card.call_deferred("connect", "button_pressed", list_handler.level_list, "transition", ["LevelInfo"])
	#warning-ignore:return_value_discarded
	level_card.call_deferred("connect", "button_pressed", list_handler.level_panel, "load_level_info", [level_info, level_id, working_folder])
	#warning-ignore:return_value_discarded
	# when returning from a level on controller its good to be able to start from its card
	level_card.call_deferred("connect", "button_pressed", list_handler, "change_focus", [level_card])


	## these signals are for dragging levels around in the list
	#warning-ignore:return_value_discarded
	level_card.call_deferred("connect", "drag_started", drag_cursor, "start_dragging")
	#warning-ignore:return_value_discarded
	level_card.call_deferred("connect", "drag_ended", drag_cursor, "stop_dragging")

	last_level_card = level_card
