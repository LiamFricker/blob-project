extends CharacterBody2D


enum {
	IDLE,
	FLOAT,
	CHARGE,
	CHARGING, 
	JAVELIN,
	SHROOM
}
var camReference

var tween #basic all purpose tween for stretches 
var tween2 #tween for glimmer 
var tween3 #tween for ripple amp UNUSED USE IT FOR SOMETHING ELSE
var tween4 #idk

var current_map = -1

#Fat:
#Pos(-17, -35) Scale(1.063, 1.063)

func _animate()-> void:
	if tween:
		tween.kill()
	tween = create_tween()

var state = IDLE

@export var size: float = 1

var waddle = false
@export var waddle_speed = 1
var waddle_modfier = 1

@export var max_velocity: float = 100
@export var accel: float = 50
@export var turning_accel_ratio: float = 1.25
@export var friction: float = 0.25

#Charge Variables
var charge = true
@export var charge_cooldown: float = 1
var charge_cool: float = 0
@export var charge_max: float = 1
@export var charge_floor: float = 0.33
@export var charge_floor_speed: float = 0.33 #Such as maybe you'd want to set this to 0 below the floor.
var charge_time: float = 0
@export var charge_speed: float = 1
@export var charge_pull_speed: float = 0.65#Default:0.65
@export var charge_length: float = 0.5
var tempVelocity: Vector2 = Vector2.ZERO

var charge_angle: float = 0
@export var charge_angle_speed: float = 1

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
	camReference = get_node("Camera2D")

func _physics_process(delta: float) -> void:
	print(camReference.position)
	_waddleLogic(delta)
	
	if charge and charge_cool < 0:
		_chargeLogic(delta)
		
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
	
	velocity += tempVelocity	 	
	move_and_slide()
	velocity -= tempVelocity	 
	
	velocity *= pow(friction, delta)
	
	if charge_cool > 0 and abs(chargeTentacleSpin + reverseTentacleSpin) > 0:
		chargeTentacleSpin *= pow(0.1, delta)
		handleTentacleShader()
	
	_timers(delta)

func _waddleLogic(delta: float) -> void:
	var x_dir = int(Input.is_action_pressed("Right")) - int(Input.is_action_pressed("Left"))
	var y_dir = -1 * (int(Input.is_action_pressed("Up")) - int(Input.is_action_pressed("Down")))
	#print("Xdirection: ", x_dir)
	#print("Right: ", Input.is_action_pressed("Right"))
	#print(velocity.length()/100)
	#$Sprite/Node2D/Inside.material.set_shader_parameter("frequency", 2.5 + ceil(velocity.length())/100 * size)
	$Sprite/Node2D/Inside.material.set_shader_parameter("amplitude", 0.5 + ceil(velocity.length())/20 * size)
	if x_dir == sign(velocity.x) * -1:
		velocity.x += x_dir * accel * turning_accel_ratio * delta * waddle_speed * waddle_modfier
		#print(x_dir)
	else:
		velocity.x += x_dir * accel * delta * waddle_speed * waddle_modfier
	if y_dir == sign(velocity.y) * -1:
		velocity.y += y_dir * accel * turning_accel_ratio * delta * waddle_speed * waddle_modfier
	else:
		velocity.y += y_dir * accel * delta * waddle_speed * waddle_modfier

	

