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
	
	#qual a última parada do elevador?
	#	- a coleta está no meio do caminho? o fluxo do pedido coincide com o do elevador?
	#	- se o fluxo do pedido não coincide com o do elevador, a última parada coincide com a coleta?
	#	
	
	lw	$s0, coleta
	lw	$s1, entrega
	lw	$s2, fluxo
	
	lw	$t0, fluxo1
	lw	$t1, fluxo2
	bne	$t1, $zero, avaliaelevador1
	bne	$t0, $zero, avaliaelevador1
	#chega aqui se ambos elevadores estão parados
	lw	$t0, andar1
	sub	$t0, $t0, $s0
	abs	$t0, $t0			#distância do elevador 1 para a coleta
	
	lw	$t1, andar2
	sub	$t1, $t1, $s0
	abs	$t1, $t1			#distância do elevador 2 para a coleta
	
	blt	$t1, $t0, atribuielevador2
	j	atribuielevador1
	
avaliaelevador1:
	lw	$t0, fluxo1
	lw	$t1, andar1
	add	$t2, $t0, $s2			#t2 = fluxo1 + fluxo
	beq	$t2, $zero, avaliaelevador2	#se os fluxos são inversos, E1 não pode ser alocado 
						#@TODO -> e se o último destino coincidir com a coleta? avaliar isso?
	mulo	$t0, $t0, $s0
	add	$t0, $t0, $t1			#t0 = andar1 + (coleta * fluxo1)
	bgt	$t0, $zero, atribuielevador1	#se positivo, a coleta está no caminho do elevador
avaliaelevador2:
	lw	$t0, fluxo2
	lw	$t1, andar2
	mulo	$t0, $t0, $s0
	add	$t0, $t0, $t1			#t0 = andar2 + (coleta * fluxo2)
	bgt	$t0, $zero, atribuielevador2	#se positivo, a coleta está no caminho do elevador

# Se chegou aqui, sabemos do seguinte:
# I- O fluxo do pedido é contrário ao fluxo do elevador 1 OU o elevador 1 já passou do andar da coleta
# II- O elevador 2 já passou do andar da coleta
# A execução continuará a partir daqui, e o elevador 1 receberá este pedido
# OBS: não verificamos se o fluxo do pedido é contrário ao fluxo do elevador 2 pois o pedido precisa ser atendido por algum deles
 
atribuielevador1:
	la	$s3, lista1
	lw	$s4, tamanholista1
	
	lw	$t2, fluxo1
	blt	$t2, $zero, lista1decrescente
lista1crescente:
	move	$a0, $s3		#a0 recebe o endereço da lista
	move	$a1, $s4		#a1 recebe o tamanho da lista
	move	$a3, $s0		#a3 recebe o elemento a ser incluído na lista
	jal	adicionalistacrescente
	move	$a3, $s1
	jal	adicionalistacrescente
	
	j	pedidoatendido
lista1decrescente:
	move	$a0, $s3
	move	$a1, $s4
	move	$a3, $s0
	jal	adicionalistadecrescente
	move	$a3, $s1
	jal	adicionalistadecrescente
	
	j	pedidoatendido
	
atribuielevador2:
	la	$s3, lista2
	lw	$s4, tamanholista2
	
	lw	$t2, fluxo1
	add	$t2, $t0, $s2			#t2 = flux02 + fluxo
	beq	$t2, $zero, finaldalista	#se os fluxos são inversos o elevador2 será responsável por atender ao finalizar sua lista
	blt	$t2, $zero, lista2decrescente
lista2crescente:
	move	$a0, $s3		#a0 recebe o endereço da lista
	move	$a1, $s4		#a1 recebe o tamanho da lista
	move	$a3, $s0		#a3 recebe o elemento a ser incluído na lista
	jal	adicionalistacrescente
	move	$a3, $s1
	jal	adicionalistacrescente
	
	j	pedidoatendido
lista2decrescente:
	move	$a0, $s3
	move	$a1, $s4
	move	$a3, $s0
	jal	adicionalistadecrescente
	move	$a3, $s1
	jal	adicionalistadecrescente
	
	j	pedidoatendido
finaldalista:
	sll	$s4, $s4, 2
	add	$s3, $s3, $s4
	sw	$s0, 0($s3)
	sw	$s1, 4($s3)

pedidoatendido:
	li	$t0, 1
	sw	$t0, pronto
	j	looppedido

# ======= PROCEDIMENTOS =======
adicionalistacrescente:
	li	$t9, 0		#contador para percorrer a lista
	lw	$t8, 0($a0)
	bgt	$a3, $t8, condicional1
	sw	$a3, 0($a0)
	move	$a3, $t8
condicional1:
	addi	$a0, $a0, 4
	addi	$t9, $t9, 1
	blt	$t9, $a1, adicionalistacrescente
	jr	$ra
	
adicionalistadecrescente:
	li	$t9, 0		#contador para percorrer a lista
	lw	$t8, 0($a0)
	blt	$a3, $t8, condicional2
	sw	$a3, 0($a0)
	move	$a3, $t8
condicional2:
	addi	$a0, $a0, 4
	addi	$t9, $t9, 1
	blt	$t9, $a1, adicionalistadecrescente
	jr	$ra