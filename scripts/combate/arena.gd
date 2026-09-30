extends Node2D

var restantes: int = 0
var reiniciando: bool = false

@onready var jogador: CharacterBody2D = $Sobrevivente


func _ready() -> void:
	jogador.vida_alterada.connect(atualizar_vida)
	jogador.morreu.connect(jogador_morreu)
	for zumbi: Node in get_tree().get_nodes_in_group("zumbis"):
		restantes += 1
		zumbi.morreu.connect(zumbi_morreu)
	atualizar_vida(jogador.vida, jogador.vida_maxima)
	atualizar_contador()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("reiniciar") and not reiniciando:
		reiniciando = true
		get_tree().call_deferred("reload_current_scene")


func atualizar_vida(atual: int, maxima: int) -> void:
	$Interface/Vida.text = "VIDA  %d / %d" % [atual, maxima]
	$Interface/BarraVida.max_value = maxima
	$Interface/BarraVida.value = atual


func atualizar_contador() -> void:
	$Interface/Restantes.text = "ZUMBIS  %d / 3" % restantes


func zumbi_morreu() -> void:
	restantes -= 1
	atualizar_contador()
	if restantes == 0 and jogador.esta_vivo():
		$Interface/Resultado.text = "ARENA CONCLUÍDA!\nPressione R para jogar novamente"
		$Interface/Resultado.show()


func jogador_morreu() -> void:
	$Interface/Resultado.text = "VOCÊ FOI DERROTADO\nPressione R para tentar novamente"
	$Interface/Resultado.show()
