extends "res://Blob/Evolutions/base_evo_general.gd"

"""
@export var base_damage : float = 1
@export var damage_mult : float = 1
#@export var size : float = 12

@export var base_intensity : float = 1
@export var dot_mult : float = 1
@export var duration : float = 1

func _on_inject(area: Area2D) -> void:
	area.getParent().applyPoison(base_intensity * dot_mult, duration)
"""

var attacking : int = 0


var impaled : bool = false
var impale : bool = true
var imp_ref : Node2D 
var impale_max_dura : float = 5.0
const impale_weight_limt = 5.0
var impale_tween

@export var spear_level : int = 0
@onready var spear_refs = [$Spear1, $Spear2, $Spear3, $Spear4, $Spear5]
@onready var spear_spear_refs = [$Spear1/SpearShade, $Spear2/SpearShade, $Spear3/SpearShade, $Spear4/SpearShade, $Spear5/SpearShade]
@onready var hitbox_refs = [$HitboxSpear/CollisionShape2D, $HitboxSpear/CollisionShape2D2, $HitboxSpear/CollisionShape2D3, $HitboxSpear/CollisionShape2D4,$HitboxSpear/CollisionShape2D5]

@export var dot : bool = true
#@onready var hitbox_ref = $Hitbox
#var dot_hitbox_enabled : bool = false 
var first_hitbox_enabled : bool = false
@export var dot_timer : float = 0.2

@export var poison : bool = true
@export var poison_max : float = 8.0
@export var poison_gain_rate : float = 1.0
var poison_amount : float = poison_max
var poison_damage : float = 1.0
var poison_tween

var damage_mult = 2.0

var spear_tween
var rust_tween

@export var rust_max : float = 10.0
var rust_level : float = 0.0

@export var rust_recovery_speed : float = 1.0

@export var startspearColor : Color
@export var endspearColor : Color

signal spawnRustParticle(partID : int, rust_pos : Vector2, totalRot : float, size : float, kwargs : Array)

func _ready() -> void:
	var spear_temp = spear_level
	spear_level = 0
	setspearLevel(spear_temp)
	super()

func addSpearLevel() -> void:
	if spear_level == 4:
		setspearLevel(0)
	else:
		setspearLevel(spear_level+1)

