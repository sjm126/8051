; KEY.ASM - keypad interface, reads keypad and echos to screen
; Steven J. Merrifield, sjm@ee.latrobe.edu.au 22 Apr 95

$mod51

ppi_pc          equ 2       ; addr of ppi port C
ppi_ctrl        equ 3       ; addr of ppi ctrl register

                org 8000h

; *******************************************************************
; init ppi
; *******************************************************************
                mov dptr,#ppi_ctrl
                mov a,#88h          ; 1000 1000
                                    ; port c lower = outputs
                                    ; port c upper = inputs

                movx @dptr,a        ; setup ctrl reg.

; *******************************************************************
; main program
; *******************************************************************
main:           lcall in_hex        ; get code from keypad
                lcall htoa          ; convert to ascii
                lcall outchar       ; send to terminal
                sjmp main

; *******************************************************************
; debounce keypress and key release
; *******************************************************************
in_hex:         mov r3,#50          ; debounce count
back:           lcall get_key       ; key pressed?
                jnc in_hex          ; no - check again
                djnz r3,back        ; yes - repeat 50 times
                push acc            ; save key code
back2:          mov r3,#50          ; wait for key release
back3:          lcall get_key       ; key still pressed?
                jc back2            ; yes - keep checking
                djnz r3,back3       ; no - repeat 50 times
                pop acc             ; recover key code
                ret

; *******************************************************************
; get keypad status - return with C = 0 if not key pressed
;                   - return with C = 1, and key in acc. if pressed
; *******************************************************************
get_key:        mov a,#0feh         ; start with column 0
                mov r6,#4           ; use r6 as a counter
test_next:      mov dptr,#ppi_pc    ; activate column line
                movx @dptr,a
                mov r7,a            ; save a
                movx a,@dptr
                anl a,#0f0h         ; isolate row lines
                cjne a,#0f0h,key_hit    ; row line active?
                mov a,r7            ; no - move to next column line
                rl a
                djnz r6,test_next
                clr c               ; no key pressed
                sjmp exit           ; return with c = 0
key_hit:        mov r7,a            ; save row code in r7
                mov a,#4            ; prepare to calc column weighting
                clr c
                subb a,r6           ; 4-r6 = column weighting
                mov r6,a            ; save in r6
                mov a,r7            ; restore scan code in acc
                swap a              ; put scan code in low nibble
                mov r5,#4           ; use r5 as counter
again:          rrc a               ; rotate until zero bit found
                jnc done            ; done when c = 0
                inc r6              ; add 4 until active row found
                inc r6
                inc r6
                inc r6
                djnz r5,again
done:           setb c              ; c = 1 (key pressed)
                mov a,r6            ; hex code in acc.
                lcall lookup_key    ; change mapping to suit my keypad
exit:           ret


; *******************************************************************
; hex to ascii
; *******************************************************************
htoa:           anl a,#0fh
                cjne a,#0ah,$+3
                jc htoa2
                add a,#7
htoa2:          add a,#'0'
                ret


; *******************************************************************
; send char out serial port
; *******************************************************************
outchar:        jnb ti,outchar      ; wait until ti is set
                clr ti              ; clear it
                mov sbuf,a          ; send acc to serial buffer
                ret


; *******************************************************************
; Keypad lookup table...
;
;            We're returning        We want to return
;            this....               this....
;
;               3 2 1 0     ->      1 2 3 A
;               7 6 5 4     ->      4 5 6 B
;               B A 9 8     ->      7 8 9 C
;               F E D C     ->      E 0 F D
;
; Hence, we need a mapping as shown:
;
;               0 1 2 3   4 5 6 7   8 9 A B   C D E F       ; Original
;               A 3 2 1   B 6 5 4   C 9 8 7   D # 0 *       ; Final
;
; The acc. contains the original value, so we need to add this value
; to the start of the table to get the new value.
; *******************************************************************
lookup_key:     mov dptr,#key_tab
                movc a,@a+dptr
                ret

key_tab:        db 0Ah,3,2,1,0Bh,6,5,4,0Ch,9,8,7,0Dh,0Fh,0,0Eh



                end


