extends Camera2D

var jogador: Node2D


func _ready() -> void:
	jogador = get_tree().get_first_node_in_group("player") as Node2D
	acompanhar()
	reset_smoothing()


func _physics_process(_delta: float) -> void:
	acompanhar()


func acompanhar() -> void:
	if is_instance_valid(jogador):
		global_position = jogador.global_position + Vector2(0, -56)
