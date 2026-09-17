extends CharacterBody2D

@export var velocidade: float = 280.0
@export var forca_pulo: float = 540.0
@export var gravidade: float = 1500.0

var posicao_inicial: Vector2
var tempo_animacao: float = 0.0

@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	posicao_inicial = global_position
	add_to_group("jogador")


func _physics_process(delta: float) -> void:
	var direcao: float = Input.get_axis(
		"esquerda",
		"direita"
	)

	velocity.x = direcao * velocidade

	if not is_on_floor():
		velocity.y += gravidade * delta

	if is_on_floor() and Input.is_action_just_pressed("pular"):
		velocity.y = -forca_pulo

	move_and_slide()

	atualizar_animacao(delta, direcao)

	if global_position.y > 1000.0:
		global_position = posicao_inicial
		velocity = Vector2.ZERO

		var camera = get_node_or_null("Camera2D")

		if camera != null:
			camera.reset_smoothing()


func atualizar_animacao(
	delta: float,
	direcao: float
) -> void:
	tempo_animacao += delta

	var escala_desejada := Vector2.ONE

	if not is_on_floor():
		if velocity.y < 0.0:
			escala_desejada = Vector2(0.85, 1.15)
		else:
			escala_desejada = Vector2(1.1, 0.9)

	elif direcao != 0.0:
		escala_desejada = Vector2(
			1.0,
			1.0 + abs(sin(tempo_animacao * 15.0)) * 0.08
		)

	else:
		escala_desejada = Vector2(
			1.0,
			1.0 + sin(tempo_animacao * 3.0) * 0.025
		)

	visual.scale = visual.scale.lerp(
		escala_desejada,
		minf(delta * 12.0, 1.0)
	)
