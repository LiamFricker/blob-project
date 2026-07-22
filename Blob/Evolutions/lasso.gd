extends Node2D

#Stealing code from a better game~

#Need to remember to do a collision check at the ending location if the player will overlap with a solid object
#We also don't know what the collision variable will be for now so let's just say 5

signal lassoLocationReached()
signal lassoThrowCancel()

#var currentPos : Vector2 = Vector2.ZERO
var finalLocation : Vector2 = Vector2.ZERO
var thrownAngle : float = 0
var lassoLength : float = 1.0
@export var throwSpeed : float = 1.0

var lasso_tween #all purpose tween for now cause I LOVE tweens compared to when I wrote this code

@export var damage = 0
@export var knockback = 0
var playerRef : Node2D

const impactID : int = 1001
const orbBoonID : int = 1002
const idleBoonID : int = 1003
#Placeholder, won't be adding this for now
const combatBoonID : int = 1004

@onready var centerRef : Node2D = $Center
@onready var tongueRef : Node2D = $Center/Length
@onready var endRef : Node2D = $Center/End

var throwing = true

var lassoProgress : float = 0.0
@export var progressGainSpeed : float = 1.0
@export var maxProgress : float = 1.0
@export var minProgress : float = 0.1
@export var baseProgress : float = 0.4

@export var maxLen : float = 300.0 * maxProgress

#You should probably spawn an entity at the location. The player itself can probably handle that.  
#Have it be named "delayed shockwave or something"

func getID(type : int) -> int:
	match type:
		0:
			return impactID
		1:
			return orbBoonID
		2:
			return idleBoonID
		3:
			return combatBoonID
		_:
			return impactID

#These variables all go into the Area2D collision. 
func getParent() -> Node2D:
	return playerRef
	
func getDamage() -> float:
	return damage

#Change this to the position of the tip.
#Or the movement object
func getPosition() -> Vector2:
	return position

#I want to make the knockback particular but we can just ignore it for now.
func getKnockback() -> float:
	return knockback


#var sprite 
var distance_vector = Vector2(0,0)
var ghost_vector = Vector2(0,0)
#var tongue_speed = 3.0 Commenting this out to show that I overhauled this mechanic 
#var tongue_speed = 2.0

var tongue_distance = 0
var angle = 0.0

var descend_down = false
var frog_seperation = 0

const TONGUE_BASE_LENGTH = 34
#const TONGUE_BASE_WIDTH = 18
#const TONGUE_TIP_RADIUS = 16

var eat = false
var despawn = false

var start = true
var retract = false

var target_enemy = Node2D
var tongue_timer = 0.0

@export var mana_mult = 0.6
"""
func _ready():
	print("Alive")
	print(position.x)
	print(position.y)
"""
func _ready():
	#$Lifetime.wait_time = lifetime
	pass 
	
func _process(delta):
	if eat:
		eating(delta)

func setParams():
	pass
	
func activate() -> void:
	show()
	set_process(true)
	"""
	if lasso_tween:
		lasso_tween.kill()
	lasso_tween = create_tween()
	lasso_tween.tween_property(tongueRef, "scale", Vector2(1,1), 0.2)
	lasso_tween.parallel().tween_property(endRef, "position", Vector2(32,0.1), 0.2)
	lasso_tween.parallel().tween_property(centerRef, "angle", -1.28*PI, 0.2)
	lasso_tween.parallel().tween_property(centerRef, "position", Vector2(-6,4), 0.2)
	"""
	endRef.position = Vector2(32,0.1)
	tongueRef.scale = Vector2(1,1)
	centerRef.scale = Vector2(0, 1)
	#centerRef.angle = -1.28*PI
	#centerRef.position = Vector2(-6,4)
	#lasso_tween.finished.connect(beginLasso)
	beginLasso()	
	
func beginLasso() -> void:
	$AnimationPlayer.play("SpinLasso")
	$ThrowRange.show()
	if lasso_tween:
		lasso_tween.kill()
	lasso_tween = create_tween()
	var scaleVec = Vector2(1,1) * (baseProgress + maxProgress * 0.1)  
	lasso_tween.tween_property(self, "lassoProgress", maxProgress, maxProgress * 3.0 / progressGainSpeed)
	lasso_tween.parallel().tween_property($ThrowRange, scale, scaleVec, maxProgress * 3.0 / progressGainSpeed)
	lasso_tween.parallel().tween_property($CenterRef, scale, Vector2(1,1), 0.2)