func setspearLevel(newBL : int) -> void:
	match spear_level:
		0:
			$HitboxSpear/CollisionShape2D.set_deferred("disabled", false)
			if first_hitbox_enabled:	
				$HitboxDOT/CollisionShape2D.set_deferred("disabled", false)
			else:
				$HitboxDOT/SecondShape2D.set_deferred("disabled", false)
			#$Hitbox1.set_deferred("monitorable", false)
			if attacking == 0:
				$Spear1.hide()
			$Spear1/Rust.position.y = 2
			$Spear1/Rust.modulate.a = 0.0
			$Spear1/Rust.position.y = 2
			$Spear1/SpearShade.modulate = Color.WHITE
			$Spear1/SpearShade.scale = Vector2(1,1)
			
		1:
			$HitboxSpear/CollisionShape2D2.set_deferred("disabled", false)
			if first_hitbox_enabled:
				$HitboxDOT/CollisionShape2D2.set_deferred("disabled", false)
			else:
				$HitboxDOT/SecondShape2D2.set_deferred("disabled", false)
			#$Hitbox2.set_deferred("monitorable", false)
			if attacking == 0:
				$Spear2.hide()
			$Spear2/Rust.position.y = 2
			$Spear2/Rust.modulate.a = 0.0
			$Spear2/Rust.position.y = 2
			$Spear2/SpearShade/Full.modulate = Color.WHITE
			$Spear2/SpearShade/Full.scale = Vector2(1,1)
		2:
			$HitboxSpear/CollisionShape2D3.set_deferred("disabled", false)
			if first_hitbox_enabled:
				$HitboxDOT/CollisionShape2D3.set_deferred("disabled", false)
			else:
				$HitboxDOT/SecondShape2D3.set_deferred("disabled", false)
			#$Hitbox3.set_deferred("monitorable", false)
			if attacking == 0:
				$Spear3.hide()
			$Spear3/Rust.position.y = 2
			$Spear3/Rust.modulate.a = 0.0
			$Spear3/Rust.position.y = 2
			$Spear3/SpearShade/Full.modulate = Color.WHITE
			$Spear3/SpearShade/Full.scale = Vector2(1,1)
		3:
			$HitboxSpear/CollisionShape2D4.set_deferred("disabled", false)
			if first_hitbox_enabled:
				$HitboxDOT/CollisionShape2D4.set_deferred("disabled", false)
			else:
				$HitboxDOT/SecondShape2D4.set_deferred("disabled", false)
			#$Hitbox4.set_deferred("monitorable", false)
			if attacking == 0:
				$Spear4.hide()
			$Spear4/Rust.position.y = 2
			$Spear4/Rust.modulate.a = 0.0
			$Spear4/Rust.position.y = 2
			$Spear4/SpearShade/Full.modulate = Color.WHITE
			$Spear4/SpearShade/Full.scale = Vector2(1,1)
		4:
			$HitboxSpear/CollisionShape2D5.set_deferred("disabled", false)
			#$Hitbox5/CollisionShape2D2.set_deferred("disabled", false)
			#$Hitbox5.set_deferred("monitorable", false)
			if attacking == 0:
				$Spear5.hide()
			#$Spear5/Rust.position.y = 2
			#$Spear5/Rust.modulate.a = 0.0
			#$Spear5/Rust.position.y = 2
			poison_amount = 0.0
			_poisonInitialFinished(0.0)
	
	impale = newBL == 2
	
	$DoTTickTimer.stop()
	
	spear_spear_refs[spear_level].modulate = startspearColor
	
	hitbox_refs[spear_level].set_deferred("monitorable", false)
	hitbox_refs[spear_level].hide()
	
	
	spear_level = newBL
	rust_level = 0.0
	
	hitbox_refs[newBL].set_deferred("monitorable", true)
	hitbox_refs[newBL].show()
	
	if rust_tween:
		rust_tween.kill()
	
	if attacking == 0:
		spear_refs[newBL].show()
	
	match newBL:
		0:
			if poison:
				$Spear1/CapsuleBG.show()
				$Spear1/Juice.show()
				$Spear1/Cover.show()
		1:	
			if poison:
				$Spear2/Juice.show()
		2:	
			if poison:
				$Spear3/Juice.show()
		3:
			if poison:
				$Spear4/Juice.show()
		4:
			poison_amount = 0.0
			_poisonInitialFinished(0.0)
		
	
func _BLtoColShape(BL : int) -> CollisionShape2D:
	match BL:
		0:
			return $Hitbox/Spear1
		1:
			return $Hitbox/Spear2
		2:
			return $Hitbox/Spear3
		3:
			return $Hitbox/Spear4
		_:
			return $Hitbox/Spear5

"""
func _toggle(toggle : bool) -> void:
	if rust_level < rust_max: 
		hitbox_refs[spear_level].set_deferred("monitorable", toggle)
		#hitbox_ref.set_deferred("monitorable", toggle)
"""
func chargeAttack(charge_max : float) -> void:
	if attacking != 1 and (rust_level < rust_max or spear_level < 3):
		if impaled:
			impaleEnd()
			return
		
		attacking = 1
		if spear_tween:
			spear_tween.kill()
		spear_tween = create_tween()
		var base_size = 2.0*size
		spear_tween.tween_property(spear_refs[spear_level], "scale", base_size*Vector2(1, 0.25), charge_max)

func attack(temp : float, charge_cd : float, charge_pull : float) -> void:
	
	if attacking == 1 and (rust_level < rust_max or spear_level < 3):
		if impaled:
			impaleEnd()
			return
			
		attacking = 2
		
		var swipePos : float = min(0.08 * charge_cd, 0.2)
		var retPos : float = min(0.3 * charge_cd, 0.4) / charge_pull
		var spearLen = max(2.0 * temp/6.0, 1.5) 

		if spear_tween:
			spear_tween.kill()
		spear_tween = create_tween().set_parallel()
		
		var base_size = 2.0*size
		
		spear_tween.tween_property(spear_refs[spear_level], "scale", base_size*Vector2(temp/20, 1 + 0.1 * temp), swipePos)
		spear_tween.tween_property(spear_refs[spear_level], "scale", base_size*Vector2(1,1), retPos).set_delay(swipePos)
		
		
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
			4:
				$Spear4.hide()
			5:
				$Spear5.hide()
		match spear_level:
			0:
				$Spear1.show()
			1:
				$Spear2.show()
			2:
				$Spear3.show()
			3:
				$Spear4.show()
			4:
				$Spear5.show()
	
	attacking = 0
	_BLtoColShape(BL).set_deferred("disabled", true)
	_colShapeReset(BL)


