extends Node2D

var children_list = []

signal spawnFriend(friend_id : int, count : int, source : Node2D)
signal damagedEnemy(amt : float)

func _damagedEnemy(amt : float) -> void:
	damagedEnemy.emit(amt)

@export var bullet_id : int = 0
@export var bullets_max : int = 0 

@export var damage = 0
@export var knockback = 0
@export var playerRef : Node2D

@export var size = 1.0

func _ready() -> void:
	_setSize()
	spawnFriend.emit(bullet_id, bullets_max, self)

func _setSize() -> void:
	pass
	"""
	for c in children_list:
		c.size = size
		c._setSize()
	"""

func getID() -> int:
	return playerRef.getID()

#These variables all go into the Area2D collision. 
func getParent() -> Node2D:
	return playerRef

func addPosition(newpos : float) -> void:
	for c in children_list:
		c.addPosition(newpos)

func connectBullet(bul : Node2D) -> void:
	children_list.append(bul)

func freeBullet(_bullet_id : int) -> void:
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
	return position + playerRef.getPosition()

#I want to make the knockback particular but we can just ignore it for now.
func getKnockback() -> float:
	return knockback
