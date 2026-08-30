extends "res://Blob/Evolutions/base_evo_general.gd"

var attacking : bool = false
var detected : bool = false

@export var blade_level : int = 0
@onready var blade_left_refs = [$Blade1/Left, $Blade2/Left, $Blade3/Left]
@onready var blade_right_refs = [$Blade1/Right, $Blade2/Right, $Blade3/Right]


@onready var hitbox_l_ref = $HitboxL
@onready var hitbox_r_ref = $HitboxR
#@onready var hitbox_ref

var blade_tween
var rust_tween_l
var rust_tween_r

@export var rust_max : float = 10.0
var rust_level_l : float = 0.0
var rust_level_r : float = 0.0

@export var rust_recovery_speed : float = 1.0

@export var startBladeColor : Color
@export var endBladeColor : Color

@export var pinch_cooldown : float = 2.0

signal spawnRustParticle(partID : int, rust_pos : Vector2, totalRot : float, size : float, kwargs : Array)


func _ready() -> void:
	var blade_temp = blade_level
	blade_level = 0
	setBladeLevel(blade_temp)
	super()

func addBladeLevel() -> void:
	if blade_level == 2:
		setBladeLevel(0)
	else:
		setBladeLevel(blade_level+1)

func setBladeLevel(newBL : int) -> void:
	match blade_level:
		0:
			$HitboxL/CollisionShape2D.set_deferred("disabled", true)
			$HitboxR/CollisionShape2D.set_deferred("disabled", true)
			#$Hitbox/CollisionShape2D.set_deferred("disabled", true)
			$Detection/CollisionShape2D.set_deferred("disabled", true)
			if not attacking:
				$Blade1.hide()
			$Blade1/RustedL.position.y = 2
			$Blade1/RustedL.modulate.a = 0.0
			$Blade1/RustedR.position.y = 2
			$Blade1/RustedR.modulate.a = 0.0
			$Blade1/RustedL.rotation = 0.0
			$Blade1/RustedR.rotation = 0.0
		1:
			$HitboxL/CollisionShape2D2.set_deferred("disabled", true)
			$HitboxR/CollisionShape2D2.set_deferred("disabled", true)
			#$Hitbox/CollisionShape2D2.set_deferred("disabled", true)
			$Detection/CollisionShape2D2.set_deferred("disabled", true)
			if not attacking:
				$Blade2.hide()
			$Blade2/RustedL.position.y = 2
			$Blade2/RustedL.modulate.a = 0.0
			$Blade2/RustedR.position.y = 2
			$Blade2/RustedR.modulate.a = 0.0
			$Blade2/RustedL.rotation = 0.0
			$Blade2/RustedR.rotation = 0.0
		2:
			$HitboxL/CollisionShape2D3.set_deferred("disabled", true)
			$HitboxR/CollisionShape2D3.set_deferred("disabled", true)
			#$Hitbox/CollisionShape2D3.set_deferred("disabled", true)
			$Detection/CollisionShape2D3.set_deferred("disabled", true)
			if not attacking:
				$Blade3.hide()
			$Blade3/RustedL.position.y = 2
			$Blade3/RustedL.modulate.a = 0.0
			$Blade3/RustedR.position.y = 2
			$Blade3/RustedR.modulate.a = 0.0
			$Blade3/RustedL.rotation = 0.0
			$Blade3/RustedR.rotation = 0.0
	
	blade_left_refs[blade_level].modulate = startBladeColor
	blade_right_refs[blade_level].modulate = startBladeColor
	hitbox_l_ref.set_deferred("monitorable", true)
	hitbox_r_ref.set_deferred("monitorable", true)
	#hitbox_l_ref.show()
	#hitbox_r_ref.show()
	
	blade_level = newBL
	rust_level_l = 0.0
	rust_level_r = 0.0
	
	if rust_tween_l:
		rust_tween_l.kill()
	if rust_tween_r:
		rust_tween_r.kill()
	
	if not detected:
		match blade_level:
			0:
				$HitboxL/CollisionShape2D.set_deferred("disabled", false)
				$HitboxR/CollisionShape2D.set_deferred("disabled", false)
				#$Hitbox/CollisionShape2D.set_deferred("disabled", false)
				$Detection/CollisionShape2D.set_deferred("disabled", false)
				if not attacking:	
					$Blade1.show()
			1:
				$HitboxL/CollisionShape2D2.set_deferred("disabled", false)
				$HitboxR/CollisionShape2D2.set_deferred("disabled", false)
				#$Hitbox/CollisionShape2D2.set_deferred("disabled", false)
				$Detection/CollisionShape2D2.set_deferred("disabled", false)
				if not attacking:
					$Blade2.show()
			2:
				$HitboxL/CollisionShape2D3.set_deferred("disabled", false)
				$HitboxR/CollisionShape2D3.set_deferred("disabled", false)
				#$Hitbox/CollisionShape2D3.set_deferred("disabled", false)
				$Detection/CollisionShape2D3.set_deferred("disabled", false)
				if not attacking:	
					$Blade3.show()
	
	

