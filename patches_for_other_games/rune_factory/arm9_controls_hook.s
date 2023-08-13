@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02034b38 | 20 10 85 e5 | str r1, [r5, #0x20]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
@ r5 - Movement State struct
@ r4 - current speed (0x5000 - walking, 0xa000 - running)
move_with_cpad:
    push    {r0-r7, lr}
    str     r1, [r5, #0x20] @ replaced opcode
    mov     r6, r4  @ speed
    mov     r7, r5  @ state

    @ Get the stick values
    ldr     r4, rtcom_output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    
    popeq   {r0-r7, pc} @ don't use the CPad if it's not touched

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

    mul     r0, r6, r4 @ multiply by SPEED
    asr     r0, #12
    str     r0, [r7, #0x18] @ set Speed.X

    mul     r1, r6, r5 @ multiply by SPEED
    asr     r1, #12
    str     r1, [r7, #0x20] @ set Speed.Y

    pop     {r0-r7, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02021924 | 10 20 91 e5 | ldr r2, [r1, #0x10]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
@ Round the angle to nearest 45 degrees (0x2000, i.e. 0 - Down, 0x2000 - Down+Right, 0x4000 - Right, etc)
fix_aiming_square:
    push    {lr}
    ldr     r2, [r1, #0x10] @ replaced opcode (load angle)

    @@ ((Angle & 0xFFFF) + 0x1000) // 0x2000) * 0x2000 
    bic     r2, r2, #0x10000    @ + 360 degrees
    add     r2, #(0x2000 / 2)   @ round to the arest 0x1000
    asr     r2, #13
    lsl     r2, #13

    pop     {pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_maxradius      = 0x69

rtcom_output:       .long 0x027ffdf0
vec_normalize_func: .long VEC_NORMALIZE_FUNC


