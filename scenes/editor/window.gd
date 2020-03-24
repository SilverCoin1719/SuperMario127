extends NinePatchRect

signal window_opened

onready var close_button = $CloseButton
onready var hover_sound = $CloseButton/HoverSound
onready var click_sound = $CloseButton/ClickSound
onready var tween = $Tween
var drag_position = null

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			drag_position = get_global_mouse_position() - rect_global_position
			raise()
		else:
			drag_position = null
	if event is InputEventMouseMotion and drag_position:
		rect_global_position = get_global_mouse_position() - drag_position

func open():
	emit_signal("window_opened")
	visible = true
	tween.interpolate_property(self, "rect_scale",
		Vector2(0, 0), Vector2(0.4, 0.4), 0.15,
		Tween.TRANS_CIRC, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_completed")
	
func close():
	tween.interpolate_property(self, "rect_scale",
		Vector2(0.4, 0.4), Vector2(0, 0), 0.15,
		Tween.TRANS_CIRC, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_completed")
	visible = false

func _ready():
	close_button.connect("mouse_entered", self, "hovered")
	close_button.connect("pressed", self, "pressed")

func hovered():
	hover_sound.play()

func pressed():
	close()
	click_sound.play()