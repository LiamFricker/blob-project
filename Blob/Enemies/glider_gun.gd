extends base_creature

@export var test_glider : PackedScene

const glider_id : int = 4
var current_anim : int = 0
var direction : Vector2 = Vector2.ZERO
var dir : int = 0

@onready var animRef = $InnerNode/Sprite/AnimatedSprite2D
@export var shadMat = preload("res://Blob/Enemies/base_creature_material.tres")

func _ready() -> void:
	shadMat = shadMat.duplicate()
	$InnerNode/Sprite/AnimatedSprite2D.material = shadMat
	if direction == Vector2.ZERO:
		var dir_rng = RandomNumberGenerator.new()
		dir = dir_rng.randi_range(0, 7)
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


func _on_animated_sprite_2d_animation_finished() -> void:
	current_anim += 1
	if current_anim % 14 == 7 || current_anim % 14 == 9:
		_spawnGlider()
		animRef.play("idle")
	elif current_anim % 14 == 6 || current_anim % 14 == 8:
		animRef.play("spawn")
	else:
		animRef.play("idle")

func _spawnGlider() -> void:
	#You might need to add an offset to this later.
	if spawnerRef:
		var childGlider = spawnerRef.spawnEntity(glider_id, -1, getPosition())
		childGlider.setParams(self, dir)
		_addConnectChild(childGlider)
	else:
		var childGlider = test_glider.instantiate()
		childGlider.position = getPosition()
		childGlider.setParams(self, dir)
		_addConnectChild(childGlider)
	
