extends Node2D

signal zoneHandleRoamer(supplyState : int, position : Vector2, creatureRef : Node2D)

#var cellReference Just do a get_parent call tbh
var entitySpawnerReference #This one should probably be saved since it's called a lot
var eventReference: Node2D #This one probably should just be added as a child.
@export var hasEvent : bool = false

#USELESS
#Stage from 0-4
#@export var stageLevel: int = 0

#Entity Vars
var creatureList = []
#ID of all dead creatures
var deadCreaturesList = []
var creatureAmount = 0
#ID of all roaming creatures
var roamingCreatures = []
@export var creatureMax = 0
@export var creatureSeed = 0
var guestList = []

#Environment Type 
#enum {NONE, POND, PLANT, HAZARD}
@export var biome: int = 0
var weights = [0.0, 0.0, 0.0]

var dimensions : Vector2

#Each Creature needs its own ID and home as well as whether it's a guest or not
#Each zone needs its own state and how many roaming guests.
#When a zone containing guest creature is disabled, the creature is sent back to its home
#There it behaves in the way it should based on how the home is. 
#When sent back, it will always be in a disabled state so mobs won't randomly teleport in or out.
#Change the respawn to 5x5 instead of 7x7, and make disable and free the same.
#So instead of hiding, removing, or queue free, just disable on the entities's rules and free the dead ones.
#Then one step later, simply queue free all the entities (not on all maps). 
#When reentering, reenable all the entities at og position and HP and respawn spare entity slots. Make sure to 
#consider how many entities may be guests in another zone.

#UGGGGGH THIS IS A BAD IDEA...
#but at some point I changed the structure of creature to be children of the spawner instead of zone?
#But it's a pain in the ass to change now... and I think it's fine for now... surely.

#Remember to disable/free guests and send them back to their home once this becomes disabled.
#Maybe use a supply state emit 4/5. Need to check the home policy since it's possible that 
#the guest is disabled but the home is freed. 
#Also go around removing unneeded variables from zone.
func removeRoamer(ID : int, dead = false) -> void:
	var tempposID = roamingCreatures.find(ID)
	if tempposID != -1:
		roamingCreatures.remove_at(tempposID)
		
	if dead:
		if creatureList.size() == roamingCreatures.size():
			for i in range(creatureList.size() - 1, -1, -1):
				if creatureList[i].ID == ID:
					creatureList[i].call_deferred("queue_free")
					creatureList[i].remove(i)
		elif deadCreaturesList.find(ID) == -1:
			deadCreaturesList.append(ID)
		#else:
		#	pass
			#Ideally this needs to be freed somehow in this case
	else:
	#Free the roamer if the zone is currently in free mode
		if creatureList.size() == roamingCreatures.size():
			for i in range(creatureList.size() - 1, -1, -1):
				if creatureList[i].ID == ID:
					creatureList[i].call_deferred("queue_free")
					creatureList[i].remove(i)


func handleRoamer(supplyState : int, position : Vector2, ID = 0) -> void:
	#Creature -> Roamer
	if supplyState == 0:
		roamingCreatures.append(creatureList[ID])
		#Emit signal
		zoneHandleRoamer.emit(supplyState, position, creatureList[ID])
	#Guest -> Roamer
	else:
		for i in range(guestList.size()):
			if guestList[i].ID == ID:
				#Emit signal
				#Remove from Guest List
				guestList.remove(i)
				zoneHandleRoamer.emit(supplyState, position, creatureList[ID])
				break
				

#Create a zone
#stgLvl : int, 
#The background should be handled in the top layer, but should probably keep the second highest zone weight
#somewhere so we can do hybrid layouts. Or not, we could always just run max on zone_weights each time we transition
#infact, that might be a better idea tbh. Though the transition will probably have to be delayed.
#Yeah let's do that instead, since it's one call every 2-4s rather than like 400 extra ints we have to store
func setParams(env : int, zone_weights : Array, entitySeed : int, entityMax : int, pos : Vector2, dim : Vector2) -> void:
	#stageLevel = stgLvl
	biome = env
	weights = zone_weights
	creatureSeed = entitySeed
	creatureMax = 0#entityMax
	position = pos
	dimensions = dim
	$Polygon2D.polygon = PackedVector2Array([-dim/2, Vector2(dim.x/2, -dim.y/2), dim/2, Vector2(-dim.x/2, dim.y/2)])
	$Polygon2D.color = Color(randf_range(0,1.0),randf_range(0,1.0),randf_range(0,1.0),0.75)

