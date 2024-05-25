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
		CALL     raquete_Mover
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
			pop		
		
		
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
	    POPf
	    POP		bp
	    RET		6
	
	
	;--------- INTERFACE DA RAQUETE ------------;
	interface_raquete:
		PUSH		CX
		MOV			byte[cor],branco_intenso
		PUSH		word[raquete_posicaoX]
		PUSH		word[raquete_posicaoY]
		MOV			CX,[raquete_posicaoY]
		ADD			CX,raquete_tamanho
		PUSH		word[raquete_posicaoX]
		PUSH		CX
		CALL		line

		POP			CX
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

;*******************************************************************
segment stack stack
            resb        512
stacktop: