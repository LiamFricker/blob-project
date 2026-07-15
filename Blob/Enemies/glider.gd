extends base_creature



#	Glider
#	Very Simple Object. Moves in one direction and that's it.

#Direction from 1-8
var direction : Vector2 = Vector2.ZERO
@export var speed = 10

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
	$Lifetime.autostart = true

func _ready() -> void:
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
		$InnerNode/Sprite.rotation += direction.angle() - PI/4

func _process(delta: float) -> void:
	while state != IDLE:
		Inner.position += speed * direction

func _on_lifetime_timeout() -> void:
	if oscillate_tween:
		oscillate_tween.kill()
	oscillate_tween = create_tween()
	oscillate_tween.tween_property(self, "modulate", Color(0,0,0,0), 0.5)
	oscillate_tween.finished.connect(_OnDeath)
