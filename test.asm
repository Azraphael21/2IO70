
@DATA

	absolute_mem_address	DW	0
	butbuf			DW		0		; The previous button input.
	current_digit	DW		0	; The current selected digit.
	digits			DW		0,0,0,0,0,0		; The values of the individual digits.
	sensor_values   DS      2		; The values of the sensors when a disk is falling
	step			DW		0		; Current step. Has to do with the PWM.
	pulse_widths	DW		0,0,0,0,0,99,99,99		; The pulse width for each digit.
	currentState    DW      0
	
	timer			DW		0
	
	abort_state		DW		0
	abort_adress	DW      0
	abort_psw		DW		0
	
	goto_initial	DW		0
	
	abort_temp		DW		0
	
	curr_button		DW		0
	prev_button 	DW		0
	
	disk_black		DW		0
	disk_white		DW		0
	
	message_initial		DW	18,23,18,29,36,36
	message_readcolor	DW	27,14,10,13,36,36
	message_pushblack	DW	25,30,28,17,36,11
	message_pushwhite	DW	25,30,28,17,36,32
	message_stopstate	DW	28,29,24,25,36,36
	message_errorstate	DW	14,27,27,36,36,36
@CODE

	; IO addreses. 
	IOAREA	EQU		-16  	; address of the I/O-Area, modulo 2^18
	INPUT	EQU		7  		; Relative address of the input buttons.
	OUTPUT	EQU		11  	; Relative address of the power outputs.
	LEDS	EQU		10		; Relative address of the 3 leds.
	DSPDIG	EQU		9  		; Relative address of the 7-segment display's digit selector.
	DSPSEG	EQU		8  		; Relative address of the 7-segment display's segments.
	TIMER	EQU		13		; Relative address of the timer.
	ADCONVS	EQU		6		; Relative address of the analog to digital converter.
	SWITCHES	EQU	0
	; Timer delay.
	DELAY	EQU		1		; The amount of time between timer interrupts.
	
	; PWM increment value.
	INCREMENT EQU	10		; The value with wich the pulse width gets larger or smaller when pressing a button.
	
	; Max and min PWM values.
	MAXPULSE EQU	99		; The maximum width of a single pulse.
	MINPULSE EQU	0		; The minimum wdth of a single pulse
	
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
	
	PWM0	EQU		0		; 
	PWM1	EQU		1		; 
	PWM2	EQU		2		; 
	PWM3	EQU		3		; 
	PWM4	EQU		4		; 
	PWM5	EQU		5		; 
	PWM6	EQU		6		;
	PWM7	EQU		7		;
	
	; State values
	INITIAL 		EQU		0
	READCOLOR		EQU		1
	PUSHBLACK		EQU		2
	PUSHWHITE		EQU		3
	PUSHERTIMEOUT	EQU		5
	STOPSTATE		EQU		6
	ERRORSTATE		EQU		7
	
	; Halfway or fullway
	HALFWAY  	EQU 	1
	FULLWAY 	EQU 	2
	
	; Start stop buttons
	START   EQU     BUTTON4
	STOP    EQU		BUTTON3
	ABORT   EQU     BUTTON2
	
	MOTOR0	EQU		PWM0	;
	SWITCH0	EQU		BUTTON0	;
	
	MOTOR1	EQU		PWM1	; 
	SWITCH1	EQU		BUTTON1	;
	
	SENSOR0	EQU		BUTTON7	; 
	SENSOR1	EQU		BUTTON6	;
	SENSOR2	EQU		BUTTON5	;
	
	LIGHT0	EQU		PWM6	;
	LIGHT1	EQU		PWM7	;
	
; R0 = general purpose.
; R1 = general purpose.
; R2 = general purpose.

; R3 = 
; R4 = 

; R5 = IO Register addres.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Start of the program.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
begin:		
			BRA   main			; Jump to the start of the main subroutine.


;  
;      Routine Hex7Seg maps a number in the range [0..15] to its hexadecimal
;      representation pattern for the 7-segment display.
;      R0 : upon entry, contains the number
;      R1 : upon exit,  contains the resulting pattern
;
Hex7Seg     :  BRS  Hex7Seg_bgn  ;  push address(tbl) onto stack and proceed at "bgn"
Hex7Seg_tbl : CONS  %01111110    ;  7-segment pattern for '0' 
              CONS  %00110000    ;  7-segment pattern for '1'
              CONS  %01101101    ;  7-segment pattern for '2'
              CONS  %01111001    ;  7-segment pattern for '3'
              CONS  %00110011    ;  7-segment pattern for '4'
              CONS  %01011011    ;  7-segment pattern for '5'
              CONS  %01011111    ;  7-segment pattern for '6'
              CONS  %01110000    ;  7-segment pattern for '7'
              CONS  %01111111    ;  7-segment pattern for '8'
              CONS  %01111011    ;  7-segment pattern for '9'
			  
              CONS  %01110111    ;  7-segment pattern for 'A'
              CONS  %00011111    ;  7-segment pattern for 'B'
              CONS  %01001110    ;  7-segment pattern for 'C'
              CONS  %00111101    ;  7-segment pattern for 'D'
              CONS  %01001111    ;  7-segment pattern for 'E'
              CONS  %01000111    ;  7-segment pattern for 'F'
			  CONS  %01111011    ;  7-segment pattern for 'G'
              CONS  %00110111    ;  7-segment pattern for 'H'
              CONS  %00000110    ;  7-segment pattern for 'I'
              CONS  %00111100    ;  7-segment pattern for 'J'
			  
              CONS  %00110111    ;  7-segment pattern for 'K'
              CONS  %00001110    ;  7-segment pattern for 'L'
              CONS  %01010100    ;  7-segment pattern for 'M'
              CONS  %00010101    ;  7-segment pattern for 'N'
              CONS  %01111110    ;  7-segment pattern for 'O'
              CONS  %01100111    ;  7-segment pattern for 'P'
              CONS  %01110011    ;  7-segment pattern for 'Q'
              CONS  %00000101    ;  7-segment pattern for 'R'
              CONS  %01011011    ;  7-segment pattern for 'S'
              CONS  %00001111    ;  7-segment pattern for 'T'
			  
			  CONS  %00111110    ;  7-segment pattern for 'U'
			  CONS  %00011100    ;  7-segment pattern for 'V'
			  CONS  %00101010    ;  7-segment pattern for 'W'
			  CONS  %00110111    ;  7-segment pattern for 'X'
			  CONS  %00111011    ;  7-segment pattern for 'Y'
			  CONS  %01101101    ;  7-segment pattern for 'Z'
			  CONS  %00000000    ;  7-segment pattern for ' '
Hex7Seg_bgn:  MOD   R0  37   	 ;  R0 := R0 MOD 37 , just to be safe...
              LOAD  R1  [SP++]   ;  R1 := address(tbl) (retrieve from stack)
              LOAD  R1  [R1+R0]  ;  R1 := tbl[R0]
              RTS			

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; get digit subroutine.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
getDigit:
			BRS   getDigit_bgn
getDigit_tbl:
			CONS  %0000001			; Digit 0
			CONS  %0000010			; Digit 1
			CONS  %0000100			; Digit 2
			CONS  %0001000			; Digit 3
			CONS  %0010000			; Digit 4
			CONS  %0100000			; Digit 5
			
getDigit_bgn:
			MOD   R0  6
			LOAD  R1  [SP++]
			LOAD  R1  [R1+R0]
			RTS

	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; display lights subroutine.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		
do_update_lights:
			LOAD  R0  [GB+step]		; R0 = current step
			LOAD  R1  7				; R1 = i
			LOAD  R2  0				; R2 = Light value
			LOAD  R3  GB			; R3 = Load the last address of the list with n into R3
			ADD   R3  pulse_widths	;
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
; display elements subroutine.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
do_digit:
			; Display digit.
			LOAD  R4  [GB+current_digit]
			ADD   R4  1				; Move to next digit
			MOD   R4  6				; 
			STOR  R4  [GB+current_digit]
			
			LOAD  R0  GB			; Load the start of where the digits are stored.
			ADD   R0  digits		; 
			LOAD  R0  [R0+R4]		; Load the value of the digit R4
			
			BRS   Hex7Seg			; Lookup the value of the leds.
			
