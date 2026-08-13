extends Node2D

@export var duration : float = 5.0
@onready var crysRef : Node2D = $Pivot/Crystal
@onready var anim_player : AnimationPlayer = $AnimationPlayer
@onready var meterRef : Node2D = $ChargeBar/ChargeMeter
var chargeRefund : float = 0.0

@export var chargeRefundRatio : float = 0.2

const BASE_COOLDOWN : float = 8.0
@export var charge_speed : float = 1.0

@export var buff_type : int = 0

#Trail variables
@export var playerRef : Node2D
var posOffset : Vector2 = Vector2.ZERO 

var crystal_tween
var waddle_tween
var waddle_state = 0

@export var is_charge : bool = false
var spawnRef : Node2D 

#detonate vars
@export var detonate : bool = true
var trail_points : PackedVector2Array = []
var trail_count = 0
var lastPoint : Vector2  
@export var detonation_size : float = 50

#bomb vars
const bomb_dmg = 5.0
const bomb_kb = 0.5
@export var bomb_ticks : int = 10
@export var bomb_cd : int = 4

signal crystal_activated()
signal crystal_canceled(decay_rate : float, detonate : bool, sz : float, posArr : PackedVector2Array)
signal boost_off_cooldown()
signal spawn_bomb(dmg : float, kb : float, sz : float, ticks : int)
signal damagedEnemy(amt : float)

func _damagedEnemy(amt : float) -> void:
	damagedEnemy.emit(amt)

func _ready() -> void:
	if playerRef:
		spawnRef = playerRef.spawnerReference
	if is_charge:
		$Pivot.position = Vector2(6, -6)
	else:
		$Pivot.position = Vector2(0, 0)

func getPosition() -> Vector2:
	return playerRef.getPosition()

func addPos(newpos) -> void:
	posOffset += newpos

func changeRot(newangle : float) -> void:
	$Pivot.rotation = newangle

func changeScale(newscale : Vector2) -> void:
	$Pivot.scale = newscale

func setParams(new_duration : float = 5.0, new_speed : float = 1.0, new_ratio : float = 0.2, tp : int = 0) -> void:
	duration = new_duration
	charge_speed = new_speed
	chargeRefundRatio = new_ratio
	buff_type = tp

#Remember to reset waddle check once the anim is done or the duration is up
func beginWaddle() -> void:
	if waddle_state == 0:#crysRef.visible == true and not anim_player.is_playing() and :
		waddle_state = 1
		if waddle_tween:
			waddle_tween.kill()
		waddle_tween = create_tween().set_loops()
		waddle_tween.tween_property(crysRef, "rotation", -0.15, 0.15).as_relative()
		waddle_tween.tween_property(crysRef, "rotation", 0.15, 0.15).as_relative()
		waddle_tween.tween_property(crysRef, "rotation", 0.15, 0.15).as_relative()
		waddle_tween.tween_property(crysRef, "rotation", -0.15, 0.15).as_relative()

func endWaddle() -> void:
	if waddle_state == 1:#crysRef.visible == true and not anim_player.is_playing() and 
		waddle_state = 0
		if waddle_tween:
			waddle_tween.kill()
		waddle_tween = create_tween()
		if crysRef.rotation >= 2 * PI:
			crysRef.rotation -= 4 * PI
		waddle_tween.tween_property(crysRef, "rotation", -0.19 * PI, 0.3)

func activate(speed = 1.0) -> void:
	waddle_state = 2
	anim_player.play("Activate", -1, speed)
	if waddle_tween:
		waddle_tween.kill()
	waddle_tween = create_tween()
	waddle_tween.tween_property($ChargeBar, "modulate:a", 1.0, 0.49 / speed)
	
