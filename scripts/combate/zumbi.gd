extends CharacterBody2D

signal morreu

enum Estado { PARADO, PERSEGUINDO, ATACANDO, FERIDO, MORTO }

@export var vida_maxima: int = 4
@export var velocidade: float = 35.0
@export var dano: int = 1
@export var distancia_ataque: float = 60.0
@export var distancia_visao: float = 130.0
@export var intervalo_ataque: float = 1.2
@export var quadro_do_golpe: int = 3
@export var animacao_movimento: StringName = &"walk"
@export var tempo_invulneravel: float = 0.25
@export var gravidade: float = 980.0

var estado: Estado = Estado.PARADO
var vida: int
var jogador: CharacterBody2D
var tempo_ataque: float = 0.0
var tempo_ferido: float = 0.0
var golpe_aplicado: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_ataque: Area2D = $AreaAtaque
@onready var barra_vida: ProgressBar = $Vida


func _ready() -> void:
	jogador = get_tree().get_first_node_in_group("player") as CharacterBody2D
	vida = vida_maxima
	barra_vida.max_value = vida_maxima
	barra_vida.value = vida
	go_to_parado()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravidade * delta
	match estado:
		Estado.PARADO:
			estado_parado()
		Estado.PERSEGUINDO:
			estado_perseguindo()
		Estado.ATACANDO:
			estado_atacando(delta)
		Estado.FERIDO:
			estado_ferido(delta)
	if estado != Estado.MORTO:
		move_and_slide()


func alvo_valido() -> bool:
	return is_instance_valid(jogador) and jogador.esta_vivo()


func distancia_do_jogador() -> float:
	return global_position.distance_to(jogador.global_position)


func estado_parado() -> void:
	velocity.x = 0.0
	if alvo_valido() and distancia_do_jogador() <= distancia_visao:
		go_to_perseguindo()
		return


func estado_perseguindo() -> void:
	if not alvo_valido() or distancia_do_jogador() > distancia_visao:
		go_to_parado()
		return
	if distancia_do_jogador() <= distancia_ataque:
		go_to_atacando()
		return
	var direcao: float = signf(jogador.global_position.x - global_position.x)
	olhar_para(direcao)
	velocity.x = direcao * velocidade


func estado_atacando(delta: float) -> void:
	velocity.x = 0.0
	tempo_ataque += delta
	if not alvo_valido():
		go_to_parado()
		return
	if anim.frame >= quadro_do_golpe and not golpe_aplicado:
		golpe_aplicado = true
		for corpo: Node2D in area_ataque.get_overlapping_bodies():
			if corpo != self and corpo.is_in_group("player") and corpo.has_method("levar_dano"):
				corpo.levar_dano(dano)
	if tempo_ataque >= intervalo_ataque and not anim.is_playing():
		if distancia_do_jogador() <= distancia_ataque:
			go_to_atacando()
		else:
			go_to_perseguindo()
		return


func estado_ferido(delta: float) -> void:
	velocity.x = 0.0
	tempo_ferido -= delta
	if tempo_ferido <= 0.0:
		go_to_perseguindo()
		return


func olhar_para(direcao: float) -> void:
	if direcao == 0.0:
		return
	anim.flip_h = direcao < 0.0
	area_ataque.position.x = absf(area_ataque.position.x) * signf(direcao)


func go_to_parado() -> void:
	estado = Estado.PARADO
	velocity.x = 0.0
	area_ataque.set_deferred("monitoring", false)
	anim.modulate = Color.WHITE
	anim.play("idle")


func go_to_perseguindo() -> void:
	estado = Estado.PERSEGUINDO
	area_ataque.set_deferred("monitoring", false)
	anim.modulate = Color.WHITE
	anim.play(animacao_movimento)


func go_to_atacando() -> void:
	estado = Estado.ATACANDO
	velocity.x = 0.0
	tempo_ataque = 0.0
	golpe_aplicado = false
	if alvo_valido():
		olhar_para(jogador.global_position.x - global_position.x)
	area_ataque.set_deferred("monitoring", true)
	anim.stop()
	anim.play("attack")


func levar_dano(quantidade: int) -> void:
	if quantidade <= 0 or estado in [Estado.FERIDO, Estado.MORTO]:
		return
	vida = maxi(0, vida - quantidade)
	barra_vida.value = vida
	if vida == 0:
		go_to_morto()
		return
	go_to_ferido()


func go_to_ferido() -> void:
	estado = Estado.FERIDO
	velocity.x = 0.0
	tempo_ferido = tempo_invulneravel
	area_ataque.set_deferred("monitoring", false)
	anim.modulate = Color(1, 0.45, 0.45)
	anim.stop()
	anim.play("hurt")


func go_to_morto() -> void:
	estado = Estado.MORTO
	velocity = Vector2.ZERO
	area_ataque.set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	barra_vida.hide()
	$Nome.hide()
	anim.modulate = Color.WHITE
	anim.play("death")
	set_physics_process(false)
	morreu.emit()
	await anim.animation_finished
	queue_free()
