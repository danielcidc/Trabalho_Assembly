;ARQUIVO UNIFICADOR DO PROJETO (posteriormente será dividido em módulos)


segment code

;org 100h
..start:

    MOV     AX, data        ;Inicializa os registradores
	MOV     DX, AX
	MOV     AX, stack
	MOV     SS, AX
	MOV     SP, stacktop
	
    ;Reprogramando a tabela de Interrupção
	CLI

    XOR     AX, AX
    MOV     ES, AX

    MOV     AX, [ES:int9*4]
	MOV     [offset_dos], AX
	MOV     AX, [ES:int9*4+2]
	MOV     [cs_dos], AX
	
	MOV     [ES:int9*4+2], CS
	MOV     WORD [ES:int9*4],keyint

    ;Salvar o modo corrente de vídeo (vendo como está o modo de vídeo na máquina)
    MOV     AH, 0Fh
    INT     10h
    MOV     [modo_anterior], AL

    ;Alterar modo de vídeo para gráfico 640x480 16 cores
    MOV    AL, 12h
    MOV    AH, 0
    INT    10h
	
	;Inicialização da interface gráfica
	MOV     byte[cor], branco_intenso 
	
	CALL     interface_bordas
	MOV     byte[cor], vermelho 
	CALL     interface_raquete
	CALL     interface_bolinha 
	
	;Loop principal do programa (animação da raquete e da bolinha)
	animation:
	    INC     word[modo_pixel]
		CALL     testateclaHardware
		
		;bolinha animada
		MOV     byte[cor], preto
		CALL     interface_bolinha 
		CALL     raqueteMover
		CALL     interface_raquete 
		
		;ajustando a posição da raquete no eixo XY
		MOV     DX, [raquete_posicaoX]
		CMP     DX, 371
		JB     raqueteAjustaPosicaoY
		
		raqueteAjustaPosicaoX:
		    CALL        raqueteAjusta
        
        raqueteAjustaPosicaoY:
        ;Deslocamento da bola em Y (decrementa Y)
           XOR         AX, AX
           MOV        CX, [bola_movimento]
           MOV        CX, [bola_velocidadeY]
           INC        AX
           CMP        AL, 0
           JBE        bolaDecrementaY
           ADD        word[bola_posicaoY], CX
           JMP        bolaIncrementaX

        bolaDecrementaY:
            SUB         word[bola_posicaoY], CX 
        
        ; Deslocamento da posição da bola em X (incrementa e decrementa X) 
        bolaIncrementaX:
			XOR			AX, AX
			MOV			AL, [bola_velocidadeX]
			CMP			AL, 0
			JS			bolaDecrementaX
			ADD			word[bola_posicaoX], CX		
			JMP			colisaoBR
		bolaDecrementaX:
			SUB			word[bola_posicaoX], CX
			
		; Tratamento de colisao com a raquete e bolinha
		colisaoBR:
			MOV			byte[cor],vermelho
			CALL		interface_bolinha
		    CALL		colisao
			CALL 		int_15h
			JMP			animation	
			
			
	;-------- DIVISÓRIAS DA INTERFACE --------;
	interface_bordas:
			
		; Preparação para começar a desenhar as bordas 
		xor			ax,ax
		mov			cx,639
		mov			dx,479
		mov			byte[cor],branco_intenso
		
		; Borda direita 
		push		cx
		push		ax
		push		cx
		push		dx
		
		; Borda superior 
		push		cx
		push		dx
		push		ax
		push		dx
				
		; Borda esquerda 
		push		ax
		push		dx
		push		ax
		push		ax
		
		; Borda do meio 
		push		ax
		push		dx
		push		cx
		push		dx
				

		; Desenhando as bordas
		call        line
		call		line
		call		line
		call		line
		ret


	interface_bordaDireita:	
		; Salvando o contexto
		push		ax
		push		bx
		push		cx
		push		dx
		
		; Preparação para começar a desenhar as bordas 
		xor			ax,ax
		mov			cx,639
		mov			dx,479
		mov			byte[cor],branco

		; Desenhando a borda direita
		push		cx
		push		ax
		push		cx
		push		dx
		call		line 

		; Recuperando o contexto
		pop			dx
		pop			cx
		pop			bx
		pop			ax
		ret
		
	;---------- CONSTRUTOR DE LINHAS (responsável de desenhar as linhas na interface) ----------; 
	line:
	   		PUSH		BP
			MOV		BP,SP
			PUSHF                        ;coloca os flags na pilha
			PUSH 		AX
			PUSH 		BX
			PUSH		CX
			PUSH		DX
			PUSH		SI
			PUSH		DI
			MOV		AX, [BP+10]   ; resgata os valores das coordenadas
			MOV		BX, [BP+8]    ; resgata os valores das coordenadas
			MOV	    CX, [BP+6]    ; resgata os valores das coordenadas
			MOV		DX, [BP+4]    ; resgata os valores das coordenadas
			CMP 	AX, CX
			JE		line2
			JB		line1
			XCHG		AX, CX
			XCHG		BX, DX
			JMP		line1
	line2:		; deltax=0
			CMP		BX, DX  ;subtrai dx de bx
			JB		line3
			XCHG		BX, DX        ;troca os valores de bx e dx entre eles
	line3:	; dx > bx
			PUSH		AX
			PUSH		BX
			CALL 		plot_xy
			CMP		BX, DX
			JNE		line31
			JMP		fim_line
	line31:		INC 	BX
			JMP		line3
	;deltax <>0
	line1:
	; comparar m�dulos de deltax e deltay sabendo que cx>ax
		; cx > ax
			push		cx
			sub		cx,ax
			mov		[deltax],cx
			pop		cx
			push		dx
			sub		dx,bx
			ja		line32
			neg		dx
	line32:		
			mov		[deltay],dx
			pop		dx

			push		ax
			mov		ax,[deltax]
			cmp		ax,[deltay]
			pop		ax
			jb		line5

		; cx > ax e deltax>deltay
			push		cx
			sub		cx,ax
			mov		[deltax],cx
			pop		cx
			push		dx
			sub		dx,bx
			mov		[deltay],dx
			pop		dx

			mov		si,ax
	line4:
			push		ax
			push		dx
			push		si
			sub		si,ax	;(x-x1)
			mov		ax,[deltay]
			imul		si
			mov		si,[deltax]		;arredondar
			shr		si,1
	; se numerador (DX)>0 soma se <0 subtrai
			cmp		dx,0
			jl		ar1
			add		ax,si
			adc		dx,0
			jmp		arc1
	ar1:		sub		ax,si
			sbb		dx,0
	arc1:
			idiv		word [deltax]
			add		ax,bx
			pop		si
			push		si
			push		ax
			call		plot_xy
			pop		dx
			pop		ax
			cmp		si,cx
			je		fim_line
			inc		si
			jmp		line4

	line5:		cmp		bx,dx
			jb 		line7
			xchg		ax,cx
			xchg		bx,dx
	line7:
			push		cx
			sub		cx,ax
			mov		[deltax],cx
			pop		cx
			push		dx
			sub		dx,bx
			mov		[deltay],dx
			pop		dx
			mov		si,bx
	line6:
			push		dx
			push		si
			push		ax
			sub		si,bx	;(y-y1)
			mov		ax,[deltax]
			imul		si
			mov		si,[deltay]		;arredondar
			shr		si,1
	; se numerador (DX)>0 soma se <0 subtrai
			cmp		dx,0
			jl		ar2
			add		ax,si
			adc		dx,0
			jmp		arc2
	ar2:		sub		ax,si
			sbb		dx,0
	arc2:
			idiv		word [deltay]
			mov		di,ax
			pop		ax
			add		di,ax
			pop		si
			push		di
			push		si
			call		plot_xy
			pop		dx
			cmp		si,dx
			je		fim_line
			inc		si
			jmp		line6

	fim_line:
			pop		di
			pop		si
			pop		dx
			pop		cx
			pop		bx
			pop		ax
			popf
			pop		bp
			ret		8 
		
		; ---------- PLOT XY (definindo os parâmetros de coordenadas) -------------------- ;
		
	plot_xy:
		PUSH    BP
		MOV		BP,SP
    ;Salvando o contexto, empilhando registradores		
		PUSHF
		PUSH 	AX
		PUSH 	BX
		PUSH	CX
		PUSH	DX
		PUSH	SI
		PUSH	DI
    ;Preparando para chamar a int 10h	    
	    MOV     AH,0Ch      ;INT 10h/AH = 0Ch - change color for a single pixel.
	    MOV     AL,[cor]    ;AL = pixel color    
	    MOV     BH,0
	    MOV     DX,479
		SUB		DX,[BP+4]   ;DX = row
	    MOV     CX,[BP+6]   ;CX = column - Load in AX
	    INT     10h
    ;Recupera-se o contexto		
		POP     DI
		POP		SI
		POP		DX
		POP		CX
		POP		BX
		POP		AX
		POPF
		POP		BP
		RET		4			;Add 4 cause row and column were updated before to enter in the function
		
		
		; ------------ CURSOR (construtor do cursor do mouse) ----------; 
		
	cursor:
    ;Salvando o contexto, empilhando registradores
		PUSHF
		PUSH 	AX
		PUSH 	BX
		PUSH	CX
		PUSH	DX
		PUSH	SI
		PUSH	DI
		PUSH	BP
    ;Preparando para chamar a int 10h	        	
		MOV     AH,2        ;INT 10h/AH = 2 - set cursor position.
		MOV     BH,0        ;BH = page number (0..7).
                            ;DL = column.		
		INT     10h
    ;Recupera-se o contexto			
		POP		BP
		POP		DI
		POP		SI
		POP		DX
		POP		CX
		POP		BX
		POP		AX
		POPF
		RET
		
		
		;------------ INTERFACE DA BOLINHA --------------;
	interface_bolinha:
		MOV			CX, [bola_posicaoX]
		PUSH		CX
		MOV			CX, [bola_posicaoY]
		PUSH		CX
		MOV			CX, bola_raio
		PUSH		CX
		CALL		full_circle
		RET
		

		; ----------- CONSTRUTOR DE F_CIRCLE (Construtor da bolinha) --------- ; 
		
	full_circle:
	    PUSH 	bp
	    MOV	 	bp,sp
	    PUSHf                        ;coloca os flags na pilha
	    PUSH 	ax
	    PUSH 	bx
	    PUSH	cx
	    PUSH	dx
	    PUSH	si
	    PUSH	di

	    MOV		ax,[bp+8]    ; resgata xc
	    MOV		bx,[bp+6]    ; resgata yc
	    MOV		cx,[bp+4]    ; resgata r
	
	    MOV		si,bx
	    SUB		si,cx
	    PUSH    ax			;coloca xc na pilha			
	    PUSH	si			;coloca yc-r na pilha
	    MOV		si,bx
	    ADD		si,cx
	    PUSH	ax		;coloca xc na pilha
	    PUSH	si		;coloca yc+r na pilha
	    CALL line
	
		
	    MOV		di,cx
	    SUB		di,1	 ;di=r-1
	    MOV		dx,0  	;dx ser� a vari�vel x. cx � a variavel y
	
