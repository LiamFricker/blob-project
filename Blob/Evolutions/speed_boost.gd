extends Node2D

@export var duration : float = 5.0
@onready var crysRef : Node2D = $Crystal
@onready var anim_player : Node2D = $AnimationPlayer
@onready var meterRef : Node2D = $ChargeBar/ChargeMeter
var chargeRefund : float = 0.0

@export var chargeRefundRatio : float = 0.2

const BASE_COOLDOWN : float = 8.0
@export var charge_speed : float = 1.0

@export var buff_type : int = 0

#Trail variables
@export var playerRef : Node2D
var trail_points : PackedVector2Array = []
var trail_count = 0
var lastPoint : Vector2  
var posOffset : Vector2 = Vector2.ZERO 

var crystal_tween
var waddle_tween

signal crystal_activated()
signal crystal_canceled(decay_rate : float)
signal boost_off_cooldown()

func addPos(newpos) -> void:
	posOffset += newpos

func setParams(new_duration : float = 5.0, new_speed : float = 1.0, new_ratio : float = 0.2, tp : int = 0) -> void:
	duration = new_duration
	charge_speed = new_speed
	chargeRefundRatio = new_ratio
	buff_type = tp

#Remember to reset waddle check once the anim is done or the duration is up
func beginWaddle() -> void:
	if crysRef.visible == true and not anim_player.is_playing():
		if waddle_tween:
			waddle_tween.kill()
		waddle_tween = create_tween().set_loops()
		waddle_tween.tween_property(crysRef, "rotation", -0.1, 0.1).as_relative()
		waddle_tween.tween_property(crysRef, "rotation", 0.1, 0.1).as_relative()
		waddle_tween.tween_property(crysRef, "rotation", 0.1, 0.1).as_relative()
		waddle_tween.tween_property(crysRef, "rotation", -0.1, 0.1).as_relative()

func endWaddle() -> void:
	if waddle_tween:
		waddle_tween.kill()
	waddle_tween = create_tween()
	waddle_tween.tween_property(crysRef, "rotation", -0.19 * PI, 0.2)

func activate(speed = 1.0) -> void:
	anim_player.play("Activate", -1, speed)
	if waddle_tween:
		waddle_tween.kill()
	
func spitOutCrystal(speed = 1.0) -> void:
	chargeRefund = chargeRefundRatio * $DurationTimer.time_left / duration
	$DurationTimer.stop()
	_activateTrailEffect()
	if buff_type == 1:
		$Slipstream.deactivate()
	
	if waddle_tween:
		waddle_tween.kill()
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
			crystal_canceled.emit(1.0 / (1.0 - chargeRefund))
			_regrowRainbows()
		"RegurgitateBig":
			crystal_canceled.emit(1.0 / (1.0 - chargeRefund))
			_regrowBigRainbows()

func _chargeBarActivate() -> void:
	lastPoint = playerRef.getPosition()
	trail_points.append(lastPoint)
	
	if buff_type == 1:
		$Slipstream.activate()
	
	$DurationTimer.start()
	$ChargeBar/Spark.show()
	$ChargeBar/Spark.play()
	$TrailEffect.start()
	if crystal_tween:
		crystal_tween.kill()
	crystal_tween = create_tween()
	crystal_tween.tween_property(meterRef, "scale:y", 0.0, duration).from(1.0)
	crystal_tween.parallel().tween_property(meterRef, "modulate", Color("ff0000c9"), duration).from(Color("c6ff5cc9"))
	crystal_tween.parallel().tween_property($ChargeBar/Spark, "position:y", 22.5, duration).from(22.5)
	
	if waddle_tween:
		waddle_tween.kill()
	waddle_tween = create_tween().set_loops()
	waddle_tween.tween_property($ChargeBar, "rotation", -0.02, 0.1)
	waddle_tween.tween_property($ChargeBar, "rotation", 0.02, 0.1)

func _on_duration_timer_timeout() -> void:
	$ChargeBar/Spark.hide()
	$ChargeBar/Spark.stop()
	_activateTrailEffect()
	if buff_type == 1:
		$Slipstream.deactivate()
	crysRef.position = Vector2(-18, 19)
	crysRef.rotation = -0.3 * PI
	crysRef.scale = Vector2(0.5, 0.5)
	crysRef.show()
	crystal_canceled.emit(1.0)
	if waddle_tween:
		waddle_tween.kill()
	waddle_tween = create_tween().set_loops()
	waddle_tween.tween_property($ChargeBar, "rotation", 0, 0.1)
	
	_regrowRainbows()
	
func _regrowRainbows(chargeRefund = 0.0) -> void:
	var remaining_cooldown = BASE_COOLDOWN - chargeRefund
	
	if crystal_tween:
		crystal_tween.kill()
	crystal_tween = create_tween()
	crystal_tween.tween_property(crysRef, "position", Vector2(-22, 16), remaining_cooldown / charge_speed)
	crystal_tween.parallel().tween_property(crysRef, "scale", Vector2(1, 1), remaining_cooldown / charge_speed)
	crystal_tween.parallel().tween_property(crysRef, "rotation", -0.19 * PI, remaining_cooldown / charge_speed)
	crystal_tween.parallel().tween_property(meterRef, "scale:y", 1.0, remaining_cooldown / charge_speed)
	crystal_tween.parallel().tween_property(meterRef, "modulate", Color("c6ff5cc9"), remaining_cooldown / charge_speed)
	crystal_tween.finished.connect(_chargeOffCD)
	
func _regrowBigRainbows(chargeRefund = 0.0) -> void:
	var remaining_cooldown = BASE_COOLDOWN - chargeRefund
	if crystal_tween:
		crystal_tween.kill()
	crystal_tween = create_tween()
	crystal_tween.tween_property(meterRef, "scale:y", 1.0, remaining_cooldown / charge_speed)
	crystal_tween.parallel().tween_property(meterRef, "modulate", Color("c6ff5cc9"), remaining_cooldown / charge_speed)
	crystal_tween.finished.connect(_chargeOffCD)
	
func _chargeOffCD() -> void:
	boost_off_cooldown.emit()

func _chargeFinished() -> void:
	boost_off_cooldown.emit()
	if crystal_tween:
		crystal_tween.kill()
	crystal_tween = create_tween()
	crystal_tween.tween_property(crysRef, "modulate", Color("ffffff"), 0.1)
	crystal_tween.tween_property(crysRef, "modulate", Color("d9d9d9"), 0.1)

func _on_trail_timer_timeout() -> void:
	var newPos = playerRef.getPosition()
	$TrailEffect.addPosition(newPos-lastPoint)
	lastPoint = newPos
	$TrailTimer.start()
	
	trail_count += 1
	#Should probably also drop the bombs here too. 
	if trail_count % 2 == 0:
		#trail_count = 0
		trail_points.append(newPos)
		#Spawn bomb
		if trail_count % 4 == 0:
			pass
	
#this means the hitbox and the collection	
func _activateTrailEffect() -> void:
	$TrailTimer.stop()
	$TrailEffect.beginDecay()
	
	#Placeholder
	trail_points = []
