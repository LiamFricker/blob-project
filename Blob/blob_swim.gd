extends CharacterBody2D

enum {
	IDLE,
	FLOAT,
	CHARGE,
	CHARGING, 
	JAVELIN,
	SHROOM
}
var state = IDLE

@export var mouseMovement : bool = true
var mouseCenter : Vector2 = Vector2(1152/2.0, 648/2.0)
var mousePos : Vector2 = Vector2.ZERO

@export var camReference : Camera2D
@export var spawnerReference : Node2D
var children_list : Array = []
var children_count : int = 0

#Offensive variables
var damage : float = 1.0
var base_knockback : float = 1.0
var attack_mods : Array = [false, false, false, false, false]

var damage_dealt : float = 0.0
var damage_dealt_check : float = 0.0

var energy = 100
var max_energy = 100
signal currencyUpdate(index : int, value : float)
signal spawnOrbs(amt : int, pos : Vector2)
#Upgrades and bonuses count
var staticBonuses = []
var upgradeTab1 = [0, 0, 0]
var upgradeTab2 = [0, 0, 0]
var upgradeTab3 = [0, 0, 0]
var upgradeBonuses = [upgradeTab1, upgradeTab2, upgradeTab3]

var primary_queued = false

var basic_tween #meant for basic movement abilities
var primary_tween #meant for primary abilities

#var tween #basic all purpose tween for stretches 
var tween2 #tween for glimmer 
var tween3 #tween for ripple amp UNUSED USE IT FOR SOMETHING ELSE
var tween4 #idk
var tween5

var current_map = -1

#Fat:
#Pos(-17, -35) Scale(1.063, 1.063)

@export var size: float = 1

enum {
	WADDLE,
	BOARD,
	FROG,
	TANK,
	FREESTYLE, 
	BACKSTROKE,
	BUTTERFLY,
	DOLPHIN
}
@export var basic_movement_type = 0#WADDLE#WADDLE			
var left_input = false
var right_input = false
var up_input = false
var down_input = false

var move_abil_mod = 1
@onready var sprite_ref = $InnerNode/Sprite

#BASIC stuff
var x_dir : float = 0.0
var y_dir : float = 0.0
var idling : bool = false

#You should attach these to a resource
#WADDLE VARS
#var waddle = false
@export var waddle_speed = 1
var waddle_speed_bonus : float = 1.0
@export var orb_speed_gain : float = 0.2
var accel: float = 50
var turning_accel_ratio: float = 1.25
var waddle_attack_speed_bonus : float = 1.0

#BOARD VARS
@export var board_accel: float = 0.5
@export var board_speed_cap: float = 250
@export var board_turning_speed: float = 1.5
var board_speed: float = 0
@export var dash_convers_mult : float = 0.25

#FROG VARS
@export var frog_speed : float = 1.0
@export var frog_charge_gain : float = 1.0
@export var frog_travel_speed : float = 1.0
@export var frog_max_charges : float = 3.0
@export var frog_charge_dash_ratio : float = 0.15
var frog_charge : float = 0.0
var frogState : int = 0 
var frogDirection : Vector2 = Vector2.ZERO
var frogIdleAllowed : bool = false

@export var friction: float = 0.25

var isHazard : bool = false



enum {
	CHARGE_DASH,
	SPEED_BOOST,
	LASSO,
	JUMP,
	GRAPPLE,
	DIVE, 
	WALLKICK,
	KITE
}
@export var primary_ability : int = 0

#Charge Variables
var charge = true
@export var charge_cooldown: float = 1
var charge_cool: float = 0
@export var charge_max: float = 1
@export var charge_floor: float = 0.33
@export var charge_floor_speed: float = 0.33 #Such as maybe you'd want to set this to 0 below the floor.
var charge_time: float = 0
@export var charge_speed: float = 1
#You should check if pull speed is still necessary
@export var charge_pull_speed: float = 0.65#Default:0.65
@export var charge_length: float = 0.5
var tempVelocity: Vector2 = Vector2.ZERO

var charge_angle: float = 0
@export var charge_angle_speed: float = 1

@export var charge_dash: bool = false
#var chargeVelocity: Vector2 = Vector2.ZERO
var chargeStrength: float = 0

#Speed Boost Variables
var sb_synergy_buffs : Array = [false, false, false]
@export var sb_buff : bool = true
@export var sb_max_speed_buff : float = 1.5
var sb_speed_buff : float = 1.0
@export var sb_synergy_buff : float = 1.5
var sb_state = 0
@onready var sb_ref = $InnerNode/SpeedBoost
@export var sb_anim_speed : float = 1.0
const base_collection_radius : float = 18.0
@export var sb_decay : bool = true 
@export var base_sb_decay_rate : float = 1.0
signal createAfterImage(trail_decay : float, trail_int : float, trail_color : int, trail_count : int)
signal endAfterImage()

#Lasso Variables
const lasso_base_range = 240
@export var lasso_max_speed : float = 0.5
@export var lasso_cursor_speed : float = 1.0
@export var lasso_retract_speed : float = 1.0 
@export var lasso_gain_speed : float = 1.0
@export var max_lasso_range : float = 1.0
var lasso_progress : float = 0.0
@onready var lassoRef = $InnerNode/lasso
@onready var crosshairRef = $InnerNode/Crosshair
var lasso_buff : bool = true
#@export var lasso_type : int = 0
var buffRef : Node2D
#var boardClockwise : int = 1

var lasso_buffs : Array = [false, false, false, false]

#Knockback vars
var knockback_tween
var kb_moving : bool = false
var super_armor : bool = false
@export var knockback_resist = 0.0
var move_kb_mod = 1.0
@export var base_invul_time = 0.25
@export var orb_refund_ratio = 0.25
var invul_leeway_count = 2
#If this doesn't work, change to using an InnerNode.

@onready var attach = $InnerNode/Attachments
@onready var Inner = $InnerNode

#A couple things here:
#The OrbTimer in cell needs to be changed based on how fast we can travel
# / need to create a variable that calculates theoretical speed.
#The distance far orbs spawn need to be changed based on our vision radius.

#Ripple Vars
var rippleOn = false
var rippleAmp = 0
var oscilator = 0
var rippleTime = 0
var rippleMax = 0

#Pulse Vars
@export var pulseDuration = 1.0
var pulseCount  = 0
var pulseAmp1 = 0.0
var pulseAmp2 = 0.0
var pulseAmp3 = 0.0
var pulseTween1
var pulseTween2
var pulseTween3
var pulseSource1 = Vector2.ZERO
var pulseSource2 = Vector2.ZERO
var pulseSource3 = Vector2.ZERO

#Tentacle Vars
#I'm gonna make a stupid design decision here but I think it would be best to have all the tentacles exist already
#Just not instantiated. I feel like I'm gonna regret this but, let's be honest here. LETS BE HONEST HERE. If the game
#was laggy with ALL the tentacles on screen all the time, then I'd need to optimize something since you CAN get all the
#tentacles on screen at the same time. So what's the point of "optimizing" by not having it exist until it's needed huh?
#If the game's laggy at the end, it'll still be as shit if the game was laggy at the beginning. 
#But yeah obviously if I wanted this game to be scalable I WOULDN'T make it like that but I'm not going to have this game
#scalable so stop overcomplicating it dumbass. Hell, if you followed the same approach with everything, I'm sure it would be fine too.
#Though you probably want to see about giving the miniblobs more abstract tentacles instead of detailed ones. 

#Well I've tried my best to make this not look like a swastika so when you get the fourth tentacle, make sure you change it
#To the CORNERS OK
#Also give like rainbow tentacles skin or somethign so people don't call you a nazi 
#Or Just Don't put a fourth one? Keep the space in front for antennas and harpoons and stuff.
var tentacle : bool = true
@onready var tent_ref = $InnerNode/Sprite/Tentacles 
#@export var tentacleAmount:int = 9
#@export var tentacleLength:int = 8
#@export var tentacleAlphaAmount:int = 0 
var chargeTentacleSpin:float = 0 #very misleading name, basically how much Right/Left while charging affects the tentacles
#var reverseTentacleSpin:float = 0#this is actually for the charge part.
"""
Things to do:
	Gotta put that size variable that influences stuff. 
	Higher size = lower charge pull speed (don't need to be connected, maybe). 
	Higher size = large pull( add size variable to all those positions)
	Figure out how the zoom in out stuff gonna work
	
	I hate this but you're gonna have to make an individual scene for each tentacle. You might as well
	move all these shitty functions into there instead, alright?
	Might as well replace these functions with a for_loop that calls them instead now since we can change them
	specifically.
	
	Ugggh

"""
const spawnerID = -255
var virus_level : float = 0.0
var virus_immunity : float = 1.0
var virus_max : float = 100

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Special"):
		position = Vector2.ZERO
		velocity = Vector2.ZERO
		activateRipple(Vector2(0.5, 0.866), 1.0)
		#$InnerNode/Sprite/Tentacle1.whip(-1)