;aqui em cima a l�gica foi invertida, 1-r => r-1
;e as compara��es passaram a ser jl => JG, assim garante 
;valores positivos para d

    stay_full:				;loop
	    MOV		si,di
	    CMP		si,0
	    JG		inf_full       ;caso d for menor que 0, seleciona pixel superior (n�o  SALta)
	    MOV		si,dx		;o jl � importante porque trata-se de conta com sinal
	    SAL		si,1		;multiplica por doi (shift arithmetic left)
	    ADD		si,3
	    ADD		di,si     ;nesse ponto d=d+2*dx+3
	    INC		dx		;INCrementa dx
	    JMP		plotar_full
    inf_full:	
	    MOV		si,dx
	    SUB		si,cx  		;faz x - y (dx-cx), e SALva em di 
	    SAL		si,1
	    ADD		si,5
	    ADD		di,si		;nesse ponto d=d+2*(dx-cx)+5
	    INC		dx		;INCrementa x (dx)
	    DEC		cx		;DECrementa y (cx)
	
    plotar_full:	
	    MOV		si,ax
	    ADD		si,cx
	    PUSH	si		;coloca a abcisa y+xc na pilha			
	    MOV		si,bx
	    SUB		si,dx
	    PUSH    si		;coloca a ordenada yc-x na pilha
	    MOV		si,ax
	    ADD		si,cx
	    PUSH	si		;coloca a abcisa y+xc na pilha	
	    MOV		si,bx
	    ADD		si,dx
	    PUSH    si		;coloca a ordenada yc+x na pilha	
	    CALL 	line
	
	    MOV		si,ax
	    ADD		si,dx
	    PUSH	si		;coloca a abcisa xc+x na pilha			
	    MOV		si,bx
	    SUB		si,cx
	    PUSH    si		;coloca a ordenada yc-y na pilha
	    MOV		si,ax
	    ADD		si,dx
	    PUSH	si		;coloca a abcisa xc+x na pilha	
	    MOV		si,bx
	    ADD		si,cx
	    PUSH    si		;coloca a ordenada yc+y na pilha	
	    CALL	line
	
	    MOV		si,ax
	    SUB		si,dx
	    PUSH	si		;coloca a abcisa xc-x na pilha			
	    MOV		si,bx
	    SUB		si,cx
	    PUSH    si		;coloca a ordenada yc-y na pilha
	    MOV		si,ax
	    SUB		si,dx
	    PUSH	si		;coloca a abcisa xc-x na pilha	
	    MOV		si,bx
	    ADD		si,cx
	    PUSH    si		;coloca a ordenada yc+y na pilha	
	    CALL	line
	
	    MOV		si,ax
	    SUB		si,cx
	    PUSH	si		;coloca a abcisa xc-y na pilha			
	    MOV		si,bx
	    SUB		si,dx
	    PUSH    si		;coloca a ordenada yc-x na pilha
	    MOV		si,ax
	    SUB		si,cx
	    PUSH	si		;coloca a abcisa xc-y na pilha	
	    MOV		si,bx
	    ADD		si,dx
	    PUSH    si		;coloca a ordenada yc+x na pilha	
	    CALL	line
	
	    CMP		cx,dx
	    JB		fim_full_circle  ;se cx (y) est� abaixo de dx (x), termina     
	    JMP		stay_full		;se cx (y) est� acima de dx (x), continua no loop
	
	
    fim_full_circle:
	    POP		di
	    POP		si
	    POP		dx
	    POP		cx
	    POP		bx
	    POP		ax
	    POPF
	    POP		bp
	    RET		6
	
	
	;-------- INTERFACE DA RAQUETE --------;
	interface_raquete:
		PUSH		CX
		MOV			byte[cor], branco_intenso
		PUSH		word[raquete_posicaoX]
		PUSH		word[raquete_posicaoY]
		MOV			CX,[raquete_posicaoY]
		ADD			CX,raquete_tamanho
		PUSH		word[raquete_posicaoX]
		PUSH		CX
		CALL		line

		POP			CX
		RET

    ;-------- ROTINA PARA AJUSTAR A RAQUETE --------;
	raqueteAjusta:
		MOV			byte[cor],branco
		PUSH		word 598
		PUSH		word 431
		PUSH		word 601
		PUSH		word 431
		CALL 		line
		RET
		
	;-------- ROTINA PARA MOVER A RAQUETE --------;
	raqueteMover:
		xor			ax,ax
		mov			al,byte[raquete_checa]		
		cmp			al,0
		ja			raquetePara
		mov			dx,[raquete_posicaoX]
		mov			cx,[raquete_movimento]
		mov			ah,[raquete_velocidade]
		inc			ah
		cmp			ah,1
		jz			raqueteFinal
		ja			raquetePosicao

		; invertendo o movimento da raquete 
		raqueteMoveInversamente:
			cmp			dx,10
			jb			raqueteFinal

			mov			byte[cor],preto 			;apagando a posição que estava anteriormente
			mov			ax,[raquete_posicaoY]
			add			ax,raquete_tamanho+1		;ascendendo em uma posição de 1 pixel a mais 
			push		word[raquete_posicaoX]
			push		ax
			sub			ax,[raquete_movimento]
			push		word[raquete_posicaoX]
			push		ax
			call 		line		
		
		;mudando para a nova posição
			sub			[raquete_posicaoX],cx
			mov			byte[raquete_checa],1	; pode se mover a cada 1(+1) frames
			jmp			raqueteFinal
			
		raquetePosicao:
			cmp			dx,371
			ja			raqueteFinal

			mov			byte[cor],preto			;apagando a posição que estava anteriormente
			mov			ax,[raquete_posicaoX]
			push		word[raquete_posicaoY]
			push		ax
			add			ax,[raquete_movimento]
			dec			ax					
			push		word[raquete_posicaoY]
			push		ax
			call 		line
			
		;Mudando para a nova posição
			add			[raquete_posicaoX],cx
			mov			byte[raquete_checa],1
			jmp			raqueteFinal
		raquetePara:
			dec			byte[raquete_checa]
		raqueteFinal:
			mov			byte[raquete_velocidade],0
			ret
			
	;-------- TRATAMENTO DAS COLISÕES --------;
	colisao:		
		; Verificando colisão com a bola
		mov 		bx,[bola_posicaoX]
		mov			dx,[bola_posicaoY]

		; Verificando colisão com a raquete em X
		cmp			bx,600-bola_raio
		jb			colisaoX
		cmp			bx,595	
		ja			colisaoX

		; Verificando colisão com a raquete em X
		mov			ax,[raquete_posicaoX]
		cmp			ax,7
		jb	raqueteColisaoNegada		
		sub			ax,7	
		raqueteColisaoNegada:
			cmp			dx,ax
			jb			colisaoX
			add			ax,14+raquete_tamanho
			cmp			dx,ax
			ja			colisaoX
		raqueteColisaoEfetivada:
			neg			byte[bola_velocidadeX]
			inc			byte[raquete_colisao]
			jmp			colisaoY
		
		; Verificando colisão com as paredes
		colisaoX:
			cmp			bx,639-bola_raio
			jae			paredeDireitaColisaoEfetivada
			cmp			bx,1+bola_raio
			jbe			colisaoEfetivadaX
			jmp			colisaoY	
			
		paredeDireitaColisaoEfetivada:
			mov			byte[cor],preto
			call		interface_bolinha
			pop			dx
			mov			word[bola_posicaoX],23
			call		interface_bordaDireita
			jmp			colisaoY
			colisaoEfetivadaX:
			neg			byte[bola_velocidadeX]

		colisaoY:
			cmp			dx,429-bola_raio
			jae			colisaoEfetivadaY
			cmp			dx,1+bola_raio
			jbe			colisaoEfetivadaY
			mov			byte[bola_colisaoY],0
			jmp			colisaoRET
			colisaoEfetivadaY:
			neg			byte[bola_velocidadeY]
			mov			byte[bola_colisaoY],1
		colisaoRET:
			ret
			
			
	;-------- SAIR DO JOGO --------;
	sai:	
		; Restaurando a tabela de interrupções

		XOR     AX, AX
		MOV     ES, AX
		MOV     AX, [cs_dos]
		MOV     [ES:int9*4+2], AX
		MOV     AX, [offset_dos]
		MOV     [ES:int9*4], AX 

		; Saindo do progama
		mov    	ah,08h
		int     21h
	    mov  	ah,0   			; set video mode
	    mov  	al,[modo_anterior]   	; modo anterior
	    int  	10h
		mov     ax,4c00h
		int     21h	
			
			
	;-------- USO DO KeyInt ---------;
	keyint:
		PUSH    AX
		push    bx
		push    ds
		mov     ax,data
		mov     ds,ax
		IN      AL, kb_data
		inc     WORD [p_i]
		and     WORD [p_i],7
		mov     bx,[p_i]
		mov     [bx+tecla],al
		IN      AL, kb_ctl
		OR      AL, 80h
		OUT     kb_ctl, AL
		AND     AL, 7Fh
		OUT     kb_ctl, AL
		MOV     AL, eoi
		OUT     pictrl, AL
		pop     ds
		pop     bx
		POP     AX
		IRET
		
	;-------- TESTA A TECLA VIA A INTERRUPÇÃO DO HARDWARE --------;
	testateclaHardware:	
		mov     ax,[p_i]
		CMP     ax,[p_t]
		JE      testateclaRetorna

		inc     word[p_t]
		and     word[p_t],7
		mov     bx,[p_t]

		XOR     AX, AX
		MOV     AL, [bx+tecla]

		; Comparação Hardware para Sair
		cmp al, 1Fh
		je sai	

		; Comparação Hardware para mover a raquete para cima
		cmp al, 16h
		je 			testateclaU		;

		; Comparação Hardware para mover a raquete para baixo
		cmp			al,20h
		je 			testateclaD		;


		; Rotina para retornar/ continuar a execução do programa 
		testateclaRetorna:
			ret

		; Rotina para mover a raquete para cima 
		testateclaU:
			mov			byte[raquete_velocidade],1
			jmp			testateclaRetorna

		; Rotina para mover a raquete para baixo 
		testateclaD:
			mov			byte[raquete_velocidade],-1
			jmp			testateclaRetorna
		
	;-------- USO DO INT 15h --------;
	int_15h:		
		PUSH		cx			
		XOR cx,cx
		MOV dx, [modo_velocidade]
		MOV ah,86h
		INT 15h
		POP		cx
		RET

