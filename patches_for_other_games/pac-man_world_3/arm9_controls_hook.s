@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02023114 | 00 00 50 e3 | cmp r0,#0x0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
move_with_cpad:
    push    {r0-r7, lr}

    @ Get the stick values
    ldr     r4, rtcom_output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    bne     move_with_cpad__read_cpad

    str     r4, backup_cpad
    cmp     r0, #0x0
    pop     {r0-r7, pc} @ don't use the CPad if it's not touched

move_with_cpad__read_cpad:
    @@ Calculate camera's angle
    ldr     r0, [sp, #4*9]     @ ForwardVec.X
    ldr     r1, [sp, #4*9 + 8] @ ForwardVec.Z
    ldr     r3, get_angle_func
    blx     r3
    mov     r6, r0  @ camera view's angle

    @@ Extract the CPad's values
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X & negate
    mov     r4, r4, lsl #24
    mov     r4, r4, asr #24
    rsb     r4, #0
    @ Sign extend Y
    mov     r5, r5, asr #24
    @ Backup for the next routine
    strh    r4, backup_cpad
    strh    r5, backup_cpad+2

    @@ Calculate the cpad's angle
    mov     r0, r4
    mov     r1, r5
    ldr     r3, get_angle_func
    blx     r3

    @@ Sum the angles and calculate the offsets for sine and cosine to get the final direction
    add     r0, r6  @ final angle = camera's angle + cpad's angle
    lsl     r0, #16 @ angle & 0xFFFF
    lsr     r0, #20
    lsl     r2, r0, #1
    lsl     r1, r2, #1  @ sin offset
    add     r2, #1
    lsl     r0, r2, #1  @ cos offset

    @@ Use the lookup table
    ldr     r3, sin_cos_lookup_table
    ldrsh   r0, [r3, r0] @ cos
    ldrsh   r1, [r3, r1] @ sin
    
    @@ Write the values (X and Y are flipped)
    str     r1, [sp, #4*9 + 12]    
    str     r0, [sp, #4*9 + 12 + 8]

    pop     {r0-r7, lr}
    
.if GET_ANGLE_FUNC == 0x02002c90
    add     lr, #0x70   @ USA version
.else
    add     lr, #0x68   @ Europe version
.endif

    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02022cf4 | 21 10 81 E2 | add r1, #0x21    @ walk
@ 02022ba0 | 85 1f a0 e3 | mov r1, #0x214   @ jump
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
.thumb
control_speed_with_cpad__jumping:
    mov     r1, #0x85
    lsl     r1, #2
    b       control_speed_with_cpad
control_speed_with_cpad__walking:
    add     r1, #0x21 @ overwritten opcode
control_speed_with_cpad:
    push    {r0, r2-r6, lr}
    ldr     r4, backup_cpad
    cmp     r4, #0
    beq     control_speed_with_cpad__end

    @@ get CPad
    asr     r5, r4, #16
    lsl     r4, #16
    asr     r4, #16

    @@ Sqrt of CPad vector
    mul     r4, r4
    mul     r5, r5
    add     r0, r4, r5
    ldr     r3, sqrt_func
    blx     r3

    @@ Rescale [0;0x69] => [0; 0x214]
    ldr     r1, cpad_speed_ratio
    mul     r1, r0, r1
    mov     r2, #100  @ r2 = 800
    lsl     r2, #3
    add     r1, r2
    asr     r1, #18
control_speed_with_cpad__end:
    pop     {r0, r2-r6, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
CPAD_MAXRADIUS          = 0x69
PACMAN_MAXSPEED         = 0x214
rtcom_output:           .long 0x027ffdf0

cpad_speed_ratio:       .long (PACMAN_MAXSPEED << 12) / CPAD_MAXRADIUS
backup_cpad:            .long 0

get_angle_func:         .long GET_ANGLE_FUNC
sin_cos_lookup_table:   .long SINCOS_LOOKUP_TABLE
sqrt_func:              .long SQRT_FUNC_ADDR