func activateRipple(origin: Vector2, amplitude: float) -> void:
	$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("rippleSource", origin)
	$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("rippleAmp", amplitude)
	$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("rippleAmpMax", -amplitude)
	$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("rippleOn", true)
	rippleAmp = amplitude
	rippleMax = -amplitude
	oscilator = 0
	rippleOn = true
	rippleTime = 1.8

"""
func _input(event: InputEvent) -> void:
	pass

func _get_input() -> Dictionary:
	return {
		"Y": int(Input.is_action_pressed("Up")) - int(Input.is_action_pressed("Down")),
		"X": int(Input.is_action_pressed("Right")) - int(Input.is_action_pressed("Left")),
		"Charge": Input.is_action_pressed("Charge"),
		"ChargeUp": Input.is_action_just_released("Charge")
	}
"""

func _ready() -> void:
	_frogReset()
	"""
	print("START")
	tween4 = create_tween()
	tween4.tween_callback(print.bind("2DONE")).set_delay(2.0)
	tween5 = create_tween()
	tween5.tween_method(_testMethod, 1.0, 10.0, 1.0).set_delay(1.0)
	tween5.tween_callback(print.bind("1DONE"))
	"""
	#camReference = get_node("Camera2D")

#Move some of this stuff to _process()
#Physics process runs at 60fps constant
func _physics_process(delta: float) -> void:
	
	var friction_delta = pow(friction, delta)
	
	_movementLogic(delta,friction_delta)
	
	if state == CHARGING:# or state == CHARGE:
		_chargeLogic(delta)
	
	match state:
		pass
	
	#These all need to be changed and optimized.	
	if rippleOn:
		oscilator += delta * 1.25
		var rippleAmpCurrent = rippleAmp/2.5 * sin(2.5 * oscilator)/oscilator
		$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("rippleAmp", rippleAmpCurrent)
		if oscilator > 17.5:
			rippleOn = false
			$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("rippleAmp", 0)
		elif oscilator > rippleTime:
			rippleMax *= -0.6
			$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("rippleAmpMax", rippleMax)
			rippleTime += 1.2
	
	if pulseCount > 0:
		#print("PulseCount: ", pulseCount)
		$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("pulseAmp1", pulseAmp1)
		#print("Pulse Amp 1: ", pulseAmp1)
		if pulseCount > 1:
			#print("Pulse Amp 2: ", pulseAmp2)
			$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("pulseAmp2", pulseAmp2)
			if pulseCount > 2:
				#print("Pulse Amp 3: ", pulseAmp3)
				$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("pulseAmp3", pulseAmp3)
	if charge_dash:# and chargeStrength > 2:
		_primaryLogic(delta, friction_delta)
	else:
		velocity += tempVelocity	 	
		move_and_slide()
		velocity -= tempVelocity	 
		
		velocity *= friction_delta#pow(friction, delta)
	
	_timers(delta)

func _movementLogic(delta: float, friction_delta:float) -> void:
	match basic_movement_type:
		WADDLE:
			_waddleLogic(delta, friction_delta)
		BOARD:
			_boardLogic(delta, friction_delta)
		FROG:
			_frogLogic(delta, friction_delta)

func _waddleLogic(delta: float, _friction_delta : float) -> void:
	#var x_dir : float
	#var y_dir : float
	#print("Right: ", Input.is_action_pressed("Right"))
	#print(velocity.length()/100)
	#$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("frequency", 2.5 + ceil(velocity.length())/100 * size)
	$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("amplitude", 0.5 + ceil(velocity.length())/20 * size)
	
	var waddle_total_speed = accel * delta * waddle_speed * move_abil_mod * move_kb_mod * waddle_speed_bonus * sb_speed_buff
	#Attack speed calc for now. Make sure to realize this is (+)  here
	waddle_attack_speed_bonus = (waddle_speed_bonus + (0.5*(sb_speed_buff - 1.0)) * sb_synergy_buff)
	
	if x_dir == sign(velocity.x) * -1:
		velocity.x += x_dir * waddle_total_speed * turning_accel_ratio
	else:
		velocity.x += x_dir * waddle_total_speed
	if y_dir == sign(velocity.y) * -1:
		velocity.y += y_dir * waddle_total_speed * turning_accel_ratio
	else:
		velocity.y += y_dir * waddle_total_speed
	
	
func _boardLogic(delta: float, friction_delta : float) -> void:
	#var x_dir : float
	#var y_dir : float
	if mouseMovement:
		#This is inefficient but I know doing this manually is a pain in the ass to bug fix so I cba
		x_dir = sign(mousePos.angle_to(Vector2.from_angle(charge_angle+PI/2)))
	
	$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("amplitude", 0.5 + ceil(velocity.length())/20 * size)
			
	#board_speed += board_accel
	
	if y_dir == -1:
		board_speed += board_accel * move_abil_mod * move_kb_mod * sb_speed_buff
		#velocity.y += y_dir * accel * turning_accel_ratio * delta * waddle_speed * move_abil_mod	
	elif y_dir == 0:
		board_speed += board_accel * 0.25 * move_abil_mod * move_kb_mod * sb_speed_buff
		board_speed *= sqrt(friction_delta)
	else:
		board_speed *= friction_delta
	
	if board_speed > board_speed_cap * sb_speed_buff:
		board_speed = board_speed_cap * sb_speed_buff
	
	if primary_ability == LASSO and lasso_buff and lasso_progress >= 1000:
		var lassoPos = lassoRef.getPos() - getPosition()
		var tempAngle = lassoPos.angle() 
		var boardClockwise = 1 if y_dir == 1 else 0
		charge_angle = tempAngle + PI * boardClockwise
		if y_dir == 0:
			velocity = Vector2.ZERO
		else:
			velocity = 1.5 * board_speed_cap * move_abil_mod * move_kb_mod * Vector2(cos(charge_angle - PI/2), sin(charge_angle - PI/2)) * sb_speed_buff
	else:
		charge_angle += board_turning_speed * x_dir * delta * move_abil_mod * move_kb_mod
		velocity = board_speed * move_abil_mod * move_kb_mod * Vector2(cos(charge_angle - PI/2), sin(charge_angle - PI/2))
	
	$InnerNode/Pivot.rotation = charge_angle
	sprite_ref.rotation = charge_angle
	if primary_ability == SPEED_BOOST:
		sb_ref.changeRot(charge_angle)
	

func _frogLogic(_delta : float, _friction_delta : float) -> void:
	#This is not handled in _unhandledInput because that can only detect 1 input at a time
	#We want to handle in case someone wants to dash diagonally.
	#print("X: ", frog_charge, " " , frogState)#, " ", frogTemp)
	
	#HAHAHAH TAKE THAT OLD ME
	#YOU WERE WRONG I SURPASSED YOU
	#Let's just keep this here in case we need it.
	pass

func _primaryLogic(delta : float, friction_delta : float) -> void:
	match primary_ability:
		CHARGE_DASH:
			_chargeDash(delta, friction_delta)
		LASSO:
			_lassoLogic(delta, friction_delta)

