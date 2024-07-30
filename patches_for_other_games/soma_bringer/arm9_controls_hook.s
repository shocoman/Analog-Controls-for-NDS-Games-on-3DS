@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02052598 | 04 00 a0 e1 | cpy r0,r4
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
move_with_cpad:
    mov     r0, r4 @ overwritten opcode

    push    {r0-r6, lr}
    mov     r6, r4

    @ Get the stick values
    ldr     r4, rtcom_output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    
    popeq   {r0-r6, pc} @ don't use the CPad if it's not touched

read_cpad:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    lsl     r4, #24
    asr     r4, #24
    @ Sign extend Y & negate
    asr     r5, #24
    neg     r5, r5

    ldr     r0, speed_multiply
    mul     r4, r0, r4
    add     r4, #(1 << 11)
    asr     r4, #12
    mul     r5, r0, r5
    add     r5, #(1 << 11)
    asr     r5, #12

    str     r4, [r6]
    str     r5, [r6, #8]

    pop     {r0-r6, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_maxradius      = 0x69

speed_multiply:     .long (0x1000 << 12) / cpad_maxradius

rtcom_output:       .long 0x027ffdf0

