;-----------------------------------------------------------------------------------;
;             PROJETO BREAKER PONG - SISTEMAS EMBARCADOS I (ELE 8575)               ;
;                                                                                   ;
; Dupla: DANIEL CID CONSTANTINIDIS e DARUÊ EUZEBIO FERNANDES                        ;
; Professor: CAMILO ARTURO RODRIGUEZ DIAZ                                           ;
; Curso: ENGENHARIA ELÉTRICA                                                        ;
;                                                                                   ;
;-----------------------------------------------------------------------------------;
; Descrição:                                                                        ;
;        O projeto consiste num jogo de ping-pong (quebrando blocos), onde o        ;
;        usuário pode ou não deixar cair a bola fora da região de jogo - "fora      ;
;        de tela". A dificuldade do jogo vai ser fixa. Essa primeira interface      ;
;        com o usuário vai ficar fixa até começar o jogo. A tecla Enter será        ;
;        usada para dar início ao jogo. Durante o jogo, o jogador poderá pausar     ;
;        o jogo (tecla p) durante tempo indefinido. Depois da tecla "p" ser         ;
;        acionada de novo, o jogo continuará sua execução normalmente. Se a letra   ;
;        "q" for pressionada o jogo fecha. No caso que o jogador deixa cair a       ;
;        bola "fora de tela", uma mensagem/imagem "Game Over" tem que aparecer e    ;
;        perguntar ao usuário se quer reiniciar a partida ou sair do jogo com as    ;
;        teclas "y" para continuar e "n". O objetivo é quebrar os blocos a cada     ;
;        contato com a bola. Uma matriz de 6x2 forma os blocos uniformemente        ;
;        distribuídos. Uma vez destruídos os blocos o jogo finaliza.   		        ;
;                                                                                   ; 
;        Os requerimentos da interface são:                                         ;    
;                                                                                   ;    
;        1) A bola vai percorrer sempre a tela com ângulos de 45 graus, sem         ;
;          retornar à direção que ela vem.                                          ;
;        2) O controle da base será feito com as setas direita e esquerda.          ;                                
;        3) Uma quadrícula da tela será feita para limitar as paredes (direita,     ;
;           superior, esquerda). A parte inferior só terá a base onde a bola vai    ;
;           quicar (retângulo).		                                                ;
;        4) O jogo pode ser finalizado em qualquer momento com a tecla "q".         ;                    
;        5) O jogo pode ser pausado em qualquer momento com a tecla "p".            ;
;        6) O jogo finaliza quando todos os blocos sejam quebrados (2 filas x 6     ;
;           colunas). A cada contato da bola com o bloco, ele é deletado e deve     ;
;           ser atualizado o limite superior onde a bola vai quicar, ou seja, se    ;
;           a bola percorrer o mesmo caminho, esta deve ser capaz de atingir o      ;
;           bloco da primeira fila (bloco vermelho ou azul) e "quebrar" ele.		;
;                                     												;
;-----------------------------------------------------------------------------------;

extern line, full_circle, cursor, caracter, plot_xy 
global cor

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
	
	
	
	;---------- CONSTRUTOR DE LINHAS (deixe na main por enquanto) ----------; 
	line:
		PUSH 	BP
	    MOV	 	BP,SP
;Salvando o contexto, empilhando registradores		
	    PUSHF
		PUSH 	AX
		PUSH 	BX
		PUSH	CX
		PUSH	DX
		PUSH	SI
		PUSH	DI
;Resgata os valores das coordenadas	previamente definidas antes de chamar a funcao line
		MOV		AX,[bp+10]  ;x1
		MOV		BX,[bp+8]   ;y1 
		MOV		CX,[bp+6]   ;x2 
		MOV		DX,[bp+4]   ;y2
		
		CMP		AX,CX       ;Compare x1 with x2 
		JE		lineV       ;Jump to Vertical Line
		
		JB		line1       ;Jump if x1 < x2 
		
		XCHG	AX,CX       ;else, exchange x1 with x2,
		XCHG	BX,DX       ;and exchange y1 with y2,
		JMP		line1

;---------------- Vertical line ------------------------------
lineV:		                ;DeltAX=0
		CMP		BX,DX       ;Compare y1 with y2                   |
		JB		lineVD      ;Jump if y1 < y2, down vertical line \|/ 
		XCHG	BX,DX       ;else, exchange y1 with y2, up vertical line /|\        
