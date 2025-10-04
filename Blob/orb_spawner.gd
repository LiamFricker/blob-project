extends Node2D

const CHILD_OFFSET = 3

@export var orb : PackedScene
@export var orb_max : int = 100
@export var near_orb_max : int = 20
@export var far_orb_max : int = 40

@export var despawn_dist_squared : float = 10000 * 9
@export var spawn_dist : float = 50 * 3

@export var near_orb_weight : float = 1.0
@export var far_orb_weight : float = 1.0
@export var spawn_orb_weight : float = 1.0

@export var weight : float = 1.0
@export var orb_size : float = 0.5
#Not sure if I need this but just keep it here
var size : float = 1.0
@export var spawn_interval_reduction : float = 1.0

var tween

var center : Vector2 = Vector2.ZERO

var used_orb_list = []
var unused_orb_list = []

var near_orb_list = []
var near_orb_positions = PackedVector2Array()

var far_orb_list = []
var far_orb_positions = PackedVector2Array()

var rng = RandomNumberGenerator.new()

var centOffset = Vector2.ZERO

func _ready() -> void:
	unused_orb_list = range(orb_max)
	for i in unused_orb_list:
		var temp_orb = orb.instantiate()
		temp_orb.collect.connect(_orb_collected)
		temp_orb.disable()
		add_child(temp_orb)

func _orb_collected(id : int) -> void:
	#Fix this please
	#Need to also add checking everywhere that doesn't remove from near orb is near orb list is at 0. 
	#you know how much needs to be removed, so just remove the excess from far orb instead.
	#var newId = used_orb_list.find(id)
	used_orb_list.remove_at(used_orb_list.find(id))
	unused_orb_list.append(id)
	var find_orb = near_orb_list.find(id)
	if (find_orb != -1):
		get_child(near_orb_list[find_orb] + CHILD_OFFSET).disable()
		near_orb_list.remove_at(find_orb)
		near_orb_positions.remove_at(find_orb)
		return
	find_orb = far_orb_list.find(id)
	if (find_orb != -1):
		get_child(far_orb_list[find_orb] + CHILD_OFFSET).disable()
		far_orb_list.remove_at(find_orb)
		far_orb_positions.remove_at(find_orb)
	

func expand(newsize : int) -> void:
	var temp_size = unused_orb_list.size()
	var another_temp_size = used_orb_list.size()
	unused_orb_list.resize(newsize - another_temp_size)
	for i in range(another_temp_size + temp_size, newsize): 
		var temp_orb = orb.instantiate()
		temp_orb.collect.connect(_orb_collected)
		temp_orb.disable()
		add_child(temp_orb) 
		unused_orb_list[i - another_temp_size] = i

