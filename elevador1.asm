.include	"labels.asm"
.globl		elevador1, andar1, fluxo1
.data
	digitos:	.byte 63,6,91,79,102,109,125,7,127,111	#guarda valores que acendem o display de 7 segmentos em ordem (0 a 9)
	chegada:	.asciiz	"Elevador 1 parou no andar: "
	pula:		.asciiz	"\n"
	andar1:		.word 0
	fluxo1:		.word 0	#-1 = para baixo, 0 = parado, 1 = para cima
	# destino1: definido em controlador.asm (só leitura aqui).
.text
elevador1:
	li	$s1, 0xFFFF0011		#s1 = endereço do display da esquerda
	jal	mostrar_andar		#mostra o andar inicial (uma vez só)

espera_fluxo:
	lw	$t0, fluxo1
	beq	$t0, $zero, espera_fluxo	#espera o controlador mudar o fluxo (enquanto 0 está parado)
	bgt	$t0, $zero, subir_e1		# fluxo > 0
	j	descer_e1			#fluxo < 0

#sobe um andar por vez até chegar ou passar do destino
subir_e1:
	lw	$s0, destino1		#relê o destino a cada andar (o controlador pode mudar)
	lw	$t1, andar1		#carrega andar atual
	bge	$t1, $s0, chegou	#andar >= destino: cheguei ou passei, para aqui

	jal	tempo_espera		#4 segundos entre um andar e outro
	lw	$t1, andar1
	addi	$t1, $t1, 1
	sw	$t1, andar1		#mantem andar1 atualizado
	jal	mostrar_andar
	j	subir_e1		#volta e pergunta de novo

#desce um andar por vez até chegar ou passar do destino
descer_e1:
	lw	$s0, destino1		#relê o destino a cada andar (o controlador pode mudar)
	lw	$t1, andar1		#carrega andar atual
	ble	$t1, $s0, chegou	#andar <= destino: cheguei ou passei, para aqui

	jal	tempo_espera		#4 segundos entre um andar e outro
	lw	$t1, andar1
	addi	$t1, $t1, -1
	sw	$t1, andar1		#mantem andar1 atualizado
	jal	mostrar_andar
	j	descer_e1		#volta e pergunta de novo

#chegada (igual para subida e descida)
chegou:
	li	$v0, 4
	la	$a0, chegada
	syscall
	li	$v0, 1
	lw	$a0, andar1
	syscall
	li	$v0, 4
	la	$a0, pula
	syscall

	jal	tempo_espera		#+ 4 segundos para abrir e fechar a porta

	sw	$zero, fluxo1		#avisa o controlador que o elevador parou e está livre
	j	espera_fluxo

#mostra andar1 no display do elevador ($s1)
mostrar_andar:
	lw	$t2, andar1
	la	$t3, digitos
	add	$t3, $t3, $t2		#adiciona o endereço ao número a ser mostrado (decodificação)
	lbu	$t3, 0($t3)		#carrega o byte correspondente ao número através do endereço calculado
	sb	$t3, 0($s1)		#mostra o número no display
	jr	$ra

#equivalente a wait(4 segundos)
tempo_espera:
	li	$v0, 30
	syscall
	move	$t8, $a0	#low order (t8 = tempo que o procedimento iniciou)
	li	$t7, 4000	#usado para a comparação (4 segundos entre 1 andar e outro)
loop_espera:
	li	$v0, 30
	syscall
	move	$t9, $a0	#low order (t9 = tempo consultado nessa repetição)

	subu	$t9, $t9, $t8	#calcula a diferença do tempo obtido inicialmente com o tempo da consulta atual
	blt	$t9, $t7, loop_espera

	jr	$ra
