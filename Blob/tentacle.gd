extends Node2D

@export var parentRef : Node2D
@export var tentacle_number: int = 0 
#Like a clock starting from 1, 0. Since we don't add that many tentacles and it doesn't happen a lot,
#We should reset them each time to their proper spots. 
#Set Amplitude to 1 when you're ready to use it. Just make it not visible else.
#Handle all the interactions with signals and stuff. Tentacles will need to be able to attack and
#maybe pick up stuff.
#Add the whip and attack. Maybe also the grab though that can be later idk

var tween

#Whip Vars
var whipping:bool = false 
var whipAmp:float = 0.0
var whipSpeed:float = 1.0
var whipBaseLen: float = 2.0

#State Vars
@export var search_len : float = 1.5
@export var search_speed = 1.0
var searching:bool = false
var retracted : bool = false
var queue_retract : bool = false
@export var retract_cd_speed : float = 1.0

@onready var pivot_ref = $Pivot
@onready var line_ref = $Pivot/Sprite/Line2D 
@onready var sprite_ref = $Pivot/Sprite
@onready var detect_ref = $Detection
@onready var hitbox_ref = $Pivot/Hitbox
@onready var collect_ref = $Pivot/CollectionBox
signal damagedEnemy(amt : float)

func _damagedEnemy(amt : float) -> void:
	damagedEnemy.emit(amt)


#signal orb_collection(value, orbpos, enemy_drop, currency_type)

"""
Tentacle Amounts:
0:
1: down
2: at bottom corners
3: at l/r/b
4: at l/r bottom mids
5: at l/r/b bottom corners
6: 5 with 1 top corner right
7: 5 with top corners
8: 7 without b but bottom mids
9: 7 with bottom mids
"""

var busyState = false #If charging or performing an action 

func getID() -> int:
	return parentRef.getID()
	


#These variables all go into the Area2D collision. 
func getParent() -> Node2D:
	return parentRef

func collect(value : int, orbpos : Vector2, enemy_drop : bool, currency_type = 0) -> void:
	if searching and not whipping:
		if tween:
			tween.kill()
		tween = create_tween()
		var search_time = 0.6 / search_speed
		tween.tween_property(pivot_ref, "rotation", 0, search_time)
		tween.parallel().tween_property(sprite_ref, "scale:x", 1.0, search_time)
		tween.finished.connect(_endSearch)
	#orb_collection.emit(value, orbpos, enemy_drop, currency_type)
	parentRef.collect(value, orbpos, enemy_drop, currency_type)

#Change this to the position of the tip.
#Or the movement object
func getPosition() -> Vector2:
	return position + parentRef.getPosition() + 32*Vector2.from_angle(rotation)


func enable() -> void:
	set_deferred("process_mode", PROCESS_MODE_INHERIT)
	show()
	

func disable() -> void:
	set_deferred("process_mode", PROCESS_MODE_DISABLED)
	hide()

func setDirection(newDir : float) -> void:
	line_ref.material.set_shader_parameter("direction", newDir)

func reset() -> void:
	if process_mode != PROCESS_MODE_DISABLED:
		match tentacle_number:
			0:
				position = Vector2(4,-4)
			1:
				position = Vector2(8,0)
			2:
				position = Vector2(4,4)
			3:
				position = Vector2(2,6)
			4:
				position = Vector2(0,8)
			5:
				position = Vector2(-2,6)
			6:
				position = Vector2(-4,4)
			7:
				position = Vector2(-8,0)
			8:
				position = Vector2(-4,-4)

func setTentacleNum(newNum : int) -> void:
	tentacle_number = newNum

func _process(_delta:float) -> void:
	if whipping:
		line_ref.material.set_shader_parameter("whip_direction", whipAmp)  

func retract() -> void:
	if not retracted:
		if whipping:
			queue_retract = true
		else:
			toggleBoxes(false)
			retracted = true
			queue_retract = false
			var retract_dur = 10.0 / retract_cd_speed
			if tween:
				tween.kill()
			tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(sprite_ref, "scale", Vector2(0.1, 1.0), 0.25)
			if searching:
				
				searching = false
			tween.parallel().tween_property(pivot_ref, "rotation", 0, 0.25)
			tween.tween_property(sprite_ref, "scale", Vector2(1.0, 1.0), 0.25).set_delay(retract_dur)
			
			tween.finished.connect(_retractEnd)
	
