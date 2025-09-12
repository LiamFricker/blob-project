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

var playerReference# = $"Blob-Swim" 
var orbReference
var currentZone : Vector2i

var atBorder : bool = false

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
const ZONE_WIDTH = [200,1,1,1,1,1,1] #Width of each zone
const ZONE_HEIGHT = [100,1,1,1,1,1,1] #Width of each zone

#Number of each environment generated in a map. Final map is larger fyi. Maybe penultimate will be too.
const ENV_MAX = [0,2,3,4,2,2,2] 
#I'd prefer there to be more events but that's also more work to do. Maybe when we add more events to the game
const EVENT_MAX = [0,3,6,9,6,6,6] 
#It'd also be preferable not to repeat events
#Create an array that tracks the ids of the events visited, 
var events_visited = []

const ENTITY_MAX = [3,3,3,3,3,3]
const ENTITY_MODIFIERS = [1, 1.5, 1.4, 0.75]

var current_map = 0
enum {
	UNLOADED, #Map isn't loaded at all. Generate zone list map. (usually when starting game)
	NEXT_UNLOADED, #Next Map needs to be loaded
	WAITING, #Waiting on Player to reach size threshold to generate next map
	TRANSITION #Transitioning from one map to another or no map to a map
}
var MapState = UNLOADED

#Change this if speed is high relative to zone size
@export var mapUpdateTime: float = 2.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var rng = RandomNumberGenerator.new()
	playerReference = get_node("Blob-Swim")
	orbReference = get_node("orb_spawner")
	currentZone = Vector2i(MAP_DIMS[current_map] / 2, MAP_DIMS[current_map] / 2) 
	
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
	"""
	for i in range(MAP_DIMS[current_map]):
		zoneString += "\n["
		for j in range(MAP_DIMS[current_map]):
			zoneString += zone_list[i][j] + ", "	
	print(zoneString)
	"""
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

#Enter a zone position in [i][j] -> Vec2(j,i) form
#Returns the actual zone position in Vec2(x,y) form
func _calculateZonePosition(i : int, j : int) -> Vector2:
	var tempDim = MAP_DIMS[current_map] / 2
	return Vector2((i - tempDim)  * ZONE_WIDTH[current_map], (j - tempDim) * ZONE_HEIGHT[current_map])

#Load in all the zones initally
#Pass in an argument if the player starts somewhere that isn't spawn (for example, loading in from a save)
func _initializeZones(playerStartPos = Vector2(MAP_DIMS[current_map] / 2, MAP_DIMS[current_map] / 2) ) -> void:
	#On 3x3 map, load initalize all
	#On 6x6 map, enable load initalize 3x3 and only initalize and load 5x5.
	#Since we removed further functionality, do the same for 6x6.
	var tempDim = MAP_DIMS[current_map]
	for i in range(playerStartPos.y - 1, playerStartPos.y + 2):
		for j in range(playerStartPos.x - 1, playerStartPos.x + 2):
			zone_list[i % tempDim][j % tempDim].firstSpawnEntities()
	if current_map > 0:
		for i in range(playerStartPos.x - 2, playerStartPos.x + 3):
			zone_list[(playerStartPos.y - 2) % tempDim][i].firstSpawnEntities()
			zone_list[(playerStartPos.y + 2) % tempDim][i].firstSpawnEntities()
			zone_list[(playerStartPos.y - 2) % tempDim][i].disableEntities()
			zone_list[(playerStartPos.y + 2) % tempDim][i].disableEntities()
		for i in range(playerStartPos.x - 1, playerStartPos.x + 2):
			zone_list[i][(playerStartPos.y - 2) % tempDim].firstSpawnEntities()
			zone_list[i][(playerStartPos.y + 2) % tempDim].firstSpawnEntities()
			zone_list[i][(playerStartPos.y - 2) % tempDim].disableEntities()
			zone_list[i][(playerStartPos.y + 2) % tempDim].disableEntities()
			

#Replicate the formula you created before. Load only the zones that will be added and 
#load out only the zones that won't be added. Make sure to count for going over the border

