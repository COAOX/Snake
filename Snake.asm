#################################################
#  1er Proyecto de Organización del Computador  #
#                Snake Version  2.0             #
#          Germano Rojas & José Quevedo         #
#               Teclas para usar:               #  
#                  w (Arriba/up)                #
#                  s (Abajo/down)               #
#                 a (Derecha/right)             #
#                d (Izquierda/left)             #
#                 p (Pausar/pause)              #
#                r (Reiniciar/restar)           #
#################################################

#########################################################
#                Uso de los Registros                   #
# 1.  $t0 Indice para recorrer el tablero / Auxiliar    #
# 2.  $t1 Guarda los colores para rellenar el tablero   #
# 3.  $t2 Contador de cuadritos para el snake           #
# 4.  $t3 Indice para el movimiento                     #
# 5.  $t4 Indice para borrar                            #
# 6.  $t5 Contiene la Direrección del movimiento        #
# 7.  $t6 Para manejar la velocidad                     #
# 8.  $t7 Auxiliar para las colisiones                  #
# 9.  $t8 Auxiliar                                      #
# 10. $t9 Para el Manejo del tiempo                     #
# 11. $s0 Acumulador del puntaje                        #
# 12. $s1 Lleva el conteo de las vidas                  #    
# 13. $s3 Lleva el tamaño del snake                     #
#                                                       #
#                      Indices                          #
#                                                       #
# $t0   para recorrer el tablero                        #
# $t3   para el movimiento                              #
# $t4   para borrar el movimiento                       #
# "4"   para el movimiento horizontal                   #
# "256" para el movimiento vertical                     #
#########################################################

principio:
.data
	#  Espacio de Memoria del tablero
	tablero: .space 1048576
	
	#  Colores del Juego
	Cborde:   .word 0x00006400 # Bordes del Tablero
	Cfondo:   .word 0x0000FF00 # Fondo del Tablero
	Cvidas:   .word 0x00FF4500 # Rojo 
	Csnake:   .word 0x00808000 # Oliva
	Cpatilla: .word 0x00FF0000 # Rojo 2 
	Ccambur:  .word 0x00FFFF00 # Amarillo
	Cnaranja: .word 0x00FFA500 # Naraja
	Cmora: 	  .word 0x004400FF # Azul
	Cpopo: 	  .word 0x00794900 # Marrón
	Cpiedras: .word 0x00808080 # Gris
	
	TiempoI:   .word 0
	velocidad: .word 0
	auxiliar:  .word 0
	movimiento: .word 0
	
	# Mensaje de puntaje
	Puntaje: .asciiz "El puntaje es: "
	salto: .asciiz "\n"
	
	#  Mensaje de Reinicio
	reinicio: .asciiz "Desea reiniciar el juego?"
	mensajePausa: .asciiz "El juego esta pausado\nDele clic en <ok> para continuar "
	Inicio: .asciiz "BIENVENIDO AL JUEGO CULEBRITA ISIS!\nElaborado por: Jose Quevedo y Germano Rojas\n Dele clic en <ok> para continuar"
	
	
.text
macros:

# Instrucción para "pintar" los bordes del tablero #
.macro bordes
	li $t0, 0				# Registro auxiliar para indice de inicio del tablero
	
	# Pintar todo el tablero como si fuese el fondo "
	fondo:
		lw   $t1, Cfondo		# Obtiene el color del fondo
		sw   $t1, tablero($t0)		# Guarda en el tablero dicho color
		addi $t0, $t0, 4		# Se posiciona en la siguiente posición a "pintar" 
		blt  $t0, 16384, fondo		# Condición para que solamente utilice el espacio necesario para el tablero
	
	li $t0, 0				# Registro auxiliar para indice de inicio del tablero
	
	# "Pinta" el borde del tablero #
	horizontal:
		lw   $t1, Cborde		# Obtiene el color del borde
		sw   $t1, tablero($t0) 		# Guarda en el tablero dicho color
		addi $t0, $t0, 4		# Se posiciona en la siguiente posición a "pintar" 
		blt  $t0, 1024, horizontal	# Condición que permite pintar solamente la parte superior del tablero
		beq  $t0, 16384, finalbordes	# Último recuadro del borde a pintar
		bge  $t0, 16128, horizontal	# Condición para pintar el borde inferior del tablero
	
	vertical:
		# Borde lateral izquierdo #
		lw   $t1, Cborde		# Obtiene el color del borde
		sw   $t1, tablero($t0)		# Guarda en el tablero dicho color
		add  $t0, $t0, 252		# Se posiciona en la siguiente posición a "pintar" 
		# Borde lateral derecho #
		lw   $t1, Cborde		# Obtiene el color del borde
		sw   $t1, tablero($t0)		# Guarda en el tablero dicho color
		add  $t0, $t0, 4		# Se posiciona en la siguiente posición a "pintar" 
		blt  $t0, 16128, vertical	# En caso de no llegar al primer recuadro del borde inferior, continúa con los laterales
		b horizontal			# En caso de llegar al primer recuadro del borde inferior, salta a "horizontal"
	finalbordes:
	.end_macro
	
	

	#  Suma al puntaje general de acuerdo a los siguiente criterios:  
	#      1. Se suman puntos cada vez que el snake va creciendo
	#      2. 3  pts por cada naranja comida
	#      3. 4  pts por cada cambur comida
	#      4. 5 pts por cada patilla comida
	#      5. 10 pts por cada mora comida
	.macro SumarPuntaje ($arg)
		add $s0, $s0, $arg 		# Al registro de puntaje le suma los puntos especificados por $arg
	.end_macro
	
	#  Esta macro arma el snake dado el tamaño deseado, puede mandar el tamaño como un ope inmediato o como un registro  #
	.macro Armar(%arg)
	li   $t3, 8064				# Punto de comienzo del snake
	armar: 
		li $t8, 1			# Referencia 1 (hacia la derecha) --- ver Macro Mover
		sb $t8, movimiento		# Se guarda el byte en "Movimiento"
		
		lw $t8, movimiento		# Se obtiene el byte 
		sll $t8, $t8, 24		# Se corren 24 bits para poder guardar el color del Snake junto con la referencia a movimiento
		lw   $t1, Csnake		# Se obtiene el color del Snake
		add   $t1, $t1, $t8		# Se le añade al byte corrido para guardarlo en el tablero
		sw   $t1, tablero($t3)		# Se guarda en el tablero
		
		addi $t3, $t3, 4 		# $t3 funciona como indice para construir el snake, se aumente en 4 para ir con el oro cuadro
		addi $t2, $t2, 1		# $t2 funciona como contador para saber cuantos cuadros falta por llenar
		blt  $t2, %arg, armar		# Condición para seguir "pintando" cuadros en el tablero
		subi $t3, $t3, 4		# Posiciona el indice de la cabeza del snake en la posición del último cuadro "pintado" (la cabeza)
		li   $t8, 64			# Proporciona un numero en ascii neutral para empezar a hacer el movimiento hacia la derecha desde el inicio
		sw   $t8, 0xFFFF0004		# Guarda dicho número
	.end_macro
	
	#  Esta Macro pinta la cantidad de Vidas en el Tablero  #
	.macro Vidas
	lw $t1, Cvidas
		# "Pinta" de rojo los recuadros que indican la primera vida #
		Vida1:
			sw $t1, tablero+268
			sw $t1, tablero+272
			sw $t1, tablero+524
			sw $t1, tablero+528
			
		# "Pinta" de rojo los recuadros que indican la primera vida #
		Vida2:
			sw $t1, tablero+280
			sw $t1, tablero+284
			sw $t1, tablero+536
			sw $t1, tablero+540
			
		# "Pinta" de rojo los recuadros que indican la primera vida #
		Vida3:
			sw $t1, tablero+292
			sw $t1, tablero+296
			sw $t1, tablero+548
			sw $t1, tablero+552
	.end_macro
	
	#  Divide el tiempo de espera entre 5 y eso permite aumentar la veloidad del movimiento   #
	.macro aumentarVelocidad
		# Si la velocidad es divible entre 5, la reduce, sino llegó al máximo
		bgtz $t6, aumentar 		# Comprueba que la velocidad actual sea mayor a 0
		b terminarMacro
		aumentar:
			li $t8, 0
			# Comprueba que la velocidad sea divisible entre 5 #
			rem $t8, $t6, 5
			bgtz $t8, terminarMacro
			
			div $t8, $t6, 5		# Realiza la división
			sub $t6, $t6, $t8	# Sustrae el resultado de la división a la velocidad actual
		terminarMacro:		
	.end_macro
	
	#  Genera las Frutas y las coloca aleatoriamente en el Tablero  #
	#  Falta verificar que no haya nada en la posición generada :|
	.macro frutasRandom
	li $t8, 0				# Registro auxiliar a usarse luego
	loopCantidadFRandom:
		
		#  Genera la cantidad de las frutas de forma aleatoria
		li   $a0, 1
		li   $a1, 10
		li   $v0, 42
		syscall
		move $t9, $a0
		blt $t9, 2, loopCantidadFRandom 	# Condición para obtener más de dos frutas como mínimo
		
		li $s5, 0				# Registro utilizado para contar cuántas frutas se han colocado en el tablero
		
	loopCantidadF:
	# Instrucciones para obtener la posición donde se colocarán las frutas #
	loopRandom:
		# Se obtiene la posición aleatoria #
		li   $a0, 1 
		li   $a1, 4031
		li   $v0, 42
		syscall
		move $t7, $a0
		mul  $t7, $t7, 4		# El número de la posición debe ser múltiplo de 4
		blt  $t7, 1024, loopRandom 	# La posición debe estar debajo del borde superior, es decir en el tablero
		
		# Evalua si en la posición establecida hay algún otro objeto #
		lw $t1, Cfondo
		lw $t8, tablero($t7)
		bne $t8, $t1, loopRandom
		
	# Determinación aleatoria de cuál furta colocar #	
	fruticasRandom:
	especiales:
		rem  $t8, $s3, 3	# Como es una fruta especial, la condicion especial es que si el tamaño del Snake es múltiplo de 3, se pueden colocar moras
		beqz $t8, mora		# En caso que si sea múltiplo de 3, se coloca la mora	
		
		rem  $t8, $s3, 5	# Como es un objeto especial, la condicion especial es que si el tamaño del Snake es múltiplo de 5, se pueden colocar popos
		beqz $t8, popo		# En caso que si sea múltiplo de 5, se coloca el popo que restará 5 pts. al puntaje
		
	normales:
		# Las frutas normales se manejan con un número aleatorio del 0 al 3"
		li   $a0, 1
		li   $a1, 4
		li   $v0, 42
		syscall
		move $t8, $a0
		beqz $t8, finMacroFrutasR	# En caso de arrojar 0, no se coloca fruta
		beq  $t8, 1, patilla		# En caso de arrojar 1, se coloca un patilla
		beq  $t8, 2, cambur		# En caso de arrojar 2, se coloca un cambur
		beq  $t8, 3, naraja		# En caso de arrojar 3, se coloca una naranja
		
		# Instrucciones para colocar las frutas en el tablero #
		patilla:
			lw $t1, Cpatilla
			sw $t1, tablero($t7)
			b finMacroFrutasR
		cambur:
			lw $t1, Ccambur($zero)
			sw $t1, tablero($t7)
			b finMacroFrutasR
		naraja:
			lw $t1, Cnaranja
			sw $t1, tablero($t7)
			b finMacroFrutasR
		mora:
			lw $t1, Cmora
			sw $t1, tablero($t7)
			b normales
		popo:
			lw $t1, Cpopo
			sw $t1, tablero($t7)
			b normales
		finMacroFrutasR:
		addi $s5, $s5, 1		# Contador para saber cuántas frutas se han colocado
		blt $s5, $t9, loopCantidadF	# Condición para colocar todas las frutas
	.end_macro
	
	#  Genera Obstaculos y los coloca aleatoriamente en el Tablero  #
	.macro obstaculosRandom
		loopcantidadRandom:
		li   $t8, 0
		li   $t0, 0
		
		#  Genera la cantidad de los obtaculos de forma aleatoria
		li   $a0, 1
		move $a1, $s3
		li   $v0, 42
		syscall
		move $t9, $a0
		beqz $t9, loopcantidadRandom
		bgt  $t9, 10, loopcantidadRandom
		
		li $s5, 0 			# Registro auxiliar para saber cuantos obstáculos se han colocado
		
		loopCantidadO:
		
		looptamanioRandom:
		li   $t8, 0
		li   $t0, 0
		
		#  Genera el tamaño de los obstaculos de forma aleatoria
		li   $a0, 1
		li   $a1, 8				# El tamaño está limitado por 8 cuadros
		li   $v0, 42
		syscall
		move $t0, $a0
		beqz $t0, looptamanioRandom		# El tamaño no puede ser igual a 0
		
		#  Genera la posicion aleatoria
		loopRandomO:
		li   $a0, 1
		li   $a1, 4031
		li   $v0, 42
		syscall
		move $t7, $a0
		mul  $t7, $t7, 4			# La posición debe ser múltiplo de 4
		blt  $t7, 1024, loopcantidadRandom	# En caso de arrojar una posición en el borde superior, buscar otra posición
		sw   $t7, auxiliar			# Guarda la posición en memoria para usarla después
		
		li $t2, 0				# Contador de piezas colocadas
		
		# Comprueba si hay algún objeto que interfiera en el espacio del obstáculo #
		comprobar:
		lw   $t1, Cfondo			# Obtiene el color del fondo
		lw   $t8, tablero($t7)			# Obtiene el color del tablero en la posición a poner el obstáculo
		bne  $t8, $t1, loopcantidadRandom	# Compara para saber si hay algun objeto en el lugar
		
		addi $t2, $t2, 1			# Contador para saber cuántas piezas del obstáculo se han evaluado
		addi $t7, $t7, 4			# Mueve el indice de posicionamiento para evaluar la siguiente pieza
		ble  $t2, $t0, comprobar		# Conidición para saber si faltan piezas por evaluar
		
		li $t8, 0				# Contador para saber cuantás piezas faltan por colocar
		lw $t7, auxiliar			# Obtiene la posición inicial del obstáculo
		
		# Una vez que se comprueba que el espacio total para poner el obstáculo está libre, se coloca el obstáculo #
		
		loopTamanioO:
		lw   $t1, Cpiedras			# Obtiene el color del obstáculo	
		sw   $t1, tablero($t7)			# Guarda el color en el tablero
		addi $t7, $t7, 4			# Aumenta el indice de posicionamiento
		addi $t8, $t8, 1			# Aumenta el contador
		blt  $t8, $t0, loopTamanioO 		# Loop para saber si ya las piezas se colocaron en su totalidad
		
		# Averigua si faltan obstáculos por colocar #
		addi $s5, $s5, 1			# Aumenta el contador de obstáculo por colocar en total
		ble $s5, $t9, loopCantidadO		# Loop para saber si ya los obstáculos se colocaron en su totalidad
		
	.end_macro	
	
	# Macro para realizar movimientos # 
	.macro mover($arg)
		inicioM:
		
		colision($arg)		# Intrucciones de colisiones
		li $t8, 0		# Registro auxiliar, se usará luego
		
		beq $arg, 4, der	# En caso de quereserse mover a la derecha ($arg = 4), saltar a der
		beq $arg, -4, izq	# En caso de quereserse mover a la derecha ($arg = -4), saltar a izq
		beq $arg, 256, aba	# En caso de quereserse mover a la derecha ($arg = 256), saltar a aba
		beq $arg, -256, arr	# En caso de quereserse mover a la derecha ($arg = -256), saltar a arr
		
		# Movimiento hacia la derecha #
		der:
		li $t8, 1		# Se carga un numeor de referencia (1) para guardarlo junto con el color del Snake en el tablero
		sb $t8, movimiento	# Se carga el byte al espacio en memoria "movimiento"
		b moveS			# Salta
		
		# Movimiento hacia la izquierda #
		izq:
		li $t8, 2		# Se carga un numeor de referencia (2) para guardarlo junto con el color del Snake en el tablero
		sb $t8, movimiento	# Se carga el byte al espacio en memoria "movimiento"
		b moveS			# Salta
		
		# Movimiento hacia la abajo #
		aba:
		li $t8, 3		# Se carga un numeor de referencia (3) para guardarlo junto con el color del Snake en el tablero
		sb $t8, movimiento	# Se carga el byte al espacio en memoria "movimiento"
		b moveS			# Salta
		
		# Movimiento hacia la arriba #
		arr:
		li $t8, 4		# Se carga un numeor de referencia (4) para guardarlo junto con el color del Snake en el tablero
		sb $t8, movimiento	# Se carga el byte al espacio en memoria "movimiento"
		b moveS			# Salta
		
		li $t8, 0		# Registro auxiliar, se lleva a 0
		
		# Instrucciones para guardar el movimiento junto con el color del Snake #
		moveS:	
		lw $t1, movimiento	# Se obtiene la palabra de "movimiento" en este caso el numero de referencia
		sll $t1, $t1, 24	# Dicha palabra se corre 24 bits para colocar el byte de referencia más hacia la izquierda (*)
		lw $t7, Csnake
		
		# (*) Se hace esto debido a que para "pintar" el tablero, el sistema lee los ultimos 3 bytes de izquierda a derecha, los byte del color #  
		
		add $t1, $t1, $t7	# Se añade el color al numero de referencia corrido
		sw $t1, tablero($t3)	# Se guarda el movimiento y el color en el tablero
		
		add $t3, $t3, $arg	# Se le suma al indice de la cabeza del snake el numero dependiendo de cuál es el movimiento que se quiere, de tal forma lo realiza
		
		sw   $t1, tablero($t3)	# Se guarda el color del Snake en el recuadro del tablero dependiendo de $t3
		
		beqz $t0, tiempo	# En caso que no sea necesario aumentar el tamaño del Snake, se salta a "tiempo"
			# En caso de aumentar el tamaño del snake se realiza lo siguiente #
			addi $t8, $t8, 1	# $t8 funciona como contador
			ble  $t8, $t0, moveS	# Hasta que el contador no alcance el tamaño de la serpiente, esta no accederá a las instrucciones de borrado por lo que "aumentará" de tamaño
		
		# Determina su movimiento en relación al tiempo (velocidad) #
		tiempo:
			# Sleep que determina esta velocidad
		li   $v0, 32
		la   $a0, ($t6)	# $t6 establece los milisegundos que se "dormirá" el proceso
		syscall
		
		
		# Inicio de las instrucciones de borrado #
		lw   $t1, Csnake # Obtiene el color del Snake para compararlo posteriormente
		li   $t8, 0
		
		lw   $t8, tablero($t4)	# Obtiene lo que está contenido en el tablero en la posición establecida por el indice de borrado o cola ($t4)
		
		# Condición para realizar el borrado #
		derecha:
		li   $t7, 4 			# Numero a sumarse para ir a la derecha
		beq $t8, 25198592, borrar 	# Si el numero guardado en la posición del tablero dada por el índice es igual al mostrado, borrar hacia la derecha
		
		izquierda:			
		li $t7, -4			# Numero a sumarse para ir a la izquierda
		beq $t8, 41975808, borrar	# Si el numero guardado en la posición del tablero dada por el índice es igual al mostrado, borrar hacia la izquierda
		
		abajo:
		li   $t7, 256			# Numero a sumarse para ir a la abajo
		beq $t8, 58753024, borrar	# Si el numero guardado en la posición del tablero dada por el índice es igual al mostrado, borrar hacia la abajo
		
		arriba:
		li   $t7, -256			# Numero a sumarse para ir a la arriba
		beq  $t8, 75530240, borrar	# Si el numero guardado en la posición del tablero dada por el índice es igual al mostrado, borrar hacia la arriba
		
		# Instrucción de borrado, de tal forma se da ilusión de movimiento dle snake #
		borrar: 	
			lw   $t1, Cfondo	# Obtiene el color del fondo del tablero
			sw   $t1, tablero($t4)	# Guarda dicho color en la posición que se desea borrar
			add  $t4, $t4, $t7	# Cambia el índice de borrado o cola para la proxima posición a evaluar
	.end_macro 
 
	#  Verifica si el snake choco contra un borde o un obstaculo  #
	.macro colision($arg)
		#  Carga el color que esta proximo a la cabeza del snake  #
		add  $t3, $t3, $arg		# Obtiene el espacio próximo, según el movimiento, para saber si hay algo	
		lw   $t1, tablero($t3)		# Obtiene el color de ese espacio
		
		sub  $t3, $t3, $arg		# Devuelve a la posición de antes
		
		lw   $t7, Cborde          #  Carga el color del borde   
		beq  $t7, $t1, pierdeVida #  Descuenta una Vida y reinicia al snake 
		
		lw   $t7, Cpiedras	  #  Carga el color de las piedras
		beq  $t7, $t1, pierdeVida #  Descuenta una Vida y reinicia al snake
		
		lw   $t7, Csnake	  #  Carga el color del snake
		beq  $t1, $t7, pierdeVida #  Descuenta una Vida y reinicia al snake
		
		
		li   $t0, 0		  #  Se usa $t0 como registro auxiliar que permita determinar que tanto se aumenta el tamaño del snake  #
		
		lw   $t7, Cfondo          #  Carga el color del fondo 
		beq  $t1, $t7, finalMacro #  Termina la macro si no choco 
		
		# En caso de "colisionar" o comer una fruta #
		lw   $t7, Cpatilla		# Obtiene el color de la fruta 
		li   $t0, 5			# Numero de cuadros extras en el Snake
		addi $s3, $s3, 5		# Conserva el numero de cuadros que forman el snake, útil para obtener un puntaje mayor dependiendo del tamaño del snake
		beq  $t1, $t7, finalMacro	# Salta las demas condiciones, en caso que esta esté acertada
		
		lw   $t7, Ccambur		# Obtiene el color de la fruta 
		li   $t0, 4			# Numero de cuadros extras en el Snake
		addi $s3, $s3, 4		# Conserva el numero de cuadros que forman el snake, útil para obtener un puntaje mayor dependiendo del tamaño del snake
		beq  $t1, $t7, finalMacro	# Salta las demas condiciones, en caso que esta esté acertada
		
		lw   $t7, Cnaranja		# Obtiene el color de la fruta
		li   $t0, 3			# Numero de cuadros extras en el Snake
		addi $s3, $s3, 3		# Conserva el numero de cuadros que forman el snake, útil para obtener un puntaje mayor dependiendo del tamaño del snake
		beq  $t1, $t7, finalMacro 	# Salta las demas condiciones, en caso que esta esté acertada
		
		lw   $t7, Cmora			# Obtiene el color de la fruta
		li   $t0, 10			# Numero de cuadros extras en el Snake
		addi $s3, $s3, 10		# Conserva el numero de cuadros que forman el snake, útil para obtener un puntaje mayor dependiendo del tamaño del snake
		beq  $t1, $t7, finalMacro 	# Salta las demas condiciones, en caso que esta esté acertada
		
		lw   $t7, Cpopo			# Obtiene el color del objeto
		li   $t0, 1			# Numero de cuadros extras en el Snake
		subi $s0, $s0, 5		# Resta 5 puntos
		addi $s3, $s3, 1		# Conserva el numero de cuadros que forman el snake, útil para obtener un puntaje mayor dependiendo del tamaño del snake
		beq  $t1, $t7, finalMacro 	# Salta las demas condiciones, en caso que esta esté acertada
		
		# Intrucciones en caso que haya una colisión #
		pierdeVida:
			
			subi $s1, $s1, 1			# Resta una vida
			una: 
				bordes				# Vuelve a poner el trablero como el inicio
				Vidas				# Pinta las vidas
				li   $t7, 0
				# Resta el primer recuadro de las vidas #
				sw   $t7, tablero+268		
				sw   $t7, tablero+272
				sw   $t7, tablero+524
				sw   $t7, tablero+528
				ble  $s1, 1, dos		# En caso que sea la segunda vida perdida, salta a "dos"
				b loopVidas			# Continúa
			dos: 
				li   $t7, 0
				# Resta el segundo recuadro de las vidas #
				sw   $t7, tablero+280
				sw   $t7, tablero+284
				sw   $t7, tablero+536
				sw   $t7, tablero+540
				beq  $s1, 0, tres		# En caso que sea la tercera vida perdida, salta a "tres"
				b loopVidas			# Continúa
			tres: 
				li   $t7, 0
				# Resta el segundo recuadro de las vidas #
				sw   $t7, tablero+292
				sw   $t7, tablero+296
				sw   $t7, tablero+548
				sw   $t7, tablero+552
				b reiniciar			# En este caso ya no quedan más vidas asi que salta a la pregunta de reiniciar o no
		finalMacro:
		SumarPuntaje ($t0)				# En caso de obtener puntaje, lo suma
		
	.end_macro
	
	# Macro para reestablecer las condiciones del tablero sin obstáculos o frutas #
	.macro reestablecer
		
		li $t8, 1024
		lw $t1, Cfondo			# Color de fondo # 
		
		inicioRes:
		lw $t0, tablero($t8) 		# Obtiene el contenido del recuadro en el tablero #
		
		beq $t0, $t1, saltar
		
		# Cuadros que no deben ser "borrados" del tablero #
		li $t7, 25198592		# Numero resultante de la suma del numero decimal más el numero usado para referenciarse al respectivo movimiento (ver Macro de movimiento)
		beq $t0, $t7, saltar
		
		li $t7, 41975808		# Numero resultante de la suma del numero decimal más el numero usado para referenciarse al respectivo movimiento (ver Macro de movimiento)
		beq $t0, $t7, saltar
		
		li $t7, 58753024		# Numero resultante de la suma del numero decimal más el numero usado para referenciarse al respectivo movimiento (ver Macro de movimiento)
		beq $t0, $t7, saltar
		
		li $t7, 75530240		# Numero resultante de la suma del numero decimal más el numero usado para referenciarse al respectivo movimiento (ver Macro de movimiento)
		beq $t0, $t7, saltar	
		
		lw $t7, Cborde			# Color del borde #
		beq $t0, $t7, saltar
		
		# Pinta el fondo del tablero #
		pintar:
		sw $t1, tablero($t8)
		
		# En caso de presentarse algún objeto que se debe conservar en el tablero, se salta al siguiente recuadro #
		saltar:
		addi $t8, $t8, 4
		blt $t8, 16124, inicioRes
		
	.end_macro
	
		

