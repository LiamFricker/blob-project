extends "res://Blob/Evolutions/base_evo_general.gd"

var attacking : bool = false
var detected : bool = false

@export var blade_level : int = 0
@onready var blade_left_refs = [$Blade1/Left, $Blade2/Left, $Blade3/Left]
@onready var blade_right_refs = [$Blade1/Right, $Blade2/Right, $Blade3/Right]

@onready var hitbox_l_ref = $HitboxL
@onready var hitbox_r_ref = $HitboxR

var blade_tween
var rust_tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func setBladeLevel(newBL : int) -> void:
	match blade_level:
		0:
			$HitboxL/CollisionShape2D.set_deferred("disabled", true)
			$HitboxR/CollisionShape2D.set_deferred("disabled", true)
		1:
			$HitboxL/CollisionShape2D2.set_deferred("disabled", true)
			$HitboxR/CollisionShape2D2.set_deferred("disabled", true)
		2:
			$HitboxL/CollisionShape2D3.set_deferred("disabled", true)
			$HitboxR/CollisionShape2D3.set_deferred("disabled", true)
	
	blade_level = newBL
	
	match blade_level:
		0:
			$HitboxL/CollisionShape2D.set_deferred("disabled", false)
			$HitboxR/CollisionShape2D.set_deferred("disabled", false)
		1:
			$HitboxL/CollisionShape2D2.set_deferred("disabled", false)
			$HitboxR/CollisionShape2D2.set_deferred("disabled", false)
		2:
			$HitboxL/CollisionShape2D3.set_deferred("disabled", false)
			$HitboxR/CollisionShape2D3.set_deferred("disabled", false)
	
	

func _on_detection_area_entered(_area: Area2D) -> void:
	if not detected and not attacking:
		detected = true
		_pinch()
		

func _on_detection_body_entered(_body: Node2D) -> void:
	if not detected and not attacking:
		detected = true
		_pinch()

func _detectionCheck() -> void:
	var detectNode = $Detection
	
	if (detectNode.has_overlapping_areas() or detectNode.has_overlapping_bodies()):
		if not detected and not attacking:
			detected = true
			_pinch()

func _pinch() -> void:
	var pinch_time = 1.5
	
	if blade_tween:
		blade_tween.kill()
	blade_tween = create_tween()
	blade_tween.tween_property(blade_left_refs[blade_level], "rotation", PI/4, pinch_time)
	blade_tween.parallel().tween_property(blade_right_refs[blade_level], "rotation", -PI/4, pinch_time)
	blade_tween.parallel().tween_property(hitbox_l_ref, "rotation", -PI/4, pinch_time)
	blade_tween.parallel().tween_property(hitbox_r_ref, "rotation", -PI/4, pinch_time)
	
	
	blade_tween.tween_property(blade_left_refs[blade_level], "rotation", 0, pinch_time)
	blade_tween.parallel().tween_property(blade_right_refs[blade_level], "rotation", 0, pinch_time)
	blade_tween.parallel().tween_property(hitbox_l_ref, "rotation", 0, pinch_time)
	blade_tween.parallel().tween_property(hitbox_r_ref, "rotation", 0, pinch_time)
	
	blade_tween.finished.connect(_pinchEnd)

func _pinchEnd() -> void:
	detected = false
	_detectionCheck()

func attack(temp : float, charge_cd : float) -> void:
	if not attacking:
		attacking = true
		detected = true
		
		var base_time = 0.75
		var scale_vec = Vector2(1.5, 1.0)
		
		if blade_tween:
			blade_tween.kill()
		blade_tween = create_tween()
		blade_tween.tween_property(blade_left_refs[blade_level], "rotation", -PI/8, base_time)
		blade_tween.parallel().tween_property(blade_right_refs[blade_level], "rotation", PI/8, base_time)
		blade_tween.parallel().tween_property(hitbox_l_ref, "rotation", -PI/8, base_time)
		blade_tween.parallel().tween_property(hitbox_r_ref, "rotation", PI/8, base_time)
		
		blade_tween.tween_property(blade_left_refs[blade_level], "rotation", PI/4, base_time)
		blade_tween.parallel().tween_property(blade_right_refs[blade_level], "rotation", -PI/4, base_time)
		blade_tween.parallel().tween_property(hitbox_l_ref, "rotation", -PI/4, base_time)
		blade_tween.parallel().tween_property(hitbox_r_ref, "rotation", -PI/4, base_time)
		
		blade_tween.tween_property(blade_left_refs[blade_level], "rotation", 0, base_time)
		blade_tween.parallel().tween_property(blade_right_refs[blade_level], "rotation", 0, base_time)
		blade_tween.parallel().tween_property(hitbox_l_ref, "rotation", 0, base_time)
		blade_tween.parallel().tween_property(hitbox_r_ref, "rotation", 0, base_time)

func _on_hitbox_l_area_entered(area: Area2D) -> void:
	pass # Replace with function body.

func _on_hitbox_l_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_hitbox_r_area_entered(area: Area2D) -> void:
	pass # Replace with function body.

func _on_hitbox_r_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
