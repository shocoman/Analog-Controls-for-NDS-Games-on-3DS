@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 021cfa44 | f0 00 00 e2 | and r0,r0,#0xf0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
cpad_movement:
    and     r0, #0xf0 @ replaced opcode

    push    {r1-r4, r6-r7, lr}
    @ Get the stick values
    ldr     r6, rtcom_output
    ldrsh   r7, [r6, #6] @ CStick X
    ldrh    r6, [r6]
    cmp     r6, #0
    popeq   {r1-r4, r6-r7, pc}

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
    mov     r5, r0  @ return angle in R5

    @ return camera rotation change in R0
    ldr     r3, cam_speed_ratio
    rsb     r0, r6, #0
    mul     r0, r3, r0
    @ don't rotate camera automatically while turning it with CStick
    cmp     r7, #0
    movne   r0, #0

    pop     {r1-r4, r6-r7, lr}
    add     lr, #0xD8
    bx      lr
    

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 021cfb98 | 00 40 a0 e1 | cpy r4,r0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
cstick_camera:
    mov     r4, r0 @ replaced opcodes
    push    {r1-r3, lr}

    ldr     r1, rtcom_output
    ldrsh   r2, [r1, #6] @ CStick X
    cmp     r2, #0
    popeq   {r1-r3, pc}

    mov     r1, #0x200
    mul     r0, r2, r1
    ldr     r3, update_camera_angle_func
    blx     r3

    pop     {r1-r3, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

cpad_maxradius              = 0x69

cam_speed_ratio:            .long 0x2800 / cpad_maxradius
radians_to_degrees_ratio:   .long (180 * (1 << 12)) / 0x3244

rtcom_output:               .long 0x027ffdf0
get_angle_func:             .long GET_ANGLE_FUNC
update_camera_angle_func:   .long UPDATE_CAMERA_ANGLE
