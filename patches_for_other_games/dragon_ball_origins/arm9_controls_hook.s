@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0201f4a0 | 84 21 9d e5 | ldr r2,[sp,#0x184]   @ entry A
@ 02020050 | 7c 21 9d e5 | ldr r2,[sp,#0x17c]   @ entry B
@ 02020e2c | bc 20 9d e5 | ldr r2,[sp,#0xbc]    @ entry C
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
entry_a:
    add     r3, sp, #0x184  @ Velocity vector
    b       main
entry_b:
    add     r3, sp, #0x17c
    b       main
entry_c:
    add     r3, sp, #0xbc

main:
    ldr     r2, [r3] @ replaced opcode

    push    {r0-r1, r3-r6, lr}
    mov     r6, r3      @ ptr to velocity vector

    @ Get the stick values
    ldr     r4, rtcom_output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    
    popeq   {r0-r1, r3-r6, pc} @ don't use the CPad if it's not touched

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
    add     r0, #0x2000 @ rotate 45 degrees
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

    @@ Rescale: (-0x1000,0x1000) => (-0x6400,0x6400)
    mov     r2, #0x6400
    mul     r0, r2, r0
    mul     r1, r2, r1
    asr     r0, #12
    asr     r1, #12

    @@ Write the values (X and Y are flipped)
    str     r1, [r6, #0] @ set Velocity.X
    str     r0, [r6, #8] @ set Velocity.Z

    mov     r2, r1  @ return Velocity.X
    pop     {r0-r1, r3-r6, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_maxradius      = 0x69

rtcom_output:           .long 0x027ffdf0

get_angle_func:         .long GET_ANGLE_FUNC
sin_cos_lookup_table:   .long SIN_COS_LOOKUP_TABLE
