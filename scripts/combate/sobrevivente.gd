extends CharacterBody2D

signal vida_alterada(atual: int, maxima: int)
signal morreu

enum Estado { PARADO, ANDANDO, PULANDO, ATACANDO, FERIDO, MORTO }

@export var velocidade: float = 150.0
@export var forca_pulo: float = 400.0
@export var gravidade: float = 980.0
@export var vida_maxima: int = 5
@export var dano_do_golpe: int = 2
@export var quadro_do_golpe: int = 6
@export var tempo_invulneravel: float = 0.4

var estado: Estado = Estado.PARADO
var vida: int
var tempo_ferido: float = 0.0
var golpe_aplicado: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_golpe: Area2D = $AreaGolpe


func _ready() -> void:
	vida = vida_maxima
	go_to_parado()
	vida_alterada.emit(vida, vida_maxima)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravidade * delta
	match estado:
		Estado.PARADO:
			estado_parado()
		Estado.ANDANDO:
			estado_andando()
		Estado.PULANDO:
			estado_pulando()
		Estado.ATACANDO:
			estado_atacando()
		Estado.FERIDO:
			estado_ferido(delta)
	if estado != Estado.MORTO:
		move_and_slide()


func estado_parado() -> void:
	velocity.x = 0.0
	if not is_on_floor():
		go_to_pulando()
		return
	if Input.is_action_just_pressed("atacar"):
		go_to_atacando()
		return
	if Input.is_action_just_pressed("pular"):
		velocity.y = -forca_pulo
		go_to_pulando()
		return
	if Input.get_axis("esquerda", "direita") != 0:
		go_to_andando()
		return


func estado_andando() -> void:
	if not is_on_floor():
		go_to_pulando()
		return
	if Input.is_action_just_pressed("atacar"):
		go_to_atacando()
		return
	if Input.is_action_just_pressed("pular"):
		velocity.y = -forca_pulo
		go_to_pulando()
		return
	var direcao: float = Input.get_axis("esquerda", "direita")
	if direcao == 0.0:
		go_to_parado()
		return
	velocity.x = direcao * velocidade
	olhar_para(direcao)


func estado_pulando() -> void:
	var direcao: float = Input.get_axis("esquerda", "direita")
	velocity.x = direcao * velocidade
	olhar_para(direcao)
	if is_on_floor() and velocity.y >= 0.0:
		go_to_parado()
		return


func estado_atacando() -> void:
	velocity.x = 0.0
	if anim.frame >= quadro_do_golpe and not golpe_aplicado:
		golpe_aplicado = true
		for corpo: Node2D in area_golpe.get_overlapping_bodies():
			if corpo != self and corpo.is_in_group("zumbis") and corpo.has_method("levar_dano"):
				corpo.levar_dano(dano_do_golpe)
	if not anim.is_playing():
		go_to_parado()
		return


func estado_ferido(delta: float) -> void:
	velocity.x = 0.0
	tempo_ferido -= delta
	anim.modulate = Color(1, 0.35, 0.35, 0.55 if int(tempo_ferido * 30) % 2 else 1.0)
	if tempo_ferido <= 0.0:
		go_to_parado()
		return


func olhar_para(direcao: float) -> void:
	if direcao == 0.0:
		return
	anim.flip_h = direcao < 0.0
	area_golpe.position.x = absf(area_golpe.position.x) * signf(direcao)


func go_to_parado() -> void:
	estado = Estado.PARADO
	velocity.x = 0.0
	area_golpe.set_deferred("monitoring", false)
	anim.modulate = Color.WHITE
	anim.play("idle")


func go_to_andando() -> void:
	estado = Estado.ANDANDO
	anim.play("walk")


func go_to_pulando() -> void:
	estado = Estado.PULANDO
	anim.stop()
	anim.play("jump")


func go_to_atacando() -> void:
	estado = Estado.ATACANDO
	velocity.x = 0.0
	golpe_aplicado = false
	area_golpe.set_deferred("monitoring", true)
	anim.stop()
	anim.play("attack")


func levar_dano(quantidade: int) -> void:
	if quantidade <= 0 or estado in [Estado.FERIDO, Estado.MORTO]:
		return
	vida = maxi(0, vida - quantidade)
	vida_alterada.emit(vida, vida_maxima)
	if vida == 0:
		go_to_morto()
		return
	go_to_ferido()


func go_to_ferido() -> void:
	estado = Estado.FERIDO
	tempo_ferido = tempo_invulneravel
	velocity.x = 0.0
	area_golpe.set_deferred("monitoring", false)
	anim.stop()
	anim.play("hurt")


func go_to_morto() -> void:
	estado = Estado.MORTO
	velocity = Vector2.ZERO
	area_golpe.set_deferred("monitoring", false)
	anim.modulate = Color.WHITE
	anim.play("death")
	set_physics_process(false)
	morreu.emit()


func esta_vivo() -> bool:
	return estado != Estado.MORTO
