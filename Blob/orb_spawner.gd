extends Node2D

const CHILD_OFFSET = 3

@export var orb : PackedScene
@export var orb_max : int = 100
@export var near_orb_max : int = 10
@export var far_orb_max : int = 40

@export var despawn_dist_squared : float = 2500
@export var spawn_dist : float = 30

@export var weight : float = 1.0
#Not sure if I need this but just keep it here
var size : float = 1.0

var center : Vector2 = Vector2.ZERO

var used_orb_list = []
var unused_orb_list = []

var near_orb_list = []
var near_orb_positions = PackedVector2Array()

var far_orb_list = []
var far_orb_positions = PackedVector2Array()

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	unused_orb_list = range(10)
	for i in unused_orb_list:
		var temp_orb = orb.instantiate()
		temp_orb.disable()
		add_child(temp_orb)

func expand(newsize : int) -> void:
	var temp_size = unused_orb_list.size()
	var another_temp_size = used_orb_list.size()
	unused_orb_list.resize(newsize - another_temp_size)
	for i in range(another_temp_size + temp_size, newsize): 
		var temp_orb = orb.instantiate()
		temp_orb.disable()
		add_child(temp_orb) 
		unused_orb_list[i - another_temp_size] = i
	
func spawn_orbs(amount : int, ) -> void:
	pass	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#Check if orbs are past despawn dist, and if so, move them back in if they're far orbs
#If they're near orbs, remove them
#If far orbs are less than max, fill to max
func distCheck(newCent : Vector2) -> void:
	center = newCent
	var temp_far_size = far_orb_list.size()
	for i in range(temp_far_size):
		if center.distance_squared_to(far_orb_positions[i]) > despawn_dist_squared:
			var angle = rng.randf_range(0, 2*PI)
			var newPos = rng.randf_range(spawn_dist, spawn_dist + 10) * Vector2(cos(angle), sin(angle))
			far_orb_positions[i] = newPos
			var chosen_child = get_child(far_orb_list[i] + CHILD_OFFSET)
			chosen_child.position = newPos
			#I thought I'd randomize it but that seems like a waste. I'll just update the weight.
			chosen_child.value = weight 
			#get_child(far_orb_list[i] + CHILD_OFFSET).move(v : float, i : int, size : float, type : int, color : Color)
	for i in range(near_orb_list.size()):
		if center.distance_squared_to(near_orb_positions[i]) > despawn_dist_squared:
			get_child(near_orb_list[i]).disable()
			used_orb_list.remove_at(used_orb_list.find(near_orb_list[i]))
			near_orb_list.remove_at(i)
			near_orb_positions.remove_at(i)
	
	if temp_far_size < far_orb_max:
		var diff = far_orb_max - temp_far_size
		var temp_use_size = used_orb_list.size()
		used_orb_list.resize(diff + temp_use_size)
		far_orb_list.resize(far_orb_max)
		for i in range(temp_far_size, far_orb_max):
			var temp_id = unused_orb_list.pop_back()
			used_orb_list[temp_use_size + i - temp_far_size] = temp_id
			far_orb_list[i] = temp_id
			var angle = rng.randf_range(0, 2*PI)
			var newPos = rng.randf_range(spawn_dist, spawn_dist + 10) * Vector2(cos(angle), sin(angle))
			far_orb_positions[i] = newPos
			var newSize = 0.7 + rng.randi_range(0, 6) / 10.0
			var newType = 1 if newSize > 1.1 else 0
			var newColor = Color.from_hsv(rng.randf_range(0, 1), rng.randf_range(0.5, 1), rng.randf_range(0.5, 1))
			get_child(temp_id).create(weight, temp_id, newSize, newType, newColor, newPos)

func _on_respawn_timer_timeout() -> void:
	var near_size = near_orb_list.size()
	if near_size > near_orb_max:
		#remove one
		pass
	#remove one
	
	$SpawnTimer.start()
	


func _on_spawn_timer_timeout() -> void:
	var near_size = near_orb_list.size()
	if near_size < near_orb_max:
		#spawn one
		pass
	#spawn one
