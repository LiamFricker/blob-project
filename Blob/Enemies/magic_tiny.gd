extends base_creature

@onready var magic_rng = RandomNumberGenerator.new() 

var move_dir : Vector2
const base_range : int = 500
const speed : float = 100

func _ready() -> void:
	_on_run_timer_timeout()

func _on_run_timer_timeout() -> void:
	var targetLen = Inner.position.length()
	var targetAngle = Inner.position.angle()
	var newAngle
	#Angle facing towards spawn
	if targetLen > base_range and magic_rng.randi_range(0, targetLen) > base_range:
		newAngle = (targetAngle + PI) - PI * (-0.5 + magic_rng.randf())
	#Any angle
	else:
		newAngle = TAU * magic_rng.randf()
	move_dir = Vector2.from_angle(newAngle)
	if abs(newAngle) < PI/2 or abs(newAngle) > 1.5 * PI: 
		$InnerNode/Sprite/Front.scale.x = -1
		$InnerNode/Sprite/Back.scale.x = -1
	else:
		$InnerNode/Sprite/Front.scale.x = 1
		$InnerNode/Sprite/Back.scale.x = 1
	
		
	const jump_speed = 1.5
	const jump_offset = 0.25
	var jump_time = (1.25-jump_offset)/jump_speed
		
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	movement_tween.tween_property(Inner, "position", move_dir * speed * 1.25, jump_time).as_relative().set_delay(jump_offset)
	$AnimationPlayer.play("jump", 0.2, jump_speed)
	$InnerNode/Hurtbox.set_deferred("monitoring", false)
	_spawnOrbs(1)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "jump":
		if movement_tween:
			movement_tween.kill()
		movement_tween = create_tween()
		movement_tween.tween_property(Inner, "position", move_dir * speed * 3.0, 3.0).as_relative()
		movement_tween.finished.connect(_on_run_timer_timeout)
		$AnimationPlayer.play("run")
		#$RunTimer.start()
		$InnerNode/Hurtbox.set_deferred("monitoring", true)


func _on_hurtbox_area_entered(area: Area2D) -> void:
	print("YOOOO?")
	area.getParent().collect(orb_reward, getPosition(), true, 0)
	#area.getParent().collect(1, getPosition(), true, 1)
	_deathAnim()

func _on_hurtbox_body_entered(body: Node2D) -> void:
	print("YOOOO")
	body.collect(orb_reward, getPosition(), true, 0)
	#body.collect(1, getPosition(), true, 1)
	_deathAnim()

func _deathAnim() -> void:
	toggleHurtbox(false)
	
	$AnimationPlayer.play("RESET", 0.4)
	
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	movement_tween.tween_property(Inner, "position", move_dir*speed*0.5, 0.4).as_relative()
	if oscillate_tween:
		oscillate_tween.kill()
	oscillate_tween = create_tween()
	oscillate_tween.tween_property(Sprite, "scale", Vector2(0,0), 0.4)
	oscillate_tween.parallel().tween_property(self, "modulate", Color(1.0,1.0,1.0,0.0), 0.4)
	oscillate_tween.finished.connect(_OnDeath)
