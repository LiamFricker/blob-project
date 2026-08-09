extends base_creature

#MAKE SURE THIS POSITION DOESN'T MOVE UNLESS IT NEEDS TO
#THAT INCLUDES DEATH KB

var orbital_states = [0,0,0,0]
var orbitals_alive = 0
var orbitals_dead = 4


func orbReady(orbit_id : int) -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

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
func _matchAngleToOrbital(travelAng : float) -> Node2D:
	match orbitals_alive:
		1:
			var orb_id = orbital_states.find(2)
			return _returnOrbitalRef(orb_id)
		2:
			#var orb_angles = [10.0, 10.0, 10.0, 10.0]
			
			var orb_id = orbital_states.find(2)
			const orb_path = "InnerNode/Sprite/Orbit"
			var orb_node : Node2D = get_node(orb_path + str(orb_id))
			var orb_angle : float = orb_node.position.angle()
			var old_orb_angle = orb_angle
			var old_orb_id = orb_id
			
			orb_id = orbital_states.find(2, orb_id)
			orb_node = get_node(orb_path + str(orb_id))
			orb_angle = orb_node.position.angle()
			#orb_angles[orb_id] = orb_angle
			
			if abs(angle_difference(orb_angle, travelAng)) > abs(angle_difference(old_orb_angle, travelAng)):
				orb_id = old_orb_id
			
			return _returnOrbitalRef(orb_id)
	return _returnOrbitalRef(0)