func endLasso(relativePos : Vector2) -> void:
	$ThrowRange.hide()
	$ThrowRange.scale = Vector2(baseProgress,baseProgress)
	if lassoProgress < minProgress:
		cancelLasso()
		lassoThrowCancel.emit()
	else:
		finalLocation = relativePos
		tongue_distance = 0
		if lasso_tween:
			lasso_tween.kill()
		lasso_tween = create_tween()
		#lasso_tween.tween_property(tongueRef, "scale", Vector2(0,1), 0.2)
		#lasso_tween.parallel().tween_property(endRef, "position", Vector2(0,0), 0.2)
		var tempAngle = (-(playerRef.getPosition() - (relativePos))).angle()
		lasso_tween.tween_property(centerRef, "angle", tempAngle, 0.1).as_relative()
		lasso_tween.parallel().tween_property(centerRef, "position", Vector2(0,0), 0.1)
		lasso_tween.finished.connect(beginThrow)
		
		#start = true

func cancelLasso() -> void:
	$Center.z_index = 0
	if lasso_tween:
		lasso_tween.kill()
	lasso_tween = create_tween()
	lasso_tween.tween_property(tongueRef, "scale", Vector2(0,1), 0.2)
	lasso_tween.parallel().tween_property(endRef, "position", Vector2(0,0), 0.2)
	lasso_tween.parallel().tween_property(centerRef, "angle", 2*PI, 0.2).as_relative()
	lasso_tween.parallel().tween_property(centerRef, "position", Vector2(0,0), 0.2)

func beginThrow() -> void:	
	start = true	

func cancelThrow() -> void:
	start = false
	if lasso_tween:
		lasso_tween.kill()
	lasso_tween = create_tween()
	 #This may not be aligned. If so, try to align it or do this in process
	lasso_tween.tween_property(tongueRef, "scale", Vector2(0,1), lassoProgress * 0.3) 
	lasso_tween.parallel().tween_property(endRef, "position", Vector2(0,0), lassoProgress * 0.3) 
	lasso_tween.parallel().tween_property(centerRef, "angle", 0.1, 0.1).as_relative()
	lasso_tween.tween_property(centerRef, "angle", -0.1, 0.1).as_relative()
	lasso_tween.tween_property(centerRef, "angle", 0.1, 0.1).as_relative()
	lasso_tween.tween_property(centerRef, "angle", -0.1, 0.1).as_relative()
	lasso_tween.tween_property(centerRef, "angle", 0.0, 0.1).as_relative()
	lasso_tween.finished.connect(deactivate)

func deactivate() -> void:
	$RetractHitbox.set_deferred("monitorable", false)
	hide()
	set_process(false)

func startAnim() -> void:
	$AnimationPlayer.play("SpinLasso")

