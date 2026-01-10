extends Node2D

class_name base_creature

@onready var Sprite = $InnerNode/Sprite
@onready var Inner = $InnerNode
@onready var attach = $Attachments

var children_list = []
@export var health_max: float = 0
@onready var health : float = health_max 
var ID: int = 0
@export var size: float = 0
var isHazard : bool = false

var zoneReference : Node2D
@export var hitboxReference : Area2D
@export var hurtboxReference : Area2D
@export var spawnerRef : Node2D

@export var spawnerID: int = -1

#State:
enum{
	IDLE, FIGHT, FLEE, FEAST, DEAD, DISABLE
} 
#1: IDLE
#2: FIGHT
#3: FLEE
#4: FEAST
#5: DEAD
var state: int = IDLE
var roaming: bool = false
var ParentULBound: Vector2
var ParentDRBound: Vector2
var RoamingULBound: Vector2
var RoamingDRBound: Vector2
var homepos : Vector2

var movement_tween 
var oscillate_tween
var dot_tween

#dot (poison)
var dot_remaining
var dot_pow
enum{
	NONE, VIRUS
} 
var dot_type = NONE


#knockback info
var startPosition: Vector2
var power : float = 0
var weight : float = 1
var kb_moving = false

var superArmor = false


func reset() -> void:
	state = IDLE
	#This shouldn't happen since the creature should be at a base state
	#for c in children_list:
	#	c.enable()
	visible = true
	toggleHitbox(true)
	toggleHurtbox(true)
	set_process(true)
	position = homepos
	health = health_max

func disable() -> void:
	state = DISABLE
	#Children should be ideally removed or deleted when parent is disabled
	for c in children_list:
		c.disable()
	visible = false
	toggleHitbox(false)
	toggleHurtbox(false)
	set_process(false)

func removeChild(childRef : Node2D) -> void:
	var temppos = children_list.find(childRef)
	if temppos == -1:
		print("CHILD NOT FOUND CHANGE THIS FUNC")
	else:
		children_list.remove_at(temppos)

func knockback(direction: Vector2, strength : int) -> void:
	var tempPower = power
	power = strength / weight
	if power <= 0.5 or superArmor:
		if oscillate_tween:
			oscillate_tween.kill()
		oscillate_tween = create_tween()
		oscillate_tween.tween_property(Sprite, "position", direction * power * 0.75, power / 4)
		oscillate_tween.tween_property(Sprite, "position", direction * power * -0.5, power / 2)
		oscillate_tween.tween_property(Sprite, "position", direction * power * 0.25, power / 2)
		oscillate_tween.tween_property(Sprite, "position", 0, power / 4)
	else:
		if kb_moving:
			if movement_tween:
				movement_tween.kill()
			movement_tween = create_tween()
			movement_tween.set_ease(Tween.EASE_OUT)
			movement_tween.set_trans(Tween.TRANS_QUART)
			var oldDirection = (getPosition() - startPosition)
			var oldLen = oldDirection.length()
			var oldPower = 1 - (oldLen / tempPower)
			if oldPower < 0:
				print("OLDpower NEGATIVE FORMULA WRONG")
			oldDirection = oldDirection / oldLen
			startPosition = getPosition()
			movement_tween.tween_property(Inner, "position", startPosition + direction * power + oldDirection * oldPower, power / 2)
			movement_tween.parallel(self, "rotation", 2 * PI * floor(power + oldPower), power / 2)
			movement_tween.tween_callback(_knockbackEnd)
		else:
			if movement_tween:
				movement_tween.kill()
			movement_tween = create_tween()
			movement_tween.set_ease(Tween.EASE_OUT)
			movement_tween.set_trans(Tween.TRANS_QUART)
			kb_moving = true
			startPosition = getPosition()
			
			movement_tween.tween_property(Inner, "position", startPosition + direction * power, power / 2)
			movement_tween.parallel(self, "rotation", 2 * PI * floor(power), power / 2)
			movement_tween.tween_callback(_knockbackEnd)

func _knockbackEnd() -> void:
	kb_moving = false
	if state == IDLE and $IdleTimer.is_stopped():
		idle()

#Use this to get the position for the creature
func getPosition() -> Vector2:
	return position + Inner.position

#Override this if needs be (such as multiple hitboxes)
func toggleHitbox(toggle : bool) -> void:
	if hitboxReference:
		hitboxReference.set_deferred("monitoring", toggle)
		hitboxReference.set_deferred("monitorable", toggle)
	
#Override this if needs be (such as multiple hurtboxes)
func toggleHurtbox(toggle : bool) -> void:
	if hurtboxReference:
		hurtboxReference.set_deferred("monitoring", toggle)
		hitboxReference.set_deferred("monitorable", toggle)