;			CMP   R4  5				; If the current digit is 5.
;			BNE   do_digit_write	; Write a point.
;			OR    R1  %010000000
;do_digit_write:
			STOR  R1  [R5+DSPSEG]	; Write digit.
			LOAD  R0  R4
			BRS   getDigit
			STOR  R1  [R5+DSPDIG]
			RTS
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; timer interrupt.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
interrupt_timer:
			LOAD  R0  DELAY			; Add delay to the PP2 timer.
			STOR  R0  [R5+TIMER]	; Writing to the timer will add that value automatically to the timer.
			
			LOAD  R0  [GB+step]		; Load the pwm_step into R0
			ADD   R0  1				; Increment the pwm_step by 1
			MOD   R0  100			; As soon as the pwm_step reaches 100 make it become 0 again.
			STOR  R0  [GB+step]		; Store the new step
			
			BRS   do_update_lights	; Update the outputs. 
			BRS   do_digit			; Update the 7-segment displays.
			
			; Update our own timer,
			LOAD  R0  [GB+timer]	; read the value of our timer.
			SUB   R0  1				; decrease timer.
			CMP   R0  0				; if the value of the timer > 0 go to store timer value.
			BPL   interrupt_timer_store 
			LOAD  R0  0				; Set timer to 0.
interrupt_timer_store:
			STOR  R0  [GB+timer]	; store new value.
			
			LOAD  R2  [R5+OUTPUT]	; TODO: This instruction seems to be useless.
			
			LOAD  R0  [GB+abort_state]
			CMP   R0  0
			BNE   interrupt_timer_end
			
			LOAD  R1  [R5+INPUT]
			AND   R1  ABORT
			CMP   R1  ABORT
			BNE   interrupt_timer_end
interrupt_timer_abort:

			LOAD  R0  [SP+1]
			STOR  R0  [GB+abort_adress]
			
			LOAD  R0  [SP+0]
			STOR  R0  [GB+abort_psw]
			
			LOAD  R0  abort
			ADD   R0  [GB+absolute_mem_address]
			STOR  R0  [SP+1]			
			
			LOAD  R0  1
			STOR  R0  [GB+abort_state]
interrupt_timer_end:
			SETI  8
			RTE

;;
;;
;;		
abort:
			PUSH  R0
			PUSH  R1
			PUSH  R2
			PUSH  R3
			PUSH  R4
			
			LOAD  R2  [GB+timer]
			
			LOAD  R1  GB
			ADD   R1  pulse_widths
			
			LOAD  R0  0
			
			LOAD  R4  [R1+MOTOR0]
			STOR  R0  [R1+MOTOR0]
			LOAD  R3  [R1+MOTOR1]
			STOR  R0  [R1+MOTOR1]
			
			
			LOAD  R0  7
			STOR  R0  [R5+LEDS]
			
abort_while_not_pressed:				
			LOAD  R0  [R5+INPUT]		; Check if the start button is pressed.
			AND   R0  START				; 
			CMP   R0  START				;
			BEQ   abort_while_pressed_start
										
			LOAD  R0  [R5+INPUT]		; Check if the stop button is pressed.
			AND   R0  STOP				;
			CMP   R0  STOP				;
			BEQ   abort_while_pressed_stop

			BRA   abort_while_not_pressed
			
abort_while_pressed_start:
			LOAD  R0  [R5+INPUT]		; Check if the start button is released.
			AND   R0  START				;
			CMP   R0  START				;
			BEQ   abort_while_pressed_start
			
			BRA   abort_while_end
			
abort_while_pressed_stop:
			LOAD  R0  [R5+INPUT]		; Check if the stop button is released.
			AND   R0  STOP				;
			CMP   R0  STOP				;
			BEQ   abort_while_pressed_stop
			
			LOAD  R0  1
			STOR  R0  [GB+goto_initial]
			
			BRA   abort_while_end
			
abort_while_end:
			LOAD  R0  0
			STOR  R0  [R5+LEDS]

			STOR  R4  [R1+MOTOR0]
			STOR  R3  [R1+MOTOR1]
			
			STOR  R2  [GB+timer]
			
			POP   R4
			POP   R3
			POP   R2
			POP   R1
			POP   R0
			