#The positions given are to be reduced by zone, but remember that position(x,y) is different than zone[i][j]
#position (x,y) = zone[y][x]. You can create a function in cell that converts player pos to zone pos.  
func _loadZones(playerStartPos : Vector2i, playerEndPos : Vector2i) -> void:
	#On 3x3 map, don't load at all. Only handle the border translation logic.
	#On 6x6 map, do not handle the queue free all creatures logic. 
	#On anything larger, do all logic.
	#Make sure to only trigger on the outer edges rather than the whole outside.
	#If this is laggy, see if you can background load it (which may be problematic if it gets queued multiple times).
	#Only background load the 5x5+ part
	
	#Make sure to not trigger this function when playerStartPos == playerEndPos in the player call
	
	var temptemp = _handleBorderLogic(playerStartPos, playerEndPos)#playerStartPos.distance_squared_to(playerEndPos)
	var tempdist = temptemp.x
	var direction = Vector2(temptemp.y, temptemp.z)
	var tempDim = MAP_DIMS[current_map] 
	
	if tempdist <= 2:
		
		if tempdist != 2:
			if direction.x == 0:
				#Down
				if direction.y == 1:
					for i in range(playerEndPos.x - 1, playerEndPos.x + 2):
						zone_list[(playerEndPos.y + 1) % tempDim][i % tempDim].enableEntities()
						zone_list[(playerEndPos.y - 2) % tempDim][i % tempDim].disableEntities()
					for i in range(playerEndPos.x - 2, playerEndPos.x + 3):
						zone_list[(playerEndPos.y - 3) % tempDim][i % tempDim].freeEntities()
				#Up
				else:
					for i in range(playerEndPos.x - 1, playerEndPos.x + 2):
						zone_list[(playerEndPos.y - 1) % tempDim][i % tempDim].enableEntities()
						zone_list[(playerEndPos.y + 2) % tempDim][i % tempDim].disableEntities()
					for i in range(playerEndPos.x - 2, playerEndPos.x + 3):
						zone_list[(playerEndPos.y + 3) % tempDim][i % tempDim].freeEntities()
			else:
				#Right
				if direction.x == 1:
					for i in range(playerEndPos.y - 1, playerEndPos.y + 2):
						zone_list[i % tempDim][(playerEndPos.x + 1) % tempDim].enableEntities()
						zone_list[i % tempDim][(playerEndPos.x - 2) % tempDim].disableEntities()
					for i in range(playerEndPos.y - 2, playerEndPos.x + 3):
						zone_list[i % tempDim][(playerEndPos.x - 3) % tempDim].freeEntities()
				#Left
				else:
					for i in range(playerEndPos.y - 1, playerEndPos.y + 2):
						zone_list[i % tempDim][(playerEndPos.x - 1) % tempDim].enableEntities()
						zone_list[i % tempDim][(playerEndPos.x + 2) % tempDim].disableEntities()
					for i in range(playerEndPos.y - 2, playerEndPos.x + 3):
						zone_list[i % tempDim][(playerEndPos.x + 3) % tempDim].freeEntities()
		#Diagonal needs its seperate case
		else:
			if direction.y == 1:
				#Down Right
				if direction.x == 1:
					#Diagonal
					zone_list[(playerEndPos.y + 1) % tempDim][(playerEndPos.x + 1) % tempDim].enableEntities()
					zone_list[(playerEndPos.y - 2) % tempDim][(playerEndPos.x - 2) % tempDim].disableEntities()
					zone_list[(playerEndPos.y - 3) % tempDim][(playerEndPos.x - 3) % tempDim].freeEntities()
					#Down
					for i in range(playerEndPos.x - 1, playerEndPos.x + 1):
						zone_list[(playerEndPos.y + 1) % tempDim][i % tempDim].enableEntities()
						zone_list[(playerEndPos.y - 2) % tempDim][i % tempDim].disableEntities()
					for i in range(playerEndPos.x - 2, playerEndPos.x + 2):
						zone_list[(playerEndPos.y - 3) % tempDim][i % tempDim].freeEntities()
					#Right
					for i in range(playerEndPos.y, playerEndPos.y + 2):
						zone_list[i % tempDim][(playerEndPos.x + 1) % tempDim].enableEntities()
						zone_list[i % tempDim][(playerEndPos.x - 2) % tempDim].disableEntities()
					for i in range(playerEndPos.y - 1, playerEndPos.x + 3):
						zone_list[i % tempDim][(playerEndPos.x - 3) % tempDim].freeEntities()
				#Down Left
				else:
					#Diagonal
					zone_list[(playerEndPos.y + 1) % tempDim][(playerEndPos.x - 1) % tempDim].enableEntities()
					zone_list[(playerEndPos.y - 2) % tempDim][(playerEndPos.x + 2) % tempDim].disableEntities()
					zone_list[(playerEndPos.y - 3) % tempDim][(playerEndPos.x + 3) % tempDim].freeEntities()
					#Down
					for i in range(playerEndPos.x - 1, playerEndPos.x + 1):
						zone_list[(playerEndPos.y + 1) % tempDim][i % tempDim].enableEntities()
						zone_list[(playerEndPos.y - 2) % tempDim][i % tempDim].disableEntities()
					for i in range(playerEndPos.x - 2, playerEndPos.x + 2):
						zone_list[(playerEndPos.y - 3) % tempDim][i % tempDim].freeEntities()
					#Left
					for i in range(playerEndPos.y, playerEndPos.y + 2):
						zone_list[i % tempDim][(playerEndPos.x - 1) % tempDim].enableEntities()
						zone_list[i % tempDim][(playerEndPos.x + 2) % tempDim].disableEntities()
					for i in range(playerEndPos.y - 1, playerEndPos.x + 3):
						zone_list[i % tempDim][(playerEndPos.x + 3) % tempDim].freeEntities()
			else:
				#Up Right
				if direction.x == 1:
					#Diagonal
					zone_list[(playerEndPos.y - 1) % tempDim][(playerEndPos.x + 1) % tempDim].enableEntities()
					zone_list[(playerEndPos.y + 2) % tempDim][(playerEndPos.x - 2) % tempDim].disableEntities()
					zone_list[(playerEndPos.y + 3) % tempDim][(playerEndPos.x - 3) % tempDim].freeEntities()
					#Up
					for i in range(playerEndPos.x - 1, playerEndPos.x + 1):
						zone_list[(playerEndPos.y - 1) % tempDim][i % tempDim].enableEntities()
						zone_list[(playerEndPos.y + 2) % tempDim][i % tempDim].disableEntities()
					for i in range(playerEndPos.x - 2, playerEndPos.x + 2):
						zone_list[(playerEndPos.y + 3) % tempDim][i % tempDim].freeEntities()
					#Right
					for i in range(playerEndPos.y, playerEndPos.y + 2):
						zone_list[i % tempDim][(playerEndPos.x + 1) % tempDim].enableEntities()
						zone_list[i % tempDim][(playerEndPos.x - 2) % tempDim].disableEntities()
					for i in range(playerEndPos.y - 1, playerEndPos.x + 3):
						zone_list[i % tempDim][(playerEndPos.x - 3) % tempDim].freeEntities()
				#Up Left
				else:
					#Diagonal
					zone_list[(playerEndPos.y - 1) % tempDim][(playerEndPos.x - 1) % tempDim].enableEntities()
					zone_list[(playerEndPos.y + 2) % tempDim][(playerEndPos.x + 2) % tempDim].disableEntities()
					zone_list[(playerEndPos.y + 3) % tempDim][(playerEndPos.x + 3) % tempDim].freeEntities()
					#Up
					for i in range(playerEndPos.x - 1, playerEndPos.x + 1):
						zone_list[(playerEndPos.y - 1) % tempDim][i % tempDim].enableEntities()
						zone_list[(playerEndPos.y + 2) % tempDim][i % tempDim].disableEntities()
					for i in range(playerEndPos.x - 2, playerEndPos.x + 2):
						zone_list[(playerEndPos.y + 3) % tempDim][i % tempDim].freeEntities()
					#Left
					for i in range(playerEndPos.y, playerEndPos.y + 2):
						zone_list[i % tempDim][(playerEndPos.x - 1) % tempDim].enableEntities()
						zone_list[i % tempDim][(playerEndPos.x + 2) % tempDim].disableEntities()
					for i in range(playerEndPos.y - 1, playerEndPos.x + 3):
						zone_list[i % tempDim][(playerEndPos.x + 3) % tempDim].freeEntities()
	#If the distance is > sqrt2:
	#Print an error message. You're not supposed to cross zones that fast. Lower the time if it does.
	#Anyways...
	#Do a disable/deletion policy on everything in the start position that is over the 5x5/7x7 range 
	#but not within the new 3x3/5x5 range of the end pos. 
	#Then go ahead and enable/load everything in 3x3/5x5 though only if they are disabled/deleted (check zone's state)
	#You don't need to do this now, but you should get it done at some point
	else:
		pass
	
	
