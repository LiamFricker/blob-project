extends base_creature

var targetRef : Node2D
#var targetFound : bool = false
@export var detection_range : float = 200 

const bullet_id = 9

var mimi_tween
var shield_tween
@onready var mimi_rng = RandomNumberGenerator.new()
@export var shoot_cooldown : float = 1.0
var min_delay = 0.75

@export var test_bullet : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var newShape = CircleShape2D.new()
	newShape.radius = detection_range
	$InnerNode/DetectionRange/CollisionShape2D.set_deferred("shape", newShape)

func _on_detection_range_area_entered(area: Area2D) -> void:
	if not kb_moving and not targetRef and area.getID() != ID:
		targetRef = area.getParent()
		if targetRef.isDead():
			targetRef = null
		else:
			_startShoot()

func _on_detection_range_body_entered(body: Node2D) -> void:
	if not kb_moving and not targetRef and body.getID() != ID:
		if body.isDead():
			return
		targetRef = body
		_startShoot()

func _knockbackEnd() -> void:
	kb_moving = false
	_collisionCheck()
	_detectionCheck()

func _detectionCheck() -> void:
	if targetRef:	
		var targetPos = targetRef.getPosition()
		if getPosition().distance_squared_to(targetPos) <= detection_range * detection_range * 2.25:
			_startShoot()
			return
		targetRef = null
	min_delay = 0.75
	if isDead():
		targetRef = null
		return
		
	var detectNode = $InnerNode/DetectionRange
	if (detectNode.has_overlapping_areas() or detectNode.has_overlapping_bodies()):
		var localAreas = detectNode.get_overlapping_areas()
		for a in localAreas:
			_on_detection_range_area_entered(a)
		
		var localBodies = detectNode.get_overlapping_bodies()
		for b in localBodies:
			_on_detection_range_body_entered(b)

func _startShoot() -> void:
	if not targetRef or targetRef.isDead():
		targetRef = null
		_detectionCheck()
		return
	
	var targetPos = targetRef.getPosition()
	var targetAngle = getPosition().angle_to_point(targetPos)
	
	if getPosition().distance_squared_to(targetPos) > detection_range * detection_range * 2.25:
		targetRef = null
		min_delay = 0.75
		if mimi_tween:
			mimi_tween.kill()
		_detectionCheck()
		return
	
	var angle_diff = -angle_difference(targetAngle, Inner.rotation + PI/2)
	var delay = max(1.5 * abs(angle_diff) / PI, min_delay) 

	Sprite.position.y = 0
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	movement_tween.tween_property(Sprite, "position:y", -3, 0.1).as_relative().set_delay(delay)
	movement_tween.tween_property(Sprite, "position:y", 6, 0.2).as_relative()
	movement_tween.tween_property(Sprite, "position:y", -6, 0.2).as_relative()
	movement_tween.tween_property(Sprite, "position:y", 3, 0.1).as_relative()
	movement_tween.tween_property(Sprite, "position:y", -3, 0.1).as_relative()
	movement_tween.tween_property(Sprite, "position:y", 6, 0.2).as_relative()
	movement_tween.tween_property(Sprite, "position:y", -6, 0.2).as_relative()
	movement_tween.tween_property(Sprite, "position:y", 3, 0.1).as_relative()
	
	
	
	if mimi_tween:
		mimi_tween.kill()
	mimi_tween = create_tween()
	mimi_tween.tween_property(Inner, "rotation", angle_diff, delay).as_relative()
	mimi_tween.parallel().tween_callback(_shootProj).set_delay(delay)
	for i in range(5):
		mimi_tween.tween_callback(_shootProj).set_delay(0.2)
	$AnimationPlayer.play("reload", -1, shoot_cooldown)

func _shootProj() -> void:
	var rand_angle = mimi_rng.randf_range(-0.1, 0.1)
	var offset = 20 * Vector2.from_angle(Inner.rotation+PI/2)
	if spawnerRef:
		var bullet = spawnerRef.spawnEntity(bullet_id, -1, getPosition()+offset)
		bullet.setParams(base_damage, self, size, bullet_id)
		bullet.initBullet(Inner.rotation + rand_angle + PI/2, 5.0)
		_addConnectBullet(bullet)
	else:
		var bullet = test_bullet.instantiate()
		bullet.position = getPosition()+offset 
		bullet.setParams(base_damage, self, size, bullet_id)
		bullet.initBullet(Inner.rotation + rand_angle + PI/2, 5.0)
		_addConnectBullet(bullet)
	
func _on_hurtbox_area_entered(area: Area2D) -> void:
	var areaID = area.getID()
	if areaID == ID:
		return
	var shieldBox = $InnerNode/ShieldBox
	if not area.getAttackMod(0) and (shieldBox.has_overlapping_areas() or shieldBox.has_overlapping_bodies()):
		var ID_list = []
		var localAreas = shieldBox.get_overlapping_areas()
		for a in localAreas:
			ID_list.append(a.getID())
		
		var localBodies = shieldBox.get_overlapping_bodies()
		for b in localBodies:
			ID_list.append(b.getID())
		#Play shielded animation
		if areaID in ID_list:
			if shield_tween:
				shield_tween.kill()
			shield_tween = create_tween()
			shield_tween.tween_property(Sprite, "modulate:r", 0.5, 0.15)#.as_relative()
			shield_tween.tween_property(Sprite, "modulate:r", 1.0, 0.15)#.as_relative()
		else:
			_stopAnims()
			super(area)
			
	else:
		_stopAnims()
		super(area)
		

func _on_hurtbox_body_entered(body: Node2D) -> void:
	var bodyID = body.getID()
	if bodyID == ID:
		return
	
	var shieldBox = $InnerNode/ShieldBox
	if not body.getAttackMod(0) and (shieldBox.has_overlapping_areas() or shieldBox.has_overlapping_bodies()):
		var ID_list = []
		var localAreas = shieldBox.get_overlapping_areas()
		for a in localAreas:
			ID_list.append(a.getID())
		
		var localBodies = shieldBox.get_overlapping_bodies()
		for b in localBodies:
			ID_list.append(b.getID())
		#Play shielded animation
		if bodyID in ID_list:
			if shield_tween:
				shield_tween.kill()
			shield_tween = create_tween()
			shield_tween.tween_property(Sprite, "modulate:r", -0.5, 0.15).as_relative()
			shield_tween.tween_property(Sprite, "modulate:r", 0.5, 0.15).as_relative()
		else:
			_stopAnims()
			super(body)
			
	else:
		_stopAnims()
		super(body)

func _stopAnims() -> void:
	if movement_tween:
		movement_tween.kill()
	if mimi_tween:
		mimi_tween.kill()
	if $AnimationPlayer.is_playing():
		$AnimationPlayer.play("RESET", 0.5)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "reload":
		min_delay = 0.5
		_startShoot()
	
func _OnDeath(pos = Vector2.ZERO, kb = 1.0, _kwargs = []) -> void:
	$InnerNode/DetectionRange.set_deferred("monitoring", false)
	super(pos, kb, _kwargs)
