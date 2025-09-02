extends Node2D

@export var value: float = 1
@export var id: int = 1
signal collect(id : int)

var tween

func move(endPos :  Vector2, moveTime : float) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, position, endPos, moveTime)

func create(val : float, i_d : int, size : float, type : int, color : Color, pos : Vector2) -> void:
	var temp_child = get_child(type)
	temp_child.visible = true
	get_child((type + 1) % 3).visible = false
	get_child((type + 2) % 3).visible = false
	temp_child.scale = Vector2(size, size)
	$Detection/CollisionShape2D.shape.radius = size
	value = val
	id = i_d
	position = pos
	visible = true
	$Detection.monitoring = true
	modulate = color

#Meant to use this for non create, but I didn't need it it seems
"""
func move(v : float, i : int, size : float, type : int, color : Color) -> void:
	var temp_child = get_child(type)
	temp_child.visible = true
	get_child((type + 1) % 3).visible = false
	get_child((type + 2) % 3).visible = false
	$Detection/CollisionShape2D.shape.radius = size
	value = v
	id = i
	modulate = color
"""		

func _on_detection_area_entered(area: Area2D) -> void:
	#Call the player's collect here too as well with the value from this orb
	#Player.collect() w/e
	
	collect.emit()
	disable()
	
func disable() -> void:
	visible = false
	$Detection.monitoring = false
	