;*******************************************************************

segment data

    cor		db		branco_intenso

    ;	I R G B COR
    ;	0 0 0 0 preto
    ;	0 0 0 1 azul
    ;	0 0 1 0 verde
    ;	0 0 1 1 cyan
    ;	0 1 0 0 vermelho
    ;	0 1 0 1 magenta
    ;	0 1 1 0 marrom
    ;	0 1 1 1 branco
    ;	1 0 0 0 cinza
    ;	1 0 0 1 azul claro
    ;	1 0 1 0 verde claro
    ;	1 0 1 1 cyan claro
    ;	1 1 0 0 rosa
    ;	1 1 0 1 magenta claro
    ;	1 1 1 0 amarelo
    ;	1 1 1 1 branco intenso	

    preto		    equ		0
    azul		    equ		1
    verde		    equ		2
    cyan		    equ		3
    vermelho	    equ		4
    magenta		    equ		5
    marrom		    equ		6
    branco		    equ		7
    cinza		    equ		8
    azul_claro	    equ		9
    verde_claro	    equ		10
    cyan_claro	    equ		11
    rosa		    equ		12
    magenta_claro	equ		13
    amarelo		    equ		14
    branco_intenso	equ		15

;---- Variáveis auxiliares (line.asm) ----;
    linha    dw    0
	coluna    dw    0
	deltax    dw    0
	deltay    dw    0
	
