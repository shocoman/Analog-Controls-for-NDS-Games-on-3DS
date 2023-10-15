@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0201c4f8 | 14 05 94 e5 | ldr r0,[r4,#0x514]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
@ r7 - speed
move_with_cpad:
    ldr     r0, [r4, #0x514] @ replaced opcode

    add     r1, sp, #0x138
    push    {r0-r6, lr}
    mov     r6, r1      @ ptr to velocity vector

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

    @@ Calculate the cpad's angle
    mov     r0, r4
    mov     r1, r5
    ldr     r3, get_angle_func
    blx     r3

    @@ Sum the angles and calculate the offsets for sine and cosine to get the final direction
    lsl     r0, #16 @ angle & 0xFFFF
    lsr     r0, #16
    
    asr     r0, #4
    lsl     r2, r0, #1
    lsl     r1, r2, #1  @ sin offset
    add     r2, #1
    lsl     r0, r2, #1  @ cos offset

    @@ Use the lookup table
    ldr     r3, sin_cos_lookup_table
    ldrsh   r0, [r3, r0] @ cos
    ldrsh   r1, [r3, r1] @ sin

    @@ Multiply by speed
    mul     r0, r7, r0
    add     r0, #0x800
    asr     r0, #12
    mul     r1, r7, r1
    add     r1, #0x800
    asr     r1, #12

    @@ Write the values (X and Y are flipped)
    str     r1, [r6, #0] @ set Velocity.X
    str     r0, [r6, #8] @ set Velocity.Z

    pop     {r0-r6, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_maxradius      = 0x69

rtcom_output:           .long 0x027ffdf0

get_angle_func:         .long GET_ANGLE_FUNC
sin_cos_lookup_table:   .long SIN_COS_LOOKUP_TABLE
