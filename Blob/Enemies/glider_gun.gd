extends base_creature

const glider_id : int = 4
var current_anim : int = 0
var direction : Vector2 = Vector2.ZERO
var dir : int = 0

@onready var animRef = $InnerNode/Sprite/AnimatedSprite2D

func _ready() -> void:
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
		$InnerNode/Sprite.rotation += direction.angle() - PI/4

func _on_animated_sprite_2d_animation_finished() -> void:
	current_anim += 1
	if current_anim % 14 == 10 || current_anim % 14 == 12:
		_spawnGlider()
		animRef.play("idle")
	elif current_anim % 14 == 9 || current_anim % 14 == 11:
		animRef.play("spawn")
	else:
		animRef.play("idle")

func _spawnGlider() -> void:
	#You might need to add an offset to this later.
	var childGlider = spawnerRef.spawnEntity(glider_id, -1, getPosition())
	childGlider.setParams(self, dir)
	children_list.append(childGlider)
	