func _on_detection_area_entered(area: Area2D) -> void:
	if not detected and not attacking:
		if area.getID() != 0:
			if rust_level_l < rust_max or rust_level_r < rust_max:
				detected = true
				_pinch()
		

func _on_detection_body_entered(body: Node2D) -> void:
	if not detected and not attacking:
		if body.getID() != 0:
			detected = true
			if rust_level_l < rust_max or rust_level_r < rust_max:
				_pinch()

func _detectionCheck() -> void:
	var detectNode = $Detection
	
	if (detectNode.has_overlapping_areas() or detectNode.has_overlapping_bodies()):
		if not attacking:
			detected = true
			if rust_level_l < rust_max or rust_level_r < rust_max:
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
"""
func _toggle(toggle : bool) -> void:
	if rust_level_l < rust_max: #not toggle or 
		#hitbox_l_ref.set_deferred("monitoring", toggle)
		hitbox_l_ref.set_deferred("monitorable", toggle)
	if rust_level_r < rust_max: #not toggle or 
		#hitbox_r_ref.set_deferred("monitoring", toggle)
		hitbox_r_ref.set_deferred("monitorable", toggle)
"""

func _pinch() -> void:
	var pinch_time = 0.6
	
	_BLtoColShape(blade_level).set_deferred("disabled", false)
	#_toggle(false)
	
	if blade_tween:
		blade_tween.kill()
	blade_tween = create_tween().set_parallel()
	if rust_level_l < rust_max:
		blade_tween.tween_property(blade_left_refs[blade_level], "scale:y", 1.2, pinch_time)
		blade_tween.tween_property(blade_left_refs[blade_level], "rotation", PI/4, pinch_time)
		blade_tween.tween_property(blade_left_refs[blade_level], "rotation", 0, pinch_time).set_delay(pinch_time)
		blade_tween.tween_property(blade_left_refs[blade_level], "scale:y", 1.0, pinch_time).set_delay(pinch_time)
	if rust_level_r < rust_max:
		blade_tween.tween_property(blade_right_refs[blade_level], "scale:y", 1.2, pinch_time)
		blade_tween.tween_property(blade_right_refs[blade_level], "rotation", -PI/4, pinch_time)
		blade_tween.tween_property(blade_right_refs[blade_level], "rotation", 0, pinch_time).set_delay(pinch_time)
		blade_tween.tween_property(blade_right_refs[blade_level], "scale:y", 1.0, pinch_time).set_delay(pinch_time)
	
	#var blade_temp = blade_level
	blade_tween.finished.connect(_pinchEnd.bind(blade_level))#blade_temp))

func _pinchEnd(BL : int) -> void:
	_BLtoColShape(BL).set_deferred("disabled", true)
	#_toggle(true)
	$PinchCooldown.start(pinch_cooldown)
	
func _on_pinch_cooldown_timeout() -> void:
	_detectionCheck()