lineVD:	                    ;                                             |
		PUSH	AX          ;column
		PUSH	BX          ;row
		CALL 	plot_xy
		
		CMP		BX,DX       ;Compare y1 with y2
		JNE		IncLineV    ;if not equal, jump to increase pixel
		JMP		End_line    ;else jump fim_line
IncLineV:	
        INC		BX
		JMP		lineVD

;---------------- Horizotnal line ----------------------------
;DeltAX <,=,>0
line1:
;Compare modulus DeltAX & Deltay due to CX > AX -> x2 > x1
		PUSH	CX          ;Save x2 in stack
		SUB		CX,AX       ;CX = CX-AX -> x2 = x2-x1 -> DeltAX
		MOV		[deltax],CX ;Save deltAX
		POP		CX          ;CX = x2
		
		PUSH	DX          ;Save y2 in stack		
		SUB		DX,BX       ;DX = DX-BX -> y2 = y2-y1 -> Deltay \
		JA		line32      ;Jump if DX > BX -> y2 > y1          \|
		NEG		DX          ;else, invert DX                                   --

;y = -mx+b 
line32:		
		MOV		[deltay],DX ;Save deltay
		POP		DX          ;DX = y2

		PUSH	AX          ;Save x2 in stack
		MOV		AX,[deltax] ;Compare DeltAX with DeltaY
		CMP		AX,[deltay]
		POP		AX          ;AX = x2
		JB		line5       ;Jump if DeltAX < DeltaY

	; CX > AX e deltAX>deltay
		PUSH	CX
		SUB		CX,AX
		MOV		[deltax],CX
		POP		CX
		PUSH	DX
		SUB		DX,BX
		MOV		[deltay],DX
		POP		DX

		MOV		SI,AX
line4:
		PUSH	AX
		PUSH	DX
		PUSH	SI
		SUB		SI,AX	;(x-x1)
		MOV		AX,[deltay]
		IMUL		SI
		MOV		SI,[deltax]		;arredondar
		SHR		SI,1
; se numerador (DX)>0 soma se <0 SUBtrai
		cmp		DX,0
		JL		ar1
		ADD		AX,SI
		ADC		DX,0
		JMP		arc1
ar1:	SUB		AX,SI
		sbb		DX,0
arc1:
		idiv    word[deltax]
		ADD		AX,BX
		POP		SI
		PUSH	SI
		PUSH	AX
		call	plot_xy
		POP		DX
		POP		AX
		cmp		SI,CX
		je		End_line
		inc		SI
		JMP		line4
                                ;                         --
line5:	cmp		BX,DX           ;Compare y1 with y2       /|
		jb 		line7           ;Jump if y1 < y2 -> line /
		xchg	AX,CX       ;else 
		xchg	BX,DX
line7:                          
		PUSH	CX
		SUB		CX,AX
		MOV		word[deltax],CX
		POP		CX
		PUSH	DX
		SUB		DX,BX
		MOV		[deltay],DX
		POP		DX

		MOV		SI,BX
line6:
		PUSH	DX
		PUSH	SI
		PUSH	AX
		SUB		SI,BX	;(y-y1)
		MOV		AX,[deltax]
		IMUL		SI          ;SIgned multiply
		MOV		SI,[deltay]		;arredondar
		SHR		SI,1            ;Shift operand1 Right
		
; se numerador (DX)>0 soma se <0 SUBtrai
		cmp		DX,0
		JL		ar2
		ADD		AX,SI
		ADC		DX,0
		JMP		arc2
ar2:	SUB		AX,SI
		sbb		DX,0
arc2:
		idiv    word[deltay]
		MOV		di,AX
		POP		AX
		ADD		di,AX
		POP		SI
		PUSH	di
		PUSH	SI
		call	plot_xy
		POP		DX
		cmp		SI,DX
		je		End_line
		inc		SI
		JMP		line6

End_line:
		POP		DI
		POP		SI
		POP		DX
		POP		CX
		POP		BX
		POP		AX
		POPF
		POP		BP
		RET		8
		
		
		; ---------- PLOT XY (deixe na main por enquanto) ----------;
		
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
		
		
		; ------------ CURSOR (deixe na main por enquanto) ----------; 
		
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
		
		
		
		; ----------- CONSTRUTOR DE F_CIRCLE (deixe na main) --------- ; 
		
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
	ret		6

    

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