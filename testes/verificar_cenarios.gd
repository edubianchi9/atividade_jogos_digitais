extends SceneTree

var jogador: CharacterBody2D
var falhas: int = 0
var verificacoes: int = 0
var capturar: bool = false
var destino_prints: String = ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		capturar = true
		destino_prints = args[0]
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	call_deferred("executar")


func tick(quantidade: int = 1) -> void:
	for i: int in range(quantidade):
		await physics_frame
		await process_frame


func conferir(condicao: bool, mensagem: String) -> void:
	verificacoes += 1
	if not condicao:
		falhas += 1
		push_error(mensagem)


func print_jogo(nome: String) -> void:
	if capturar:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(destino_prints.path_join(nome + ".png"))


func andar_ate(x: float) -> void:
	var direcao: float = signf(x - jogador.position.x)
	var acao: String = "direita" if direcao > 0 else "esquerda"
	Input.action_press(acao)
	for i: int in range(300):
		await tick()
		if (jogador.position.x - x) * direcao >= -3.0:
			break
	Input.action_release(acao)
	await tick(2)
	conferir(absf(jogador.position.x-x)<10,"Alcança x=%s, atual=%s" % [x,jogador.position])


func saltar_ate(x: float, y: float) -> void:
	await tick(2)
	Input.action_press("pular")
	await tick()
	Input.action_release("pular")
	await andar_ate(x)
	for i: int in range(120):
		await tick()
		if jogador.is_on_floor():
			break
	conferir(absf(jogador.position.y-y)<3,"Pousa em y=%s, atual=%s" % [y,jogador.position])


func percurso_chao() -> void:
	await andar_ate(154)
	await saltar_ate(264,144)
	await andar_ate(356)
	await saltar_ate(476,144)
	await andar_ate(526)
	await saltar_ate(668,176)


func estrutura(numero: int) -> void:
	var terrain: TileMapLayer = current_scene.get_node("tiles/terrain")
	conferir(terrain.get_used_rect().position.x==0 and terrain.get_used_rect().end.x==63,"63 colunas de largura")
	conferir(terrain.get_cell_source_id(Vector2i(0,5))!=-1 and terrain.get_cell_source_id(Vector2i(62,5))!=-1,"Paredes nas duas pontas")
	var dec: TileMapLayer = current_scene.get_node("tiles/decoration")
	conferir(not dec.collision_enabled and dec.get_used_cells().size()>=3,"Decoração atravessável")
	var camera: Camera2D = current_scene.get_node("Camera2D")
	conferir(camera.limit_right==1008 and camera.limit_left==0 and camera.limit_bottom==208,"Limites da câmera")
	conferir(get_nodes_in_group("player").size()==1 and camera.jogador==jogador,"Câmera separada encontra o grupo player")
	if numero==1:
		conferir(camera.limit_top==0,"Câmera 1 não sobe")
		var parallax: ParallaxBackground = current_scene.get_node("ParallaxBackground")
		conferir(parallax.get_child_count()==3,"Três planos de parallax")
		var anterior: float = 0
		for plano: ParallaxLayer in parallax.get_children():
			conferir(plano.motion_scale.x>anterior and plano.motion_scale.x<1 and plano.motion_mirroring.x==288,"Velocidade e repetição do parallax")
			anterior=plano.motion_scale.x
	else:
		conferir(camera.limit_top < -272,"Câmera 2 alcança a sala")
		for i: int in range(5):
			var cell := Vector2i(46 if i==3 else (43 if i%2==0 else 49),7-i*4)
			conferir(terrain.get_cell_tile_data(cell).is_collision_polygon_one_way(0,0),"Plataforma de sentido único")
		var falso: TileMapLayer=current_scene.get_node("tiles/terrenoFalso")
		conferir(falso.tile_set.get_physics_layers_count()==0 and falso.z_index>jogador.z_index,"Parede falsa sem física e na frente do personagem")
		conferir(terrain.get_cell_source_id(Vector2i(50,-14))==-1,"Passagem aberta no terreno sólido")


func executar() -> void:
	change_scene_to_file("res://scenes/cenario_1.tscn")
	await scene_changed
	jogador=current_scene.get_node("player")
	await tick(8)
	estrutura(1)
	await print_jogo("01-campo-parallax")
	Input.action_press("esquerda")
	await tick(40)
	Input.action_release("esquerda")
	conferir(jogador.position.x>=27 and jogador.position.x<30,"Parede esquerda segura o personagem")
	await print_jogo("02-parede")
	await percurso_chao()
	Input.action_press("direita")
	await scene_changed
	Input.action_release("direita")
	conferir(current_scene.name=="Cenario2","Portal leva ao cenário 2")
	jogador=current_scene.get_node("player")
	await tick(8)
	estrutura(2)
	await percurso_chao()
	await saltar_ate(728,112)
	await saltar_ate(824,48)
	await saltar_ate(728,-16)
	await saltar_ate(776,-80)
	await saltar_ate(728,-144)
	await print_jogo("03-alto-da-subida")
	await saltar_ate(848,-192)
	await andar_ate(888)
	conferir(jogador.position.y < -180 and jogador.position.x > 816,"Entra pela parede falsa")
	await print_jogo("04-camara-secreta")
	Input.action_press("direita")
	await scene_changed
	Input.action_release("direita")
	conferir(current_scene.name=="Cenario1","Portal secreto retorna ao cenário 1")
	print("CENARIOS: %d verificações, %d falhas" % [verificacoes,falhas])
	quit(falhas)