#playerEndPos HAS to be (% tempdim). If not, do it yourself. 
func _handleBorderLogic(playerStartPos : Vector2, playerEndPos : Vector2) -> Vector3:
	print("border logic check: ", playerStartPos, " ", playerEndPos)
	
	#Couple things to consider:
	#You need to handle the border translation logic for start pos as well
	
	#You also need to handle the border translation logic for going over the border
	#Earlier, you also need to factor in the equation that handles whether startpos and endpos features a jump over border
	#Perhaps it'll be your best bet to handle this stuff first before the previous logic
	#Ruminate on this and come back to it later.
	
	var tempDim = MAP_DIMS[current_map] 
	playerStartPos = playerStartPos.posmod(tempDim)
	var tempPEP = playerEndPos
	playerEndPos = playerEndPos.posmod(tempDim)
	
	#Check if playerEndPos is in the position being moved over, if so move the player as well.
	
	#Down the line you'll have to consider if you move multiple zones in one 
	#This can be problematic to most of this calculation, mainly the start pos stuff. 
	#It's preferably if you PREVENT that rather than accounting for that here.
	
	#I hate what I'm about to do here, but the rot inside my brain inside me forces me to 
	#minimal useless optimization
	#If you want to "optimize" it more, dumbass, you could go replace those variables in the for loops 
	#with their actual values since you know what they are at all times dumbass.
	 
	#So I forgot to consider corner when you're already in a corner, which can cause you to cross and end up 
	#in another border.
	#I'll probably forget more stuff so let's just scrap this idea already, comment it out.
	"""
	#Left Border
	if playerStartPos.x == 0:
		#Top Diagonal
		if playerStartPos.y == 0:
			#If endpos is not at a border 	
			if playerEndPos.x == 1 and playerEndPos.y == 1:
				#Return all borders back
				for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
					zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
				for i in range(playerStartPos.x, playerStartPos.x+2):	
					zone_list[tempDim - 1][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, tempDim - 1))
				return 2
			#Left
			elif playerEndPos.x == 0:
				#If it moved along the Left Border
				if playerEndPos.y == 1:	
					#Return Top Borders back
					for i in range(playerStartPos.x-1, playerStartPos.x+2):	
						zone_list[tempDim - 1][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, tempDim - 1))
					#Add bot border #int(playerStartPos.y+2) = 2
					zone_list[2 % tempDim][tempDim - 1].changePosition(_calculateZonePosition(-1, 2 % tempDim))
					return 1
				#Bottom Diagonal (Same border is impossible fyi)
				else:
					#Remove left top border
					for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
						zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
					#Add left bottom border
					for i in range(tempDim - 2, tempDim+1):	
						zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(-1, i % tempDim))
					#Remove top and add bottom border
					for i in range(playerStartPos.x, playerStartPos.x+2):	
						zone_list[tempDim - 1][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, tempDim - 1))
						zone_list[0][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, tempDim))
					#Teleport player over
					playerReference.changePosition(_calculateZonePosition(0, tempDim - 1))
					return 1
			#Top
			elif playerEndPos.y == 0:
				#If it moved along the Top Border
				if playerEndPos.x == 1:	
					#Return Left Borders back
					for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
						zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
					#Add right border #int(playerStartPos.x+2) = 2
					zone_list[tempDim - 1][2 % tempDim].changePosition(_calculateZonePosition(2 % tempDim, -1))
					return 1
				#Bottom Diagonal (Same border is impossible fyi)
				else:
					#Remove left and add right  border
					for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
						zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
						zone_list[i % tempDim][0].changePosition(_calculateZonePosition(tempDim, i % tempDim))
					#Remove top left
					for i in range(playerStartPos.x, playerStartPos.x+2):	
						zone_list[tempDim - 1][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, tempDim - 1))
					#Add top right
					for i in range(tempDim - 2, tempDim+1):	
						zone_list[tempDim - 1][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, -1))
					#Teleport player over
					playerReference.changePosition(_calculateZonePosition(tempDim - 1, 0))
					return 1
			#Bottom Right
			else:
				#Remove left and add right  border
				for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
					zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
					zone_list[i % tempDim][0].changePosition(_calculateZonePosition(tempDim, i % tempDim))
				#Remove top and add bottom border
				for i in range(playerStartPos.x, playerStartPos.x+2):	
					zone_list[tempDim - 1][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, tempDim - 1))
					zone_list[0][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, tempDim))		
				#Teleport player over
				playerReference.changePosition(_calculateZonePosition(tempDim - 1, tempDim - 1))
				return 2
		#Bottom Diagonal
		elif playerStartPos.y == tempDim - 1:
			#If endpos is not at a border 	
			if playerEndPos.x == 1 and playerEndPos.y == tempDim - 2:
				#Return all borders back
				
				for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
					zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
				for i in range(playerStartPos.x, playerStartPos.x+2):	
					zone_list[0][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, 0))
				return 2
			#Left
			elif playerEndPos.x == 0:
				#If it moved along the Left Border
				if playerEndPos.y == 1:	
					#Return Bottom Borders back
					for i in range(playerStartPos.x-1, playerStartPos.x+2):	
						zone_list[0][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, 0))
					#Add top border #int(playerStartPos.y-2) = tempDim - 3
					zone_list[(tempDim - 3) % tempDim][tempDim - 1].changePosition(_calculateZonePosition(-1, (tempDim - 3) % tempDim))
					return 1
				#Top Diagonal (Same border is impossible fyi)
				else:
					#Remove left top border
					for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
						zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
					#Add left bottom border
					for i in range(-1, 2):	
						zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(-1, i % tempDim))
					#Remove top and add bottom border
					for i in range(playerStartPos.x, playerStartPos.x+2):	
						zone_list[0][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, 0))
						zone_list[tempDim - 1][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, -1))
					#Teleport player over
					playerReference.changePosition(_calculateZonePosition(0, 0))
					return 1
			#Bottom
			elif playerEndPos.y == 0:
				#If it moved along the Bottom Border
				if playerEndPos.x == 1:	
					#Return Left Borders back
					for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
						zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
					#Add right border #int(playerStartPos.x+2) = 2
					zone_list[0][2 % tempDim].changePosition(_calculateZonePosition(2 % tempDim, tempDim))
					return 1
				#Bottom Right Diagonal (Same border is impossible fyi)
				else:
					#Remove left and add right  border
					for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
						zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
						zone_list[i % tempDim][0].changePosition(_calculateZonePosition(tempDim, i % tempDim))
					#Remove bottom left
					for i in range(playerStartPos.x, playerStartPos.x+2):	
						zone_list[0][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, 0))
					#Add bottom right
					for i in range(tempDim-2, tempDim+1):	
						zone_list[0][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, tempDim))
					#Teleport player over
					playerReference.changePosition(_calculateZonePosition(tempDim - 1, tempDim - 1))
					return 1
			#Bottom Right
			else:
				#Remove left and add right  border
				for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
					zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
					zone_list[i % tempDim][0].changePosition(_calculateZonePosition(tempDim, i % tempDim))
				#Remove bottom and add top border
				for i in range(playerStartPos.x, playerStartPos.x+2):	
					zone_list[0][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, 0))
					zone_list[tempDim - 1][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, -1))		
				#Teleport player over
				playerReference.changePosition(_calculateZonePosition(tempDim - 1, 0))
				return 2
		#Any ol' border along left. 
		else:
			#Conditions:
			#Straight Cross the border if endpos.x == tempDim -1
			#Diagonal Up Over Border if endpos.x == tempDim -1 && endpos.y == startpos.y - 1
			#Diagonal Down Over Border if endpos.x == tempDim -1 && endpos.y == startpos.y + 1
			#Diagonal Up Over Border into Corner if endpos.x == tempDim -1 && endpos.y == 0
			#Diagonal Down Over Border into Corner if endpos.x == tempDim -1 && endpos.y == tempDim - 1
			#Up/Down along Border if endpos.x == 0
			#Up into Corner if endpos.x == 0 && endpos.y == 0
			#Down into Corner if endpos.x == 0 && endpos.y == tempDim - 1
			#Diagonal Up Into Perpendicular Border if endpos.y == 0
			#Diagonal Down Into Perpendicular Border if endpos.y == tempDim - 1
			#Anything else
			if playerEndPos.x == tempDim - 1:
				if playerEndPos.y == 0:
					#Remove left border and add right border
					for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
						zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
					for i in range(playerEndPos.y - 1, playerEndPos.y+2):		
						zone_list[i % tempDim][0].changePosition(_calculateZonePosition(tempDim, i % tempDim))
					#Add Top Border
					for i in range(playerEndPos.x, playerEndPos.x+2):	
						zone_list[tempDim - 1][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, -1))
					#Teleport player over
					playerReference.changePosition(_calculateZonePosition(0, 0))
					return 2
				elif playerEndPos.y == tempDim - 1:
					#Remove left border and add right border
					for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
						zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
					for i in range(playerEndPos.y - 1, playerEndPos.y+2):		
						zone_list[i % tempDim][0].changePosition(_calculateZonePosition(tempDim, i % tempDim))
					#Add Bottom Border
					for i in range(playerEndPos.x, playerEndPos.x+2):	
						zone_list[0][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, tempDim))
					#Teleport player over
					playerReference.changePosition(_calculateZonePosition(0, tempDim-1))
					return 2
				elif playerEndPos.y == playerStartPos.y - 1 or playerEndPos.y == playerStartPos.y + 1:
					#Remove left border and add right border
					for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
						zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
					for i in range(playerEndPos.y - 1, playerEndPos.y+2):		
						zone_list[i % tempDim][0].changePosition(_calculateZonePosition(tempDim, i % tempDim))
					#Teleport player over
					playerReference.changePosition(_calculateZonePosition(0, playerEndPos.y))
					return 2
				else:
					#Remove left border and add right border
					for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
						zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
						zone_list[i % tempDim][0].changePosition(_calculateZonePosition(tempDim, i % tempDim))
					#Teleport player over
					playerReference.changePosition(_calculateZonePosition(0, playerStartPos.y))
					return 1
			elif playerEndPos.x == 0:
				if playerEndPos.y == 0:
					zone_list[(playerStartPos.y + 1) % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, (playerStartPos.y + 1) % tempDim))
					#Add Top Border
					for i in range(playerEndPos.x - 1, playerEndPos.x+2):	
						zone_list[tempDim - 1][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, -1))
					return 1
				elif playerEndPos.y == tempDim - 1:
					zone_list[(playerStartPos.y - 1) % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, (playerStartPos.y - 1) % tempDim))
					#Add Bottom Border
					for i in range(playerEndPos.x - 1, playerEndPos.x+2):	
						zone_list[0][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, tempDim))
					return 1
				elif playerEndPos.y == playerStartPos.y - 1:
					zone_list[(playerStartPos.y + 1) % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, (playerStartPos.y + 1) % tempDim))
					zone_list[(playerStartPos.y - 2) % tempDim][tempDim - 1].changePosition(_calculateZonePosition(-1, (playerStartPos.y - 2) % tempDim))
					return 1
				else:
					zone_list[(playerStartPos.y - 1) % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, (playerStartPos.y - 1) % tempDim))
					zone_list[(playerStartPos.y + 2) % tempDim][tempDim - 1].changePosition(_calculateZonePosition(-1, (playerStartPos.y + 2) % tempDim))
					return 1
			elif playerEndPos.y == 0:
				#Remove left border
				for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
					zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
				#Add Top Border
				for i in range(playerEndPos.x - 1, playerEndPos.x+2):	
					zone_list[tempDim - 1][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, -1))
				return 2
			elif playerEndPos.y == tempDim - 1:
				#Remove left border
				for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
					zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
				#Add Bottom Border
				for i in range(playerEndPos.x - 1, playerEndPos.x+2):	
					zone_list[0][i % tempDim].changePosition(_calculateZonePosition(i % tempDim, tempDim))
				return 2
			else:
				#Remove left border
				for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
					zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
				return playerStartPos.distance_squared_to(playerEndPos)
			
	#Right Border
	elif playerStartPos.x == tempDim - 1:
		#Top Diagonal
		if playerStartPos.y == 0:
			pass
		#Bottom Diagonal
		elif playerStartPos.y == tempDim - 1:
			pass
		#Normal
		else:
			pass
	#Top Border
	elif playerStartPos.y == 0:
		#Diagonal cannot trigger here
		pass
	#Bottom Border
	elif playerStartPos.y == tempDim - 1:
		#Diagonal cannot trigger here
		pass
	"""
	
	var at_border = false
	
	#Remove all the start borders.
	#Make sure to make the change position function change it deferred.
	#Left Border
	if playerStartPos.x == 0:
		#Top Diagonal
		if playerStartPos.y == 0:
			for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
				zone_list[tempDim - 1][i % tempDim].changePosition(_calculateZonePosition(tempDim - 1, (i+tempDim) % tempDim))
			for i in range(playerStartPos.x, playerStartPos.x+2):	
				zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(i % tempDim, tempDim - 1))
		#Bottom Diagonal
		elif playerStartPos.y == tempDim - 1:
			for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
				zone_list[tempDim - 1][i % tempDim].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
			for i in range(playerStartPos.x, playerStartPos.x+2):	
				zone_list[i % tempDim][0].changePosition(_calculateZonePosition(i % tempDim, 0))
		#Normal
		else:
			for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
				zone_list[tempDim - 1][i % tempDim].changePosition(_calculateZonePosition(tempDim - 1, i % tempDim))
	#Right Border
	elif playerStartPos.x == tempDim - 1:
		#Top Diagonal
		if playerStartPos.y == 0:
			for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
				zone_list[0][i % tempDim].changePosition(_calculateZonePosition(0, (i+tempDim) % tempDim))
			for i in range(playerStartPos.x-1, playerStartPos.x+1):	
				zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(i % tempDim, tempDim - 1))
		#Bottom Diagonal
		elif playerStartPos.y == tempDim - 1:
			for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
				zone_list[0][i % tempDim].changePosition(_calculateZonePosition(0, i % tempDim))
			for i in range(playerStartPos.x-1, playerStartPos.x+1):
				zone_list[i % tempDim][0].changePosition(_calculateZonePosition(i % tempDim, 0))
		#Normal
		else:
			for i in range(playerStartPos.y - 1, playerStartPos.y+2):	
				zone_list[0][i % tempDim].changePosition(_calculateZonePosition(0, i % tempDim))
	#Top Border
	elif playerStartPos.y == 0:
		#Diagonal cannot trigger here
		for i in range(playerStartPos.x - 1, playerStartPos.x+2):	
			zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(i % tempDim, tempDim - 1))
	#Bottom Border
	elif playerStartPos.y == tempDim - 1:
		#Diagonal cannot trigger here
		for i in range(playerStartPos.x - 1, playerStartPos.x+2):	
			zone_list[i % tempDim][0].changePosition(_calculateZonePosition(i % tempDim, 0))
	
	#Yes this'll cause bugs if you can move multiple zones but WHO CARES.
	#ACTUALLY IT WONT EVEN CAUSE BUGS DUMBASS
	#might as well check if they are in that zone though somehow.
	print(playerStartPos, " ", playerEndPos)
	if playerStartPos.distance_squared_to(playerEndPos) > 2:	
		print("this trigger")
		playerReference.changePosition(_calculateZonePosition(playerEndPos.x, playerEndPos.y), Vector2(ZONE_WIDTH[current_map], ZONE_HEIGHT[current_map]))
		orbReference.changePosition(Vector2(ZONE_WIDTH[current_map], ZONE_HEIGHT[current_map])* (playerEndPos-tempPEP))
		set_deferred("currentZone", playerEndPos)
	
	
	
	#Handle the border translation logic. Perhaps make its own function for it if you want.
	#Left Border
	if playerEndPos.x == 0:
		at_border = true
		#Top Diagonal
		if playerEndPos.y == 0:
			for i in range(playerEndPos.y - 1, playerEndPos.y+2):	
				zone_list[tempDim - 1][i % tempDim].changePosition(_calculateZonePosition(-1, i))# % tempDim
			for i in range(playerEndPos.x, playerEndPos.x+2):	
				zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(i % tempDim, -1))
		#Bottom Diagonal
		elif playerEndPos.y == tempDim - 1:
			for i in range(playerEndPos.y - 1, playerEndPos.y+2):	
				zone_list[tempDim - 1][i % tempDim].changePosition(_calculateZonePosition(-1, i)) #% tempDim
			for i in range(playerEndPos.x, playerEndPos.x+2):	
				zone_list[i % tempDim][0].changePosition(_calculateZonePosition(i % tempDim, tempDim))
		#Normal
		else:
			for i in range(playerEndPos.y - 1, playerEndPos.y+2):	
				zone_list[tempDim - 1][i % tempDim].changePosition(_calculateZonePosition(-1, i))# % tempDim
	#Right Border
	elif playerEndPos.x == tempDim - 1:
		at_border = true
		#Top Diagonal
		if playerEndPos.y == 0:
			for i in range(playerEndPos.y - 1, playerEndPos.y+2):	
				zone_list[0][i % tempDim].changePosition(_calculateZonePosition(tempDim, i))
			for i in range(playerEndPos.x-1, playerEndPos.x+1):	
				zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(i, -1))
		#Bottom Diagonal
		elif playerEndPos.y == tempDim - 1:
			for i in range(playerEndPos.y - 1, playerEndPos.y+2):	
				zone_list[0][i % tempDim].changePosition(_calculateZonePosition(tempDim, i))
			for i in range(playerEndPos.x-1, playerEndPos.x+1):	
				zone_list[i % tempDim][0].changePosition(_calculateZonePosition(i, tempDim))
		#Normal
		else:
			for i in range(playerEndPos.y - 1, playerEndPos.y+2):	
				zone_list[0][i % tempDim].changePosition(_calculateZonePosition(tempDim, i))
	#Top Border
	elif playerEndPos.y == 0:
		at_border = true
		#Diagonal cannot trigger here
		for i in range(playerEndPos.x - 1, playerEndPos.x+2):	
			zone_list[i % tempDim][tempDim - 1].changePosition(_calculateZonePosition(i % tempDim, -1))
	#Bottom Border
	elif playerEndPos.y == tempDim - 1:
		at_border = true
		#Diagonal cannot trigger here
		for i in range(playerEndPos.x - 1, playerEndPos.x+2):	
			zone_list[i % tempDim][0].changePosition(_calculateZonePosition(i % tempDim, tempDim))
	
	if at_border and not atBorder:
		atBorder = true
		#change this to 3 if it goes up too fast
		playerReference.changeCameraSpeed(true, 2 * mapUpdateTime)
	else:
		atBorder = false
		playerReference.changeCameraSpeed(false, mapUpdateTime)
	
	var sources
	if playerStartPos.x <= tempDim/2:
		if playerStartPos.y <= tempDim/2:
			sources = [playerStartPos, playerStartPos + Vector2(tempDim, tempDim), playerStartPos + Vector2(0, tempDim), playerStartPos + Vector2(tempDim, 0)]
		else:
			sources = [playerStartPos, playerStartPos + Vector2(tempDim, -tempDim), playerStartPos + Vector2(0, -tempDim), playerStartPos + Vector2(tempDim, 0)]
	else:
		if playerStartPos.y <= tempDim/2:
			sources = [playerStartPos, playerStartPos + Vector2(-tempDim, tempDim), playerStartPos + Vector2(0, tempDim), playerStartPos + Vector2(-tempDim, 0)]
		else:
			sources = [playerStartPos, playerStartPos + Vector2(-tempDim, -tempDim), playerStartPos + Vector2(0, -tempDim), playerStartPos + Vector2(-tempDim, 0)]
	var index = 0
	var minin = 10
	for i in 4:
		var newdist = playerEndPos.distance_squared_to(sources[i])
		if newdist < minin:
			minin = newdist
			index = i
	
	#WOW WASNT THAT SO MUCH EASIER THAN WRITING 1000 LINES OF NESTED IF BLOCKS?
	return Vector3(minin, playerEndPos.x - sources[index].x, playerEndPos.y-sources[index].y)

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
				#"""
				var temp = zone.instantiate()
				temp.setParams(current_map, environments[i][j], [pool_map[i][j], plant_map[i][j], hazard_map[i][j]], map_seed
				 + hash(str(current_map) + str(i) + str(j)), 
				+ ceil(randf_range(0.5, 1.5) * ENTITY_MAX[current_map] * ENTITY_MODIFIERS[environments[i][j]]), 
				_calculateZonePosition(i, j),
				Vector2(ZONE_WIDTH[current_map], ZONE_HEIGHT[current_map]))
				add_child(temp)
				#"""
				
				#var temp = ""#str(current_map) + str(environments[i][j]) + str([pool_map[i][j], plant_map[i][j], hazard_map[i][j]])
				#temp += str(map_seed + hash(str(current_map) + str(i) + str(j))) + " "
				#temp += str(ceil(randf_range(0.5, 1.5) * ENTITY_MAX[current_map] * ENTITY_MODIFIERS[environments[i][j]]))
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
				#"""
				var temp = zone.instantiate()
				temp.setParams(current_map, 0, [0, 0, 0], 0, 
				+ ceil(randf_range(0.5, 1.5) * ENTITY_MAX[current_map] * ENTITY_MODIFIERS[0]), 
				_calculateZonePosition(i, j),
				Vector2(ZONE_WIDTH[current_map], ZONE_HEIGHT[current_map]))
				
				add_child(temp)
				#"""
				
				
				#var temp = ""#str(current_map) + str(environments[i][j]) + str([pool_map[i][j], plant_map[i][j], hazard_map[i][j]])
				#temp += str(map_seed + hash(str(current_map) + str(i) + str(j))) + " "
				#temp += str(ceil(randf_range(0.5, 1.5) * ENTITY_MAX[current_map] * ENTITY_MODIFIERS[0]))
				#temp += _calculateZonePosition(i, j)#str(Vector2(ZONE_WIDTH[current_map]*i, ZONE_HEIGHT[current_map]*j)) 
				 
				zone_list[i][j] = temp
	
	#Generate Events
	if current_map != 0:
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

