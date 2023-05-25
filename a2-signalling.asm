; a2-signalling.asm
; University of Victoria
; CSC 230: Spring 2023
; Instructor: Ahmad Abdullah
;
; Student name:
; Student ID:
; Date of completed work:
;
; *******************************
; Code provided for Assignment #2 
;
; Author: Mike Zastre (2022-Oct-15)
;
 
; This skeleton of an assembly-language program is provided to help you
; begin with the programming tasks for A#2. As with A#1, there are "DO
; NOT TOUCH" sections. You are *not* to modify the lines within these
; sections. The only exceptions are for specific changes changes
; announced on Brightspace or in written permission from the course
; instructor. *** Unapproved changes could result in incorrect code
; execution during assignment evaluation, along with an assignment grade
; of zero. ****

.include "m2560def.inc"
.cseg
.org 0

; ***************************************************
; **** BEGINNING OF FIRST "STUDENT CODE" SECTION ****
; ***************************************************

; initializion code will need to appear in this
; section
ldi r16, 0b10101010
sts DDRL, r16
sts PORTL, r16
ldi r16,0b00001010
out DDRB, r16
out PORTB, r16



; ***************************************************
; **** END OF FIRST "STUDENT CODE" SECTION **********
; ***************************************************

; ---------------------------------------------------
; ---- TESTING SECTIONS OF THE CODE -----------------
; ---- TO BE USED AS FUNCTIONS ARE COMPLETED. -------
; ---------------------------------------------------
; ---- YOU CAN SELECT WHICH TEST IS INVOKED ---------
; ---- BY MODIFY THE rjmp INSTRUCTION BELOW. --------
; -----------------------------------------------------

	rjmp test_part_d
	; Test code


test_part_a:
	ldi r16, 0b00100001
	rcall set_leds
	rcall delay_long

	clr r16
	rcall set_leds
	rcall delay_long

	ldi r16, 0b00111000
	rcall set_leds
	rcall delay_short

	clr r16
	rcall set_leds
	rcall delay_long

	ldi r16, 0b00100001
	rcall set_leds
	rcall delay_long

	clr r16
	rcall set_leds

	rjmp end


test_part_b:
	ldi r17, 0b00101010
	rcall slow_leds
	ldi r17, 0b00010101
	rcall slow_leds
	ldi r17, 0b00101010
	rcall slow_leds
	ldi r17, 0b00010101
	rcall slow_leds

	rcall delay_long
	rcall delay_long

	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds
	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds
	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds
	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds

	rjmp end

test_part_c:
	ldi r16, 0b11111000
	push r16
	rcall leds_with_speed
	pop r16

	ldi r16, 0b11011100
	push r16
	rcall leds_with_speed
	pop r16

	ldi r20, 0b00100000
test_part_c_loop:
	push r20
	rcall leds_with_speed
	pop r20
	lsr r20
	brne test_part_c_loop

	rjmp end


test_part_d:
	ldi r21, 'E'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long

	ldi r21, 'A'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long


	ldi r21, 'M'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long

	ldi r21, 'H'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long

	rjmp end


test_part_e:
	ldi r25, HIGH(WORD02 << 1)
	ldi r24, LOW(WORD02 << 1)
	rcall display_message
	rjmp end

end:
    rjmp end






; ****************************************************
; **** BEGINNING OF SECOND "STUDENT CODE" SECTION ****
; ****************************************************

set_leds:

	; Initialization
	clr r20 ;port b
	clr r21 ;port l

	; Check each bit of r16 (the input value) to determine which LEDs to turn on
	sbrc r16, 5
		ori r20, 0b00000010
	sbrc r16, 4
		ori r20, 0b00001000

	out DDRB,r20
	out PORTB,r20

	sbrc r16, 3
		ori r21, 0b00000010
	sbrc r16, 2
		ori r21, 0b00001000
	sbrc r16, 1
		ori r21, 0b00100000
	sbrc r16, 0
		ori r21, 0b10000000

	; Output the LED values to the appropriate ports
    sts DDRL, r21
    sts PORTL, r21

	; Clear registers used in this function
	clr r20
	clr r21
	clr r16

	ret


slow_leds:
	mov r16, r17 ; Copy input value to r16 to use set_leds
	rcall set_leds
	rcall delay_long

	clr r16 ; Clear r16 to turn off all LEDs
    call set_leds ; turn off all LEDs

	ret


fast_leds:
	mov r16, r17 ; Copy input value to r16 to use set_leds
	rcall set_leds
	rcall delay_short

	clr r16 ; Clear r16 to turn off all LEDs
    call set_leds ; turn off all LEDs

	ret


leds_with_speed:

	push ZL 
	push ZH
	push r0

	; Load ZH and ZL with the current stack pointer
	in ZH, SPH
	in ZL, SPL

	ldd r0, Z+7
	mov r17, r0

	; Check the 7th bit of r17 to determine whether to display the LEDs quickly or slowly
	; If the 7th bit is set (i.e., r17 is negative), call slow_leds; otherwise, call fast_leds
	sbrs r17, 7
	rcall fast_leds
	sbrc r17, 7
	rcall slow_leds

	pop r0
	pop ZH
	pop ZL

	clr r17

	ret


; Note -- this function will only ever be tested
; with upper-case letters, but it is a good idea
; to anticipate some errors when programming (i.e. by
; accidentally putting in lower-case letters). Therefore
; the loop does explicitly check if the hyphen/dash occurs,
; in which case it terminates with a code not found
; for any legal letter.