#Spawn orb (usually on enemy death)
func spawnOrbs(amount : int, spawncenter : Vector2) -> void:
	var small_orbs:int = 0
	var med_orbs:int = 0
	var big_orbs:int = 0
	if amount > 31: 
		@warning_ignore("integer_division")
		big_orbs = 3 + (amount - 32) / 4 
		med_orbs = 6 + int((amount % 4) > 1) 
		small_orbs = 8 + (amount % 2)
	elif amount > 19: 
		@warning_ignore("integer_division")
		big_orbs = (amount - 16) / 4 
		med_orbs = 4 + int((amount % 4) > 1) 
		small_orbs = 7 + (amount % 2)
	elif amount > 9:
		@warning_ignore("integer_division")
		med_orbs = (amount - 8) / 2 
		small_orbs = 8 + (amount % 2)
	else:
		small_orbs = amount
	
	#There's no scenario where this really should matter but if I die at least the code is here
	var total:int = small_orbs + med_orbs + big_orbs
	var bigOrbBonusWeight = 1.0
	var medOrbBonusWeight = 1.0
	var smallOrbBonusWeight = 1.0
	if total > orb_max:
		if big_orbs > orb_max:
			small_orbs = 0
			med_orbs = 0
			bigOrbBonusWeight = 1.0 + (big_orbs - orb_max) / (orb_max * 1.0)
			big_orbs = orb_max
		elif big_orbs + med_orbs > orb_max:
			small_orbs = 0
			medOrbBonusWeight = 1.0 + (med_orbs + big_orbs - orb_max) / (1.0 * (orb_max - big_orbs))
			med_orbs = orb_max - big_orbs
		else:
			smallOrbBonusWeight = 1.0 + (total - orb_max) / (1.0*(orb_max - big_orbs - med_orbs))
			small_orbs = orb_max - big_orbs - med_orbs
		
	#Yes there's so much repeated code here, I know it hurts me too but I CANNOT be arsed 
	#I can optimize this a bit if I remove from the max removed than 0. For example if we're removing 2, we would do 1, then 0
	#I don't think it's a huge issue but keep it in mind perhaps.
	var post_orb_count = used_orb_list.size() - orb_max + small_orbs + med_orbs + big_orbs
	if (post_orb_count <= near_orb_list.size()):
		for i in range(post_orb_count - 1, -1, -1):
			get_child(near_orb_list[i] + CHILD_OFFSET).disable()
			used_orb_list.remove_at(used_orb_list.find(near_orb_list[i]))
			unused_orb_list.append(near_orb_list[i])
			near_orb_list.remove_at(i)
			near_orb_positions.remove_at(i)
	elif (post_orb_count <= far_orb_list.size()):
		for i in range(post_orb_count - 1, -1, -1):
			get_child(far_orb_list[i] + CHILD_OFFSET).disable()
			used_orb_list.remove_at(used_orb_list.find(far_orb_list[i]))
			unused_orb_list.append(far_orb_list[i])
			far_orb_list.remove_at(i)
			far_orb_positions.remove_at(i)
	
	
	
	var range_bonus = 1 + 0.3 * med_orbs + 0.6 * big_orbs
	
	for i in range(big_orbs):
		var temp_id = unused_orb_list.pop_back()
		used_orb_list.append(temp_id)
		near_orb_list.append(temp_id) 
		var angle = i * 2*PI/big_orbs + rng.randf_range(0, 2*PI/big_orbs)
		var newPos = spawncenter + rng.randf_range(0, 5 * range_bonus) * Vector2(cos(angle), sin(angle))
		near_orb_positions.append(newPos)
		var newSize = 2.5 + rng.randi_range(0, 2) / 10.0
		var newColor = Color.from_hsv(rng.randf_range(0, 1), rng.randf_range(0.5, 1), rng.randf_range(0.5, 1))
		var tempChild = get_child(temp_id + CHILD_OFFSET)
		tempChild.create(weight*spawn_orb_weight*bigOrbBonusWeight, temp_id, newSize*orb_size, 2, newColor, newPos)
		tempChild.move(spawncenter + rng.randf_range(10 * range_bonus, 25 * range_bonus) * Vector2(cos(angle), sin(angle)), 2 + rng.randi_range(0, 8) / 10.0)

	for i in range(med_orbs):
		var temp_id = unused_orb_list.pop_back()
		used_orb_list.append(temp_id)
		near_orb_list.append(temp_id) 
		var angle = i * 2*PI/med_orbs + rng.randf_range(0, 2*PI/med_orbs)
		var newPos = spawncenter + rng.randf_range(0, 5 * range_bonus) * Vector2(cos(angle), sin(angle))
		near_orb_positions.append(newPos)
		var newSize = 1.2 + rng.randi_range(0, 2) / 10.0
		var newColor = Color.from_hsv(rng.randf_range(0, 1), rng.randf_range(0.5, 1), rng.randf_range(0.5, 1))
		var tempChild = get_child(temp_id + CHILD_OFFSET)
		tempChild.create(weight*spawn_orb_weight*medOrbBonusWeight, temp_id, newSize*orb_size, 1, newColor, newPos)
		tempChild.move(spawncenter + rng.randf_range(10 * range_bonus, 25 * range_bonus) * Vector2(cos(angle), sin(angle)), 1.75 + rng.randi_range(0, 6) / 10.0)
		
	for i in range(small_orbs):
		var temp_id = unused_orb_list.pop_back()
		used_orb_list.append(temp_id)
		near_orb_list.append(temp_id) 
		var angle = i * 2*PI/small_orbs + rng.randf_range(0, 2*PI/small_orbs)
		var newPos = spawncenter + rng.randf_range(0, 5 * range_bonus) * Vector2(cos(angle), sin(angle))
		near_orb_positions.append(newPos)
		var newSize = 0.6 + rng.randi_range(0, 2) / 10.0
		var newColor = Color.from_hsv(rng.randf_range(0, 1), rng.randf_range(0.5, 1), rng.randf_range(0.5, 1))
		var tempChild = get_child(temp_id + CHILD_OFFSET)
		tempChild.create(weight*spawn_orb_weight*smallOrbBonusWeight, temp_id, newSize*orb_size, 0, newColor, newPos)
		tempChild.move(spawncenter + rng.randf_range(10 * range_bonus, 25 * range_bonus) * Vector2(cos(angle), sin(angle)), 1.5 + rng.randi_range(0, 4) / 10.0)
