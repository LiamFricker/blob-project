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

#Offensive variables
var damage : float = 1.0
var base_knockback : float = 1.0

var energy = 0
signal currencyUpdate(index : int, value : float)
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

#You should attach these to a resource
#WADDLE VARS
#var waddle = false
@export var waddle_speed = 1
var waddle_speed_bonus : float = 1.0
@export var orb_speed_gain : float = 0.2
var accel: float = 50
var turning_accel_ratio: float = 1.25

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

@export var friction: float = 0.25

var isHazard : bool = false



enum {
	CHARGE_DASH,
	LASSO,
	JUMP,
	GRAPPLE,
	DIVE, 
	WALLKICK,
	KITE
}
var primary_ability = CHARGE_DASH

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

@export var charge_dash: bool = true
#var chargeVelocity: Vector2 = Vector2.ZERO
var chargeStrength: float = 0

@onready var attach = $Attachments

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
@export var tentacleAmount:int = 9
@export var tentacleLength:int = 8
@export var tentacleAlphaAmount:int = 0 
var chargeTentacleSpin:float = 0 #very misleading name, basically how much Right/Left while charging affects the tentacles
var reverseTentacleSpin:float = 0#this is actually for the charge part.
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
		$Sprite/Tentacle1.whip(-1)

func activateRipple(origin: Vector2, amplitude: float) -> void:
	$Sprite/Node2D/Inside.material.set_shader_parameter("rippleSource", origin)
	$Sprite/Node2D/Inside.material.set_shader_parameter("rippleAmp", amplitude)
	$Sprite/Node2D/Inside.material.set_shader_parameter("rippleAmpMax", -amplitude)
	$Sprite/Node2D/Inside.material.set_shader_parameter("rippleOn", true)
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
	for i in range(18):
		print(rad_to_deg((i - 9.5) * PI/8), " ueh ", (Vector2.from_angle(snapped((i - 9.5) * PI/8, PI/4))).snappedf(1.0))
	
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
	$Test.position = mousePos
	
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
		$Sprite/Node2D/Inside.material.set_shader_parameter("rippleAmp", rippleAmpCurrent)
		if oscilator > 17.5:
			rippleOn = false
			$Sprite/Node2D/Inside.material.set_shader_parameter("rippleAmp", 0)
		elif oscilator > rippleTime:
			rippleMax *= -0.6
			$Sprite/Node2D/Inside.material.set_shader_parameter("rippleAmpMax", rippleMax)
			rippleTime += 1.2
	
	if pulseCount > 0:
		#print("PulseCount: ", pulseCount)
		$Sprite/Node2D/Inside.material.set_shader_parameter("pulseAmp1", pulseAmp1)
		#print("Pulse Amp 1: ", pulseAmp1)
		if pulseCount > 1:
			#print("Pulse Amp 2: ", pulseAmp2)
			$Sprite/Node2D/Inside.material.set_shader_parameter("pulseAmp2", pulseAmp2)
			if pulseCount > 2:
				#print("Pulse Amp 3: ", pulseAmp3)
				$Sprite/Node2D/Inside.material.set_shader_parameter("pulseAmp3", pulseAmp3)
	
	if charge_dash:# and chargeStrength > 2:
		_chargeDash(delta, friction_delta)
	else:
		velocity += tempVelocity	 	
		move_and_slide()
		velocity -= tempVelocity	 
		
		velocity *= friction_delta#pow(friction, delta)
		
	if charge_cool > 0 and abs(chargeTentacleSpin + reverseTentacleSpin) > 0:
		chargeTentacleSpin *= pow(0.1, delta)
		handleTentacleShader()
	
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
	var x_dir : float
	var y_dir : float
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
	#print("Right: ", Input.is_action_pressed("Right"))
	#print(velocity.length()/100)
	#$Sprite/Node2D/Inside.material.set_shader_parameter("frequency", 2.5 + ceil(velocity.length())/100 * size)
	$Sprite/Node2D/Inside.material.set_shader_parameter("amplitude", 0.5 + ceil(velocity.length())/20 * size)
	
	var waddle_total_speed = accel * delta * waddle_speed * move_abil_mod * waddle_speed_bonus
	
	if x_dir == sign(velocity.x) * -1:
		velocity.x += x_dir * waddle_total_speed * turning_accel_ratio
	else:
		velocity.x += x_dir * waddle_total_speed
	if y_dir == sign(velocity.y) * -1:
		velocity.y += y_dir * waddle_total_speed * turning_accel_ratio
	else:
		velocity.y += y_dir * waddle_total_speed
	
