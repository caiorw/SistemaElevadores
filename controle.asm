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
	viajando1:	.word 0	# 1 = o controle mandou o elevador e ele ainda nao chegou
	viajando2:	.word 0
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
	
	# 1o: algum elevador ja vai passar pela coleta, no mesmo sentido? (carona)
	# 2o: se nenhum vai, escolhe o que termina o trabalho mais perto da coleta.
avaliaelevador1:
	lw	$t0, fluxo1
	lw	$t1, andar1
	add	$t2, $t0, $s2			#t2 = fluxo1 + fluxo
	beq	$t2, $zero, avaliaelevador2	#se os fluxos são inversos, E1 não pode dar carona
	sub	$t2, $s0, $t1
	mul	$t0, $t0, $t2			# $t0 =  (coleta - andar1) * fluxo1
	bgt	$t0, $zero, atribuielevador1	#se positivo, a coleta está no caminho do elevador
avaliaelevador2:
	lw	$t0, fluxo2
	lw	$t1, andar2
	add	$t2, $t0, $s2			#t2 = fluxo2 + fluxo
	beq	$t2, $zero, escolhe_por_distancia	#se os fluxos são inversos, E2 não pode dar carona
	sub	$t2, $s0, $t1
	mul	$t0, $t0, $t2			# $t0 =  (coleta - andar2) * fluxo2
	bgt	$t0, $zero, atribuielevador2	#se positivo, a coleta está no caminho do elevador

escolhe_por_distancia:
	# Nenhum elevador da carona: vai o que termina o trabalho mais perto da coleta.
	# Fim do trabalho = ultimo item da lista, ou o andar atual se a lista estiver vazia.
	lw	$t0, tamanholista1
	lw	$t2, andar1			# lista vazia: termina onde esta
	beqz	$t0, distancia1
	la	$t1, lista1
	addi	$t0, $t0, -1
	sll	$t0, $t0, 2
	add	$t1, $t1, $t0
	lw	$t2, 0($t1)			# lista1[tamanho - 1]
distancia1:
	sub	$t2, $t2, $s0
	abs	$t2, $t2			# distancia do fim do E1 ate a coleta

	lw	$t0, tamanholista2
	lw	$t3, andar2
	beqz	$t0, distancia2
	la	$t1, lista2
	addi	$t0, $t0, -1
	sll	$t0, $t0, 2
	add	$t1, $t1, $t0
	lw	$t3, 0($t1)			# lista2[tamanho - 1]
distancia2:
	sub	$t3, $t3, $s0
	abs	$t3, $t3			# distancia do fim do E2 ate a coleta

	blt	$t3, $t2, atribuielevador2	# E2 termina mais perto
					# empate ou E1 mais perto: segue para o E1

atribuielevador1:
	la	$s3, lista1
	la	$s4, tamanholista1
	
	lw	$t0, 0($s4)		# verifica se elevador está cheio
	addi	$t0, $t0, 2		
	li	$t1, 16
	bgt	$t0, $t1, lista_cheia
	
	# carona: so se o elevador esta andando, no mesmo sentido do pedido, e a coleta esta a frente.
	# em qualquer outro caso o pedido vai para o fim da lista.
	lw	$t2, fluxo1
	beqz	$t2, finaldalista		#elevador parado: entra no fim da lista
	bne	$t2, $s2, finaldalista		#fluxo oposto: atende ao finalizar a lista
	lw	$t1, andar1
	sub	$t3, $s0, $t1
	mul	$t3, $t3, $t2			# (coleta - andar1) * fluxo1
	blez	$t3, finaldalista		#coleta nao esta a frente: fim da lista
	blt	$t2, $zero, lista1decrescente	#carona descendo
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
	
	# carona: so se o elevador esta andando, no mesmo sentido do pedido, e a coleta esta a frente.
	# em qualquer outro caso o pedido vai para o fim da lista.
	lw	$t2, fluxo2
	beqz	$t2, finaldalista		#elevador parado: entra no fim da lista
	bne	$t2, $s2, finaldalista		#fluxo oposto: atende ao finalizar a lista
	lw	$t1, andar2
	sub	$t3, $s0, $t1
	mul	$t3, $t3, $t2			# (coleta - andar2) * fluxo2
	blez	$t3, finaldalista		#coleta nao esta a frente: fim da lista
	blt	$t2, $zero, lista2decrescente	#carona descendo
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
	# label funil para deixar codigo mais legível
