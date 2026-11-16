.include	"labels.asm"
.globl		controle, destino1, destino2
.data
	destino1:	.word 0
	destino2: 	.word 0
	lista1:		.space 64	# cabem 8 usuários por elevador (8 * 2 * 4)
	lista2:		.space 64	# 8 usuarios * 2 pontos (origem / destino) * 4 byte
	tamanholista1:	.word 0
	tamanholista2:	.word 0
	avisou_cheio:	.word 0
	lotado_txt:	.asciiz	"Elevador lotado. Aguarde, o pedido sera atendido assim que houver espaco.\n"
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
	# duas listas: uma para cada elevador
	# PRIORIDADE: DISTANCIA DOS ELEVADORES
	# segue o fluxo? 
	#	sim: reordena lista em ordem crescente/descrescente (subindo ou descendo)
	#	não: adiciona final da lista
looppedido:
	# looppedido -> tem pedido novo?
	#	não -> cuidar_elevadores
	#	sim -> escolhe o elevador. elevador tem espaço?
	#		sim -> insere na lista -> pedidoatendido -> cuidar_elevadores
	#		nao -> lista_cheia -> cuidar_elevadores
	# cuidar_elevadores -> j looppedido
	
	lw	$t0, pronto
	beq	$t0, $zero, cuidar_elevadores		#enquanto o teclado não indicar que há um pedido a ser processado
	
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
	sub	$t2, $s0, $t1
	mul	$t0, $t0, $t2			# $t0 =  (coleta - andar1) * fluxo1
						
	bgt	$t0, $zero, atribuielevador1	#se positivo, a coleta está no caminho do elevador
avaliaelevador2:
	lw	$t0, fluxo2
	lw	$t1, andar2
	sub	$t2, $s0, $t1
	mul	$t0, $t0, $t2			# $t0 =  (coleta - andar2) * fluxo2
	bgt	$t0, $zero, atribuielevador2	#se positivo, a coleta está no caminho do elevador

# Se chegou aqui, sabemos do seguinte:
# I- O fluxo do pedido é contrário ao fluxo do elevador 1 OU o elevador 1 já passou do andar da coleta
# II- O elevador 2 já passou do andar da coleta
# A execução continuará a partir daqui, e o elevador 1 receberá este pedido
# OBS: não verificamos se o fluxo do pedido é contrário ao fluxo do elevador 2 pois o pedido precisa ser atendido por algum deles
 
atribuielevador1:
	la	$s3, lista1
	la	$s4, tamanholista1
	
	lw	$t0, 0($s4)		# verifica se elevador está cheio
	addi	$t0, $t0, 2		
	li	$t1, 16
	bgt	$t0, $t1, lista_cheia
	
	lw	$t2, fluxo1
	add	$t2, $t2, $s2
	beq	$t2, $zero, finaldalista	#se os fluxos são inversos o elevador1 será responsável por atender ao finalizar sua lista
	blt	$t2, $zero, lista1decrescente
lista1crescente:
	move	$a0, $s3		#a0 recebe o endereço da lista
	move	$a1, $s4		#a1 recebe o endereço do tamanho da lista
	move	$a3, $s0		#a3 recebe o elemento a ser incluído na lista
	jal	adicionalistacrescente
	move	$a0, $s3
	move	$a3, $s1
	jal	adicionalistacrescente
	
	j	pedidoatendido
lista1decrescente:
	move	$a0, $s3
	move	$a1, $s4
	move	$a3, $s0
	jal	adicionalistadecrescente
	move	$a0, $s3
	move	$a3, $s1
	jal	adicionalistadecrescente
	
	j	pedidoatendido
	
atribuielevador2:
	la	$s3, lista2
	la	$s4, tamanholista2
	
	lw	$t0, 0($s4)		# verifica se elevador está cheio
	addi	$t0, $t0, 2
	li	$t1, 16
	bgt	$t0, $t1, lista_cheia
	
	lw	$t2, fluxo2
	add	$t2, $t2, $s2			#t2 = flux02 + fluxo
	beq	$t2, $zero, finaldalista	#se os fluxos são inversos o elevador2 será responsável por atender ao finalizar sua lista
	blt	$t2, $zero, lista2decrescente