func attack(temp : float, charge_cd : float) -> void:
	var rustL : bool = rust_level_l < rust_max
	var rustR : bool = rust_level_r < rust_max
	if not attacking and (rustL or rustR):
		attacking = true
		
		var charge_time : float = min(0.3 * charge_cd, 0.45)
		var swipe_time : float = min(0.2 * charge_cd, 0.3)
		var return_time : float = min(0.5 * charge_cd, 0.75)
		var bladeLen = max(2.0 * temp/6.0, 1.5) 
		
		var posChange 
		match blade_level:
			0:
				posChange = 9*size
			1:
				posChange = 14*size
			2:
				posChange = 17*size

		if blade_tween:
			blade_tween.kill()
		blade_tween = create_tween().set_parallel()
		if rustL:
			blade_tween.tween_property(blade_left_refs[blade_level], "scale:y", bladeLen, charge_time)
			blade_tween.tween_property(blade_left_refs[blade_level], "position:x", posChange, swipe_time).as_relative()
			blade_tween.tween_property(blade_left_refs[blade_level], "rotation", -PI/8, charge_time)
			blade_tween.tween_property(blade_left_refs[blade_level], "rotation", PI/4, swipe_time).set_delay(charge_time)
			blade_tween.tween_property(blade_left_refs[blade_level], "position:x", -0, charge_time).as_relative().set_delay(charge_time)
			blade_tween.tween_property(blade_left_refs[blade_level], "rotation", 0, return_time).set_delay(return_time)
			blade_tween.tween_property(blade_left_refs[blade_level], "scale:y", 1.0, return_time).set_delay(return_time)
		
		if rustR:
			blade_tween.tween_property(blade_right_refs[blade_level], "scale:y", bladeLen, charge_time)
			blade_tween.tween_property(blade_right_refs[blade_level], "position:x", -posChange, swipe_time).as_relative()
			blade_tween.tween_property(blade_right_refs[blade_level], "rotation", PI/8, charge_time)
			blade_tween.tween_property(blade_right_refs[blade_level], "rotation", -PI/4, swipe_time).set_delay(charge_time)
			blade_tween.tween_property(blade_right_refs[blade_level], "position:x", 0, charge_time).as_relative().set_delay(charge_time)
			blade_tween.tween_property(blade_right_refs[blade_level], "rotation", 0, return_time).set_delay(return_time)
			blade_tween.tween_property(blade_right_refs[blade_level], "scale:y", 1.0, return_time).set_delay(return_time)
		
		#var blade_temp = blade_level
		blade_tween.finished.connect(_attackEnd.bind(blade_level))#blade_temp))
		
		_colShapeIncrease(blade_level, bladeLen)
		_BLtoColShape(blade_level).set_deferred("disabled", false)
		

func _attackEnd(BL : int) -> void:
	if BL != blade_level:
		match BL:
			0:
				$Blade1.hide()
			1:
				$Blade2.hide()
			2:
				$Blade3.hide()
		match blade_level:
			0:
				$Blade1.show()
			1:
				$Blade2.show()
			2:
				$Blade3.show()
	
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
	$Blade1.scale = sizeVec
	$Blade2.scale = sizeVec
	$Blade3.scale = sizeVec
	
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
	$HitboxL/CollisionShape2D.set_deferred("shape", tempRect)
	$HitboxL/CollisionShape2D.set_deferred("position", Vector2(-15,-19)*size)
	$HitboxR/CollisionShape2D.set_deferred("shape", tempRect)
	$HitboxR/CollisionShape2D.set_deferred("position", Vector2(15,-19)*size)
	
	tempRect = RectangleShape2D.new()
	tempRect.size = size * Vector2(16.0, 46.0)
	$HitboxL/CollisionShape2D2.set_deferred("shape", tempRect)
	$HitboxL/CollisionShape2D2.set_deferred("position", Vector2(-18,-23)*size)
	$HitboxR/CollisionShape2D2.set_deferred("shape", tempRect)
	$HitboxR/CollisionShape2D2.set_deferred("position", Vector2(18,-23)*size)
	
	tempRect = RectangleShape2D.new()
	tempRect.size = size * Vector2(20.0, 60.0)
	$HitboxL/CollisionShape2D3.set_deferred("shape", tempRect)
	$HitboxL/CollisionShape2D3.set_deferred("position", Vector2(-20,-30)*size)
	$HitboxR/CollisionShape2D3.set_deferred("shape", tempRect)
	$HitboxR/CollisionShape2D3.set_deferred("position", Vector2(20,-30)*size)

func _damagedEnemyLeft(amt : float) -> void:
	_damagedEnemy(amt)
	_handleRustLeft(amt)

func _handleRustLeft(amt : float) -> void:
	if rust_level_l < rust_max:
		rust_level_l += 1.0 * amt
		var rust_length = 1.5 * min(amt / rust_max, 1.0)
		var rust_level_diff = min(rust_level_l / rust_max, 1.0)
		var end_rust_color = startBladeColor.lerp(endBladeColor, rust_level_diff)
		
		if rust_tween_l:
			rust_tween_l.kill()
		rust_tween_l = create_tween()
		rust_tween_l.tween_property(blade_left_refs[blade_level], "modulate", end_rust_color, rust_length)
		if rust_level_l < rust_max:
			rust_tween_l.tween_interval(1.0 / rust_recovery_speed)
			rust_tween_l.finished.connect(_deRustLeft)
		else:
			rust_tween_l.finished.connect(_RustedLeft)
			#hitbox_l_ref.set_deferred("monitoring", false)
			hitbox_l_ref.set_deferred("monitorable", false)
			hitbox_l_ref.hide()
	

