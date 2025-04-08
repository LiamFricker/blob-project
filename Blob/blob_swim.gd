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

var charge_angle: float = 0
@export var charge_angle_speed: float = 1

#Ripple Vars
var rippleOn = false
var rippleAmp = 0
var oscilator = 0
var rippleTime = 0
var rippleMax = 0

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
		 	
	move_and_slide()
	
	velocity *= pow(friction, delta)
	
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
				resetCharge(-$Sprite/Node2D.position.y, charge_angle-PI/2)
			$Pivot.modulate = Color(1,1,1,1)
			tween.tween_property($Pivot, "scale", Vector2(-2, 0.6), charge_max)
			tween.parallel().tween_property($Sprite/Node2D, "scale", Vector2(1, 0.25), charge_max)
			waddle_modfier = 0.25
			
			
		elif charge_time < charge_max * 0.8:
			charge_time += delta
			charge_angle += charge_angle_speed * (int(Input.is_action_pressed("Right")) - int(Input.is_action_pressed("Left"))) * delta * pow((charge_max / (charge_time + 0.2)), 1.6)
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
			charge_angle += charge_angle_speed * (int(Input.is_action_pressed("Right")) - int(Input.is_action_pressed("Left"))) * delta
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
		#tween.parallel().tween_property($Sprite, "position", Vector2(9 - (9 * 0.4 * ceil(10 * charge_floor/charge_max) * sin(charge_angle)), 9 - (9 * 0.4 * ceil(10 * charge_floor/charge_max)) * cos(charge_angle)), 0.2 * charge_cooldown)
		
		tween.tween_property($Sprite/Node2D, "scale", Vector2(1, 1), 0.3 * charge_cooldown/charge_pull_speed)
		tween.parallel().tween_property($Sprite/Node2D, "position", Vector2(0, -4.8 * temp), 0.3 * charge_cooldown /charge_pull_speed)
		tween.parallel().tween_property($CollisionShape2D, "position", temp * 4.8 * Vector2(cos(charge_angle - PI/2), sin(charge_angle - PI/2)), 0.3 * charge_cooldown/charge_pull_speed)
		tween.parallel().tween_property($Pivot, "modulate", Color(1,1,1,0), 0.3 * charge_cooldown)
		
		tween.tween_callback(self.resetCharge.bind(4.8*temp, charge_angle - PI/2))
		
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
		
func resetCharge(distance:float, angle:float) -> void:
	position += Vector2(cos(angle), sin(angle))*distance
	$CollisionShape2D.position = Vector2(0,0)
	$Sprite/Node2D.position = Vector2(0,0)

	
	
#Run all the times here that you can about the values for.
func _timers(delta:float) -> void:
	if charge_cool >= 0:
		charge_cool -= delta
		#if waddle_modfier < 1 and charge_cool <= charge_cooldown * 0.75:
		#	waddle_modfier = 1
