@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020d47ca | 30 1c | adds r0,r6,#0x0
@ 020d47cc | 29 1c | adds r1,r5,#0x0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
movement_with_cpad:
    @ replaced opcodes
    adds    r0,r6,#0x0
    adds    r1,r5,#0x0

    push    {r2-r6, lr}
    @ Get the stick values
    ldr     r4, rtcom_output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    popeq   {r2-r6, pc} @ don't use the CPad if it's not touched

Read_CPAD:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    lsl     r4, #24
    asr     r4, #24
    @ Sign extend Y & negate
    asr     r5, #24
    rsb     r5, #0

    @ set speed
    mov     r1, r4, lsl #5
    mov     r2, r5, lsl #5
    mov     r3, #0
    push    {r1-r3}
    mov     r0, sp
    ldr     r3, vec3d_length_func
    blx     r3
    pop     {r1-r3}
    ldr     r3, =(0x1000 << 12) / (0x69 << 5)
    mul     r0, r3, r0
    mov     r7, r0, asr #12

    @ set direction X and Y
    mov     r0, r4, lsl #5
    mov     r1, r5, lsl #5

    pop     {r2-r6, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2

rtcom_output:       .long 0x02FFFDF0

vec3d_length_func:  .long VEC_LENGTH_FUNC