func _colShapeIncrease(BL : int, inc : float) -> void:
	var tempShape = CircleShape2D.new()
	
	var abs_size = size * inc
	var hb_shape = _BLtoColShape(BL)
	tempShape.radius = 12 * abs_size if BL != 4 else 24 * abs_size
	if BL == 2:
		tempShape.radius = 18 * abs_size
	hb_shape.set_deferred("shape", tempShape)
	match BL:
		0:	
			hb_shape.set_deferred("position:y", -43*abs_size)
		1:
			#tempShape.radius = 26 * abs_size
			#hb_shape.set_deferred("shape", tempShape)
			hb_shape.set_deferred("position:y", -49*abs_size)
		2:
			#tempShape.radius = 32 * abs_size
			#hb_shape.set_deferred("shape", tempShape)
			hb_shape.set_deferred("position:y", -61*abs_size)
		3:
			#tempShape.radius = 32 * abs_size
			#hb_shape.set_deferred("shape", tempShape)
			hb_shape.set_deferred("position:y", -55*abs_size)
		4:
			#tempShape.radius = 32 * abs_size
			#hb_shape.set_deferred("shape", tempShape)
			hb_shape.set_deferred("position:y", -37*abs_size)
			
func _colShapeReset(BL : int) -> void:
	var tempShape = CircleShape2D.new()
	var hb_shape = _BLtoColShape(BL)
	tempShape.radius = 12 * size if BL != 4 else 24 * size
	if BL == 2:
		tempShape.radius = 18 * size
	hb_shape.set_deferred("shape", tempShape)
	match BL:
		0:
			#tempShape.radius = 20 * size
			#hb_shape.set_deferred("shape", tempShape)
			hb_shape.set_deferred("position:y", -43*size)
		1:
			#tempShape.radius = 26 * size
			#hb_shape.set_deferred("shape", tempShape)
			hb_shape.set_deferred("position:y", -49*size)
		2:
			#tempShape.radius = 32 * size
			#hb_shape.set_deferred("shape", tempShape)
			hb_shape.set_deferred("position:y", -61*size)
		3:
			#tempShape.radius = 32 * size
			#hb_shape.set_deferred("shape", tempShape)
			hb_shape.set_deferred("position:y", -55*size)
		4:
			#tempShape.radius = 32 * size
			#hb_shape.set_deferred("shape", tempShape)
			hb_shape.set_deferred("position:y", -37*size)


