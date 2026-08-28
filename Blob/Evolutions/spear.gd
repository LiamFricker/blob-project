extends "res://Blob/Evolutions/base_evo_general.gd"

@export var base_damage : float = 1
@export var damage_mult : float = 1
#@export var size : float = 12

@export var base_intensity : float = 1
@export var dot_mult : float = 1
@export var duration : float = 1


func changeSize(newSize : float) -> void:
	var tempShape = CircleShape2D.new()
	tempShape.radius = 25
	$Hitbox/CollisionShape2D.shape = tempShape

func _on_hitbox_area_entered(area: Area2D) -> void:
	area.getParent().takeDamage(base_damage * damage_mult)

func _on_inject(area: Area2D) -> void:
	area.getParent().applyPoison(base_intensity * dot_mult, duration)

var attacking : bool = false
var detected : bool = false

@export var spear_level : int = 0
@onready var spear_refs = [$Spear1/Left, $Spear2/Left, $Spear3/Left]

@onready var hitbox_ref = $HitboxL

var spear_tween
var rust_tween

@export var rust_max : float = 10.0
var rust_level : float = 0.0

@export var rust_recovery_speed : float = 1.0

@export var startspearColor : Color
@export var endspearColor : Color

@export var pinch_cooldown : float = 2.0

signal spawnRustParticle(partID : int, rust_pos : Vector2, totalRot : float, size : float, kwargs : Array)

func _ready() -> void:
	var spear_temp = spear_level
	spear_level = 0
	setspearLevel(spear_temp)
	super()

func addspearLevel() -> void:
	if spear_level == 2:
		setspearLevel(0)
	else:
		setspearLevel(spear_level+1)

func setspearLevel(newBL : int) -> void:
	match spear_level:
		0:
			$Hitbox/CollisionShape2D.set_deferred("disabled", true)
			#$Hitbox/CollisionShape2D.set_deferred("disabled", true)
			$Detection/CollisionShape2D.set_deferred("disabled", true)
			if not attacking:
				$Spear1.hide()
			$Spear1/Rusted.position.y = 2
			$Spear1/Rusted.modulate.a = 0.0
			$Spear1/Rusted.position.y = 2
		1:
			$Hitbox/CollisionShape2D2.set_deferred("disabled", true)
			$Hitbox/CollisionShape2D2.set_deferred("disabled", true)
			#$Hitbox/CollisionShape2D2.set_deferred("disabled", true)
			$Detection/CollisionShape2D2.set_deferred("disabled", true)
			if not attacking:
				$Spear2.hide()
			$Spear2/Rusted.position.y = 2
			$Spear2/Rusted.modulate.a = 0.0
			$Spear2/Rusted.rotation = 0.0
		2:
			$Hitbox/CollisionShape2D3.set_deferred("disabled", true)
			$Hitbox/CollisionShape2D3.set_deferred("disabled", true)
			#$Hitbox/CollisionShape2D3.set_deferred("disabled", true)
			$Detection/CollisionShape2D3.set_deferred("disabled", true)
			if not attacking:
				$Spear3.hide()
			$Spear3/Rusted.position.y = 2
			$Spear3/Rusted.modulate.a = 0.0
			$Spear3/Rusted.rotation = 0.0
	
	spear_refs[spear_level].modulate = startspearColor
	hitbox_ref.set_deferred("monitorable", true)
	
	spear_level = newBL
	rust_level = 0.0
	
	if rust_tween:
		rust_tween.kill()
	
	if not detected:
		match spear_level:
			0:
				$Hitbox/CollisionShape2D.set_deferred("disabled", false)
				$Hitbox/CollisionShape2D.set_deferred("disabled", false)
				#$Hitbox/CollisionShape2D.set_deferred("disabled", false)
				$Detection/CollisionShape2D.set_deferred("disabled", false)
				if not attacking:	
					$Spear1.show()
			1:
				$Hitbox/CollisionShape2D2.set_deferred("disabled", false)
				$Hitbox/CollisionShape2D2.set_deferred("disabled", false)
				#$Hitbox/CollisionShape2D2.set_deferred("disabled", false)
				$Detection/CollisionShape2D2.set_deferred("disabled", false)
				if not attacking:
					$Spear2.show()
			2:
				$Hitbox/CollisionShape2D3.set_deferred("disabled", false)
				$Hitbox/CollisionShape2D3.set_deferred("disabled", false)
				#$Hitbox/CollisionShape2D3.set_deferred("disabled", false)
				$Detection/CollisionShape2D3.set_deferred("disabled", false)
				if not attacking:	
					$Spear3.show()
	
	

