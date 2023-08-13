@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02013610 | 00 00 8d e2 | add r0, sp, #0x0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    

move_with_cpad:
    mov     r0, sp @ replaced opcode
    push    {r0-r6, lr}
    mov     r6, r0 @ Velocity vector

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


    @@ Normalize and rescale according to the current CPad direction
    mov     r3, #0
    push    {r3-r5}
    mov     r0, sp
    mov     r1, sp
    ldr     r2, vec_normalize_func
    blx     r2
    pop     {r3-r5}

    @@ Set arbitrary high speed, it will be renormalized later anyway
    mov     r3, #0x4000 
    mul     r0, r3, r4
    asr     r0, #12
    str     r0, [r6, #0] @ set Speed.X

    mul     r1, r3, r5
    asr     r1, #12
    str     r1, [r6, #8] @ set Speed.Y

    pop     {r0-r6, pc}



@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_maxradius      = 0x69

rtcom_output:       .long 0x027ffdf0
vec_normalize_func: .long VEC_NORMALIZE_FUNC


