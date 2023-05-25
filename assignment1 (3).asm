; Assignment #1 
; Student Name: Xinyi Li
; V Number: V00930447
;
; Problem 1
; Please copy your code for Problem 1 here between START and STOP marks
; and do not modify any other lines
add16:
; START -----------------------------------------------------------------
	or r30, r26
	or r31, r28
	add r30, r28
	adc r31, r29

	sbrc r31, 7
		inc r0
; STOP ------------------------------------------------------------------
	ret
;
;
;
;
;
; Problem 2
; Please copy your code for Problem 2 here between START and STOP marks
; and do not modify any other lines
add_prity:
; START -----------------------------------------------------------------
ldi r25, 0x00 ;initialization
mov r24, r26 ;compare in r24
mov r30, r26 ;copy XL to ZL

;andi r30, 0b01111111
ori r30, 0b10000000

ldi r16, 0x01 ;register helps see if bx of XL is 1:
and r16, r24 
ldi r17, 0x01 
cpse r16, r17
	dec r25
inc r25

ldi r16, 0x02 ;register helps see if bx of XL is 1:
and r16, r24 
ldi r17, 0x02
cpse r16, r17
	dec r25
inc r25

ldi r16, 0x04 ;register helps see if bx of XL is 1:
and r16, r24 
ldi r17, 0x04
cpse r16, r17
	dec r25
inc r25

ldi r16, 0x08 ;register helps see if bx of XL is 1:
and r16, r24 
ldi r17, 0x08
cpse r16, r17
	dec r25
inc r25

ldi r16, 0x10 ;register helps see if bx of XL is 1:
and r16, r24 
ldi r17, 0x10
cpse r16, r17
	dec r25
inc r25

ldi r16, 0x20 ;register helps see if bx of XL is 1:
and r16, r24 
ldi r17, 0x20
cpse r16, r17
	dec r25
inc r25

ldi r16, 0x40 ;register helps see if bx of XL is 1:
and r16, r24 
ldi r17, 0x40
cpse r16, r17
	dec r25
inc r25


ldi r16, 0x01 ;register helps see if bx of XL is 1:
and r16, r25 
ldi r17, 0x01 
cpse r16, r17
	andi r30, 0b01111111
; STOP ------------------------------------------------------------------
	ret
