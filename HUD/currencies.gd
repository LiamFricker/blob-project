extends Control

var base_tick_time = 0.5

var energy_tween
var size_tween

var energy_old : float = 0
var size_old : float = 0

@onready var energy_ref = $MarginContainer/VBoxContainer/Energy/HBoxContainer/Label
@onready var size_ref = $MarginContainer/VBoxContainer/Size/HBoxContainer/Label

func setEnergy(new_amt : float) -> void:
	var ener_max = max(energy_old, new_amt)
	var time_duration = max(5.0 * base_tick_time * abs(new_amt - energy_old) / ener_max, base_tick_time)
	
	if energy_tween:
		energy_tween.kill()
	energy_tween = create_tween()
	energy_tween.tween_method(_setEnergy, energy_old, new_amt, time_duration)
	energy_old = new_amt
	
func setSize(new_amt : float) -> void:
	var size_max = max(size_old, new_amt)
	var time_duration = max(5.0 * base_tick_time * abs(new_amt - size_old) / size_max, base_tick_time)
	
	if size_tween:
		size_tween.kill()
	size_tween = create_tween()
	size_tween.tween_method(_setSize, size_old, new_amt, time_duration)
	size_old = new_amt

func _parseAmt(new_amt : float) -> String:
	return str(snappedf(new_amt, 0.01))

func _setEnergy(new_amt : float) -> void:
	energy_ref.text = _parseAmt(new_amt)

func _setSize(new_amt : float) -> void:
	size_ref.text = _parseAmt(new_amt)