func _damagedEnemyRight(amt : float) -> void:
	_damagedEnemy(amt)
	_handleRustRight(amt)
	
func _handleRustRight(amt : float) -> void:
	if rust_level_r < rust_max:
		rust_level_r += 1.0 * amt
		var rust_length = 1.5 * min(amt / rust_max, 1.0)
		var rust_level_diff = min(rust_level_r / rust_max, 1.0)
		var end_rust_color = startBladeColor.lerp(endBladeColor, rust_level_diff)
		
		if rust_tween_r:
			rust_tween_r.kill()
		rust_tween_r = create_tween()
		rust_tween_r.tween_property(blade_right_refs[blade_level], "modulate", end_rust_color, rust_length)
		if rust_level_r < rust_max:
			rust_tween_r.tween_interval(1.0 / rust_recovery_speed)
			rust_tween_r.finished.connect(_deRustRight)
		else:
			rust_tween_r.finished.connect(_RustedRight)
			#hitbox_r_ref.set_deferred("monitoring", false)
			hitbox_r_ref.set_deferred("monitorable", false)
			hitbox_r_ref.hide()
	
func _damagedEnemyMid(amt : float) -> void:
	_damagedEnemy(amt)
	
	_handleRustLeft(0.5*amt)
	_handleRustRight(0.5*amt)

func _RustedLeft() -> void:
	#hitbox_l_ref.set_deferred("monitorable", false)
	#$AnimationPlayer.play("removeRustLeft", -1, rust_recovery_speed)
	
	var rustNode : Node2D
	var rustOffset : float
	match blade_level:
		0:
			rustNode = $Blade1/RustedL
			rustOffset = -8.5
		1:
			rustNode = $Blade2/RustedL
			rustOffset = -10.0
		2:
			rustNode = $Blade3/RustedL 
			rustOffset = -12.0
	
	var derust_start = 1.0 
	var derust_time = 12.55 / rust_recovery_speed
	var derust_interval = 0.1
	var derust_end = 0.75 # *2 
	var derust_end_end = 0.6
	
	#var startColor : Color = startBladeColor
	#startColor.a = 0.0
	if rust_tween_l:
		rust_tween_l.kill()
	rust_tween_l = create_tween()
	rust_tween_l.tween_property(blade_left_refs[blade_level], "modulate:a", 0.0, derust_start)
	rust_tween_l.parallel().tween_property(rustNode, "modulate:a", 1.0, derust_start)
	rust_tween_l.tween_property(blade_left_refs[blade_level], "scale", Vector2(0.0,0.0), derust_time)
	rust_tween_l.tween_property(blade_left_refs[blade_level], "modulate", startBladeColor, derust_interval)
	rust_tween_l.tween_property(blade_left_refs[blade_level], "scale", Vector2(0.5,0.25), derust_end)
	rust_tween_l.parallel().tween_property(rustNode, "position:y", rustOffset, derust_end).as_relative()
	rust_tween_l.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	rust_tween_l.tween_property(blade_left_refs[blade_level], "scale", Vector2(1.0,1.0), derust_end_end)
	rust_tween_l.parallel().tween_property(rustNode, "position:y", 5*rustOffset, derust_end_end).as_relative()
	rust_tween_l.parallel().tween_property(rustNode, "rotation", 2.0, derust_end_end)
	rust_tween_l.finished.connect(_fullDeRust.bind(true, rustNode))