cuidar_elevador1:
	# o primeiro item da lista é sempre o destino atual: ele so sai da lista quando o elevador chega nele
	# assim uma carona inserida na frente vira o novo destino durante a viagem
	lw	$t1, tamanholista1
	beqz	$t1, cuidar_elevador2		# lista vazia: elevador sem tarefa
	lw	$t0, fluxo1
	beqz	$t0, e1_parado		# fluxo == 0: chegou (ou estava livre)

	# andando: se a primeira parada esta a frente, ela vira o destino
	lw	$t2, lista1		# lista1[0]
	lw	$t3, andar1
	sub	$t4, $t2, $t3
	mul	$t4, $t4, $t0		# (lista1[0] - andar1) * fluxo1
	blez	$t4, cuidar_elevador2		# nao esta a frente: mantem o destino atual
	sw	$t2, destino1		# o elevador rele o destino a cada andar
	j	cuidar_elevador2

e1_parado:
	lw	$t5, viajando1
	beqz	$t5, e1_primeira	# estava livre: so manda para a primeira parada
	sw	$zero, viajando1	# acabou de chegar
e1_remove:			# tira da lista as paradas atendidas neste andar
	lw	$t1, tamanholista1
	beqz	$t1, cuidar_elevador2		# atendeu tudo: elevador livre
	lw	$t2, lista1		# lista1[0]
	lw	$t3, andar1
	bne	$t2, $t3, e1_envia	# proxima parada e outro andar: manda o elevador
	la	$a0, lista1
	la	$a1, tamanholista1
	jal	diminui_lista
	j	e1_remove		# pode haver mais de uma parada neste andar

e1_primeira:			# mesmo que seja o andar atual: o elevador abre a porta
	lw	$t2, lista1
	lw	$t3, andar1
e1_envia:			# $t2 = proxima parada, $t3 = andar atual
	sw	$t2, destino1		# primeiro o destino...
	li	$t0, 1
	bgt	$t2, $t3, e1_fluxo	# destino > andar atual: sobe
	li	$t0, -1			# senao desce (vale tambem para destino == andar)
e1_fluxo:
	sw	$t0, fluxo1		# ...depois o sinal de partida
	li	$t0, 1
	sw	$t0, viajando1	# lembra que mandou: o proximo fluxo == 0 e uma chegada
	j	cuidar_elevador2

cuidar_elevador2:
	# o primeiro item da lista é sempre o destino atual: ele so sai da lista quando o elevador chega nele
	# assim uma carona inserida na frente vira o novo destino durante a viagem
	lw	$t1, tamanholista2
	beqz	$t1, looppedido		# lista vazia: elevador sem tarefa
	lw	$t0, fluxo2
	beqz	$t0, e2_parado		# fluxo == 0: chegou (ou estava livre)

	# andando: se a primeira parada esta a frente, ela vira o destino
	lw	$t2, lista2		# lista2[0]
	lw	$t3, andar2
	sub	$t4, $t2, $t3
	mul	$t4, $t4, $t0		# (lista2[0] - andar2) * fluxo2
	blez	$t4, looppedido		# nao esta a frente: mantem o destino atual
	sw	$t2, destino2		# o elevador rele o destino a cada andar
	j	looppedido

e2_parado:
	lw	$t5, viajando2
	beqz	$t5, e2_primeira	# estava livre: so manda para a primeira parada
	sw	$zero, viajando2	# acabou de chegar
e2_remove:			# tira da lista as paradas atendidas neste andar
	lw	$t1, tamanholista2
	beqz	$t1, looppedido		# atendeu tudo: elevador livre
	lw	$t2, lista2		# lista2[0]
	lw	$t3, andar2
	bne	$t2, $t3, e2_envia	# proxima parada e outro andar: manda o elevador
	la	$a0, lista2
	la	$a1, tamanholista2
	jal	diminui_lista
	j	e2_remove		# pode haver mais de uma parada neste andar

e2_primeira:			# mesmo que seja o andar atual: o elevador abre a porta
	lw	$t2, lista2
	lw	$t3, andar2
e2_envia:			# $t2 = proxima parada, $t3 = andar atual
	sw	$t2, destino2		# primeiro o destino...
	li	$t0, 1
	bgt	$t2, $t3, e2_fluxo	# destino > andar atual: sobe
	li	$t0, -1			# senao desce (vale tambem para destino == andar)
e2_fluxo:
	sw	$t0, fluxo2		# ...depois o sinal de partida
	li	$t0, 1
	sw	$t0, viajando2	# lembra que mandou: o proximo fluxo == 0 e uma chegada
	j	looppedido