#  Este es el comienzo del juego, al principio se inicializan las vidas y el puntaje  #
inicio1:
	la $a0, Inicio
	li $a1, 2
	li $v0, 55
	syscall

	bordes
	
main:
	li $s0, 0  						#  Cantidad de Puntos acumulados
	li $s1, 3  						#  Vidas del snake
	li $s3, 5  						#  Cantidad de cuadritos del snake
	Vidas

	loopVidas:
		li $t6, 1000 					#  Tiempo predeterminado para comenzar
		li $s3, 5		
		
		star:                				#  Inicio del Juego
			li $t2, 0    				#  Contador de cuadritos para el snake
			li $t3, 8064 				#  Indice para Avanzar (Primera Posicion)
			li $t4, 8064				#  Indice para Borrar
			Armar(5)   				#  Macro para armar al snake (Cantidad de cuadros)
			
		pausa1:
			lw  $t9,  0xffff0000
			beq $t9, 0, pausa1
			beq $t9, 1, loopJuego
		
		# Ciclo del juego, se lee hacia donde se quiere ir para luego realizar las instrucciones respectivas #
		loopJuego:
			#contar tiempo
			li   $t8, 0
			li   $v0, 30
			syscall
			move $t8, $a0
			sw   $t8, TiempoI
			
			mientras:				#loop para hacer un movimiento
			        
				
				lw   $t9, 0xFFFF0004
				
				move $t8, $t9
			preguntar:
				# Condiciones para moverse
				beq  $t9, 72, principio 	#  Lleva al inicio del juego
				beq  $t9, 70, final		#  Finaliza el juego
				beq  $t9, 112, pausa		#  Pausa el juego, es necesario volver a apretar esta tecla para continuar 
				beq  $t9, 119, arriba		#  Movimiento hacia arriba
				beq  $t9, 115, abajo		#  Movimiento hacia abajo
				beq  $t9, 64, inicio		#  Movimiento hacia la derecha
				beq  $t9, 100, derecha		#  Movimiento hacia la derecha 2
				beq  $t9, 97, izquierda		#  Movimiento hacia la izquierda
				
				
				## En caso que se teclee alguna tecla errónea el juego continuará sin alteraciones ##
				bne  $t9, 72, siga2 	
				bne  $t9, 70, siga2
				bne  $t9, 112, siga2
				bne  $t9, 119, siga2
				bne  $t9, 115, siga2
				bne  $t9, 64, siga2
				bne  $t9, 100, siga2
				bne  $t9, 97, siga2	
				
			# Mensaje de pausa por consola #
			pausa:
				la $a0, mensajePausa
				li $a1, 2
				li $v0, 55		# Imprime mensaje de pausa
				syscall
				
				b pausa1		# Condicion para que el pueda seguir el juego
				
				
				# Instrucciones de movimiento
				arriba:
					beq $s4, 256, siga2	# Condición para que no vaya en sentido contrario
					li $s4, -256		# Se resta 256 a la posición actual para que suba el cuadrito
					b siga2			# Continúa
				abajo:
					beq $s4, -256, siga2	# Condición para que no vaya en sentido contrario
					li $s4, 256		# Se resta 256 a la posición actual para que suba el cuadrito
					b siga2			# Continúa
				derecha:
					beq $s4, -4, siga2	# Condición para que no vaya en sentido contrario
					li $s4, 4		# Se resta 256 a la posición actual para que suba el cuadrito
					b siga2			# Continúa
				izquierda:
					beq $s4, 4, siga2	# Condición para que no vaya en sentido contrario
					li $s4, -4		# Se resta 256 a la posición actual para que suba el cuadrito
					b siga2
				inicio:
					li $s4, 4		# Se resta 256 a la posición actual para que suba el cuadrito
					b siga2			# Continúa
				
				siga2: 				# Loop para saltar cuando se sepa qué movimiento hacer
				mover($s4)			# Macro de movimiento, están las instrucciones que permiten el movimiento del Snake
				bnez $t0, aparicion		# En caso que se coma una fruta "aparición" salta al label para limpiar el tablero
				
				# 2da toma de tiempo
				li   $v0, 30
				syscall
				move $t0, $a0
				lw   $t8, TiempoI
				
				sub  $t8, $t0, $t8		# Resta para saber si han pasado 10 segundos
				blt  $t8, 10000, mientras	# Condicion de los 10 segundos
				
				SumarPuntaje ($s3) 		#suma un punto por cada 10 segundos transcurridos dependiendo de la dificultad
				
				aparicion:			# Pasados 10 segundos o comida una fruta, pone en blanco el tablero para volver a poner las otras frutas/obstaculos
				reestablecer			# Pone en blanco el tablero y conserva la posicion del snake
				obstaculosRandom 		# Coloca nuevos obstaculos
				frutasRandom			# Coloca nuevas frutas
				
				# Imprime el puntaje por consola #
				la $a0, salto   		# Salto para que se vea mas ordenado
				li $v0, 4
				syscall
				
				la $a0, Puntaje			
				li $v0, 4
				syscall
								
				move $a0, $s0
				li $v0, 1
				syscall
				
				la $a0, salto			# Salto para que se vea mas ordenado
				li $v0, 4
				syscall
				
				sw $zero, TiempoI		# Retorna a 0 la posicion de memoria donde se guarda el tiempo para que se cuente a partir de ahí 10 segundos
				
				blt  $t6, 200, siga		# Condicion para que la velocidad no disminuya menor a 0.20 segundos
				aumentarVelocidad		# Aumenta la velocidad
				
				siga:
				b loopJuego			# Retorna para seguir jugando
			
		
	# Condiciones del loop de vidas  #
	
	beqz $s1, reiniciar          				#  Si llego a 0 vida pregunto para reiniciar		
	ble  $s1, 3, loopVidas	     				#  Sino vuelvo a iniciar todo el proceso del juego							
	
	#  Para reiniciar el Juego  #
reiniciar:
	
	la $a0, reinicio   #  Pregunto por otra partida
	li $v0, 50
	syscall
	
	
	
	beqz $a0, otraPartida 
	
	# Para salir del juego #
	final:
	li $v0, 10
	syscall
	
	# Permite otra partida #
	otraPartida:
		b principio
