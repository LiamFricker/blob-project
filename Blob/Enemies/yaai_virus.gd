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
func _matchAngleToOrbital(travelAng : float) -> void:
	match orbitals_alive:
		1:
			pass