func spitOutCrystal(speed = 1.0) -> void:
	chargeRefund = chargeRefundRatio * $DurationTimer.time_left / duration
	var minDecayRate = max(0.1, 1.0 - chargeRefund)
	$DurationTimer.stop()
	$ChargeBar/Spark.hide()
	if detonate:	
		$TrailTimer.stop()
		#trail_points = [Vector2.ZERO, Vector2(100, 0), Vector2(200, 0)]
		crystal_canceled.emit(minDecayRate, true, detonation_size, trail_points)
	else:
		crystal_canceled.emit(minDecayRate, false, 0.0, [])
	
	if crystal_tween:
		crystal_tween.kill()
	
	if chargeRefund < 1.0:	
	
		var newColor = Color(0.78, 1.0, 0.36, 0.79).lerp(Color(1.0, 0.0, 0.0, 0.79), 1.0-chargeRefund)
		var newPos = 22.5 - 45 * chargeRefund
		
		if waddle_tween:
			waddle_tween.kill()
		waddle_tween = create_tween().set_loops()
		waddle_tween.tween_property($ChargeBar, "rotation", 0, 0.1)
		waddle_tween.parallel().tween_property(meterRef, "scale:y", chargeRefund, 0.49 / speed)
		waddle_tween.parallel().tween_property(meterRef, "color", newColor, 0.49 / speed)
		waddle_tween.parallel().tween_property($ChargeBar/Spark, "position:y", newPos, 0.49 / speed)
		if buff_type == 1:
			$Slipstream.set_deferred("monitorable", false)
			$Pivot/AnimatedSprite2D2.stop()
			waddle_tween.parallel().tween_property($Pivot/AnimatedSprite2D2, "modulate:a", 0.0, 0.49 / speed)
	else:
		if waddle_tween:
			waddle_tween.kill()
		waddle_tween = create_tween().set_loops()
		waddle_tween.tween_property($ChargeBar, "rotation", 0, 0.1)
		waddle_tween.parallel().tween_property(meterRef, "scale:y", 1.0, 0.49 / speed)
		waddle_tween.parallel().tween_property(meterRef, "color", Color(0.78, 1.0, 0.36, 0.79), 0.49 / speed)
		waddle_tween.parallel().tween_property($ChargeBar/Spark, "position:y", -22.5, 0.49 / speed)
		if buff_type == 1:
			$Slipstream.set_deferred("monitorable", false)
			$Pivot/AnimatedSprite2D2.stop()
			waddle_tween.parallel().tween_property($Pivot/AnimatedSprite2D2, "modulate:a", 0.0, 0.49 / speed)
	
	if chargeRefund < 0.9:	
		anim_player.play("Regurgitate", -1, speed)
	else:
		anim_player.play("RegurgitateBig", -1, speed)
		
#This allows for a weird tech where people can regurgitate to extend duration briefly.
#I kinda like keeping that in ngl.
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"Activate":
			crystal_activated.emit()
			_chargeBarActivate()
		"Regurgitate":
			_regrowRainbows()
		"RegurgitateBig":
			_regrowBigRainbows()

func _chargeBarActivate() -> void:
	
	$DurationTimer.start(duration)
	$ChargeBar/Spark.show()
	$ChargeBar/Spark.play()
	$ChargeBar.modulate.a = 1.0
	#$TrailEffect.start()
	if detonate:
		#lastPoint = playerRef.getPosition()
		trail_points.clear()	
		trail_points.append(playerRef.getPosition())
		$TrailTimer.start()
	#meterRef.modulate = Color("c6ff5cc9")
	
	if crystal_tween:
		crystal_tween.kill()
	crystal_tween = create_tween()
	crystal_tween.tween_property(meterRef, "scale:y", 0.0, duration).from(1.0)
	crystal_tween.parallel().tween_property(meterRef, "color", Color(1.0, 0.0, 0.0, 0.79), duration).from(Color(0.78, 1.0, 0.36, 0.79))
	crystal_tween.parallel().tween_property($ChargeBar/Spark, "position:y", 22.5, duration).from(-22.5)
	if buff_type == 1:
		$Slipstream.set_deferred("monitorable", true)
		$Pivot/AnimatedSprite2D2.play("default")
		crystal_tween.parallel().tween_property($Pivot/AnimatedSprite2D2, "modulate:a", 1.0, 0.25)
	
	if waddle_tween:
		waddle_tween.kill()
	waddle_tween = create_tween().set_loops()
	waddle_tween.tween_property($ChargeBar, "rotation", -0.02, 0.1)
	waddle_tween.tween_property($ChargeBar, "rotation", 0.02, 0.1)

