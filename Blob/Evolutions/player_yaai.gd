extends "res://Blob/base_evo_dmg.gd"

const orb_base_angles = [-3*PI/4, -PI/4, PI/4, 3*PI/4]
var orbital_states = [0,0,0,0]
var orbitals_alive = 0
var orbitals_dead = 4

@export var cooldown = 2
@export var lifetime = 2.0

#var shot_queued : bool = false

@onready var Orbit1 = $Pivot/CentralOrbit/Orbit1
@onready var Orbit2 = $Pivot/CentralOrbit/Orbit2
@onready var Orbit3 = $Pivot/CentralOrbit/Orbit3
@onready var Orbit4 = $Pivot/CentralOrbit/Orbit4

func changeRot(newangle : float) -> void:
	$Pivot.rotation = newangle

func _ready() -> void:
	super()
	$CooldownTimer.start(cooldown)

func _setSize() -> void:
	var tempShape = CircleShape2D.new()
	tempShape.radius = size * 250
	$DetectionRange/CollisionShape2D.set_deferred("shape", tempShape)
	$Pivot/CentralOrbit.scale = size * Vector2(1,1)
	
	var orbit_rad = 32 * size
	$Pivot/CentralOrbit/Orbit1.position = orbit_rad * Vector2(-1,1)
	$Pivot/CentralOrbit/Orbit2.position = orbit_rad * Vector2(1,1)
	$Pivot/CentralOrbit/Orbit3.position = orbit_rad * Vector2(1,-1)
	$Pivot/CentralOrbit/Orbit4.position = orbit_rad * Vector2(-1,-1)
	
	super()

func _returnOrbitalRef(orb_id : int) -> Node2D:
	match orb_id:
		0:
			return Orbit1
		1:
			return Orbit2
		2:
			return Orbit3
		_:
			return Orbit4

#Make sure to check for orbitals == 0 beforehand
func _matchAngleToOrbital(travelAng : float, travelPos : Vector2) -> void: 
	var centRot = $Pivot/CentralOrbit.rotation + $Pivot.rotation
	var orb_id : int
	#print("orb states: ", orbital_states)
	#print("orb alive: ", orbitals_alive)
	match orbitals_alive:
		1:
			orb_id = orbital_states.find(2)
			
			"""
			orbital_states[orb_id] = 1
			
			var prog = orb_node.vanish()
			var orbPos = getPosition() + size * size * 32 * Vector2.from_angle(-orb_base_angles[orb_id] - centRot)
			print("this angle ", rad_to_deg(orb_base_angles[orb_id] + centRot))
			orb_chosen.initBullet(orbPos, travelPos, orb_node.rotation + centRot, prog, lifetime)
			"""
		_:
			#var orb_angles = [10.0, 10.0, 10.0, 10.0]
			#Enable this if you want to throw all at once.
			"""
			for i in range(orbitals_alive):
				var orb_id = orbital_states.find(2, orb_id)
				var orb_chosen = children_list[orb_id]
				var orb_node = _returnOrbitalRef(orb_id)
				
				orbital_states[orb_id] = 0
				
				var prog = orb_node.vanish()
				var orbPos = getPosition() + size * size * 32 * Vector2.from_angle(orb_base_angles[orb_id] + centRot)
				orb_chosen.initBullet(orbPos, travelPos, orb_node.rotation + centRot, prog)
			
			"""
			#travelAng -= centRot
			
			orb_id = orbital_states.find(2)
			
			var orb_angle : float = centRot - orb_base_angles[orb_id]
			var best_orb_angle = abs(angle_difference(orb_angle, travelAng))
			var best_orb_id = orb_id
			
			for i in range(orbitals_alive - 1):
				orb_id = orbital_states.find(2, orb_id+1)
				orb_angle = centRot - orb_base_angles[orb_id]
				#orb_angles[orb_id] = orb_angle
				
				orb_angle = abs(angle_difference(orb_angle, travelAng))
				if orb_angle < best_orb_angle:
					best_orb_id = orb_id
					best_orb_angle = orb_angle
			
			orb_id = best_orb_id
		
	var orb_chosen = children_list[orb_id]
	var orb_node = _returnOrbitalRef(orb_id)
	
	orbital_states[orb_id] = 1
		
	var prog = orb_node.vanish()
	
	var used_angle = centRot - orb_base_angles[orb_id]
	var orbPos = getPosition() + size * size * 45.25 * Vector2.from_angle(used_angle)
	print("this angle ", rad_to_deg(used_angle), " vs ", rad_to_deg(travelAng))
	orb_chosen.initBullet(orbPos, travelPos, -(centRot + orb_node.rotation), prog, lifetime)
			

func updateOrbID(orb_id : int, alive : bool = true) -> void:
	if alive:
		#print("ORB ID: ", orb_id)
		orbital_states[orb_id] = 2
		orbitals_alive += 1
		#if shot_queued:
		#	shot_queued = false
		_detectionCheck()
	else:
		#print("ORBBAL ID: ", orb_id)
		orbital_states[orb_id] = 0
		orbitals_dead += 1
		if $CooldownTimer.is_stopped():
			_on_cooldown_timeout()

func _throwOrbital(targetPos : Vector2) -> void:
	if orbitals_alive > 0:
		
		var travelAng : float = getPosition().angle_to_point(targetPos)
		
		_matchAngleToOrbital(travelAng, targetPos)
		orbitals_alive -= 1
	#else:
		#shot_queued = true

func _on_detection_range_area_entered(area: Area2D) -> void:
	_throwOrbital(area.getParent().getPosition())

func _on_detection_range_body_entered(body: Node2D) -> void:
	_throwOrbital(body.getPosition())

func _detectionCheck() -> void:
	var detectNode = $DetectionRange
	
	if (detectNode.has_overlapping_areas() or detectNode.has_overlapping_bodies()):
		var localAreas = detectNode.get_overlapping_areas()
		for a in localAreas:
			_on_detection_range_area_entered(a)
		
		var localBodies = detectNode.get_overlapping_bodies()
		for b in localBodies:
			_on_detection_range_body_entered(b)

func _on_cooldown_timeout() -> void:
	if orbitals_dead > 0:
		#print("orbal states: ", orbital_states)
		orbitals_dead -= 1
		var orb_id = orbital_states.find(0)
		orbital_states[orb_id] = 1 
		var orb_node = _returnOrbitalRef(orb_id)
		orb_node.create()
		
		$CooldownTimer.start(cooldown)

func connectBullet(bul : Node2D) -> void:
	bul.creation_complete.connect(updateOrbID)
	super(bul)
