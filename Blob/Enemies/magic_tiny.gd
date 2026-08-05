extends base_creature

@onready var magic_rng = RandomNumberGenerator.new() 

var move_dir : Vector2
const base_range : int = 500
@export var speed : float = 10
var speed_mod = 1.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	Inner.position += speed * speed_mod * delta * move_dir

func _on_run_timer_timeout() -> void:
	var targetLen = Inner.position.length()
	var targetAngle = Inner.position.angle()
	#Angle facing towards spawn
	if targetLen > base_range and magic_rng.randi_range(0, targetLen) > base_range:
		var newAngle = (targetAngle + PI) - PI * (-0.5 + magic_rng.randf())
		move_dir = Vector2.from_angle(newAngle)
	#Any angle
	else:
		var newAngle = TAU * magic_rng.randf()
		move_dir = Vector2.from_angle(newAngle)
	speed_mod = 0.5
	$AnimationPlayer.play("jump", 0.2)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "jump":
		speed_mod = 1.0
		$AnimationPlayer.play("run")

#Need to let it add one of these here. Code it later. 
"""
func _on_detection_area_entered(area: Area2D) -> void:
	#Call the player's collect here too as well with the value from this orb
	area.getParent().collect(value, position, enemy_drop, 0) 
	#This needs to connect to tentacle or something since it's an area rather than a body.
	#print("collect")
	#Need to fix this signal
	collect.emit(id)
	disable()

func _on_detection_body_entered(body: Node2D) -> void:
	#Call the player's collect here too as well with the value from this orb
	body.collect(value, position, enemy_drop, 0)# w/e
	#print("collect")
	collect.emit(id)
	disable()

"""