func _on_duration_timer_timeout() -> void:
	chargeRefund = 0.0
	$ChargeBar/Spark.hide()
	$ChargeBar/Spark.stop()
	if detonate:	
		$TrailTimer.stop()
		#trail_points = [Vector2.ZERO, Vector2(100, 100), Vector2(200, 200)]
		crystal_canceled.emit(1.0, true, detonation_size, trail_points)
	else:
		crystal_canceled.emit(1.0, false, 0.0, [])
	
	crysRef.position = Vector2(-18, 19)
	crysRef.scale = Vector2(0.5, 0.5)
	crysRef.show()
	if waddle_tween:
		waddle_tween.kill()
	waddle_tween = create_tween().set_loops()
	waddle_tween.tween_property($ChargeBar, "rotation", 0, 0.1)
	if buff_type == 1:
		$Slipstream.set_deferred("monitorable", false)
		$Pivot/AnimatedSprite2D2.stop()
		waddle_tween.parallel().tween_property($Pivot/AnimatedSprite2D2, "modulate:a", 0.0, 0.25)
	
	_regrowRainbows()
	
func _regrowRainbows() -> void:
	#if waddle_tween:
	#	waddle_tween.kill()
	$ChargeBar.rotation = 0
	crysRef.rotation = -0.3 * PI
	
	var remaining_cooldown = BASE_COOLDOWN * (1.0 - chargeRefund)
	
	if crystal_tween:
		crystal_tween.kill()
	crystal_tween = create_tween()
	crystal_tween.tween_property(crysRef, "position", Vector2(-22, 16), remaining_cooldown / charge_speed)
	crystal_tween.parallel().tween_property(crysRef, "scale", Vector2(1, 1), remaining_cooldown / charge_speed)
	crystal_tween.parallel().tween_property(crysRef, "rotation", -0.19 * PI, remaining_cooldown / charge_speed)
	crystal_tween.parallel().tween_property(meterRef, "scale:y", 1.0, remaining_cooldown / charge_speed)
	crystal_tween.parallel().tween_property(meterRef, "color", Color("c6ff5cc9"), remaining_cooldown / charge_speed)
	crystal_tween.finished.connect(_chargeOffCD)
	
func _regrowBigRainbows() -> void:
	#if waddle_tween:
	#	waddle_tween.kill()
	$ChargeBar.rotation = 0
	crysRef.rotation = -0.3 * PI
	
	if chargeRefund < 1.0:
		var remaining_cooldown = BASE_COOLDOWN * (1.0 - chargeRefund)
		if crystal_tween:
			crystal_tween.kill()
		crystal_tween = create_tween()
		crystal_tween.tween_property(meterRef, "scale:y", 1.0, remaining_cooldown / charge_speed)
		crystal_tween.parallel().tween_property(meterRef, "color", Color("c6ff5cc9"), remaining_cooldown / charge_speed)
		crystal_tween.finished.connect(_chargeOffCD)
	else:
		_chargeOffCD()
	
func _chargeOffCD() -> void:
	boost_off_cooldown.emit()
	waddle_state = 0
	
	if crystal_tween:
		crystal_tween.kill()
	crystal_tween = create_tween()
	crystal_tween.tween_property(meterRef, "color", Color("f7ff00c9"), 0.2)
	crystal_tween.tween_property(meterRef, "color", Color("c6ff5cc9"), 0.25)
	crystal_tween.tween_property($ChargeBar, "modulate:a", 0.0, 1.0)
	

func _on_trail_timer_timeout() -> void:
	var newPos = playerRef.getPosition()
	trail_points.append(newPos)
	
	
	trail_count += 1
	#Should probably also drop the bombs here too. 
	if trail_count % bomb_cd == 0:
		#trail_count = 0
		#Spawn bomb
		spawn_bomb.emit(bomb_dmg, bomb_kb, 62.3, bomb_ticks)

func getSPAWNID(isDeto : bool) -> int:
	if isDeto:
		return 1011
	else:
		return 1012

func getID() -> int:
	return playerRef.getID()
