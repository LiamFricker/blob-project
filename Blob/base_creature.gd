extends Node2D

class_name base_creature

signal spawnOrbs(amt : int, pos : Vector2)

@onready var Sprite = $InnerNode/Sprite
@onready var Inner = $InnerNode
@onready var attach = $InnerNode/Sprite/Attachments

@export var orb_reward = 0

var isChild : bool = false
var parentRef : Node2D 

@export var base_damage : float = 0

var children_list = []
@export var health_max: float = 0
@onready var health : float = health_max 
#var ID: int = 0
@export var size: float = 0
var isHazard : bool = false

var zoneReference : Node2D
@export var hitboxReference : Area2D
@export var hurtboxReference : Area2D
@export var spawnerRef : Node2D

@export var ID: int = -1

#@export var white_flash : bool = false

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
	NONE, VIRUS, POISON
} 
var dot_type = NONE


#knockback info
var startPosition: Vector2
var oldDirPower : float = 0
#var power : float = 0
@export var weight : float = 1.0
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

func _shake(direction: Vector2, power : float) -> void:
	if oscillate_tween:
		oscillate_tween.kill()
	oscillate_tween = create_tween()
	oscillate_tween.tween_property(Sprite, "position", direction * 0.75, power / 4)
	oscillate_tween.tween_property(Sprite, "position", direction * -0.5, power / 2)
	oscillate_tween.tween_property(Sprite, "position", direction * 0.25, power / 2)
	oscillate_tween.tween_property(Sprite, "position", Vector2.ZERO, power / 4)
	_handleRedFlash(oscillate_tween)
	oscillate_tween.tween_callback(_collisionCheck)
	

func knockback(pos: Vector2, dmg : float, kb = 1.0, speed = 0) -> void:
	var power = 4.0 * kb * dmg / (health_max * weight)
	var dir : Vector2 = getPosition() - pos
	var dir_len : float = dir.length()
	if dir_len < 20:
		dir_len = 20
	var dir_norm : Vector2 = dir.normalized() #Could also do dir / dir_len
	
	oldDirPower = 5000.0 * power / dir_len 
	var end_dir = oldDirPower*dir_norm
	if power <= 0.5 or superArmor:
		_shake(end_dir, power)
	else:
		var rot_speed = 0.1 * power * dir_len if dir.x > 0 else -0.1 * power * dir_len
		
		if kb_moving:
			var oldDirection = (getPosition() - startPosition)
			var oldLen = oldDirection.length()
			var percentDist = 1 - oldLen/(oldDirPower+1)
			if percentDist <= 0:
				kb_moving = false
				knockback(pos, dmg, speed)
			else:
				end_dir += oldDirPower * percentDist * oldDirection.normalized()
				oldDirPower = end_dir.length()
				power += percentDist
				
				if movement_tween:
					movement_tween.kill()
				movement_tween = create_tween()
				match speed:
					0:
						movement_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
					1:
						movement_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
					2:
						movement_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
				startPosition = getPosition()
				var timeSpeed = snapped(log(power+1.25), 0.01)
				movement_tween.tween_property(Inner, "position", end_dir, timeSpeed).as_relative()
				movement_tween.parallel().tween_property(Inner, "rotation", rot_speed, timeSpeed)
				_handleRedFlash()
				movement_tween.tween_callback(_knockbackEnd)
		else:
			if movement_tween:
				movement_tween.kill()
			movement_tween = create_tween()
			match speed:
				0:
					movement_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
				1:
					movement_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
				2:
					movement_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
			kb_moving = true
			startPosition = getPosition()
			var timeSpeed = snapped(log(power+1.25), 0.01)
			movement_tween.tween_property(Inner, "position", end_dir, timeSpeed).as_relative()
			movement_tween.parallel().tween_property(Inner, "rotation", rot_speed, timeSpeed)
			_handleRedFlash()
			movement_tween.tween_callback(_knockbackEnd)

func _knockbackEnd() -> void:
	kb_moving = false
	#modulate = Color(1.0, 1.0, 1.0, 1.0)
	_collisionCheck()
	#if state == IDLE and $IdleTimer.is_stopped():
		#idle()

func _collisionCheck() -> void:
	if hurtboxReference:
		if (hurtboxReference.has_overlapping_areas() or hurtboxReference.has_overlapping_bodies()):
			var localAreas = hurtboxReference.get_overlapping_areas()
			for a in localAreas:
				_on_hurtbox_area_entered(a)
			
			var localBodies = hurtboxReference.get_overlapping_bodies()
			for b in localBodies:
				_on_hurtbox_body_entered(b)
				
#Use this to get the position for the creature
func getPosition() -> Vector2:
	return position + Inner.position
	
func getDamage() -> float:
	return base_damage

