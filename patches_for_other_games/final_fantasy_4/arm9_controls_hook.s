@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02116c86 | 40 58 | ldr    r0,[r0,r1]
@ 02116c88 | 00 04 | lsls   r0,r0,#0x10
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
move_with_cpad:
    push    {r1-r6, lr}
    mov     r6, r0 @ ptr to (camera_angle - 0x8000)

    @ Get the stick values
    bl      __get_cpad_angle
    cmp     r0, #-1

    ldreq   r0, [r6, r1]
    lsleq   r0, r0, #0x10
    popeq   {r1-r6, pc}

    @ add camera angle
    ldr     r6, [r6]
    add     r0, r6
    lsl     r0, #0x10

    pop     {r1-r6, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0211ff9e | e8 6b | ldr r0,[r5,#0x3c]
@ 0211ffa0 | 80 6e | ldr r0,[r0,#0x68]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
ship_set_dir:
    @ overwritten opcodes
    ldr     r0,[r5,#0x3c]
    ldr     r0,[r0,#0x68]

    push    {r0-r6, lr}
    mov     r6, lr
    bl      __get_cpad_angle
    cmp     r0, #-1
    popeq   {r0-r6, pc}

    @ set ship direction
    .if IS_TOUCHSCREEN_PRESSED == 0x0204D73C
        @ Japan
        ldr     r6, [r6, #0x107]
        str     r0, [r6]
    .else
        @ USA and Europe
        ldr     r6, [r6, #0x105]
        str     r0, [r6, #0x14]
    .endif
    pop     {r0-r6, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0211fca6 | 2a f7 20 eb | blx isTouchscreenPressed
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
fake_touchscreen_press:
    @ Get the stick values
    ldr     r3, rtcom_output
    ldrh    r3, [r3]
    cmp     r3, #0

    movne   r0, #1
    bxne    lr

    ldr     r2, is_touchscreen_pressed_func
    bx      r2

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
__get_cpad_angle:
    @ Get the stick values
    ldr     r0, rtcom_output
    ldrh    r0, [r0]
    cmp     r0, #0
    moveq   r0, #-1
    bxeq    lr
    @ Split stick Y and X components
    mov     r1, r0, lsl #16
    @ Sign extend X
    mov     r0, r0, lsl #24
    mov     r0, r0, asr #24
    @ Sign extend Y
    mov     r1, r1, asr #24
    rsb     r1, #0
    @ Get angle
    ldr     r2, get_angle_func
    bx      r2

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

rtcom_output:                   .long 0x027ffdf0
get_angle_func:                 .long GET_ANGLE_FUNC
is_touchscreen_pressed_func:    .long IS_TOUCHSCREEN_PRESSED

