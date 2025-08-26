extends Node2D

const SEED_LENGTH = 6
var map_seed: int = 0
var map_hash: String = ""

@export var zone : PackedScene

#You'll need to background load the next zone at a certain size threshold.

#You'll need to clear and repopulate this
var used_event_array = []
var next_event_array = []
var event_positions = []
var dict_variable_key = "Another key name"

#Environment Map
var hazard_map = [[0]]
var plant_map = [[0]]
var pool_map = [[0]]
var environments = [[0]]
#Track the center of environments
var EnvironmentSources = []
#Track the type each center is
var EnvironmentTypes = []


#Events
@export var peaceful_event : PackedScene
"""
var MAP1_EVENTS = [peaceful_event]
var MAP2_EVENTS = [peaceful_event]
var MAP3_EVENTS = [peaceful_event]
var MAP4A_EVENTS = [peaceful_event]
var MAP4B_EVENTS = [peaceful_event]
var MAP4C_EVENTS = [peaceful_event]
"""
#I really really really want to put all these maps in an array so it'll be neater 
#BUT I also think it'd be unnecesary extra baggage for one function likely.
#var MAP_EVENTS = [MAP1_EVENTS, MAP2_EVENTS, MAP3_EVENTS] 
#var event_ids = [[0],[0],[0],[0],[0],[0]]

var zone_list = [[]]
var next_zone_list = [[]]

const MAP_DIMS = [3,6,10,20,10,10,10] #Dimensions of the map
const ZONE_WIDTH = [1,1,1,1,1,1,1] #Width of each zone
const ZONE_HEIGHT = [1,1,1,1,1,1,1] #Width of each zone

#Number of each environment generated in a map. Final map is larger fyi. Maybe penultimate will be too.
const ENV_MAX = [0,2,3,4,2,2,2] 
#I'd prefer there to be more events but that's also more work to do. Maybe when we add more events to the game
const EVENT_MAX = [0,3,6,9,6,6,6] 
#It'd also be preferable not to repeat events
#Create an array that tracks the ids of the events visited, 
var events_visited = []

const ENTITY_MAX = [3,3,3,3,3,3]
const ENTITY_MODIFIERS = [1, 1.5, 1.4, 0.75]

var current_map = 3
enum {
	UNLOADED, #Map isn't loaded at all. Generate zone list map. (usually when starting game)
	NEXT_UNLOADED, #Next Map needs to be loaded
	WAITING, #Waiting on Player to reach size threshold to generate next map
	TRANSITION #Transitioning from one map to another or no map to a map
}
var MapState = UNLOADED

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var rng = RandomNumberGenerator.new()
	
	#The c++ programmer in me hates this but it's simpler than the alternative
	var alphabet_uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" 
	#rng.seed = hash("Godot")
	
	seed(hash("Godot"))
	for i in range(SEED_LENGTH):
		map_hash += alphabet_uppercase[randi_range(0, 25)] #rng.
	map_seed = hash(map_hash)
	
	generateMap()
	
	#Should probably run some unit tests here
	#print out the env arrays
	if current_map != 0:
	
		for i in range(EnvironmentTypes.size()):
			print("Env Type: ", EnvironmentTypes[i])
			print("Env Source: ", EnvironmentSources[i])
			
		var poolString = "Pool Weight: \n["
		var plantString = "Plant Weight: \n["
		var hazString = "Haz Weight: \n["
		var totalString = "Total Weight: \n["
		for i in range(MAP_DIMS[current_map]):
			poolString += "\n["
			plantString += "\n["
			hazString += "\n["
			totalString += "\n["
			for j in range(MAP_DIMS[current_map]):
				poolString += str(snapped(pool_map[i][j], 0.01)) + ", "
				plantString += str(snapped(plant_map[i][j], 0.01)) + ", "
				hazString += str(snapped(hazard_map[i][j], 0.01)) + ", "
				totalString += str(snapped(pool_map[i][j]+plant_map[i][j]+hazard_map[i][j], 0.01)) + ", "	
		print(poolString)
		print(plantString)
		print(hazString)
		print(totalString)
	var zoneString = "Zone Info: \n["		
	#print out the zone array 
	for i in range(MAP_DIMS[current_map]):
		zoneString += "\n["
		for j in range(MAP_DIMS[current_map]):
			zoneString += zone_list[i][j] + ", "	
	print(zoneString)
	#print out the event array
	for i in event_positions:
		print("Event: ", i)
	"""
	for i in used_event_array:
		print("Event: ", i)
	"""

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