func _chargeDash(delta: float, friction_delta : float)-> void:
	var temp : float
	if mouseMovement:
		temp = sign(mousePos.angle_to(Vector2.from_angle(charge_angle+PI/2)))
	else:
		temp = int(right_input) - int(left_input)
	charge_angle += charge_angle_speed * temp * delta * chargeStrength * 0.005
	$InnerNode/Pivot.rotation = charge_angle
	sprite_ref.rotation = charge_angle
	
	var chargeVelocity = Vector2(chargeStrength * cos(charge_angle - PI/2), chargeStrength * sin(charge_angle - PI/2))
	
	velocity += tempVelocity + chargeVelocity 	
	move_and_slide()
	velocity -= tempVelocity + chargeVelocity	 
	
	#var tempPow = friction_delta#pow(friction, delta)
	velocity *= friction_delta
	#velocity.move_toward(Vector2.ZERO, friction*delta)
	chargeStrength *= friction_delta	
	
	if chargeStrength < 2:
		charge_dash = false

func _lassoLogic(delta: float, friction_delta : float) -> void:
	if mouseMovement:
		crosshairRef.position = mousePos
	else:
		#var x_dir : float
		#var y_dir : float
		var temp_x_dir = int(right_input) - int(left_input)
		var temp_y_dir = int(down_input) - int(up_input)
		crosshairRef.position += 250 * delta * lasso_cursor_speed * Vector2(temp_x_dir, temp_y_dir)
	var crossLen = crosshairRef.position.length()
	if crossLen > lasso_base_range * lasso_progress:
		crosshairRef.position = lasso_base_range * lasso_progress * crosshairRef.position / (crossLen+1) #No divide by 0
	
	velocity += tempVelocity	 	
	move_and_slide()
	velocity -= tempVelocity	 
	
	velocity *= friction_delta#pow(friction, delta)

func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("Primary"):
		_primaryOnPress()
		return
	elif event.is_action_released("Primary"):
		_primaryOnRelease()
		return
	
	if event.is_action_pressed("Secondary"):
		return
	elif event.is_action_released("Secondary"):
		return
	
	if mouseMovement:
		if event is InputEventMouseMotion:
			mousePos = event.position - mouseCenter
			_basicOnPress()
	else:
		if event.is_action_pressed("Left"):
			left_input = true
			_basicOnPress()
			return
		elif event.is_action_released("Left"):
			left_input = false
			_basicOnRelease()
			return
			
		if event.is_action_pressed("Right"):
			right_input = true
			_basicOnPress()
			return
		elif event.is_action_released("Right"):
			right_input = false
			_basicOnRelease()
			return
		
		if event.is_action_pressed("Up"):
			up_input = true
			_basicOnPress()
			return
		elif event.is_action_released("Up"):
			up_input = false
			_basicOnRelease()
			return
		
		if event.is_action_pressed("Down"):
			down_input = true
			_basicOnPress()
			return
		elif event.is_action_released("Down"):
			down_input = false
			_basicOnRelease()
			return

func _basicOnPress() -> void:
	match basic_movement_type:
		WADDLE:
			_getWaddleDirection()
		BOARD:
			_getBoardDirection()
		FROG:
			if frogState == 0 and frog_charge >= 0:
				_frogReset()

func _basicOnRelease() -> void:
	match basic_movement_type:
		WADDLE:
			_getWaddleDirection()
		BOARD:
			_getBoardDirection()

func _idlingTrigger() -> void:
	if not idling:
		if primary_ability == SPEED_BOOST:
			sb_ref.endWaddle()
		idling = true
		#Have a check that boosts idle gains if frog_charge >= max_charge
		#Also boost idle gains under the effect of the lasso buff
		#* (1 + int(lasso_buffs[2]) * 0.5)
		

func _idlingCancel() -> void:
	if idling:
		if primary_ability == SPEED_BOOST:	
			sb_ref.beginWaddle()
		idling = false

func _getWaddleDirection() -> void: #-> bool:
	if mouseMovement:
		var absMPX = abs(mousePos.x)
		if absMPX < 15:
			x_dir = 0
		elif absMPX < 100:
			x_dir = mousePos.x/100
		else:
			x_dir = sign(mousePos.x)
		var absMPY = abs(mousePos.y)
		if absMPY < 15:
			y_dir = 0
		elif absMPY < 100:
			y_dir = mousePos.y/100
		else:
			y_dir = sign(mousePos.y)
	else:
		x_dir = int(right_input) - int(left_input)
		y_dir = int(down_input) - int(up_input)
	if x_dir or y_dir:
		_idlingCancel()
	else:
		_idlingTrigger()

func _getBoardDirection() -> void:# -> bool:
	var x_temp = x_dir
	if mouseMovement:
		#This is inefficient but I know doing this manually is a pain in the ass to bug fix so I cba
		var tempAng = mousePos.angle_to(Vector2.from_angle(charge_angle+PI/2))
	
		x_dir = sign(tempAng)
		var mousePosLen = mousePos.length()
		if abs(tempAng) < PI/2:
			y_dir = 1
		elif mousePosLen < 15:
			y_dir = 0
		elif mousePosLen < 100:
			y_dir = -mousePos.y/100
		else:
			y_dir = -1
	else:
		x_dir = int(right_input) - int(left_input)
		y_dir = int(down_input) - int(up_input)
	
	if x_dir != x_temp:
		if tentacle:
			tent_ref.shaderNewDirection(x_dir)
	
	if y_dir < 0:
		_idlingCancel()
	else:
		_idlingTrigger()

func _getFrogDirection() -> bool:
	#var x_dir : float
	#var y_dir : float
	if mouseMovement:
		var absMPX = abs(mousePos.x)
		if absMPX < 75:
			x_dir = 0
		else:
			x_dir = sign(mousePos.x)
		var absMPY = abs(mousePos.y)
		if absMPY < 75:
			y_dir = 0
		else:
			y_dir = sign(mousePos.y)
	else:
		x_dir = int(right_input) - int(left_input)
		y_dir = int(down_input) - int(up_input)
	frogDirection = Vector2(x_dir, y_dir)
	return x_dir or y_dir

func _frogPressStart() -> void:
	#There should be a special case with frog not to cancel idling when having the upgrade
	if not frogIdleAllowed:
		_idlingCancel()
	if frog_charge >= 1.0:
		if frog_charge >= frog_max_charges:
			frog_charge = frog_max_charges
		frogState = 3
		_frogRelease()
	else:
		frogState = 1
		if basic_tween:
			basic_tween.kill()
		basic_tween = create_tween()
		
		var frogLowerBound = 0.4
		var scaleVec
		if abs(charge_angle) > PI / 6:#state == CHARGING or charge_cool > 0:
			var newDir = (Vector2.from_angle(snapped(frogDirection.angle() - charge_angle, PI/4))).snappedf(1.0)
			scaleVec = Vector2(1.0, 1.0) - 0.3 * abs(newDir)			
		else:
			scaleVec = Vector2(1.0, 1.0) - 0.3 * abs(frogDirection)
		
		
		var synergy_gain = 1.0
		if sb_synergy_buffs[basic_movement_type]:	
			synergy_gain += (sb_synergy_buff-1.0)
		var frog_charge_rate = frogLowerBound / (frog_charge_gain * synergy_gain)	
		
		#Think I made a bug here. It seemed like it worked before but if this fix breaks it, revert the fix:
		if state == CHARGING and charge_time < charge_max:#state == CHARGING or charge_cool > 0: 
			basic_tween.tween_property(self, "frog_charge", frogLowerBound, frog_charge_rate).as_relative()
			#var tempVec = 0.25 * (scaleVec - Vector2(1.0, 1.0))
			#basic_tween.tween_property($InnerNode/Sprite/Node2D, "scale", tempVec, frogLowerBound / frog_charge_gain).as_relative()
		else:
			basic_tween.tween_property($InnerNode/Sprite/Node2D, "scale", scaleVec, frog_charge_rate)
			basic_tween.parallel().tween_property(self, "frog_charge", frogLowerBound, frog_charge_rate).as_relative()
			
		"""
		if frogDirection.y:
			if frogDirection.x:
				basic_tween.tween_property($InnerNode/Sprite/Node2D, "scale", Vector2(0.7, 0.7), frogLowerBound / frog_charge_gain)
			else:
				basic_tween.tween_property($InnerNode/Sprite/Node2D, "scale", Vector2(1, 0.7), frogLowerBound / frog_charge_gain)
		elif frogDirection.x:
			basic_tween.tween_property($InnerNode/Sprite/Node2D, "scale", Vector2(0.7, 1), frogLowerBound / frog_charge_gain)
		"""
		
		basic_tween.finished.connect(_frogPress)