func _setSize() -> void:
	var sizeVec = size * Vector2(1,1)
	#Some FUCKING idiot decided to scale all of them by 2 for NO good reason. Some lazy fucking idiot
	#Now when I'm done with ALL the sprites do I realize this fucking lazy idiot scaled them all by two
	#and it'd take me hours to fix it.
	#Make sure you scale ALL the fucking position offsets by two you god damn idiot.
	$Spear1.scale = sizeVec * 2 
	$Spear2.scale = sizeVec * 2
	$Spear3.scale = sizeVec * 2
	$Spear4.scale = sizeVec * 2
	$Spear5.scale = sizeVec * 2
	
	"""
	if not attacking:
		var tempShape = CircleShape2D.new()
		tempShape.radius = 20 * size
		$Hitbox/Spear1.set_deferred("shape", tempShape)
		$Hitbox/Spear1.set_deferred("position:y", -22*size)
		
		tempShape = CircleShape2D.new()
		tempShape.radius = 26 * size
		$Hitbox/Spear2.set_deferred("shape", tempShape)
		$Hitbox/Spear2.set_deferred("position:y", -26*size)
		
		tempShape = CircleShape2D.new()
		tempShape.radius = 32 * size
		$Hitbox/Spear3.set_deferred("shape", tempShape)
		$Hitbox/Spear3.set_deferred("position:y", -34*size)
		
		tempShape = CircleShape2D.new()
		tempShape.radius = 32 * size
		$Hitbox/Spear4.set_deferred("shape", tempShape)
		$Hitbox/Spear4.set_deferred("position:y", -34*size)
		
		tempShape = CircleShape2D.new()
		tempShape.radius = 32 * size
		$Hitbox/Spear5.set_deferred("shape", tempShape)
		$Hitbox/Spear5.set_deferred("position:y", -34*size)
	"""
	
	var tempRect = RectangleShape2D.new()
	tempRect.size = size * Vector2(12.0, 40.0)
	$HitboxSpear/CollisionShape2D.set_deferred("shape", tempRect)
	$HitboxSpear/CollisionShape2D.set_deferred("position", Vector2(0,-23)*size)
	$HitboxDOT/CollisionShape2D.set_deferred("shape", tempRect)
	$HitboxDOT/SecondShape2D.set_deferred("position", Vector2(0,-23)*size)
	
	tempRect = RectangleShape2D.new()
	tempRect.size = size * Vector2(12.0, 46.0)
	$HitboxSpear/CollisionShape2D2.set_deferred("shape", tempRect)
	$HitboxSpear/CollisionShape2D2.set_deferred("position", Vector2(-0,-26)*size)
	$HitboxDOT/CollisionShape2D2.set_deferred("shape", tempRect)
	$HitboxDOT/SecondShape2D2.set_deferred("position", Vector2(-0,-26)*size)
	
	tempRect = RectangleShape2D.new()
	tempRect.size = size * Vector2(18.0, 58.0)
	$HitboxSpear/CollisionShape2D3.set_deferred("shape", tempRect)
	$HitboxSpear/CollisionShape2D3.set_deferred("position", Vector2(0,-32)*size)
	$HitboxDOT/CollisionShape2D3.set_deferred("shape", tempRect)
	$HitboxDOT/SecondShape2D3.set_deferred("position", Vector2(0,-32)*size)
	
	tempRect = RectangleShape2D.new()
	tempRect.size = size * Vector2(14.0, 47.0)
	$HitboxSpear/CollisionShape2D4.set_deferred("shape", tempRect)
	$HitboxSpear/CollisionShape2D4.set_deferred("position", Vector2(0,-26.5)*size)
	$HitboxDOT/CollisionShape2D4.set_deferred("shape", tempRect)
	$HitboxDOT/SecondShape2D4.set_deferred("position", Vector2(0,-26.5)*size)
	
	tempRect = RectangleShape2D.new()
	tempRect.size = size * Vector2(16.0, 34.0)
	$HitboxSpear/CollisionShape2D5.set_deferred("shape", tempRect)
	$HitboxSpear/CollisionShape2D5.set_deferred("position", Vector2(0,-20)*size)
	#$Hitbox5/CollisionShape2D2.set_deferred("shape", tempRect)
	#$Hitbox5/CollisionShape2D2.set_deferred("position", Vector2(-20,-30)*size)

func _damagedEnemyNormal(amt : float) -> void:
	_damagedEnemy(amt)
	_handleRust(amt)
	if dot and $DoTTickTimer.is_stopped():
		$DoTTickTimer.start(dot_timer)
		#dot_hitbox_enabled = true
		$HitboxDOT.set_deferred("monitorable", true)
	

func _damagedEnemyAttack(amt : float) -> void:
	_damagedEnemy(amt)
	_handleRust(amt*0.5)

func _handleRust(amt : float) -> void:
	if rust_level < rust_max:
		rust_level += 1.0 * amt
		var rust_length = 1.5 * min(amt / rust_max, 1.0)
		var rust_level_diff = min(rust_level / rust_max, 1.0)
		var end_rust_color = startspearColor.lerp(endspearColor, rust_level_diff)
		
		if rust_tween:
			rust_tween.kill()
		rust_tween = create_tween()
		rust_tween.tween_property(spear_spear_refs[spear_level], "modulate", end_rust_color, rust_length)
		if rust_level < rust_max:
			rust_tween.tween_interval(1.0 / rust_recovery_speed)
			rust_tween.finished.connect(_deRust)
		else:
			rust_tween.finished.connect(_Rusted)
			#hitbox_ref.set_deferred("monitoring", false)
			hitbox_refs[spear_level].set_deferred("monitorable", false)
			hitbox_refs[spear_level].hide()
			
			if impaled:
				impaleEnd()