#Need to remember generate the events as well
#To reduce complexity of Zones, have the events be generated here
#Events always exist however, they are not active until the zone becomes active.
func generateMap() -> void:
	#var rng = RandomNumberGenerator.new()
	
	#Need to reseed everytime incase it's starting from a fresh save and everything isn't generated
	#Either that or we save all that map data to file, which I think would be a metric pain in the ass.
	#Let's look at how long it takes and we'll see.
	#We could also store the states of the rng.
	#GlobalScope RNG also does not allow you to find the state fyi. Let's see what happens.
	#However, global does allow us to use randomize on an array. However, we could always just make a randomize
	#function of our own, though it's likely more expensive.
	#rng.seed = map_seed + hash(str(current_map))
	seed(map_seed + hash(str(current_map)))
	#Generate Environments
	#Set Array of Zone Boundaries (top left, bottom right in Vec2)
	#Set Array of Zone Types
	#Set
	#Final = 2 large zones for primary, 2 small zones for secondary, 1 small zone for unpreferred
	#i.e. Hazard -> Puddle -> Plant, Puddle -> Plant -> Hazard, Plant -> Hazard -> Puddle
	if current_map != 0:
		generateEnvironments()
	
		#Generate Zones
		var tempDim = MAP_DIMS[current_map]
		zone_list.resize(tempDim)
		for i in range(tempDim):
			zone_list[i] = [0]
			zone_list[i].resize(tempDim)
			for j in range(tempDim): 
				"""
				var temp = zone.instantiate()
				temp.setParams(current_map, environments[i][j], [pool_map[i][j], plant_map[i][j], hazard_map[i][j]], map_seed
				 + hash(str(current_map) + str(i) + str(j)), 
				+ ceil(randf_range(0.5, 1.5) * ENTITY_MAX[current_map] * ENTITY_MODIFIERS[environments[i][j]]), 
				Vector2(ZONE_WIDTH[current_map]*i, ZONE_HEIGHT[current_map]*j))
				"""
				
				var temp = ""#str(current_map) + str(environments[i][j]) + str([pool_map[i][j], plant_map[i][j], hazard_map[i][j]])
				temp += str(map_seed + hash(str(current_map) + str(i) + str(j))) + " "
				temp += str(ceil(randf_range(0.5, 1.5) * ENTITY_MAX[current_map] * ENTITY_MODIFIERS[environments[i][j]]))
				#temp += str(Vector2(ZONE_WIDTH[current_map]*i, ZONE_HEIGHT[current_map]*j)) 
				 
				zone_list[i][j] = temp
	else:
		#Generate Zones
		var tempDim = MAP_DIMS[current_map]
		zone_list.resize(tempDim)
		for i in range(tempDim):
			zone_list[i] = [0]
			zone_list[i].resize(tempDim)
			for j in range(tempDim): 
				"""
				var temp = zone.instantiate()
				temp.setParams(current_map, 0, [0, 0, 0], map_seed
				 + hash(str(current_map) + str(i) + str(j)), 
				+ ceil(randf_range(0.5, 1.5) * ENTITY_MAX[current_map] * ENTITY_MODIFIERS[0]), 
				Vector2(ZONE_WIDTH[current_map]*i, ZONE_HEIGHT[current_map]*j))
				"""
				
				var temp = ""#str(current_map) + str(environments[i][j]) + str([pool_map[i][j], plant_map[i][j], hazard_map[i][j]])
				temp += str(map_seed + hash(str(current_map) + str(i) + str(j))) + " "
				temp += str(ceil(randf_range(0.5, 1.5) * ENTITY_MAX[current_map] * ENTITY_MODIFIERS[0]))
				#temp += str(Vector2(ZONE_WIDTH[current_map]*i, ZONE_HEIGHT[current_map]*j)) 
				 
				zone_list[i][j] = temp
	
	#Generate Events
	generateEvents()
			
