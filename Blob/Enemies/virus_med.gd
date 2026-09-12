extends "res://Blob/Enemies/base_common_creature.gd"

func _setCollisionAndSuch() -> void:
	
	$InnerNode/Sprite/InnerSprite.scale = size * Vector2.ONE
	$InnerNode/Sprite/Attachments.scale = size * Vector2.ONE
	
	var tempShape = RectangleShape2D.new()
	tempShape.size = size * Vector2(66.0, 108.0)
	$InnerNode/Hurtbox/CollisionShape2D.set_deferred("shape", tempShape)
	$InnerNode/Hurtbox/CollisionShape2D.set_deferred("position", size*Vector2(1,-1))
	
	tempShape = CircleShape2D.new()
	tempShape.radius = size * 120
	$InnerNode/Detection/CollisionShape2D.set_deferred("shape", tempShape)
	$InnerNode/Detection/CollisionShape2D.set_deferred("position", size*Vector2(0,177.0))
	
	tempShape = CircleShape2D.new()
	tempShape.radius = size * 12
	$InnerNode/Weakpoint/CollisionShape2D.set_deferred("shape", tempShape)
	$InnerNode/Weakpoint.set_deferred("position", size*Vector2(0,-52.0))
	$InnerNode/Weakpoint/Polygon2D.scale = size * Vector2(12,12)
	
	tempShape = CircleShape2D.new()
	tempShape.radius = size * 14.04
	$InnerNode/FeedingBox/CollisionShape2D.set_deferred("shape", tempShape)
	
	tempShape = CircleShape2D.new()
	tempShape.radius = size * 28.02
	$InnerNode/Hitbox/CollisionShape2D.set_deferred("shape", tempShape)
	$InnerNode/Hitbox/CollisionShape2D2.set_deferred("shape", tempShape)
	$InnerNode/Hitbox/CollisionShape2D.set_deferred("position", size*Vector2(1,21.0))
	$InnerNode/Hitbox/CollisionShape2D2.set_deferred("position", size*Vector2(1,-20.0))
	
