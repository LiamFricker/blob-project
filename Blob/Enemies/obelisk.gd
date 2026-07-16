extends base_creature

@export var rotation_speed : float = 1.0
var topTaken : bool = false
const piece_id = 7
@export var test_part : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	Inner.rotation += delta * rotation_speed

#Override the function and remove its ability to spawn orbs.
func _spawnOrbs(orb_amt = 0) -> void:
	return

func takeDamage(amt : float, pos = Vector2.ZERO, _kwargs = []) -> void:
	breakPiece(pos)
	
func _on_hurtbox_area_entered(area: Area2D) -> void:
	var temp_enemy = area.getParent()
	var posDiff = getPosition() - temp_enemy.getPosition() 
	breakPiece(posDiff)

func _on_hurtbox_body_entered(body: Node2D) -> void:
	var posDiff = getPosition() - body.getPosition() 
	breakPiece(posDiff)

#Invul Timer
func _renableHurtbox() -> void:
	$InnerNode/Hurtbox.set_deferred("monitoring", true)
	
func breakPiece(posDiff) -> void:
	$InnerNode/Hurtbox.set_deferred("monitoring", false)
	
	var InnerRot = $InnerNode.rotation
	var isTop : bool
	var spinDir : int
	
	#if abs(InnerRot) < PI/2:
	isTop = posDiff.y <= 0
	spinDir = 1 if posDiff.x > 0 else -1
	#else:
	#	isTop = posDiff.y > 0  
	#	spinDir = -1 if posDiff.x > 0 else 1 
	
	var dir_len : float = posDiff.length()
	
	var end_dir = 7500.0*posDiff.normalized()/dir_len
	var rot_speed = 0.1*dir_len * spinDir
	
	if health == 1:
		if topTaken:
			spawnPiece(Vector2(48 * sin(InnerRot), 48 * cos(InnerRot)), -1.5*rot_speed, end_dir)
		else:
			spawnPiece(Vector2(-48 * sin(InnerRot), -48 * cos(InnerRot)), -1.5*rot_speed, end_dir)
		spawnPiece(Vector2.ZERO, rot_speed, -1.25 * end_dir)
		
		_OnDeath()
		
		#get_tree().create_timer(12.0).timeout.connect(_OnDeath)
	else:
		$InnerNode/Sprite/Sprite2D.scale = Vector2(1,1)
		var rectShape = RectangleShape2D.new()
		rectShape.size = Vector2(20, 70)
		$InnerNode/Hurtbox/CollisionShape2D.set_deferred("shape", rectShape)
		$InnerNode/Hitbox/CollisionShape2D.set_deferred("shape", rectShape)
		
		#Test if adding rotation_speed to the rotation part makes any difference
		if isTop: 
			spawnPiece(Vector2(-48 * sin(InnerRot), -48 * cos(InnerRot)), rot_speed, end_dir)
			$InnerNode/Sprite/Body.polygon = [Vector2(0,32), Vector2(32,32), Vector2(32,96), Vector2(0,96)]
			$InnerNode/Sprite/Sprite2D.position = Vector2(16, 64)
			$InnerNode/Sprite/Reds/Polygon2D.polygon = [Vector2(0,32), Vector2(12,32), Vector2(12,96), Vector2(0,96)]
			$InnerNode/Sprite/Greens/Polygon2D.polygon = [Vector2(0,32), Vector2(12,32), Vector2(12,96), Vector2(0,96)]
			$InnerNode/Hurtbox.position = Vector2(-16, -32)
			$InnerNode/Hitbox.position = Vector2(-16, -32)
			
		else:
			spawnPiece(Vector2(48 * sin(InnerRot), 48 * cos(InnerRot)), rot_speed, end_dir)
			$InnerNode/Sprite/Body.polygon = [Vector2(0,0), Vector2(32,0), Vector2(32,64), Vector2(0,64)]
			$InnerNode/Sprite/Sprite2D.position = Vector2(16, 32)
			$InnerNode/Sprite/Reds/Polygon2D.polygon = [Vector2(0,0), Vector2(12,0), Vector2(12,64), Vector2(0,64)]
			$InnerNode/Sprite/Greens/Polygon2D.polygon = [Vector2(0,0), Vector2(12,0), Vector2(12,64), Vector2(0,64)]
			$InnerNode/Hurtbox.position = Vector2(-16, -64)
			$InnerNode/Hitbox.position = Vector2(-16, -64)
			
		topTaken = isTop
		health -= 1
		rotation_speed *= 2
		get_tree().create_timer(1.5).timeout.connect(_renableHurtbox)

func spawnPiece(offset : Vector2, rot_speed : float, direction : Vector2) -> void:
	if spawnerRef:
		var childPiece = spawnerRef.spawnEntity(piece_id, -1, getPosition() + offset)
		childPiece.setParams($InnerNode.rotation, rot_speed, direction, self, size)
		_addConnectChild(childPiece)
	else:
		var childPiece = test_part.instantiate()
		childPiece.position = getPosition() + offset
		childPiece.setParams($InnerNode.rotation, rot_speed, direction, self, size)
		_addConnectChild(childPiece)
	