func idle() -> void:
	if not kb_moving:
		if movement_tween:
			movement_tween.kill()
		movement_tween = create_tween()
		movement_tween.tween_property(Inner, "position", Vector2.ZERO, 4)
		movement_tween.tween_callback($IdleTimer.start)

func _on_idle_timer_timeout() -> void:
	if state == IDLE:
		idle()


func addPosition(addpos : Vector2) -> void:#, dims : Vector2) -> void:
	#You can make this slightly more efficient if you make this calculation 
	#On the top level where it's called instead of down here where it has to be ran
	#multiple times.
	#Wow I guess me from fucking 2 weeks ago already fixed that problem but I'm too 
	#fucking stupid to realize it.
	#Anyways, you can make it slightly more efficient if you calculate it in the top function
	#Since multiple zones change at once, but that's really minimal gains.
	
	position += addpos  
	for c in children_list:
		c.addPosition(addpos)

func _OnDeath() -> void:
	print("DEATH: ", self)
	state = DEAD
	for c in children_list:
		c.orphan()
	visible = false
	toggleHitbox(false)
	toggleHurtbox(false)
	set_process(false)

func increaseVirusLevel(type : int, intensity : float, duration = 2.0) -> void: #ID : int, 
	var dotLeft = 0
	dot_type = VIRUS
	if dot_tween:
		dot_tween.kill()
		if dot_remaining == -1:
			dotLeft = dot_remaining * dot_pow
	dot_tween = create_tween()
	dot_tween.tween_method(_dot_tick.bind(type), 0, int(dotLeft + intensity*duration), duration) #ID, 
	dot_tween.tween_callback(_dot_end.bind(false, type))
	dot_pow = intensity
	dot_remaining = 0

func _dot_tick(dot_speed : int, type : int) -> void:
	health -= (dot_speed - dot_remaining)
	dot_remaining = dot_speed
	if health <= 0:
		if dot_tween:
			dot_tween.kill()
		_dot_end(true, type)	#ID, 

func _dot_end(death : bool, type : int) -> void: #ID : int, 
	dot_remaining = -1
	if death:
		if dot_type == VIRUS:
			#Add Code to make it explode
			#Need to free attachment as well
			print("EXPLOOODODDDDEEEEE")
			var vCount = 1 + ceil(log(size+1))
			var angle = 2 * PI / vCount
			var vRNG = RandomNumberGenerator.new()
			for v in range(vCount):
				var tempC = spawnerRef.spawnEntity(type, -1, position)
				#zoneReference.addCreature(tempC)
				get_parent().add_child(tempC)
				tempC.explode(size, v * angle + angle * vRNG.randf_range(-0.5, 0.5), getPosition())
		_OnDeath()		
		
func _on_roam_timer_timeout():
	var roamTemp = $RoamTimer
	if not kb_moving: 
		print("CHANGE")
		position += Inner.position
		Inner.position = 0 
	 
	if roaming:
		if position > RoamingULBound or position < RoamingDRBound:
			var supplyState = 1
			if position <= ParentDRBound or position >= ParentULBound:
				roaming = false
				supplyState = 2
			
			#In this case, call the zoneref and supply (id and new position and supplyState)
			#since supplyState is 1/2:
			#Zone then removes this creature from its guest creatures list and 
			#emits a signal containing the creature_list[id] as well as new postion and supplyState
			#Cell then catches that signal (needs to connect to it on creation)
			#If supply state is 1
			#It then finds the new zone, and adds this creature to its guest list (just an append)
			#Finally, it fills in RoamingULBound/RoamingDRBound in this creature
			#with the bounds of the new zone
			#Otherwise, if supply state is 2 
			#it finds the new zone, and removes this creature from its roaming creatures
			#it then sets zoneReference back to the parent zone
			
			#Ideally also needs to also check what state Zone is in.
			#Let's just make the game so that enemies never get knockbacked far enough into zones that
			#aren't active. If they are, just disable roam timer and kill them when they're off screen.
			zoneReference.handleRoamer(supplyState, position, ID)
			roamTemp.wait_time = 10
			roamTemp.start()
		else:
			roamTemp.wait_time = 5
			roamTemp.start()
	else:
		if position > ParentDRBound or position < ParentULBound:
			roaming = true
			
			#Need to call the Zone parent and supply (id and new position as well as 0)
			#since supplystate is 0
			#Zone then adds this creature to its roaming creatures list and 
			#emits a signal containing the creature_list[id] as well as new postion and 0
			#Cell then catches that signal (needs to connect to it on creation)
			#It then finds the new zone, and adds this creature to its guest list (just an append)
			#Finally, it fills in RoamingULBound/RoamingDRBound in this creature
			#with the bounds of the new zone. Also resets zoneReference
			zoneReference.handleRoamer(0, position, ID)
			roamTemp.wait_time = 10
			roamTemp.start()
		else:
			roamTemp.wait_time = 5
			roamTemp.start()
			
	
