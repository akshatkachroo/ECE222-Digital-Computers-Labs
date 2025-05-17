; ECE-222 Lab ... Winter 2013 term 
; Lab 3 sample code 
				THUMB 		; Thumb instruction set 
                AREA 		My_code, CODE, READONLY
                EXPORT 		__MAIN
				ENTRY  
__MAIN

; The following lines are similar to Lab-1 but use a defined address to make it easier.
; They just turn off all LEDs 
				LDR			R10, =LED_BASE_ADR		; R10 is a permenant pointer to the base address for the LEDs, offset of 0x20 and 0x40 for the ports

				
				; FIO1CLR - 0x2009 C03C
				; FIO2CLR - 0x2009 C05C
				
				; FIO1SET - 0x2009 C038
				; FIO2SET - 0x2009 C058

; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!

				MOV			R11, #0xABCD		; Init the random number generator with a non-zero number
				
loop 			
				; this is the main loop
				MOV 		R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 		R3, [R10, #0x20]
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x40] 	; Turn off five LEDs on port 2
				
				BL 			RandomNum 
				MOV			R0, R11
				BFC 		R0, #16, #16
				
				; given that the number we are receiving is between 1 and 65535, to achieve range of 20,000 to 100,000
				; offset by 20,000 and then find the ratio of 65545 to 100,000 - 20,000 = 80,000
				; the ratio is approximately 16 / 13
				
				MOV 		R3, #16
				MUL 		R0, R0, R3
				MOV 		R3, #13
				UDIV 		R0, R0, R3
				MOV			R1,	#0x4e20
				ADD			R0, R1
				
				BL 			DELAY 				; branch to delay for random time of 2 to 10 seconds
				
				MOV			R3, #0x20000000		; initialize bit 29 for setting
				STR			R3, [R10, #0x38]	; turn the LED on

				MOV			R9, #0				; holds the number of iterations of 100us before user presses the button
				LDR 		R6, =FIO2PIN		; use FIO2PIN since we are at p2.10 for pin 2

POLL
				LDR			R7, [R6]			; load value of input pin
				AND			R7, #0X0400			
				CMP			R7, #0				; AND the 10th bit to see if there was a value
				BEQ			DISPLAY				; branch to DISPLAY_NUM if it is set
				
				ADD			R9, #1				; ADD 1 to the number of iterations
				MOV			R0, #1				
				BL 			DELAY				; run the delay for 100us
				B			POLL
				
DISPLAY	
				MOV 		R5, R9
				MOV			R8, #4

DISPLAY_LOOP
				BL 			DISPLAY_NUM
				LSR			R5, #8
				SUBS		R8, #1
				BNE			DISPLAY_LOOP
				
				MOV 		R0, #0x4e20;
				BL 			DELAY
				B 			DISPLAY
				
;
; Display the number in R3 onto the 8 LEDs
; Usefull commaands:  RBIT (reverse bits), BFC (bit field clear), LSR & LSL to shift bits left and right, ORR & AND and EOR for bitwise operations

DISPLAY_NUM		STMFD		R13!,{R1, R2, R14} 

				;turn off all the LEDS
				MOV 		R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 		R3, [R10, #0x3C]
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x5C] 	; Turn off five LEDs on port 2 
				
				MOV 		R3, #0				; clears R3 (where we will store bits)
				BFI			R3, R5, #25, #5		; insert the first 5 bits of R7 into position 25 - 29 in R3
				RBIT		R3, R3				; reverse R3 such that MSB become LSB -> position 2 - 6
				BFC			R3, #0, #2			
				BFC			R3, #7, #25			; clear all other bits in 32 bit range
				
				STR 		R3, [R10, #0x58] 	; turn on the LEDS on port 2
				
				BFI			R3, R5, #1, #8 		; insert 8 bits -> position 1 - 8
				BFI			R3, R5, #0, #6		; insert 6 bits -> position 0 - 5
				LSR			R3, #5				; shift right to get only 4 bits
				RBIT		R3, R3				; reverse R3 such that LSB become MSB -> position 28 - 31
				BFC			R3, #30, #1			
				BFC			R3, #0, #28			; ckear all other bits in 32 bit range
				STR 		R3, [R10, #0x38] 	; turn on the LEDS on port 1
				
				MOV			R0, #0xC350			; 50000 in hex, because we need to run the delay for 5 seconds
				BL			DELAY

				LDMFD		R13!,{R1, R2, R15}
				BX 			LR

;
; R11 holds a 16-bit random number via a pseudo-random sequence as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 holds a non-zero 16-bit number.  If a zero is fed in the pseudo-random sequence will stay stuck at 0
; Take as many bits of R11 as you need.  If you take the lowest 4 bits then you get a number between 1 and 15.
;   If you take bits 5..1 you'll get a number between 0 and 15 (assuming you right shift by 1 bit).
;
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program OR ELSE!
; R11 can be read anywhere in the code but must only be written to by this subroutine
RandomNum		STMFD		R13!,{R1, R2, R3, R14}

				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1		; the new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				
				LDMFD		R13!,{R1, R2, R3, R15}

;
;		Delay 0.1ms (100us) * R0 times
; 		aim for better than 10% accuracy
;               The formula to determine the number of loop cycles is equal to Clock speed x Delay time / (#clock cycles)
;               where clock speed = 4MHz and if you use the BNE or other conditional branch command, the #clock cycles =
;               2 if you take the branch, and 1 if you don't.

DELAY			STMFD		R13!,{R2, R14}
		
				; code to generate a delay of 0.1mS * R0 times
		
MultipleDelay	TEQ		R0, #0			; setting the zero flag to test R0 to see if it's 0 
				BEQ		exitDelay		
				MOV 	R2,#0x85		; variable for 100 micro seconds; introduce delay element 
delayloop		
				SUBS 	R2,#1 
				BNE 	delayloop
				SUBS 	R0, R0, #1 		; reduce number of loop iterations
				BNE		MultipleDelay 
					
exitDelay		LDMFD		R13!,{R2, R15}
				

LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002c00c 		; Address of Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002c010 		; Address of Pin Select Register 4 for P2[15:0]
FIO2PIN			EQU		0x2009c054		; address of pin 2.10 

;	Usefull GPIO Registers
;	FIODIR  - register to set individual pins as input or output
;	FIOPIN  - register to read and write pins
;	FIOSET  - register to set I/O pins to 1 by writing a 1
;	FIOCLR  - register to clr I/O pins to 0 by writing a 1


; 	1) max time for 8-bit: 255 * 100ms 16-bit: 65535 * 100ms 24-bit: 16777215 * 100ms 32-bit: 4.2949673 * 10^{9} * 100ms
;	2) Given that me and my partners reaction time on human benchmark was 255 ms, we believe that 16-bit is the best size as it allows variance
;	3) Given that the number we are receiving is between 1 and 65535 for 16 bits, to achieve range of 20,000 to 100,000 we 
;	   find the ratio of 65545 to 100,000 - 20,000 = 80,000 which is approximately 16 / 13 and offset the base by 20,000 to achieve 20,000 to 100,000

				ALIGN 

				END 