#Need to call this a bit earlier I think but it's good now
func _on_orb_timer_timeout() -> void:
	orbReference.distCheck($"Blob-Swim".position)


func _on_update_zone_timer_timeout():
	var playerPos = playerReference.position
	var currentZonePosition = _calculateZonePosition(currentZone.x, currentZone.y)
	var zoneBarrierX = ZONE_WIDTH[current_map]/2
	var zoneBarrierY = ZONE_HEIGHT[current_map]/2
	
	var updatezoneref = $UpdateZoneTimer
	print("update zone check: ", currentZone)
	#This logic only handles one zone at a time btw.
	if playerPos.x > currentZonePosition.x + zoneBarrierX:
		if playerPos.y > currentZonePosition.y + zoneBarrierY:
			_loadZones(currentZone, currentZone + Vector2i(1,1))
			currentZone.y = (currentZone.y + 1) % MAP_DIMS[current_map]
		elif playerPos.y < currentZonePosition.y - zoneBarrierY:
			_loadZones(currentZone, currentZone + Vector2i(1,-1))
			currentZone.y = (currentZone.y - 1) % MAP_DIMS[current_map]
		else:
			_loadZones(currentZone, currentZone + Vector2i(1,0))
		currentZone.x = (currentZone.x + 1) % MAP_DIMS[current_map]
		updatezoneref.wait_time = 2 * mapUpdateTime
	elif playerPos.x < currentZonePosition.x - zoneBarrierX:
		if playerPos.y > currentZonePosition.y + zoneBarrierY:
			_loadZones(currentZone, currentZone + Vector2i(-1,1))
			currentZone.y = (currentZone.y + 1) % MAP_DIMS[current_map]
		elif playerPos.y < currentZonePosition.y - zoneBarrierY:
			_loadZones(currentZone, currentZone + Vector2i(-1,-1))
			currentZone.y = (currentZone.y - 1) % MAP_DIMS[current_map]
		else:
			_loadZones(currentZone, currentZone + Vector2i(-1,0))
		currentZone.x = (currentZone.x - 1) % MAP_DIMS[current_map]
		updatezoneref.wait_time = 2 * mapUpdateTime
	elif playerPos.y > currentZonePosition.y + zoneBarrierY:
		_loadZones(currentZone, currentZone + Vector2i(0,1))
		currentZone.y = (currentZone.y + 1) % MAP_DIMS[current_map]
		updatezoneref.wait_time = 2 * mapUpdateTime
	elif playerPos.y < currentZonePosition.y - zoneBarrierY:
		_loadZones(currentZone, currentZone - Vector2i(0,1))
		currentZone.y = (currentZone.y - 1) % MAP_DIMS[current_map]
		updatezoneref.wait_time = 2 * mapUpdateTime
	else:
		updatezoneref.wait_time = mapUpdateTime
	updatezoneref.start()
	
