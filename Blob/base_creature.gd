extends Node2D

class_name base_creature

var children_list = []
@export var health_max: float = 0
var health : float 
var ID: int = 0

var zoneReference
@export var hitboxReference : Area2D
@export var hurtboxReference : Area2D

#State: 
#1:
#2: dead
var state: int = 0
var roaming: bool = false
var ParentULBound: Vector2
var ParentDRBound: Vector2
var RoamingULBound: Vector2
var RoamingDRBound: Vector2
var homepos : Vector2

func reset() -> void:
	state = 0
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
	state = 1
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

#Override this if needs be (such as multiple hitboxes)
func toggleHitbox(toggle : bool) -> void:
	hitboxReference.monitoring = toggle
	
#Override this if needs be (such as multiple hurtboxes)
func toggleHurtbox(toggle : bool) -> void:
	hurtboxReference.monitoring = toggle

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
	state = 2
	for c in children_list:
		c.orphan()
	visible = false
	toggleHitbox(false)
	toggleHurtbox(false)
	set_process(false)
		
func _on_roam_timer_timeout():
	var roamTemp = $RoamTimer
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
			
	
