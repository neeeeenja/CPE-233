;- Programmers: Spencer Chang, Nick Avila
;- Description:
;-
;-----------------------------------------------
;----PORTS----------------
.EQU TCCR 		= 0xB5
.EQU TCCNT2 		= 0xB2
.EQU TCCNT1 		= 0xB1
.EQU TCCNT0 		= 0xB0

.EQU SWITCHES		= 0x20
.EQU LEDS		= 0x40
.EQU SSEG_EN		= 0x82

;-------------------------

;---NUMERIC CONSTANTS-----
; --For Prescale
.EQU PRESCALE_OFF 	= 0x02
.EQU PRESCALE_ON	= 0x82

; --Use to set TCCNT to 2 Hz
; 12,500,000 --> 0xBEBC20
;.EQU TWOHZA			= 0xBE
;.EQU TWOHZB			= 0xBC
;.EQU TWOHZC			= 0x20
;  6,250,000 --> 0x5F5E10
.EQU TWOHZA			= 0x5F
.EQU TWOHZB			= 0x5E
.EQU TWOHZC			= 0x10

; --Use to set TCCNT to 10 Hz
;  2,500,000 --> 0x2625A0
;.EQU TENHZA			= 0x26
;.EQU TENHZB			= 0x25
;.EQU TENHZC			= 0xA0
;  1,250,000 --> 0x1312D0
.EQU TENHZA			= 0x13
.EQU TENHZB			= 0x12
.EQU TENHZC			= 0xD0

.EQU TENHZ			= 0x01
.EQU TWOHZ			= 0x80

.CSEG
.ORG 0x01

;---REGISTER MAP---------------
; r0  => in from switches
; r1  => upper byte of counter
; r2  => middl byte of counter
; r3  => lower byte of counter
; r4  => Holds prescale
; r5  => LED out
;------------------------------
init1:		MOV		r0, 0xFF
		MOV		r5, 0x00
		OUT		r0, SSEG_EN

main:		SEI
		MOV		r0, 0x00
		CALL 	switch_dec
		OUT		r5, LEDS
brnch:		BRN		main

switch_dec:	IN 		r0, SWITCHES		; Take input from switches

;----------- Input 2Hz Values -----------------------
two_check: 	CMP 	r0, TWOHZ			; If the left-most switch is low
		BRNE	ten_check			; Branch to check the tens place
		MOV		r1, TWOHZA			; Output the new clock count to the 
		MOV		r2, TWOHZB			;   timer-counter
		MOV		r3, TWOHZC
		BRN		prescale			; Go to the prescale 

;----------- Input 10Hz Values ----------------------
ten_check:	CMP		r0, TENHZ			; If the right-most switch is low
		BRNE	def_action			; Clear LED's and prescale
		MOV		r1, TENHZA			; Else, move in values to the timer-counter
		MOV		r2, TENHZB
		MOV		r3, TENHZC

;----- Output the Prescale and Count Values ---------
prescale:	MOV		r4, PRESCALE_ON		; Prescale moved to r4
		OUT		r1, TCCNT2			; Output the most significant bits
		OUT		r2, TCCNT1			; "  " middle significant bits
		OUT		r3, TCCNT0			; "  " least significant bits
		OUT		r4, TCCR			; "  " timer-counter enable and prescale
		RET

def_action:	MOV		r4, PRESCALE_OFF
		MOV		r1, 0x00
		MOV		r5, 0x00
		RET
;----------- Interrupt Service Routine ----------
ISR:		EXOR	r5, 0x01

isr_exit:	RETIE
;------------------------------------------------
.ORG 0x3FF
			BRN ISR
;------------------------------------------------
