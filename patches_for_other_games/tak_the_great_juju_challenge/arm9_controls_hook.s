@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02149820 | 2c 20 80 e5 | str r2,[r0,#0x2c]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
move_with_cpad:
    str     r2,[r0,#0x2c] @ replaced opcode

    push    {r0-r7, lr}
    add     r6, r0, #0x2c @ ptr to Player direction and camera speed  
    add     r7, r5, #0x100

    @ Get the stick values
    ldr     r4, rtcom_output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    
    popeq   {r0-r7, pc} @ don't use the CPad if it's not touched

read_cpad:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    lsl     r4, #24
    asr     r4, #24
    @ Sign extend Y & negate
    asr     r5, #24
    neg     r5, r5

    @ Get direction
    mov     r0, r4
    mov     r1, r5
    ldr     r3, get_angle_func
    blx     r3
    @ rotate 180 degrees
    add     r0, #0x8000 
    lsl     r0, #16
    asr     r0, #16

    @ Rescale thet direction: [0,0xFFFF] => [0,0x6400]
    ldr     r3, =(0x6400 << 12) / 0x10000
    mul     r0, r3, r0
    asr     r0, #12
    strh    r0, dude_direction

    @ Copy camera rotation speed
    ldr     r3, [r6]
    ldrsh   r1, [r3, #2] 
    strh    r1, camera_rot_speed

    @ Swap the pointer to Direction and Camera speed
    adr     r0, dude_direction
    str     r0, [r6]

    pop     {r0-r7, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02145c60 | 24 00 97 e5 | ldr r0,[r7,#0x24]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
move_camera_x:
    ldr     r0, [r7, #0x24] @ overwritten opcode

    ldr     r3, rtcom_output
    ldrsh   r2, [r3, #6] @ CStick X
    rsbs    r2, #0

    lslne   r2, #8
    addne   r0, r2, #0xb800
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02145cd8 | 28 00 97 e5 | ldr r0,[r7,#0x28]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
move_camera_y:
    ldr     r0, [r7, #0x28] @ overwritten opcode

    ldr     r3, rtcom_output
    ldrsh   r2, [r3, #8] @ CStick Y
    rsbs    r2, #0

    lslne   r2, #8
    addne   r0, r2, #0x8600
    bx      lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_maxradius      = 0x69
min_rot_speed       = 0x10

rtcom_output:       .long 0x027ffdf0
get_angle_func:     .long GET_ANGLE_FUNC


dude_direction:     .short  0
camera_rot_speed:   .short  0

