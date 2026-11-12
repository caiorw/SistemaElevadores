.include	"labels.asm"
.globl		elevador2, andar2, fluxo2
.data
	digitos:	.byte 63,6,91,79,102,109,125,7,127,111	#guarda valores que acendem o display de 7 segmentos em ordem (0 a 9)
	chegada:	.asciiz	"Elevador 1 parou no andar: "
	pula:		.asciiz	"\n"
	andar2:		.word 0
	fluxo2:		.word 0	#-1 = para baixo, 0 = parado, 1 = para cima
.text
elevador2:
	lw	$t0, fluxo1
	beq	$t0, $zero, elevador1	#espera o controlador mudar o fluxo (enquanto 0 está parado)
	
	move	$s0, $a0	#destino do elevador
	
	bgt	$t0, $zero, subir_e1
	blt	$t0, $zero, descer_e1
	
	j elevador2

#recebe quantos andares precisa subir
subir_e2:
	lw	$t1, andar2
	jal	tempo_espera	#fica dentro de um for do número de andares
	addi	$t1, $t1, 1
	bne	$t1, $s0, subir_e2
	li	$v0, 4
	la	$a0, chegada
	syscall
	li	$v0, 1
	move	$a0, t1
	syscall
	li	$v0, 4
	la	$a0, pula
	syscall
	j	elevador2

#recebe quantos andares precisa descer
descer_e2:
	lw	$t1, andar2
	jal	tempo_espera	#fica dentro de um for do número de andares
	addi	$t1, $t1, -1
	bne	$t1, $s0, descer_e2
	li	$v0, 4
	la	$a0, chegada
	syscall
	li	$v0, 1
	move	$a0, t1
	syscall
	li	$v0, 4
	la	$a0, pula
	syscall
	j	elevador2

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
	
	sub	$t9, $t9, $t8	#calcula a diferença do tempo obtido inicialmente com o tempo da consulta atual
	blt	$t9, $t7, loop_espera
	
	jr	$ra