func _chargeLogic(delta: float) -> void:
	if Input.is_action_pressed("Charge"):
		if state != CHARGING and state != CHARGE:
			state = CHARGING
			#var tempDirection = Vector2(int(Input.is_action_pressed("Right")) - int(Input.is_action_pressed("Left")), int(Input.is_action_pressed("Up")) - int(Input.is_action_pressed("Down")))
			#charge_angle = tempDirection.angle()
			_animate()
			if $Sprite/Node2D.position.y != 0:
				resetCharge(true)
			$Pivot.modulate = Color(1,1,1,1)
			tween.tween_property($Pivot, "scale", Vector2(-2, 0.6), charge_max)
			tween.parallel().tween_property($Sprite/Node2D, "scale", Vector2(1, 0.25), charge_max)
			handleTentacleSqueeze()	
			waddle_modfier = 0.25
			
			
		elif charge_time < charge_max * 0.8:
			charge_time += delta
			var temp = (int(Input.is_action_pressed("Right")) - int(Input.is_action_pressed("Left"))) * delta * pow((charge_max / (charge_time + 0.2)), 1.6)
			chargeTentacleSpin *= pow(0.05, delta)
			chargeTentacleSpin += -2 *temp# if abs(chargeTentacleSpin) <= 1.0 else 0
			handleTentacleShader()
			charge_angle += charge_angle_speed * temp
			
			$Pivot.rotation = charge_angle
			$Sprite.rotation = charge_angle
		else:
			if charge_time < charge_max:	
				charge_time += delta
			elif state != CHARGE:
				if tween2:
					tween2.kill()
				tween2 = create_tween()
				 
				tween2.tween_property($Pivot/Node2D/Glimmer, "texture_offset", Vector2(24, 7), 0.4)
				tween2.parallel().tween_property($Pivot/Node2D/Polygon2D2, "color", Color(1, 1, 0), 0.2)
				tween2.tween_property($Pivot/Node2D/Polygon2D2, "color", Color(0.8, 0.8, 0.8), 0.2) 
				state = CHARGE
				charge_time = charge_max
			
			var temp = (int(Input.is_action_pressed("Right")) - int(Input.is_action_pressed("Left"))) * delta
			
			chargeTentacleSpin *= pow(0.1, delta)
			chargeTentacleSpin += -1.5*temp# if abs(chargeTentacleSpin) < 2.5 else 0
			handleTentacleShader()
			charge_angle += charge_angle_speed * temp
			
			$Pivot.rotation = charge_angle
			$Sprite.rotation = charge_angle
			
			
			
	elif Input.is_action_just_released("Charge"):
		charge_cool = charge_cooldown 
		state = IDLE
		waddle_modfier = 1
		_animate()
		tween.tween_property($Pivot, "scale", Vector2(1, 1.5), 0.1 * charge_cooldown)
		$Pivot/Node2D/Glimmer.texture_offset = Vector2(3, 25)
		$Pivot/Node2D/Polygon2D2.color = Color(0.8, 0.8, 0.8)
		
		var temp = ceil(10 * charge_floor/charge_max) * charge_length if charge_time < charge_floor else ceil(10 * charge_time/charge_max) * charge_length
		
		print("Temp ", temp / charge_length)
		tween.tween_property($Sprite/Node2D, "scale", Vector2(temp/20, 1 + 0.1 * temp), 0.08 * charge_cooldown)
		tween.parallel().tween_property($Sprite/Node2D, "position", Vector2(0, -3.6 * temp), 0.08 * charge_cooldown)
		tween.parallel().tween_property(self, "reverseTentacleSpin", 1.0, 0.08 * charge_cooldown)
		handleTentacleStretch(temp)
		#tween.parallel().tween_property($Sprite, "position", Vector2(9 - (9 * 0.4 * ceil(10 * charge_floor/charge_max) * sin(charge_angle)), 9 - (9 * 0.4 * ceil(10 * charge_floor/charge_max)) * cos(charge_angle)), 0.2 * charge_cooldown)
		tween.tween_callback(self.setTempVelocity.bind(temp))
		tween.tween_callback(self.activateRipple.bind(Vector2(0, -1), temp/10))
		tween.tween_property($Sprite/Node2D, "scale", Vector2(1, 1), 0.3 * charge_cooldown/charge_pull_speed)
		tween.parallel().tween_property(self, "reverseTentacleSpin", 0.0, 0.3 * charge_cooldown)
		tween.parallel().tween_property($Sprite/Node2D, "position", Vector2(0, 0), 0.3 * charge_cooldown /charge_pull_speed) #-4.8 * temp
		handleTentacleReturn()
		#tween.parallel().tween_property($CollisionShape2D, "position", temp * 4.8 * Vector2(cos(charge_angle - PI/2), sin(charge_angle - PI/2)), 0.3 * charge_cooldown/charge_pull_speed)
		#tween.parallel().tween_property($Camera2D, "position", temp * 4.8 * Vector2(cos(charge_angle - PI/2), sin(charge_angle - PI/2)), 0.45 * charge_cooldown/charge_pull_speed)
		#tween.parallel().tween_property($Pivot, "modulate", Color(1,1,1,0), 0.3 * charge_cooldown)
		
		tween.tween_callback(self.resetCharge.bind(false))#.bind(4.8*temp, charge_angle - PI/2))
		
		#tween.tween_property($Sprite/Node2D, "position", Vector2(0, 0), 0.001)
		#tween.parallel().tween_property($Pivot/Node2D, "position", Vector2(0, 0), 0.001)
		
		#tween.parallel().tween_property($Sprite, "position", Vector2(9, 9), 0.4 * charge_cooldown)
		
		if charge_time <= charge_max * charge_floor: 
			
			velocity.x += cos(charge_angle - PI/2) * charge_floor_speed * 100 * charge_speed
			velocity.y += sin(charge_angle - PI/2) * charge_floor_speed * 100 * charge_speed
		else:
			velocity.x += cos(charge_angle - PI/2) * charge_time * 50 * charge_speed
			velocity.y += sin(charge_angle - PI/2) * charge_time * 50 * charge_speed
		charge_time = 0

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
			tween.parallel().tween_property($Sprite/Tentacle0, "position", Vector2(4, -2), charge_max)
			
			tween.parallel().tween_property($Sprite/Tentacle2, "position", Vector2(4, 2), charge_max)
			tween.parallel().tween_property($Sprite/Tentacle3, "position", Vector2(2, 2), charge_max)
			tween.parallel().tween_property($Sprite/Tentacle4, "position", Vector2(0, 2), charge_max)
			tween.parallel().tween_property($Sprite/Tentacle5, "position", Vector2(-2, 2), charge_max)
			tween.parallel().tween_property($Sprite/Tentacle6, "position", Vector2(-4, 2), charge_max)
			
			tween.parallel().tween_property($Sprite/Tentacle8, "position", Vector2(-4, -2), charge_max)
			#tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(0, -3.6 * temp), 0.08 * charge_cooldown)		