lista2crescente:
	move	$a0, $s3		#a0 recebe o endereço da lista
	move	$a1, $s4		#a1 recebe o endereço do tamanho da lista
	move	$a3, $s0		#a3 recebe o elemento a ser incluído na lista
	jal	adicionalistacrescente
	move	$a0, $s3
	move	$a3, $s1
	jal	adicionalistacrescente
	
	j	pedidoatendido
lista2decrescente:
	move	$a0, $s3
	move	$a1, $s4
	move	$a3, $s0
	jal	adicionalistadecrescente
	move	$a0, $s3
	move	$a3, $s1
	jal	adicionalistadecrescente
	
	j	pedidoatendido
finaldalista:
	lw	$t0, 0($s4)		# t0 = tamanho (s4 é o endereço)
	sll	$t1, $t0, 2		# posição do fim da lista
	add	$t1, $s3, $t1
	sw	$s0, 0($t1)		# coleta
	sw	$s1, 4($t1)		# entrega
	addi	$t0, $t0, 2
	sw	$t0, 0($s4)		# atualiza o tamanho

pedidoatendido:
	sw	$zero, pronto		#libera teclado
	sw	$zero, avisou_cheio	# pode imprimir que ta lotado dnv (evita ficar imprimindo infinitamente)
	j	cuidar_elevadores

lista_cheia:				# não zera o pronto: o pedido continua esperando
	lw	$t0, avisou_cheio
	bnez	$t0, cuidar_elevadores	# já avisou: não repete a mensagem
	li	$v0, 4
	la	$a0, lotado_txt
	syscall
	li	$t0, 1
	sw	$t0, avisou_cheio

cuidar_elevadores:
	# @todo: cuidar do elevador 1
	# @todo: cuidar do elevador 2
	j	looppedido

# ======= PROCEDIMENTOS =======
adicionalistacrescente:
	li	$t9, 0		#contador para percorrer a lista
	lw	$t7, 0($a1)	# carrega tamanho da lista (a1 é o endereço)
posinicializacao_alc:	# bloco para não ficar resetando contador
	bge	$t9, $t7, fim_alc	#testa se lista ta vazia OU contador chegou no fim da lista. Caso esteja vazia, so adiciona item e vai embora
	lw	$t8, 0($a0)	# t8 = elemento do iterador da lista
	bgt	$a3, $t8, condicional1
	
	sw	$a3, 0($a0)	# se for menor, guarda naquela posição da lista
	move	$a3, $t8	# passa antiga posição p frente
condicional1:
	addi	$a0, $a0, 4	# avança na lista
	addi	$t9, $t9, 1	# avança contador
	j	posinicializacao_alc
fim_alc:
	sw	$a3, 0($a0)
	addi	$t7, $t7, 1
	sw	$t7, 0($a1)	# atualiza tamanho da lista
	jr	$ra



adicionalistadecrescente:
	li	$t9, 0		#contador para percorrer a lista
	lw	$t7, 0($a1)	# carrega tamanho da lista (a1 é o endereço)
posinicializacao_ald:	# bloco para não ficar resetando contador
	bge	$t9, $t7, fim_ald	#testa se lista ta vazia OU contador chegou no fim da lista. Caso esteja vazia, so adiciona item e vai embora
	lw	$t8, 0($a0)	# t8 = elemento do iterador da lista
	blt	$a3, $t8, condicional2
	
	sw	$a3, 0($a0)	# se for maior ou igual, guarda naquela posição da lista
	move	$a3, $t8	# passa antiga posição p frente
condicional2:
	addi	$a0, $a0, 4	# avança na lista
	addi	$t9, $t9, 1	# avança contador
	j	posinicializacao_ald
fim_ald:
	sw	$a3, 0($a0)
	addi	$t7, $t7, 1
	sw	$t7, 0($a1)	# atualiza tamanho da lista
	jr	$ra
