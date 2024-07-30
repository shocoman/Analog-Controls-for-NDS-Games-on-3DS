@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0206c938 | 88 63 | str r0,[r1,#0x38]
@ 0206c93a | 28 69 | ldr r0,[r5,#0x10]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
move_with_cpad:
    @ overwritten opcodes
    str     r0,[r1,#0x38]
    ldr     r0,[r5,#0x10]

    mov     r2, sp
    push    {r0-r9, lr}
    mov     r8, r1
    mov     r6, r2  @ original stack pointer

    @ Get the stick values
    ldr     r4, rtcom_output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    
    popeq   {r0-r9, pc} @ don't use the CPad if it's not touched

read_cpad:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    lsl     r4, #24
    asr     r4, #24
    @ Sign extend Y
    asr     r5, #24

    @ get dude direction angle (from dpad)
    ldr     r1, [r6, #0x10]
    mov     r0, r7
    ldr     r3, get_angle_function
    blx     r3
    mov     r7, r0
    @ get cpad angle
    mov     r0, r5
    mov     r1, r4
    ldr     r3, get_angle_function
    blx     r3
    @ get sin & cos based on "cpad_angle" + "current_angle"
    add     r0, r7
    sub     r0, #0x4000
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

    @@ scale sin & cos according to the current speed and the cpad offset
    @ calculate Cpad offset
    mul     r0, r4, r4
    mla     r0, r5, r5, r0
    ldr     r3, sqrt_function
    blx     r3

    ldr     r1, [r6, #0x14] @ current speed
    ldr     r3, cpad_maxradius_ratio
    mul     r0, r1, r0
    mul     r0, r3, r0
    asr     r0, #18
    @ scale sin & cos (new "dx" and "dy")
    mul     r1, r0, r9 @ cos
    mul     r2, r0, r7 @ sin

    str     r1, [r8, #0x30]
    str     r2, [r8, #0x34]

    pop     {r0-r9, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0202acb8 | 00 00 54 e3 | cmp r4,#0x0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
cstick_camera_control:
    push    {r0-r9, lr}

    @ Get the CStick X and Y values
    ldr     r0, rtcom_output
    ldrsh   r2, [r0, #6] @ CStick.X
    ldrsh   r3, [r0, #8] @ CStick.Y
    rsb     r2, #0
    cmp     r2, #0
    cmpeq   r3, #0
    popeq   {r0-r9, pc}

    @ get current camera speed
    ldr     r5, [r6, #0x40]
    asr     r5, #5
    @ rescale CStick
    ldr     r0, [r6, #0x30] @ current camera.x
    ldr     r1, [r6, #0x3C] @ current camera.y
    mla     r0, r2, r5, r0  @ cam.x += speed * cstick.x
    mla     r1, r3, r5, r1  @ cam.y += speed * cstick.y
    str     r0, [r6, #0x30] @ current camera.x
    str     r1, [r6, #0x3C] @ current camera.y

    cmp     r6, #0
    pop     {r0-r9, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_maxradius  = 0x69

cpad_maxradius_ratio:   .long (1 << 12) / cpad_maxradius

rtcom_output:           .long 0x027ffdf0
sqrt_function:          .long SQRT_FUNCTION
get_angle_function:     .long GET_ANGLE_FUNCTION
trig_lookup_table:      .long TRIG_TABLE