func generateEnvironments() -> void:
	var tempDims = MAP_DIMS[current_map]
	var playerSpawn = Vector2(tempDims / 2, tempDims / 2) 
	
	#I think this would be a more optimized implementation of this. Should look into possible algorithms for it later
	#Like creating a map of available spots instead of going around blind in the dark 
	"""
	var EnvironmentSources = [[]]
	EnvironmentSources.resize(MAP_DIMS[current_map])
	for x in EnvironmentSources:
		EnvironmentSources.resize(MAP_DIMS[current_map])
		EnvironmentSources.fill(0)
	"""
	#This will work for now. Maybe consider changing it later
	EnvironmentSources = []
	EnvironmentTypes = [] #0: Default, 1: Pool, 2: Plant, 3: Hazard
	
	#Don't want hazard to spawn too close to spawn initially for early maps.
	#Yet we do want hazard to be able to be placed.
	pool_map.resize(tempDims)
	for i in range(tempDims):
		pool_map[i] = [0.0]
		pool_map[i].resize(tempDims)
		for j in range(tempDims):
			pool_map[i][j] = 0
	plant_map.resize(tempDims)
	for i in range(tempDims):
		plant_map[i] = [0.0]
		plant_map[i].resize(tempDims)
		for j in range(tempDims):
			plant_map[i][j] = 0
	hazard_map.resize(tempDims)
	for i in range(tempDims):
		hazard_map[i] = [0.0]
		hazard_map[i].resize(tempDims)
		for j in range(tempDims):
			hazard_map[i][j] = 0

	if current_map == 1:
		for i in 2:
			var index = 0
			var HazSource
			while index < 50: #Exit if cannot find a spot in a number of iterations. 
				HazSource = Vector2(randi_range(0, tempDims), randi_range(0, tempDims))
				if HazSource.distance_squared_to(playerSpawn) > 8:
					
					#Check for overlaps in environment
					"""
					var overlap = false
					for e in EnvironmentSources:
						if HazSource.distance_squared_to(e) < 4:
							overlap = true 
							break
					"""
					#Gonna use one of these instead
					if not EnvironmentSources.any(func(e : Vector2): return HazSource.distance_squared_to(e) < 4):
						break
				index += 1
			EnvironmentSources.append(HazSource)
			EnvironmentTypes.append(3)
			populateEnvWeights(3, HazSource, playerSpawn)
		var temp = [1,1,2,2]
		temp.shuffle()
		for i in temp:
			var index = 0
			var EnvSource
			while index < 50: #Exit if cannot find a spot in a number of iterations. 
				EnvSource = Vector2(randi_range(0, tempDims), randi_range(0, tempDims))
				
				if EnvSource.distance_squared_to(playerSpawn) > 4:
					
					#Check for overlaps in environment
					"""
					var overlap = false
					for e in EnvironmentSources:
						if HazSource.distance_squared_to(e) < 4:
							overlap = true 
							break
					"""
					#Gonna use one of these instead
					if not EnvironmentSources.any(func(e : Vector2): return EnvSource.distance_squared_to(e) < 4):
						break
				index += 1
			EnvironmentSources.append(EnvSource)
			EnvironmentTypes.append(i)
			populateEnvWeights(i, EnvSource, playerSpawn)
	else:
		#Need custom code for maps 4+ when we get to it
		var tempStrength = 1 + 0.25 * current_map 
		var tempEnvs = []
		var tempMaxEnv = ENV_MAX[current_map]
		tempEnvs.resize(tempMaxEnv*3)
		for i in range(3):
			for j in range(tempMaxEnv):
				tempEnvs[tempMaxEnv * i + j] = i+1
			#Example for Map 1 (env = 2)
			#temp[2*i] = i #0, 2, 4
			#temp[2*i+1] = i #1, 3, 5 
		tempEnvs.shuffle()
		for i in tempEnvs:
			var index = 0
			var EnvSource
			while index < 50: #Exit if cannot find a spot in a number of iterations. 
				"""
				var tempnum = randi_range(0, 3)
				match tempnum:
					0:
						EnvSource = Vector2(randi_range(0, 0), randi_range(0, 0))
					1:
						EnvSource = Vector2(randi_range(tempDims, tempDims), randi_range(tempDims, tempDims))
					2:
						EnvSource = Vector2(randi_range(0, 0), randi_range(tempDims, tempDims))
					3:
						EnvSource = Vector2(randi_range(tempDims, tempDims), randi_range(0, 0))
				"""
				EnvSource = Vector2(randi_range(0, tempDims), randi_range(0, tempDims))
				#Hey dumbass, ever realize that spawn is NEVER on the edges?
				#var mapTemp = []
				#for s in sources:
					#mapTemp.append(playerSpawn.distance_squared_to(s))
				if EnvSource.distance_squared_to(playerSpawn) > 4:
					var sources
					if EnvSource.x <= tempDims/2:
						if EnvSource.y <= tempDims/2:
							sources = [EnvSource, EnvSource + Vector2(tempDims, tempDims), EnvSource + Vector2(0, tempDims), EnvSource + Vector2(tempDims, 0)]
						else:
							sources = [EnvSource, EnvSource + Vector2(tempDims, -tempDims), EnvSource + Vector2(0, -tempDims), EnvSource + Vector2(tempDims, 0)]
					else:
						if EnvSource.y <= tempDims/2:
							sources = [EnvSource, EnvSource + Vector2(-tempDims, tempDims), EnvSource + Vector2(0, tempDims), EnvSource + Vector2(-tempDims, 0)]
						else:
							sources = [EnvSource, EnvSource + Vector2(-tempDims, -tempDims), EnvSource + Vector2(0, -tempDims), EnvSource + Vector2(-tempDims, 0)]
					
					#Check for overlaps in environment
					"""
					var overlap = false
					for e in EnvironmentSources:
						print(index, " " , EnvSource.distance_squared_to(e))
						if EnvSource.distance_squared_to(e) < 4:
							overlap = true 
							break
					"""
					#Gonna use one of these instead
					#Nevermind I CANT because SOMEONE decided to make the code too stupid
					#Actually I still can it's just ugly as fuck
					#Actually it's not that bad, but it basically multiplies this functions time by 4 fyi for a very rare case 
					if not EnvironmentSources.any(func(e : Vector2): 
						return sources.any(func(s : Vector2): return s.distance_squared_to(e) < 4)):
						break
					
				index += 1
				if (index == 50):
					print("Limit Exceeded: ", i)
			EnvironmentSources.append(EnvSource)
			EnvironmentTypes.append(i)
			populateEnvWeights(i, EnvSource, playerSpawn, tempStrength)
	environments.resize(tempDims)
	for i in range(tempDims):
		environments[i] = [0]
		environments[i].resize(tempDims)
		for j in range(tempDims):
			if pool_map[i][j] >= plant_map[i][j]:
				if pool_map[i][j] >= hazard_map[i][j]:
					if pool_map[i][j] >= 0.5:
						environments[i][j] = 1
					else:
						environments[i][j] = 0
				else:
					if hazard_map[i][j] >= 0.5:
						environments[i][j] = 3
					else:
						environments[i][j] = 0
			else:
				if plant_map[i][j] >= hazard_map[i][j]:
					if plant_map[i][j] >= 0.5:
						environments[i][j] = 2
					else:
						environments[i][j] = 0
				else:
					if hazard_map[i][j] >= 0.5:
						environments[i][j] = 3
					else:
						environments[i][j] = 0
		
