@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0204727c | 00 10 a0 e3 | mov r1,#0x0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
@ [sp + 8] - Velocity vector
move_with_cpad:
    mov     r1, #0  @ replaced opcode
    
    add     r2, sp, #8  @ get velocity
    push    {r0-r5, lr}

    @ Get the stick values
    ldr     r4, rtcom_output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    
    popeq   {r0-r5, pc} @ don't use the CPad if it's not touched

read_cpad:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    lsl     r4, #24
    asr     r4, #24
    @ Sign extend Y & negate
    asr     r5, #24
    neg     r5, r5

    @ rescale CPad X and Y from [-0x69;0x69] to [-0x1000;0x1000]
    ldr     r3, speed_ratio
    mul     r0, r3, r4
    add     r0, #0x800
    asr     r0, #12
    str     r0, [r2, #0] @ set Velocity.X

    mul     r1, r3, r5
    add     r1, #0x800
    asr     r1, #12
    str     r1, [r2, #8] @ set Velocity.Z

    pop     {r0-r5, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_maxradius      = 0x69
speed_ratio:        .long   ((0x1000 << 12) / cpad_maxradius)

rtcom_output:       .long 0x027ffdf0


