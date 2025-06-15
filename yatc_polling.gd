extends Node
class_name YatcPolling

var callbacks: Array[Callable] = []
var timer: Timer

func _init() -> void:
	self.name = 'YatcPolling'


func _ready() -> void:
	timer = Timer.new()
	timer.name = 'polling_timer'
	self.add_child(timer)
	timer.timeout.connect(_on_timeout)
	timer.start(60)


func add_callback(fn: Callable) -> void:
	callbacks.push_back(fn)


func remove_callback(fn: Callable) -> void:
	callbacks.erase(fn)


func clear_callbacks() -> void:
	callbacks.clear()


func _on_timeout() -> void:
	for fn: Callable in callbacks:
		fn.call()