# ======= PROCEDIMENTOS =======
# crescente: entra antes do primeiro item >= valor, ou no ponto em que a
# ordem da lista quebra (lista[i] < lista[i-1]). Depois desse ponto estao os pedidos
# de fluxo oposto, que nao podem ser misturados com a carona.
# $a0 = endereco da lista, $a1 = endereco do tamanho, $a3 = valor
adicionalistacrescente:
	lw	$t7, 0($a1)		# tamanho
	li	$t9, 0			# i = posicao onde o valor vai entrar
alc_busca:
	bge	$t9, $t7, alc_abre	# chegou ao fim da lista
	sll	$t8, $t9, 2
	add	$t8, $a0, $t8		# $t8 = &lista[i]
	lw	$t6, 0($t8)		# lista[i]
	bge	$t6, $a3, alc_abre	# achou a posicao
	beqz	$t9, alc_proximo	# i == 0: nao tem anterior
	lw	$t5, -4($t8)		# lista[i-1]
	blt	$t6, $t5, alc_abre	# a ordem quebrou: a parte do fluxo atual acabou
alc_proximo:
	addi	$t9, $t9, 1
	j	alc_busca
alc_abre:			# desloca lista[i..fim] uma posicao para a direita
	move	$t5, $t7		# j = tamanho
alc_desloca:
	ble	$t5, $t9, alc_grava
	sll	$t8, $t5, 2
	add	$t8, $a0, $t8		# $t8 = &lista[j]
	lw	$t6, -4($t8)
	sw	$t6, 0($t8)		# lista[j] = lista[j-1]
	addi	$t5, $t5, -1
	j	alc_desloca
alc_grava:
	sll	$t8, $t9, 2
	add	$t8, $a0, $t8
	sw	$a3, 0($t8)		# lista[i] = valor
	addi	$t7, $t7, 1
	sw	$t7, 0($a1)		# atualiza tamanho da lista
	jr	$ra

# decrescente: entra antes do primeiro item <= valor, ou no ponto em que a
# ordem da lista quebra (lista[i] > lista[i-1]). Depois desse ponto estao os pedidos
# de fluxo oposto, que nao podem ser misturados com a carona.
# $a0 = endereco da lista, $a1 = endereco do tamanho, $a3 = valor
adicionalistadecrescente:
	lw	$t7, 0($a1)		# tamanho
	li	$t9, 0			# i = posicao onde o valor vai entrar
ald_busca:
	bge	$t9, $t7, ald_abre	# chegou ao fim da lista
	sll	$t8, $t9, 2
	add	$t8, $a0, $t8		# $t8 = &lista[i]
	lw	$t6, 0($t8)		# lista[i]
	ble	$t6, $a3, ald_abre	# achou a posicao
	beqz	$t9, ald_proximo	# i == 0: nao tem anterior
	lw	$t5, -4($t8)		# lista[i-1]
	bgt	$t6, $t5, ald_abre	# a ordem quebrou: a parte do fluxo atual acabou
ald_proximo:
	addi	$t9, $t9, 1
	j	ald_busca
ald_abre:			# desloca lista[i..fim] uma posicao para a direita
	move	$t5, $t7		# j = tamanho
ald_desloca:
	ble	$t5, $t9, ald_grava
	sll	$t8, $t5, 2
	add	$t8, $a0, $t8		# $t8 = &lista[j]
	lw	$t6, -4($t8)
	sw	$t6, 0($t8)		# lista[j] = lista[j-1]
	addi	$t5, $t5, -1
	j	ald_desloca
ald_grava:
	sll	$t8, $t9, 2
	add	$t8, $a0, $t8
	sw	$a3, 0($t8)		# lista[i] = valor
	addi	$t7, $t7, 1
	sw	$t7, 0($a1)		# atualiza tamanho da lista
	jr	$ra

diminui_lista:
	lw	$t0, 0($a1)	# carrega tamanho da lista
	
	addi	$t0, $t0, -1	# diminui tamanho da lista
	sw	$t0, 0($a1)	# atualiza na memoria
	li	$t2, 0		#contador = 0
loop_dl:
	bge	$t2, $t0, fim_dl
	lw	$t1, 4($a0)		# lista[i+1]
	sw	$t1, 0($a0)		# lista[i] = lista[i+1]
	addi	$a0, $a0, 4
	addi	$t2, $t2, 1
	j	loop_dl
fim_dl:
	jr	$ra