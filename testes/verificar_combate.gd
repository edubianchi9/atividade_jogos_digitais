extends SceneTree

const Sobrevivente = preload("res://scripts/combate/sobrevivente.gd")
const Zumbi = preload("res://scripts/combate/zumbi.gd")

var jogador: CharacterBody2D
var lento: CharacterBody2D
var rapido: CharacterBody2D
var grande: CharacterBody2D
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


func nova_arena() -> void:
	change_scene_to_file("res://cenas/combate.tscn")
	await scene_changed
	jogador = current_scene.get_node("Sobrevivente")
	lento = current_scene.get_node("ZumbiLento")
	rapido = current_scene.get_node("ZumbiRapido")
	grande = current_scene.get_node("ZumbiGrande")
	await esperar(10)


func executar() -> void:
	await nova_arena()
	conferir(get_nodes_in_group("player").size() == 1, "Apenas o sobrevivente pertence ao grupo player")
	conferir(get_nodes_in_group("zumbis").size() == 3, "A arena instancia os três zumbis")
	conferir(jogador.is_on_floor() and lento.is_on_floor() and rapido.is_on_floor() and grande.is_on_floor(), "Os quatro personagens apoiam no piso")
	conferir(lento.get_script() == rapido.get_script() and lento.get_script() == grande.get_script(), "Os três zumbis compartilham o mesmo script")
	conferir([lento.vida, rapido.vida, grande.vida] == [4,2,8], "Vidas dos três tipos")
	conferir([lento.velocidade, rapido.velocidade, grande.velocidade] == [35.0,110.0,25.0], "Velocidades dos três tipos")
	conferir([lento.dano, rapido.dano, grande.dano] == [1,1,2], "Danos dos três tipos")
	conferir(jogador.vida == 5 and jogador.dano_do_golpe == 2, "Vida e dano iniciais do sobrevivente")
	conferir(current_scene.get_node("Camera2D").jogador == jogador, "A câmera encontra o sobrevivente pelo grupo")
	for ator: CharacterBody2D in [jogador,lento,rapido,grande]:
		var frames: SpriteFrames = ator.get_node("AnimatedSprite2D").sprite_frames
		conferir(not frames.get_animation_loop("attack") and not frames.get_animation_loop("hurt") and not frames.get_animation_loop("death"), "Ataque, dano e morte não repetem: " + ator.name)
	var x_inicial: float = jogador.position.x
	Input.action_press("direita")
	await esperar(12)
	Input.action_release("direita")
	await esperar(2)
	conferir(jogador.position.x > x_inicial + 20, "Anda com o controle de direção")
	await tocar("pular")
	await esperar(12)
	conferir(jogador.estado == Sobrevivente.Estado.PULANDO and jogador.position.y < 300, "Pulo usa o estado e deslocamento vertical")
	await esperar(55)
	conferir(jogador.is_on_floor() and jogador.estado == Sobrevivente.Estado.PARADO, "Retorna ao chão e ao estado parado")
	jogador.position.x = 220
	await esperar(3)
	conferir(lento.estado == Zumbi.Estado.PERSEGUINDO and lento.velocity.x < 0, "Zumbi persegue dentro da visão")
	conferir(lento.anim.flip_h and lento.area_ataque.position.x < 0, "Animação e área de ataque viram à esquerda")
	jogador.position.x = 100
	await esperar(3)
	conferir(lento.estado == Zumbi.Estado.PARADO, "Zumbi para ao perder o jogador de vista")
	jogador.position.x = lento.position.x + 100
	await esperar(3)
	conferir(not lento.anim.flip_h and lento.area_ataque.position.x > 0, "Zumbi também persegue à direita")

	await nova_arena()
	jogador.position.x = lento.position.x - 55
	await esperar(4)
	conferir(lento.estado == Zumbi.Estado.ATACANDO, "Zumbi entra em ataque na distância correta")
	conferir(jogador.vida == 5, "Entrar na área não aplica dano imediatamente")
	await esperar(21)
	conferir(jogador.vida == 5, "Preparação da animação não causa dano")
	await esperar(12)
	conferir(jogador.vida == 4 and lento.golpe_aplicado, "Impacto aplica exatamente um ponto de dano")
	jogador.levar_dano(2)
	conferir(jogador.vida == 4, "Invulnerabilidade impede dano durante hurt")
	await esperar(26)
	conferir(jogador.vida == 4 and jogador.estado == Sobrevivente.Estado.PARADO, "Mesmo ataque não repete dano após a invulnerabilidade")
	conferir(jogador.anim.modulate == Color.WHITE, "Cor volta ao normal após hurt")
	await esperar(52)
	conferir(jogador.vida == 3, "Novo ataque após o intervalo causa novo dano")

	await nova_arena()
	jogador.position.x = lento.position.x - 55
	await esperar(5)
	jogador.position.x = lento.position.x + 55
	await esperar(34)
	conferir(jogador.vida == 5 and lento.area_ataque.position.x < 0, "Golpe não vira nem acerta quem passou para trás durante a preparação")

	await nova_arena()
	lento.set_physics_process(false)
	jogador.position.x = lento.position.x - 75
	await esperar(3)
	await tocar("atacar")
	await esperar(30)
	conferir(lento.vida == 4, "Ataque do jogador aguarda o quadro de impacto")
	await esperar(10)
	conferir(lento.vida == 2 and jogador.vida == 5, "Golpe frontal causa dois de dano e não atinge o próprio jogador")
	lento.levar_dano(2)
	conferir(lento.vida == 2, "Zumbi ferido também tem invulnerabilidade temporária")
	await esperar(8)
	conferir(lento.vida == 2 and not jogador.area_golpe.monitoring, "Golpe único encerra e desativa a área")
	lento.go_to_parado()
	jogador.position.x = lento.position.x + 75
	jogador.olhar_para(-1)
	await esperar(3)
	await tocar("atacar")
	await esperar(40)
	conferir(lento.vida == 0 and lento.estado == Zumbi.Estado.MORTO, "Segundo golpe à esquerda mata o zumbi lento")
	var y_morte: float = lento.position.y
	await esperar(6)
	conferir(lento.get_node("CollisionShape2D").disabled and lento.position.y == y_morte, "Zumbi morto desativa colisão sem afundar")
	await esperar(45)
	conferir(not is_instance_valid(lento), "Zumbi é removido depois da animação de morte")
	conferir(current_scene.restantes == 2, "Contador atualiza quando um zumbi morre")

	await nova_arena()
	lento.set_physics_process(false)
	jogador.position.x = lento.position.x - 75
	await esperar(3)
	await tocar("atacar")
	await esperar(12)
	jogador.levar_dano(1)
	await esperar(40)
	conferir(lento.vida == 4 and not jogador.area_golpe.monitoring, "Dano interrompe o ataque do jogador antes do impacto")
	lento.set_physics_process(true)
	jogador.position.x = lento.position.x - 55
	await esperar(5)
	lento.levar_dano(2)
	await esperar(10)
	conferir(lento.estado == Zumbi.Estado.FERIDO and not lento.area_ataque.monitoring, "Dano interrompe e desativa o ataque do zumbi")
	await esperar(8)
	conferir(lento.estado != Zumbi.Estado.FERIDO, "Zumbi sai de hurt após o tempo configurado")
	jogador.levar_dano(100)
	await esperar(2)
	var posicao_morte: Vector2 = jogador.position
	Input.action_press("direita")
	await tocar("pular")
	await tocar("atacar")
	await esperar(50)
	Input.action_release("direita")
	conferir(jogador.vida == 0 and jogador.estado == Sobrevivente.Estado.MORTO, "Dano fatal limita a vida a zero e mantém o estado morto")
	conferir(jogador.position == posicao_morte and not jogador.is_physics_processing(), "Morto ignora movimento, pulo e ataque")
	conferir(jogador.anim.animation == &"death" and not jogador.anim.is_playing(), "Animação de morte termina sem voltar a idle")
	conferir(current_scene.get_node("Interface/Resultado").visible, "Derrota aparece na interface")
	Input.action_press("reiniciar")
	await scene_changed
	Input.action_release("reiniciar")
	await esperar(10)
	conferir(current_scene.get_node("Sobrevivente").vida == 5 and current_scene.restantes == 3, "R reinicia mesmo depois da morte")
	for inimigo: Node in get_nodes_in_group("zumbis"):
		inimigo.levar_dano(100)
	await esperar(2)
	conferir(current_scene.restantes == 0 and current_scene.get_node("Interface/Resultado").text.begins_with("ARENA CONCLUÍDA"), "Derrotar os três conclui a arena")
	await esperar(50)
	conferir(get_nodes_in_group("zumbis").is_empty(), "Os três corpos são removidos após a animação")
	await nova_arena()
	for inimigo: CharacterBody2D in [lento,rapido,grande]:
		var passos: int = 0
		Input.action_press("direita")
		while inimigo.position.x - jogador.position.x > 80.0 and passos < 400:
			await esperar()
			passos += 1
		Input.action_release("direita")
		await esperar(2)
		var tipo: String = inimigo.name
		var rodadas: int = 0
		while is_instance_valid(inimigo) and inimigo.vida > 0 and jogador.esta_vivo() and rodadas < 10:
			if jogador.estado in [Sobrevivente.Estado.PARADO, Sobrevivente.Estado.ANDANDO]:
				await tocar("atacar")
			while jogador.estado in [Sobrevivente.Estado.ATACANDO, Sobrevivente.Estado.FERIDO]:
				await esperar()
			rodadas += 1
			if is_instance_valid(inimigo) and inimigo.vida > 0:
				Input.action_press("esquerda")
				await esperar(12)
				Input.action_release("esquerda")
				Input.action_press("direita")
				await esperar(2)
				Input.action_release("direita")
				await esperar(2)
				passos = 0
				while inimigo.position.x - jogador.position.x > 80 and passos < 180:
					await esperar()
					passos += 1
		conferir(jogador.esta_vivo() and (not is_instance_valid(inimigo) or inimigo.vida == 0), "Partida pelos controles consegue derrotar " + tipo)
	conferir(current_scene.restantes == 0, "É possível vencer os três em sequência usando J")
	print("COMBATE: %d verificações, %d falhas" % [verificacoes,falhas])
	quit(1 if falhas else 0)
