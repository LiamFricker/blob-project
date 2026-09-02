extends Area2D

@export var health : int = 1
@export var parentRef : Node2D
@export var knockback : float = 0.0
@export var damage : float = 1.0
var size = 0.0
@export var attack_mods : Array = [false, false, false, false, false]
@export var ID : int = 0

var movement_tween
var oscillate_tween

@export var hurtboxRef : Node2D = null
@export var SpriteRef : Node2D = null

func getAttackMod(num: int)-> bool:
	return attack_mods[num]
	
func getID() -> int:
	return ID

func setParams(dmg : float, pR : Node2D, sz : float, newID : int, hp = 1, kb = 0.0) -> void:
	health = hp
	damage = dmg
	if kb != 0.0:	
		knockback = kb
	parentRef = pR
	size = sz
	ID = newID

func _ready() -> void:
	if size > 0:
		var tempShape = CircleShape2D.new()
		tempShape.radius = size
		$CollisionShape2D.set_deferred("shape", tempShape)
		if hurtboxRef:
			tempShape = CircleShape2D.new()
			tempShape.radius = size * 0.8
			$CollisionShape2D.set_deferred("shape", tempShape)

#These variables all go into the Area2D collision. 
func getParent() -> Node2D:
	return parentRef
	
func getDamage() -> float:
	return damage

func addPosition(newpos : Vector2) -> void:
	position += newpos

#Change this to the position of the tip.
#Or the movement object
func getPosition() -> Vector2:
	return position

#I want to make the knockback particular but we can just ignore it for now.
func getKnockback() -> float:
	return knockback
	
func toggle(on = true) -> void:
	set_deferred("monitorable", on)
	if hurtboxRef:
		hurtboxRef.set_deferred("monitoring", on)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if health > 0:
		if area.getID() != ID and area.getAttackMod(1): #temp_enemy.getID()
			area.emitDamage(max(area.getDamage() * 0.25, 0.5*getDamage()))
			_takeDamage()

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if health > 0:
		if body.getID() != ID and body.getAttackMod(1): #temp_enemy.getID()
			body.emitDamage(max(body.getDamage() * 0.25, 0.5*getDamage()))
			_takeDamage()

func _takeDamage() -> void:
	if SpriteRef:
		if oscillate_tween:
			oscillate_tween.kill()
		oscillate_tween = create_tween()
		SpriteRef.position = Vector2.ZERO
		oscillate_tween.tween_property(SpriteRef, "position", Vector2(0, -2), 0.1).as_relative()
		oscillate_tween.tween_property(SpriteRef, "position", Vector2(-2, 1), 0.1).as_relative()
		oscillate_tween.tween_property(SpriteRef, "position", Vector2(3, 2), 0.1).as_relative()
		oscillate_tween.tween_property(SpriteRef, "position", Vector2(-1, -1), 0.1).as_relative()
	
	health -= 1
	if health <= 0:
		_OnDeath()

func emitDamage(_dmg_amt) -> void:
	pass

func isDead() -> bool:
	return health > 0 

func _OnDeath() -> void:
	toggle(false)
	if movement_tween:
		movement_tween.kill()
	if oscillate_tween:
		oscillate_tween.kill()
	oscillate_tween = create_tween()
	oscillate_tween.tween_property(self, "modulate:a", 0, 0.3).as_relative()
	oscillate_tween.finished.connect(_delete)

func orphan(_pos : Vector2) -> void:
	get_tree().create_timer(6.0).timeout.connect(_OnDeath)

func _delete() -> void:
	if parentRef:	
		parentRef.removeChild(self)
	call_deferred("queue_free")
	
