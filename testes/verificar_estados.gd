extends SceneTree

const JogadorScript = preload("res://scripts/jogador.gd")
var jogador: CharacterBody2D
var verificacoes: int = 0
var falhas: int = 0

func _initialize() -> void:
	call_deferred("executar")

func conferir(condicao: bool, descricao: String) -> void:
	verificacoes += 1
	if not condicao:
		falhas += 1
		push_error(descricao)

func esperar(frames: int = 1) -> void:
	for frame: int in range(frames):
		await physics_frame
		await process_frame

func tocar(acao: String) -> void:
	Input.action_press(acao)
	await esperar()
	Input.action_release(acao)

func executar() -> void:
	change_scene_to_file("res://cenas/fase_1.tscn")
	await scene_changed
	jogador = current_scene.get_node("Jogador")
	await esperar(10)
	var colisor: CollisionShape2D = jogador.get_node("CollisionShape2D")
	var forma: RectangleShape2D = colisor.shape
	var visual: Polygon2D = jogador.get_node("Visual")
	var inicio: Vector2 = jogador.position
	conferir(jogador.estado == JogadorScript.Estado.PARADO, "Começa parado")
	conferir(jogador.is_on_floor(), "Começa apoiado no chão")
	var escala_parado: Vector2 = visual.scale
	await esperar(10)
	conferir(visual.scale != escala_parado, "Estado parado anima o visual")
	Input.action_press("direita")
	await esperar(3)
	conferir(jogador.estado == JogadorScript.Estado.ANDANDO and jogador.position.x > inicio.x, "Anda ao segurar a direção")
	Input.action_release("direita")
	await esperar(3)
	conferir(jogador.estado == JogadorScript.Estado.PARADO, "Volta a parado ao soltar a direção")

	Input.action_press("agachar")
	await esperar(3)
	conferir(jogador.estado == JogadorScript.Estado.AGACHADO, "Entra em agachado")
	conferir(forma.size == Vector2(24,16) and colisor.position == Vector2(0,-8), "Colisor encolhe mantendo a base")
	conferir(absf(jogador.position.y - inicio.y) < 0.1 and visual.scale.y < 0.6, "Visual agacha sem deslocar os pés")
	var x_agachado: float = jogador.position.x
	Input.action_press("direita")
	await esperar(10)
	await tocar("pular")
	conferir(jogador.estado == JogadorScript.Estado.AGACHADO and jogador.position.x == x_agachado, "Agachar segurado bloqueia andar e pular")
	Input.action_release("direita")
	Input.action_release("agachar")
	await esperar(3)
	conferir(jogador.estado == JogadorScript.Estado.PARADO, "Sai de agachado pelo estado parado")
	conferir(forma.size == Vector2(24,32) and colisor.position == Vector2(0,-16), "Colisor recupera exatamente o tamanho e a posição")

	Input.action_press("direita")
	await esperar(3)
	Input.action_press("agachar")
	await esperar()
	conferir(jogador.estado == JogadorScript.Estado.PARADO, "Andando passa por parado antes de agachar")
	await esperar()
	conferir(jogador.estado == JogadorScript.Estado.AGACHADO, "Agacha no próximo passo")
	Input.action_release("agachar")
	await esperar()
	conferir(jogador.estado == JogadorScript.Estado.PARADO, "Agachado passa por parado antes de andar")
	await esperar()
	conferir(jogador.estado == JogadorScript.Estado.ANDANDO, "Retoma a direção que continua segurada")
	Input.action_release("direita")
	await esperar(3)

	Input.action_press("pular")
	await esperar(12)
	conferir(jogador.estado == JogadorScript.Estado.PULANDO and jogador.pulos_realizados == 1, "Segurar pular não gasta o segundo salto")
	Input.action_release("pular")
	await esperar()
	await tocar("pular")
	conferir(jogador.pulos_realizados == 2 and jogador.velocity.y < -500.0, "Segundo toque aplica o pulo duplo")
	await esperar(6)
	var velocidade_antes: float = jogador.velocity.y
	await tocar("pular")
	conferir(jogador.pulos_realizados == 2 and jogador.velocity.y > velocidade_antes, "Terceiro toque não cria outro impulso")
	for frame: int in range(180):
		await esperar()
		if jogador.is_on_floor():
			break
	conferir(jogador.is_on_floor() and jogador.pulos_realizados == 0, "Contador zera no frame de contato com o chão")
	await esperar(2)
	await tocar("pular")
	conferir(jogador.pulos_realizados == 1 and jogador.velocity.y < 0.0, "Pode iniciar outra sequência de saltos")
	await tocar("reiniciar")
	await esperar(4)
	conferir(jogador.position.distance_to(inicio) < 1.0 and jogador.pulos_realizados == 0, "Reinício restaura posição e contador")

	Input.action_press("agachar")
	await esperar(3)
	var teto := StaticBody2D.new()
	teto.position = jogador.position + Vector2(0,-24)
	var forma_teto := RectangleShape2D.new()
	forma_teto.size = Vector2(100,8)
	var colisor_teto := CollisionShape2D.new()
	colisor_teto.shape = forma_teto
	teto.add_child(colisor_teto)
	current_scene.add_child(teto)
	await esperar(3)
	Input.action_release("agachar")
	await esperar(3)
	conferir(jogador.estado == JogadorScript.Estado.AGACHADO and forma.size.y == 16.0, "Não levanta dentro de um teto baixo")
	teto.queue_free()
	await esperar(4)
	conferir(jogador.estado == JogadorScript.Estado.PARADO and forma.size.y == 32.0, "Levanta quando há espaço novamente")

	var outro: CharacterBody2D = load("res://cenas/jogador.tscn").instantiate()
	outro.position = Vector2(-660,519)
	outro.get_node("Camera2D").enabled = false
	current_scene.add_child(outro)
	outro.set_physics_process(false)
	Input.action_press("agachar")
	await esperar(3)
	conferir(outro.get_node("CollisionShape2D").shape.size == Vector2(24,32), "Agachar não altera o colisor de outra instância")
	await tocar("reiniciar")
	conferir(forma.size == Vector2(24,32) and jogador.estado == JogadorScript.Estado.PARADO, "Reiniciar agachado restaura o colisor e o estado")
	Input.action_release("agachar")
	outro.queue_free()
	await esperar(3)

	Input.action_press("direita")
	for frame: int in range(100):
		await esperar()
		if jogador.estado == JogadorScript.Estado.PULANDO:
			break
	Input.action_release("direita")
	conferir(not jogador.is_on_floor() and jogador.pulos_realizados == 1, "Sair de uma borda entra em pulando sem impulso")
	await tocar("pular")
	conferir(jogador.pulos_realizados == 2 and jogador.velocity.y < -500.0, "Resta um salto de recuperação ao cair da borda")
	print("ESTADOS_OK verificacoes=", verificacoes, " falhas=", falhas)
	quit(falhas)
