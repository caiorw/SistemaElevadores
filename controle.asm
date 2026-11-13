.include	"labels.asm"
.globl		controle, destino1, destino2
.data
	codigos_andar:	.byte 0x11, 0x21, 0x41, 0x81, 0x12, 0x22, 0x42, 0x82	# teclas 0..7
	destino1:	.word 0
	destino2: 	.word 0
	# variáveis globais a disposição: 
	# 	coleta (definido em teclado)
	# 	fluxo (definido em teclado)
	# 	entrega (definido em teclado)
	# 	fluxo1 (definido em elevador1)
	# 	fluxo2 (definido em elevador2)
.text
controle:
	# @todo:
	# - coleta está mais perto de andar1 ou andar2?
	# - se andar1: andar1 = coleta e fluxo1 = fluxo. quando fluxo1 == 0, andar1 = entrega
	# - se andar2: andar2 = coleta e fluxo2 = fluxo. quando fluxo2 == 0, andar2 = entrega
	# precisamos de lista???
	
	
	j controle
