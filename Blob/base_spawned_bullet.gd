extends "res://Blob/base_spawned_attack.gd"

var bullet_id : int = 0

func setBulletParams(pR : Node2D, bulID : int) -> void:
	parentRef = pR
	bullet_id = bulID

func updateParams(dmg : float, kb : float, sz : float) -> void:
	if size != sz:
		size = sz
		_setSize()
	damage = dmg
	knockback = kb

func _OnDeath() -> void:
	parentRef.freeBullet(bullet_id)
