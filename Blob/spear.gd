extends Node2D

@export var base_damage : float = 1
@export var damage_mult : float = 1
@export var size : float = 12

@export var base_intensity : float = 1
@export var dot_mult : float = 1
@export var duration : float = 1

func changeSize(newSize : float) -> void:
	var tempShape = CircleShape2D.new()
	tempShape.radius = 25
	$Hitbox/CollisionShape2D.shape = tempShape

func _on_hitbox_area_entered(area: Area2D) -> void:
	area.getParent().takeDamage(base_damage * damage_mult)

func _on_inject(area: Area2D) -> void:
	area.getParent().applyPoison(base_intensity * dot_mult, duration)
