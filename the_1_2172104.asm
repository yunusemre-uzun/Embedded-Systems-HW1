LIST    P=18F8722

#include<p18f8722.inc>

    
CONFIG OSC = HSPLL, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF,WDT = OFF, MCLRE = ON, LPT1OSC = OFF, LVP = OFF, XINST = OFF, DEBUG = OFF
    
org h'00'; start code at 0
goto    main

;0x23 is used for state1 counter
;0x22<0> is used for RA4 flag, 0x22<1> is used for state flag
;0x21 and 0x20 are used for wait variables
;0x24<0:3> is used to seve state's state
    
init: ;Configuration for I/O pins
    movlw h'00'
    movwf TRISB
    movwf TRISC
    movwf TRISD
    clrf  LATA
    clrf  LATB
    clrf  LATC
    clrf  LATD
    clrf  LATE
    clrf  LATG
    clrf  0x22
    clrf  0x24
    movlw b'00010000'
    movwf TRISA
    movlw b'00011111' ; To make RA0~RA3 as digital output
    movwf ADCON1
    movlw b'00011000'
    movwf TRISE
    
    
    return

led_task:
    movlw h'0F'
    movwf LATA
    movwf LATB
    movwf LATC
    movwf LATD
    
    return
    
turn_off_all:
    movlw h'00'
    movwf LATA
    movwf LATB
    movwf LATC
    movwf LATD
    
    return
    
wait:
    MOVLW 0x09
    MOVWF 0x21
    call wait_loop
    return
    
wait_loop:
    MOVLW 0xDA
    MOVWF 0x20
    MOVLW 0xFF
    DECFSZ WREG
    goto inner_loop ;jump to the inner loop
    goto middle_loop ;wreg is zero goto the middle loop
    inner_loop:
	btfsc 0x22,0        ;check the button is pressed before or not
	goto pressed_before ;if pressed before
	btfsc PORTA,4       ;else check for RA4
	bsf 0x22,0	    ;if RA4 pressed set flag		
	goto wait_loop+6    ;then continue
	pressed_before:
	    btfsc PORTA,4      ;check RA4 released
	    goto  wait_loop+6  ;if not released
	    call  state2       ;if released
	    btfsc 0x22,1       ;where state2 returns, check for stage flag
	    goto state3        ;if it is 1 then goto state3
	    goto wait_loop+6   ;else continue loop
    middle_loop:
	DECFSZ 0x20,1          ;middle loop
	goto wait_loop+4       ;if middle_loop variable is not consumed yet
    outer_loop:
	DECFSZ 0x21,1          ;decrement outer loop variable
	goto wait_loop    
	return		       ;if outer loop variable consumed end wait
   
state1:
    btfsc 0x24,0
    goto state1_lata
    btfsc 0x24,1
    goto state1_latb
    btfsc 0x24,2
    goto state1_latc
    btfsc 0x24,3
    goto state1_latd
    goto state1_wait
    state1_lata:
	movlw b'00000001'
	movwf 0x24
	state1_lata_helper_call:
	    goto state1_helper_lata
	    btfsc LATA,3	;check last bit of the lat registers e.g. RA3
	    goto state1_latb	;if it is set, goto next lat
	    goto state1_lata_helper_call  ;else go back
    state1_latb:
	movlw b'00000010'
	movwf 0x24
	state1_latb_helper_call:
	    goto state1_helper_latb
	    btfsc LATB,3
	    goto state1_latc
	    goto state1_latb_helper_call
    state1_latc:
	movlw b'00000100'
	movwf 0x24
	state1_latc_helper_call:
	    goto state1_helper_latc
	    btfsc LATC,3
	    goto state1_latd
	    goto state1_latc_helper_call
    state1_latd:
	movlw b'00001000'
	movwf 0x24
	state1_latd_helper_call:
	    goto state1_helper_latd
	    btfsc LATD,3
	    goto state1_wait
	    goto state1_latd_helper_call
    state1_wait:
	movlw b'00010000'
	movwf 0x24
	goto wait_ra4	 
    return

state1_helper_lata:
    rlncf LATA, 1
    INCF LATA, 1
    call wait
    goto state1_lata_helper_call+2
state1_helper_latb:
    rlncf LATB, 1
    INCF LATB, 1
    call wait
    goto state1_latb_helper_call+2
state1_helper_latc:
    rlncf LATC, 1
    INCF LATC, 1
    goto state1_latc_helper_call+2
    return
state1_helper_latd:
    rlncf LATD, 1
    INCF LATD, 1
    call wait
    goto state1_latd_helper_call+2
     
state2:
    decf  0x22	  ;if state2 is called then button is released, hence set 0x22<0> to zero
    btfsc PORTE,3 ;if RE3 pressed
    return        ;return
    btfsc PORTE,4 ;if RE4 pressed
    bsf   0x22,1  ;set state flag
    goto state2+2 ;check for RE3 or RE4 press
    return

state3:
    btfsc 0x24,0
    goto state3_lata
    btfsc 0x24,1
    goto state3_latb
    btfsc 0x24,2
    goto state3_latc
    btfsc 0x24,3
    goto state3_latd
    goto state3_wait
    state3_latd:
	movlw b'00001000'
	movwf 0x24
	movlw b'00000100'
	movwf 0x23
	state3_latd_helper_call:
	    goto state3_helper_latd
	    btfsc LATD,0
	    goto state3_latd_helper_call
    state3_latc:
	movlw b'00000100'
	movwf 0x24
	movlw b'00000100'
	movwf 0x23
	state3_latc_helper_call:
	    goto state3_helper_latc
	    btfsc LATC,0
	    goto state3_latc_helper_call
	    
    state3_latb:
	movlw b'00000010'
	movwf 0x24
	movlw b'00000100'
	movwf 0x23
	state3_latb_helper_call:
	    goto state3_helper_latb
	    btfsc LATB,0
	    goto state3_latb_helper_call
    
    state3_lata:
	movlw b'00000001'
	movwf 0x24
	state3_lata_helper_call:
	    goto state3_helper_lata
	    btfsc LATA,0
	    goto state3_lata_helper_call
    
    state3_wait:
	movlw b'00010000'
	movwf 0x24
	goto wait_ra4
    return
    
state3_helper_lata:
    decf LATA, 1
    rrncf LATA, 1
    call wait
    goto state2_lata_helper_call+2
state3_helper_latb:
    decf LATB, 1
    rrncf LATB, 1
    call wait
    goto state2_latb_helper_call+2
state3_helper_latc:
    decf LATC, 1
    rrncf LATC, 1
    call wait
    goto state2_latc_helper_call+2
state3_helper_latd:
    decf LATD, 1
    rrncf LATD, 1
    call wait
    goto state2_latd_helper_call+2
    

wait_ra4:
    btfsc 0x22,0    ;check RA4 flag
    goto  wait_for_release
    btfsc PORTA,4   ;if not pressed
    bsf 0x22,0      ;set RA4 flag as pressed
    goto wait_ra4   ;continue loop
    wait_for_release:
	btfsc PORTA,4   
	goto wait_for_release  ; if not released yet
	call state2	       ; if released call state2
	btfsc 0x22,1	       ; check state flag
	goto state3	       ; if it is 1
	goto state1	       ; if it is 0
    return
    
main:
    call init
loop:
    call led_task
    call wait
    call wait
    call wait
    call wait
    call turn_off_all
    call wait
    call wait
    movlw b'00000001'
    movwf 0x24
    goto state1

goto loop
end
    