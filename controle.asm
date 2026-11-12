.include	"labels.asm"
.globl		controle, destino1
.data
	digitos:	.byte 63,6,91,79,102,109,125,7,127,111	#guarda valores que acendem o display de 7 segmentos em ordem (0 a 9)
	pula:		.asciiz	"\n"
	destino1:	.word 0
.text
controle:
	#precisa avaliar alguns endereços de memória que dizem o estado do outro elevador (critérios de economia de energia do pdf)
	
	j controle
