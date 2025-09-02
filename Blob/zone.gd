extends Node2D

@export var entitySpawnerReference: NodePath
@export var eventReference: NodePath
@export var hasEvent : bool = false

#Stage from 0-4
@export var stageLevel: int = 0

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
enum {NONE, POND, PLANT, HAZARD}
@export var biome = NONE
var weights = [0.0, 0.0, 0.0]

var mapPosition : Vector2

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

#Create a zone
func setParams(stgLvl : int, env : int, zone_weights : Array, entitySeed : int, entityMax : int, pos : Vector2) -> void:
	stageLevel = stgLvl
	biome = env
	weights = zone_weights
	creatureSeed = entitySeed
	creatureMax = entityMax
	mapPosition = pos

func changePosition(newpos : Vector2) -> void:
	var diff = newpos - position
	for c in creatureList:
		if not c.roaming: 
			#Add this to the base class that basically += position
			#In case they have children of their own, ya know.
			c.addPosition(diff)
	position = newpos

#I really want to make this one switch statement since they're all so similar.
func createEntities() -> void:
	#var index = 0
	creatureList.resize(creatureMax)
	for i in range(creatureMax):# - creatureList.size()):
		
		var creaturePos = 0  
		
		creatureList[i] = get_node(entitySpawnerReference).spawn_entity()
		#index += 1

func refactorCreatures(count : int) -> void:
	if count < 0:
		for i in range(creatureMax, creatureMax + count, -1): 
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

func firstSpawnEntities() -> void:
	pass

func spawnEntities() -> void:
	if creatureAmount == roamingCreatures.size():
		for i in range(0, creatureMax):
			if not (i in roamingCreatures):
				var tempEntity = 0
				creatureList[i] = tempEntity
	else:
		for d in deadCreaturesList:
			var tempEntity = 0
			creatureList[d] = tempEntity
			
	
func freeEntities() -> void:
	for c in creatureList:
		if not c.roaming: 
			c.queue_free()
	deadCreaturesList = []
	creatureAmount = roamingCreatures.size()

func enableEntities() -> void:
	#Putting this here since we're changing the logic.
	spawnEntities()
	if hasEvent:
		get_node(eventReference).enable()
	for c in creatureList:
		c.reset()
		add_child(c)
		
func disableEntities() -> void:
	if hasEvent:
		get_node(eventReference).disable()
	for c in creatureList:
		if not c.roaming: 
			if c.state == 2:
				deadCreaturesList.append(c.ID)
				c.queue_free()
			else:
				#Call this incase there's any enemies with some special code that should be disabled remotely
				#If there is no need for this, just remove it later. Put a dummy function in the enemy baseclass
				c.disable()
				remove_child(c)
		

#We won't be using this but keep this here incase I need it later
func showEntities() -> void:
	if hasEvent:
		get_node(eventReference).enable()
	for c in creatureList:
		c.enable()
		
#We won't be using this but keep this here incase
#Need to combine this code with disable now
func hideEntities() -> void:
	if hasEvent:
		get_node(eventReference).disable()
	for c in creatureList:
		c.disable()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
