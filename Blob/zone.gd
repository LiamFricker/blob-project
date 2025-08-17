extends Node2D

@export var entitySpawnerReference: NodePath
@export var eventReference: NodePath
@export var hasEvent : bool = false

#Stage from 0-4
@export var stageLevel: int = 0

#Entity Vars
var creatureList = []
@export var creatureMax = 0
@export var creatureSeed = 0
var guestList = []

#Environment Type 
enum {NONE, POND, PLANT, HAZARD}
@export var biome = NONE
var weights = [0.0, 0.0, 0.0]

var mapPosition : Vector2

#Create a zone
func setParams(stgLvl : int, env : int, zone_weights : Array, entitySeed : int, entityMax : int, pos : Vector2) -> void:
	stageLevel = stgLvl
	biome = env
	weights = zone_weights
	creatureSeed = entitySeed
	creatureMax = entityMax
	mapPosition = pos

#I really want to make this one switch statement since they're all so similar.
func createEntities() -> void:
	#var index = 0
	
	for i in range(creatureMax - creatureList.size()):
		
		var creaturePos = 0  
		
		creatureList.append(get_node(entitySpawnerReference).spawn_entity())
		#index += 1

#I don't think we're doing it this way, but if we are, refact the enemies positions and the max amount of enemies to account for 
#the event. For now, let's just lower the max amount of entities.
func eventRefactor(entityMin:int) -> void:
	if creatureMax > entityMin:
		creatureMax -= 1
	
func freeEntities() -> void:
	for c in creatureList:
		c.queue_free()
	creatureList = []

func spawnEntities() -> void:
	for c in creatureList:
		add_child(c)
		
func disableEntities() -> void:
	for c in creatureList:
		remove_child(c)

func showEntities() -> void:
	if hasEvent:
		get_node(eventReference).enable()
	for c in creatureList:
		c.enable()

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