func _retractEnd() -> void:
	toggleBoxes(true)
	retracted = false

func toggleBoxes(toggle : bool) -> void:
	detect_ref.set_deferred("monitoring", toggle)
	hitbox_ref.set_deferred("monitorable", toggle)
	hitbox_ref.set_deferred("monitoring", toggle)
	collect_ref.set_deferred("monitorable", toggle)

func changeSearchLength(newLen : float) -> void:
	search_len = newLen
	var newRad = 30.0 * newLen
	
	var tempShape = RectangleShape2D.new()
	tempShape.size = Vector2(16.0, 60.0 * newLen)
	$Pivot/CollectionBox/CollisionShape2D3.set_deferred("shape", tempShape)
	$Pivot/CollectionBox/CollisionShape2D3.set_deferred("position", Vector2(newRad - 1, 0))
	
	var tempCirc = CircleShape2D.new()
	tempCirc.radius = newRad - 5.0
	$Detection/CollisionShape2D.set_deferred("shape", tempCirc)
	$Pivot/CollectionBox/CollisionShape2D3.set_deferred("position:x", Vector2(newRad, 0))

func toggleSearch(toggle) -> void:
	$Detection/CollisionShape2D.set_deferred("disabled", not toggle)
	if not toggle and searching:
		_endSearch()

func _on_detection_area_entered(area: Area2D) -> void:
	detect_ref.set_deferred("monitoring", false)
	$Pivot/CollectionBox/CollisionShape2D.set_deferred("disabled", true)
	$Pivot/CollectionBox/CollisionShape2D3.set_deferred("disabled", false)
	
	#This is kinda annoying to configure and there's lots of stuff so let's just do it this way
	var c:float = getPosition().angle_to_point(area.getPosition()) 
	var c_diff = angle_difference(c, rotation + pivot_ref.rotation)
	if tween:
		tween.kill()
	tween = create_tween()
	#$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	#$Hitbox/CollisionShape2D2.set_deferred("disabled", false)
	searching = true
	var search_time = 1.25 / search_speed
	#print(getPosition())
	#print(area.getPosition())
	#print("tent num", tentacle_number, " ", rad_to_deg(c))
	if c_diff >= 0:
		tween.tween_property(pivot_ref, "rotation", -PI/3, search_time)
	else:
		tween.tween_property(pivot_ref, "rotation", PI/3, search_time)
	tween.parallel().tween_property(sprite_ref, "scale:x", search_len, search_time)
	tween.tween_property(pivot_ref, "rotation", 0, search_time)
	tween.parallel().tween_property(sprite_ref, "scale:x", 1.0, search_time)
	tween.finished.connect(_endSearch)

func _on_hitbox_area_entered(_area: Area2D) -> void:
	retract()

func _endSearch() -> void:
	detect_ref.set_deferred("monitoring", true)
	$Pivot/CollectionBox/CollisionShape2D.set_deferred("disabled", false)
	$Pivot/CollectionBox/CollisionShape2D3.set_deferred("disabled", true)
	searching = false
	
func whip(reverse = 1) -> void:
	if not retracted and not whipping:
		if tween:
			tween.kill()
		tween = create_tween()
		whipping = true
		
		var whipTime = 0.1/whipSpeed
		
		tween.tween_property(self, "whipAmp", reverse*1.0, 8.0 * whipTime)
		if searching:
			#tween.parallel().tween_property(pivot_ref, "rotation", 0, 0.25)
			tween.parallel().tween_property(sprite_ref, "scale:x", 1.0, 8.0 * whipTime)
		else:
			detect_ref.set_deferred("monitoring", false)
		tween.parallel().tween_property(pivot_ref, "rotation", PI/16 *reverse, 8.0 * whipTime)
		
		tween.tween_property(self, "whipAmp", reverse*1.05, whipTime)
		tween.tween_property(self, "whipAmp", reverse*0.95, whipTime)
		tween.tween_property(self, "whipAmp", reverse*1.05, whipTime)
		tween.tween_property(self, "whipAmp", reverse*0.95, whipTime)
		tween.tween_property(self, "whipAmp", 0, 2.0 * whipTime)
		tween.finished.connect(reverseWhip.bind(reverse))