func eating(delta):
	#This has got to be the most messy code outside of any of the player code
	
	#Yeah too bad this ain't happening
	#if get_parent().flipped_direction:
	#	apply_scale(Vector2(-1,1))
	#	$FrogSprite/Tongue.apply_scale(Vector2(-1,1))
	#	$FrogSprite/Area2D.apply_scale(Vector2(-1,1))
	if start:
		#ghost_vector = -(playerRef.getPosition() - (finalLocation))
		distance_vector = -(playerRef.getPosition() - (finalLocation))
		#So we gotta replicate this code but with a CHANGING ROTATIONAL ANGLE HAHAHAAHHA
		#I LOVE EXCESS COMPLEXITY
		#But realistically, charge angle only changes the sprite and this would be added to Inner
		#SO IM SAFE AHAHAHAHAHA
		#if playerRef.current_angle == 0:
		#	pass
		#if get_parent().face_direction == -1:
		#	distance_vector = ghost_vector - Vector2(7,-1.2)
		#	distance_vector.x = -1 * distance_vector.x
			
			#This is the one with the bugs right now. It points at the opposite side. Fix this.
		#else:
			#distance_vector = ghost_vector - Vector2(-7,-1.2)
		angle = distance_vector.angle()
		
		var disLen = distance_vector.length()
		if disLen >= maxLen:
			cancelThrow()
		
		if throwing:
			if tongue_distance <= (disLen): 
				retract = true
				tongue_timer += throwSpeed * delta * 250 / disLen
				angle += sin(tongue_timer) / tongue_timer
			elif throwing:
				throwing = false
				lassoLocationReached.emit()
				if lasso_tween:
					lasso_tween.kill()
				lasso_tween = create_tween()
				lasso_tween.tween_property(self, "angle", -sin(tongue_timer) / tongue_timer, 0.25).as_relative()
				#angle += 0.5 * sin(tongue_timer) / tongue_timer
			tongue_distance = (distance_vector.length() * tongue_timer)
		else:
			tongue_distance = (distance_vector.length())
		
		centerRef.rotation = angle
		
		#God I wonder why this is so fucking buggy
		#tongue_distance += (tongue_speed * delta * 60 * TONGUE_BASE_LENGTH)
		#There: fixed
		
		
		#God I wonder why this is so fucking buggy and the tongue kept clipping huh?
		#$FrogSprite/Tongue.scale.x += tongue_speed * delta * 60
		
		#The frog's tongue is a length ~7px at 0.2x scale. 
		tongueRef.scale.x = (1) + (tongue_distance / TONGUE_BASE_LENGTH)
		
		#35.5 is length of base tongue vector(35, -6)
		#nvm that was dumb, should be fixed now
		#?!??!?!?!?!? HAHAHAHAHA THIS DUMBASS HAD THE FROG SCALE BY 0.2x, THE TOUNGE AXIS SCALED BY 0.8, AND THE TONGUE SCALED BY 2
		#HOW THE HELL IS THAT GOING TO HELP ?!??!?!?!?!
		#NOW I HAVE TO FUCKING SCALE EVERYTHING BY 5 SO IT DOESNT KILL ALL THE ANIMATIONS 
		#You know what screw, that. Removing all scaling on the base sprite.
		
		#Yeah ok wtf is all this?
		#$FrogSprite/Area2D.position.x = 35 +($FrogSprite/Tongue.scale.x / 0.8 - 1) * TONGUE_BASE_LENGTH * 4 * cos(distance_vector.angle())
		#$FrogSprite/Area2D.position.y = -6 + ($FrogSprite/Tongue.scale.x / 0.8 - 1) * TONGUE_BASE_LENGTH * 4 * sin(distance_vector.angle())
		endRef.position = tongue_distance * Vector2(cos(angle), sin(angle))
		
		#Some enemy register boxes aren't completely aligned with the hitbox. Make it a bit bigger incase.
		
	#We don't need to retract so this can stay constant.
	"""
	elif tongue_distance > TONGUE_BASE_LENGTH: 	
		if get_parent().face_direction == -1:
			distance_vector = ghost_vector - Vector2(7,-1.2)
			distance_vector.x = -1 * distance_vector.x
		else:
			distance_vector = ghost_vector - Vector2(-7,-1.2)
		#This was equally as horrendous as the previous case. I deleted it all to preserve your sanity
		angle = distance_vector.angle()
		
		$FrogSprite/Tongue.rotation = angle
		$FrogSprite/Area2D.rotation = angle
		
		tongue_timer -= 1.5 * tongue_speed * delta 
		tongue_distance = (distance_vector.length() * tongue_timer)
		
		$FrogSprite/Tongue.scale.x = (1) + (tongue_distance / 7.0)
		
		$FrogSprite/Area2D.position.x = 7 + (tongue_distance * cos(angle))
		$FrogSprite/Area2D.position.y = -1.2 + (tongue_distance * sin(angle))
	"""
	"""
	else:
		$AttackCooldown.start()
		$DetectionRange.position.y += 10000
		$DetectionRange.monitoring = false
		$FrogSprite/Sprite2D.play_backwards("eat") 
		$FrogSprite/Tongue.visible = false
		$FrogSprite/Area2D.visible = false
		$FrogSprite/Area2D.monitorable = false
		eat = false
		start = true
	"""
		
func _on_animation_player_animation_finished(anim_name):
	match anim_name:
		"Spawn":
			$DetectionRange.monitoring = true
		"Despawn":
			queue_free()

#Hey this code is pretty useful huh
func setDamage(dmg : float) -> void:
	$FrogSprite/Area2D.damage = dmg * 2.0

func _on_attack_cooldown_timeout():
	$DetectionRange.position.y -= 10000
	$DetectionRange.monitoring = true
	
func _on_area_2d_body_entered(body):
	if body == target_enemy:
		retract = true
		print("hit enemy")