func _boardLogic(delta: float, friction_delta : float) -> void:
	var x_dir : float
	var y_dir : float
	if mouseMovement:
		#This is inefficient but I know doing this manually is a pain in the ass to bug fix so I cba
		var tempAng = mousePos.angle_to(Vector2.from_angle(charge_angle+PI/2))
	
		x_dir = sign(tempAng)
		var mousePosLen = mousePos.length()
		if abs(tempAng) > PI/2:
			y_dir = -1
		elif mousePosLen < 15:
			y_dir = 0
		elif mousePosLen < 100:
			y_dir = mousePos.y/100
		else:
			y_dir = 1
	else:
		x_dir = int(right_input) - int(left_input)
		y_dir = int(down_input) - int(up_input)
	
	$Sprite/Node2D/Inside.material.set_shader_parameter("amplitude", 0.5 + ceil(velocity.length())/20 * size)
	
	charge_angle += board_turning_speed * x_dir * delta * move_abil_mod
	$Pivot.rotation = charge_angle
	$Sprite.rotation = charge_angle
			
	#board_speed += board_accel
	
	if y_dir == -1:
		board_speed += board_accel * move_abil_mod
		#velocity.y += y_dir * accel * turning_accel_ratio * delta * waddle_speed * move_abil_mod	
	elif y_dir == 0:
		board_speed += board_accel * 0.25 * move_abil_mod
		board_speed *= sqrt(friction_delta)
	else:
		board_speed *= friction_delta
	
	if board_speed > board_speed_cap:
		board_speed = board_speed_cap
	
	velocity = board_speed * move_abil_mod * Vector2(cos(charge_angle - PI/2), sin(charge_angle - PI/2))

func _frogLogic(_delta : float, _friction_delta : float) -> void:
	#This is not handled in _unhandledInput because that can only detect 1 input at a time
	#We want to handle in case someone wants to dash diagonally.
	#print("X: ", frog_charge, " " , frogState)#, " ", frogTemp)
	
	#HAHAHAH TAKE THAT OLD ME
	#YOU WERE WRONG I SURPASSED YOU
	#Let's just keep this here in case we need it.
	pass

func _chargeDash(delta: float, friction_delta : float)-> void:
	var temp : float
	if mouseMovement:
		temp = sign(mousePos.angle_to(Vector2.from_angle(charge_angle+PI/2)))
	else:
		temp = int(right_input) - int(left_input)
	charge_angle += charge_angle_speed * temp * delta * chargeStrength * 0.005
	$Pivot.rotation = charge_angle
	$Sprite.rotation = charge_angle
	
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
			return
			
		if event.is_action_pressed("Right"):
			right_input = true
			_basicOnPress()
			return
		elif event.is_action_released("Right"):
			right_input = false
			return
		
		if event.is_action_pressed("Up"):
			up_input = true
			_basicOnPress()
			return
		elif event.is_action_released("Up"):
			up_input = false
			return
		
		if event.is_action_pressed("Down"):
			down_input = true
			_basicOnPress()
			return
		elif event.is_action_released("Down"):
			down_input = false
			return

func _basicOnPress() -> void:
	match basic_movement_type:
		FROG:
			if frogState == 0 and frog_charge >= 0:
				_frogReset()
		_:
			pass

