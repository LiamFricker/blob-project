extends Node2D

var stageLevel = 0
var sizeLevel = 0

var baseEntitiesList = []
var poolEntitiesList = []
var plantEntitiesList = []
var hazardEntitiesList = []
var spawnedEntitiesList = []

var baseEntitiesWeights = []
var poolEntitiesWeights = []
var plantEntitiesWeights = []
var hazardEntitiesWeights = []

var baseEntitiesLowBounds = [0]
var poolEntitiesLowBounds = [0]
var plantEntitiesLowBounds = [0]
var hazardEntitiesLowBounds = [0]

var baseEntitiesUpBounds = [0]
var poolEntitiesUpBounds = [0]
var plantEntitiesUpBounds = [0]
var hazardEntitiesUpBounds = [0]

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
	match currentMap:
		0:
			var weightTotal = 0
			#Load in the spawner entities. If they're duplicate use somewhere, you can also
			#start weight code up here as well.
			#However, I don't think that will be the case since spawned entities have a "parent"
			#entity, so it wouldn't make sense.
			_loadEntity("res://Art/Cell/DNA0.png", 5 - 1)
			_loadEntity("res://Art/Cell/DNA0.png", 5 - 1)
			_loadEntity("res://Art/Cell/DNA0.png", 5 - 1)
			
			#First weight is -1 since we're including 0
			weightTotal += _loadEntity("res://Art/Cell/DNA0.png", 5 - 1, 0)
			baseEntitiesUpBounds[0] = weightTotal
			
			baseEntitiesLowBounds.append(weightTotal + 1)
			weightTotal += _loadEntity("res://Art/Cell/DNA0.png", weightTotal + 5, 0)
			weightTotal += _loadEntity("res://Art/Cell/DNA0.png", weightTotal + 5, 0)
			baseEntitiesUpBounds.append(weightTotal)
			
			baseEntitiesLowBounds.append(weightTotal + 1)
			weightTotal += _loadEntity("res://Art/Cell/DNA0.png", weightTotal + 5, 0)
			weightTotal += _loadEntity("res://Art/Cell/DNA0.png", weightTotal + 5, 0)
			weightTotal += _loadEntity("res://Art/Cell/DNA0.png", weightTotal + 5, 0)
			baseEntitiesUpBounds.append(weightTotal)
			
		1:
			#Probably a more elegant way of doing this but this is just a reminder to 
			#unload all this stuff.
			if not fromNew:
				for e in baseEntitiesList:
					e.queue_free()
				for e in poolEntitiesList:
					e.queue_free()
				for e in plantEntitiesList:
					e.queue_free()
				for e in hazardEntitiesList:
					e.queue_free()
			
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
func _loadEntity(path : String, weight : int, biome = 4) -> int:
	var temp = load(path)
	#I had this var before because I thought I'd do the weight add in here
	#why the heck am I commenting this
	#var tempWeight = weight
	match biome:
		#base
		0:
			baseEntitiesList.append(temp)
			baseEntitiesWeights.append(weight)
		#pool
		1:
			poolEntitiesList.append(temp)
			poolEntitiesWeights.append(weight) 
		#plant
		2:
			plantEntitiesList.append(temp)
			plantEntitiesWeights.append(weight)
		#haz
		3:
			hazardEntitiesList.append(temp)
			hazardEntitiesWeights.append(weight) 
		#spawn
		4:
			spawnedEntitiesList.append(temp)
			return 0
		
	
	return weight

#To be honest, I should probably use a 2D list but my experience in coding up the zones
#has taught me that 2D lists are a pain in the ass here
#Since we know these IDs before hand, the spawners will want to spawn them directly.
#Of course, this brings the issue of the spawners needing to remember their IDs though
#We'll solve this by making a new list and adding new spawns incrementally so it doesn't 
#affect old spawns. And later spawns will be added to a new list anyways so they'll always
#be in somewhat consistent order to their map. Id will replace biome for spawners
func spawnEntity(biomeOrID : int, weight : float, pos : Vector2) -> Node2D:
	var tempEntity = Node2D
	
	#Huh I just learnt you can do a ton of stuff with switch cases in Godot
	#Makes me wonder why no one uses them, I'll prob go read up on them in a bit
	
	match biomeOrID:
		0:
			var chosenID = baseEntitiesUpBounds[sizeLevel] 
			+ floor(weight * (baseEntitiesUpBounds[sizeLevel] - baseEntitiesLowBounds[sizeLevel]))
			if weight == 1.0:
				chosenID -= 1
			var tempSize = baseEntitiesWeights.size()
			for i in range(tempSize):
				if baseEntitiesList[i] >= chosenID:
					chosenID = i
					break
			#Just incase I mess up my math badly
			if chosenID > tempSize - 1:
				chosenID = 0
				print("Messed up weights")
			tempEntity = baseEntitiesList[chosenID].instantiate()
			tempEntity.position = pos
		1:
			pass
		2:
			pass
		3:
			pass
		_:
			#I should probably run a basic check 
			tempEntity = spawnedEntitiesList[biomeOrID].instantiate()
			tempEntity.position = pos
			#The spawner should add this to their children 
			#and add themselves as a parent
			#We should honestly make a own seperate thing for spawners but 
			#I think a lot of enemies will be spawners because each projectile
			#is technically an entity as we learnt from our other game.
			#Could probably make that more optimized and personalized for enemies
			#with lotsof projectiles
	
	return tempEntity