abort_restore_stack:			
			STOR  R0  [GB+abort_temp]
			
			LOAD  R0  0
			STOR  R0  [GB+abort_state]
			
			LOAD  R0  [GB+abort_temp]
			
			PUSH  R5
			PUSH  R4
			PUSH  R3
			PUSH  R2
			PUSH  R1
			PUSH  R0
			
			LOAD  R0  [GB+abort_adress]
			PUSH  R0
			
			LOAD  R0  [GB+abort_psw]
			PUSH  R0
			
abort_end:
			RTE


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Get the state message.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; R4 == state to get message from.
; Return:
; R0 == memory location of the message.

get_state_message:
			CMP   R4  INITIAL
			BEQ   get_state_message_initial
			CMP   R4  READCOLOR
			BEQ   get_state_message_readcolor
			CMP   R4  PUSHBLACK
			BEQ   get_state_message_pushblack
			CMP   R4  PUSHWHITE
			BEQ   get_state_message_pushwhite
			CMP   R4  STOPSTATE
			BEQ   get_state_message_stopstate
			CMP   R4  ERRORSTATE
			BEQ   get_state_message_errorstate
			
get_state_message_initial:
			LOAD  R0  message_initial
			BRA   get_state_message_end
get_state_message_readcolor:
			LOAD  R0  message_readcolor
			BRA   get_state_message_end
get_state_message_pushblack:
			LOAD  R0  message_pushblack
			BRA   get_state_message_end
get_state_message_pushwhite:
			LOAD  R0  message_pushwhite
			BRA   get_state_message_end
get_state_message_stopstate:
			LOAD  R0  message_stopstate
			BRA   get_state_message_end
get_state_message_errorstate:
			LOAD  R0  message_errorstate
			BRA   get_state_message_end
get_state_message_end:
			RTS
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Set state and text.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; R4 == state to set
; R3 == is an error
set_state:
			STOR  R4  [GB+currentState]
			CMP   R4  ERRORSTATE
			BEQ   set_state_error
			
			BRS   get_state_message
			LOAD  R1  R0
			ADD   R1  GB
			LOAD  R0  [R1+0]
			STOR  R0  [GB+digits+5]
			LOAD  R0  [R1+1]
			STOR  R0  [GB+digits+4]
			LOAD  R0  [R1+2]
			STOR  R0  [GB+digits+3]
			LOAD  R0  [R1+3]
			STOR  R0  [GB+digits+2]
			LOAD  R0  [R1+4]
			STOR  R0  [GB+digits+1]
			LOAD  R0  [R1+5]
			STOR  R0  [GB+digits+0]
			
			
			BRA   set_state_end
set_state_error:
			LOAD  R0  36
			STOR  R0  [GB+digits+0]
			LOAD  R0  R3
			STOR  R0  [GB+digits+1]
			LOAD  R0  36
			STOR  R0  [GB+digits+2]
			LOAD  R0  27			; Code for r
			STOR  R0  [GB+digits+3]
			LOAD  R0  27			; Code for r
			STOR  R0  [GB+digits+4]
			LOAD  R0  14			; Code for E
			STOR  R0  [GB+digits+5]
set_state_end:
			RTS
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sleep subroutine.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; R0 == sleep time
sleep:
			;;LOAD  R0  3000
			STOR  R0  [GB+timer]
			
sleep_loop_start:
			LOAD  R0  [GB+timer]
			CMP   R0  0
			BEQ   sleep_end
			BRA   sleep_loop_start
sleep_end:
			RTS
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Read sensor subroutine.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Senors variables could be saved to the stack instead of RAM

