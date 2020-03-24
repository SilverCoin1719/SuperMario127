extends AudioStreamPlayer

export var play_bus: String
export var edit_bus: String

export var volume_multiplier : float = 1
export var loading = false
var orig_volume = 0

var last_mode = 3
var last_song = 0

func get_song(song_id: int):
	var level_songs : IdMap  = preload("res://assets/music/ids.tres")
	var song : LevelSong = load("res://assets/music/resources/" + level_songs.ids[song_id] + ".tres")
	return song

func _ready():
	orig_volume = volume_db
	connect("music_changed", self, "change_song")
	
func change_song():
	var song = get_song(CurrentLevelData.level_data.areas[0].settings.music)
	if stream != song.stream:
		stream = song.stream
		play()
	if get_tree().get_current_scene().mode == 0:
		bus = play_bus
	else:
		bus = edit_bus

func _process(delta):
	if loading and OS.has_feature("JavaScript"):
		AudioServer.set_bus_mute(0, true)
		AudioServer.set_bus_mute(1, true)
	else:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_mute(1, false)
	if get_tree().get_current_scene().mode != last_mode or CurrentLevelData.level_data.areas[0].settings.music != last_song:
		change_song()
	volume_db = linear2db(db2linear(orig_volume) * volume_multiplier)
	last_mode = get_tree().get_current_scene().mode
	last_song = CurrentLevelData.level_data.areas[0].settings.music

func _unhandled_input(event):
	if event.is_action_pressed("mute"):
		volume_multiplier = 0 if volume_multiplier == 1 else 1