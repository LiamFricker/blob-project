extends base_creature

var targetRef : Node2D
var targetFound : bool = false
@export var detection_range : float = 200 

const bullet_id = 1000

var mimi_tween
@onready var mimi_rng = RandomNumberGenerator.new()
@export var shoot_cooldown = 5.0

@export var test_bullet : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var newShape = CircleShape2D.new()
	newShape.radius = detection_range
	$InnerNode/DetectionRange/CollisionShape2D.set_deferred("shape", newShape)

func _on_detection_range_area_entered(area: Area2D) -> void:
	pass # Replace with function body.

func _on_detection_range_body_entered(body: Node2D) -> void:
	if kb_moving:
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
	var detectNode = $InnerNode/DetectionRange
	if (detectNode.has_overlapping_areas() or detectNode.has_overlapping_bodies()):
		var localAreas = detectNode.get_overlapping_areas()
		for a in localAreas:
			_on_detection_range_area_entered(a)
		
		var localBodies = detectNode.get_overlapping_bodies()
		for b in localBodies:
			_on_detection_range_body_entered(b)

func _startShoot() -> void:
	var targetPos = targetRef.getPosition()
	var targetAngle = getPosition().angle_to_point(targetPos)
	
	if getPosition().distance_squared_to(targetPos) > detection_range * detection_range * 2.25:
		targetRef = null
		if mimi_tween:
			mimi_tween.kill()
		return
	
	Sprite.position.y = 0
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	movement_tween.tween_property(Sprite, "position:y", -3, 0.1).as_relative().set_delay(0.75)
	movement_tween.tween_property(Sprite, "position:y", 6, 0.2).as_relative()
	movement_tween.tween_property(Sprite, "position:y", -6, 0.2).as_relative()
	movement_tween.tween_property(Sprite, "position:y", 3, 0.1).as_relative()
	
	var angle_diff = angle_difference(targetAngle, Inner.rotation + PI/4)
	
	if mimi_tween:
		mimi_tween.kill()
	mimi_tween = create_tween()
	mimi_tween.tween_property(Inner, "rotation", angle_diff, 1.0).as_relative()
	mimi_tween.parallel().tween_callback(_shootProj).set_delay(0.75)
	for i in range(5):
		mimi_tween.tween_callback(_shootProj).set_delay(0.1)
	mimi_tween.tween_interval(shoot_cooldown)
	mimi_tween.finished.connect(_startShoot)

func _shootProj() -> void:
	var rand_angle = mimi_rng.randf_range(-0.1, 0.1)
	if spawnerRef:
		var bullet = spawnerRef.spawnEntity(bullet_id, -1, getPosition())
		bullet.setParams(Inner.rotation + rand_angle, self, base_damage, size)
		_addConnectChild(bullet)
	else:
		var bullet = test_bullet.instantiate()
		bullet.position = getPosition()
		bullet.setParams(Inner.rotation + rand_angle, self, base_damage, size)
		_addConnectChild(bullet)
	
func _on_hurtbox_area_entered(area: Area2D) -> void:
	var areaID = area.getID()
	if areaID == ID:
		return
	
	var shieldBox = $InnerNode/ShieldBox
	if (shieldBox.has_overlapping_areas() or shieldBox.has_overlapping_bodies()):
		var ID_list = []
		var localAreas = shieldBox.get_overlapping_areas()
		for a in localAreas:
			ID_list.append(a.getID())
		
		var localBodies = shieldBox.get_overlapping_bodies()
		for b in localBodies:
			ID_list.append(b.getID())
		#Play shielded animation
		if areaID in ID_list:
			pass
		else:
			if movement_tween:
				movement_tween.kill()
			if mimi_tween:
				mimi_tween.kill()
			super(area)
			
	else:
		if movement_tween:
			movement_tween.kill()
		if mimi_tween:
			mimi_tween.kill()
		super(area)
		

func _on_hurtbox_body_entered(body: Node2D) -> void:
	var bodyID = body.getID()
	if bodyID == ID:
		return
	
	var shieldBox = $InnerNode/ShieldBox
	if (shieldBox.has_overlapping_areas() or shieldBox.has_overlapping_bodies()):
		var ID_list = []
		var localAreas = shieldBox.get_overlapping_areas()
		for a in localAreas:
			ID_list.append(a.getID())
		
		var localBodies = shieldBox.get_overlapping_bodies()
		for b in localBodies:
			ID_list.append(b.getID())
		#Play shielded animation
		if bodyID in ID_list:
			pass
		else:
			if movement_tween:
				movement_tween.kill()
			if mimi_tween:
				mimi_tween.kill()
			super(body)
			
	else:
		if movement_tween:
			movement_tween.kill()
		if mimi_tween:
			mimi_tween.kill()
		super(body)
