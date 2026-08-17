extends Node2D

@export var value: float = 1
@export var id: int = 1
signal collect(id : int)

var enemy_drop = false

var tween
var tween2
var visible_sprite

#func _ready() -> void:
#	pass
	#print("orb ready")

#I don't like this but it's ok.
func getPosition() -> Vector2:
	return position + get_parent().position

func move(endPos :  Vector2, moveTime : float) -> void:
	if tween2:
		tween2.kill()
	tween2 = create_tween()
	tween2.set_ease(Tween.EASE_OUT)
	tween2.set_trans(Tween.TRANS_CUBIC)
	tween2.tween_property(self, "position", endPos, moveTime)

func create(val : float, i_d : int, size : float, type : int, color : Color, pos : Vector2, en_drop = false) -> void:
	#print(size)
	
	var temp_child = get_child(type)
	temp_child.visible = true
	get_child((type + 1) % 3).visible = false
	get_child((type + 2) % 3).visible = false
	visible_sprite = temp_child
	enemy_drop = en_drop
	
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1, 0.25).from(0)
	tween.parallel().tween_property(visible_sprite, "scale", Vector2(size, size), 0.25).from(Vector2.ZERO)
	#Need to write some code here that updates the shape size
	#$Detection/CollisionShape2D.shape.radius = 10#ceil(size*10)
	value = val
	id = i_d
	position = pos
	visible = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	temp_child.modulate = color

#Call this when you need to change the orb size
func augmentCollision(size : int) -> void:
	var newShape = CircleShape2D.new()
	newShape.radius = size
	$CollisionShape2D.set_deferred("shape", newShape)

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
	
func disable() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.25)
	if visible_sprite:	
		tween.parallel().tween_property(visible_sprite, "scale", Vector2.ZERO, 0.25)
	tween.tween_property(self, "visible", false, 0)
	#visible = fals
	
func _on_detection_area_entered(area: Area2D) -> void:
	if value != -1:
		var tempValue = value
		value = -1
		
		disable()
		
		#Call the player's collect here too as well with the value from this orb
		area.getParent().collect(tempValue, position, enemy_drop, 0) 
		#This needs to connect to tentacle or something since it's an area rather than a body.
		#print("collect")
		#Need to fix this signal
		#print("ORB COLLECT! ", id)
		collect.emit(id)
	

func _on_detection_body_entered(body: Node2D) -> void:
	if value != -1:
		var tempValue = value
		value = -1
		
		disable()
		
		#Call the player's collect here too as well with the value from this orb
		body.collect(tempValue, position, enemy_drop, 0)# w/e
		#print("collect")
		#print("ORB body COLLECT! ", id)
		collect.emit(id)
	
