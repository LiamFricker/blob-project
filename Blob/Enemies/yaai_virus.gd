extends base_creature

#MAKE SURE THIS POSITION DOESN'T MOVE UNLESS IT NEEDS TO
#THAT INCLUDES DEATH KB

var orbital_states = [0,0,0,0]
var orbitals_alive = 0
var orbitals_dead = 4

var update_count = 0

var previous_angles = [0.0, 1.0, -1.0]

@export var yaai_orbital : PackedScene

@onready var yaai_rng = RandomNumberGenerator.new()

#It shouldn't be changing children list
func addPosition(addpos : Vector2) -> void:
	position += addpos

func _returnOrbitalRef(orb_id : int) -> Node2D:
	match orb_id:
		0:
			return $InnerNode/Sprite/Orbit1.get_child(0)
		1:
			return $InnerNode/Sprite/Orbit2.get_child(0)
		2:
			return $InnerNode/Sprite/Orbit3.get_child(0)
		_:
			return $InnerNode/Sprite/Orbit4.get_child(0)

#Make sure to check for orbitals == 0 beforehand
func _matchAngleToOrbital(travelAng : float, travelPos : Vector2) -> void:
	match orbitals_alive:
		1:
			var orb_id = orbital_states.find(2)
			var orb_node : Node2D = get_node("InnerNode/Sprite/Orbit" + str(orb_id+1))
			var orb_chosen = _returnOrbitalRef(orb_id)
			
			orbital_states[orb_id] = 0
			
			orb_node.remove_child(orb_chosen)
			add_child(orb_chosen)
			orb_chosen.initSelf(orb_node.position, travelPos, orb_node.rotation, orb_node.z_index)
			
		_:
			#var orb_angles = [10.0, 10.0, 10.0, 10.0]
			
			var orb_id = orbital_states.find(2)
			const orb_path = "InnerNode/Sprite/Orbit"
			var orb_node : Node2D = get_node(orb_path + str(orb_id+1))
			var orb_angle : float = orb_node.position.angle()
			var best_orb_angle = orb_angle
			var best_orb_id = orb_id
			var best_orb_node = orb_node
			
			for i in range(orbitals_alive - 1):
				orb_id = orbital_states.find(2, orb_id)
				orb_node = get_node(orb_path + str(orb_id+1))
				orb_angle = orb_node.position.angle()
				#orb_angles[orb_id] = orb_angle
				
				if abs(angle_difference(orb_angle, travelAng)) < abs(angle_difference(best_orb_angle, travelAng)):
					best_orb_id = orb_id
					best_orb_node = orb_node
			
			var orb_chosen = _returnOrbitalRef(best_orb_id)
			orbital_states[best_orb_id] = 0
			best_orb_node.remove_child(orb_chosen)
			add_child(orb_chosen)
			orb_chosen.initSelf(best_orb_node.position, travelPos, best_orb_node.rotation, best_orb_node.z_index)
			

func _on_update_timer_timeout() -> void:
	if orbitals_alive != 0:
		update_count += 1
		if update_count % 7 == 0:
			_throwOrbital(2)
		elif update_count % 3 == 0:
			_throwOrbital(1)
		elif update_count % 2 == 0:
			_throwOrbital(0)
	
	if orbitals_dead != 0:
		orbitals_dead -= 1
		
		var orb_id = orbital_states.find(0)
		orbital_states[orb_id] = 1 
		
		var new_orbital = yaai_orbital.instantiate()
		new_orbital.setParams(base_damage, self, 0.0, 0.0, orb_id)
		new_orbital.creation_complete.connect(updateOrbID)
		var orb_node : Node2D = get_node("InnerNode/Sprite/Orbit" + str(orb_id+1))
		orb_node.add_child(new_orbital)
		children_list.append(new_orbital)

func updateOrbID(orb_id : int) -> void:
	orbital_states[orb_id] = 2
	orbitals_alive += 1
		
func _throwOrbital(distance : int) -> void:
	if state == DEAD:
		$UpdateTimer.stop()
		return
	print("throw orbital ", distance)
	orbitals_dead += 1
	orbitals_alive -= 1
	var travelAng : float = previous_angles[distance] + 0.25 + randf_range(0, 5.783)
	var travelPos : Vector2
	
	match distance:
		0:
			#This is just to prevent them from throwing all at the same spot and making a wall
			var travelDist = randi_range(150, 300)
			travelPos = travelDist * Vector2.from_angle(travelAng)
		1:
			var travelDist = randi_range(250, 700)
			travelPos = travelDist * Vector2.from_angle(travelAng)
		2:
			var travelDist = randi_range(600, 1300)
			travelPos = travelDist * Vector2.from_angle(travelAng)
	
	previous_angles[distance] = travelAng
	_matchAngleToOrbital(travelAng, travelPos)

func _handleRedDeath() -> void:
	dot_tween.tween_property(Sprite, "modulate", Color(1.0, 0, 0, 0), 1.0).set_delay(2.0)
