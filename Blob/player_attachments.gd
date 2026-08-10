extends Node2D

var id_dict : PackedInt32Array = []
@export var id_max : int = 5
@export var playerRef : Node2D

func _ready() -> void:
	id_dict.resize(id_max)

func triggerDamage(dmg : float) -> void:
	playerRef.takeDamage(dmg)

func attachSelf(newAttach : Node2D, ID : int) -> void:
	id_dict[ID] += 1
	call_deferred("add_child", newAttach)

func attachDeath(ID : int) -> void:
	if id_dict[ID]:
		id_dict[ID] -= 1

func idCount(ID : int) -> int:
	return id_dict[ID]
