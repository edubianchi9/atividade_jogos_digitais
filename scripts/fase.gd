extends Node2D
## Configura o início, a câmera e o céu de qualquer uma das três cenas.

@export var nome_fase: String = "Fase"
@export var cor_ceu_base: Color = Color("a9d9dd")
@export var cor_ceu_alto: Color = Color("5e8eb6")
@export var cor_fundo_alto: Color = Color.WHITE
@export var altura_inicio_subida: float = 519.0
@export var altura_fim_subida: float = -441.0

@onready var jogador: CharacterBody2D = $Jogador
@onready var terreno: TileMapLayer = $Terreno
@onready var ceu: ColorRect = $Ceu/Cor
@onready var mensagem: Label = $Interface/Mensagem
var imagens_fundo: Array[Sprite2D] = []


func _ready() -> void:
	$Interface/Titulo.text = nome_fase
	jogador.definir_inicio($Inicio.global_position)
	configurar_camera()
	var parallax: Node = get_node_or_null("ParallaxFundo")
	if parallax != null:
		for imagem: Node in parallax.find_children("*", "Sprite2D", true, false):
			imagens_fundo.append(imagem as Sprite2D)
	for cristal: Node in find_children("*", "Area2D", true, false):
		if cristal.has_signal("coletado"):
			cristal.coletado.connect(mostrar_mensagem)


func configurar_camera() -> void:
	# O retângulo é calculado com os tiles realmente pintados no Terreno.
	var area: Rect2i = terreno.get_used_rect()
	var tamanho: Vector2 = Vector2(terreno.tile_set.tile_size)
	var inicio: Vector2 = terreno.to_global(Vector2(area.position) * tamanho)
	var fim: Vector2 = terreno.to_global(Vector2(area.end) * tamanho)
	var camera: Camera2D = jogador.get_node("Camera2D")
	var altura_pulo: float = jogador.forca_pulo * jogador.forca_pulo / (2.0 * jogador.gravidade)
	camera.limit_left = floori(inicio.x)
	camera.limit_right = ceili(fim.x)
	# Acima do tile mais alto, reservamos o espaço do pulo e do personagem.
	camera.limit_top = floori(inicio.y - altura_pulo * jogador.MAX_PULOS - 32.0)
	camera.limit_bottom = ceili(fim.y)
	jogador.altura_queda = fim.y + 320.0
	camera.reset_smoothing()
	camera.force_update_scroll()


func _process(_delta: float) -> void:
	var progresso: float = inverse_lerp(altura_inicio_subida, altura_fim_subida, jogador.global_position.y)
	ceu.color = cor_ceu_base.lerp(cor_ceu_alto, clampf(progresso, 0.0, 1.0))
	# As imagens opacas das montanhas também precisam acompanhar a cor do céu.
	for imagem: Sprite2D in imagens_fundo:
		imagem.modulate = Color.WHITE.lerp(cor_fundo_alto, clampf(progresso, 0.0, 1.0))


func mostrar_mensagem(texto: String) -> void:
	mensagem.text = texto
	$Interface/TempoMensagem.start()


func _on_tempo_mensagem_timeout() -> void:
	mensagem.text = ""