func changePosition(newpos : Vector2) -> void:
	#MAKE THIS FUNCTION SET A POSITION VARIABLE AND CHANGE IT AT THE END OF THE FRAME
	var diff = newpos - position
	for c in creatureList:
		if not c.roaming: 
			#Add this to the base class that basically += position
			#In case they have children of their own, ya know.
			c.addPosition(diff)
	position = newpos

#MAKE SURE TO SPAWN THE ENTITY WITHIN THE BOUNDS OF THIS ZONE * 0.9
#NOT A CIRCLE, do WITHIN THE DIMENSIONS I PASSED
#I really want to make this one switch statement since they're all so similar.
func createEntities() -> void:
	return
	
	#var index = 0
	creatureList.resize(creatureMax)
	for i in range(creatureMax):# - creatureList.size()):
		
		var _creaturePos = 0  
		
		creatureList[i] = get_node(entitySpawnerReference).spawn_entity()
		#index += 1

func refactorCreatures(count : int) -> void:
	if count < 0:
		for i in range(creatureMax - 1, creatureMax + count - 1, -1): 
			if creatureList[i]:	
				creatureList[i].queue_free()
			creatureList.remove_at(i)
	else:
		creatureList.resize(creatureMax + count)
		for i in range(creatureMax, creatureMax + count): 
			creatureList[i] = get_node(entitySpawnerReference).spawn_entity()
	
	creatureMax += count

#I don't think we're doing it this way, but if we are, refact the enemies positions and the max amount of enemies to account for 
#the event. For now, let's just lower the max amount of entities.
func eventRefactor(entityMin:int) -> void:
	if creatureMax > entityMin:
		creatureMax -= 1

#Need to call spawner to spawn them
func firstSpawnEntities() -> void:
	pass

#MAKE SURE TO SPAWN THE ENTITY WITHIN THE BOUNDS OF THIS ZONE * 0.9
#NOT A CIRCLE, do WITHIN THE DIMENSIONS I PASSED
func spawnEntities() -> void:
	var creatureAmount = creatureList.size()
	if creatureAmount == roamingCreatures.size() and creatureAmount > 0:
		creatureList.resize(creatureMax)
		for i in range(0, creatureMax):
			#This is to preserve the order.
			if not (i in roamingCreatures):
				var tempEntity = 0
				creatureList[i] = tempEntity
	else:
		var tempEntity = 0
		creatureList.append(tempEntity)
		creatureList.resize(creatureMax)
		for i in range(1, creatureMax):
			#This is to preserve the order.
			var temperEntity = 0
			creatureList[i] = temperEntity
			
	
func freeEntities() -> void:
	for i in range(creatureList.size()-1, -1, -1):
		if not creatureList[i].roaming: 
			creatureList[i].queue_free()
			creatureList.remove_at(i)
	deadCreaturesList = []
	#creatureAmount = roamingCreatures.size()
	#This shouldn't really trigger but just in case
	for g in guestList:
		zoneHandleRoamer.emit(4, g.homepos, g)
		g.roaming = false
		#g.call_deferred("queue_free")
	guestList = []
	
func enableEntities() -> void:
	#Putting this here since we're changing the logic.
	spawnEntities()
	if hasEvent:
		#get_node(eventReference).enable()
		eventReference.enable()
	for c in creatureList:
		c.reset()
		#add_child(c)
	for d in range(deadCreaturesList.size()):# - 1, -1 , 0):
		var temp # = spawnCreature w/e
		creatureList[deadCreaturesList[d]].call_deferred("queue_free")
		creatureList[deadCreaturesList[d]] = temp
	deadCreaturesList = []
		
func disableEntities() -> void:
	if hasEvent:
		eventReference.disable()
	for c in creatureList:
		if not c.roaming: 
			if c.state == 2:
				deadCreaturesList.append(c.ID)
				#c.queue_free()
			else:
				#Call this incase there's any enemies with some special code that should be disabled remotely
				#If there is no need for this, just remove it later. Put a dummy function in the enemy baseclass
				c.disable()
				#remove_child(c)
	for g in guestList:
		if g.state == 2:
			zoneHandleRoamer.emit(4, g.homepos, g)
			g.roaming = false
			#g.call_deferred("queue_free")
		else:
			#Call this incase there's any enemies with some special code that should be disabled remotely
			#If there is no need for this, just remove it later. Put a dummy function in the enemy baseclass
			g.disable()
			g.roaming = false
			zoneHandleRoamer.emit(2, g.homepos, g)
	guestList = []
		

#We won't be using this but keep this here incase I need it later
func showEntities() -> void:
	if hasEvent:
		eventReference.enable()
	for c in creatureList:
		c.enable()
		
#We won't be using this but keep this here incase
#Need to combine this code with disable now
func hideEntities() -> void:
	if hasEvent:
		eventReference.disable()
	for c in creatureList:
		c.disable()
