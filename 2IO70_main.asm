
@DATA
	; pdasd
	butbuf	DW		0		; The previous button input.
	current_digit	DW	0	; The current selected digit.
	digits	DS		6		; The values of the individual digits.
	step	DW		0		; Current step. Has to do with the PWM.
	n_but	DW		99,0,0,0,0,0,0,0		; The pulse width for each digit.
	prs_0	DW		0		; presence detector 0
	prs_1	DW		0		; presence detector 1
	prs_2	DW		0		; presence detector 2
	prs_color    DW		0		; color detector
	out_light    DW		30		; light to enable {only 1 light at a time}
	current_state   DW	1		; state variable
@CODE

	; IO addreses. 
	IOAREA	EQU		-16  	; address of the I/O-Area, modulo 2^18
	INPUT	EQU		7  		; Relative address of the input buttons.
	OUTPUT	EQU		11  	; Relative address of the power outputs.
	DSPDIG	EQU		9  		; Relative address of the 7-segment display's digit selector.
	DSPSEG	EQU		8  		; Relative address of the 7-segment display's segments.
	TIMER	EQU		13		; Relative address of the timer.
	ADCONVS	EQU		6		; Relative address of the analog to digital converter.
	
	; Timer delay.
	DELAY	EQU		1		; The amount of time between timer interrupts.
	
	; PWM increment value.
	INCREMENT EQU	10		; The value with wich the pulse width gets larger or smaller when pressing a button.
	
	; Button values.
	BUTTON0	EQU		1		; Bit for button 0.
	BUTTON1	EQU		2		; Bit for button 1.
	BUTTON2	EQU		4		; Bit for button 2.
	BUTTON3	EQU		8		; Bit for button 3.
	BUTTON4	EQU		16		; Bit for button 4.
	BUTTON5	EQU		32		; Bit for button 5.
	BUTTON6	EQU		64		; Bit for button 6.
	BUTTON7	EQU		128		; Bit for button 7.
	
	; LED values.
	LED0	EQU		1		; Bit for LED 0.
	LED1	EQU		2		; Bit for LED 1.
	LED2	EQU		4		; Bit for LED 2.
	LED3	EQU		8		; Bit for LED 3.
	LED4	EQU		16		; Bit for LED 4.
	LED5	EQU		32		; Bit for LED 5.
	LED6	EQU		64		; Bit for LED 6.
	LED7	EQU		128		; Bit for LED 7.
	scan_p0     EQU		1
	scan_p1		EQU		2
	scan_p2		EQU		3
	scan_color  EQU		4
	push_lever  EQU 	5
	scan_conveyor	EQU	6
	BLACK		EQU  	0
	WHITE		EQU 	1
	

; R0 = general purpose.
; R1 = general purpose.
; R2 = general purpose.

; R3 = output leds.
; R4 = x.	
; R5 = IO Register address.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Start of the program.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

begin:		
	BRA   setup_timer				; Jump to the start of the main subroutine.


			
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; display lights subroutine.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

do_update_lights:
			LOAD  R0  [GB+step]		; R0 = current step
			LOAD  R1  7				; R1 = i
			LOAD  R2  0				; R2 = Light value
			LOAD  R3  GB			; R3 = Load the last address of the list with n into R3
			ADD   R3  n_but			;
			ADD   R3  7				; 
do_update_lights_start:			
			CMP   R1  0				; while R1 <= 7
			BMI   do_update_lights_end; do
			MULS  R2  2				; 
			LOAD  R4  [R3]			; load the n for this digit.
			CMP   R0  R4			; 
			BPL   do_update_lights_off;
			OR    R2  1				; turn light on.
do_update_lights_off:
			SUB   R3  1				; 
			SUB   R1  1				; 
			BRA   do_update_lights_start;
do_update_lights_end:

			STOR  R2  [R5+OUTPUT]	; Write led value.
			RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; timer interrupt.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

interrupt_timer:
			LOAD  R0  DELAY			; Add delay to timer
			STOR  R0  [R5+TIMER]	; 
			
			LOAD  R0  [GB+step]		; Load the step into R0
			ADD   R0  1			; Increment step by 1
			MOD   R0  100			;
			STOR  R0  [GB+step]		; Store the new step
			
			BRS   do_update_lights	; Update the lights.
			
			SETI  8
			RTE
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main program.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_timer:		
			; Initialize global variables
			LOAD  R0  0
			STOR  R0  [GB+prs_0]
			STOR  R0  [GB+prs_1]
			STOR  R0  [GB+prs_2]
			STOR  R0  [GB+prs_color]
		        ;LOAD  R0  BUTTON0
		        ;STOR  R0  [GB+out_light]        ; The light for the first presence detector
		           
			; Setup timer interrupt.
			LOAD  R0  interrupt_timer       ; Load the relative address of the interrupt routine into R0.
			ADD   R0  R5			; Load the absolute address of the interrupt routine into R0.
			LOAD  R1  16			; Load the address of the timer interrupt into R1.
		    STOR  R0  [R1]			; Set timer interrupt.
			LOAD  R5  IOAREA		; Load address with the IO registers into R5.
			
			; Set the timer value to 0.
			LOAD  R1  1				; Load the value 1 into R1. Had some problems with a value of 0.
			SUB   R1  [R5+TIMER]	; Do R1 = 1 - TIMER. So you get the negative value of the timer.
			STOR  R1  [R5+TIMER]	; Add the negative value to the timer so it will become 1.
			
			SETI  8					; Enable timer interrupt.
			
