extends Node2D

@export var playerRef : Node2D

func _ready() -> void:
	$PlayerAfterImage.playerRef = playerRef

func addPosition(newpos) -> void:
	position += newpos
	$PlayerAfterImage.addOffset(newpos)

func createAfterImage(trail_decay : float, trail_int : float, trail_color : int, trail_count : int) -> void:
	$PlayerAfterImage.trailCreate(trail_decay, trail_int, trail_color, trail_count)

func endAfterImage() -> void:
	$PlayerAfterImage.trailStop()
