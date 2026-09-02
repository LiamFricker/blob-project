extends "res://Blob/base_spawned_attack.gd"

var enemy_count = 0
var rusted : bool = false

var speed : float = 0.0
var direction : Vector2 = Vector2(0,-1)

func _process(delta : float) -> void:
	position += direction * delta * speed

func _on_area_entered(area: Area2D) -> void:
	call_deferred("_hitCheck", area.getParent())

func _on_body_entered(body: Node2D) -> void:
	call_deferred("_hitCheck", body)

func _hitCheck(enemyHitQueued : Node2D) -> void:
	if enemyHitQueued.isDead():
		damage *= 2 
		speed *= 1.25
		
		var offset : float
	
		if rusted:
			offset = -size * (9.5 - 10.0 * (enemy_count % 3) + 2.0 * (((enemy_count+2) % 6) - 3))
		else:
			offset = -size * (20.0 - 13.0 * (enemy_count % 3) + 2.0 * (((enemy_count+5) % 6) - 3))
		var tempEne = enemyHitQueued.Sprite.duplicate()
		tempEne.scale = 0.75 * tempEne.scale
		tempEne.position = Vector2(0,offset).rotated(rotation-PI/2) 
		add_child(tempEne)
		
		enemyHitQueued.hide()

func _initSpearProj(isRusted : bool, new_speed : float, rot : float) -> void:	
	direction = Vector2(0,-1).rotated(rot)
	rotation = rot
	speed = new_speed
	
	rusted = isRusted
	
	$Sprite.scale = size * Vector2(1,1)
	var tempShape = RectangleShape2D.new()
	
	if isRusted:
		damage *= 1.25
		speed *= 0.75
		
		tempShape.size = size * Vector2(14.0, 37.0)
		
		$CollisionShape2D.set_deferred("shape", tempShape)
		$CollisionShape2D.set_deferred("disabled", false)
		$CollisionShape2D.set_deferred("position:y", size * -0.5)
		$Sprite/Rust.show()
	else:
		tempShape.size = size * Vector2(10.0, 46.0)
		
		$CollisionShape2D2.set_deferred("shape", tempShape)
		$CollisionShape2D2.set_deferred("disabled", false)
		$CollisionShape2D2.set_deferred("position:y", size * -5)
		$Sprite/Full.show()
	
