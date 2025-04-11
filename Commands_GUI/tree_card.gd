@tool
extends Control
class_name TreeCard

@onready var icon = $Icon
@onready var amount_label = $Amount
@onready var button1 = $Button1
@onready var button2 = $Button2
@onready var button3 = $Button3

func _ready():
	# Connect button presses
	button1.pressed.connect(_on_button1_pressed)
	button2.pressed.connect(_on_button2_pressed)
	button3.pressed.connect(_on_button3_pressed)

func set_data(icon_texture, amount_text):
	icon.texture = icon_texture
	amount_label.text = str(amount_text)

func _on_button1_pressed():
	print("%s: Button 1 pressed!" % name)

func _on_button2_pressed():
	print("%s: Button 2 pressed!" % name)

func _on_button3_pressed():
	print("%s: Button 3 pressed!" % name)
