@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 021e9d34 | 98 22 | movs   r2,#0x98
@ 021e9d36 | 8a 5e | ldrsh  r2,[r1,r2]
@ 021e9d38 | 02 80 | strh   r2,[r0,#0x0]
@ 021e9d3a | 9a 22 | movs   r2,#0x9a
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
MovePlayerWithCPad:
    push    {r1-r5, lr}

    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    bne     Read_CPAD

    pop     {r1-r5, lr} @ don't use the CPad if it's not touched
    b       MovePlayerWithCPad_End

Read_CPAD:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    mov     r4, r4, lsl #24
    mov     r4, r4, asr #24
    rsb     r4, #0
    @ Sign extend Y & negate
    mov     r5, r5, asr #24
    rsb     r5, #0

    mov     r3, r4 @ X * 3
    lsl     r4, #1
    add     r4, r3
    mov     r3, r5 @ Y * 3
    lsl     r5, #1
    add     r5, r3
    
    @ 0x98, 0x9A: Y, X, offsets
    ldrsh   r2, [r1, #0x98]
    add     r2, r5
    strh    r2, [r1, #0x98]

    ldrsh   r2, [r1, #0x9A]
    add     r2, r4
    strh    r2, [r1, #0x9A]
    
    pop     {r1-r5, lr}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
MovePlayerWithCPad_End: 
    @ replaced opcodes
    movs    r2, #0x98
    ldrsh   r2, [r1, r2]
    strh    r2, [r0, #0x0]
    movs    r2, #0x9a

    ldr     r3, returnaddr
    bx      r3

    returnaddr:     .long MOVE_RETURN_ADDR
    RTCom_Output:   .long 0x027ffdf0


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 022115be | 41 30 | adds r0,#0x41
@ 022115c0 | 00 78 | ldrb r0,[r0,#0x0]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ activate barrel roll when X is held
barrel_roll_func:
    ldrb    r0, [r0, #0x41] @ overwritten opcode
    push    {r0-r7}

    @ get SuperState
    ldr     r0, [r4, #0x30]
    ldr     r6, [r0]

    @ check if roll_btn is currently pressed
    mov     r1, #0x4000000
    ldr     r1, [r1, #0x130]
    ldr     r2, =0x027fffa8
    ldrh    r2, [r2]
    orr     r1, r2
    mvn     r7, r1
    tst     r7, #0x400
    moveq   r1, #0
    movne   r1, #1
    
    @ old X state
    ldr     r3, is_roll_btn_held 

    @ is_released = is_held_old & (is_held_now ^ is_held_old) ; r3 = r3 & (r1 ^ r3)
    eor     r2, r1, r3
    and     r3, r2

    str     r1, is_roll_btn_held
    str     r3, is_roll_btn_released

    @ X is held
    cmp     r1, #0
    bne     barrel_roll_func__start_rolling
    @ X has been released
    cmp     r3, #0
    mov     r0, #0
    strne   r0, is_blocked
    bne     barrel_roll_func__stop_rolling
    b       barrel_roll_func__exit

barrel_roll_func__stop_rolling:
    mov     r2, #0
    strb    r2, [r6, #0x113]
    b       barrel_roll_func__exit

barrel_roll_func__start_rolling:
    @ check if we have enough energy to initiate the barrel roll
    ldr     r1, [r6, #0xbc] @ energy wasted currently
    ldr     r2, [r6, #0xc4] @ max energy
    cmp     r1, r2
    mov     r1, #1
    strge   r1, is_blocked

    ldr     r0, is_blocked
    cmp     r0, #0
    bne     barrel_roll_func__exit

    ldr     r4, RTCom_Output
    ldrsb   r4, [r4, #0]
    cmp     r4, #0
    addge   lr, #0x28
    addlt   lr, #0x4

    @ tst     r7, #0x10
    @ addne   lr, #0x28
    @ addeq   lr, #0x4


barrel_roll_func__exit:
    pop     {r0-r7}
    bx      lr


is_roll_btn_held:       .long 0
is_roll_btn_released:   .long 0
is_blocked:             .long 0

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ source: https://web.archive.org/web/20110604163902/http://crackerscrap.com/docs/sfchacktut.html
@ 0x021EE4CC
boostbrake_func:
    ;@ Start of brake, boost handler
    push    {r0-r12,lr}
    mov     r1,#0x4000000
    ldr     r1,[r1,#0x130]		;@ read key register
    ;@ code to reset ability to brake or boost after a and/or b are released
    and     r0,r1,#0x3			;@ mask out everything but a, b
    eors    r0,#0x3				;@ toggle first two bits
    moveq   r0,#0x1				;@ if neither a nor b pressed reset flag to allow braking and boosting
    streq   r0,canuseboost
    ;@ code end
    ldr     r0,canuseboost
    cmp     r0,#0x0
    beq     noboost

    add     r4,#0x100			;@ increase pointer address
    mov     r0,#0x49000			;@ max boost used value - 0 = full meter
    ldr     r2,[r4,#-0x44]		;@ load current boost used value
    cmp     r2,r0				;@ compare the value to the max boost used
    movge   r0,#0x0				;@ no boost left
    movlt   r0,#0x1				;@ boost left
    str     r0,canuseboost		;@ save the flag to disable boost or brake
    bge     noboost

    ands    r0,r1,#0x3			;@ a + b pressed?
    streqb  r0,[r4,#0xf]		;@ turn brake flag off
    beq     onlyboost			;@ only boost

    and     r0,r1,#0x2			;@ b pressed? - brake
    lsr     r0,#0x1				;@ shift r0 one bit to the right - quick way of dividing by 2	
    eor     r0,#0x1				;@ invert value since 0 = button down, 1 = button up
    strb    r0,[r4,#0xf]		;@ store brake flag
onlyboost:
    ands    r0,r1,#0x1			;@ a - boost
    eor     r0,#0x1
    strb    r0,[r4,#0xe]       ;@ store boost flag
noboost:
    pop     {r0-r12,lr}
    ;@ patch 4 overwritten opcodes from 0x21ee4cc-0x21ee4d3
    ldrb    r3,[r4,r0]
    add     r0,#0x3
    add     r2,r4,r0
    mov     r1,#0xff
    ;@ patch end
    ldr     r0,bbreturn
    bx      r0

    bbreturn:       .long BOOSTBRAKE_RETURN_ADDR
    canuseboost:    .long 0x1
;@ End of brake, boost handler