#0, 1, 2, 3 : default, pool, plant, hazard
#Add a strength just incase we want to later change the strength. I think it should be fine for now.
func populateEnvWeights(env: int, source: Vector2, _playerSource: Vector2, strength = 1):
	#Why the fuck do we need player source?
	
	#Since they're all basic types, I'm pretty sure I can't do a reference so I'll have to do it this way.
	var tempDim = MAP_DIMS[current_map]
	strength *= sqrt(current_map) * randf_range(0.75, 1.25)
	var sources
	if source.x <= tempDim/2:
		if source.y <= tempDim/2:
			sources = [source, source + Vector2(tempDim, tempDim), source + Vector2(0, tempDim), source + Vector2(tempDim, 0)]
		else:
			sources = [source, source + Vector2(tempDim, -tempDim), source + Vector2(0, -tempDim), source + Vector2(tempDim, 0)]
	else:
		if source.y <= tempDim/2:
			sources = [source, source + Vector2(-tempDim, tempDim), source + Vector2(0, tempDim), source + Vector2(-tempDim, 0)]
		else:
			sources = [source, source + Vector2(-tempDim, -tempDim), source + Vector2(0, -tempDim), source + Vector2(-tempDim, 0)]
	match(env):
		1:
			for i in range(tempDim):
				for j in range(tempDim): 
					#GUH 3 FOR LOOPS
					var mapTemp = []
					for s in sources:
						mapTemp.append(Vector2(i,j).distance_squared_to(s))
					
					pool_map[i][j] += 1.0 / (1 + mapTemp.min() / strength)	
			
		2:
			for i in range(tempDim):
				for j in range(tempDim): 
					var mapTemp = []
					for s in sources:
						mapTemp.append(Vector2(i,j).distance_squared_to(s))
						
					plant_map[i][j] += 1.0 / (1 + mapTemp.min() / strength)
		3:
			for i in range(tempDim):
				for j in range(tempDim): 
					var mapTemp = []
					for s in sources:
						mapTemp.append(Vector2(i,j).distance_squared_to(s))
						
					#Make hazard map smaller than the rest
					hazard_map[i][j] += 1.0 / (1 + mapTemp.min() / (strength * 0.75))

					