#Check if orbs are past despawn dist, and if so, move them back in if they're far orbs
#If they're near orbs, remove them
#If far orbs are less than max, fill to max
func distCheck(newCent : Vector2) -> void:
	#print("Dist Check: ", center)
	center = newCent - centOffset
	#print("Center: ", center)
	return
	var temp_far_size = far_orb_list.size()
	for i in range(temp_far_size):
		if center.distance_squared_to(far_orb_positions[i]) > despawn_dist_squared:
			var angle = rng.randf_range(0, 2*PI)
			var newPos = center + rng.randf_range(spawn_dist * 0.75, spawn_dist * 2) * Vector2(cos(angle), sin(angle))
			far_orb_positions[i] = newPos
			var chosen_child = get_child(far_orb_list[i] + CHILD_OFFSET)
			chosen_child.position = newPos
			#I thought I'd randomize it but that seems like a waste. I'll just update the weight.
			chosen_child.value = weight 
			#get_child(far_orb_list[i] + CHILD_OFFSET).move(v : float, i : int, size : float, type : int, color : Color)
	
	for i in range(near_orb_list.size() - 1, -1, -1):
		if center.distance_squared_to(near_orb_positions[i]) > despawn_dist_squared:
			get_child(near_orb_list[i] + CHILD_OFFSET).disable()
			used_orb_list.remove_at(used_orb_list.find(near_orb_list[i]))
			unused_orb_list.append(near_orb_list[i])
			near_orb_list.remove_at(i)
			near_orb_positions.remove_at(i)
	
			
	
	if temp_far_size < far_orb_max:
		var diff = far_orb_max - temp_far_size
		var temp_use_size = used_orb_list.size()
		used_orb_list.resize(diff + temp_use_size)
		far_orb_list.resize(far_orb_max)
		far_orb_positions.resize(far_orb_max)
		
		var post_orb_count = used_orb_list.size() - orb_max + diff
		if (post_orb_count <= near_orb_list.size()):
			for i in range(post_orb_count - 1, -1, -1):
				get_child(near_orb_list[i] + CHILD_OFFSET).disable()
				used_orb_list.remove_at(used_orb_list.find(near_orb_list[i]))
				unused_orb_list.append(near_orb_list[i])
				near_orb_list.remove_at(i)
				near_orb_positions.remove_at(i)
		elif (post_orb_count <= far_orb_max):
			for i in range(post_orb_count - 1, -1, -1):
				get_child(far_orb_list[i] + CHILD_OFFSET).disable()
				used_orb_list.remove_at(used_orb_list.find(far_orb_list[i]))
				unused_orb_list.append(far_orb_list[i])
				far_orb_list.remove_at(i)
				far_orb_positions.remove_at(i)
		
		for i in range(temp_far_size, far_orb_max):
			var temp_id = unused_orb_list.pop_back()
			used_orb_list[temp_use_size + i - temp_far_size] = temp_id
			far_orb_list[i] = temp_id
			var angle = rng.randf_range(0, 2*PI)
			var newPos = center + rng.randf_range(spawn_dist * 0.75, spawn_dist * 2) * Vector2(cos(angle), sin(angle))
			far_orb_positions[i] = newPos
			var newSize = 0.7 + rng.randi_range(0, 6) / 10.0
			var newType = 1 if newSize > 1.1 else 0
			var newColor = Color.from_hsv(rng.randf_range(0, 1), rng.randf_range(0.5, 1), rng.randf_range(0.5, 1))
			get_child(temp_id + CHILD_OFFSET).create(newSize*weight*far_orb_weight, temp_id, newSize*orb_size, newType, newColor, newPos)

