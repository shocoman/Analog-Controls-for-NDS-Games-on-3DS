@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0207783c | 21 18 a0 e1 | mov r1,r1, lsr #0x10     @ Walking
@ 02077800 | 21 18 a0 e1 | mov r1,r1, lsr #0x10     @ or Running
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
move_with_cpad:
    mov     r1, r1, lsr #0x10 @ replaced opcode

    push    {r0, r2-r6, lr}

    @ Get the stick values
    ldr     r4, rtcom_output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    
    popeq   {r0, r2-r6, pc} @ don't use the CPad if it's not touched

read_cpad:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    lsl     r4, #24
    asr     r4, #24
    @ Sign extend Y & negate
    asr     r5, #24
    neg     r5, r5

    mov     r0, r4
    mov     r1, r5
    ldr     r5, getangle_func
    blx     r5

    mov     r1, r0  @ return new player direction


    pop     {r0, r2-r6, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_maxradius      = 0x69

rtcom_output:       .long 0x027ffdf0
getangle_func:      .long GET_ANGLE_FUNC

