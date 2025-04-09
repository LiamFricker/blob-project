extends CharacterBody2D


enum {
	IDLE,
	FLOAT,
	CHARGE,
	CHARGING, 
	JAVELIN,
	SHROOM
}

var tween #basic all purpose tween for stretches 
var tween2 #tween for glimmer 
var tween3 #tween for ripple amp UNUSED USE IT FOR SOMETHING ELSE

#Fat:
#Pos(-17, -35) Scale(1.063, 1.063)

func _animate()-> void:
	if tween:
		tween.kill()
	tween = create_tween()

var state = IDLE

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

#Ripple Vars
var rippleOn = false
var rippleAmp = 0
var oscilator = 0
var rippleTime = 0
var rippleMax = 0

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
@export var tentacleAmount:int = 1
@export var tentacleLength:int = 8
@export var tentacleAlphaAmount:int = 0 
var chargeTentacleSpin:float = 0 #very misleading name, basically how much Right/Left while charging affects the tentacles

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Special"):
		position = Vector2.ZERO
		velocity = Vector2.ZERO
		#activateRipple(Vector2(-0.707, -0.707), 2.5)

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

func _physics_process(delta: float) -> void:

	_waddleLogic(delta)
	
	if charge and charge_cool < 0:
		_chargeLogic(delta)
		
	if rippleOn:
		oscilator += delta * 1.25
		var rippleAmpCurrent = sin(rippleAmp * oscilator)/oscilator
		$Sprite/Node2D/Inside.material.set_shader_parameter("rippleAmp", rippleAmpCurrent)
		if oscilator > rippleAmp * 7:
			rippleOn = false
			$Sprite/Node2D/Inside.material.set_shader_parameter("rippleAmp", 0)
		elif oscilator > rippleTime:
			rippleMax *= -0.6
			$Sprite/Node2D/Inside.material.set_shader_parameter("rippleAmpMax", rippleMax)
			rippleTime += 1.2
	
	velocity += tempVelocity	 	
	move_and_slide()
	velocity -= tempVelocity	 
	
	velocity *= pow(friction, delta)
	
	if charge_cool / charge_cooldown >= 0.5:
		$Sprite/Tentacle1/Line2D.material.set_shader_parameter("direction", chargeTentacleSpin)
	
	_timers(delta)

func _waddleLogic(delta: float) -> void:
	var x_dir = int(Input.is_action_pressed("Right")) - int(Input.is_action_pressed("Left"))
	var y_dir = -1 * (int(Input.is_action_pressed("Up")) - int(Input.is_action_pressed("Down")))
	#print("Xdirection: ", x_dir)
	#print("Right: ", Input.is_action_pressed("Right"))
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
				resetCharge()
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
			$Sprite/Tentacle1/Line2D.material.set_shader_parameter("direction", chargeTentacleSpin)
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
				tween2.parallel().tween_property($Pivot/Node2D/Glimmer, "texture_offset", Vector2(24, 7), 0.4) 
				print("true")
				state = CHARGE
				charge_time = charge_max
			
			var temp = (int(Input.is_action_pressed("Right")) - int(Input.is_action_pressed("Left"))) * delta
			
			chargeTentacleSpin *= pow(0.1, delta)
			chargeTentacleSpin += -1.5*temp# if abs(chargeTentacleSpin) < 2.5 else 0
			$Sprite/Tentacle1/Line2D.material.set_shader_parameter("direction", chargeTentacleSpin)
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
		
		var temp = ceil(10 * charge_floor/charge_max) * charge_length if charge_time < charge_floor else ceil(10 * charge_time/charge_max) * charge_length
		
		print("Temp ", temp / charge_length)
		tween.tween_property($Sprite/Node2D, "scale", Vector2(temp/20, 1 + 0.1 * temp), 0.08 * charge_cooldown)
		tween.parallel().tween_property($Sprite/Node2D, "position", Vector2(0, -3.6 * temp), 0.08 * charge_cooldown)
		tween.parallel().tween_property(self, "chargeTentacleSpin", 0, 0.08 * charge_cooldown)
		handleTentacleStretch(temp)
		#tween.parallel().tween_property($Sprite, "position", Vector2(9 - (9 * 0.4 * ceil(10 * charge_floor/charge_max) * sin(charge_angle)), 9 - (9 * 0.4 * ceil(10 * charge_floor/charge_max)) * cos(charge_angle)), 0.2 * charge_cooldown)
		tween.tween_callback(self.setTempVelocity.bind(temp))
		
		tween.tween_property($Sprite/Node2D, "scale", Vector2(1, 1), 0.3 * charge_cooldown/charge_pull_speed)
		
		tween.parallel().tween_property($Sprite/Node2D, "position", Vector2(0, 0), 0.3 * charge_cooldown /charge_pull_speed) #-4.8 * temp
		handleTentacleReturn()
		#tween.parallel().tween_property($CollisionShape2D, "position", temp * 4.8 * Vector2(cos(charge_angle - PI/2), sin(charge_angle - PI/2)), 0.3 * charge_cooldown/charge_pull_speed)
		#tween.parallel().tween_property($Camera2D, "position", temp * 4.8 * Vector2(cos(charge_angle - PI/2), sin(charge_angle - PI/2)), 0.45 * charge_cooldown/charge_pull_speed)
		#tween.parallel().tween_property($Pivot, "modulate", Color(1,1,1,0), 0.3 * charge_cooldown)
		
		tween.tween_callback(self.resetCharge)#.bind(4.8*temp, charge_angle - PI/2))
		
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
	tempVelocity = temp * 4.8 * Vector2(cos(charge_angle - PI/2), sin(charge_angle - PI/2))# * (0.3 * charge_cooldown /charge_pull_speed)
		
func resetCharge() -> void:#distance:float, angle:float) -> void:
	#position += Vector2(cos(angle), sin(angle))*distance
	tempVelocity = Vector2.ZERO
	#$CollisionShape2D.position = Vector2(0,0)
	$Sprite/Node2D.position = Vector2(0,0)
	$Sprite/Tentacle1.position = Vector2(8,0)
	#$Camera2D.position = Vector2(0,0)

func handleTentacleSqueeze():
	match tentacleAmount:
		0:
			pass
		1:
			pass
			#tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(0, -3.6 * temp), 0.08 * charge_cooldown)		

func handleTentacleStretch(temp:float):
	match tentacleAmount:
		0:
			pass
		1:
			tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(0, -3.6 * temp), 0.08 * charge_cooldown)	
			
func handleTentacleReturn():
	match tentacleAmount:
		0:
			pass
		1:
			tween.parallel().tween_property($Sprite/Tentacle1, "position", Vector2(8, 0), 0.3 * charge_cooldown)
	#Cool useless line of code
	#for i in range(tentacleAmount):	
	#	tween.parallel().tween_property(get_node("Sprite/Tentacle"+str(i+1)), "position", Vector2(8, 0), 0.3 * charge_cooldown)
	
#Run all the times here that you can about the values for.
func _timers(delta:float) -> void:
	if charge_cool >= 0:
		charge_cool -= delta
		#if waddle_modfier < 1 and charge_cool <= charge_cooldown * 0.75:
		#	waddle_modfier = 1
