;********************************************************************
;  8051 Boot Loader ver 3.0
;  Download standard Intel hex format files
;  Assemble using ASM51.EXE by MetaLink Corp.
;  Author: Steven J. Merrifield, sjm@ee.latrobe.edu.au
;  sjm 11 Apr 95
;  sjm 16 Apr 95
;  sjm 18 Apr 95
;********************************************************************

$mod51                              ; symbol definitions

error_led       equ p1.7            ; active low - clr to turn on
cr              equ 0dh             ; carriage return

ram             set 8000h           ; Start address for loading
                                    ; programs into

;********************************************************************
; Interrupt vector table
;********************************************************************
                org 0               ; System reset      RST
                ljmp main
                org 3               ; External 0        IE0
                ljmp (ram+3)
                org 0bh             ; Timer 0           TF0
                ljmp (ram+0bh)
                org 13h             ; External 1        IE1
                ljmp (ram+13h)
                org 1bh             ; Timer 1           TF1
                ljmp (ram+1bh)
                org 23h             ; Serial port       TI or RI
                ljmp (ram+23h)
                org 2bh             ; Timer 2           TF2 or EXF2
                ljmp (ram+2bh)

;********************************************************************
; Main program starts here
;********************************************************************
                org 30h
main:           setb error_led      ; turn off error led
                lcall init          ; init serial port
                lcall intro         ; print welcome message

load1:          lcall inchar
                cjne a,#1ah,skip1   ; end of file?
                sjmp done

skip1:          cjne a,#':',load1   ; each record begins with ':'
                mov r1,#0           ; init checksum to zero
                lcall gethex        ; get byte from serial port
                mov b,a             ; use b as byte counter
                jz done             ; if b = 0

load2:          inc b
                lcall gethex        ; get address high byte
                mov dph,a
                lcall gethex        ; get address low byte
                mov dpl,a
                lcall gethex        ; get record type (ignore this)

load4:          acall gethex        ; get data byte
                movx @dptr,a        ; store in ext. ram
                inc dptr
                dec b               ; repeat until count = 0
                mov a,b
                jnz load4
                mov a,r1            ; checksum should be zero
                jz load1            ; if so, then get next record
                ljmp error          ; if not, stop download

done:           ljmp ram            ; start running program

;********************************************************************
;  Get two characters from serial port and form a hex byte. Also add
;  byte to checksum in r1.
;********************************************************************
gethex:         lcall inchar        ; get first character
                lcall atoh          ; convert to hex
                swap a              ; put in upper nibble
                mov r0,a            ; save it
                lcall inchar        ; get second character
                lcall atoh          ; convert to hex
                orl a,r0            ; or with first nibble
                mov r2,a            ; save byte
                add a,r1            ; add byte to checksum
                mov r1,a            ; restore checkum in r1
                mov a,r2            ; retrieve byte
                ret

;********************************************************************
; Wait until a char is received from the serial port, and return
; that char in the accumulator.
;********************************************************************
inchar:         jnb ri,inchar       ; wait until ri is set
                clr ri              ; clear interrupt
                mov a,sbuf          ; get character
                ret

;********************************************************************
; ASCII to hex - enter with ascii code in acc. (assume hex char 0-F)
; exit with hex nibble in A.0-A.3
;********************************************************************
atoh:           clr acc.7           ; ensure parity bit is off
                cjne a,#3ah,next    ; ?? this just sets carry bit ??
next:           jc atoh2
                add a,#9            ; no, adjust for range A-F
atoh2:          anl a,#0fh          ; yes, convert directly
                ret


;********************************************************************
; Print welcome message
;********************************************************************
intro:          mov dptr,#prompt1
                lcall outstr
                mov dptr,#prompt2
                lcall outstr
                ret

;********************************************************************
; Wait until tx ready, then send a char out serial port
;********************************************************************
outchar:        jnb ti,outchar      ; wait until ti is set
                clr ti              ; clear it
                mov sbuf,a          ; send acc to serial buffer
                ret

;********************************************************************
; Send a null terminated string out serial port
;********************************************************************
outstr:         clr a
                movc a,@a+dptr      ; get character
                jz exit             ; stop if char == null
                lcall outchar       ; else send it
                inc dptr            ; point to next char
                sjmp outstr
exit:           ret

;********************************************************************
; Init serial port
;********************************************************************
init:           mov scon,#52h       ; 8 bit UART mode
                mov tmod,#20h       ; use timer 1 as baud rate clk
                mov th1,#-13        ; 2400 Baud with 12MHz xtal
                setb tr1            ; start timer
                ret

error:          clr error_led       ; turn on error LED
stop:           sjmp stop

prompt1:        db cr,'Steve''s 8051 bootloader - 18 April 1995',0
prompt2:        db cr,'Download Intel hex files to address 8000h',cr,0

                end