func _frogPress() -> void:
	if _getFrogDirection():
		frogState = 2
		if basic_tween:
			basic_tween.kill()
		basic_tween = create_tween()
		
		var frogLowerBound = (1 - 0.4)
		var scaleVec
		
		print("CT ", charge_time)
		
		
		if abs(charge_angle) > PI / 6:#state == CHARGING or charge_cool > 0:
			var newDir = (Vector2.from_angle(snapped(frogDirection.angle() - charge_angle, PI/4))).snappedf(1.0)
			scaleVec = Vector2(1.0, 1.0) - 0.6 * abs(newDir)
		else:
			scaleVec = Vector2(1.0, 1.0) - 0.6 * abs(frogDirection)
		
		var synergy_gain = 1.0
		if sb_synergy_buffs[basic_movement_type]:	
			synergy_gain += (sb_synergy_buff-1.0)
		var frog_charge_rate = frogLowerBound / (frog_charge_gain * synergy_gain)
		
		if state == CHARGING and charge_time < charge_max:#state == CHARGING or charge_cool > 0: 
			#var tempVec = 0.1 * (scaleVec - Vector2(1.0, 1.0))
			#basic_tween.tween_property($InnerNode/Sprite/Node2D, "scale", tempVec, frogLowerBound / frog_charge_gain).as_relative()
			basic_tween.tween_property(self, "frog_charge", frogLowerBound, frog_charge_rate).as_relative()
		else:
			basic_tween.tween_property($InnerNode/Sprite/Node2D, "scale", scaleVec, frog_charge_rate)
			basic_tween.parallel().tween_property(self, "frog_charge", frogLowerBound, frog_charge_rate).as_relative()
			"""
			if frogDirection.y:
				if frogDirection.x:
					basic_tween.tween_property($InnerNode/Sprite/Node2D, "scale", Vector2(0.4, 0.4), frogLowerBound / frog_charge_gain)
				else:
					basic_tween.tween_property($InnerNode/Sprite/Node2D, "scale", Vector2(1, 0.4), frogLowerBound / frog_charge_gain)
			elif frogDirection.x:
				basic_tween.tween_property($InnerNode/Sprite/Node2D, "scale", Vector2(0.4, 1), frogLowerBound / frog_charge_gain)
			"""
		
		basic_tween.finished.connect(_frogRelease)
	else:
		_frogCancel()

func _frogCancel() -> void:
	_idlingTrigger()
	
	frogState = 0
	if basic_tween:
		basic_tween.kill()
	basic_tween = create_tween()
	var synergy_gain = 1.0 #+ ((sb_synergy_buff-1.0) * int(sb_synergy_buffs[basic_movement_type]))
	#I kinda prefer this than doing one big formula. 
	if sb_synergy_buffs[basic_movement_type]:	
		synergy_gain += (sb_synergy_buff-1.0)
	var frog_charge_rate = frog_max_charges * 2.0 / (frog_charge_gain * synergy_gain)
	if state == CHARGING and charge_time < charge_max:#state == CHARGING or charge_cool > 0:
		basic_tween.tween_property(self, "frog_charge", frog_max_charges, frog_charge_rate).as_relative() 
		basic_tween.parallel().tween_property($InnerNode/Sprite/Node2D, "position", Vector2(0.0, 0.0), 0.25)
	else:
		basic_tween.tween_property($InnerNode/Sprite/Node2D, "scale", Vector2(1.0, 1.0), 0.25)
		basic_tween.parallel().tween_property($InnerNode/Sprite/Node2D, "position", Vector2(0.0, 0.0), 0.25)
		basic_tween.parallel().tween_property(self, "frog_charge", frog_max_charges, frog_charge_rate).as_relative()

func _frogReset() -> void:
	if _getFrogDirection():
		_frogPressStart()
	else:
		_frogCancel() 

func _frogRelease() -> void:
	frogState = 3
	if state == CHARGING:
		velocity += frogDirection * frog_speed * 100 * frog_travel_speed * sb_speed_buff
	else:
		velocity += frogDirection * frog_speed * 100 * frog_travel_speed * move_abil_mod * move_kb_mod * sb_speed_buff
	if frog_charge <= (frogState - frog_max_charges):
		frogState = 0
	if basic_tween:
		basic_tween.kill()
	basic_tween = create_tween()
	var temp = 3.5
	var scaleVec
	var posVec
	if abs(charge_angle) > PI / 6:#state == CHARGING or charge_cool > 0:
		var newDir = (Vector2.from_angle(snapped(frogDirection.angle() - charge_angle, PI/4))).snappedf(1.0)
		scaleVec = Vector2(0.6, 0.6) + abs(newDir) * (0.4 + 0.1 * temp)
		posVec = newDir * 3.6 * temp	
	else:
		scaleVec = Vector2(0.6, 0.6) + abs(frogDirection) * (0.4 + 0.1 * temp)
		posVec = frogDirection * 3.6 * temp
	
	if state == CHARGING and charge_time < charge_max:#state == CHARGING or charge_cool > 0:
		#var tempVec = 0.1 * (scaleVec - Vector2(1.0, 1.0))
		#basic_tween.tween_property($InnerNode/Sprite/Node2D, "scale", tempVec, 0.1 / frog_travel_speed).as_relative()	
		basic_tween.parallel().tween_property($InnerNode/Sprite/Node2D, "position", posVec, 0.1 / frog_travel_speed)#.as_relative()
		#basic_tween.tween_property($InnerNode/Sprite/Node2D, "scale", -tempVec, 0.2 / frog_travel_speed).as_relative()
		basic_tween.parallel().tween_property($InnerNode/Sprite/Node2D, "position", Vector2(0, 0), 0.4 / frog_travel_speed)#.as_relative()
	else:	
		basic_tween.tween_property($InnerNode/Sprite/Node2D, "scale", scaleVec, 0.1 / frog_travel_speed)	
		basic_tween.parallel().tween_property($InnerNode/Sprite/Node2D, "position", posVec, 0.1 / frog_travel_speed)
		basic_tween.tween_property($InnerNode/Sprite/Node2D, "scale", Vector2(1, 1), 0.4 / frog_travel_speed)
		basic_tween.parallel().tween_property($InnerNode/Sprite/Node2D, "position", Vector2(0, 0), 0.4 / frog_travel_speed) 
	
	basic_tween.parallel().tween_property(self, "frog_charge", -1.0, 0.4 / frog_travel_speed).as_relative()
	basic_tween.finished.connect(_frogReset)
	
	#handleTentacleReturn()

func _primaryOnPress() -> void:
	match primary_ability:
		CHARGE_DASH:
			if charge_cool <= 0:
				_chargePress()
			else:
				primary_queued = true
		SPEED_BOOST:
			_sbPress()
		LASSO:
			_lassoPress()
				
func _primaryOnRelease() -> void:
	match primary_ability:
		CHARGE_DASH:
			#If somehow previous logic doesn't go through
			if charge_cool <= 0 and state == CHARGING:
				_chargeRelease()
			else:
				primary_queued = false
		SPEED_BOOST:
			primary_queued = false
		LASSO:
			_lassoRelease()

func _chargePress() -> void:
	state = CHARGING
	if tentacle:
		tent_ref.startTentacleShader()
		tent_ref.handleTentacleSqueeze(charge_max)	
	if primary_tween:
		primary_tween.kill()
	primary_tween = create_tween()
	if $InnerNode/Sprite/Node2D.position.y != 0:
		resetCharge(true)
	$InnerNode/Pivot.modulate = Color(1,1,1,1)
	if frogState == 0:	
		primary_tween.tween_property($InnerNode/Pivot, "scale", Vector2(-2, 0.6), charge_max)
	#if frog_charge <= 0:	
	primary_tween.parallel().tween_property($InnerNode/Sprite/Node2D, "scale", Vector2(1, 0.25), charge_max)
	primary_tween.finished.connect(_onFullCharge)
	
	move_abil_mod = 0.25
	charge_time = 0

func _chargeOffCD() -> void:
	if primary_queued:
		_chargePress()
	
