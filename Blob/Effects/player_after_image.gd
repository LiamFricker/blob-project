extends Node2D

@export var empty_player_sprite : PackedScene

@export var trail_color: Color = Color8(0, 225, 255, 200)
#@export 
var trail_decay: float = 1.5
var trail_interval: float = 0.1
var trail_number: int = 999
var trailing: bool = false

var playerRef : Node2D
var trail_tween
var offset : Vector2 = Vector2.ZERO

func addOffset(newoff : Vector2) -> void:
	offset += newoff

#Trail number is a mechanic from Dyscrasia where you'd have limited amounts of trails since move abilities would be quick.
func trailCreate(td : float = 1.5, ti : float = 0.1, tc : int = 0, tn : int = 999) -> void:
	match tc:
		0:
			#Waddle
			trail_color = Color8(214, 172, 19, 150)
			
		1:
			#Board
			trail_color = Color8(0, 225, 255, 200)
		2:
			#Frog
			trail_color = Color8(74, 255, 125, 180) #(0, 255, 132, 150)
		3:
			#Pink
			trail_color = Color8(255, 0, 108, 150)
		_:
			#Orange
			trail_color = Color8(0, 225, 255, 200)
			trail_color = Color8(255, 0, 108, 150)
			
	
	trail_decay = td
	trail_interval = ti
	trail_number = tn
	_trailStart()

func addTrailPart() -> void:
	#Normally it's better to just duplicate this but my smart ass wanted to use a funny viewport texture so now we can't.
	#Make sure you do the duplicate if you copy this over to other stuff.
	var tempChild : Node2D = empty_player_sprite.instantiate()#(playerRef.getSpriteDuplicate()).duplicate()
	tempChild.modulate = trail_color
	tempChild.get_child(1).texture = null
	tempChild.position = playerRef.getPosition() - offset
	tempChild.rotation = playerRef.getRotation()
	tempChild.scale = playerRef.getScale()
	add_child(tempChild)

func _trailStart() -> void:
	if trail_number > 0:
		trail_number -= 1
		for child in get_children():
			child.modulate = child.modulate.darkened(0.25)
		addTrailPart()
		
	if trail_tween:
		trail_tween.kill()
	trail_tween = create_tween()
	trail_tween.set_parallel()
	var tot_trail_decay = -trail_decay*trail_interval
	for child in get_children():
		if child.modulate.a <= 0.01:
			child.call_deferred("queue_free")
		else:
			trail_tween.tween_property(child, "modulate:a", tot_trail_decay, trail_interval).as_relative()
			trail_tween.tween_property(child, "modulate:a", 0.2*tot_trail_decay, trail_interval).as_relative()
	
	trail_tween.finished.connect(_trailStart)
	
func trailStop() -> void:
	if trail_tween:
		trail_tween.kill()
	trail_tween = create_tween()
	trail_tween.set_parallel()
	for child in get_children():
		trail_tween.tween_property(child, "modulate:a", -1.0, 10*trail_interval).as_relative()
	trail_tween.finished.connect(_freeTrail)

func _freeTrail() -> void:
	for child in get_children():
		child.call_deferred("queue_free")
