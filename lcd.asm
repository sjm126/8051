; Scroll a message across LCD display
; Steven J. Merrifield, sjm@ee.latrobe.edu.au 05 May 95

$mod51

cr              equ 0dh
enable          equ p1.5    ; enable line
read_wri        equ p1.4    ; read/write line
reg_sel         equ p1.3    ; register select line
ppi_pa          equ 0       ; address of data port a
ppi_ctrl        equ 3       ; address of ctrl register

; This determines whether the display is updated quickly (instant text)
; or slowly (scrolling text).
slow_disp       set 30h     ; 0 = fast, 1 = slow



                org 8000h

                mov sp,#3fh

; init 8255A ppi
                mov a,#88h          ; port a = outputs
                mov dptr,#ppi_ctrl
                movx @dptr,a

; init lcd
                mov a,#38h          ; 8 bits, 5x7 font
                lcall wr_ctrl

                mov a,#7h           ; 7/6 = scroll on/off
                lcall wr_ctrl

                mov a,#0ch          ; display on, cursor off, blink off
                lcall wr_ctrl

                mov slow_disp,#1    ; slow

top:            mov dptr,#mess1     ; write message to LCD
                lcall outstr
                sjmp top


wr_data:        push dph            ; save data pointer
                push dpl
                mov dptr,#ppi_pa
                setb reg_sel        ; register select goes high
                clr read_wri        ; read/write goes low
                movx @dptr,a        ; write data
                setb enable         ; enable goes high
                clr enable          ; enable goes low
                setb read_wri       ; read/write goes high
                clr reg_sel         ; register select goes low
                pop dpl
                pop dph             ; restore data pointer
                mov a,slow_disp     ; is this a fast or slow write?
                jz bott_data        ; - fast
                lcall long_delay    ; - slow
bott_data:      lcall delay
                ret


wr_ctrl:        push dph            ; see comments for wr_data
                push dpl
                clr reg_sel         ; register select goes low - different
                clr read_wri        ; ... from above code
                mov dptr,#ppi_pa
                movx @dptr,a
                setb enable
                clr enable
                setb read_wri
                setb reg_sel        ; register select goes high - different
                pop dpl             ; ... from above code
                pop dph
                mov a,slow_disp
                jz bott_ctrl
                lcall long_delay
bott_ctrl:      lcall delay
                ret

; short delay - used to set timing requirments
delay:          mov r7,#0ffh
del2:           djnz r7,del2
                ret

; long delay - used to scroll across screen slowly
long_delay:     mov r5,#02h
lgdel:          mov r6,#070h
lgdel1:         mov r7,#0ffh
lgdel2:         djnz r7,lgdel2
                djnz r6,lgdel1
                djnz r5,lgdel
                ret


clrscr:         push slow_disp
                mov slow_disp,#1        ; update quickly
                mov a,#1
                lcall wr_ctrl
                pop slow_disp
                ret


;********************************************************************
; Send a null terminated string to LCD
;*******************************************************************/
outstr:         clr a
                movc a,@a+dptr      ; get character
                jz exit             ; stop if char == null
                lcall wr_data       ; else send it
                inc dptr            ; point to next char
                sjmp outstr
exit:           ret


mess1:          db 'Welcome to Steve''s 8051 microcontroller system.    ',0

                end