func _chargeRelease() -> void:
	if basic_tween and basic_movement_type == FROG:
		basic_tween.kill()
	if kb_moving:
		_knockbackCancel()
	chargeTentacleSpin = 0.0
	primary_queued = false
	state = IDLE
	move_abil_mod = 1
	if primary_tween:
		primary_tween.kill()
	primary_tween = create_tween().set_parallel()
	
	var swipePos : float = min(0.08 * charge_cooldown, 0.2)
	var retPos : float = min(0.3 * charge_cooldown, 0.4)
	
	
	$InnerNode/Pivot/Node2D/Glimmer.texture_offset = Vector2(3, 25)
	$InnerNode/Pivot/Node2D/Polygon2D2.color = Color(0.8, 0.8, 0.8)
	charge_time = min(charge_time, charge_max)
	charge_time = max(charge_time, charge_floor)  
	var temp = ceil(10 * charge_time/charge_max) * charge_length# if charge_time < charge_floor else ceil(10 * charge_time/charge_max) * charge_length
	
	
	primary_tween.tween_property(self, "charge_cool", 0.0, charge_cooldown).from(1.0)
	#primary_tween
	primary_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	primary_tween.tween_property($InnerNode/Pivot, "scale", Vector2(1, 1.5), swipePos * 1.2)
	primary_tween.tween_property($InnerNode/Sprite/Node2D, "scale", Vector2(temp/20, 1 + 0.1 * temp), swipePos)
	primary_tween.tween_property($InnerNode/Sprite/Node2D, "position", Vector2(0, -3.6 * temp), swipePos)
	
	if tentacle:
		tent_ref.handleTentacleChargeSwipe(temp, charge_cooldown)
	
	primary_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	
	primary_tween.tween_callback(self.setTempVelocity.bind(temp)).set_delay(swipePos)
	primary_tween.tween_callback(self.activateRipple.bind(Vector2(0, -1), temp/10)).set_delay(swipePos)
	primary_tween.tween_property($InnerNode/Sprite/Node2D, "scale", Vector2(1, 1), retPos/charge_pull_speed).set_delay(swipePos)
	primary_tween.tween_property($InnerNode/Sprite/Node2D, "position", Vector2(0, 0), retPos /charge_pull_speed).set_delay(swipePos)
	
	primary_tween.tween_callback(self.resetCharge.bind(false)).set_delay(swipePos + retPos/charge_pull_speed)#.bind(4.8*temp, charge_angle - PI/2))
	
	primary_tween.finished.connect(_chargeOffCD)
	
	charge_dash = true
	#if charge_dash:
	var frogBuff : float = 1.0
	if basic_movement_type == FROG:
		if frog_charge <= 1.0:	
			frogBuff = 1 + frog_charge_dash_ratio * frog_charge
		elif frog_max_charges == 1.0:
			frogBuff = 1 + frog_charge_dash_ratio
		elif frog_charge <= frog_max_charges:
			frogBuff = 1 + frog_charge_dash_ratio * (1 + 0.5 * frog_charge)
		else:
			frogBuff = 1 + frog_charge_dash_ratio * (1 + 0.5 * frog_max_charges)
		#Put it on CD for a bit to avoid bad interactions	
		frog_charge = -0.5
		
		var synergy_gain = 1.0
		if sb_synergy_buffs[basic_movement_type]:	
			synergy_gain += (sb_synergy_buff-1.0)
		var frog_charge_rate = frog_max_charges * 2.0 / (frog_charge_gain * synergy_gain)
		
		if basic_tween:
			basic_tween.kill()
		basic_tween = create_tween()
		basic_tween.tween_property(self, "frog_charge", frog_max_charges, frog_charge_rate).as_relative()
		frogState = 0
	
	if charge_time <= charge_max * charge_floor: 
		chargeStrength += charge_floor_speed * 100 * charge_speed * frogBuff
	else:
		chargeStrength += charge_time * 50 * charge_speed * frogBuff
	
	if basic_movement_type == BOARD:
		board_speed += chargeStrength * dash_convers_mult
	"""
	else:
		if charge_time <= charge_max * charge_floor: 
			velocity.x += cos(charge_angle - PI/2) * charge_floor_speed * 100 * charge_speed
			velocity.y += sin(charge_angle - PI/2) * charge_floor_speed * 100 * charge_speed
		else:
			velocity.x += cos(charge_angle - PI/2) * charge_time * 50 * charge_speed
			velocity.y += sin(charge_angle - PI/2) * charge_time * 50 * charge_speed
	"""

func _chargeLogic(delta: float) -> void:
	charge_time += delta
	var temp : float
	if mouseMovement:
		#I don't like how I have +Pi/2 and -PI/2 . Fix this later.
		temp = sign(mousePos.angle_to(Vector2.from_angle(charge_angle+PI/2)))
	else:
		temp = int(right_input) - int(left_input)
	
	if tentacle:	
		
		if charge_time < charge_max * 0.8:
			temp *= delta * pow((charge_max / (charge_time + 0.2)), 1.6)
			chargeTentacleSpin *= pow(0.05, delta)
			chargeTentacleSpin += -2 *temp# if abs(chargeTentacleSpin) <= 1.0 else 0
			charge_angle += charge_angle_speed * temp
			
		else:
			temp *= delta
			chargeTentacleSpin *= pow(0.1, delta)
			chargeTentacleSpin += -1.5*temp# if abs(chargeTentacleSpin) < 2.5 else 0
			charge_angle += charge_angle_speed * temp
		tent_ref.handleTentacleShader(chargeTentacleSpin)
		
	else:
		if charge_time < charge_max * 0.8:
			temp *= delta * pow((charge_max / (charge_time + 0.2)), 1.6)
			charge_angle += charge_angle_speed * temp
			
		else:
			temp *= delta
			charge_angle += charge_angle_speed * temp
	
		
	$InnerNode/Pivot.rotation = charge_angle
	sprite_ref.rotation = charge_angle

func _sbPress() -> void:
	match sb_state:
		0:
			if kb_moving:
				_knockbackCancel()
			sb_ref.activate(sb_anim_speed)
			sb_state = 1 
		1:
			primary_queued = true
		2: 
			sb_ref.spitOutCrystal(sb_anim_speed)
			sb_state = 1

func _lassoPress() -> void:
	print("LAS PROG, " , lasso_progress)
	if lasso_progress >= 1000:
		_lassoGo()
	elif lasso_progress < 100:
		charge_dash = true
		lassoRef.activate()
		crosshairRef.show()
		if primary_tween:
			primary_tween.kill()
		primary_tween = create_tween()
		primary_tween.tween_property(self, "move_abil_mod", lasso_max_speed, max_lasso_range * 3.0 / lasso_gain_speed).from(1.0)
		primary_tween.parallel().tween_property(self, "lasso_progress", max_lasso_range, max_lasso_range * 3.0 / lasso_gain_speed).from(0.0)
	elif lasso_progress < 210:
		_on_lasso_lasso_stall()

func _lassoRelease() -> void:
	primary_queued = false
	if lasso_progress < 100 and lasso_progress > 0:
		charge_dash = false
		move_abil_mod = 1.0
		crosshairRef.hide()
		if lassoRef.endLasso(getPosition()+crosshairRef.position):
			_on_lasso_lasso_stall()
		else:
			_lassoCancel()
	elif lasso_progress >= 1000:
		_lassoGo()	
		
func _lassoGo() -> void:
	primary_queued = true
	var endPos = lassoRef.getPos()
	if lasso_progress >= 1000:
		if _lassoCollisionCheck(endPos):
			if kb_moving:
				_knockbackCancel()
			move_abil_mod = 0
			$CollisionShape2D.set_deferred("disabled", true)
			if primary_tween:
				primary_tween.kill()
			primary_tween = create_tween() 
			
			var normEndPos = endPos - getPosition()
			var crossLen = normEndPos.length()
			primary_tween.tween_property(Inner, "position", normEndPos, crossLen / (2.0*lasso_base_range*lasso_retract_speed)).as_relative()
			primary_tween.finished.connect(_lassoEnd)
		else:
			lassoRef.cancelLasso(true)
			move_abil_mod = 1.0

#Check for solid objects and if it's out of bounds.
func _lassoCollisionCheck(_checkPos : Vector2) -> bool:
	
	return true

