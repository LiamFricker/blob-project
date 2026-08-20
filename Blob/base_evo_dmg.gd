extends Node2D

var children_list = []

signal spawnFriend(friend_id : int, count : int, source : Node2D)
signal damagedEnemy(amt : float)

func _damagedEnemy(amt : float) -> void:
	damagedEnemy.emit(amt)

@export var damage = 0
@export var knockback = 0
@export var playerRef : Node2D

func getID() -> int:
	return playerRef.getID()

#These variables all go into the Area2D collision. 
func getParent() -> Node2D:
	return playerRef

func addPos(newpos : float) -> void:
	for c in children_list:
		c.addPosition(newpos)

func connectBullet(bul : Node2D) -> void:
	children_list.append(bul)

func freeBullet(bullet_id : int) -> void:
	pass
	
"""
func getDamage() -> float:
	return damage

func emitDamage(dmg_amt : float):
	damagedEnemy.emit(damage) 
"""	

#Change this to the position of the tip.
#Or the movement object
func getPosition() -> Vector2:
	return position

#I want to make the knockback particular but we can just ignore it for now.
func getKnockback() -> float:
	return knockback