func handleTentacleStretch(temp:float):
	match tentacleAmount:
		0:
			pass
		1:
			tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(0, -3.6 * temp), 0.08 * charge_cooldown)
		2:
			tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(0, -3.6 * temp), 0.08 * charge_cooldown)
		3:
			tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(0, -3.6 * temp), 0.08 * charge_cooldown)
			
			if tween3:
				tween3.kill()
			tween3 = create_tween()
			tween3.tween_property($Sprite/Tentacle1, "rotation", PI/2, 0.3 * charge_cooldown)
			tween3.parallel().tween_property($Sprite/Tentacle7, "rotation", -3*PI/2, 0.3 * charge_cooldown)
		4:
			tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(0, -3.6 * temp), 0.08 * charge_cooldown)	
		9:
			tween.parallel().tween_property($Sprite/Tentacle0, "position", Vector2(4, -4-3.6*temp), 0.08 * charge_cooldown)
			tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(6, -3.6*temp), 0.08 * charge_cooldown)
			tween.parallel().tween_property($Sprite/Tentacle2, "position", Vector2(4, 4-3.6*temp), 0.08 * charge_cooldown)
			tween.parallel().tween_property($Sprite/Tentacle3, "position", Vector2(2, 6-3.6*temp), 0.08 * charge_cooldown)
			tween.parallel().tween_property($Sprite/Tentacle4, "position", Vector2(0, 8-3.6*temp), 0.08 * charge_cooldown)
			tween.parallel().tween_property($Sprite/Tentacle5, "position", Vector2(-2, 6-3.6*temp), 0.08 * charge_cooldown)
			tween.parallel().tween_property($Sprite/Tentacle6, "position", Vector2(-4, 4-3.6*temp), 0.08 * charge_cooldown)
			tween.parallel().tween_property($Sprite/Tentacle7, "position", Vector2(-6, -3.6*temp), 0.08 * charge_cooldown)
			tween.parallel().tween_property($Sprite/Tentacle8, "position", Vector2(-4, -4-3.6*temp), 0.08 * charge_cooldown)
			
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
			tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(8, 0), 0.3 * charge_cooldown)
		3:
			tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(8, 0), 0.3 * charge_cooldown)
			tween3.tween_property($Sprite/Tentacle1, "rotation", 0, 0.6 * charge_cooldown)
			tween3.parallel().tween_property($Sprite/Tentacle7, "rotation", PI, 0.6 * charge_cooldown)
		9:
			tween.parallel().tween_property($Sprite/Tentacle0, "position", Vector2(4, -4), 0.3 * charge_cooldown)
			tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(8, 0), 0.3 * charge_cooldown)
			tween.parallel().tween_property($Sprite/Tentacle2, "position", Vector2(4, 4), 0.3 * charge_cooldown)
			tween.parallel().tween_property($Sprite/Tentacle3, "position", Vector2(2, 6), 0.3 * charge_cooldown)
			tween.parallel().tween_property($Sprite/Tentacle4, "position", Vector2(0, 8), 0.3 * charge_cooldown)
			tween.parallel().tween_property($Sprite/Tentacle5, "position", Vector2(-2, 6), 0.3 * charge_cooldown)
			tween.parallel().tween_property($Sprite/Tentacle6, "position", Vector2(-4, 4), 0.3 * charge_cooldown)
			tween.parallel().tween_property($Sprite/Tentacle7, "position", Vector2(-8, 0), 0.3 * charge_cooldown)
			tween.parallel().tween_property($Sprite/Tentacle8, "position", Vector2(-4, -4), 0.3 * charge_cooldown)
			
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
	if charge_cool >= 0:
		charge_cool -= delta
		#if waddle_modfier < 1 and charge_cool <= charge_cooldown * 0.75:
		#	waddle_modfier = 1

func collect(_value : int, orbpos : Vector2) -> void:
	#Need a variable that tracks ripples
	#Need 3 variables that track ripple amps.
	#Need a function that's called when ripple amp reaches 0
	#Might be easier to do this with tweens than with process to be honest.
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
	
	changeCamera()
	
	position = newpos + (modPos-dims/2)  	
	
	
	#call_deferred("changeCamera")
	#return position

func changeCameraSpeed(toggle : bool, updateTime : float) -> void:
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
	
	var zoom = 2
	
	#var camera_offset = camReference.get_screen_center_position()-camReference.get_target_position()
	
	#print("CAMERA POS: ", camReference.get_screen_center_position(), " ", camReference.get_target_position())
	#camReference.position = camera_offset/zoom
	#print("CAMERA OFFSET: ", camera_offset)
	camReference.position_smoothing_enabled = false
	
	if tween4:
		tween4.kill()
	tween4 = create_tween()
	tween4.tween_property(camReference, "position_smoothing_enabled", true, 0.01)
	#tween4.parallel().tween_property(camReference, "position", Vector2(0,0), 2).from(camera_offset/zoom)
	