encode_letter:

  clr r25

  ; Load the letter to encode from memory
  push YH
  push YL
  push r2
  in YH, SPH
  in YL, SPL
  ldd r2, Y+7

  ldi ZL, low(PATTERNS<<1)
  ldi ZH, high(PATTERNS<<1)
  
  ;jmp encode_loop
  rcall encode_loop

  pop r2
  pop YL
  pop YH

  ret


  encode_loop:
    ; Find the LED pattern for the letter
    
    lpm r18, Z+
    cp r18, r2
    breq pattern_found
    lpm r18, Z+
    ; If we reach a hyphen/dash, we didn't find a valid pattern
    cpi r18, '-'
    ;breq invalid_pattern
    rjmp encode_loop

  pattern_found:
    ; Extract the delay from the pattern
    lpm r19, Z+
	cpi r19, 1
	breq slow
	cpi r19, 2
	breq fast
	; Extract the on/off from the pattern
	cpi r19, 0x6f
	breq light_on 
	cpi r19 ,0x2e
	breq light_off

    ret

	slow:;"11"
		ori r25 ,0b11000000
		jmp pattern_found

	fast:;"00"
		andi r25 ,0b00111111
		jmp pattern_found

	light_on:;"o"
		lsl r25
		ori r25, 0b00000001
		jmp pattern_found

	light_off:;"."
		lsl r25
		andi r25, 0b11111110
		jmp pattern_found


  invalid_pattern:
    ; If we found an invalid pattern, turn off all LEDs and return
    sts PORTL, r23
    rcall delay_long
    sts PORTL, r25

	ret







;test_part_e:
;	ldi r25, HIGH(WORD02 << 1)
;	ldi r24, LOW(WORD02 << 1)
;	rcall display_message
;	rjmp end

display_message:
  push YH
  push YL
  push r2
  in YH, SPH
  in YL, SPL
  ldd r2, Y+7

  mov ZL, r25
  mov ZH, r24

  display_message_loop:
	lpm r29, Z+
    cpi r29, 0x00 ; check if end of message has been reached
    breq display_message_done
	mov r21, r29

	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

    call delay_short ; delay for a short period of time

    rjmp display_message_loop

display_message_done:
    clr r16
    call set_leds ; turn off all LEDs

	ret


; ****************************************************
; **** END OF SECOND "STUDENT CODE" SECTION **********
; ****************************************************




; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================

; about one second
delay_long:
	push r16

	ldi r16, 14
delay_long_loop:
	rcall delay
	dec r16
	brne delay_long_loop

	pop r16
	ret


; about 0.25 of a second
delay_short:
	push r16

	ldi r16, 4
delay_short_loop:
	rcall delay
	dec r16
	brne delay_short_loop

	pop r16
	ret

; When wanting about a 1/5th of a second delay, all other
; code must call this function
;
delay:
	rcall delay_busywait
	ret


; This function is ONLY called from "delay", and
; never directly from other code. Really this is
; nothing other than a specially-tuned triply-nested
; loop. It provides the delay it does by virtue of
; running on a mega2560 processor.
;
delay_busywait:
	push r16
	push r17
	push r18

	ldi r16, 0x08
delay_busywait_loop1:
	dec r16
	breq delay_busywait_exit

	ldi r17, 0xff
delay_busywait_loop2:
	dec r17
	breq delay_busywait_loop1

	ldi r18, 0xff
delay_busywait_loop3:
	dec r18
	breq delay_busywait_loop2
	rjmp delay_busywait_loop3

delay_busywait_exit:
	pop r18
	pop r17
	pop r16
	ret


; Some tables


PATTERNS:
	; LED pattern shown from left to right: "." means off, "o" means
    ; on, 1 means long/slow, while 2 means short/fast.
	.db "A", "..oo..", 1
	.db "B", ".o..o.", 2
	.db "C", "o.o...", 1
	.db "D", ".....o", 1
	.db "E", "oooooo", 1
	.db "F", ".oooo.", 2
	.db "G", "oo..oo", 2
	.db "H", "..oo..", 2
	.db "I", ".o..o.", 1
	.db "J", ".....o", 2
	.db "K", "....oo", 2
	.db "L", "o.o.o.", 1
	.db "M", "oooooo", 2
	.db "N", "oo....", 1
	.db "O", ".oooo.", 1
	.db "P", "o.oo.o", 1
	.db "Q", "o.oo.o", 2
	.db "R", "oo..oo", 1
	.db "S", "....oo", 1
	.db "T", "..oo..", 1
	.db "U", "o.....", 1
	.db "V", "o.o.o.", 2
	.db "W", "o.o...", 2
	.db "W", "oo....", 2
	.db "Y", "..oo..", 2
	.db "Z", "o.....", 2
	.db "-", "o...oo", 1   ; Just in case!

WORD00: .db "HELLOWORLD", 0, 0
WORD01: .db "THE", 0
WORD02: .db "QUICK", 0
WORD03: .db "BROWN", 0
WORD04: .db "FOX", 0
WORD05: .db "JUMPED", 0, 0
WORD06: .db "OVER", 0, 0
WORD07: .db "THE", 0
WORD08: .db "LAZY", 0, 0
WORD09: .db "DOG", 0

; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================

