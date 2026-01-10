extends Node2D

var stageLevel = 0
var sizeLevel = 0

var entitiesList = []
var entitiesSize = 0

var baseEntitiesList: PackedInt32Array = []
var poolEntitiesList: PackedInt32Array = []
var plantEntitiesList: PackedInt32Array = []
var hazardEntitiesList: PackedInt32Array = []
var spawnedEntitiesList: PackedInt32Array = []

#idk what the point is to this shit
"""
var baseEntitiesWeights = []
var poolEntitiesWeights = []
var plantEntitiesWeights = []
var hazardEntitiesWeights = []
"""

var baseEntitiesLowBounds: PackedInt32Array = [0]
var poolEntitiesLowBounds: PackedInt32Array = [0]
var plantEntitiesLowBounds: PackedInt32Array = [0]
var hazardEntitiesLowBounds: PackedInt32Array = [0]

var baseEntitiesUpBounds: PackedInt32Array = [0]
var poolEntitiesUpBounds: PackedInt32Array = [0]
var plantEntitiesUpBounds: PackedInt32Array = [0]
var hazardEntitiesUpBounds: PackedInt32Array = [0]

var id_count : int = 0

#Ok here's the gameplan
#Each map transition, load in the entities you need
#Or free all the previous if you're loading out (besides the ones you need later)
#Each entitiy has a weight. Since we can't instantiate them now to access their info
#you're gonna have to define them here. Some entities will repeat between lists
#Just don't load them a second time. They're all a reference at the end of the day.
#You should probably add them all at the same time. This likely isn't the most 
#efficient way of doing this but I'm being heavily distracted right now and I'm 
#not being allowed to think. 
#Anyways, we'll have to add those weights. Since we want a different sample per 
#size level. But we don't want to load them middle of gameplay so we'll load them all
#at the start, and we'll have upper and lower bounds of where to check the list at.
#We'll take the float from 0.0 to 1.0. Need to also make sure that if it ends up being 1.0
#change it to the last number so we don't get an array out of bounds. Floor the resulting int
#You're gonna have to manually put in the path and the weight for each of them. 
#If it's problematic to search later on, put down an ID or something next to the names
#Probably better to do this differently somehow, but I think this is the best for now
func loadMapEntities(currentMap : int, fromNew = false) -> void:
	id_count = 0
	match currentMap:
		0:
			var weightTotal = 0
			var weightBase = 25
			#Load in the spawner entities. If they're duplicate use somewhere, you can also
			#start weight code up here as well.
			#However, I don't think that will be the case since spawned entities have a "parent"
			#entity, so it wouldn't make sense.
			#_loadEntity("res://Art/Cell/DNA0.png", 5 - 1)
			#_loadEntity("res://Art/Cell/DNA0.png", 5 - 1)
			#_loadEntity("res://Art/Cell/DNA0.png", 5 - 1)
			
			#Base
			#First weight is -1 since we're including 0
			#baseEntitiesLowBounds[0] = 0
			weightTotal = weightBase - 1
			#weightTotal += _loadEntity("res://Art/Cell/DNA0.png", weightBase - 1, 0, weightTotal, -1)
			entitiesList.append(load("res://Blob/virus_tiny.tscn"))
			baseEntitiesList.append(0)
			baseEntitiesUpBounds[0] = weightTotal
			
			return
			
			weightTotal += _loadEntity("res://Art/Cell/DNA0.png", weightBase - weightBase/5, weightTotal, 0)
			weightTotal += _loadEntity("res://Art/Cell/DNA0.png", weightBase, weightTotal, 0)
			weightTotal += _loadEntity("res://Art/Cell/DNA0.png", weightBase, weightTotal, 0)
			
			#Pool (keep in mind this is for testing, pool and rest doesn't actually show up in map 0)
			weightTotal = weightBase - 1
			entitiesList.append(load("res://Art/Cell/DNA0.png"))
			poolEntitiesList.append(0)
			poolEntitiesUpBounds[0] = weightTotal
			
			weightTotal += _loadEntity("res://Art/Cell/DNA0.png", weightBase, weightTotal, 1)
			weightTotal += _loadEntity("res://Art/Cell/DNA0.png", weightBase, weightTotal, 1, 3)
			
			#Plant
			weightTotal = weightBase - 1
			entitiesList.append(load("res://Art/Cell/DNA0.png"))
			plantEntitiesList.append(0)
			plantEntitiesUpBounds[0] = weightTotal
			
			weightTotal += _loadEntity("res://Art/Cell/DNA0.png", weightBase, weightTotal, 2)
			weightTotal += _loadEntity("res://Art/Cell/DNA0.png", weightBase, weightTotal, 2, 2)
			
			#Haz
			weightTotal = weightBase - 1
			entitiesList.append(load("res://Art/Cell/DNA0.png"))
			hazardEntitiesList.append(0)
			hazardEntitiesUpBounds[0] = weightTotal
			weightTotal += _loadEntity("res://Art/Cell/DNA0.png", weightBase, weightTotal, 3)
			weightTotal += _loadEntity("res://Art/Cell/DNA0.png", weightBase, weightTotal, 3, 1)
			
			#Spawned Entities
			_loadEntity("res://Art/Cell/DNA0.png", 0, 0, 4)
			
		1:
			#There's probably a more elegant way of doing this but this is just a reminder to 
			#unload all this stuff.
			if not fromNew:
				for e in entitiesList:
					e.queue_free()
			baseEntitiesList = []
			poolEntitiesList = []
			plantEntitiesList = []
			hazardEntitiesList = []
			spawnedEntitiesList = []
			
		2:
			pass
		3:
			pass
		4:
			pass
		5:
			pass

