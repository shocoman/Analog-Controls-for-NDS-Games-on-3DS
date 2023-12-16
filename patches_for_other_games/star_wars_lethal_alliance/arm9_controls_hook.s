@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02121838 | 7c 00 8d e2 | add r0,sp,#0x7c
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
move_with_cpad_a:
    add     r0, sp, #0x7c @ replaced opcode

    push    {r0-r6, lr}
    add     r6, r4, #0x148  @ velocity

    @ Get the stick values
    ldr     r4, rtcom_output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    popeq   {r0-r6, pc} @ don't use the CPad if it's not touched

    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    lsl     r4, #24
    asr     r4, #24
    neg     r4, r4
    @ Sign extend Y & negate
    asr     r5, #24
    neg     r5, r5

    mov     r3, #0
    push    {r3-r5}
    mov     r0, sp
    mov     r1, sp
    ldr     r2, vec3d_normalize
    blx     r2
    pop     {r3-r5}

    str     r4, [r6]
    str     r5, [r6, #4]

    pop     {r0-r6, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02121d10 | b8 10 9d e5 | ldr r1,[sp,#0xb8]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
move_with_cpad_b:
    ldr     r1,[sp,#0xb8] @ replaced opcode

    add     r2, sp, #0xb4   @ velocity
    push    {r0, r2-r6, lr}
    mov     r6, r2  @ velocity

    @ Get the stick values
    ldr     r4, rtcom_output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    popeq   {r0, r2-r6, pc} @ don't use the CPad if it's not touched

    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    lsl     r4, #24
    asr     r4, #24
    @ Sign extend Y
    asr     r5, #24

    mov     r3, #0
    push    {r3-r5}
    mov     r0, sp
    mov     r1, sp
    ldr     r2, vec3d_normalize
    blx     r2
    pop     {r3-r5}

    str     r5, [r6]
    str     r4, [r6, #4]

    mov     r1, r4
    pop     {r0, r2-r6, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_maxradius      = 0x69

rtcom_output:       .long 0x027ffdf0
vec3d_normalize:    .long VEC_NORMALIZE
