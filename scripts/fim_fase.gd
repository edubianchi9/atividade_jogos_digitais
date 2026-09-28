extends Area2D
## Uma única cena de portal, com um destino diferente em cada instância.

@export_file("*.tscn") var destino: String = ""
@export var titulo: String = "PRÓXIMA FASE"
@export var mostrar_rotulo: bool = true

var transicao_iniciada: bool = false


func _ready() -> void:
	$Rotulo.text = titulo
	$Rotulo.visible = mostrar_rotulo
	body_entered.connect(_ao_entrar)


func _ao_entrar(body: Node2D) -> void:
	if transicao_iniciada or not body.is_in_group("jogador"):
		return
	if destino.is_empty() or not ResourceLoader.exists(destino):
		push_error("Configure uma cena válida na propriedade Destino do portal: " + name)
		return
	transicao_iniciada = true
	# O sinal ocorre durante a física. A troca espera o fim desse processamento.
	_trocar_fase.call_deferred()


func _trocar_fase() -> void:
	var resultado: Error = get_tree().change_scene_to_file(destino)
	if resultado != OK:
		transicao_iniciada = false
		push_error("Não foi possível abrir a fase: " + destino)
