;
; a3part-C.asm
;
; Part C of assignment #3
;
;
; Student name:
; Student ID:
; Date of completed work:
;
; **********************************
; Code provided for Assignment #3
;
; Author: Mike Zastre (2022-Nov-05)
;
; This skeleton of an assembly-language program is provided to help you 
; begin with the programming tasks for A#3. As with A#2 and A#1, there are
; "DO NOT TOUCH" sections. You are *not* to modify the lines within these
; sections. The only exceptions are for specific changes announced on
; Brightspace or in written permission from the course instruction.
; *** Unapproved changes could result in incorrect code execution
; during assignment evaluation, along with an assignment grade of zero. ***
;


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================
;
; In this "DO NOT TOUCH" section are:
; 
; (1) assembler direction setting up the interrupt-vector table
;
; (2) "includes" for the LCD display
;
; (3) some definitions of constants that may be used later in
;     the program
;
; (4) code for initial setup of the Analog-to-Digital Converter
;     (in the same manner in which it was set up for Lab #4)
;
; (5) Code for setting up three timers (timers 1, 3, and 4).
;
; After all this initial code, your own solutions's code may start
;

.cseg
.org 0
	jmp reset

; Actual .org details for this an other interrupt vectors can be
; obtained from main ATmega2560 data sheet
;
.org 0x22
	jmp timer1

; This included for completeness. Because timer3 is used to
; drive updates of the LCD display, and because LCD routines
; *cannot* be called from within an interrupt handler, we
; will need to use a polling loop for timer3.
;
; .org 0x40
;	jmp timer3

.org 0x54
	jmp timer4

.include "m2560def.inc"
.include "lcd.asm"

.cseg
#define CLOCK 16.0e6
#define DELAY1 0.01
#define DELAY3 0.1
#define DELAY4 0.5

#define BUTTON_RIGHT_MASK 0b00000001	
#define BUTTON_UP_MASK    0b00000010
#define BUTTON_DOWN_MASK  0b00000100
#define BUTTON_LEFT_MASK  0b00001000

#define BUTTON_RIGHT_ADC  0x032
#define BUTTON_UP_ADC     0x0b0   ; was 0x0c3
#define BUTTON_DOWN_ADC   0x160   ; was 0x17c
#define BUTTON_LEFT_ADC   0x22b
#define BUTTON_SELECT_ADC 0x316

.equ PRESCALE_DIV=1024   ; w.r.t. clock, CS[2:0] = 0b101

; TIMER1 is a 16-bit timer. If the Output Compare value is
; larger than what can be stored in 16 bits, then either
; the PRESCALE needs to be larger, or the DELAY has to be
; shorter, or both.
.equ TOP1=int(0.5+(CLOCK/PRESCALE_DIV*DELAY1))
.if TOP1>65535
.error "TOP1 is out of range"
.endif

; TIMER3 is a 16-bit timer. If the Output Compare value is
; larger than what can be stored in 16 bits, then either
; the PRESCALE needs to be larger, or the DELAY has to be
; shorter, or both.
.equ TOP3=int(0.5+(CLOCK/PRESCALE_DIV*DELAY3))
.if TOP3>65535
.error "TOP3 is out of range"
.endif

; TIMER4 is a 16-bit timer. If the Output Compare value is
; larger than what can be stored in 16 bits, then either
; the PRESCALE needs to be larger, or the DELAY has to be
; shorter, or both.
.equ TOP4=int(0.5+(CLOCK/PRESCALE_DIV*DELAY4))
.if TOP4>65535
.error "TOP4 is out of range"
.endif

reset:
; ***************************************************
; **** BEGINNING OF FIRST "STUDENT CODE" SECTION ****
; ***************************************************

; Anything that needs initialization before interrupts
; start must be placed here.
	rcall lcd_init

	clr r18

	ldi r16, 1
	ldi r17, 15
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, '-'
	push r19
	rcall lcd_putchar
	pop r19

; ***************************************************
; ******* END OF FIRST "STUDENT CODE" SECTION *******
; ***************************************************

; =============================================
; ====  START OF "DO NOT TOUCH" SECTION    ====
; =============================================

	; initialize the ADC converter (which is needed
	; to read buttons on shield). Note that we'll
	; use the interrupt handler for timer 1 to
	; read the buttons (i.e., every 10 ms)
	;
	ldi temp, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
	sts ADCSRA, temp
	ldi temp, (1 << REFS0)
	sts ADMUX, r16

	; Timer 1 is for sampling the buttons at 10 ms intervals.
	; We will use an interrupt handler for this timer.
	ldi r17, high(TOP1)
	ldi r16, low(TOP1)
	sts OCR1AH, r17
	sts OCR1AL, r16
	clr r16
	sts TCCR1A, r16
	ldi r16, (1 << WGM12) | (1 << CS12) | (1 << CS10)
	sts TCCR1B, r16
	ldi r16, (1 << OCIE1A)
	sts TIMSK1, r16

	; Timer 3 is for updating the LCD display. We are
	; *not* able to call LCD routines from within an 
	; interrupt handler, so this timer must be used
	; in a polling loop.
	ldi r17, high(TOP3)
	ldi r16, low(TOP3)
	sts OCR3AH, r17
	sts OCR3AL, r16
	clr r16
	sts TCCR3A, r16
	ldi r16, (1 << WGM32) | (1 << CS32) | (1 << CS30)
	sts TCCR3B, r16
	; Notice that the code for enabling the Timer 3
	; interrupt is missing at this point.

	; Timer 4 is for updating the contents to be displayed
	; on the top line of the LCD.
	ldi r17, high(TOP4)
	ldi r16, low(TOP4)
	sts OCR4AH, r17
	sts OCR4AL, r16
	clr r16
	sts TCCR4A, r16
	ldi r16, (1 << WGM42) | (1 << CS42) | (1 << CS40)
	sts TCCR4B, r16
	ldi r16, (1 << OCIE4A)
	sts TIMSK4, r16

	sei

; =============================================
; ====    END OF "DO NOT TOUCH" SECTION    ====
; =============================================

; ****************************************************
; **** BEGINNING OF SECOND "STUDENT CODE" SECTION ****
; ****************************************************

.def temp=r17
	; initialize the stack pointer (SP) to the end of RAM
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	; initialize built-in Analog to Digital Converter
	; initialize the Analog to Digital converter
	ldi r16, 0x87
	sts ADCSRA, r16
	ldi r16, 0x40
	sts ADMUX, r16

	clr r24
main_loop:
	call delay

	ldi r16, 1
	ldi r17, 15
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, '-'
	push r19
	rcall lcd_putchar
	pop r19
	
	call check_button   ; check to see if a button is pressed 

	cpi r24, 1          ; register R24 is set to 1 if "right" is pressed
	breq rightLED

	cpi r24, 2          ; register R24 is set to 1 if "right" is pressed
	breq upLED

	cpi r24, 3          ; register R24 is set to 1 if "right" is pressed
	breq downLED

	cpi r24, 4          ; register R24 is set to 1 if "right" is pressed
	breq leftLED
	;rjmp stringDisplay

rjmp main_loop  
rightLED:

	jmp right_lcd_display
	rightLEDaftDisp:

	ldi r16, 1
	ldi r17, 15
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, '*'
	push r19
	rcall lcd_putchar
	pop r19
	rjmp stringDisplay
	rjmp main_loop

upLED:

	jmp up_lcd_display
	upLEDaftDisp:

	ldi r16, 1
	ldi r17, 15
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, '*'
	push r19
	rcall lcd_putchar
	pop r19

	ldi r16, 1
	add r18, r16
	rjmp stringDisplay
	rjmp main_loop

downLED:

	jmp down_lcd_display
	downLEDaftDisp:                                                                                                                                                                                                                                                                                                    

	ldi r16, 1
	ldi r17, 15
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, '*'
	push r19
	rcall lcd_putchar
	pop r19

	ldi r16, 1
	sub r18, r16
	rjmp stringDisplay
	rjmp main_loop

leftLED:

	jmp left_lcd_display
	leftLEDaftDisp:

	ldi r16, 1
	ldi r17, 15
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, '*'
	push r19
	rcall lcd_putchar
	pop r19
	rjmp stringDisplay
	rjmp main_loop

right_lcd_display:
	ldi r16, 1
	ldi r17, 0
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, ' '
	push r19
	rcall lcd_putchar
	pop r19

	ldi r16, 1
	ldi r17, 1
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, ' '
	push r19
	rcall lcd_putchar
	pop r19

	ldi r16, 1
	ldi r17, 2
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, ' '
	push r19
	rcall lcd_putchar
	pop r19

	ldi r16, 1
	ldi r17, 3
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, 'R'
	push r19
	rcall lcd_putchar
	pop r19

	ldi r16, 1
	ldi r17, 15
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16
	rjmp rightLEDaftDisp

up_lcd_display:
	ldi r16, 1
	ldi r17, 0
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, ' '
	push r19
	rcall lcd_putchar
	pop r19

	ldi r16, 1
	ldi r17, 1
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, ' '
	push r19
	rcall lcd_putchar
	pop r19

	ldi r16, 1
	ldi r17, 2
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, 'U'
	push r19
	rcall lcd_putchar
	pop r19

	ldi r16, 1
	ldi r17, 3
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, ' '
	push r19
	rcall lcd_putchar
	pop r19

	ldi r16, 1
	ldi r17, 15
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16
	rjmp upLEDaftDisp

down_lcd_display:
	ldi r16, 1
	ldi r17, 0
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, ' '
	push r19
	rcall lcd_putchar
	pop r19

	ldi r16, 1
	ldi r17, 1
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, 'D'
	push r19
	rcall lcd_putchar
	pop r19

	ldi r16, 1
	ldi r17, 2
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, ' '
	push r19
	rcall lcd_putchar
	pop r19

	ldi r16, 1
	ldi r17, 3
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, ' '
	push r19
	rcall lcd_putchar
	pop r19

	ldi r16, 1
	ldi r17, 15
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	rjmp downLEDaftDisp

left_lcd_display:
	ldi r16, 1
	ldi r17, 0
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, 'L'
	push r19
	rcall lcd_putchar
	pop r19

	ldi r16, 1
	ldi r17, 1
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, ' '
	push r19
	rcall lcd_putchar
	pop r19

	ldi r16, 1
	ldi r17, 2
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, ' '
	push r19
	rcall lcd_putchar
	pop r19

	ldi r16, 1
	ldi r17, 3
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r19, ' '
	push r19
	rcall lcd_putchar
	pop r19

	ldi r16, 1
	ldi r17, 15
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16
	rjmp leftLEDaftDisp                                    


stringDisplay:
	ldi r16, 0
	ldi r17, 0
	push r16 ;row
	push r17 ;column
	rcall lcd_gotoxy
	pop r17
	pop r16

	cpi r18, 1
	breq put_1
	cpi r18, 2
	breq put_2
	cpi r18, 3
	breq put_3
	cpi r18, 4
	breq put_4
	cpi r18, 5
	breq put_5
	cpi r18, 6
	breq put_6
	cpi r18, 7
	breq put_7
	cpi r18, 8
	breq put_8
	cpi r18, 9
	breq put_9
	cpi r18, 10
	breq put_a
	cpi r18, 11
	breq put_b
	cpi r18, 12
	breq put_c
	cpi r18, 13
	breq put_d
	cpi r18, 14
	breq put_e
	cpi r18, 15
	breq put_f
	rjmp main_loop
put_1:
	ldi r19, '1'
	rjmp print_letter
put_2:
	ldi r19, '2'
	rjmp print_letter
put_3:
	ldi r19, '3'
	rjmp print_letter
put_4:
	ldi r19, '4'
	rjmp print_letter
put_5:
	ldi r19, '5'
	rjmp print_letter
put_6:
	ldi r19, '6'
	rjmp print_letter
put_7:
	ldi r19, '7'
	rjmp print_letter
put_8:
	ldi r19, '8'
	rjmp print_letter
put_9:
	ldi r19, '9'
	rjmp print_letter
put_a:
	ldi r19, 'a'
	rjmp print_letter
put_b:
	ldi r19, 'b'
	rjmp print_letter
put_c:
	ldi r19, 'c'
	rjmp print_letter
put_d:
	ldi r19, 'd'
	rjmp print_letter
put_e:
	ldi r19, 'e'
	rjmp print_letter
put_f:
	ldi r19, 'f'
	rjmp print_letter

print_letter:
	push r19
	rcall lcd_putchar
	pop r19
	rjmp main_loop
	
;
; delay function
;
delay:
	push r20
	push r21
	push r22
	; Nested delay loop
	ldi r20, 0x10
x1:
		ldi r21, 0xFF
x2:
			ldi r22, 0xFF
x3:
				dec r22
				brne x3
			dec r21
			brne x2
		dec r20
		brne x1
	pop r22
	pop r21
	pop r20
	ret

.equ RIGHT	= 0x032
.equ UP     = 0x0b0

.equ DOWN   = 0x160

.equ LEFT   = 0x22B
.equ SELECT = 0x316

;#define BUTTON_RIGHT_ADC  0x032
;#define BUTTON_UP_ADC     0x0b0   ; was 0x0c3
;#define BUTTON_DOWN_ADC   0x160   ; was 0x17c
;#define BUTTON_LEFT_ADC   0x22b
;#define BUTTON_SELECT_ADC 0x316




check_button:
	lds r16, ADCSRA
	ori r16, 0x40
	sts ADCSRA, r16

wait:
	lds r16, ADCSRA
	andi r16, 0x40     
	brne wait          

	lds r16, ADCL
	lds r17, ADCH
	

	clr r24
	cpi r17,0
	brne DLS
	rjmp upAndRight
	skip:	
		ret	

DLS:;down left and select
	
	ldi r19,low(DOWN)
	ldi r20,high(DOWN)
	cp r16,r19
	cpc r17,r20
	brlo btnDOWN

	ldi r19,low(LEFT)
	ldi r20,high(LEFT)
	cp r16,r19
	cpc r17,r20
	brlo btnLEFT

	ldi r19,low(SELECT)
	ldi r20,high(SELECT)
	cp r16,r19
	cpc r17,r20
	brlo btnSELECT

	rjmp skip

upAndRight:
	ldi r24,1;right
	cpi r16,low(RIGHT)
	brlo skip
	ldi r24,2;up
	rjmp skip

btnDOWN:
	ldi r24,3;down
	rjmp skip
btnLeft:
	ldi r24,4;left
	rjmp skip
btnSELECT:
	ldi r24,5;select
	rjmp skip

start:
	;rcall timer1
stop:
	rjmp stop


timer1:
	reti

; timer3:
;
; Note: There is no "timer3" interrupt handler as you must use
; timer3 in a polling style (i.e. it is used to drive the refreshing
; of the LCD display, but LCD functions cannot be called/used from
; within an interrupt handler).


timer4:
	reti


; ****************************************************
; ******* END OF SECOND "STUDENT CODE" SECTION *******
; ****************************************************


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================

; r17:r16 -- word 1
; r19:r18 -- word 2
; word 1 < word 2? return -1 in r25
; word 1 > word 2? return 1 in r25
; word 1 == word 2? return 0 in r25
;
compare_words:
	; if high bytes are different, look at lower bytes
	cp r17, r19
	breq compare_words_lower_byte

	; since high bytes are different, use these to
	; determine result
	;
	; if C is set from previous cp, it means r17 < r19
	; 
	; preload r25 with 1 with the assume r17 > r19
	ldi r25, 1
	brcs compare_words_is_less_than
	rjmp compare_words_exit

compare_words_is_less_than:
	ldi r25, -1
	rjmp compare_words_exit

compare_words_lower_byte:
	clr r25
	cp r16, r18
	breq compare_words_exit

	ldi r25, 1
	brcs compare_words_is_less_than  ; re-use what we already wrote...

compare_words_exit:
	ret

.cseg
AVAILABLE_CHARSET: .db "0123456789abcdef_", 0


.dseg

BUTTON_IS_PRESSED: .byte 1			; updated by timer1 interrupt, used by LCD update loop
LAST_BUTTON_PRESSED: .byte 1        ; updated by timer1 interrupt, used by LCD update loop

TOP_LINE_CONTENT: .byte 16			; updated by timer4 interrupt, used by LCD update loop
CURRENT_CHARSET_INDEX: .byte 16		; updated by timer4 interrupt, used by LCD update loop
CURRENT_CHAR_INDEX: .byte 1			; ; updated by timer4 interrupt, used by LCD update loop


; =============================================
; ======= END OF "DO NOT TOUCH" SECTION =======
; =============================================


; ***************************************************
; **** BEGINNING OF THIRD "STUDENT CODE" SECTION ****
; ***************************************************

.dseg

; If you should need additional memory for storage of state,
; then place it within the section. However, the items here
; must not be simply a way to replace or ignore the memory
; locations provided up above.


; ***************************************************
; ******* END OF THIRD "STUDENT CODE" SECTION *******
; ***************************************************
