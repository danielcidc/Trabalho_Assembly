; versão de 18/10/2022
; Uso de diretivas extern e global 
; Professor Camilo Diaz

extern line, full_circle, circle, cursor, caracter, plot_xy, full_rec
global cor

segment code

;org 100h
..start:
        MOV     AX,data			;Inicializa os registradores
    	MOV 	DS,AX
    	MOV 	AX,stack
    	MOV 	SS,AX
    	MOV 	SP,stacktop

;Salvar modo corrente de video(vendo como esta o modo de video da maquina)
        MOV  	AH,0Fh
    	INT  	10h
    	MOV  	[modo_anterior],AL   

;Alterar modo de video para grafico 640x480 16 cores
    	MOV     AL,12h
   		MOV     AH,0
    	INT     10h
		
;desenhar retas
       
		MOV		byte [cor],branco_intenso	;linha
		MOV		AX,9		;x1
		PUSH	AX
		MOV		AX,9		;y1
		PUSH	AX
		MOV		AX,9		;x2
		PUSH	AX
		MOV		AX,470		;y2
		PUSH	AX
		CALL	line
				
		MOV		AX,9		;x1
		PUSH	AX
		MOV		AX,470		;y1
		PUSH	AX
		MOV		AX,631		;x2
		PUSH	AX
		MOV		AX,470		;y2
		PUSH	AX
		CALL	line
		
		MOV		AX,631		;x1
		PUSH	AX
		MOV		AX,470		;y1
		PUSH	AX
		MOV		AX,631		;x2
		PUSH	AX
		MOV		AX,9		;y2
		PUSH	AX
		CALL	line
		
;-----------------------------------------------------------------------------------------
;Bloco 1
MOV     byte [cor],magenta
        MOV		AX,19		;x (inferior esquerda)
        PUSH    AX
        MOV		AX,430		;y (inferior esquerda)
        PUSH    AX
        MOV		AX,25		;altura
        PUSH    AX
        MOV		AX,85		;largura
        PUSH    AX
        CALL    full_rec
;-----------------------------------------------------------------------------------------
;Bloco 2
MOV     byte [cor],azul
        MOV		AX,121		;x (inferior esquerda)
        PUSH    AX
        MOV		AX,430		;y (inferior esquerda)
        PUSH    AX
        MOV		AX,25		;altura
        PUSH    AX
        MOV		AX,85		;largura
        PUSH    AX
        CALL    full_rec
;-----------------------------------------------------------------------------------------
;Bloco 3
MOV     byte [cor],cyan
        MOV		AX,223		;x (inferior esquerda)
        PUSH    AX
        MOV		AX,430		;y (inferior esquerda)
        PUSH    AX
        MOV		AX,25		;altura
        PUSH    AX
        MOV		AX,85		;largura
        PUSH    AX
        CALL    full_rec
;-----------------------------------------------------------------------------------------
;Bloco 4
MOV     byte [cor],verde_claro
        MOV		AX,325		;x (inferior esquerda)
        PUSH    AX
        MOV		AX,430		;y (inferior esquerda)
        PUSH    AX
        MOV		AX,25		;altura
        PUSH    AX
        MOV		AX,85		;largura
        PUSH    AX
        CALL    full_rec
;-----------------------------------------------------------------------------------------
;Bloco 5
MOV     byte [cor],amarelo
        MOV		AX,427		;x (inferior esquerda)
        PUSH    AX
        MOV		AX,430		;y (inferior esquerda)
        PUSH    AX
        MOV		AX,25		;altura
        PUSH    AX
        MOV		AX,85		;largura
        PUSH    AX
        CALL    full_rec
;-----------------------------------------------------------------------------------------
;Bloco 6
MOV     byte [cor],vermelho
        MOV		AX,529		;x (inferior esquerda)
        PUSH    AX
        MOV		AX,430		;y (inferior esquerda)
        PUSH    AX
        MOV		AX,25		;altura
        PUSH    AX
        MOV		AX,85		;largura
        PUSH    AX
        CALL    full_rec
;-----------------------------------------------------------------------------------------

;Bloco 7
MOV     byte [cor],vermelho
        MOV		AX,19		;x (inferior esquerda)
        PUSH    AX
        MOV		AX,390		;y (inferior esquerda)
        PUSH    AX
        MOV		AX,25		;altura
        PUSH    AX
        MOV		AX,85		;largura
        PUSH    AX
        CALL    full_rec
;-----------------------------------------------------------------------------------------
;Bloco 8
MOV     byte [cor],amarelo
        MOV		AX,121		;x (inferior esquerda)
        PUSH    AX
        MOV		AX,390		;y (inferior esquerda)
        PUSH    AX
        MOV		AX,25		;altura
        PUSH    AX
        MOV		AX,85		;largura
        PUSH    AX
        CALL    full_rec
;-----------------------------------------------------------------------------------------
;Bloco 9
MOV     byte [cor],verde_claro
        MOV		AX,223		;x (inferior esquerda)
        PUSH    AX
        MOV		AX,390		;y (inferior esquerda)
        PUSH    AX
        MOV		AX,25		;altura
        PUSH    AX
        MOV		AX,85		;largura
        PUSH    AX
        CALL    full_rec
;-----------------------------------------------------------------------------------------
;Bloco 10
MOV     byte [cor],cyan
        MOV		AX,325		;x (inferior esquerda)
        PUSH    AX
        MOV		AX,390		;y (inferior esquerda)
        PUSH    AX
        MOV		AX,25		;altura
        PUSH    AX
        MOV		AX,85		;largura
        PUSH    AX
        CALL    full_rec
;-----------------------------------------------------------------------------------------
;Bloco 11
MOV     byte [cor],azul
        MOV		AX,427		;x (inferior esquerda)
        PUSH    AX
        MOV		AX,390		;y (inferior esquerda)
        PUSH    AX
        MOV		AX,25		;altura
        PUSH    AX
        MOV		AX,85		;largura
        PUSH    AX
        CALL    full_rec
;-----------------------------------------------------------------------------------------
;Bloco 12
MOV     byte [cor],magenta
        MOV		AX,529		;x (inferior esquerda)
        PUSH    AX
        MOV		AX,390		;y (inferior esquerda)
        PUSH    AX
        MOV		AX,25		;altura
        PUSH    AX
        MOV		AX,85		;largura
        PUSH    AX
        CALL    full_rec
;-----------------------------------------------------------------------------------------


;desenha bolinha
		MOV		byte [cor],vermelho			
		MOV		AX,320						;x
		PUSH	AX
		MOV		AX,40						;y
		PUSH	AX
		MOV		AX,14						;r
		PUSH	AX
		CALL	full_circle
		
;-----------------------------------------------------------------------------------------
		
;desenha raquete
        MOV     byte [cor], branco_intenso
		MOV     AX,292       ;x (inferior esquerda)
		PUSH    AX
		MOV     AX,21        ;y (inferior esquerda)
		PUSH    AX
		MOV     AX,5         ;altura
		PUSH    AX
		MOV     AX,56        ;largura
		PUSH    AX
		CALL    full_rec

;-----------------------------------------------------------------------------------------
		


		MOV    	AH,08h
		INT     21h
	    MOV  	AH,0   						; set video mode
	    MOV  	AL,[modo_anterior]   		; modo anterior
	    INT  	10h
		MOV     AX,4c00h
		INT     21h
		


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

modo_anterior	db		0
linha   	    dw  	0
coluna  	    dw  	0
deltax		    dw		0
deltay		    dw		0	
mens    	    db  	'Funcao Grafica SE_I $' 

;*************************************************************************
segment stack stack
		DW 		512
stacktop:
