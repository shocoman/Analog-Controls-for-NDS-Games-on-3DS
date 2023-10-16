@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02013e18 | 14 00 8d e2 | add r0, sp, #0x14
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ r1 - pointer to Velocity vector
movement:
    add     r0, sp, #0x14 @ replaced opcode

    push    {r0-r6, lr}
    mov     r6, r1 @ "velocity" pointer

    @ Read CPad or CStick
    mov     r0, #0
    bl      read_sticks_func
    cmp     r0, #0
    cmpeq   r1, #0
    popeq   {r0-r6, pc}

    @ Set velocity (direction)
    stm     r6, {r0-r1}

    pop     {r0-r6, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02013eb4 | ec c0 8d e5 | str r12,[sp,#0xec]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
firing:
    str     r12, [sp, #0xec] @ replaced opcode

    add     r2, sp, #0xec @ ptr to the direction vector (Y and X)
    push    {r0-r6, lr}
    mov     r6, r2

    @ Read CPad or CStick
    mov     r0, #1
    bl      read_sticks_func
    cmp     r0, #0
    cmpeq   r1, #0
    popeq   {r0-r6, pc}

    @ Normalize the direction vector
    mov     r2, #0
    push    {r0-r2}
    mov     r0, sp
    mov     r1, sp
    ldr     r2, vec_normalize_func
    blx     r2
    pop     {r0-r2}

    str     r0, [r6, #4] @ set direction.X
    str     r1, [r6, #0] @ set direction.Y

    pop     {r0-r6, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Read values from CPad or CStick depending on the Options (Left/Right handness)
@ r0 = 0 - for Movement
@ r0 = 1 - for Firing
read_sticks_func:
    @ get Options index
    ldr     r3, =0x021A8C8C
    ldrsh   r3, [r3, #8]

    @ check if "Handed" in Options set to Right or Left
    ldr     r2, =0x021AAEE4
    mov     r1, #0xb8                    
    mla     r3, r1, r3, r2                       
    ldr     r3, [r3, #0xa8] @ get "Handed"; bit 2 is either 0 (Right) or 1 (Left)

    eor     r3, r0, lsl #1
    tst     r3, #2
    bne     read_cstick

read_cpad:
    ldr     r0, rtcom_output
    ldrh    r0, [r0, #0]

    @ Split CPad Y and X components
    mov     r1, r0, lsl #16
    @ Sign extend X
    lsl     r0, #24
    asr     r0, #24
    @ Sign extend Y & negate
    asr     r1, #24
    neg     r1, r1
    bx      lr

read_cstick:
    ldr     r0, rtcom_output
    ldrsh   r1, [r0, #8] @ CStick Y
    ldrsh   r0, [r0, #6] @ CStick X
    neg     r0, r0
    bx      lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_maxradius = 0x69
rtcom_output:               .long 0x027ffdf0

vec_normalize_func:         .long VECTOR_NORMALIZE_FUNC

