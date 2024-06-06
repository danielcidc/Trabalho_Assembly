;-----------------------------------------------------------------------------
;    fun��o full_rec
;	 PUSH xc; PUSH yc; PUSH r; CALL full_circle;  (xc+r<639,yc+r<479)e(xc-r>0,yc-r>0)
; cor definida na variavel cor					  
global full_rec
extern line 

full_rec:
	PUSH 	bp
	MOV	 	bp,sp
	PUSHf                        ;coloca os flags na pilha
	PUSH 	ax
	PUSH 	bx
	PUSH	cx
	PUSH	dx
	PUSH	si
	PUSH	di

	MOV		ax,[bp+10]    ; resgata x
	MOV		bx,[bp+8]    ; resgata y
	MOV		cx,[bp+6]    ; resgata altura
	MOV		dx,[bp+4]    ; resgata largura
	
	MOV		si,ax
	ADD		si,dx
	
	MOV		di,bx
	
	draw_rec:
		PUSH	ax		;x1
		PUSH	di		;y1
		PUSH	si		;x2
		PUSH	di		;y2
		CALL line
	
		INC		di
	loop draw_rec
	
	POP		di
	POP		si
	POP		dx
	POP		cx
	POP		bx
	POP		ax
	POPf
	POP		bp
	ret		6