do_detect_color:
			LOAD  R3  0				; Initializing some variables
			LOAD  R1  GB			; 
			ADD   R1  pulse_widths	; 
			
			LOAD  R0  10
			;BRS   sleep
			
			LOAD  R0  [R5+INPUT]			; Read the values of the bottom sensors
			AND   R0  SENSOR1				;
			STOR  R0  [GB+sensor_values+0]	;
			LOAD  R0  [R5+INPUT]			;
			AND   R0  SENSOR0				;
			STOR  R0  [GB+sensor_values+1]	;
			
			; Control the top sensor
			LOAD  R2  0				; 
			STOR  R2  [R1+LIGHT0]	;
			
			LOAD  R0  3000
			BRS   sleep				;
			
			LOAD  R0  [R5+INPUT]	;
			AND   R0  SENSOR2		;
			LOAD  R3  R0			;
			
			LOAD  R2  99			;	
			STOR  R2  [R1+LIGHT0]	;
			
			LOAD  R2  0				;
			STOR  R2  [R1+LIGHT1]	;
			
			LOAD  R0  3000
			BRS   sleep				;
			
			LOAD  R0  [R5+INPUT]	;
			LOAD  R2  99
			STOR  R2  [R1+LIGHT1]
			AND   R0  SENSOR2		;
			AND   R3  R0
			
			CMP   R3  0
			BNE   do_detect_color_empty
			
			;
			LOAD  R0  [GB+sensor_values+0]	; If(white)
			AND   R0  SENSOR1
			CMP   R0  SENSOR1
			BEQ   do_detect_color_white		; Then
			
			LOAD  R0  [GB+sensor_values+1]	; If(white)
			AND   R0  SENSOR0
			CMP   R0  SENSOR0
			BEQ   do_detect_color_white		; Then
			
do_detect_color_black:
			
			LOAD  R4  PUSHBLACK
			LOAD  R3  0
			BRS   set_state
			
			LOAD  R0  [GB+disk_black]
			ADD   R0  1
			STOR  R0  [GB+disk_black]
			
			BRA   do_detect_color_end

do_detect_color_empty:

			LOAD  R4  INITIAL
			LOAD  R3  0
			BRS   set_state
			
			BRA   do_detect_color_end

do_detect_color_white:
			
			LOAD  R4  PUSHWHITE
			LOAD  R3  0
			BRS   set_state
			
			LOAD  R0  [GB+disk_white]
			ADD   R0  1
			STOR  R0  [GB+disk_white]
			
do_detect_color_end:
			RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Do pusher subroutine.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;R2  ==  AMOUNT OF DEGREES
;R3  ==  MOTOR
;R4  ==  SWITCH
do_pusher:
			LOAD  R1  GB			; Load adress of the output into R1
			ADD   R1  pulse_widths	; 
			
			LOAD  R0  10000
			STOR  R0  [GB+timer]
			
			LOAD  R0  [R5+INPUT]
			STOR  R0  [GB+curr_button]
			
			LOAD  R0  [GB+curr_button]
			STOR  R0  [GB+prev_button]
			
			LOAD  R0  75			; start motor
			STOR  R0  [R1+R3]		; 
			
do_pusher_if_degrees_fullway:
			CMP   R2  FULLWAY
			BNE   do_pusher_else_if_halfway
			
do_pusher_while_fullway:
			LOAD  R0  [GB+timer]
			CMP   R0  0
			BEQ   do_pusher_timeout
			
			LOAD  R0  [GB+curr_button]
			STOR  R0  [GB+prev_button]
			
			LOAD  R0  [R5+INPUT]
			STOR  R0  [GB+curr_button]
			
			LOAD  R0  [GB+curr_button]	; If button is pressed 
			AND   R0  R4		; 
			CMP   R0  R4		; 
			BNE   do_pusher_while_fullway	;
			
			LOAD  R0  [GB+prev_button]; If button was not pressed
			AND   R0  R4		;
			CMP   R0  R4		;
			BEQ   do_pusher_while_fullway	;
			
			BRA   do_pusher_stop_motor_fullway
			
do_pusher_else_if_halfway:
			CMP   R2  HALFWAY
			BNE   do_pusher_end