func generateEvents() -> void:
	var tempDim = MAP_DIMS[current_map]
	var playerSpawn = Vector2(tempDim / 2, tempDim / 2) 
	var event_ids = [[0],[0],[0],[0],[0],[0]]
	var MAP_EVENTS;
	
	#Need prob gonna need custom code for each event generation
	#Let's worry about that later
	match current_map:
		1:
			MAP_EVENTS = [peaceful_event]
			event_ids = [0,1,2]
		2:
			MAP_EVENTS = [peaceful_event]
			event_ids = [0,1,2,3,4,5]
		3:
			MAP_EVENTS = [peaceful_event]
			event_ids = [0,1,2,3,4,5,6,7,8]
		4:
			
			MAP_EVENTS = [peaceful_event]
			event_ids = [0,1,2,3,4,5]
		5:
			MAP_EVENTS = [peaceful_event]
			event_ids = [0,1,2,3,4,5]
		6:
			MAP_EVENTS = [peaceful_event]
			event_ids = [0,1,2,3,4,5]
	var tempRange = range(EVENT_MAX[current_map])#range(MAP_EVENTS.size())
	tempRange.shuffle()
	#I would like there to be a random amount of events as well but let's do that when we have more events
	#randi_range(ceil(EVENT_MAX[current_map]), EVENT_MAX[current_map])
	#Something like that function
	var temp_index = 0
	var temp_max = EVENT_MAX[current_map]
	var forced_location_starts = [0, 0, 0]
	for i in range(temp_max):
		#Modulus is to prevent accidental overflow
		var event_index = tempRange[(i+temp_index)%temp_max]
		#Avoid duplicates if possible
		while events_visited.find(event_ids[event_index]) != -1:
			temp_index += 1
			event_index = tempRange[(i+temp_index)%temp_max]
			#This code can also cause only duplicates of new if not enough events
			if temp_index > temp_max:
				temp_index += 1
				break
		
		"""
		var tempEvent = MAP_EVENTS[event_index].instantiate()
		"""
		
		#Event with a forced location has to be placed within 1 block away from the source.
		#use a randi_range(-1, 1) on the source vector
		#Either check the forced variable from here, or make anohter array for it (prob just check tbh)
		
		var forced_location = 1#tempEvent.forced_location
		var tempSource
		var eventPosition
		if forced_location != 0:
			#Find a new environment center with a matching envionment
			var tempSpot = EnvironmentTypes.find(forced_location, forced_location_starts[forced_location-1])
			#If not, start from 0
			if tempSpot == -1:
				tempSpot = EnvironmentTypes.find(forced_location, 0)
			#If this is somehow still impossible, place it anywhere.
			if tempSpot == -1:
				tempSpot = randi_range(0, ENV_MAX[current_map]*3 - 1)
				forced_location_starts[forced_location-1] = EnvironmentTypes.size() - 1
			else:
				forced_location_starts[forced_location-1] = tempSpot + 1
				print(forced_location_starts[forced_location-1])
			tempSource = EnvironmentSources[tempSpot]
			var index = 0
			while index < 10: #Exit if cannot find a spot in a number of iterations. 
				eventPosition = Vector2(int(tempSource.x + randi_range(-1,1)) % MAP_DIMS[current_map], int(tempSource.y + randi_range(-1,1) % MAP_DIMS[current_map]))
				if eventPosition.distance_squared_to(playerSpawn) > 4:
					
					var sources
					if eventPosition.x <= tempDim/2:
						if eventPosition.y <= tempDim/2:
							sources = [eventPosition, eventPosition + Vector2(tempDim, tempDim), eventPosition + Vector2(0, tempDim), eventPosition + Vector2(tempDim, 0)]
						else:
							sources = [eventPosition, eventPosition + Vector2(tempDim, -tempDim), eventPosition + Vector2(0, -tempDim), eventPosition + Vector2(tempDim, 0)]
					else:
						if eventPosition.y <= tempDim/2:
							sources = [eventPosition, eventPosition + Vector2(-tempDim, tempDim), eventPosition + Vector2(0, tempDim), eventPosition + Vector2(-tempDim, 0)]
						else:
							sources = [eventPosition, eventPosition + Vector2(-tempDim, -tempDim), eventPosition + Vector2(0, -tempDim), eventPosition + Vector2(-tempDim, 0)]
					
					if not event_positions.any(func(e : Vector2): 
						return sources.any(func(s : Vector2): return s.distance_squared_to(e) <= 1)):
						break
					#if not event_positions.any(func(e : Vector2): 
					#	return eventPosition.distance_squared_to(e) <= 1):
					#	break
				index += 1
			#Lower the requirements if not found
			if index >= 10:
				while index < 20: #Exit if cannot find a spot in a number of iterations. 
					eventPosition = Vector2(int(tempSource.x + randi_range(-1,1)) % MAP_DIMS[current_map], int(tempSource.y + randi_range(-1,1) % MAP_DIMS[current_map]))
					if eventPosition.distance_squared_to(playerSpawn) > 2:
						
						var sources
						if eventPosition.x <= tempDim/2:
							if eventPosition.y <= tempDim/2:
								sources = [eventPosition, eventPosition + Vector2(tempDim, tempDim), eventPosition + Vector2(0, tempDim), eventPosition + Vector2(tempDim, 0)]
							else:
								sources = [eventPosition, eventPosition + Vector2(tempDim, -tempDim), eventPosition + Vector2(0, -tempDim), eventPosition + Vector2(tempDim, 0)]
						else:
							if eventPosition.y <= tempDim/2:
								sources = [eventPosition, eventPosition + Vector2(-tempDim, tempDim), eventPosition + Vector2(0, tempDim), eventPosition + Vector2(-tempDim, 0)]
							else:
								sources = [eventPosition, eventPosition + Vector2(-tempDim, -tempDim), eventPosition + Vector2(0, -tempDim), eventPosition + Vector2(-tempDim, 0)]
						
						if not event_positions.any(func(e : Vector2): 
							return sources.any(func(s : Vector2): return s.distance_squared_to(e) <= 1)):
							break
					index += 1
			if index == 20:
				print("limit reached")
			#Choose a random spot if not found
			if index >= 20:
				while index < 30: #Exit if cannot find a spot in a number of iterations. 
					eventPosition = Vector2(randi_range(0, tempDim), randi_range(0, tempDim))
					if eventPosition.distance_squared_to(playerSpawn) > 2:
						
						var sources
						if eventPosition.x <= tempDim/2:
							if eventPosition.y <= tempDim/2:
								sources = [eventPosition, eventPosition + Vector2(tempDim, tempDim), eventPosition + Vector2(0, tempDim), eventPosition + Vector2(tempDim, 0)]
							else:
								sources = [eventPosition, eventPosition + Vector2(tempDim, -tempDim), eventPosition + Vector2(0, -tempDim), eventPosition + Vector2(tempDim, 0)]
						else:
							if eventPosition.y <= tempDim/2:
								sources = [eventPosition, eventPosition + Vector2(-tempDim, tempDim), eventPosition + Vector2(0, tempDim), eventPosition + Vector2(-tempDim, 0)]
							else:
								sources = [eventPosition, eventPosition + Vector2(-tempDim, -tempDim), eventPosition + Vector2(0, -tempDim), eventPosition + Vector2(-tempDim, 0)]
						
						if not event_positions.any(func(e : Vector2): 
							return sources.any(func(s : Vector2): return s.distance_squared_to(e) <= 1)):
							break
					index += 1
			if index == 30:
				print("overdone")
		else:
			var index = 0
			while index < 20: #Exit if cannot find a spot in a number of iterations. 
				eventPosition = Vector2(randi_range(0, tempDim), randi_range(0, tempDim))
				if eventPosition.distance_squared_to(playerSpawn) > 2:
					
					if not event_positions.any(func(e : Vector2): return eventPosition.distance_squared_to(e) <= 1):
						break
				index += 1
		#If the zone doesn't already have an event, create the event and add it to the zone.
		#This shouldn't not trigger, but it's there just in case.
		event_positions.append(eventPosition)
		"""
		if not zone[eventPosition.x][eventPosition.y].hasEvent:
			event_positions.append(eventPosition)
			tempEvent.position = (eventPosition + Vector2(0.5,0.5)) * Vector2(ZONE_WIDTH[current_map], ZONE_HEIGHT[current_map])
			zone[eventPosition.x][eventPosition.y].hasEvent = true
			zone[eventPosition.x][eventPosition.y].eventRefactor()
			#Might need to call defer on these two
			add_child(tempEvent)
			zone[eventPosition.x][eventPosition.y].eventReference = tempEvent.get_path()
		"""	
		 	
		#used_event_array.append(tempEvent)

func backgroundGenerateMap() -> void:
	
	for i in range(MAP_DIMS[current_map]):
		for j in range(MAP_DIMS[current_map]): 
			var temp = zone.instantiate()
			temp.setParams(current_map, 0, 0, 0, Vector2(i, j))
			next_zone_list.append(temp) 