func _Rusted() -> void:
	#hitbox_ref.set_deferred("monitorable", false)
	#$AnimationPlayer.play("removeRustLeft", -1, rust_recovery_speed)
	
	var rustNode : Node2D
	var spearNode : Node2D
	var rustOffset : float
	
	var derust_start : float
	var derust_time : float
	var derust_end : float
	
	match spear_level:
		0:
			rustNode = $Spear1/Rust
			spearNode = $Spear1/SpearShade
			rustOffset = -6.0
		1:
			rustNode = $Spear2/Rust
			spearNode = $Spear2/SpearShade/Full
			rustOffset = -7.5
		2:
			rustNode = $Spear3/Rust 
			spearNode = $Spear3/SpearShade/Full
			rustOffset = -8
		3:
			rustNode = $Spear4/Rust 
			spearNode = $Spear4/SpearShade/Full
			rustOffset = -8.0
		4:
			rustNode = $Spear5/SpearShade/Rust 
			spearNode = $Spear5/SpearShade/Full
			
			derust_start = 1.0 
			derust_time = 13.0 / rust_recovery_speed
			derust_end = 1.0
			
			if rust_tween:
				rust_tween.kill()
			rust_tween = create_tween()
			rust_tween.tween_property(spearNode, "modulate:a", 0.0, derust_start)
			rust_tween.parallel().tween_property(rustNode, "modulate:a", 1.0, derust_start)
			rust_tween.tween_interval(derust_time)
			rust_tween.tween_property(spear_spear_refs[spear_level], "modulate", startspearColor, derust_end)
			rust_tween.parallel().tween_property(spearNode, "modulate:a", 1.0, derust_end)
			rust_tween.parallel().tween_property(rustNode, "modulate:a", 0.0, derust_end)
			rust_tween.finished.connect(_fullDeRust.bind(rustNode, false))
			return
	
	derust_start = 1.0 
	derust_time = 12.55 / rust_recovery_speed
	var derust_interval = 0.1
	derust_end = 0.75 # *2 
	var derust_end_end = 0.6
	
	#var startColor : Color = startspearColor
	#startColor.a = 0.0
	if rust_tween:
		rust_tween.kill()
	rust_tween = create_tween()
	rust_tween.tween_property(spearNode, "modulate:a", 0.0, derust_start)
	rust_tween.parallel().tween_property(rustNode, "modulate:a", 1.0, derust_start)
	rust_tween.tween_property(spearNode, "scale", Vector2(0.0,0.0), derust_time)
	rust_tween.tween_property(spear_spear_refs[spear_level], "modulate", startspearColor, derust_end_end*0.5)
	rust_tween.parallel().tween_property(spearNode, "modulate:a", 1.0, derust_interval)
	rust_tween.parallel().tween_property(spearNode, "scale", Vector2(0.75,0.5), derust_end)
	rust_tween.parallel().tween_property(rustNode, "position:y", rustOffset, derust_end).as_relative()
	rust_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	rust_tween.tween_property(spearNode, "scale", Vector2(1.0,1.0), derust_end_end*0.5)
	rust_tween.parallel().tween_property(rustNode, "position:y", 7.5*rustOffset, derust_end_end*1.5).as_relative()
	rust_tween.parallel().tween_property(rustNode, "rotation", 2.0, derust_end_end*1.5)
	rust_tween.finished.connect(_fullDeRust.bind(rustNode, true))

func _fullDeRust(rustNode : Node2D, notLast : bool) -> void:
	if notLast:
		rustNode.modulate.a = 0.0
		rustNode.position.y = 2
		var tempRot = rustNode.rotation
		
		rustNode.rotation = 0
	
		_spawnRustParticle(tempRot)
	
	hitbox_refs[spear_level].show()
	rust_level = 0.0
	hitbox_refs[spear_level].set_deferred("monitorable", true)


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
	rust_tween.tween_property(spear_spear_refs[spear_level], "modulate", startspearColor, rust_length)
	rust_tween.parallel().tween_property(self, "rust_level", 0, rust_length)


