;*-------------------------------------------------------------------
;* Name:    	lab_4_program.s 
;* Purpose: 	A sample style for lab-4
;* Term:		Winter 2013
;*-------------------------------------------------------------------
				THUMB 								; Declare THUMB instruction set 
				AREA 	My_code, CODE, READONLY 	; 
				EXPORT 		__MAIN 					; Label __MAIN is used externally 
                                EXPORT          EINT3_IRQHandler
				ENTRY 

__MAIN

; The following lines are similar to previous labs.
; They just turn off all LEDs 
				LDR			R10, =LED_BASE_ADR	; R10 is a  pointer to the base address for the LEDs
				MOV 		R3, #0xB0000000		  
				STR 		R3, [r10, #0x20]	; Turn off three LEDs on port 1
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x40] 	; Turn off five LEDs on port 2 
								
				LDR			R3, =ISER0			; Enable the EINT3 channel
				MOV32		R4, #0x00200000		; Set the 19th bit 
				STR			R4, [R3]
				
				LDR			R3, =IO2IntEnf		; Enable port for the falling edge of the button
				MOV			R4, #0x0400			; Set the 10th bit
				STR			R4, [R3]
				
				

; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				MOV			R11, #0xABCD		; Init the random number generator with a non-zero number
LOOP 			
				BL 			RNG 
				
				; flickers the lights with a delay of 100ms
				
				MOV 		R3, #0xB0000000		  
				STR 		R3, [R10, #0x3C]	; Turn off three LEDs on port 1
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x5C] 	; Turn off five LEDs on port 2 
				
				MOV			R0, #1				; Call delay for 100ms
				BL			DELAY
				
				MOV 		R3, #0xB0000000		 
				STR 		R3, [R10, #0x38]	; Turn on three LEDs on port 1 
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x58] 	; Turn on five LEDs on port 2 
				
				MOV			R0, #1
				BL 			DELAY
				
				B 			LOOP
				
				
;*------------------------------------------------------------------- 
; Subroutine RNG ... Generates a pseudo-Random Number in R11 
;*------------------------------------------------------------------- 
; R11 holds a random number as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program
; R11 can be read anywhere in the code but must only be written to by this subroutine
RNG 			STMFD		R13!,{R1-R3, R14} 	; Random Number Generator 
				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1			; The new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				LDMFD		R13!, {R1-R3, R15}

;*------------------------------------------------------------------- 
; Subroutine DELAY ... Causes a delay of 100ms * R0 times
;*------------------------------------------------------------------- 
; 		aim for better than 10% accuracy
DELAY			STMFD		R13!,{R2, R14}
		;
		; code to generate a delay of 0.1mS * R0 times
		;
		
MultipleDelay		TEQ		R0, #0				; test R0 to see if it's 0 - set Zero flag so you can use BEQ, BNE
					BEQ		exitDelay			; need to modify for 100ms
					MOV32 	R2, #0x00020788		; introduce delay element, 0x00020788 corresponds with 100ms
delayLoop		
					SUBS 	R2, #1
					BNE 	delayLoop
					SUBS 	R0, R0, #1 			; big # subtraction
					BNE		MultipleDelay 
					
exitDelay		LDMFD		R13!,{R2, R15}

; The Interrupt Service Routine MUST be in the startup file for simulation 
;   to work correctly.  Add it where there is the label "EINT3_IRQHandler
;
;*------------------------------------------------------------------- 
; Interrupt Service Routine (ISR) for EINT3_IRQHandler 
;*------------------------------------------------------------------- 
; This ISR handles the interrupt triggered when the INT0 push-button is pressed 
; with the assumption that the interrupt activation is done in the main program
EINT3_IRQHandler 	
				STMFD		R13!,{R2, R14} 				; Use this command if you need it  
		;
		; Code that handles the interrupt 
		;
				AND			R6, R11, #0xFF				; keep only the first 16 bits
				
DISPLAYLOOP
				;turn off all the LEDS
				MOV 		R3, #0xB0000000		
				STR 		R3, [R10, #0x3C]	; turn off three LEDs on port 1  
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x5C] 	; turn off five LEDs on port 2 
								
				MOV 		R3, #0				; clears R3 (where we will store bits)
				BFI			R3, R6, #25, #5		; insert the first 5 bits of R7 into position 25 - 29 in R3
				RBIT		R3, R3				; reverse R3 such that MSB become LSB -> position 2 - 6
				BFC			R3, #0, #2			
				BFC			R3, #7, #25			; clear all other bits in 32 bit range
				STR 		R3, [R10, #0x58] 	; turn on the LEDS on port 2
				
				MOV			R3, #0				; clear r3
				
				BFI			R3, R6, #1, #8 		; insert 8 bits -> position 1 - 8
				BFI			R3, R6, #0, #6		; insert 6 bits -> position 0 - 5
				LSR			R3, #5				; shift right to get only 4 bits
				RBIT		R3, R3				; reverse R3 such that LSB become MSB -> position 28 - 31
				BFC			R3, #30, #1			
				BFC			R3, #0, #28			; ckear all other bits in 32 bit range
				STR 		R3, [R10, #0x38] 	; turn on the LEDS on port 1

				MOV			R0, #10 ; run for 1 seonds
				BL			DELAY
				
				SUBS		R6,#10
				BEQ			FINAL
				BMI			FINAL
							
				B 			DISPLAYLOOP
FINAL
				LDR			R3, =IO2IntClr				; clears interrupts when dealing with it
				MOV			R4,#0x0400
				STR			R4,[R3]
				
				LDMFD		R13!,{R2, R15} 				; Use this command if you used STMFD (otherwise use BX LR) 


;*-------------------------------------------------------------------
; Below is a list of useful registers with their respective memory addresses.
;*------------------------------------------------------------------- 
LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002C00C 		; Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002C010 		; Pin Select Register 4 for P2[15:0]
FIO1DIR			EQU		0x2009C020 		; Fast Input Output Direction Register for Port 1 
FIO2DIR			EQU		0x2009C040 		; Fast Input Output Direction Register for Port 2 
FIO1SET			EQU		0x2009C038 		; Fast Input Output Set Register for Port 1 
FIO2SET			EQU		0x2009C058 		; Fast Input Output Set Register for Port 2 
FIO1CLR			EQU		0x2009C03C 		; Fast Input Output Clear Register for Port 1 
FIO2CLR			EQU		0x2009C05C 		; Fast Input Output Clear Register for Port 2 
IO2IntEnf		EQU		0x400280B4		; GPIO Interrupt Enable for port 2 Falling Edge 
IO2IntClr		EQU		0x400280AC
ISER0			EQU		0xE000E100		; Interrupt Set-Enable Register 0 

				ALIGN 

				END 