func _on_detection_area_entered(area: Area2D) -> void:
	if not detected and not attacking:
		if area.getID() != 0:
			if rust_level < rust_max:
				detected = true
				_pinch()
		

func _on_detection_body_entered(body: Node2D) -> void:
	if not detected and not attacking:
		if body.getID() != 0:
			detected = true
			if rust_level < rust_max:
				_pinch()

func _detectionCheck() -> void:
	var detectNode = $Detection
	
	if (detectNode.has_overlapping_areas() or detectNode.has_overlapping_bodies()):
		if not attacking:
			detected = true
			if rust_level < rust_max:
				_pinch()
	detected = false

func _BLtoColShape(BL : int) -> CollisionShape2D:
	match BL:
		0:
			return $Hitbox/CollisionShape2D
		1:
			return $Hitbox/CollisionShape2D2
		_:
			return $Hitbox/CollisionShape2D3

func _toggle(toggle : bool) -> void:
	if rust_level < rust_max: #not toggle or 
		#hitbox_ref.set_deferred("monitoring", toggle)
		hitbox_ref.set_deferred("monitorable", toggle)

func _pinch() -> void:
	print("pinch")
	var pinch_time = 0.6
	
	_BLtoColShape(spear_level).set_deferred("disabled", false)
	#_toggle(false)
	
	if spear_tween:
		spear_tween.kill()
	spear_tween = create_tween().set_parallel()
	if rust_level < rust_max:
		spear_tween.tween_property(spear_refs[spear_level], "scale:y", 1.2, pinch_time)
		spear_tween.tween_property(spear_refs[spear_level], "rotation", PI/4, pinch_time)
		spear_tween.tween_property(spear_refs[spear_level], "rotation", 0, pinch_time).set_delay(pinch_time)
		spear_tween.tween_property(spear_refs[spear_level], "scale:y", 1.0, pinch_time).set_delay(pinch_time)

	
	#var spear_temp = spear_level
	spear_tween.finished.connect(_pinchEnd.bind(spear_level))#spear_temp))

func _pinchEnd(BL : int) -> void:
	_BLtoColShape(BL).set_deferred("disabled", true)
	#_toggle(true)
	$PinchCooldown.start(pinch_cooldown)
	
func _on_pinch_cooldown_timeout() -> void:
	_detectionCheck()

func attack(temp : float, charge_cd : float) -> void:
	
	if not attacking and rust_level < rust_max:
		attacking = true
		
		var charge_time : float = min(0.3 * charge_cd, 0.45)
		var swipe_time : float = min(0.2 * charge_cd, 0.3)
		var return_time : float = min(0.5 * charge_cd, 0.75)
		var spearLen = max(2.0 * temp/6.0, 1.5) 
		
		var posChange 
		match spear_level:
			0:
				posChange = 9*size
			1:
				posChange = 14*size
			2:
				posChange = 17*size

		if spear_tween:
			spear_tween.kill()
		spear_tween = create_tween().set_parallel()
		
		spear_tween.tween_property(spear_refs[spear_level], "scale:y", spearLen, charge_time)
		spear_tween.tween_property(spear_refs[spear_level], "position:x", posChange, swipe_time).as_relative()
		spear_tween.tween_property(spear_refs[spear_level], "rotation", -PI/8, charge_time)
		spear_tween.tween_property(spear_refs[spear_level], "rotation", PI/4, swipe_time).set_delay(charge_time)
		spear_tween.tween_property(spear_refs[spear_level], "position:x", -0, charge_time).as_relative().set_delay(charge_time)
		spear_tween.tween_property(spear_refs[spear_level], "rotation", 0, return_time).set_delay(return_time)
		spear_tween.tween_property(spear_refs[spear_level], "scale:y", 1.0, return_time).set_delay(return_time)
		
		
		#var spear_temp = spear_level
		spear_tween.finished.connect(_attackEnd.bind(spear_level))#spear_temp))
		
		_colShapeIncrease(spear_level, spearLen)
		_BLtoColShape(spear_level).set_deferred("disabled", false)
		

func _attackEnd(BL : int) -> void:
	if BL != spear_level:
		match BL:
			0:
				$Spear1.hide()
			1:
				$Spear2.hide()
			2:
				$Spear3.hide()
		match spear_level:
			0:
				$Spear1.show()
			1:
				$Spear2.show()
			2:
				$Spear3.show()
	
	attacking = false
	_BLtoColShape(BL).set_deferred("disabled", true)
	_colShapeReset(BL)
	if detected:
		_detectionCheck()