do_pusher_while_halfway:
			LOAD  R0  [GB+timer]
			CMP   R0  0
			BEQ   do_pusher_timeout
			
			LOAD  R0  [GB+curr_button]
			STOR  R0  [GB+prev_button]
			
			LOAD  R0  [R5+INPUT]
			STOR  R0  [GB+curr_button]
			
			LOAD  R0  [GB+curr_button]	; If button is pressed 
			AND   R0  R4		; 
			CMP   R0  R4		; 
			BEQ   do_pusher_while_halfway	;
			
			LOAD  R0  [GB+prev_button]; If button was not pressed
			AND   R0  R4		;
			CMP   R0  R4		;
			BNE   do_pusher_while_halfway	;
			
do_pusher_stop_motor_halfway:
			LOAD  R1  GB			; Load adress of the output into R1
			ADD   R1  pulse_widths	; 
			LOAD  R0  0				; Stop motor
			STOR  R0  [R1+R3]		;
			BRA   do_pusher_end		
			
do_pusher_stop_motor_fullway:
			LOAD  R1  GB			; Load adress of the output into R1
			ADD   R1  pulse_widths	; 
			LOAD  R0  0				; Stop motor
			STOR  R0  [R1+R3]		;
			BRA   do_pusher_return_to_readcolor

do_pusher_timeout:
			LOAD  R1  GB			; Load adress of the output into R1
			ADD   R1  pulse_widths	; 
			LOAD  R0  0				; Stop motor
			STOR  R0  [R1+R3]		;
			
			LOAD  R4  ERRORSTATE
			LOAD  R3  1
			BRS   set_state
			
			BRA   do_pusher_end

do_pusher_return_to_readcolor:
			LOAD  R4  READCOLOR
			LOAD  R3  0
			BRS   set_state
			
do_pusher_end:
			RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; intializing.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
initializing:
			LOAD  R4  INITIAL
			LOAD  R3  0
			BRS   set_state
			LOAD  R4  SWITCH0
			LOAD  R3  MOTOR0
			LOAD  R2  HALFWAY
			BRS   do_pusher
			LOAD  R0  [GB+currentState]
			CMP   R0  ERRORSTATE
			BEQ   initializing_end
			
initializing_wait_start:
			LOAD  R0  [R5+INPUT]
			AND   R0  START
			CMP   R0  START
			BEQ   initializing_reset_pusher
			
			BRA   initializing_wait_start

initializing_reset_pusher:
			LOAD  R4  SWITCH0
			LOAD  R3  MOTOR0
			LOAD  R2  FULLWAY
			BRS   do_pusher
			
initializing_end:			
			RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; error state.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
error_state:
			LOAD  R0  R0				; Do nothing instruction to prevent label errors
			LOAD  R0  5
			STOR  R0  [R5+LEDS]
			
error_state_while_not_pressed:				
			LOAD  R0  [R5+INPUT]		; Check if the start button is pressed.
			AND   R0  START				; 
			CMP   R0  START				;
			BEQ   error_state_while_pressed_start
										
			LOAD  R0  [R5+INPUT]		; Check if the stop button is pressed.
			AND   R0  STOP				;
			CMP   R0  STOP				;
			BEQ   error_state_while_pressed_stop

			BRA   error_state_while_not_pressed
			
error_state_while_pressed_start:
			LOAD  R0  [R5+INPUT]		; Check if the start button is released.
			AND   R0  START				;
			CMP   R0  START				;
			BEQ   error_state_while_pressed_start
			
			LOAD  R4  READCOLOR
			LOAD  R3  0
			BRS   set_state
			
			BRA   error_state_end
			
error_state_while_pressed_stop:
			LOAD  R0  [R5+INPUT]		; Check if the stop button is released.
			AND   R0  STOP				;
			CMP   R0  STOP				;
			BEQ   error_state_while_pressed_stop
			
			LOAD  R4  INITIAL
			LOAD  R3  0
			BRS   set_state
			
			BRA   error_state_end
error_state_end:
			LOAD  R0  0
			STOR  R0  [R5+LEDS]
			RTS

			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; stop state.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
stop_state:
			LOAD  R0  R0				; Do nothing instruction to prevent label errors
			
stop_state_while_not_pressed:				
			LOAD  R0  [R5+INPUT]		; Check if the start button is pressed.
			AND   R0  START				; 
			CMP   R0  START				;
			BEQ   stop_state_while_pressed_start
										
			LOAD  R0  [R5+INPUT]		; Check if the stop button is pressed.
			AND   R0  STOP				;
			CMP   R0  STOP				;
			BEQ   stop_state_while_pressed_stop

			BRA   stop_state_while_not_pressed
			