func getFocusedPosition(hitbox_type : int) -> Vector2: 
	var retVec = getPosition()
	
	match hitbox_type:
		0:
			var the_node_path : String = "Hitbox/Spear"
	
			match spear_level:
				0:
					retVec += get_node(the_node_path+"1").position
				1:
					retVec += get_node(the_node_path+"2").position
				2:
					retVec += get_node(the_node_path+"3").position
				3:
					retVec += get_node(the_node_path+"4").position
				4:
					retVec += get_node(the_node_path+"5").positions
		1:
			var the_node_path : String = "HitboxSpear/CollisionShape2D"
	
			match spear_level:
				0:
					retVec += get_node(the_node_path).position
				1:
					retVec += get_node(the_node_path+"2").position
				2:
					retVec += get_node(the_node_path+"3").position
				3:
					retVec += get_node(the_node_path+"4").position
				4:
					retVec += get_node(the_node_path+"5").positions
		2:
			var the_node_path : String = "HitboxDOT/CollisionShape2D"
	
			match spear_level:
				0:
					retVec += get_node(the_node_path).position
				1:
					retVec += get_node(the_node_path+"2").position
				2:
					retVec += get_node(the_node_path+"3").position
				3:
					retVec += get_node(the_node_path+"4").position
				4:
					retVec += get_node(the_node_path+"5").positions
	
	return retVec

func getRustPosition() -> Vector2:
	
	var retVec = position#getPosition()
	
	#var neg_left = -1.0 if left else 1.0
	
	match spear_level:
		0:
			retVec += 2.0 * size * Vector2(0, -49) #-8.5*6
		1:
			retVec += 2.0 * size * Vector2(0, -61.75) #-8.5*7.5
		2:
			retVec += 2.0 * size * Vector2(0, -66) #-8.5*8.0
		3:
			retVec += 2.0 * size * Vector2(0, -66) #-8.5*8.0
		#4:
		#	retVec += size * Vector2(12, -70) #2 + -12*6
	
	return retVec#.rotated(totalRot)


func _on_do_t_tick_timer_timeout() -> void:
	
	match spear_level:
		0:
			$HitboxDOT/SecondShape2D.set_deferred("disabled", first_hitbox_enabled)
			$HitboxDOT/CollisionShape2D.set_deferred("disabled", not first_hitbox_enabled)
		1:
			$HitboxDOT/SecondShape2D2.set_deferred("disabled", first_hitbox_enabled)
			$HitboxDOT/CollisionShape2D2.set_deferred("disabled", not first_hitbox_enabled)
		2:
			$HitboxDOT/SecondShape2D3.set_deferred("disabled", first_hitbox_enabled)
			$HitboxDOT/CollisionShape2D3.set_deferred("disabled", not first_hitbox_enabled)
		3:
			$HitboxDOT/SecondShape2D4.set_deferred("disabled", first_hitbox_enabled)
			$HitboxDOT/CollisionShape2D4.set_deferred("disabled", not first_hitbox_enabled)
	first_hitbox_enabled = not first_hitbox_enabled
	
	if _detectionCheck():
		$DoTTickTimer.start(dot_timer)
	else:
		$HitboxDOT.set_deferred("monitoring", false)

func _detectionCheck() -> bool:
	if rust_level >= rust_max:
		return false
	
	var detectNode = $HitboxSpear
	
	if (detectNode.has_overlapping_areas() or detectNode.has_overlapping_bodies()):
			return true
			
	return false

func setDamage(new_dmg : float) -> void:
	$HitboxDOT.setDamage(new_dmg*0.6)
	$HitboxSpear.setDamage(new_dmg)
	$Hitbox.setDamage(new_dmg)

func _on_hitbox_spear_area_entered(area: Area2D) -> void:
	var duration = _applyAndCalcPoison(false)
	if duration > 0:
		area.getParent().applyPoison(poison_damage, duration, self)

func _on_hitbox_spear_body_entered(body: Node2D) -> void:
	var duration = _applyAndCalcPoison(false)
	if duration > 0:
		body.applyPoison(poison_damage, duration, self)


func _on_hitbox_area_entered(area: Area2D) -> void:
	var targetNode = area.getParent()
	if not impaled and impale:
		if targetNode.getWeight() < impale_weight_limt:
			targetNode.dragGrab()
			imp_ref = targetNode
			impaleEnemy()
			
	
	var duration = _applyAndCalcPoison()
	if duration > 0:	
		targetNode.applyPoison(poison_damage, duration, self)
	

