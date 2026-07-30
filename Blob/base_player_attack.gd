extends Node2D

@export var parentRef : Node2D
@export var knockback : float = 2.0
@export var damage : float = 3.0
var size = 0.0
@export var dependent : bool = true

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
	return damage

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
	
