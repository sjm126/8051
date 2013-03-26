; Generates a 7kHz and 500Hz square wave simultaneously
; Author - Steven J. Merrifield, sjm@ee.latrobe.edu.au
; sjm 16 Apr 95

$mod51

            org 8000h
            ljmp main
            org 800bh       ; timer 0 vector address
            ljmp t0isr
            org 801bh       ; timer 1 vector address
            ljmp t1isr

            org 8030h
main:       mov tmod,#12h       ; timer 1 = mode 1, timer 0 = mode 2
            mov th0,#-71        ; 7kHz using timer 1 interrupt
            setb tr0
            setb tf1            ; force timer 1 interrupt
            mov ie,#8ah         ; enable both timer interrupts
            sjmp $

t0isr:      cpl p1.7
            reti

t1isr:      clr tr1
            mov th1,#high(-1000)
            mov tl1,#low(-1000)
            setb tr1
            cpl p1.6
            reti

            end





