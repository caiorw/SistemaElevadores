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
	# - coleta está mais perto de andar1 ou andar2?
	# - se andar1: andar1 = coleta e fluxo1 = fluxo. quando fluxo1 == 0, andar1 = entrega
	# - se andar2: andar2 = coleta e fluxo2 = fluxo. quando fluxo2 == 0, andar2 = entrega
	# precisamos de lista???
	
	# duas listas: uma para cada elevador
	# andares ordenados em ordem de atendimento: qual elevador alocar basta ver o último item da lista
	# importante: coleta e entrega sempre vão ser alocados pro mesmo elevador
	# PRIORIDADE: DISTANCIA DOS ELEVADORES
	# segue o fluxo? 
	#	sim: reordena lista em ordem crescente/descrescente (subindo ou descendo)
	#	não: adiciona final da lista
	lw	$s0, coleta
	lw	$s1, andar1
	lw	$s2, andar2
	
	sub	$t0, 
	
	
	j controle
