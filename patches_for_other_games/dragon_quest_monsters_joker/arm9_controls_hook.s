@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 021d7bb0 | 00 00 50 e3 | cmp r0,#0x0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
cpad_movement:
    push    {r1-r3, r5-r7, lr}
    @ Get the stick values
    ldr     r6, rtcom_output
    ldrsh   r7, [r6, #6] @ CStick X
    ldrh    r6, [r6]
    cmp     r6, #0
    bne     read_cpad

    cmp     r0, #0x0
    pop     {r1-r3, r5-r7, pc}

read_cpad:
    @ Split stick Y and X components
    mov     r5, r6, lsl #16
    @ Sign extend X
    lsl     r6, #24
    asr     r6, #24
    @ Sign extend Y & negate
    asr     r5, #24
    rsb     r5, #0

    @@ Get movement direction
    mov     r0, r6
    mov     r1, r5
    ldr     r5, get_angle_func
    blx     r5

    ldr     r3, radians_to_degrees_ratio
    mul     r0, r3, r0
    mov     r4, r0  @ return angle in R4

    @ return camera rotation change in R0
    ldr     r3, cam_speed_ratio
    rsb     r0, r6, #0
    mul     r0, r3, r0
    @ don't rotate camera automatically while turning it with CStick
    cmp     r7, #0
    movne   r0, #0
    cmp     r0, #0

    pop     {r1-r3, r5-r7, pc}
    

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 021d7c44 | 03 0c 08 e2 | and r0,r8,#0x300
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
cstick_camera:
    and     r0, r8, #0x300 @ replaced opcodes
    push    {r1-r2, lr}

    ldr     r1, rtcom_output
    ldrsh   r2, [r1, #6] @ CStick X
    cmp     r2, #0
    popeq   {r1-r2, pc}

    mov     r1, #0x200
    mul     r0, r2, r1

    pop     {r1-r2, lr}
    add     lr, #0x10
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

cpad_maxradius              = 0x69

cam_speed_ratio:            .long 0x2800 / cpad_maxradius
radians_to_degrees_ratio:   .long (180 * (1 << 12)) / 0x3244

rtcom_output:               .long 0x027ffdf0
get_angle_func:             .long GET_ANGLE_FUNC
