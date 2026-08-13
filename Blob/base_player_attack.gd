extends Node2D

@export var parentRef : Node2D
@export var knockback : float = 2.0
@export var damage : float = 3.0
var size = 0.0
@export var dependent : bool = true
@export var attack_mods : Array = [false, false, false, false, false]
var ID : int = 0.0

signal damagedEnemy(amt : float)

func getAttackMod(num : int) -> bool:
	return attack_mods[num]

func setID(newID : int) -> void:
	ID = newID
	
func getID() -> int:
	if dependent:
		return parentRef.getID()
	else:
		return ID

func setParams(dmg : float, kb : float, pR : Node2D, sz = 0.0) -> void:
	damage = dmg
	knockback = kb
	parentRef = pR
	size = sz

func _ready() -> void:
	if size > 0:
		var tempShape = CircleShape2D.new()
		tempShape.radius = size
		$CollisionShape2D.set_deferred("shape", tempShape)

#These variables all go into the Area2D collision. 
func getParent() -> Node2D:
	return parentRef
	
func getDamage() -> float:
	damagedEnemy.emit(damage)
	return damage

func connectDMG(call : Callable) -> void:
	damagedEnemy.connect(call)

func addPosition(newpos) -> void:
	if not dependent:
		position += newpos

#Change this to the position of the tip.
#Or the movement object
func getPosition() -> Vector2:
	if dependent:
		return position + parentRef.getPosition() 
	else:
		return position

#I want to make the knockback particular but we can just ignore it for now.
func getKnockback() -> float:
	return knockback
	
func toggle(on = true) -> void:
	set_deferred("monitorable", on)
	