#Helper function to help make code cleaner
#Kwargs would be a blessing here tbh
#I could also do some thing where I pass one int id 
#in binary, but I feel like that defeats the purpose
#OH WAIT YOU'RE SO DUMB
#EACH BIOMES HAS DIFFERENT WEIGHTS DUMMY
#SO YOU CAN'T USE ON FUNC LIKE THIS
#Idk what I was talking about here. baseEntities list needs to be indexes of the 
#entities in entity list since some will be shared
#Need some extra arguments to declare whether it'll be a reference to another
#If so, do not load and instead have it point to the index declared.
#Tbh it'd be better to have this in a serperate json file but idgaf
func _loadEntity(path : String, weight : int, weightTotal : int, biome = 4, isReference = -1) -> int:
	#I had this var before because I thought I'd do the weight add in here
	#why the heck am I commenting this
	#var tempWeight = weight
	var EntLoRef
	var EntIdRef
	var EntUpRef 
	match biome:
		#base
		0:
			#idk wtf this was for
			#baseEntitiesWeights.append(weight)
			EntLoRef = baseEntitiesLowBounds
			EntIdRef = baseEntitiesList
			EntUpRef = baseEntitiesUpBounds
		#pool
		1:
			EntLoRef = poolEntitiesLowBounds
			EntIdRef = poolEntitiesList
			EntUpRef = poolEntitiesUpBounds
		#plant
		2:
			EntLoRef = plantEntitiesLowBounds
			EntIdRef = plantEntitiesList
			EntUpRef = plantEntitiesUpBounds
		#haz
		3:
			EntLoRef = hazardEntitiesLowBounds
			EntIdRef = hazardEntitiesList
			EntUpRef = hazardEntitiesUpBounds
		#spawn
		4:
			#I don't think this should ever matter... but... just in case.
			#Remember to comment this out later.
			if isReference == -1:
				entitiesList.append(load(path))
				spawnedEntitiesList.append(entitiesSize)
				entitiesSize += 1
			else:
				spawnedEntitiesList.append(isReference)
			return 0
		
	EntLoRef.append(weightTotal)
	if isReference == -1:
		entitiesList.append(load(path))
		EntIdRef.append(entitiesSize)
		entitiesSize += 1
	else:
		EntIdRef.append(isReference)
	weightTotal += weight
	EntUpRef.append(weightTotal)
	return weightTotal

