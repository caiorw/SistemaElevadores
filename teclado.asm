.include	"labels.asm"
.globl		teclado, coleta, fluxo, entrega, pronto
.data
	codigos_andar:	.byte 0x11, 0x21, 0x41, 0x81, 0x12, 0x22, 0x42, 0x82	# teclas 0..7
	aviso_txt:	.asciiz	"Teclas invalidas, tente novamente.\n"
	pede_origem:	.asciiz	"\nEscolha o andar onde voce esta (0 a 7).\n"
	origem_ok:	.asciiz	"Andar "
	pede_direcao:	.asciiz	" ok. Escolha c (ir para cima) ou b (ir para baixo).\n"
	nao_direcao:	.asciiz	"Essa tecla nao e c nem b. Escolha c (ir para cima) ou b (ir para baixo).\n"
	subindo_txt:	.asciiz	"Subindo. Escolha o andar de destino.\n"
	descendo_txt:	.asciiz	"Descendo. Escolha o andar de destino.\n"
	nao_andar:	.asciiz	"Essa tecla nao e um andar. Escolha o destino (0 a 7).\n"
	origem_txt:	.asciiz	"Chamada -> origem: "
	fluxo_txt:	.asciiz	", fluxo: "
	destino_txt:	.asciiz	", destino: "
	pula:		.asciiz	"\n"
	coleta:		.word 0
	fluxo:		.word 0
	entrega:	.word 0
	pronto:		.word 0
.text
teclado:
	lw	$t0, pronto
	bne	$t0, $zero, teclado	#enquanto o controle não informar que o pedido foi processado

	la	$a0, pede_origem
	jal	imprime

primeira_tecla:
	jal 	esperar_tecla_nova
	move 	$a0, $v0
	jal 	codigo_para_andar
	bltz	$v0, primeira_tecla		#repete enquanto nao for numero de 0 a 7
	move	$s0, $v0		#andar de coleta do usuário vai p $s0

	la	$a0, origem_ok		# "Andar X ok. Escolha c (subir) ou b (descer)."
	jal	imprime
	li	$v0, 1
	move	$a0, $s0
	syscall
	la	$a0, pede_direcao
	jal	imprime

segunda_tecla:
	jal	esperar_tecla_nova
	li	$t0, 0x84
	li 	$t1, 0x18
	beq	$v0, $t0, escolheu_baixo
	beq	$v0, $t1, escolheu_cima
	la	$a0, nao_direcao	# nao eh c nem b: avisa e espera de novo
	jal	imprime
	j 	segunda_tecla

escolheu_baixo:
	la	$a0, descendo_txt
	jal	imprime
baixo:
	jal 	esperar_tecla_nova
	move 	$a0, $v0
	jal 	codigo_para_andar
	bltz	$v0, baixo_nao_andar	#nao eh numero de 0 a 7
	move	$s2, $v0		# $s2 = destino (guardado antes de imprimir, que estraga o $v0)
	sub	$t0, $s0, $s2	# se (primeira tecla - segunda) for negativo ou igual a zero, não é válido (segunda tecla é maior doq primeira)
	li	$s1, -1			# $s1 = fluxo
	bgtz	$t0, viagem
	jal 	aviso
	j 	teclado
baixo_nao_andar:
	la	$a0, nao_andar
	jal	imprime
	j	baixo

escolheu_cima:
	la	$a0, subindo_txt
	jal	imprime
cima:
	jal 	esperar_tecla_nova
	move 	$a0, $v0
	jal 	codigo_para_andar
	bltz	$v0, cima_nao_andar	#nao eh numero de 0 a 7
	move	$s2, $v0		# $s2 = destino (guardado antes de imprimir, que estraga o $v0)
	sub	$t0, $s0, $s2	# se (primeira tecla - segunda) for positiva ou igual a zero, não é válido (segunda tecla é menor doq primeira)
	li	$s1, 1			# $s1 = fluxo
	bltz	$t0, viagem
	jal 	aviso
	j 	teclado
cima_nao_andar:
	la	$a0, nao_andar
	jal	imprime
	j	cima

viagem:
	la	$a0, origem_txt		# "Chamada -> origem: 3, fluxo: 1, destino: 6"
	jal	imprime
	li	$v0, 1
	move	$a0, $s0
	syscall

	la	$a0, fluxo_txt
	jal	imprime
	li	$v0, 1
	move	$a0, $s1
	syscall

	la	$a0, destino_txt
	jal	imprime
	li	$v0, 1
	move	$a0, $s2
	syscall

	la	$a0, pula
	jal	imprime
	
	sw	$s0, coleta
	sw	$s1, fluxo
	sw	$s2, entrega

	li	$t0, 1
	sw	$t0, pronto

	j teclado

esperar_tecla_nova:
	addi	$sp, $sp, -4		# abre espaço para 1 palavra (4 bytes)
	sw	$ra, 0($sp)		# guarda o endereço de retorno
	# Espera soltar a tecla anterior SO LENDO 0xFFFF0014, sem escrever a linha.
	# Ao soltar, o proprio Digital Lab Sim grava 0 ali. Se o programa estiver
	# escrevendo em 0xFFFF0012 bem na hora desse clique, o MARS trava (bug dele).
	li	$t0, 0xFFFF0014
soltou_tecla:
	lbu	$v0, 0($t0)
	bnez	$v0, soltou_tecla	#enquanto nao for 0, a tecla continua apertada
nova_tecla:
	jal	varrer_teclado
	beqz	$v0, nova_tecla		# espera vir nova tecla p retornar p função

	lw	$ra, 0($sp)		# recupera o endereço de retorno
	addi	$sp, $sp, 4		# devolve o espaço
	jr	$ra

# $v0 = código da tecla apertada, ou 0 se nenhuma
varrer_teclado:
	li	$t0, 0xFFFF0012		# onde escreve a linha
	li	$t1, 0xFFFF0014		# onde lê o código
	li	$t2, 1			# começa na linha 1
varre_linha:
	sb	$t2, 0($t0)
	lbu	$v0, 0($t1)
	bnez	$v0, fim_varredura	# achou uma tecla nesta linha
	sll	$t2, $t2, 1		# próxima linha: 1, 2, 4, 8
	li	$t3, 16
	blt	$t2, $t3, varre_linha
	li	$v0, 0			# nenhuma tecla
fim_varredura:
	jr	$ra


# $a0 = código lido do teclado
# $v0 = andar (0..7), ou -1 se não for tecla de andar
codigo_para_andar:
	la	$t0, codigos_andar	# endereço do início da tabela
	li	$t1, 0			# i = 0
	li	$t2, 8			# tamanho da tabela
cpa_laco:
	beq	$t1, $t2, cpa_nao_achou	# i == 8: percorreu tudo
	add	$t3, $t0, $t1		# endereço de codigos_andar[i]
	lbu	$t4, 0($t3)		# $t4 = codigos_andar[i]
	beq	$t4, $a0, cpa_achou	# é esse!
	addi	$t1, $t1, 1		# i++
	j	cpa_laco
cpa_achou:
	move	$v0, $t1		# o andar é a posição na tabela
	jr	$ra
cpa_nao_achou:
	li	$v0, -1
	jr	$ra

aviso:
	li	$v0, 4
	la	$a0, aviso_txt
	syscall

	jr 	$ra

# imprime a string cujo endereço está em $a0
imprime:
	li	$v0, 4
	syscall
	jr	$ra