loop_start:
						;If state == light , call enable-light from all states  enable_light(int light); -> R0 = something -> BRS enable_light
			LOAD  R0  [GB+current_state]
			CMP   R0  scan_p0
			BNE   loop_read_1
			BRS   read_input_0
			BRA   loop_start
loop_read_1:
			CMP   R0  scan_p1
			BNE   loop_color
			BRS   read_input_1;
			BRA   loop_start
loop_color:
			CMP   R0  scan_color
			BNE   loop_conveyor
			BRS   read_input_color;
			BRA   loop_start
loop_conveyor:
			LOAD  R1  5
			;STOR  R1  [R5+10]
			CMP   R0  scan_conveyor
			BNE   loop_start
			BRS   conveyor_check;
			BRA   loop_start
;
;
;R0 == lamp that should be turned on
enable_light:		
			ADD   R0  GB
			ADD   R0  n_but
			LOAD  R3  99
			STOR  R3  [R0]
			RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;			
			
read_input_0:
			LOAD  R0  [R5+INPUT]
			AND   R0  BUTTON0
			CMP   R0  BUTTON0
			BNE   store_input_0
			LOAD  R0  scan_p0
			STOR  R0  [GB+current_state]
			BRA   store_input_0_end
			
store_input_0:
			LOAD  R0  scan_color
			STOR  R0  [GB+current_state]
store_input_0_end:
			
			RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
read_input_1:
			LOAD  R0  [R5+INPUT]
			AND   R0  BUTTON1
			CMP   R0  BUTTON1
			BEQ   store_input_1
			LOAD  R0  BLACK
			STOR  R0  [GB+prs_1]
			BRA   store_input_1_end
			
store_input_1:		
			LOAD  R0  WHITE
			STOR  R0  [GB+prs_1]
store_input_1_end:
			LOAD  R0  5
			;STOR  R0  [R5+10]
			RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_input_2:		
			LOAD  R0  [R5+INPUT]
			AND   R0  BUTTON2
			CMP   R0  BUTTON2
			BEQ   store_input_2
			LOAD  R0  0
			STOR  R0  [GB+prs_2]
			RTS
			
store_input_2:		
			LOAD  R0  1
			STOR  R0  [GB+prs_2]
			RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_input_color:
			LOAD  R0  1
			STOR  R0  [R5+10]
			LOAD  R0  [R5+INPUT]
			AND   R0  BUTTON3
			CMP   R0  BUTTON3
			BEQ   store_input_color
			LOAD  R0  BLACK
			STOR  R0  [GB+prs_color]
			LOAD  R0  conveyor_check
			STOR  R0  [GB+current_state]
			BRA   store_input_color_end
			
store_input_color:
			LOAD  R0  WHITE
			STOR  R0  [GB+prs_color]
			LOAD  R0  conveyor_check
			STOR  R0  [GB+current_state]
store_input_color_end:
			RTS
			
			

conveyor_check:	
			LOAD  R0  5
			STOR  R0  [R5+10]
			LOAD  R0  [GB+prs_color]
			CMP   R0  WHITE
			BEQ   conveyor_white
conveyor_black:		
			LOAD  R0  75
			STOR  R0  [GB+n_but+4]
conveyor_black_motor_stop:
			LOAD  R0  [R5+INPUT]
			AND   R0  BUTTON1
			CMP   R0  BUTTON1
			BEQ   conveyor_black_motor_stop
			LOAD  R0  0
			STOR  R0  [GB+n_but+4]
			LOAD  R0  prs_0
			STOR  R0  [GB+current_state]
			BRA   conveyor_end
conveyor_white:
			LOAD  R0  75
			STOR  R0  [GB+n_but+5]
conveyor_white_motor_stop:
			LOAD  R0  [R5+INPUT]
			AND   R0  BUTTON2
			CMP   R0  BUTTON2
			BEQ   conveyor_white_motor_stop
			LOAD  R0  0
			STOR  R0  [GB+n_but+5]
			LOAD  R0  prs_0
			STOR  R0  [GB+current_state]
conveyor_end:
			RTS
			
@END
