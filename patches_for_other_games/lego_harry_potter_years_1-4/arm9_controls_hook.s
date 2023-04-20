@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0204b348 | 09 10 d0 e7 | ldrb r1,[r0,r9]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
set_direction:
    ldrb    r1, [r0,r9] @ overwritten opcode
    push    {r0, r2-r6, lr}

    mov     r5, #0
    str     r5, current_speed_var

    @ Get the stick values
    ldr     r4, rtcom_output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    beq     set_direction__end @ don't use the CPad if it's not touched

    @ Split stick Y and X components
    mov     r6, r4, lsl #16
    @ Sign extend X
    mov     r4, r4, lsl #24
    mov     r4, r4, asr #24
    @ Sign extend Y
    mov     r6, r6, asr #24

    @@ Get Speed (part 1)
    @ get CPad length
    push    {r4,r6}
    mov     r0, sp
    ldr     r3, vector2d_length_func
    blx     r3
    str     r0, current_speed_var

    @@ Get Direction
    push    {r5} @ r5 is 0
    push    {r5}
    push    {r5}
    mov     r0, sp      @ Center: (0, 0, 0)
    push    {r4-r6}     
    mov     r1, sp      @ Cpad:   (CPad.x, 0, CPad.y)
    ldr     r3, direction_between_points_func
    blx     r3

    add     sp, #6*4 + 2*4 @ restore stack
    mov     r1, r0 @ return angle in R1
set_direction__end:
    pop     {r0, r2-r6, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0204b3a4 | 34 00 88 e5 | str r0,[r8,#0x34]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
set_speed:
    push    {lr}
    ldr     r2, current_speed_var
    cmp     r2, #0
    beq     set_speed__end

    @@ Get Speed (part 2). Rescaling from [-cpad; +cpad] to [-max_speed; +max_speed]
    @ divide speed by cpad max radius
    ldr     r3, speed_multiplier
    mul     r2, r3, r2
    @ multiply by the current max speed
    mul     r2, r0, r2
    add     r2, #800
    asr     r2, #12

    @ clamp the speed
    cmp     r2, r0
    movlt   r0, r2 

set_speed__end:
    str     r0, [r8, #0x34] @ overwritten opcode
    pop     {pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
CPAD_MAXRADIUS = 0x69

rtcom_output:       .long 0x02fffdf0
current_speed_var:  .long 0
speed_multiplier:   .long (1 << 12) / (CPAD_MAXRADIUS - 5) @ "-5" to achieve higher speed a bit easier

direction_between_points_func:  .long DIRECTION_BETWEEN_POINTS_FUNC @ 0x020eccbc
vector2d_length_func:           .long VECTOR2D_LENGTH_FUNC @ 0x020be4b8
