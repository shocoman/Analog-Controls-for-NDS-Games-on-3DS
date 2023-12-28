@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
@ 020aeed8 | b0 20 d0 e1 | ldrh r2,[r0,#0x0]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
is_moving_a:
    ldrh    r2, [r0,#0x0] @ overwritten opcode

    push    {r0-r1, r3-r6, lr}
    mov     r6, r0  @ currenly pressed keys

    mov     r4, r2
    bl      __read_stick
    
    cmp     r0, #0
    moveq   r2, r4
    beq     is_moving_a__end

    @ simulate DPad with the stick (otherwise the game might glitch when exiting a shop and force you back in)
    mov     r5, #0
    @ check X
    cmp     r1, #0
    orrlt   r5, #0x20
    orrgt   r5, #0x10
    @ check Y
    cmp     r2, #0
    orrlt   r5, #0x40
    orrgt   r5, #0x80

    strh    r5, [r6]
    mov     r2, r5

is_moving_a__end:
    pop     {r0-r1, r3-r6, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
@ 020b2878 | b0 10 d1 e1 | ldrh r1,[r1,#0x0]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
is_moving_b:
    ldrh    r1,[r1,#0x0] @ overwritten opcode

    push    {r0, r2-r5, lr}
    mov     r4, r1
    bl      __read_stick
    cmp     r0, #0
    mov     r1, r4
    movne   r1, #0x20
    pop     {r0, r2-r5, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
@ 020b288c | b8 1a d7 e1 | ldrh r1,[r7,#0xa8]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ r0 - new angle
move_with_cpad:
    ldrh    r1, [r7, #0xa8]   @ put back the replaced instructions

    push    {r1-r5, lr}
    mov     r4, r0
    bl      __read_stick
    cmp     r0, #0
    moveq   r0, r4
    popeq   {r1-r5, pc} @ don't use the stick if it's not touched

    @@ Get new direction
    mov     r0, r2
    mov     r1, r1
    ldr     r2, get_angle_func
    blx     r2

    pop     {r1-r5, pc}



@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0208f8dc | 06 00 a0 e3 | mov r0, #0x6
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
combat_is_moving_a:
    mov     r0, #0x6 @ overwritten opcode
    push    {r0-r5, lr}
    bl      __read_stick
    cmp     r0, #0
    pop     {r0-r5, lr}

    addne   lr, #0x98
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02090868 | 06 00 a0 e3 | mov r0,#0x6
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
combat_is_moving_b:
    mov     r0, #0x6 @ overwritten opcode
    push    {r0-r5, lr}
    bl      __read_stick
    cmp     r0, #0
    pop     {r0-r5, lr}

    addne   lr, #0xC
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020906c8 | 01 00 a0 e3 | mov r0,#0x1
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ r6 - game state
combat_movement:
    mov     r0, #0x1 @ overwritten opcode

    push    {r0-r5, lr}
    bl      __read_stick
    cmp     r0, #0
    popeq   {r0-r5, pc}
   
    mov     r3, #0
    mov     r4, r1
    mov     r5, r2


    @@ normalize the stick values into the range [-(0x1000 * 32);(0x1000 * 32)] (more or less arbitrary chosen)
    push    {r3-r5}
    mov     r0, sp
    mov     r1, sp
    ldr     r2, vec_normalize_func
    blx     r2
    pop     {r3-r5}

    @ restrict stick.Y (otherwise the character just stops at times for some reason)
    cmp     r5, #0x20
    movls   r5, #0x20


    @ set the target ("touch") position relative to the main character's one
    ldr     r0, [r6, #0x28] @ dude pos X
    ldr     r1, [r6, #0x2C] @ dude pos Y
    add     r0, r4, lsl #5
    add     r1, r5, lsl #5
    str     r0, [r6, #0x1d4] @ target pos X
    str     r1, [r6, #0x1d8] @ target pos Y

    @ hide the target marker
    ldr     r1, [r6, #0x1d0]
    bic     r1, r1, #0x2
    str     r1, [r6, #0x1d0]

    pop     {r0-r5, lr}
    addne   lr, #0x7C
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ Read either CPad or CStick (if the CPad isn't touched)
@ Return values:
@  r0 - whether CPad or CStick is being used ('0' - isn't used, everything else - is used)
@  r1 - CPad.X or CStick.X
@  r2 - CPad.Y or CStick.Y
__read_stick:
    push    {r3-r4, lr}

    @ check CPad
    ldr     r4, rtcom_output
    ldrh    r0, [r4]
    cmp     r0, #0
    bne     __read_stick__cpad

    @ check CStick
    ldrsh   r1, [r4, #6] @ CStick X
    ldrsh   r2, [r4, #8] @ CStick Y
    lsl     r1, #3
    lsl     r2, #3
    rsb     r1, #0
    orr     r0, r1, r2
    pop     {r3-r4, pc}

__read_stick__cpad:
    @ Split stick Y and X components
    mov     r2, r0, lsl #16
    @ Sign extend X
    mov     r1, r0, lsl #24
    mov     r1, r1, asr #24
    @ Sign extend Y & negate
    mov     r2, r2, asr #24
    rsb     r2, #0

    pop     {r3-r4, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
CPAD_MaxRadius = 0x69
rtcom_output:           .long 0x027ffdf0

get_angle_func:         .long GET_ANGLE_FUNC
vec_normalize_func:     .long VEC_NORMALIZE_FUNC