func _lassoEnd() -> void:
	move_abil_mod = 1.0
	_lassoCancel()
	$CollisionShape2D.set_deferred("disabled", false)
	
#Placeholder incase I need to do stuff with this
func _lassoCancel() -> void:
	lasso_progress = 0
	lassoRef.deactivate()
	crosshairRef.position = Vector2.ZERO
	move_abil_mod = 1.0
	if buffRef:
		buffRef.disable()
		buffRef = null
		lasso_buffs = [false, false, false, false]
	
	if primary_queued and Input.is_action_pressed("Primary"):
		_lassoPress()

func _onFullCharge() -> void:
	if tween2:
		tween2.kill()
	tween2 = create_tween()
	tween2.tween_property($InnerNode/Pivot/Node2D/Glimmer, "texture_offset", Vector2(24, 7), 0.4)
	tween2.parallel().tween_property($InnerNode/Pivot/Node2D/Polygon2D2, "color", Color(1, 1, 0), 0.2)
	tween2.tween_property($InnerNode/Pivot/Node2D/Polygon2D2, "color", Color(0.8, 0.8, 0.8), 0.2) 

#Just so idiot ol' me doesn't forget what this does again:
#It's meant to align the animation dumbass. 
func setTempVelocity(temp:float) -> void:
	tempVelocity = temp * 4.8 * Vector2(cos(charge_angle - PI/2), sin(charge_angle - PI/2)) * size# * (0.3 * charge_cooldown /charge_pull_speed)
		
func resetCharge(cutoff : bool) -> void:#distance:float, angle:float) -> void:
	#position += Vector2(cos(angle), sin(angle))*distance
	tempVelocity = Vector2.ZERO
	#$CollisionShape2D.position = Vector2(0,0)
	if cutoff:
		$InnerNode/Sprite/Node2D.position = Vector2(0,0)
		if tentacle:	
			tent_ref.resetCharge()
		#$InnerNode/Sprite/Tentacle0.position = Vector2(4,-4)
		#$InnerNode/Sprite/Tentacle1.position = Vector2(8,0)
		#$InnerNode/Sprite/Tentacle2.position = Vector2(4,4)
		#$InnerNode/Sprite/Tentacle3.position = Vector2(2,6)
		#$InnerNode/Sprite/Tentacle4.position = Vector2(0,8)
		#$InnerNode/Sprite/Tentacle5.position = Vector2(-2,6)
		#$InnerNode/Sprite/Tentacle6.position = Vector2(-4,4)
		#$InnerNode/Sprite/Tentacle7.position = Vector2(-8,0)
		#$InnerNode/Sprite/Tentacle8.position = Vector2(-4,-4)

	
	
	#$InnerNode/Camera2D.position = Vector2(0,0)

#Run all the times here that you can about the values for.
func _timers(delta:float) -> void:
	if virus_level >= 0:
		virus_level -= delta * virus_immunity
	
	#if charge_cool >= 0:
	#	charge_cool -= delta
		#if move_abil_mod < 1 and charge_cool <= charge_cooldown * 0.75:
		#	move_abil_mod = 1

func _waddleOrbDecay() -> void:
	waddle_speed_bonus -= orb_speed_gain
	if waddle_speed_bonus > 1.0:
		$WaddleOrbTimer.start(0.15)
	else:
		waddle_speed_bonus = 1.0

func energyGainFormula(value : int, enemy_drop : bool) -> float:
	if enemy_drop:
		return value
	else:
		return value * (1 + int(lasso_buffs[1]) * 0.5)

func collect(value : int, orbpos : Vector2, enemy_drop : bool, currency_type = 0) -> void:
	if currency_type == 0:
		set_energy(energyGainFormula(value, enemy_drop))
	#else: 
		#set_currency(value, currency_type)
	
	#Need a variable that tracks ripples
	#Need 3 variables that track ripple amps.
	#Need a function that's called when ripple amp reaches 0
	#Might be easier to do this with tweens than with process to be honest.
	if not enemy_drop:
		if waddle_speed < 1.0 + orb_speed_gain * 10:	
			waddle_speed_bonus += orb_speed_gain
		$WaddleOrbTimer.start(1.0)
	
	if pulseCount > 2:
		return
		#This didn't look good
		#pulseCancel(1)
		#pulseCount = 3
		
	var newpos = (orbpos - position).normalized()
	#print(newpos)
	pulseCount += 1
	
	$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("pulses", pulseCount)
	match pulseCount:
		1:
			if pulseTween1:
				pulseTween1.kill()
			pulseTween1 = create_tween()
			pulseTween1.tween_property(self, "pulseAmp1", 1.0, pulseDuration)#.from(0)
			pulseAmp1 = 0
			pulseTween1.tween_callback(pulseCancel.bind(1))
			pulseSource1 = newpos
			$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("pulseSource1", newpos)
			#$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("pulseAmp1", 0.0)
	
		2:
			if pulseTween2:
				pulseTween2.kill()
			pulseTween2 = create_tween()
			pulseTween2.tween_property(self, "pulseAmp2", 1.0, pulseDuration)#.from(0)
			pulseAmp2 = 0
			pulseTween2.tween_callback(pulseCancel.bind(2))
			pulseSource2 = newpos
			$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("pulseSource2", newpos)
			#$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("pulseAmp2", 0.0)
		3:
			if pulseTween3:
				pulseTween3.kill()
			pulseTween3 = create_tween()
			pulseTween3.tween_property(self, "pulseAmp3", 1.0, pulseDuration)#.from(0)
			pulseAmp3 = 0
			pulseTween3.tween_callback(pulseCancel.bind(3))
			pulseSource3 = newpos
			$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("pulseSource3", newpos)
			#$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("pulseAmp3", 0.0)

func pulseCancel(pulseNum : int) -> void:
	pulseCount -= 1
	#$InnerNode/Sprite/Node2D/Inside.material.call_deferred("set_shader_parameter", "pulses", pulseCount)
	$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("pulses", pulseCount)
	#print("Cancel: ",  pulseNum)
	match pulseNum:
		1:
			if pulseTween1:
				pulseTween1.kill()
			if pulseCount > 0:
				if pulseTween2:
					pulseTween2.kill()
				pulseTween1 = create_tween()
				var temp1 = pulseDuration * (1.0 - pulseAmp2)
				pulseTween1.tween_property(self, "pulseAmp1", 1.0, temp1)#.from(pulseAmp2)
				pulseAmp1 = pulseAmp2
				pulseTween1.tween_callback(pulseCancel.bind(1))
				pulseSource1 = pulseSource2
				$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("pulseSource1", pulseSource1)
				$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("pulseAmp1", pulseAmp2)
				#pulseAmp2 = 0
				if pulseCount > 1:
					if pulseTween3:
						pulseTween3.kill()
					pulseTween2 = create_tween()
					var temp2 = pulseDuration * (1.0 - pulseAmp3)
					pulseTween2.tween_property(self, "pulseAmp2", 1.0, temp2)#.from(pulseAmp3)
					pulseAmp2 = pulseAmp3
					pulseTween2.tween_callback(pulseCancel.bind(2))
					pulseSource2 = pulseSource3
					$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("pulseSource2", pulseSource2)
					$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("pulseAmp2", pulseAmp3)
					#pulseAmp3 = 0
			#else:
				#print("1 done")
		2:
			if pulseTween2:
				pulseTween2.kill()
			if pulseCount > 1:	
				if pulseTween3:
					pulseTween3.kill()
				pulseTween2 = create_tween()
				var temp2 = pulseDuration * (1.0 - pulseAmp3)
				pulseTween2.tween_property(self, "pulseAmp2", 1.0, temp2)#.from(pulseAmp3)
				pulseAmp2 = pulseAmp3
				pulseTween2.tween_callback(pulseCancel.bind(2))
				pulseSource2 = pulseSource3
				$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("pulseSource2", pulseSource2)
				$InnerNode/Sprite/Node2D/Inside.material.set_shader_parameter("pulseAmp2", pulseAmp3)
				#pulseAmp3 = 0
		3:
			if pulseTween3:
				pulseTween3.kill()
