;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.
            .sect ".sysmem"
Cantidad	.word	0
x			.word	0
;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer
;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
	bic.b #LOCKLPM5, PM5CTL0	; Not needed for MSP430G2553
SetupPins:
	bis.b	#BIT0, &P1DIR	;P1.0 as output
    bic.b	#BIT0, &P1OUT	;initialize LED off
    bic.b	#BIT3, &P2DIR	;P2.3 as input
    bis.b	#BIT3, &P2REN	;Select P2.3 internal resistance
    bis.b	#BIT3, &P2OUT	;Make it pull-up to voltage
    bis.b	#BIT1, &P1DIR	;P1.0 as output
    bic.b	#BIT1, &P1OUT	;initialize LED off
    bic.b	#BIT7, &P2DIR	;P2.7 as input
    bis.b	#BIT7, &P2REN	;Select P2.7 internal resistance
    bis.b	#BIT7, &P2OUT	;Make it pull-up to voltage
Loop:
	bit.b	#BIT3, P2IN
	jz GO
	jmp Loop
GO:
	nop
    bis.b	#BIT3, &P2IE	;Enable interrupt flags
    bis.b	#BIT3, &P2IES
    bic.b	#BIT3, &P2IFG
    bis.b	#BIT7, &P2IE	;Enable interrupt flags
    bis.b	#BIT7, &P2IES
    bic.b	#BIT7, &P2IFG
SetupC0:
	mov.w	#CCIE, &TA0CCTL0	;Enable CCR0 interrupt
	mov.w	#4096, &TA0CCR0

SetupTimerA:
	bis.w   #TASSEL_1+ID_3+MC_1,&TA0CTL
	bis.w	#GIE+LPM0, SR	;Enable interrupts and enter low power mode 0
;----------------------------------------------------------------------------
;Interrupt Service Routine for TIMER_A
;----------------------------------------------------------------------------
TACCR0_ISR
	inc x
	mov x, R7
	add R7, Cantidad
    clr x
    xor.b #1, &P1OUT	;Toggle LED
	reti
;----------------------------------------------------------------------------
;P2.7 Interrupt Service Routine
;----------------------------------------------------------------------------
PIN_ISR
	bic.b #BIT7, &P2IFG
	xor.b #1, &P1OUT
Display:
	bit.b #BIT7, &P2IN		;Al presionar el boton, se activa el display del resultado de las centenas
	jnz Display
	clrz					; Limpiar flag Z
In:
	xor.b #1,&P1OUT 		; Toggle P1.0
	mov #15, R9				; Tiempo para Separación de digitos
Brinco:
	mov #65535,R8
	call #Delay				; Loop para aumentar duración de luz
	dec R9
	jnz Brinco				; Si R9 no es cero volvemos
	mov Cantidad, R5		; Movemos valor de centena a nuevo registro
	xor.b #1,&P1OUT 		; Toggle P1.0
	call #Wait				; Espacio entre luz
	call #DISPLAY
DISPLAY:
	clrn
	dec R5
	jn stop
	xor.b #BIT1,&P1OUT 		; Toggle P1.0
	call #Wait
	xor.b #BIT1,&P1OUT 		; Toggle P1.0
Wait:
	clrz
	mov #65535,R15 			; Delay to R15
L1:
	dec R15 				; Decrement R15
	jz DISPLAY 				; Delay over ?
	jmp L1
stop:
	ret
Delay:
	dec R8
	jnz Delay
	ret
End:
	reti
;-----------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            .sect	TIMER0_A0_VECTOR
            .short	TACCR0_ISR
            .sect	PORT2_VECTOR
            .short	PIN_ISR
            .end
            
