extends "res://Blob/base_player_attack.gd"

var tween
var lt : float = 2.0

func setParams(dmg : float, kb : float, pR : Node2D, sz = 0.0, lifetime = 2.0) -> void:
	super(dmg, kb, pR, sz)
	lt = lifetime

func _ready() -> void:
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, lt)
	tween.finished.connect(_delete)
	
func _delete() -> void:
	call_deferred("queue_free")