#Override this if needs be (such as multiple hitboxes)
func toggleHitbox(toggle : bool) -> void:
	if hitboxReference:
		#hitboxReference.set_deferred("monitoring", toggle)
		hitboxReference.set_deferred("monitorable", toggle)
	
#Override this if needs be (such as multiple hurtboxes)
func toggleHurtbox(toggle : bool) -> void:
	if hurtboxReference:
		hurtboxReference.set_deferred("monitoring", toggle)
		#hurtboxReference.set_deferred("monitorable", toggle)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	var temp_enemy = area.getParent()
	var dmg = area.getDamage()
	if temp_enemy.getID() != ID and dmg > 0:
		takeDamage(dmg, area.getPosition(), area.getKnockback())

func _on_hurtbox_body_entered(body: Node2D) -> void:
	var dmg = body.getDamage()
	var kb = body.getKnockback()
	if body.getID() != ID and dmg > 0:
		takeDamage(dmg, body.getPosition(), body.getKnockback())

func getKnockback() -> float:
	return 1.0

func _spawnOrbs(orb_amt = orb_reward) -> void:
	spawnOrbs.emit(orb_amt, getPosition())

func _addConnectChild(childRef : Node2D) -> void:
	children_list.append(childRef)
	childRef.isChild = true
	var parentZone
	if zoneReference:
		parentZone = zoneReference
	else:
		parentZone = get_parent()
	childRef.parentRef = self
	childRef.spawnOrbs.connect(parentZone._spawnOrbs)
	parentZone.call_deferred("add_child", childRef)

"""
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
"""

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

func _OnDeath(pos = Vector2.ZERO, kb = 1.0, _kwargs = []) -> void:
	print("DEATH: ", self)
	state = DEAD
	
	for c in children_list:
		c.orphan(pos)
	toggleHitbox(false)
	toggleHurtbox(false)
	if pos == Vector2.ZERO:
		_spawnOrbs()
		visible = false
		set_process(false)
		if isChild:
			if parentRef:
				parentRef.removeChild(self)
			call_deferred("queue_free")
	else:
		_deathKnockback(pos, kb)

func getID(IDtype = 0) -> int:
	if IDtype:
		return ID
	else:
		return 0

func orphan(pos = Vector2.ZERO) -> void:
	get_tree().create_timer(6.0).timeout.connect(_OnDeath.bind(pos))

func _deathKnockback(pos : Vector2, kb = 1.0) -> void:
	var dir : Vector2 = getPosition() - pos
	var dir_len : float = dir.length()
	if dir_len < 20:
		dir_len = 20
	
	var rot_speed = 0.1 * dir_len if dir.x > 0 else -0.1 * dir_len
	var end_dir = kb * 6000.0*dir.normalized()/dir_len
	if dot_tween:
		dot_tween.kill()
	dot_tween = create_tween()
	_handleRedDeath()
	dot_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	dot_tween.parallel().tween_property(Inner, "position", end_dir, 1.0).as_relative()
	dot_tween.parallel().tween_property(Inner, "rotation", rot_speed, 1.0).as_relative()
	dot_tween.finished.connect(_FullDeath)

func _handleRedFlash(tweener : Tween = movement_tween) -> void:
	tweener.parallel().tween_property(self, "modulate", Color(0.8, 0.4, 0.4, 1.0), 0.25)
	tweener.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)

func _handleRedDeath() -> void:
	dot_tween.tween_property(self, "modulate", Color(1.0, 0, 0, 0), 1.0)

func _FullDeath() -> void:
	if isChild:
		if parentRef:	
			parentRef.removeChild(self)
		call_deferred("queue_free")
	_spawnOrbs()
	visible = false
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
	
func applyPoison(intensity : float, duration = 2.0) -> void: #ID : int, 
	var dotLeft = 0
	dot_type = POISON
	if dot_tween:
		dot_tween.kill()
		if dot_remaining == -1:
			dotLeft = dot_remaining * dot_pow
	dot_tween = create_tween()
	dot_tween.tween_method(_dot_tick, 0, int(dotLeft + intensity*duration), duration) #ID, 
	dot_tween.tween_callback(_dot_end.bind(false))
	dot_pow = intensity
	dot_remaining = 0

func _dot_tick(dot_speed : int, type : int = 0) -> void:
	health -= (dot_speed - dot_remaining)
	dot_remaining = dot_speed
	if health <= 0:
		if dot_tween:
			dot_tween.kill()
		_dot_end(true, type)	#ID, 

func _dot_end(death : bool, type : int = 0) -> void: #ID : int, 
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
		
func takeDamage(amt : float, pos : Vector2, kb = 1.0, _kwargs = []) -> void:
	health -= amt
	if health <= 0:
		_OnDeath(pos, kb)		
	else:
		_damagedEffect(amt, pos, knockback, _kwargs)

func _damagedEffect(amt : float, pos : Vector2, kb = 1.0, _kwargs = []) -> void:
	knockback(pos, amt, kb)
		
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
			
	
