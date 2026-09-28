extends Area2D

signal coletado(mensagem: String)

@export var mensagem: String = "Cristal secreto encontrado!"
var ja_coletado: bool = false


func _ready() -> void:
	body_entered.connect(_ao_encostar)
	var flutuar: Tween = create_tween().set_loops()
	flutuar.tween_property($Visual, "position:y", -4.0, 0.7).set_trans(Tween.TRANS_SINE)
	flutuar.tween_property($Visual, "position:y", 4.0, 0.7).set_trans(Tween.TRANS_SINE)


func _ao_encostar(body: Node2D) -> void:
	if ja_coletado or not body.is_in_group("jogador"):
		return
	ja_coletado = true
	coletado.emit(mensagem)
	queue_free()