func changePosition(newpos : Vector2, dims : Vector2) -> Vector2:
	var oldPos = getPosition()
	
	var modPos = (getPosition() - dims/2).posmodv(dims)
	#var innerMod = (Inner.position - dims/2).posmodv(dims)
	#changeCamera()
	
	position = newpos + (modPos-dims/2) - Inner.position  
	#Inner.position = Vector2.ZERO 	
	#CHANGE LASSO COORD
	if primary_ability == LASSO:
		lassoRef.updateLocation(getPosition() - oldPos)
	
	for c in children_list:
		c.addPosition(getPosition() - oldPos)
		#Since we're relative this shouldn't be needed
		#if move_abil_mod == 0: 
		#	pass
	
	call_deferred("changeCamera")
	return getPosition() - oldPos

func getSpriteDuplicate() -> Node2D:
	return $InnerNode/Sprite/Node2D
	
func removeChild(childRef : Node2D) -> void:
	var temppos = children_list.find(childRef)
	if temppos == -1:
		print("CHILD NOT FOUND CHANGE THIS FUNC")
	else:
		children_list.remove_at(temppos)

#IDk why I kept this shitty function for
func changeCameraSpeed(toggle : bool, updateTime : float) -> void:
	print("THIS STUPID FUNCTION CALLED")
	if tween4:
		tween4.kill()
	tween4 = create_tween()
	
	if toggle:
		tween4.tween_property(camReference, "position_smoothing_speed", 50, updateTime)
	else:
		tween4.tween_property(camReference, "position_smoothing_speed", 5, updateTime)

#It's probably best to just disable position smoothing here
#When the player is at  a border, increase the position smoothing speed over time
#Then make it instananeous
#Keep it disabled for now and bring it back later	
func changeCamera() -> void:
	#camReference.force_update_scroll()
	
	#var zoom = 2
	
	#var camera_offset = camReference.get_screen_center_position()-camReference.get_target_position()
	
	#print("CAMERA POS: ", camReference.get_screen_center_position(), " ", camReference.get_target_position())
	#camReference.position = camera_offset/zoom
	#print("CAMERA OFFSET: ", camera_offset)
	print("CAMERA CHANGED")
	
	"""
	$InnerNode/Camera2D2.enabled = true
	#$InnerNode/Camera2D.enabled = false
	camReference.enabled = false
	
	
	if tween4:
		tween4.kill()
	tween4 = create_tween()
	tween4.tween_callback(_fixCamera.bind(0)).set_delay(0.3)
	tween4.tween_callback(_fixCamera.bind(1)).set_delay(0.3)
	tween4.tween_callback(_fixCamera.bind(2)).set_delay(3.3)
	"""
	#tween4.parallel().tween_property(camReference, "position", Vector2(0,0), 2).from(camera_offset/zoom)
	return

func _fixCamera(i : int) -> void:
	match i:
		0:
			camReference.position_smoothing_enabled = false
		1:
			camReference.position_smoothing_enabled = true
		2:
			$InnerNode/Camera2D2.enabled = false
			camReference.enabled = true
	
	#$InnerNode/Camera2D2.enabled = false
	
	#camReference.enabled = true

#Duration isn't used for this?
#This should be changed anyways. DOT damage sounds like ass for constant health.
func increaseVirusLevel(_type : int, intensity : float, _duration = 2.0) -> void:
	virus_level += intensity
	if virus_level >= virus_max:
		#Have the viri spawn out of the player as well. Just choose random ones tbh, no need to store type
		_death()

func getPosition() -> Vector2:
	return position + Inner.position

func getRotation() -> float:
	return charge_angle
	
func getScale() -> Vector2:
	return $InnerNode/Sprite/Node2D.scale

func _death() -> void:
	pass

#For all events, collectables, abilities, and monsters to use
func set_energy(amount : float) -> void:
	if amount < 0 and energy > max_energy:
		max_energy = energy
	energy += amount
	#currencyUpdate.emit(amount, 0)

#For all events, collectables, abilities, and monsters to use
func set_currency(amount : float, type = 1) -> void:
	currencyUpdate.emit(amount, type)

#For the parent to directly update currency on a purchase 
func remove_energy(amount : float) -> void:
	energy -= amount

func updateUpgrade(upgradeTab : int, upgradeID : int, upgradeCount : int) -> void:
	if (upgradeTab == 0):
		staticBonuses[upgradeID] = upgradeCount
	else:
		upgradeBonuses[upgradeTab - 1][upgradeID] = upgradeCount
		#ADD UPGRADE CASE BY CASE SCENARIOS HERE. Probably a match case idc

func updateAllUpgrades(saveBonuses : Array) -> void:
	staticBonuses = saveBonuses[0]
	upgradeBonuses = saveBonuses.slice(1)

func damagedEnemy(amt : float) -> void:
	damage_dealt += amt

#This doesn't account for bonus dmg and weakenesses but idgaf
func getDamage() -> float:
	damage_dealt += damage
	return damage
	
func getKnockback() -> float:
	return base_knockback 

func getID(idtype = 0) -> int:
	if idtype:	
		return 0
	else:
		return 0

func isDead() -> bool:
	return false

func getAttackMod(num : int) -> bool:
	return attack_mods[num]

func _on_lasso_lasso_location_reached() -> void:
	if lasso_buff:
		var tempImpactId = lassoRef.getSPAWNID(-1)
		var lasso_type = basic_movement_type
		var tempLasId = lassoRef.getSPAWNID(lasso_type)
		
		if tempLasId != -1:
			match lasso_type:
				0:
					buffRef = spawnerReference.spawnFriend(tempLasId, lassoRef.getPos())
				2:
					buffRef = spawnerReference.spawnFriend(tempLasId, lassoRef.getPos())
			if lasso_progress < 100:
				buffRef.setParams(lasso_type, lasso_progress, self)	
			else:
				buffRef.setParams(lasso_type, (fmod(lasso_progress, 100.0)), self)			
			children_list.append(buffRef)
			
		var shock = spawnerReference.spawnFriend(tempImpactId, lassoRef.getPos())
		if lasso_progress < 100:
			shock.setParams(3.0, 2.0, self, 60 * lasso_progress, 2.0)
		else:
			shock.setParams(3.0, 2.0, self, 60 * (fmod(lasso_progress, 100.0)), 2.0)
		shock.setID(tempImpactId + children_count * 10000)
		shock.connectDMG(damagedEnemy)
		children_count += 1
		children_list.append(shock)
	if primary_tween:
		primary_tween.kill()		
	move_abil_mod = 1.0		
	lasso_progress = 1000
func _on_lasso_lasso_throw_cancel() -> void:
	_lassoCancel()

func _on_lasso_lasso_buff_toggle(on: bool) -> void:
	lasso_buffs[basic_movement_type] = on

func _on_lasso_lasso_stall() -> void:
	print("LASSO STALLED")
	lasso_progress += 100
	if primary_tween:
		primary_tween.kill()
	primary_tween = create_tween()
	primary_tween.tween_interval(3.0)
	primary_tween.tween_callback(_lassoCancel)

func _on_speed_boost_boost_off_cooldown() -> void:
	sb_state = 0
	if primary_queued:
		_sbPress()
	
func _on_speed_boost_crystal_activated() -> void:
	createAfterImage.emit(3.5, 0.1, basic_movement_type, 999)
	sb_state = 2
	if primary_tween:
		primary_tween.kill()
		
	if sb_decay:
		sb_speed_buff += (sb_max_speed_buff-1.0)
	else:	
		sb_speed_buff = sb_max_speed_buff
	sb_synergy_buffs[basic_movement_type] = true
	#This is placeholder. We should have a different collision area for this.
	match basic_movement_type:
		0:
			var tempShape = CircleShape2D.new()
			tempShape.radius = base_collection_radius * sb_synergy_buff
			$CollisionShape2D.set_deferred("shape", tempShape)
		2:
			if frogState == 0:
				_frogCancel()

