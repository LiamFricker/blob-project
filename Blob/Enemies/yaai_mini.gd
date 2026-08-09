extends "res://Blob/base_enemy_attachment.gd"

var orbit_id
var parentRef : Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	oscillate_tween = create_tween().set_loops()
	oscillate_tween.tween_property($Sprite/Tiny/Black, "modulate:a", 0, 0.6)
	oscillate_tween.parallel().tween_property($Sprite/Full/Black, "modulate:a", 0, 0.6)
	oscillate_tween.parallel().tween_property($Sprite/Tiny/White, "modulate:a", 1, 0.6)
	oscillate_tween.parallel().tween_property($Sprite/Full/White, "modulate:a", 1, 0.6)
	oscillate_tween.tween_interval(0.6)
	oscillate_tween.tween_property($Sprite/Tiny/Black, "modulate:a", 1, 0.6)
	oscillate_tween.parallel().tween_property($Sprite/Full/Black, "modulate:a", 1, 0.6)
	oscillate_tween.parallel().tween_property($Sprite/Tiny/White, "modulate:a", 0, 0.6)
	oscillate_tween.parallel().tween_property($Sprite/Full/White, "modulate:a", 0, 0.6)
	oscillate_tween.tween_interval(0.6)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setParams(dmg : float, pR : Node2D, kb : float, sz : float, orb_id = 1) -> void:
	orbit_id = orb_id
	super(dmg, pR, kb, sz)
	parentRef = pR

func initSelf(currPos : Vector2, finalPos : Vector2, currRot : float, currIndex : int) -> void:

	var duration = currPos.distance_to(finalPos) / 150.0
	
	z_index = currIndex
	
	movement_tween = create_tween()
	movement_tween.tween_property(self, "position", finalPos, duration).from(currPos)
	movement_tween.parallel().tween_property($Sprite/Tiny, "position:y", -40, duration).from(currPos)
	movement_tween.parallel().tween_property(self, "rotation", 0, duration).from(currRot)
	movement_tween.finished.connect(endInit)
	
func endInit() -> void:
	z_index = 0
	$AnimationPlayer.play("transform")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"create":
			attachRef.orbReady(orbit_id)
		"transform":
			$Hitbox.set_deferred("monitoring", true)
		"death":
			_delete()


func _on_hitbox_area_entered(area: Area2D) -> void:
	pass # Replace with function body.

func _on_hitbox_body_entered(body: Node2D) -> void:
	var tempRef = body.getAttachNode()
	if tempRef.idCount(ID) >= 1:
		tempRef.triggerDamage(damage)
		$Lifetime.stop()
		_on_lifetime_timeout()
	else:
		attachRef.removeChild(self, ID)
		attachRef = tempRef
		
		tempRef.attachSelf(self)
		attached = true
		$Lifetime.start()

func orphan(_pos : Vector2) -> void:
	_on_lifetime_timeout()

func _on_lifetime_timeout() -> void:
	if parentRef:
		parentRef.removeChild(self)
	if attached:
		attachRef.attachDeath(ID)
	
	$Hitbox.set_deferred("monitoring", false)
	$AnimationPlayer.play("death")
