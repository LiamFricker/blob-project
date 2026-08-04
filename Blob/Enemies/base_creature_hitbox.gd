extends Area2D

@export var parentInherit : bool = true

@export var parentRef : Node2D
@export var knockback : float = 0.0
@export var damage : float = 1.0
@export var attack_mods : Array = [false, false, false, false, false]
@export var ID : int = 0

func getAttackMod(num: int)-> bool:
	return attack_mods[num]
	
func getID() -> int:
	if parentInherit:	
		return parentRef.getID()
	else:
		return ID

#These variables all go into the Area2D collision. 
func getParent() -> Node2D:
	return parentRef
	
func getDamage() -> float:
	if parentInherit:	
		return parentRef.getDamage()
	else:
		return damage

#I want to make the knockback particular but we can just ignore it for now.
func getKnockback() -> float:
	if parentInherit:	
		return parentRef.getKnockback()
	else:
		return knockback

func toggle(on = true) -> void:
	set_deferred("monitorable", on)