func _RustedRight() -> void:
	var rustNode : Node2D
	var rustOffset : float
	match blade_level:
		0:
			rustNode = $Blade1/RustedR
			rustOffset = -8.5 * size
		1:
			rustNode = $Blade2/RustedR
			rustOffset = -10.0 * size
		2:
			rustNode = $Blade3/RustedR 
			rustOffset = -12.0 * size
	
	var derust_start = 1.0 
	var derust_time = 12.55 / rust_recovery_speed
	var derust_interval = 0.1
	var derust_end = 0.75  
	var derust_end_end = 0.6
	
	var startColor : Color = startBladeColor
	startColor.a = 0.0
	if rust_tween_r:
		rust_tween_r.kill()
	rust_tween_r = create_tween()
	rust_tween_r.tween_property(blade_right_refs[blade_level], "modulate:a", 0.0, derust_start)
	rust_tween_r.parallel().tween_property(rustNode, "modulate:a", 1.0, derust_start)
	rust_tween_r.tween_property(blade_right_refs[blade_level], "scale", Vector2(0.0,0.0), derust_time)
	rust_tween_r.tween_property(blade_right_refs[blade_level], "modulate", startBladeColor, derust_interval)
	rust_tween_r.tween_property(blade_right_refs[blade_level], "scale", Vector2(0.5,0.25), derust_end)
	rust_tween_r.parallel().tween_property(rustNode, "position:y", rustOffset, derust_end).as_relative()
	rust_tween_r.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	rust_tween_r.tween_property(blade_right_refs[blade_level], "scale", Vector2(1.0,1.0), derust_end_end)
	rust_tween_r.parallel().tween_property(rustNode, "position:y", 5*rustOffset, derust_end_end).as_relative()
	rust_tween_r.parallel().tween_property(rustNode, "rotation", -2.0, derust_end_end)
	rust_tween_r.finished.connect(_fullDeRust.bind(false, rustNode))

func _fullDeRust(left : bool, rustNode : Node2D) -> void:
	rustNode.modulate.a = 0.0
	rustNode.position.y = 2
	var tempRot = rustNode.rotation
	
	rustNode.rotation = 0
	
	if left:
		#if rust_level_l >= rust_max:	
		
		_spawnRustParticle(true, tempRot)
		
		hitbox_l_ref.show()
		rust_level_l = 0.0
		hitbox_l_ref.set_deferred("monitorable", true)
		if detected and not attacking:	
			_detectionCheck()
	else:
		
		_spawnRustParticle(false, tempRot)
		
		#if rust_level_r >= rust_max:	
		hitbox_r_ref.show()
		rust_level_r = 0.0
		hitbox_r_ref.set_deferred("monitorable", true)
		if detected and not attacking:	
			_detectionCheck()

#Need rotation, size, proper position, L/R, and BL
func _spawnRustParticle(left : bool, tempRot : float) -> void: #BL : int, 
	#var totalRot : float = parentRef.getRotation()
	
	var rust_pos = getRustPosition(left) #totalRot, 
	spawnRustParticle.emit(0, rust_pos, tempRot, size, [left, blade_level])#totalRot + 

func _deRustLeft() -> void:
	var rust_length = 12.0 / rust_recovery_speed * min(rust_level_l / rust_max, 1.0)
	
	if rust_tween_l:
		rust_tween_l.kill()
	rust_tween_l = create_tween()
	rust_tween_l.tween_property(blade_left_refs[blade_level], "modulate", startBladeColor, rust_length)
	rust_tween_l.parallel().tween_property(self, "rust_level_l", 0, rust_length)

func _deRustRight() -> void:
	var rust_length = 12.0 / rust_recovery_speed * min(rust_level_r / rust_max, 1.0)
	
	if rust_tween_r:
		rust_tween_r.kill()
	rust_tween_r = create_tween()
	rust_tween_r.tween_property(blade_right_refs[blade_level], "modulate", startBladeColor, rust_length)
	rust_tween_r.parallel().tween_property(self, "rust_level_r", 0, rust_length)

func getFocusedPosition(hitbox_type : int) -> Vector2: 
	var retVec = getPosition()
	var the_node_path : String
	
	
	match hitbox_type:
		0:
			the_node_path = "HitboxL/CollisionShape2D"
		1:
			the_node_path = "HitboxR/CollisionShape2D"
		2:
			the_node_path = "Hitbox/CollisionShape2D"
	
	match blade_level:
		0:
			retVec += get_node(the_node_path).position
		1:
			retVec += get_node(the_node_path+"2").position
		2:
			retVec += get_node(the_node_path+"3").position
	
	return retVec

#The rot calculation has to be here instead of player bcause particles might come from difference sources that don't need to be rotated
#like that 
#NVM I'll just create another func for it if needs be
func getRustPosition(left : bool) -> Vector2: #totalRot : float, 
	
	
	var retVec = position#getPosition()
	
	var neg_left = -1.0 if left else 1.0
	
	match blade_level:
		0:
			retVec += size * Vector2(neg_left * 10, -49) #2 + -8.5*6
		1:
			retVec += size * Vector2(neg_left * 11, -58) #2 + -10*6
		2:
			retVec += size * Vector2(neg_left * 12, -70) #2 + -12*6
	
	return retVec#.rotated(totalRot)