func reverseWhip(reverse:int) -> void:
	line_ref.material.set_shader_parameter("reverse_direction", true)  
	$Pivot/Hitbox/CollisionShape2D.set_deferred("disabled", true)
	$Pivot/CollectionBox/CollisionShape2D.set_deferred("disabled", true)
	$Pivot/Hitbox/CollisionShape2D2.set_deferred("disabled", false)
	$Pivot/CollectionBox/CollisionShape2D2.set_deferred("disabled", false)
	updateWhipBoxes(whipBaseLen)
	
	var whipTime = 0.2/whipSpeed
	
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "whipAmp", reverse*1.0, whipTime)
	tween.parallel().tween_property(sprite_ref, "scale", Vector2(2, 1), whipTime)
	tween.parallel().tween_property(pivot_ref, "rotation", -PI/1.5 *reverse, whipTime)
	tween.tween_property(self, "whipAmp", 0.0, 7.5 * whipTime)
	tween.parallel().tween_property(sprite_ref, "scale", Vector2(1, 1), 7.5 * whipTime)
	tween.parallel().tween_property(pivot_ref, "rotation", 0, 7.5 * whipTime)
	tween.finished.connect(endWhip)

func endWhip() -> void:
	line_ref.material.set_shader_parameter("reverse_direction", false)  
	whipping = false
	$Pivot/Hitbox/CollisionShape2D.set_deferred("disabled", false)
	$Pivot/CollectionBox/CollisionShape2D.set_deferred("disabled", false)
	$Pivot/Hitbox/CollisionShape2D2.set_deferred("disabled", true)
	$Pivot/CollectionBox/CollisionShape2D2.set_deferred("disabled", true)
	
	
	if searching:
		detect_ref.set_deferred("monitoring", true)
		searching = false
	
	if queue_retract:
		retract()

func tentConfig() -> void:
	#$Node2D/Line2D.material.set_shader_parameter("amplitude", 1.0)
	match tentacle_number:
		0:
			position = Vector2(4, -4)
			rotation = -PI/4
		1:
			position = Vector2(8, 0)
			rotation = 0
		2:
			position = Vector2(4, 4)
			rotation = PI/4
		3:
			position = Vector2(2, 6)
			rotation = 3*PI/8
		4:
			position = Vector2(0, 8)
			rotation = PI/2
		5:
			position = Vector2(-2, 6)
			rotation = 5*PI/8
		6:
			position = Vector2(-4, 4)
			rotation = 3*PI/4
		7:
			position = Vector2(-8, 0)
			rotation = PI
		8:
			position = Vector2(-4, -4)
			rotation = 5*PI/4
		
func chargeWhip(temp : float, charge_cd : float) -> void:
	if not retracted and not whipping:
		whipping = true
		
		var whipLen = max(2.0 * temp/5.0, 1.5) 
		updateWhipBoxes(whipLen)
		
		$Pivot/Hitbox/CollisionShape2D.set_deferred("disabled", true)
		$Pivot/CollectionBox/CollisionShape2D.set_deferred("disabled", true)
		$Pivot/Hitbox/CollisionShape2D2.set_deferred("disabled", false)
		$Pivot/CollectionBox/CollisionShape2D2.set_deferred("disabled", false)
		
		var retPos : float = min(0.3 * charge_cd, 0.4)
		
		if tween:
			tween.kill()
		tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(sprite_ref, "scale:x", whipLen, retPos).set_delay(retPos * 0.25)
		tween.parallel().tween_property(pivot_ref, "rotation", 0, retPos)
		tween.tween_property(sprite_ref, "scale:x", 1.0, retPos*2)
		tween.finished.connect(endWhip)

func updateWhipBoxes(whipLen : float) -> void:
	var newPos = Vector2(30 * whipLen - 1, 0)
	
	var tempShape = RectangleShape2D.new()
	tempShape.size = Vector2(16.0, 60.0 * whipLen)
	$Pivot/CollectionBox/CollisionShape2D2.set_deferred("shape", tempShape)
	$Pivot/CollectionBox/CollisionShape2D2.set_deferred("position", newPos)
	$Pivot/Hitbox/CollisionShape2D2.set_deferred("shape", tempShape)
	$Pivot/Hitbox/CollisionShape2D2.set_deferred("position", newPos)