func _on_respawn_timer_timeout() -> void:
	var near_size = near_orb_list.size()
	if near_size > near_orb_max:
		#remove one
		get_child(near_orb_list[1] + CHILD_OFFSET).disable()
		used_orb_list.remove_at(used_orb_list.find(near_orb_list[1]))
		unused_orb_list.append(near_orb_list[1])
		near_orb_list.remove_at(1)
		near_orb_positions.remove_at(1)
	if near_size > 1:	
		#remove one
		get_child(near_orb_list[0] + CHILD_OFFSET).disable()
		used_orb_list.remove_at(used_orb_list.find(near_orb_list[0]))
		unused_orb_list.append(near_orb_list[0])
		near_orb_list.remove_at(0)
		near_orb_positions.remove_at(0)
	$RespawnTimer.wait_time = 4 / spawn_interval_reduction
	$RespawnTimer.start()
	$SpawnTimer.wait_time = 2 / spawn_interval_reduction
	$SpawnTimer.start()
	


func _on_spawn_timer_timeout() -> void:
	var near_size = near_orb_list.size()
	var post_orb_count = used_orb_list.size() - orb_max + 2
	if (post_orb_count <= near_orb_list.size()):
		for i in range(post_orb_count - 1, -1, -1):
			get_child(near_orb_list[i] + CHILD_OFFSET).disable()
			used_orb_list.remove_at(used_orb_list.find(near_orb_list[i]))
			unused_orb_list.append(near_orb_list[i])
			near_orb_list.remove_at(i)
			near_orb_positions.remove_at(i)
	elif (post_orb_count < far_orb_list.size()):
		for i in range(post_orb_count - 1, -1, -1):
			get_child(far_orb_list[i] + CHILD_OFFSET).disable()
			used_orb_list.remove_at(used_orb_list.find(far_orb_list[i]))
			unused_orb_list.append(far_orb_list[i])
			far_orb_list.remove_at(i)
			far_orb_positions.remove_at(i)
	
	if near_size < near_orb_max - 15:
		#spawn one
		if tween:
			tween.kill()
		tween = create_tween()
		tween.tween_callback(_spawn_orb).set_delay(0.75 / spawn_interval_reduction)
		tween.tween_callback(_spawn_orb).set_delay(0.75 / spawn_interval_reduction)
	elif near_size < near_orb_max - 5:
		#spawn one
		if tween:
			tween.kill()
		tween = create_tween()
		tween.tween_callback(_spawn_orb).set_delay(1 / spawn_interval_reduction)
	
	_spawn_orb()
	
func _spawn_orb() -> void:
	if used_orb_list.size() < orb_max:
		#spawn one
		#Test orb spawn
		#var aangle = rng.randf_range(0, 2*PI)
		#var nnewPos = center + rng.randf_range(spawn_dist * 0.5, spawn_dist * 0.9) * Vector2(cos(aangle), sin(aangle))
		#spawnOrbs(5, nnewPos)
		#return
		var temp_id = unused_orb_list.pop_back()
		used_orb_list.append(temp_id)
		near_orb_list.append(temp_id) 
		var angle = rng.randf_range(0, 2*PI)
		var newPos = center + rng.randf_range(spawn_dist * 0.1, spawn_dist * 0.9) * Vector2(cos(angle), sin(angle))
		near_orb_positions.append(newPos)
		var newSize = 0.6 + rng.randi_range(0, 6) / 10.0
		var newType = 1 if newSize > 1.1 else 0
		var newColor = Color.from_hsv(rng.randf_range(0, 1), rng.randf_range(0.5, 1), rng.randf_range(0.5, 1))
		get_child(temp_id + CHILD_OFFSET).create(newSize*weight*near_orb_weight, temp_id, newSize*orb_size, newType, newColor, newPos)

func _remove_near_orb() -> void:
	if near_orb_list.size() > 0:
		get_child(near_orb_list[0] + CHILD_OFFSET).disable()
		used_orb_list.remove_at(used_orb_list.find(near_orb_list[0]))
		unused_orb_list.append(near_orb_list[0])
		near_orb_list.remove_at(0)
		near_orb_positions.remove_at(0)

func changePosition(newpos : Vector2) -> void:
	position += newpos  
	centOffset += newpos	
	