func _on_hitbox_body_entered(body: Node2D) -> void:
	var duration = _applyAndCalcPoison()
	if duration > 0:	
		body.applyPoison(poison_damage, duration, self)
	if not impaled and impale:
		if body.getWeight() < impale_weight_limt:
			body.dragGrab()
			imp_ref = body
			impaleEnemy()

func _applyAndCalcPoison(spearOrInject : bool = true) -> float:
	if not dot:
		return 0.0
	
	if poison_tween:
		poison_tween.kill()
	poison_tween = create_tween().set_parallel()
	
	var rusted = rust_level >= rust_max
	
	if spear_level == 4 and not spearOrInject:
		var poison_loss = poison_amount / 12.0
		var poison_loss_amt = poison_amount * 0.8
		poison_tween.tween_property(self, "poison_amount", poison_loss_amt, poison_loss)
		poison_tween.tween_method(_setRedPoisonShader, poison_amount, poison_loss_amt, poison_loss)
		poison_tween.finished.connect(_poisonInitialFinished.bind(poison_loss))
		return poison_amount * 0.25 if rusted else poison_amount * 0.2
	else:
		var poison_loss = poison_amount / 6.0
		poison_tween.tween_property(self, "poison_amount", 0, poison_loss)
		poison_tween.tween_method(_setPoisonShader, poison_amount, 0, poison_loss)
		poison_tween.finished.connect(_poisonInitialFinished.bind(poison_loss))
		return poison_amount * 1.25 if rusted else poison_amount

func _poisonInitialFinished(poison_lost : float) -> void:
	if poison_tween:
		poison_tween.kill()
	poison_tween = create_tween().set_parallel()

	if spear_level == 4: 
		var dot_amt = 0.4/dot_timer
		if rust_level < rust_max:
			var poison_remaining = max((poison_max*damage_mult) - poison_amount - poison_lost, 0.0) / (poison_gain_rate * dot_amt)
			poison_tween.tween_property(self, "poison_amount", 2.0*poison_max, poison_remaining)
			poison_tween.tween_method(_setRedPoisonShader, poison_amount, 2.0*poison_max, poison_remaining)
			#poison_tween.finished.connect(_poisonEnd.bind(0.0))
		else:
			var poison_remaining = max((poison_max*damage_mult) - poison_amount - poison_lost, 0.0) / (poison_gain_rate * dot_amt)
			poison_tween.tween_property(self, "poison_amount", poison_max, poison_remaining)
			poison_tween.tween_method(_setRedPoisonShader, poison_amount, poison_max, poison_remaining)
			#poison_tween.finished.connect(_poisonEnd.bind(0.0))
	else:
		var poison_remaining = max(poison_max - poison_amount - poison_lost, 0.0) / poison_gain_rate
		poison_tween.tween_property(self, "poison_amount", poison_max, poison_remaining)
		poison_tween.tween_method(_setPoisonShader, poison_amount, poison_max, poison_remaining)
		#poison_tween.finished.connect(_poisonEnd.bind(0.0))

func _setPoisonShader(poison_prog : float) -> void:
	$Spear1/Juice.material.set_shader_parameter("progress", poison_prog/poison_max)

func _setRedPoisonShader(poison_prog : float) -> void:
	$Spear5/Juice.material.set_shader_parameter("progress", poison_prog/poison_max)

func impaleEnemy() -> void:
	impaled = true
	
	if impale_tween:
		impale_tween.kill()
	impale_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	impale_tween.tween_method(setImpaledEnemyPos, -61, -20, impale_max_dura)
	impale_tween.finished.connect(impaleEnd)

func setImpaledEnemyPos(impale_offset : float) -> void:
	var currentRot = parentRef.getRotation()
	
	var returnPos = getPosition() + size * Vector2(0, impale_offset).rotated(currentRot)
	
	if imp_ref.updateGrabPos(returnPos, currentRot): 
		impaleEnd(true)

func impaleEnd(isDead : bool = false) -> void:
	if impale_tween:
		impale_tween.kill()
	if not isDead:
		imp_ref.endGrab()	
		imp_ref.takeDamage(6*damage_mult, imp_ref.getPosition() + Vector2(0,1).rotated(parentRef.getRotation()), 2.5)
	imp_ref = null
	impaled = false
	
