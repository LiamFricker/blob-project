extends base_creature

@export var spriteRef : Node2D# = $InnerNode/Sprite/AnimatedSprite2D
@export var shadMat = preload("res://Blob/Enemies/base_creature_material.tres")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	shadMat = shadMat.duplicate()
	spriteRef.material = shadMat

func _handleRedFlash() -> void:
	#print("this triggered")
	spriteRef.material.set_shader_parameter("end_color", Color(1,0,0))
	var tempMod = spriteRef.material.get_shader_parameter("progress")
	movement_tween.parallel().tween_method(_updateSpriteModulate, tempMod, 0.5, 0.25)
	movement_tween.tween_method(_updateSpriteModulate, tempMod, 0.0, 0.25)

func _handleRedDeath() -> void:
	#print("this triggered")
	spriteRef.material.set_shader_parameter("end_color", Color(1,0,0))
	var tempMod = spriteRef.material.get_shader_parameter("progress")
	dot_tween.tween_method(_updateSpriteModulate, tempMod, 0.5, 0.5)
	dot_tween.parallel().tween_property(self, "modulate:a", 0.0, 1.0)

func _updateSpriteModulate(progress: float) -> void:
	spriteRef.material.set_shader_parameter("progress", progress)
