;- Programmers: Spencer Chang, Nick Avila
;- EXPERIMENT 11: TIMER-COUNTER MODULE
;-
;- Description: This RATASM program blinks the left
;-    most LED at a given frequency depending on 
;-    if the left-most switch or the right-most 
;-    switch is high.
;-    If SW(7) = 1, Blink at a 2Hz rate.
;-    If SW(0) = 1, Blink at a 10Hz rate.
;-    In any other switch input, the LEDs should
;-    be off.
;-----------------------------------------------
;-------------- PORTS --------------------------
.EQU TCCR 			= 0xB5
.EQU TCCNT2 		= 0xB2
.EQU TCCNT1 		= 0xB1
.EQU TCCNT0 		= 0xB0

.EQU SWITCHES		= 0x20
.EQU LEDS			= 0x40
.EQU SSEG_EN		= 0x82

;-- NUMERIC CONSTANTS --------------------------
;-- For Prescale ---------
.EQU PRESCALE_OFF 	= 0x00
.EQU PRESCALE_ON	= 0x82

;-- Use to set TCCNT to 2 Hz
;  6,250,000 --> 0x5F5E10
.EQU TWOHZA			= 0x5F
.EQU TWOHZB			= 0x5E
.EQU TWOHZC			= 0x10

;-- Use to set TCCNT to 10 Hz
;  1,250,000 --> 0x1312D0
.EQU TENHZA			= 0x13
.EQU TENHZB			= 0x12
.EQU TENHZC			= 0xD0

.EQU TENHZ			= 0x01
.EQU TWOHZ			= 0x80

;------------------ Assembler Directives ------------------
.CSEG
.ORG 0x01
;---REGISTER MAP-------------------------------------------
; r0  => in from switches
; r1  => upper byte of counter
; r2  => middl byte of counter
; r3  => lower byte of counter
; r4  => Holds prescale
; r5  => LED out
;----------------------------------------------------------
init1:		MOV		r0, 0xFF			; Clear the segement display
			MOV		r5, 0x00			; Clear register for LEDS
			OUT		r5, TCCR			; Initialize timer-counter to off
			OUT		r0, SSEG_EN			; Clear Seven-Segment display
			SEI
			
main:		CALL 	switch_dec			; Decode Switch input
			CMP 	r0, 0x00			; See if the switch input is 0x00
			BRNE	brnch				; If not, just toggle the LED in r5
			MOV		r5, 0x00

brnch:		OUT		r5, LEDS			; Output to LEDs
			BRN		main				; Continue looping

;----------------- Switch Decoder Subroutine --------------------
;-
;- Description: This subroutine takes in the value of the switches
;-    from input and uses a "case" statement to choose what clock
;-    count to send to the timer-counter hooked up to the RAT MCU.
;-
;----------------------------------------------------------------
switch_dec:	IN 		r0, SWITCHES		; Take input from switches

;----------- Input 2Hz Values -----------------------------
two_check: 	CMP 	r0, TWOHZ			; If the left-most switch is low
			BRNE	ten_check			; Branch to check the tens place
			MOV		r1, TWOHZA			; Output the new clock count to the 
			MOV		r2, TWOHZB			;   timer-counter
			MOV		r3, TWOHZC
			BRN		prescale			; Go to the prescale 

;----------- Input 10Hz Values -----------------------------
ten_check:	CMP		r0, TENHZ			; If the right-most switch is low
			BRNE	nop_action			; Clear LED's and prescale
			MOV		r1, TENHZA			; Else, move in values to the timer-counter
			MOV		r2, TENHZB
			MOV		r3, TENHZC

;----- Output the Prescale and Count Values ----------------
prescale:	MOV		r4, PRESCALE_ON		; Prescale moved to r4
			OUT		r1, TCCNT2			; Output the most significant bits to TC
			OUT		r2, TCCNT1			; "  " middle significant bits to TC
			OUT		r3, TCCNT0			; "  " least significant bits to TC
			OUT		r4, TCCR			; "  " timer-counter enable and prescale to TC
			RET

;----- If neither 2Hz or 10Hz input, No Op ------------------
nop_action:	MOV		r4, PRESCALE_OFF
			MOV		r5, 0x00
			OUT		r4, TCCR
			RET

;----------- Interrupt Service Routine -----------------------
;- Description: This ISR just toggles the LSB in r5,
;-      which outputs to the LEDs in the main loop above.
;-------------------------------------------------------------
ISR:		EXOR	r5, 0x01
			RETIE
;-------------------------------------------------------------
.ORG 0x3FF
			BRN ISR
;-------------------------------------------------------------

;-------------- Post-Lab Notes -------------------------------
;- It turns out that we didn't need the prescale of 2 since
;-    a clock cycle runs at a rate of 25MHz (1 Cycle = 2 RET).
;- In the main loop, the "CMP r0, 0x00" was used to catch a
;-    switch input that seemed to evade the logic given in the
;-    switch_dec subroutine. This was a simple yet (seemingly)
;-    unnecessary fix.
;--------------------------------------------------------------
