.include	"labels.asm"
.globl		elevador_1
.data
	digitos:	.byte 63,6,91,79,102,109,125,7,127,111	#guarda valores que acendem o display de 7 segmentos em ordem (0 a 9)
	pula:		.asciiz	"\n"
	andar1:		.word 0
.text
elevador_1:
	#precisa avaliar alguns endereços de memória que dizem o estado do outro elevador (critérios de economia de energia do pdf)
	
	j elevador_1

#recebe quantos andares precisa subir
subir:
	jal	tempo_espera	#fica dentro de um for do número de andares
	jr	$ra

#recebe quantos andares precisa descer
descer:
	jal	tempo_espera	#fica dentro de um for do número de andares
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
	
	sub	$t9, $t9, $t8	#calcula a diferença do tempo obtido inicialmente com o tempo da consulta atual
	blt	$t9, $t7, loop_espera
	
	jr	$ra