func _on_speed_boost_crystal_canceled(decay_rate: float, detonate : bool, sz : float, posArr : PackedVector2Array) -> void:
	
	if detonate:
		var temp_ID = sb_ref.getSPAWNID(true)
		var temp_td = spawnerReference.spawnFriend(temp_ID, Vector2.ZERO)
		temp_td.setParams(10, 0, self, sz)
		temp_td.initLines(posArr)
		children_list.append(temp_td)
		temp_td.setID(temp_ID + children_count * 10000)
		children_count += 1
	
	
	endAfterImage.emit()
	if sb_state == 2:
		sb_state = 1
	if sb_decay:
		if primary_tween:
			primary_tween.kill()
		primary_tween = create_tween()
		primary_tween.tween_property(self, "sb_speed_buff", 1.0, 2.5 * base_sb_decay_rate * decay_rate)
	else:
		sb_speed_buff = 1.0
	sb_synergy_buffs[basic_movement_type] = false
	#This is placeholder. We should have a different collision area for this. 
	match basic_movement_type:
		0:
			var tempShape = CircleShape2D.new()
			tempShape.radius = base_collection_radius
			$CollisionShape2D.set_deferred("shape", tempShape)
		2:
			if frogState == 0:	
				_frogCancel()

func _on_speed_boost_spawn_bomb(dmg : float, kb : float, sz : float, ticks : int) -> void:
	var temp_ID = sb_ref.getSPAWNID(false)
	var temp_td = spawnerReference.spawnFriend(temp_ID, getPosition())
	temp_td.setParams(dmg, kb, self, sz)
	temp_td.initExplosion(basic_movement_type, ticks)
	children_list.append(temp_td)
	temp_td.setID(temp_ID + children_count * 10000)
	children_count += 1

func getAttachNode() -> Node2D:
	return attach

func _on_hurtbox_area_entered(area: Area2D) -> void:
	#var temp_enemy = area.getParent()
	var dmg = area.getDamage()
	if area.getID() != 0 and dmg > 0: #temp_enemy.getID()
		takeDamage(dmg, area.getPosition(), area.getKnockback())

func _on_hurtbox_body_entered(body: Node2D) -> void:
	var dmg = body.getDamage()
	if body.getID() != 0 and dmg > 0:
		takeDamage(dmg, body.getPosition(), body.getKnockback())
#Damage after damage reduction reset shields as well 
func _damageTakenFormula(damageTaken : float) -> float:
	return damageTaken

func takeDamage(dmg : float, dmgDir = Vector2.ZERO, kb = 1.0, _kwargs = []) -> void:
	if not $InvulTimer.is_stopped():
		return
	
	print("dmg taken")
	
	#Damage after damage reduction reset shields as well 
	var damage_taken = _damageTakenFormula(dmg) #_damageTakenFormula()
	
	#If energy is 0, need to trigger some sort of death punishment. Let the player survive 1 hit at 0 first.
	var energy_lost = min(damage_taken, energy)
	
	var dmg_ratio = clampf(10 * energy_lost/(max_energy+1.0), 0.5, 3.0)
	print("dmg ratio this should be min 0.5", dmg_ratio)
	var invul_time = base_invul_time * dmg_ratio + 0.25 * kb
	print("INVUL TIMMEEEE ", invul_time)
	
	set_energy(-energy_lost)
	
	_damagedEffect(dmg_ratio, dmgDir, kb, _kwargs)
	
	#$InnerNode/Hurtbox.set_deferred("monitoring", false)
	$InvulTimer.start(invul_time)
	
	spawnOrbs.emit(ceil(energy_lost * orb_refund_ratio), getPosition())

func _damagedEffect(amt : float, pos : Vector2, kb : float = 1.0, _kwargs = []) -> void:
	knockback(pos, amt, kb)

#player cannot get multiple knocback effects. If they somehow get a new one, just cancel the old one.
#Player shouldn't be able to do things while knockbacked. Make sure to cancel abilities and such.
func knockback(pos: Vector2, dmg : float, kb : float = 1.0, speed = 0) -> void:
	
	#Regurgitate Crystal
	if primary_ability == SPEED_BOOST and sb_state == 2:
		_sbPress()
	
	var power = kb * dmg * max(1.0-knockback_resist, 0.0)
	var dir : Vector2 = getPosition() - pos
	#var dir_len : float = dir.length()
	#if dir_len < 20:
	#	dir_len = 20
	var dir_norm : Vector2 = dir.normalized() #Could also do dir / dir_len
	
	#var dirPower = 5000.0 * power / dir_len 
	var end_dir = 180.0 * power*dir_norm
	print("enddidr: ", end_dir, " dirpow ", dir_norm, " POWER ", power, " pow ", dmg, " ", kb)
	kb_moving = true
	if power <= 0.5 or super_armor:
		var shakePow = min(power, 0.5)
		_shake(shakePow * dir_norm, shakePow)
	else:
		move_kb_mod = 0
		var rot_speed = 2.0 * log(power+1.25) if dir.x > 0 else -2.0 * log(power+1.25)
		if knockback_tween:
			knockback_tween.kill()
		knockback_tween = create_tween()
		match speed:
			0:
				knockback_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			1:
				knockback_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			2:
				knockback_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		kb_moving = true
		var timeSpeed = snapped(log(0.5*kb + dmg+1.0), 0.01)
		knockback_tween.tween_property(Inner, "position", end_dir, timeSpeed).as_relative()
		knockback_tween.parallel().tween_property(sprite_ref, "rotation", rot_speed, timeSpeed).as_relative()
		knockback_tween.parallel().tween_property(self, "charge_angle", rot_speed, timeSpeed).as_relative()
		knockback_tween.set_ease(Tween.EASE_IN)
		knockback_tween.parallel().tween_property(self, "move_kb_mod", 1.0, 0.1)
		knockback_tween.set_trans(Tween.TRANS_LINEAR)
		knockback_tween.parallel().tween_property(sprite_ref, "modulate", Color(0.8, 0.4, 0.4, 1.0), 0.25)
		knockback_tween.parallel().tween_property(sprite_ref, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25).set_delay(0.35)
		knockback_tween.tween_callback(_knockbackEnd)
	

func _knockbackCancel() -> void:
	kb_moving = false
	if knockback_tween:
		knockback_tween.kill()
	knockback_tween = create_tween()	
	knockback_tween.tween_property(sprite_ref, "position", Vector2.ZERO, 0.25)
	knockback_tween.parallel().tween_property(sprite_ref, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
	move_kb_mod = 1.0
	
func _knockbackEnd() -> void:
	kb_moving = false
	move_kb_mod = 1.0

func _shake(direction: Vector2, power : float) -> void:
	if knockback_tween:
		knockback_tween.kill()
	knockback_tween = create_tween()
	knockback_tween.tween_property(sprite_ref, "position", direction * 30.0, power / 4).as_relative()
	knockback_tween.tween_property(sprite_ref, "position", direction * -45.0, power / 2).as_relative()
	knockback_tween.tween_property(sprite_ref, "position", direction * 30.0, power / 2).as_relative()
	knockback_tween.tween_property(sprite_ref, "position", Vector2.ZERO, power / 4)
	knockback_tween.parallel().tween_property(sprite_ref, "modulate", Color(0.8, 0.4, 0.4, 1.0), 0.25)
	knockback_tween.tween_property(sprite_ref, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
	
func _on_invul_timer_timeout() -> void:
	#Extend timer if player is still colliding
	if invul_leeway_count == 0:
		$InnerNode/Hurtbox.set_deferred("monitoring", true)
		invul_leeway_count = 2
	elif _collisionCheck():
		invul_leeway_count = 2
		$InvulTimer.start(10.0)
		$InvulLeeWay.start()
	

func _on_invul_lee_way_timeout() -> void:
	invul_leeway_count -= 1
	if invul_leeway_count == 0 or not _collisionCheck():
		$InnerNode/Hurtbox.set_deferred("monitoring", false)
		$InvulTimer.start(0.05)
		invul_leeway_count = 0
	else:
		$InvulLeeWay.start()

func _collisionCheck() -> bool:
	var hurtboxReference = $InnerNode/Hurtbox
	if (hurtboxReference.has_overlapping_areas() or hurtboxReference.has_overlapping_bodies()):
		var localAreas = hurtboxReference.get_overlapping_areas()
		for a in localAreas:
			if a.getID() != 0 and a.getDamage() > 0:
				return true
		
		var localBodies = hurtboxReference.get_overlapping_bodies()
		for b in localBodies:
			if b.getID() != 0 and b.getDamage() > 0:
				return true
	return false