;---- Variáveis para o modo de animação / tela ----;
    modo_anterior    db    0
    modo_pixel    dw    0
	modo_velocidade    dw    9999h
	
;---- Variáveis para a raquete ----;
    raquete_posicaoX    dw    320
	raquete_posicaoYASCII	db	'000'
	raquete_posicaoY        dw  48 
	raquete_tamanho		    equ	50
	raquete_velocidade		db  0
	raquete_movimento		db  10
	raquete_checa			db  0
	raquete_colisao			db	0
	
;---- Variáveis para a bolinha ----;
    bola_posicaoX			dw  23 ; Posição inicial 
	bola_posicaoXASCII		db	'000'
	bola_velocidadeX		db  1
	bola_colisaoX	db  0	; Bit que indica se houve colisão com parede em x no frame anterior
	bola_posicaoY			dw 	239 ; Posição inicial y
	bola_posicaoYASCII		db	'000'
	bola_velocidadeY		db  -1
	bola_colisaoY	db  0	; Bit que indica se houve colisão com parede em y no frame anterior

	bola_movimento      	dw  6
	bola_raio				equ 10
	
;---- Variáveis para a rotina KeyInt ----;

	kb_data EQU 	60h  ;PORTA DE LEITURA DE TECLADO
	kb_ctl  EQU 	61h  ;PORTA DE RESET PARA PEDIR NOVA INTERRUPCAO
	pictrl  EQU 	20h
	eoi     EQU 	20h
	int9    EQU 	9h
	cs_dos  DW  	1
	offset_dos  DW 	1
	tecla_u db 		0
	tecla   resb  	8 
	p_i     dw  	0   ;ponteiro p/ interrupcao (qnd pressiona tecla)  
	p_t     dw  	0   ;ponterio p/ interrupcao ( qnd solta tecla)    
	teclasc DB  	0,0,13,10,'$'

;*******************************************************************
segment stack stack
            resb        512
stacktop: