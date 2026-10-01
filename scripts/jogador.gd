extends CharacterBody2D

enum Estado { PARADO, ANDANDO, PULANDO, AGACHADO }
const MAX_PULOS: int = 2

@export var velocidade: float = 280.0
@export var forca_pulo: float = 540.0
@export var gravidade: float = 1500.0
@export var altura_queda: float = 1000.0

var posicao_inicial: Vector2
var tempo_animacao: float = 0.0
var estado: Estado
var pulos_realizados: int = 0
var tamanho_colisor_normal: Vector2
var posicao_colisor_normal: Vector2

@onready var visual: Polygon2D = $Visual
@onready var colisor: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	posicao_inicial = global_position
	add_to_group("jogador")

	colisor.shape = colisor.shape.duplicate()
	tamanho_colisor_normal = (colisor.shape as RectangleShape2D).size
	posicao_colisor_normal = colisor.position
	go_to_parado()
	return


func _physics_process(delta: float) -> void:
	if global_position.y > altura_queda or Input.is_action_just_pressed("reiniciar"):
		reiniciar()
		return

	if is_on_floor():
		pulos_realizados = 0
	else:
		velocity.y += gravidade * delta


	match estado:
		Estado.PARADO:
			parado(delta)
		Estado.ANDANDO:
			andando(delta)
		Estado.PULANDO:
			pulando(delta)
		Estado.AGACHADO:
			agachado(delta)

	move_and_slide()
	if is_on_floor():
		pulos_realizados = 0


func go_to_parado() -> void:
	estado = Estado.PARADO
	tempo_animacao = 0.0
	velocity.x = 0.0
	(colisor.shape as RectangleShape2D).size = tamanho_colisor_normal
	colisor.position = posicao_colisor_normal
	visual.scale = Vector2.ONE


func parado(delta: float) -> void:
	if not is_on_floor():
		go_to_pulando(false)
		return
	if Input.is_action_pressed("agachar"):
		go_to_agachado()
		return
	if Input.is_action_just_pressed("pular"):
		go_to_pulando()
		return
	if Input.get_axis("esquerda", "direita") != 0.0:
		go_to_andando()
		return
	tempo_animacao += delta
	animar(Vector2(1.0, 1.0 + sin(tempo_animacao * 3.0) * 0.025), delta)


func go_to_andando() -> void:
	estado = Estado.ANDANDO
	tempo_animacao = 0.0
	velocity.x = Input.get_axis("esquerda", "direita") * velocidade
	visual.scale = Vector2.ONE


func andando(delta: float) -> void:
	if not is_on_floor():
		go_to_pulando(false)
		return
	if Input.is_action_pressed("agachar"):
		go_to_parado()
		return
	if Input.is_action_just_pressed("pular"):
		go_to_pulando()
		return
	var direcao: float = Input.get_axis("esquerda", "direita")
	if direcao == 0.0:
		go_to_parado()
		return
	velocity.x = direcao * velocidade
	tempo_animacao += delta
	animar(Vector2(1.0, 1.0 + abs(sin(tempo_animacao * 15.0)) * 0.08), delta)


func go_to_pulando(aplicar_impulso: bool = true) -> void:
	estado = Estado.PULANDO
	tempo_animacao = 0.0
	velocity.x = Input.get_axis("esquerda", "direita") * velocidade
	if aplicar_impulso:
		pulos_realizados += 1
		velocity.y = -forca_pulo
	else:
		pulos_realizados = maxi(pulos_realizados, 1)
	visual.scale = Vector2(0.85, 1.15) if velocity.y < 0.0 else Vector2(1.1, 0.9)


func pulando(delta: float) -> void:
	if is_on_floor():
		go_to_parado()
		return
	if Input.is_action_just_pressed("pular") and pulos_realizados < MAX_PULOS:
		go_to_pulando()
		return
	velocity.x = Input.get_axis("esquerda", "direita") * velocidade
	var escala: Vector2 = Vector2(0.85, 1.15) if velocity.y < 0.0 else Vector2(1.1, 0.9)
	animar(escala, delta)


func go_to_agachado() -> void:
	estado = Estado.AGACHADO
	tempo_animacao = 0.0
	velocity.x = 0.0
	var tamanho_baixo := Vector2(tamanho_colisor_normal.x, tamanho_colisor_normal.y * 0.5)
	(colisor.shape as RectangleShape2D).size = tamanho_baixo
	colisor.position = posicao_colisor_normal + Vector2(0, tamanho_colisor_normal.y * 0.25)
	visual.scale = Vector2(1.0, 0.5)


func agachado(delta: float) -> void:
	if not Input.is_action_pressed("agachar") and pode_levantar():
		go_to_parado()
		return
	tempo_animacao += delta
	animar(Vector2(1.0, 0.5 + sin(tempo_animacao * 3.0) * 0.012), delta)


func pode_levantar() -> bool:
	var forma := RectangleShape2D.new()
	forma.size = tamanho_colisor_normal - Vector2(0.2, 0.2)
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.transform = global_transform * Transform2D(0.0, posicao_colisor_normal)
	consulta.collision_mask = collision_mask
	consulta.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty()


func animar(escala: Vector2, delta: float) -> void:
	visual.scale = visual.scale.lerp(escala, minf(delta * 12.0, 1.0))


func definir_inicio(posicao: Vector2) -> void:
	posicao_inicial = posicao
	reiniciar()


func reiniciar() -> void:
	global_position = posicao_inicial
	velocity = Vector2.ZERO
	pulos_realizados = 0
	var camera: Camera2D = get_node_or_null("Camera2D")
	if camera != null:
		camera.reset_smoothing()
		camera.force_update_scroll()
	go_to_parado()
	return
