# Atividade 2 - Duas fases que se ligam

## 1. As duas fases

### Campo Verde

Tema: campo aberto, com grama, árvores e silhuetas verdes ao fundo.
Percurso: atravessar ilhas separadas por vãos e usar plataformas suspensas até o portal à direita.
Decisão: o trajeto é principalmente horizontal, para apresentar os saltos antes da subida da segunda fase.

### Subida na Neve

Tema: plataformas cobertas de neve diante de montanhas, com tons mais frios nas partes altas.
Percurso: subir pelas plataformas até o portal do topo ou explorar o desvio à direita em busca da sala secreta.
Decisão: manter o percurso vertical e separar o destino principal da recompensa opcional incentiva a exploração.

As duas fases medem 2.896 pixels de largura. A janela lógica mede 1.152 × 648,
com zoom 2 na câmera: o jogador vê 576 × 324 pixels do mundo por vez.
Assim, cada fase tem pouco mais de cinco telas de largura.

## 2. O parallax

Cada fase usa um `ParallaxBackground` com três `ParallaxLayer`.

| Fase | Camada | motion_scale (X, Y) | Efeito pretendido |
| Campo | Distante | (0.12, 0.08) | Montanhas se deslocam pouco e parecem distantes. |
| Campo | Média | (0.35, 0.22) | O bosque apresenta um movimento intermediário. |
| Campo | Próxima | (0.65, 0.45) | Os arbustos se deslocam mais e dão sensação de proximidade. |
| Neve | Distante | (0.15, 0.10) | A montanha maior permanece como referência durante a subida. |
| Neve | Média | (0.40, 0.30) | As montanhas menores se separam visualmente da camada distante. |
| Neve | Próxima | (0.70, 0.55) | A paisagem próxima sai da vista mais rapidamente quando o jogador sobe. |

Antes desta revisão, os fatores eram (0.15, 0.15), (0.40, 0.40) e (0.70, 0.70).
As três camadas do campo existiam, mas seus `TileMapLayer` estavam vazios.
Elas receberam desenhos de montanhas, bosque e arbustos. Os fatores verticais
foram reduzidos para manter as paisagens visíveis por mais tempo durante os saltos.

Na neve, as imagens de 288 pixels de largura foram ampliadas três vezes.
Por isso, a repetição horizontal foi ajustada para 864 pixels, evitando um
intervalo diferente da largura da imagem exibida. No campo, o desenho mede
1.024 pixels e a repetição também é de 1.024 pixels.

Na subida da fase de neve, o movimento vertical do parallax revela partes
diferentes da paisagem. Além disso, o fundo recebe gradualmente uma tonalidade
azulada entre a altura inicial (Y = 519) e o topo (Y = -441).

Os resultados foram conferidos em capturas geradas pelo próprio Godot no
início, no meio e no topo do percurso.

## 3. A área secreta

A pista está na plataforma com as três placas, perto de (1632, 8): há um
pequeno losango azul que repete a aparência do cristal da sala.
A entrada fica mais à direita, na parede esquerda da sala, em X = 1904,
entre Y = 87 e Y = 135. Uma plataforma intermediária permite chegar até lá.

A pista e a entrada ficam separadas para que o jogador investigue o caminho.
A camada `ParedeFalsa` usa o mesmo alinhamento do `Terreno`, mas tem
`collision_enabled = false` e `z_index = 2`. O jogador tem `z_index = 1`,
portanto fica escondido atrás dos tiles enquanto atravessa a entrada.

O piso da sala é sólido para impedir que o jogador simplesmente entre pelo
chão. Dentro dela há um cristal coletável e um portal para o Refúgio de Cristal.
O refúgio contém outra recompensa e um portal que retorna ao início da neve.

## 4. A câmera

A câmera é filha do personagem. Essa opção permite reaproveitar a cena
`jogador.tscn` nas três fases e manter apenas uma câmera ativa por vez.
Ao trocar de fase, a cena anterior é removida e a nova recebe o jogador com sua câmera.

O script `fase.gd` mede o retângulo usado pelo `Terreno`, multiplica pelo
tamanho dos tiles (16 × 16) e considera a posição da camada. Nas duas fases
principais, os limites horizontais são -768 e 2128. O limite inferior termina
no fim dos tiles; o superior também reserva espaço para a altura do pulo e
os 32 pixels do personagem.

Com uma câmera independente, seria mais fácil trocar o alvo para outro
personagem ou para uma cena narrativa. A câmera filha fica vinculada ao jogador,
mas é suficiente para este projeto.

Para manter os pixels estáveis, a janela usa modo `viewport`, proporção
preservada e escala inteira. As texturas usam filtro de vizinho mais próximo,
as transformações 2D são alinhadas a pixels e a câmera acompanha a física,
sem suavização. A estabilidade em movimento ainda deve ser conferida no
computador usado para gravar o vídeo.

## 5. A transição

`fim_fase.tscn` é uma entidade reutilizável com um `Area2D` e um sensor.
O script exporta `destino` com `@export_file("*.tscn")`. Cada instância escolhe
o arquivo da próxima cena no Inspetor, sem duplicar o script.

| Portal | Destino |
| Saída do Campo Verde | Subida na Neve |
| Portal no topo da neve | Campo Verde |
| Portal dentro da sala secreta | Refúgio de Cristal |
| Saída do refúgio | Subida na Neve |

As camadas físicas são: 1 = Terreno, 2 = Jogador, 3 = Portais e 4 = Coletáveis.
O jogador está na camada 2 e procura colisões com a camada 1. Os portais
e os cristais têm máscara apenas para a camada 2. O script também verifica
o grupo `jogador`, evitando que outros corpos disparem a troca.

O sinal `body_entered` é emitido durante o processamento da física. Trocar a
cena imediatamente pode remover corpos e áreas enquanto o motor ainda está
processando essas colisões. Por isso, o portal agenda `_trocar_fase` com
`call_deferred()`. A função chama `change_scene_to_file()` depois, em um momento
seguro. Uma variável impede que o mesmo portal agende a troca várias vezes.

Cada fase tem um `Marker2D` chamado `Inicio`. O jogador é colocado nesse ponto
ao carregar a fase e volta para ele se cair ou se a tecla R for pressionada.

## 6. O que travou

A mudança de cor do céu durante a subida
não aparecia na primeira captura do jogo. O script alterava o `ColorRect` do
céu, mas a imagem opaca da montanha distante cobria esse fundo.
A causa foi identificada comparando as capturas do início e do topo e
verificando a ordem das camadas. A correção foi aplicar a variação de cor
também aos `Sprite2D` das montanhas, usando a altura do jogador. A nova captura
do topo permite conferir a tonalidade mais fria.

Ao configurar o fundo de inverno, percebi que as imagens apareciam deslocadas durante o teste do jogo.
Primeiro pensei que o problema fosse a opção “Centered” do Sprite2D, mas conferi no Inspetor e ela já estava desativada.
Então revisei as posições e os offsets das camadas do Parallax e fiz novos testes. Descobri que o desalinhamento estava relacionado ao posicionamento dessas camadas.
Depois dos ajustes, o fundo apareceu no jogo e pude observar que as montanhas distantes se moviam mais devagar que os elementos próximos.
