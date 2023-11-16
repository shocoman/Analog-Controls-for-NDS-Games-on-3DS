@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0210c1b4 | b1 20 90 e1 | ldrh r2,[r0,r1]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
@ return angle in R2
move_with_cpad:
    ldrh    r2, [r0,r1] @ replaced opcodes
    push    {r0-r1, r3-r5, lr}

    @ Get the stick values
    ldr     r4, rtcom_output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    
    popeq   {r0-r1, r3-r5, pc} @ don't use the CPad if it's not touched

read_cpad:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    lsl     r4, r4, #24
    asr     r4, #24
    @ Sign extend Y
    asr     r5, #24

    mov     r0, r4
    mov     r1, r5
    ldr     r3, vec_angle_func
    blx     r3
    add     r2, r0, #0xC000

    pop     {r0-r1, r3-r5, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_maxradius      = 0x69
speed_ratio:        .long   ((0x1E0 << 12) / cpad_maxradius)

rtcom_output:       .long 0x02FFFDF0

vec_angle_func:     .long VEC_ANGLE_FUNC

