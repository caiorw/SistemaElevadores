.include	"labels.asm"
.globl		controle, destino1, destino2
.data
	destino1:	.word 0
	destino2: 	.word 0
	lista1:		.space 32
	lista2:		.space 32
	tamanholista1:	.word 0
	tamanholista2:	.word 0
	# variáveis globais a disposição: 
	# 	coleta (definido em teclado)
	# 	fluxo (definido em teclado)
	# 	entrega (definido em teclado)
	# 	fluxo1 (definido em elevador1)
	# 	fluxo2 (definido em elevador2)
	#	andar1
	#	andar2
.text
controle:
	# @todo:
	# - coleta está mais perto de andar1 ou andar2? check
	# - se andar1: andar1 = coleta e fluxo1 = fluxo. quando fluxo1 == 0, andar1 = entrega
	# - se andar2: andar2 = coleta e fluxo2 = fluxo. quando fluxo2 == 0, andar2 = entrega
	# precisamos de lista???
	
	# duas listas: uma para cada elevador
	# andares ordenados em ordem de atendimento: qual elevador alocar basta ver o último item da lista
	# importante: coleta e entrega sempre vão ser alocados pro mesmo elevador
	# PRIORIDADE: DISTANCIA DOS ELEVADORES
	# segue o fluxo? 
	#	sim: reordena lista em ordem crescente/descrescente (subindo ou descendo)
	#	não: adiciona final da lista
looppedido:
	lw	$t0, pronto
	beq	$t0, $zero, looppedido		#enquanto o teclado não indicar que há um pedido a ser processado
	sw	$zero, pronto
	
	lw	$s0, coleta
	
	lw	$t0, tamanholista1
	bne	$t0, $zero, conferelista1	#tem coisa na lista
	lw	$s1, andar1
	j continuaconfere1
conferelista1:
	la	$t1, lista1
	sll	$t0, $t0, 2		#multiplica a quantidade de itens na lista por 4
	add	$t1, $t1, $t0
	lw	$s1, 0($t1)		#acessa o último item da lista
	#s1 será o andar para comparação do elevador 1
continuaconfere1:

	lw	$t0, tamanholista2
	bne	$t0, $zero, conferelista2	#tem coisa na lista
	lw	$s2, andar2
	j continuaconfere2
conferelista1:
	la	$t1, lista2
	sll	$t0, $t0, 2		#multiplica a quantidade de itens na lista por 4
	add	$t1, $t1, $t0
	lw	$s2, 0($t1)		#acessa o último item da lista
	#s2 será o andar para comparação do elevador 2
continuaconfere2:
	
	sub	$s1, $s1, $s0
	abs	$s1, $s1
	sub	$s2, $s2, $s0
	abs	$s2, $s2
	
	blt	$s2, $s1, mandaelevador2
mandaelevador1:
	sw	$s0, destino1
	
mandaelevador2:
	sw	$s0, destino2
	
	j controle