func _colShapeIncrease(BL : int, inc : float) -> void:
	var tempShape = CircleShape2D.new()
	var abs_size = size * inc
	match BL:
		0:
			tempShape.radius = 20 * abs_size
			$Hitbox/CollisionShape2D.set_deferred("shape", tempShape)
			$Hitbox/CollisionShape2D.set_deferred("position:y", -22*abs_size)
		1:
			tempShape.radius = 26 * abs_size
			$Hitbox/CollisionShape2D2.set_deferred("shape", tempShape)
			$Hitbox/CollisionShape2D2.set_deferred("position:y", -26*abs_size)
		2:
			tempShape.radius = 32 * abs_size
			$Hitbox/CollisionShape2D3.set_deferred("shape", tempShape)
			$Hitbox/CollisionShape2D3.set_deferred("position:y", -34*abs_size)

func _colShapeReset(BL : int) -> void:
	var tempShape = CircleShape2D.new()
	match BL:
		0:
			tempShape.radius = 20 * size
			$Hitbox/CollisionShape2D.set_deferred("shape", tempShape)
			$Hitbox/CollisionShape2D.set_deferred("position:y", -22*size)
		1:
			tempShape.radius = 26 * size
			$Hitbox/CollisionShape2D2.set_deferred("shape", tempShape)
			$Hitbox/CollisionShape2D2.set_deferred("position:y", -26*size)
		2:
			tempShape.radius = 32 * size
			$Hitbox/CollisionShape2D3.set_deferred("shape", tempShape)
			$Hitbox/CollisionShape2D3.set_deferred("position:y", -34*size)


func _setSize() -> void:
	var sizeVec = size * Vector2(1,1)
	$Spear1.scale = sizeVec
	$Spear2.scale = sizeVec
	$Spear3.scale = sizeVec
	
	if attacking:
		var tempShape = CircleShape2D.new()
		tempShape.radius = 20 * size
		$Detection/CollisionShape2D.set_deferred("shape", tempShape)
		$Detection/CollisionShape2D.set_deferred("position:y", -22*size)
		
		tempShape = CircleShape2D.new()
		tempShape.radius = 26 * size
		$Detection/CollisionShape2D2.set_deferred("shape", tempShape)
		$Detection/CollisionShape2D2.set_deferred("position:y", -26*size)
		
		tempShape = CircleShape2D.new()
		tempShape.radius = 32 * size
		$Detection/CollisionShape2D3.set_deferred("shape", tempShape)
		$Detection/CollisionShape2D3.set_deferred("position:y", -34*size)
	else:
		var tempShape = CircleShape2D.new()
		tempShape.radius = 20 * size
		$Hitbox/CollisionShape2D.set_deferred("shape", tempShape)
		$Hitbox/CollisionShape2D.set_deferred("position:y", -22*size)
		$Detection/CollisionShape2D.set_deferred("shape", tempShape)
		$Detection/CollisionShape2D.set_deferred("position:y", -22*size)
		
		tempShape = CircleShape2D.new()
		tempShape.radius = 26 * size
		$Hitbox/CollisionShape2D2.set_deferred("shape", tempShape)
		$Hitbox/CollisionShape2D2.set_deferred("position:y", -26*size)
		$Detection/CollisionShape2D2.set_deferred("shape", tempShape)
		$Detection/CollisionShape2D2.set_deferred("position:y", -26*size)
		
		tempShape = CircleShape2D.new()
		tempShape.radius = 32 * size
		$Hitbox/CollisionShape2D3.set_deferred("shape", tempShape)
		$Hitbox/CollisionShape2D3.set_deferred("position:y", -34*size)
		$Detection/CollisionShape2D3.set_deferred("shape", tempShape)
		$Detection/CollisionShape2D3.set_deferred("position:y", -34*size)
	
	var tempRect = RectangleShape2D.new()
	tempRect.size = size * Vector2(14.0, 38.0)
	$Hitbox/CollisionShape2D.set_deferred("shape", tempRect)
	$Hitbox/CollisionShape2D.set_deferred("position", Vector2(-15,-19)*size)
	
	tempRect = RectangleShape2D.new()
	tempRect.size = size * Vector2(16.0, 46.0)
	$Hitbox/CollisionShape2D2.set_deferred("shape", tempRect)
	$Hitbox/CollisionShape2D2.set_deferred("position", Vector2(-18,-23)*size)
	
	tempRect = RectangleShape2D.new()
	tempRect.size = size * Vector2(20.0, 60.0)
	$Hitbox/CollisionShape2D3.set_deferred("shape", tempRect)
	$Hitbox/CollisionShape2D3.set_deferred("position", Vector2(-20,-30)*size)

func _damagedEnemy(amt : float) -> void:
	super(amt)
	_handleRust(amt)

