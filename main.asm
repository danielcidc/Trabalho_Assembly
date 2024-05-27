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