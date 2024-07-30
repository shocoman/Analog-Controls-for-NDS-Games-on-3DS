@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0202657c | 00 30 a0 e3 | mov r3,#0x0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
save_speed:
    str     r9, dude_speed
    mov     r3, #0
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020267e0 | 3c 10 86 e2 | add r1,r6,#0x3c
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
cpad_movement:
    add     r1, r6, #0x3c @ overwritten opcode
    push    {r0-r9, lr}

    @ Get the stick values
    ldr     r4, rtcom_output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    popeq   {r0-r9, pc} @ don't use the CPad if it's not touched

    @ update position.Y 
    ldr     r0, [r6, #0x40]
    add     r0, r3
    str     r0, [r6, #0x40]

    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    lsl     r4, #24
    asr     r4, #24
    @ Sign extend Y & negate
    asr     r5, #24
    rsb     r4, #0

    @ get dude direction angle (from dpad)
    ldr     r7, [r6, #0xfc]
    @ get cpad angle
    mov     r0, r5
    mov     r1, r4
    ldr     r3, get_angle_func
    blx     r3
    @ get sin & cos based on "cpad_angle" + "current_angle"
    sub     r0, r7
    lsl     r0, #16 @ angle & 0xFFFF
    lsr     r0, #16
    @ calculate indexes into the trig lookup table
    asr     r0, #4
    lsl     r2, r0, #1
    lsl     r1, r2, #1  @ sin offset
    add     r2, #1
    lsl     r0, r2, #1  @ cos offset
    @@ Use the lookup table
    ldr     r3, trig_lookup_table
    ldrsh   r9, [r3, r0] @ cos
    ldrsh   r7, [r3, r1] @ sin
    asr     r9, #3
    asr     r7, #3

    @@ get cpad offset length
    mov     r3, #0
    push    {r3-r5}
    mov     r0, sp
    ldr     r3, vec_length_func
    blx     r3
    pop     {r3-r5}
    @@ Calculate the current speed according to the cpad
    ldr     r2, dude_speed
    ldr     r3, cpad_maxradius_ratio
    mul     r0, r2, r0
    mul     r0, r3, r0
    asr     r0, #12

    @@ rescale according to the current speed
    mul     r9, r0, r9
    mul     r7, r0, r7
    @
    ldr     r0, [r6, #0x3c]
    ldr     r1, [r6, #0x44]
    add     r0, r9, asr #12
    add     r1, r7, asr #12
    str     r0, [r6, #0x3c]
    str     r1, [r6, #0x44]

    
    pop     {r0-r9, lr}
    add     lr, #0x2c
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_maxradius          = 0x69
cpad_maxradius_ratio:   .long (1 << 12) / cpad_maxradius

dude_speed:         .long 0

get_angle_func:     .long GET_ANGLE_FUNC
vec_length_func:    .long VEC_LENGTH_FUNC
trig_lookup_table:  .long TRIG_LOOKUP_TABLE

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02026390 | b4 0f d6 e1 | ldrh r0,[r6,#0xf4]
@ r6 - main state
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
control_camera_cstick:
    ldrh    r0, [r6, #0xf4] @ overwritten opcode
    push    {r0-r5, lr}
    
    ldr     r0, rtcom_output
    ldrsh   r1, [r0, #6]
    ldrsh   r2, [r0, #8]

    cmp     r1, #0
    cmpeq   r2, #0
    popeq   {r0-r5, pc}

    neg     r1, r1
    neg     r2, r2
    ldr     r3, sensitivity
    mul     r1, r3, r1
    mul     r2, r3, r2

    ldr     r3, [r6, #0xfc]
    ldr     r4, [r6, #0x104]
    add     r3, r1
    add     r4, r2
    str     r3, [r6, #0xfc]
    str     r4, [r6, #0x104]
    
    mov     r2, #0x1
    str     r2, [r6, #0x270]

    mov     r0, r6
    ldr     r3, update_camera_rotation_func
    blx     r3

    pop     {r0-r5, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
rtcom_output:   .long 0x027ffdf0
sensitivity:    .long 8

update_camera_rotation_func:    .long UPDATE_CAMERA_ROTATION_FUNC

