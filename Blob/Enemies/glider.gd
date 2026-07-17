extends base_creature



#	Glider
#	Very Simple Object. Moves in one direction and that's it.

#Direction from 1-8
var direction : Vector2 = Vector2.ZERO
@export var speed = 1
@export var shadMat : ShaderMaterial = preload("res://Blob/Enemies/base_creature_material.tres")

func setParams(parRef, dir = 0) -> void:
	parentRef = parRef
	isChild = true
	match dir:
		0:
			direction = Vector2.UP
		1:
			direction = Vector2(-0.71, -0.71)
		2:
			direction = Vector2.LEFT
		3:
			direction = Vector2(-0.71, 0.71)
		4:
			direction = Vector2.DOWN
		5:
			direction = Vector2(0.71, 0.71)
		6:
			direction = Vector2.RIGHT
		7:
			direction = Vector2(0.71, -0.71)
	$InnerNode/Sprite.rotation += direction.angle()# - PI/4
	$Lifetime.autostart = true
	
func _handleRedFlash() -> void:
	#print("this triggered")
	$InnerNode/Sprite/AnimatedSprite2D.material.set_shader_parameter("end_color", Color(1,0,0))
	var tempMod = $InnerNode/Sprite/AnimatedSprite2D.material.get_shader_parameter("progress")
	movement_tween.parallel().tween_method(_updateSpriteModulate, tempMod, 0.5, 0.25)
	movement_tween.tween_method(_updateSpriteModulate, tempMod, 0.0, 0.25)

func _handleRedDeath() -> void:
	#print("this triggered")
	$InnerNode/Sprite/AnimatedSprite2D.material.set_shader_parameter("end_color", Color(1,0,0))
	var tempMod = $InnerNode/Sprite/AnimatedSprite2D.material.get_shader_parameter("progress")
	dot_tween.tween_method(_updateSpriteModulate, tempMod, 0.5, 0.5)
	dot_tween.parallel().tween_property(self, "modulate:a", 0.0, 1.0)

func _updateSpriteModulate(progress: float) -> void:
	$InnerNode/Sprite/AnimatedSprite2D.material.set_shader_parameter("progress", progress)

func _ready() -> void:
	shadMat = shadMat.duplicate()
	$InnerNode/Sprite/AnimatedSprite2D.material = shadMat
	if direction == Vector2.ZERO:
		var dir_rng = RandomNumberGenerator.new()
		var dir = dir_rng.randi_range(0, 7)
		match dir:
			0:
				direction = Vector2.UP
			1:
				direction = Vector2(-0.71, -0.71)
			2:
				direction = Vector2.LEFT
			3:
				direction = Vector2(-0.71, 0.71)
			4:
				direction = Vector2.DOWN
			5:
				direction = Vector2(0.71, 0.71)
			6:
				direction = Vector2.RIGHT
			7:
				direction = Vector2(0.71, -0.71)
		$InnerNode/Sprite.rotation += direction.angle()# - PI/4

func _process(delta: float) -> void:
	#while state != IDLE:
	Inner.position += speed * direction

func _on_lifetime_timeout() -> void:
	if oscillate_tween:
		oscillate_tween.kill()
	oscillate_tween = create_tween()
	oscillate_tween.tween_property(self, "modulate", Color(0,0,0,0), 0.5)
	orb_reward -= 1
	oscillate_tween.finished.connect(_OnDeath)