func _handleRust(amt : float) -> void:
	if rust_level < rust_max:
		rust_level += 1.0 * amt
		var rust_length = 1.5 * min(amt / rust_max, 1.0)
		var rust_level_diff = min(rust_level / rust_max, 1.0)
		var end_rust_color = startspearColor.lerp(endspearColor, rust_level_diff)
		
		if rust_tween:
			rust_tween.kill()
		rust_tween = create_tween()
		rust_tween.tween_property(spear_refs[spear_level], "modulate", end_rust_color, rust_length)
		if rust_level < rust_max:
			rust_tween.tween_interval(1.0 / rust_recovery_speed)
			rust_tween.finished.connect(_deRust)
		else:
			rust_tween.finished.connect(_Rusted)
			#hitbox_ref.set_deferred("monitoring", false)
			hitbox_ref.set_deferred("monitorable", false)
			hitbox_ref.hide()

func _Rusted() -> void:
	#hitbox_ref.set_deferred("monitorable", false)
	#$AnimationPlayer.play("removeRustLeft", -1, rust_recovery_speed)
	
	var rustNode : Node2D
	var rustOffset : float
	match spear_level:
		0:
			rustNode = $Spear1/RustedL
			rustOffset = -8.5
		1:
			rustNode = $Spear2/RustedL
			rustOffset = -10.0
		2:
			rustNode = $Spear3/RustedL 
			rustOffset = -12.0
	
	var derust_start = 1.0 
	var derust_time = 12.55 / rust_recovery_speed
	var derust_interval = 0.1
	var derust_end = 0.75 # *2 
	var derust_end_end = 0.6
	
	#var startColor : Color = startspearColor
	#startColor.a = 0.0
	if rust_tween:
		rust_tween.kill()
	rust_tween = create_tween()
	rust_tween.tween_property(spear_refs[spear_level], "modulate:a", 0.0, derust_start)
	rust_tween.parallel().tween_property(rustNode, "modulate:a", 1.0, derust_start)
	rust_tween.tween_property(spear_refs[spear_level], "scale", Vector2(0.0,0.0), derust_time)
	rust_tween.tween_property(spear_refs[spear_level], "modulate", startspearColor, derust_interval)
	rust_tween.tween_property(spear_refs[spear_level], "scale", Vector2(0.5,0.25), derust_end)
	rust_tween.parallel().tween_property(rustNode, "position:y", rustOffset, derust_end).as_relative()
	rust_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	rust_tween.tween_property(spear_refs[spear_level], "scale", Vector2(1.0,1.0), derust_end_end)
	rust_tween.parallel().tween_property(rustNode, "position:y", 5*rustOffset, derust_end_end).as_relative()
	rust_tween.parallel().tween_property(rustNode, "rotation", 2.0, derust_end_end)
	rust_tween.finished.connect(_fullDeRust.bind(rustNode))

func _fullDeRust(rustNode : Node2D) -> void:
	rustNode.modulate.a = 0.0
	rustNode.position.y = 2
	var tempRot = rustNode.rotation
	
	rustNode.rotation = 0
	
	_spawnRustParticle(tempRot)
	
	hitbox_ref.show()
	rust_level = 0.0
	hitbox_ref.set_deferred("monitorable", true)
	if detected and not attacking:	
		_detectionCheck()

#Need rotation, size, proper position, L/R, and BL
func _spawnRustParticle(tempRot : float) -> void: #BL : int, 
	#var totalRot : float = parentRef.getRotation()
	
	var rust_pos = getRustPosition()
	spawnRustParticle.emit(1, rust_pos, tempRot, size, [spear_level])

func _deRust() -> void:
	var rust_length = 12.0 / rust_recovery_speed * min(rust_level / rust_max, 1.0)
	
	if rust_tween:
		rust_tween.kill()
	rust_tween = create_tween()
	rust_tween.tween_property(spear_refs[spear_level], "modulate", startspearColor, rust_length)
	rust_tween.parallel().tween_property(self, "rust_level", 0, rust_length)


func getFocusedPosition() -> Vector2: 
	var retVec = getPosition()
	var the_node_path : String = "Hitbox/CollisionShape2D"
	
	
	match spear_level:
		0:
			retVec += get_node(the_node_path).position
		1:
			retVec += get_node(the_node_path+"2").position
		2:
			retVec += get_node(the_node_path+"3").position
	
	return retVec

func getRustPosition() -> Vector2:
	
	var retVec = position#getPosition()
	
	#var neg_left = -1.0 if left else 1.0
	
	match spear_level:
		0:
			retVec += size * Vector2(10, -49) #2 + -8.5*6
		1:
			retVec += size * Vector2(11, -58) #2 + -10*6
		2:
			retVec += size * Vector2(12, -70) #2 + -12*6
	
	return retVec#.rotated(totalRot)