stop_state_while_pressed_start:
			LOAD  R0  [R5+INPUT]		; Check if the start button is released.
			AND   R0  START				;
			CMP   R0  START				;
			BEQ   stop_state_while_pressed_start
			
			LOAD  R4  READCOLOR
			LOAD  R3  0
			BRS   set_state
			
			BRA   stop_state_end
			
stop_state_while_pressed_stop:
			LOAD  R0  [R5+INPUT]		; Check if the stop button is released.
			AND   R0  STOP				;
			CMP   R0  STOP				;
			BEQ   stop_state_while_pressed_stop
			
			LOAD  R4  INITIAL
			LOAD  R3  0
			BRS   set_state
			
			BRA   stop_state_end
stop_state_end:			
			RTS
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main program.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
main:		
			; Setup timer interrupt.
			STOR  R5  [GB+absolute_mem_address]
			
			LOAD  R0  interrupt_timer;Load the relative address of the interrupt routine into R0.
			ADD   R0  R5			; Load the absolute address of the interrupt routine into R0.
			LOAD  R1  16			; Load the address of the timer interrupt into R1.
			STOR  R0  [R1]			; Set timer interrupt.
			LOAD  R5  IOAREA		; Load address with the IO registers into R5.
			
			; Set the timer value to 0.
			LOAD  R1  1				; Load the value 1 into R1. Had some problems with a value of 0.
			SUB   R1  [R5+TIMER]	; Do R1 = 1 - TIMER. So you get the negative value of the timer.
			STOR  R1  [R5+TIMER]	; Add the negative value to the timer so it will become 1.
			
			SETI  8					; Enable timer interrupt.
			
main_loop_start:
			LOAD  R0  [R5+INPUT]
			AND   R0  STOP
			CMP   R0  STOP
			BNE   main_switch
			LOAD  R4  STOPSTATE
			LOAD  R3  0
			BRS   set_state
			BRA   main_loop_start
main_switch:
			LOAD  R0  [GB+goto_initial]
			CMP   R0  1
			BEQ   main_on_abort
			
			LOAD  R0  [GB+currentState]
			CMP   R0  INITIAL
			BEQ   main_do_initializing
			CMP   R0  READCOLOR
			BEQ   main_do_readcolor
			CMP   R0  PUSHBLACK
			BEQ   main_do_pushblack
			CMP   R0  PUSHWHITE
			BEQ   main_do_pushwhite
			CMP   R0  STOPSTATE
			BEQ   main_do_stopstate
			CMP   R0  ERRORSTATE
			BEQ   main_do_errorstate
			BRA   main_loop_start

main_on_abort:		
			LOAD  R0  0
			STOR  R0  [GB+goto_initial]
			BRS   initializing
			BRA   main_loop_start

main_do_initializing:
			BRS   initializing			; Go to the analyzing state.
			BRA   main_loop_start		; Go to the start of the loop.
main_do_readcolor:
			BRS   do_detect_color		; Go to the detect color state.
			BRA   main_loop_start		; Go to the start of the loop.
main_do_pushblack:
			LOAD  R4  SWITCH0			; Set the parameters for the pusher subroutine.
			LOAD  R3  MOTOR0			; 
			LOAD  R2  FULLWAY			; 
			BRS   do_pusher				; Go to the pusher state.
			BRA   main_loop_start		; Go back to the start of the loop.
main_do_pushwhite:
			LOAD  R4  SWITCH1			; Set the parameters for the pusher routine.
			LOAD  R3  MOTOR1			; 
			LOAD  R2  FULLWAY			; 
			BRS   do_pusher				; Go to the pusher state.
			BRA   main_loop_start		; Go back to the start of the loop.
main_do_stopstate:
			BRS   stop_state			; Go to the stop state.
			BRA   main_loop_start		; Go back to the start of the loop.
main_do_errorstate:
			BRS   error_state			; Go to the error state.
			BRA   main_loop_start		; Go back to the start of the loop.
@END