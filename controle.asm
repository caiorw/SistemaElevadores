.include	"labels.asm"
.globl		controle, destino1, destino2
.data
	codigos_andar:	.byte 0x11, 0x21, 0x41, 0x81, 0x12, 0x22, 0x42, 0x82	# teclas 0..7
	aviso_txt:	.asciiz	"Teclas invalidas, tente novamente. \n"
	pula:		.asciiz	"\n"
	destino1:	.word 0
	destino2:	.word 0
.text
controle:

primeira_tecla:
	jal 	esperar_tecla_nova
	move 	$a0, $v0
	jal 	codigo_para_andar
	bltz	$v0, primeira_tecla		#repete enquanto nao for numero de 0 a 7
	move	$s0, $v0		#andar de coleta do usuário vai p $s0

segunda_tecla:
	jal	esperar_tecla_nova
	li	$t0, 0x84
	li 	$t1, 0x18
	beq	$v0, $t0, baixo
	beq	$v0, $t1, cima
	j 	segunda_tecla		# repete se nao é C nem B
	
baixo:
	jal 	esperar_tecla_nova
	move 	$a0, $v0
	jal 	codigo_para_andar
	bltz	$v0, baixo		#repete enquanto nao for numero de 0 a 7
	sub	$t0, $s0, $v0	# se (primeira tecla - segunda) for negativo ou igual a zero, não é válido (segunda tecla é maior doq primeira)
	li	$s1, -1			# $s1 = fluxo
	bgtz	$t0, viagem
	jal 	aviso
	j 	primeira_tecla
	
cima:
	jal 	esperar_tecla_nova
	move 	$a0, $v0
	jal 	codigo_para_andar
	bltz	$v0, cima		#repete enquanto nao for numero de 0 a 7
	sub	$t0, $s0, $v0	# se (primeira tecla - segunda) for positiva, não é válido (segunda tecla é maior doq primeira
	li	$s1, 1			# $s1 = fluxo
	bltz	$t0, viagem
	jal 	aviso
	j 	primeira_tecla
	
viagem:
	move	$s2, $v0		# $s2 = destino
	# @todo: delegar elevadores
	
	 
	
	j controle
	
esperar_tecla_nova:
	addi	$sp, $sp, -4		# abre espaço para 1 palavra (4 bytes)
	sw	$ra, 0($sp)		# guarda o endereço de retorno
soltou_tecla:
	jal 	varrer_teclado
	bnez	$v0, soltou_tecla	#espera soltar a tecla anterior (retorna 0 quando nada esta pressionado)
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
