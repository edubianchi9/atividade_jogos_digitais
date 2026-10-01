@tool
extends Node2D

@export_enum("Montanhas", "Bosque", "Arbustos") var tipo: int = 0:
	set(valor):
		tipo = valor
		queue_redraw()
@export var cor: Color = Color("89b9b8"):
	set(valor):
		cor = valor
		queue_redraw()


func _draw() -> void:
	if tipo == 0:
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, 190), Vector2(80, 190), Vector2(80, 160),
			Vector2(160, 160), Vector2(160, 115), Vector2(240, 115),
			Vector2(240, 155), Vector2(340, 155), Vector2(340, 190),
			Vector2(480, 190), Vector2(480, 135), Vector2(570, 135),
			Vector2(570, 95), Vector2(640, 95), Vector2(640, 140),
			Vector2(730, 140), Vector2(730, 165), Vector2(880, 165),
			Vector2(880, 190), Vector2(1024, 190), Vector2(1024, 1200),
			Vector2(0, 1200)
		]), cor)
	else:
		var base: float = 255.0 if tipo == 1 else 330.0
		draw_rect(Rect2(0, base, 1024, 1200), cor)
		for indice: int in range(16):
			var x: float = indice * 64.0 + 32.0
			var altura: float = 42.0 + float((indice * 17) % 40)
			if tipo == 1:
				draw_rect(Rect2(x - 5.0, base - altura, 10, altura), cor)
				draw_rect(Rect2(x - 22.0, base - altura, 44, 35), cor)
				draw_rect(Rect2(x - 14.0, base - altura - 12.0, 28, 12), cor)
			else:
				draw_rect(Rect2(x - 28.0, base - altura * 0.3, 56, altura * 0.3), cor)
				draw_rect(Rect2(x - 16.0, base - altura * 0.5, 32, altura * 0.3), cor)
