extends SceneTree

var falhas: int = 0
var saltos: int = 0

func _initialize() -> void:
	call_deferred("executar")

func conferir(condicao: bool, texto: String) -> bool:
	if not condicao:
		falhas += 1
		push_error(texto)
		quit(1)
	return condicao

func tick() -> void:
	await physics_frame
	await process_frame

func parar() -> void:
	Input.action_release("esquerda")
	Input.action_release("direita")
	Input.action_release("pular")

func direcao(valor: float) -> void:
	Input.action_release("esquerda")
	Input.action_release("direita")
	if valor > 0:
		Input.action_press("direita")
	elif valor < 0:
		Input.action_press("esquerda")

func abrir(nome: String) -> void:
	parar()
	change_scene_to_file("res://cenas/" + nome + ".tscn")
	await scene_changed
	for frame: int in range(8):
		await tick()
	var jogador: CharacterBody2D = current_scene.get_node("Jogador")
	conferir(jogador.is_on_floor(), nome + ": início fora do chão")
	conferir(jogador.collision_layer == 2 and jogador.collision_mask == 1, "Camadas do jogador incorretas")
	conferir(current_scene.find_children("*", "Camera2D", true, false).size() == 1, "Deve existir uma câmera")
	for area: Node in current_scene.find_children("*", "Area2D", true, false):
		conferir(area.collision_mask == 2, "Sensor deve detectar apenas o jogador")
	if nome != "sala_tesouro":
		var terreno: TileMapLayer = current_scene.get_node("Terreno")
		conferir(terreno.get_used_rect().size.x * 16 >= 3 * 576, "Fase menor que três telas")
		conferir(current_scene.get_node("ParallaxFundo").get_child_count() >= 3, "Parallax incompleto")
	print("ESTRUTURA_OK ", nome)

func andar_ate(x: float) -> bool:
	var jogador: CharacterBody2D = current_scene.get_node("Jogador")
	for frame: int in range(600):
		var distancia: float = x - jogador.position.x
		if absf(distancia) <= 5.0:
			parar()
			await tick()
			return true
		direcao(signf(distancia))
		await tick()
	parar()
	return conferir(false, "Não conseguiu andar até x=" + str(x) + "; posição=" + str(jogador.position))

func saltar(origem_x: float, destino_x: float, piso_y: float) -> bool:
	if not await andar_ate(origem_x):
		return false
	var jogador: CharacterBody2D = current_scene.get_node("Jogador")
	if not conferir(jogador.is_on_floor(), "Salto iniciado no ar em " + str(jogador.position)):
		return false
	direcao(signf(destino_x - jogador.position.x))
	Input.action_press("pular")
	await tick()
	Input.action_release("pular")
	for frame: int in range(100):
		var distancia: float = destino_x - jogador.position.x
		direcao(signf(distancia) if absf(distancia) > 4.0 else 0.0)
		await tick()
		if jogador.is_on_floor() and frame > 2:
			parar()
			if not conferir(absf(jogador.position.y - piso_y) <= 2.0, "Salto de " + str(origem_x) + " para " + str(destino_x) + ": piso esperado " + str(piso_y) + ", posição " + str(jogador.position)):
				return false
			saltos += 1
			return true
	parar()
	return conferir(false, "Salto sem pouso de " + str(origem_x) + " para " + str(destino_x) + "; posição=" + str(jogador.position))

func rota(passos: Array) -> bool:
	for passo: Array in passos:
		if not await saltar(passo[0], passo[1], passo[2]):
			return false
	return true

func passar_portal(sentido: float, destino: String) -> bool:
	var antiga: Node = current_scene
	direcao(sentido)
	for frame: int in range(650):
		await tick()
		if current_scene != antiga and current_scene != null:
			parar()
			for espera: int in range(8):
				await tick()
			var jogador: CharacterBody2D = current_scene.get_node("Jogador")
			if not conferir(current_scene.scene_file_path.ends_with(destino + ".tscn"), "Destino incorreto"):
				return false
			if not conferir(jogador.position.distance_to(current_scene.get_node("Inicio").position) < 20.0, "Jogador não reapareceu no início"):
				return false
			conferir(jogador.is_on_floor(), "Chegada fora do chão")
			print("TRANSICAO_OK ", destino)
			return true
	parar()
	return conferir(false, "Portal não disparou para " + destino)

func inicio_neve() -> bool:
	return await rota([
		[-440.0,-352.0,519.0], [-328.0,-240.0,519.0], [-216.0,-112.0,519.0],
		[184.0,312.0,503.0], [360.0,456.0,519.0], [488.0,624.0,439.0],
		[728.0,864.0,359.0], [968.0,1088.0,279.0], [1136.0,1136.0,199.0],
		[1192.0,1312.0,119.0], [1416.0,1536.0,39.0]
	])

func executar() -> void:
	await abrir("fase_1")
	if not await rota([
		[-440.0,-352.0,519.0], [-328.0,-240.0,519.0], [-216.0,-112.0,519.0],
		[184.0,336.0,519.0], [664.0,800.0,455.0], [1112.0,1264.0,519.0],
		[1656.0,1808.0,455.0]
	]):
		return
	if not await passar_portal(1.0, "fase_2"):
		return
	if not await inicio_neve():
		return
	if not await rota([
		[1528.0,1408.0,-41.0], [1304.0,1184.0,-121.0], [1136.0,1136.0,-201.0],
		[1192.0,1312.0,-281.0], [1416.0,1536.0,-361.0], [1528.0,1408.0,-441.0]
	]):
		return
	if not await passar_portal(-1.0, "fase_1"):
		return
	await abrir("fase_2")
	if not await inicio_neve():
		return
	if not await saltar(1640.0,1776.0,103.0):
		return
	if not await andar_ate(1990.0):
		return
	if not conferir(not current_scene.has_node("CristalSecreto"), "Cristal não foi coletado"):
		return
	var parede: TileMapLayer = current_scene.get_node("ParedeFalsa")
	conferir(not parede.collision_enabled and parede.z_index > 1, "Parede falsa incorreta")
	print("SEGREDO_OK")
	if not await passar_portal(1.0, "sala_tesouro"):
		return
	if not await andar_ate(380.0):
		return
	if not conferir(not current_scene.has_node("CristalSecreto"), "Tesouro não foi coletado"):
		return
	if not await passar_portal(1.0, "fase_2"):
		return
	var jogador: CharacterBody2D = current_scene.get_node("Jogador")
	jogador.position.y = jogador.altura_queda + 10.0
	for frame: int in range(4):
		await tick()
	conferir(jogador.position.distance_to(current_scene.get_node("Inicio").position) < 2.0, "Reinício após queda falhou")
	print("TESTES_OK saltos=", saltos, " falhas=", falhas)
	quit(falhas)
