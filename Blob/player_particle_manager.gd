extends Node2D

#If this causes a notable memory issue, consider loading at runtime instead or loading when the upgrade is passed.
var rust_blade_particle = preload("res://Blob/Evolutions/Particles/rust_blade_particle.tscn")

@export var playerRef : Node2D

func _ready() -> void:
	$PlayerAfterImage.playerRef = playerRef

func addPosition(newpos) -> void:
	position += newpos
	$PlayerAfterImage.addOffset(newpos)

func createAfterImage(trail_decay : float, trail_int : float, trail_color : int, trail_count : int) -> void:
	$PlayerAfterImage.trailCreate(trail_decay, trail_int, trail_color, trail_count)

func endAfterImage() -> void:
	$PlayerAfterImage.trailStop()

func createParticle(particleID : int, pos : Vector2, rot : float, size : float, kwargs : Array) -> void:
	var tempParticle
	match particleID:
		0:
			tempParticle = rust_blade_particle.instantiate()
	
	
	tempParticle.setParams(pos, rot, size, kwargs)
	#call_deferred("add_child", tempParticle)
	add_child(tempParticle)
