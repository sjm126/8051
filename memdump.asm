; memory dump - press 'd' to start dump
; Author: Steven J. Merrifield, sjm@ee.latrobe.edu.au
; sjm 22 Apr 95
; sjm 28 Apr 95


$mod51

cr              equ 0dh

                org 8000h

main_prog:      mov dptr,#0h        ; start addr for dump

main:           lcall check_key
                mov r1,#5           ; print 5 lines per dump
main2:          lcall one_line
                djnz r1,main2
                sjmp main



check_key:      lcall inchar        ; wait for key
                clr c
                subb a,#'d'         ; was it 'd'
                jnz check_key       ; no - check again
                mov a,#cr           ; yes - print blank and continue dump
                lcall outchar
                ret



; *******************************************************************
; Send one line of memory dump to screen
; *******************************************************************
one_line:       mov r7,#10h         ; each line is 16 bytes
                mov a,dph           ; high nibble of high byte of addr ptr
                rr a
                rr a
                rr a
                rr a
                anl a,#0fh
                lcall htoa
                lcall outchar

                mov a,dph           ; low nibble of high byte of addr ptr
                anl a,#0fh
                lcall htoa
                lcall outchar

                mov a,dpl           ; high nibble of low byte of addr ptr
                rr a
                rr a
                rr a
                rr a
                anl a,#0fh
                lcall htoa
                lcall outchar

                mov a,dpl           ; low nibble of low byte of addr ptr
                anl a,#0fh
                lcall htoa
                lcall outchar

                mov a,#':'          ; separate address from data
                lcall outchar
                mov a,#' '
                lcall outchar

top:            clr a
                movc a,@a+dptr    ; contents of (a+dptr) -> a
                rr a
                rr a
                rr a
                rr a
                anl a,#0fh          ; high nibble of data
                lcall htoa
                lcall outchar

                clr a
                movc a,@a+dptr
                anl a,#0fh          ; low nibble of data
                lcall htoa
                lcall outchar

                inc dptr
                mov a,#' '          ; space between each byte
                lcall outchar
                djnz r7,top         ; bytes per line
                mov a,#cr
                lcall outchar
                ret



; *******************************************************************
; hex to ascii
; *******************************************************************
htoa:           anl a,#0fh
                cjne a,#0ah,$+3
                jc htoa2
                add a,#7
htoa2:          add a,#'0'
                ret


;********************************************************************
; Wait until tx ready, then send a char out serial port
;*******************************************************************/
outchar:    jnb ti,outchar      ; wait until ti is set
            clr ti              ; clear it
            mov sbuf,a          ; send acc to serial buffer
            ret

; *******************************************************************
; Wait unti we receive a char, and return it in acc.
; *******************************************************************
inchar:     jnb ri,$            ;; wait until ri is set
            clr ri              ;; clear it
            mov a,sbuf          ;; read value from serial port buffer
            ret

            end