#To be honest, I should probably use a 2D list but my experience in coding up the zones
#has taught me that 2D lists are a pain in the ass here
#Since we know these IDs before hand, the spawners will want to spawn them directly.
#Of course, this brings the issue of the spawners needing to remember their IDs though
#We'll solve this by making a new list and adding new spawns incrementally so it doesn't 
#affect old spawns. And later spawns will be added to a new list anyways so they'll always
#be in somewhat consistent order to their map. Id will replace biome for spawners
#?????
#Anyways idk what the fuck this shit is, it's way too fucking messy.
#Binary search this shit. We have upper and lower bound so use upper to check for > upper
#and < to check for less than lower.
func spawnEntity(biomeOrID : int, weight : float, pos : Vector2) -> Node2D:
	var tempEntity = Node2D
	
	#Huh I just learnt you can do a ton of stuff with switch cases in Godot
	#Makes me wonder why no one uses them, I'll prob go read up on them in a bit
	#It's because if type cases are for babies dumbass.
	
	if weight == -1:
		tempEntity = entitiesList[biomeOrID].instantiate()
		tempEntity.position = pos
		tempEntity.spawnerRef = self
		tempEntity.ID = id_count
		#tempEntity.name = id_count
		id_count += 1
		#The spawner should add this to their children 
		#and add themselves as a parent
		#We should honestly make a own seperate thing for spawners but 
		#I think a lot of enemies will be spawners because each projectile
		#is technically an entity as we learnt from our other game.
		#Could probably make that more optimized and personalized for enemies
		#with lotsof projectiles
		
		print("SPWANED COMP ")
		
		#MAKE SURE TO CHANGE THIS LATER WITH PARENT AND CHILD
		return tempEntity
	
	var EntLoRef
	var EntUpRef 
	
	match biomeOrID:
		0:
			EntLoRef = baseEntitiesLowBounds
			EntUpRef = baseEntitiesUpBounds
		#pool
		1:
			EntLoRef = poolEntitiesLowBounds
			EntUpRef = poolEntitiesUpBounds
		#plant
		2:
			EntLoRef = plantEntitiesLowBounds
			EntUpRef = plantEntitiesUpBounds
		#haz
		3:
			EntLoRef = hazardEntitiesLowBounds
			EntUpRef = hazardEntitiesUpBounds
		_:
			#I should probably run a basic check 
			
			tempEntity = entitiesList[biomeOrID].instantiate()
			tempEntity.position = pos
			tempEntity.spawnerRef = self
			tempEntity.ID = id_count
			#tempEntity.name = id_count
			id_count += 1
			#The spawner should add this to their children 
			#and add themselves as a parent
			#We should honestly make a own seperate thing for spawners but 
			#I think a lot of enemies will be spawners because each projectile
			#is technically an entity as we learnt from our other game.
			#Could probably make that more optimized and personalized for enemies
			#with lotsof projectiles
			
			#MAKE SURE TO CHANGE THIS LATER WITH PARENT AND CHILD
			return tempEntity
	
	#var chosenID = baseEntitiesLowBounds[sizeLevel] 
	#+ floor(weight * (baseEntitiesUpBounds[sizeLevel] - baseEntitiesLowBounds[sizeLevel]))
	var chosenID = floor(weight * (EntUpRef[entitiesSize-1] + 1))
	#This is just done to try to keep the chance as close as possible since 1.0 will be rare af.
	if weight == 1.0:
		chosenID -= 1
	chosenID = binaryFindEntity(chosenID, biomeOrID)
	
	tempEntity = entitiesList[chosenID].instantiate()
	tempEntity.position = pos
	tempEntity.spawnerRef = self
	tempEntity.ID = id_count
	#tempEntity.name = id_count
	id_count += 1
	
	return tempEntity

#We have upper and lower bound so use upper to check for > upper
#and < to check for less than lower.
func binaryFindEntity(chosenID: int, biome : int) -> int:
	var EntLoRef
	var EntIdRef
	var EntUpRef 
	var low = 0
	var high : int
	match biome:
		0:
			EntLoRef = baseEntitiesLowBounds
			EntIdRef = baseEntitiesList
			EntUpRef = baseEntitiesUpBounds
			high = baseEntitiesList.size() - 1
		#pool
		1:
			EntLoRef = poolEntitiesLowBounds
			EntIdRef = poolEntitiesList
			EntUpRef = poolEntitiesUpBounds
			high = poolEntitiesList.size() - 1
		#plant
		2:
			EntLoRef = plantEntitiesLowBounds
			EntIdRef = plantEntitiesList
			EntUpRef = plantEntitiesUpBounds
			high = plantEntitiesList.size() - 1
		#haz
		3:
			EntLoRef = hazardEntitiesLowBounds
			EntIdRef = hazardEntitiesList
			EntUpRef = hazardEntitiesUpBounds
			high = hazardEntitiesList.size() - 1
	
	while(low <= high):
		var mid : int = low + (high-low) / 2
		if chosenID > EntUpRef[mid]:
			low = mid + 1
		elif chosenID < EntLoRef[mid]:
			high = mid - 1
		else:
			return EntIdRef[mid]
	print("SEARCH FAILED YOU MESSED UP")
	return 0
