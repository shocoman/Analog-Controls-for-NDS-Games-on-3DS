@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0214e00c | 28 1c | adds r0,r5,#0x0
@ 0214e00e | 64 30 | adds r0,#0x64
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
@ r4 - speed
move_with_cpad:
    @ replaced opcodes
    adds    r0, r5, #0x0
    adds    r0, #0x64
    
    add     r2, sp, #0xd8  @ get velocity
    push    {r0-r3,r5-r7, lr}
    mov     r6, r2

    @ Get the stick values
    ldr     r7, rtcom_output
    ldrh    r7, [r7, #0]
    cmp     r7, #0
    
    popeq   {r0-r3,r5-r7, pc} @ don't use the CPad if it's not touched

read_cpad:
    @ Split stick Y and X components
    mov     r5, r7, lsl #16
    @ Sign extend X
    lsl     r4, r7, #24
    asr     r4, #24
    @ Sign extend Y & negate
    asr     r5, #24
    neg     r5, r5

    mov     r3, #0
    push    {r3-r5}

    @@ set speed (rescale from [0;0x69] to [0x20;0x200])
    mov     r0, sp
    ldr     r2, vec_length_func
    blx     r2
    mov     r4, r0
    
    ldr     r0, speed_ratio
    mul     r4, r0, r4
    add     r4, #0x800
    asr     r4, #0xC
    add     r4, #0x20


    @@ set velocity (direction)
    mov     r0, sp
    mov     r1, sp
    ldr     r2, vec_normalize_func
    blx     r2
    pop     {r0-r2}

    str     r1, [r6, #0] @ set Velocity.X
    str     r2, [r6, #8] @ set Velocity.Z

    pop     {r0-r3,r5-r7, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_maxradius      = 0x69
speed_ratio:        .long   ((0x1E0 << 12) / cpad_maxradius)

rtcom_output:       .long 0x02FFFDF0

vec_normalize_func: .long VEC_NORMALIZE_FUNC
vec_length_func:    .long VEC_LENGTH_FUNC