func _getFrogDirection() -> bool:
	var x_dir : float
	var y_dir : float
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
			
		if state == CHARGING and charge_time < charge_max:#state == CHARGING or charge_cool > 0: 
			basic_tween.tween_property(self, "frog_charge", frogLowerBound, frogLowerBound / frog_charge_gain).as_relative()
			#var tempVec = 0.25 * (scaleVec - Vector2(1.0, 1.0))
			#basic_tween.tween_property($Sprite/Node2D, "scale", tempVec, frogLowerBound / frog_charge_gain).as_relative()
		else:
			basic_tween.tween_property($Sprite/Node2D, "scale", scaleVec, frogLowerBound / frog_charge_gain)
			
		"""
		if frogDirection.y:
			if frogDirection.x:
				basic_tween.tween_property($Sprite/Node2D, "scale", Vector2(0.7, 0.7), frogLowerBound / frog_charge_gain)
			else:
				basic_tween.tween_property($Sprite/Node2D, "scale", Vector2(1, 0.7), frogLowerBound / frog_charge_gain)
		elif frogDirection.x:
			basic_tween.tween_property($Sprite/Node2D, "scale", Vector2(0.7, 1), frogLowerBound / frog_charge_gain)
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
		if state == CHARGING and charge_time < charge_max:#state == CHARGING or charge_cool > 0: 
			#var tempVec = 0.1 * (scaleVec - Vector2(1.0, 1.0))
			#basic_tween.tween_property($Sprite/Node2D, "scale", tempVec, frogLowerBound / frog_charge_gain).as_relative()
			basic_tween.tween_property(self, "frog_charge", frogLowerBound, frogLowerBound / frog_charge_gain).as_relative()
		else:
			basic_tween.tween_property($Sprite/Node2D, "scale", scaleVec, frogLowerBound / frog_charge_gain)
			basic_tween.parallel().tween_property(self, "frog_charge", frogLowerBound, frogLowerBound / frog_charge_gain).as_relative()
			"""
			if frogDirection.y:
				if frogDirection.x:
					basic_tween.tween_property($Sprite/Node2D, "scale", Vector2(0.4, 0.4), frogLowerBound / frog_charge_gain)
				else:
					basic_tween.tween_property($Sprite/Node2D, "scale", Vector2(1, 0.4), frogLowerBound / frog_charge_gain)
			elif frogDirection.x:
				basic_tween.tween_property($Sprite/Node2D, "scale", Vector2(0.4, 1), frogLowerBound / frog_charge_gain)
			"""
		
		basic_tween.finished.connect(_frogRelease)
	else:
		_frogCancel()

func _frogCancel() -> void:
	frogState = 0
	if basic_tween:
		basic_tween.kill()
	basic_tween = create_tween()
	if state == CHARGING and charge_time < charge_max:#state == CHARGING or charge_cool > 0:
		basic_tween.tween_property(self, "frog_charge", frog_max_charges, frog_max_charges * 2.0 / frog_charge_gain).as_relative() 
		basic_tween.parallel().tween_property($Sprite/Node2D, "position", Vector2(0.0, 0.0), 0.25)
	else:
		basic_tween.tween_property($Sprite/Node2D, "scale", Vector2(1.0, 1.0), 0.25)
		basic_tween.parallel().tween_property($Sprite/Node2D, "position", Vector2(0.0, 0.0), 0.25)
		basic_tween.parallel().tween_property(self, "frog_charge", frog_max_charges, frog_max_charges * 2.0 / frog_charge_gain).as_relative()

func _frogReset() -> void:
	if _getFrogDirection():
		_frogPressStart()
	else:
		_frogCancel() 

func _frogRelease() -> void:
	frogState = 3
	velocity += frogDirection * frog_speed * 100 * frog_travel_speed
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
		var tempVec = 0.1 * (scaleVec - Vector2(1.0, 1.0))
		#basic_tween.tween_property($Sprite/Node2D, "scale", tempVec, 0.1 / frog_travel_speed).as_relative()	
		basic_tween.parallel().tween_property($Sprite/Node2D, "position", posVec, 0.1 / frog_travel_speed)#.as_relative()
		#basic_tween.tween_property($Sprite/Node2D, "scale", -tempVec, 0.2 / frog_travel_speed).as_relative()
		basic_tween.parallel().tween_property($Sprite/Node2D, "position", Vector2(0, 0), 0.4 / frog_travel_speed)#.as_relative()
	else:	
		basic_tween.tween_property($Sprite/Node2D, "scale", scaleVec, 0.1 / frog_travel_speed)	
		basic_tween.parallel().tween_property($Sprite/Node2D, "position", posVec, 0.1 / frog_travel_speed)
		basic_tween.tween_property($Sprite/Node2D, "scale", Vector2(1, 1), 0.4 / frog_travel_speed)
		basic_tween.parallel().tween_property($Sprite/Node2D, "position", Vector2(0, 0), 0.4 / frog_travel_speed) 
	
	basic_tween.parallel().tween_property(self, "frog_charge", -1.0, 0.4 / frog_travel_speed).as_relative()
	basic_tween.finished.connect(_frogReset)
	
	#handleTentacleReturn()

func _primaryOnPress() -> void:
	match primary_ability:
		CHARGE_DASH:
			if charge_cool < 0:
				_chargePress()
			else:
				primary_queued = true
				
func _primaryOnRelease() -> void:
	match primary_ability:
		CHARGE_DASH:
			if charge_cool < 0:
				_chargeRelease()
			else:
				primary_queued = false

func _chargePress() -> void:
	state = CHARGING
	if primary_tween:
		primary_tween.kill()
	primary_tween = create_tween()
	if $Sprite/Node2D.position.y != 0:
		resetCharge(true)
	$Pivot.modulate = Color(1,1,1,1)
	if frogState == 0:	
		primary_tween.tween_property($Pivot, "scale", Vector2(-2, 0.6), charge_max)
	#if frog_charge <= 0:	
	primary_tween.parallel().tween_property($Sprite/Node2D, "scale", Vector2(1, 0.25), charge_max)
	primary_tween.finished.connect(_onFullCharge)
	handleTentacleSqueeze()	
	move_abil_mod = 0.25
	charge_time = 0

func _chargeOffCD() -> void:
	if primary_queued:
		_chargePress()
	
func _chargeRelease() -> void:
	if basic_tween and basic_movement_type == FROG:
		basic_tween.kill()
	primary_queued = false
	charge_cool = charge_cooldown 
	state = IDLE
	move_abil_mod = 1
	if primary_tween:
		primary_tween.kill()
	primary_tween = create_tween()
	primary_tween.tween_property($Pivot, "scale", Vector2(1, 1.5), 0.1 * charge_cooldown)
	$Pivot/Node2D/Glimmer.texture_offset = Vector2(3, 25)
	$Pivot/Node2D/Polygon2D2.color = Color(0.8, 0.8, 0.8)
	charge_time = min(charge_time, charge_max)
	charge_time = max(charge_time, charge_floor)  
	var temp = ceil(10 * charge_time/charge_max) * charge_length# if charge_time < charge_floor else ceil(10 * charge_time/charge_max) * charge_length
	
	#print("Temp ", temp / charge_length)
	#Temp/20 doesn't make sense to me here
	primary_tween.tween_property($Sprite/Node2D, "scale", Vector2(temp/20, 1 + 0.1 * temp), 0.08 * charge_cooldown)
	primary_tween.parallel().tween_property($Sprite/Node2D, "position", Vector2(0, -3.6 * temp), 0.08 * charge_cooldown)
	primary_tween.parallel().tween_property(self, "reverseTentacleSpin", 1.0, 0.08 * charge_cooldown)
	handleTentacleStretch(temp)

	primary_tween.tween_callback(self.setTempVelocity.bind(temp))
	primary_tween.tween_callback(self.activateRipple.bind(Vector2(0, -1), temp/10))
	primary_tween.tween_property($Sprite/Node2D, "scale", Vector2(1, 1), 0.3 * charge_cooldown/charge_pull_speed)
	primary_tween.parallel().tween_property(self, "reverseTentacleSpin", 0.0, 0.3 * charge_cooldown)
	primary_tween.parallel().tween_property($Sprite/Node2D, "position", Vector2(0, 0), 0.3 * charge_cooldown /charge_pull_speed) #-4.8 * temp
	handleTentacleReturn()
	
	primary_tween.tween_callback(self.resetCharge.bind(false))#.bind(4.8*temp, charge_angle - PI/2))
	
	#Too lazy to create a timer for this exact case
	get_tree().create_timer(charge_cool).timeout.connect(_chargeOffCD)
	
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
		if basic_tween:
			basic_tween.kill()
		basic_tween = create_tween()
		basic_tween.tween_property(self, "frog_charge", frog_max_charges, frog_max_charges * 2.0 / frog_charge_gain).as_relative()
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
		
	handleTentacleShader()	
	$Pivot.rotation = charge_angle
	$Sprite.rotation = charge_angle

func _onFullCharge() -> void:
	if tween2:
		tween2.kill()
	tween2 = create_tween()
	tween2.tween_property($Pivot/Node2D/Glimmer, "texture_offset", Vector2(24, 7), 0.4)
	tween2.parallel().tween_property($Pivot/Node2D/Polygon2D2, "color", Color(1, 1, 0), 0.2)
	tween2.tween_property($Pivot/Node2D/Polygon2D2, "color", Color(0.8, 0.8, 0.8), 0.2) 

#Just so idiot ol' me doesn't forget what this does again:
#It's meant to align the animation dumbass. 
func setTempVelocity(temp:float) -> void:
	tempVelocity = temp * 4.8 * Vector2(cos(charge_angle - PI/2), sin(charge_angle - PI/2)) * size# * (0.3 * charge_cooldown /charge_pull_speed)
		
func resetCharge(cutoff : bool) -> void:#distance:float, angle:float) -> void:
	#position += Vector2(cos(angle), sin(angle))*distance
	tempVelocity = Vector2.ZERO
	#$CollisionShape2D.position = Vector2(0,0)
	if cutoff:
		$Sprite/Node2D.position = Vector2(0,0)
		$Sprite/Tentacle0.position = Vector2(4,-4)
		$Sprite/Tentacle1.position = Vector2(8,0)
		$Sprite/Tentacle2.position = Vector2(4,4)
		$Sprite/Tentacle3.position = Vector2(2,6)
		$Sprite/Tentacle4.position = Vector2(0,8)
		$Sprite/Tentacle5.position = Vector2(-2,6)
		$Sprite/Tentacle6.position = Vector2(-4,4)
		$Sprite/Tentacle7.position = Vector2(-8,0)
		$Sprite/Tentacle8.position = Vector2(-4,-4)

	
	
	#$Camera2D.position = Vector2(0,0)

func handleTentacleShader():
	match tentacleAmount:
		1:
			$Sprite/Tentacle1/Node2D/Line2D.material.set_shader_parameter("direction", chargeTentacleSpin)
		2:
			$Sprite/Tentacle1/Node2D/Line2D.material.set_shader_parameter("direction", chargeTentacleSpin)
			$Sprite/Tentacle7/Node2D/Line2D.material.set_shader_parameter("direction", chargeTentacleSpin)
		3:
			$Sprite/Tentacle1/Node2D/Line2D.material.set_shader_parameter("direction", chargeTentacleSpin+reverseTentacleSpin)
			$Sprite/Tentacle7/Node2D/Line2D.material.set_shader_parameter("direction", chargeTentacleSpin-reverseTentacleSpin)
			$Sprite/Tentacle4/Node2D/Line2D.material.set_shader_parameter("direction", chargeTentacleSpin)
		9:
			$Sprite/Tentacle0/Node2D/Line2D.material.set_shader_parameter("direction", chargeTentacleSpin+reverseTentacleSpin)
			$Sprite/Tentacle1/Node2D/Line2D.material.set_shader_parameter("direction", chargeTentacleSpin+reverseTentacleSpin*2)
			$Sprite/Tentacle2/Node2D/Line2D.material.set_shader_parameter("direction", chargeTentacleSpin+reverseTentacleSpin*3)
			$Sprite/Tentacle3/Node2D/Line2D.material.set_shader_parameter("direction", chargeTentacleSpin+reverseTentacleSpin*4)
			
			$Sprite/Tentacle5/Node2D/Line2D.material.set_shader_parameter("direction", chargeTentacleSpin-reverseTentacleSpin*4)
			$Sprite/Tentacle6/Node2D/Line2D.material.set_shader_parameter("direction", chargeTentacleSpin-reverseTentacleSpin*3)
			$Sprite/Tentacle7/Node2D/Line2D.material.set_shader_parameter("direction", chargeTentacleSpin-reverseTentacleSpin*2)
			$Sprite/Tentacle8/Node2D/Line2D.material.set_shader_parameter("direction", chargeTentacleSpin-reverseTentacleSpin)
			
			$Sprite/Tentacle4/Node2D/Line2D.material.set_shader_parameter("direction", chargeTentacleSpin)
	

func handleTentacleSqueeze():
	match tentacleAmount:
		0:
			pass
		9:
			primary_tween.parallel().tween_property($Sprite/Tentacle0, "position", Vector2(4, -2), charge_max)
			
			primary_tween.parallel().tween_property($Sprite/Tentacle2, "position", Vector2(4, 2), charge_max)
			primary_tween.parallel().tween_property($Sprite/Tentacle3, "position", Vector2(2, 2), charge_max)
			primary_tween.parallel().tween_property($Sprite/Tentacle4, "position", Vector2(0, 2), charge_max)
			primary_tween.parallel().tween_property($Sprite/Tentacle5, "position", Vector2(-2, 2), charge_max)
			primary_tween.parallel().tween_property($Sprite/Tentacle6, "position", Vector2(-4, 2), charge_max)
			
			primary_tween.parallel().tween_property($Sprite/Tentacle8, "position", Vector2(-4, -2), charge_max)
			#tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(0, -3.6 * temp), 0.08 * charge_cooldown)		

func handleTentacleStretch(temp:float):
	match tentacleAmount:
		0:
			pass
		1:
			primary_tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(0, -3.6 * temp), 0.08 * charge_cooldown)
		2:
			primary_tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(0, -3.6 * temp), 0.08 * charge_cooldown)
		3:
			primary_tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(0, -3.6 * temp), 0.08 * charge_cooldown)
			
			if tween3:
				tween3.kill()
			tween3 = create_tween()
			tween3.tween_property($Sprite/Tentacle1, "rotation", PI/2, 0.3 * charge_cooldown)
			tween3.parallel().tween_property($Sprite/Tentacle7, "rotation", -3*PI/2, 0.3 * charge_cooldown)
		4:
			primary_tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(0, -3.6 * temp), 0.08 * charge_cooldown)	
		9:
			primary_tween.parallel().tween_property($Sprite/Tentacle0, "position", Vector2(4, -4-3.6*temp), 0.08 * charge_cooldown)
			primary_tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(6, -3.6*temp), 0.08 * charge_cooldown)
			primary_tween.parallel().tween_property($Sprite/Tentacle2, "position", Vector2(4, 4-3.6*temp), 0.08 * charge_cooldown)
			primary_tween.parallel().tween_property($Sprite/Tentacle3, "position", Vector2(2, 6-3.6*temp), 0.08 * charge_cooldown)
			primary_tween.parallel().tween_property($Sprite/Tentacle4, "position", Vector2(0, 8-3.6*temp), 0.08 * charge_cooldown)
			primary_tween.parallel().tween_property($Sprite/Tentacle5, "position", Vector2(-2, 6-3.6*temp), 0.08 * charge_cooldown)
			primary_tween.parallel().tween_property($Sprite/Tentacle6, "position", Vector2(-4, 4-3.6*temp), 0.08 * charge_cooldown)
			primary_tween.parallel().tween_property($Sprite/Tentacle7, "position", Vector2(-6, -3.6*temp), 0.08 * charge_cooldown)
			primary_tween.parallel().tween_property($Sprite/Tentacle8, "position", Vector2(-4, -4-3.6*temp), 0.08 * charge_cooldown)
			
			if tween3:
				tween3.kill()
			tween3 = create_tween()
			tween3.tween_property($Sprite/Tentacle7, "rotation", PI/2, 0.3 * charge_cooldown)
			tween3.parallel().tween_property($Sprite/Tentacle1, "rotation", PI/2, 0.3 * charge_cooldown)
			tween3.parallel().tween_property($Sprite/Tentacle2, "rotation", PI/2, 0.3 * charge_cooldown)
			tween3.parallel().tween_property($Sprite/Tentacle3, "rotation", PI/2, 0.3 * charge_cooldown)
			tween3.parallel().tween_property($Sprite/Tentacle5, "rotation", PI/2, 0.3 * charge_cooldown)
			tween3.parallel().tween_property($Sprite/Tentacle6, "rotation", PI/2, 0.3 * charge_cooldown)
			
			tween3.parallel().tween_property($Sprite/Tentacle0, "rotation", PI/2, 0.3 * charge_cooldown)
			tween3.parallel().tween_property($Sprite/Tentacle8, "rotation", -3*PI/2, 0.3 * charge_cooldown)
			
			
func handleTentacleReturn():
	match tentacleAmount:
		0:
			pass
		1:
			primary_tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(8, 0), 0.3 * charge_cooldown)
		3:
			primary_tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(8, 0), 0.3 * charge_cooldown)
			tween3.tween_property($Sprite/Tentacle1, "rotation", 0, 0.6 * charge_cooldown)
			tween3.parallel().tween_property($Sprite/Tentacle7, "rotation", PI, 0.6 * charge_cooldown)
		9:
			primary_tween.parallel().tween_property($Sprite/Tentacle0, "position", Vector2(4, -4), 0.3 * charge_cooldown)
			primary_tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(8, 0), 0.3 * charge_cooldown)
			primary_tween.parallel().tween_property($Sprite/Tentacle2, "position", Vector2(4, 4), 0.3 * charge_cooldown)
			primary_tween.parallel().tween_property($Sprite/Tentacle3, "position", Vector2(2, 6), 0.3 * charge_cooldown)
			primary_tween.parallel().tween_property($Sprite/Tentacle4, "position", Vector2(0, 8), 0.3 * charge_cooldown)
			primary_tween.parallel().tween_property($Sprite/Tentacle5, "position", Vector2(-2, 6), 0.3 * charge_cooldown)
			primary_tween.parallel().tween_property($Sprite/Tentacle6, "position", Vector2(-4, 4), 0.3 * charge_cooldown)
			primary_tween.parallel().tween_property($Sprite/Tentacle7, "position", Vector2(-8, 0), 0.3 * charge_cooldown)
			primary_tween.parallel().tween_property($Sprite/Tentacle8, "position", Vector2(-4, -4), 0.3 * charge_cooldown)
			
			tween3.tween_property($Sprite/Tentacle1, "rotation", 0, 0.6 * charge_cooldown)
			tween3.parallel().tween_property($Sprite/Tentacle7, "rotation", PI, 0.6 * charge_cooldown)
			tween3.parallel().tween_property($Sprite/Tentacle2, "rotation", PI/4, 0.6 * charge_cooldown)
			tween3.parallel().tween_property($Sprite/Tentacle3, "rotation", 3*PI/8, 0.6 * charge_cooldown)
			tween3.parallel().tween_property($Sprite/Tentacle4, "rotation", PI/2, 0.6 * charge_cooldown)
			tween3.parallel().tween_property($Sprite/Tentacle5, "rotation", 5*PI/8, 0.6 * charge_cooldown)
			tween3.parallel().tween_property($Sprite/Tentacle6, "rotation", 3*PI/4, 0.6 * charge_cooldown)
			
			tween3.parallel().tween_property($Sprite/Tentacle8, "rotation", -3*PI/4, 0.6 * charge_cooldown)
			tween3.parallel().tween_property($Sprite/Tentacle0, "rotation", -PI/4, 0.6 * charge_cooldown)
			
	#Cool useless line of code
	#for i in range(tentacleAmount):	
	#	tween.parallel().tween_property(get_node("Sprite/Tentacle"+str(i+1)), "position", Vector2(8, 0), 0.3 * charge_cooldown)

#Run all the times here that you can about the values for.
func _timers(delta:float) -> void:
	if virus_level >= 0:
		virus_level -= delta * virus_immunity
	
	if charge_cool >= 0:
		charge_cool -= delta
		#if move_abil_mod < 1 and charge_cool <= charge_cooldown * 0.75:
		#	move_abil_mod = 1

func _waddleOrbDecay() -> void:
	waddle_speed_bonus -= orb_speed_gain
	if waddle_speed_bonus > 1.0:
		$WaddleOrbTimer.start(0.15)
	else:
		waddle_speed_bonus = 1.0

func collect(_value : int, orbpos : Vector2, enemy_drop : bool, _currency_type = 0) -> void:
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
	
	$Sprite/Node2D/Inside.material.set_shader_parameter("pulses", pulseCount)
	match pulseCount:
		1:
			if pulseTween1:
				pulseTween1.kill()
			pulseTween1 = create_tween()
			pulseTween1.tween_property(self, "pulseAmp1", 1.0, pulseDuration)#.from(0)
			pulseAmp1 = 0
			pulseTween1.tween_callback(pulseCancel.bind(1))
			pulseSource1 = newpos
			$Sprite/Node2D/Inside.material.set_shader_parameter("pulseSource1", newpos)
			#$Sprite/Node2D/Inside.material.set_shader_parameter("pulseAmp1", 0.0)
	
		2:
			if pulseTween2:
				pulseTween2.kill()
			pulseTween2 = create_tween()
			pulseTween2.tween_property(self, "pulseAmp2", 1.0, pulseDuration)#.from(0)
			pulseAmp2 = 0
			pulseTween2.tween_callback(pulseCancel.bind(2))
			pulseSource2 = newpos
			$Sprite/Node2D/Inside.material.set_shader_parameter("pulseSource2", newpos)
			#$Sprite/Node2D/Inside.material.set_shader_parameter("pulseAmp2", 0.0)
		3:
			if pulseTween3:
				pulseTween3.kill()
			pulseTween3 = create_tween()
			pulseTween3.tween_property(self, "pulseAmp3", 1.0, pulseDuration)#.from(0)
			pulseAmp3 = 0
			pulseTween3.tween_callback(pulseCancel.bind(3))
			pulseSource3 = newpos
			$Sprite/Node2D/Inside.material.set_shader_parameter("pulseSource3", newpos)
			#$Sprite/Node2D/Inside.material.set_shader_parameter("pulseAmp3", 0.0)

func pulseCancel(pulseNum : int) -> void:
	pulseCount -= 1
	#$Sprite/Node2D/Inside.material.call_deferred("set_shader_parameter", "pulses", pulseCount)
	$Sprite/Node2D/Inside.material.set_shader_parameter("pulses", pulseCount)
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
				$Sprite/Node2D/Inside.material.set_shader_parameter("pulseSource1", pulseSource1)
				$Sprite/Node2D/Inside.material.set_shader_parameter("pulseAmp1", pulseAmp2)
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
					$Sprite/Node2D/Inside.material.set_shader_parameter("pulseSource2", pulseSource2)
					$Sprite/Node2D/Inside.material.set_shader_parameter("pulseAmp2", pulseAmp3)
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
				$Sprite/Node2D/Inside.material.set_shader_parameter("pulseSource2", pulseSource2)
				$Sprite/Node2D/Inside.material.set_shader_parameter("pulseAmp2", pulseAmp3)
				#pulseAmp3 = 0
		3:
			if pulseTween3:
				pulseTween3.kill()
func changePosition(newpos : Vector2, dims : Vector2) -> void:
	var modPos = (position - dims/2).posmodv(dims)
	
	#changeCamera()
	
	position = newpos + (modPos-dims/2)  	
	#CHANGE LASSO COORD
	if primary_ability == LASSO:
		pass
	
	call_deferred("changeCamera")
	#return position

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
	$Camera2D2.enabled = true
	#$Camera2D.enabled = false
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
			$Camera2D2.enabled = false
			camReference.enabled = true
	
	#$Camera2D2.enabled = false
	
	#camReference.enabled = true

#Duration isn't used for this?
#This should be changed anyways. DOT damage sounds like ass for constant health.
func increaseVirusLevel(_type : int, intensity : float, _duration = 2.0) -> void:
	virus_level += intensity
	if virus_level >= virus_max:
		#Have the viri spawn out of the player as well. Just choose random ones tbh, no need to store type
		_death()

func getPosition() -> Vector2:
	return position

func _death() -> void:
	pass

#For all events, collectables, abilities, and monsters to use
func set_energy(amount : float) -> void:
	energy += amount
	currencyUpdate.emit(amount, 0)

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

func getDamage() -> float:
	return damage
	
func getKnockback() -> float:
	return base_knockback 

func getID(idtype = 0) -> int:
	if idtype:	
		return 0
	else:
		return 0
