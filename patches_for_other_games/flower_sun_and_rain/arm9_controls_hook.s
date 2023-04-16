@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0202891e | c0 6e | ldr r0, [r0, #0x6c]
@ 02028920 | 00 28 | cmp r0, #0x0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
movement_with_cpad:
    push    {r1-r6, lr}
    mov     r6, r0
    ldr     r0, [r0, #0x6c]

    @ Get the stick values
    ldr     r4, rtcom_output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    bne     read_cpad

    cmp     r0, #0x0
    pop     {r1-r6, pc} @ don't use the CPad if it's not touched

read_cpad:
    @ Split stick Y and X components
    mov     r5, r4
    @ Sign extend X
    lsl     r4, #24
    asr     r4, #24
    @ Sign extend Y & negate
    lsl     r5, #16
    asr     r5, #24
    neg     r5, r5

    @@ 1) CPad's angle
    str     r4, [r6, #0x70] @ TOUCH_JOYSTICK_X
    str     r5, [r6, #0x74] @ TOUCH_JOYSTICK_Y
    
    @@ 2) Speed (CPad's length)
    mov     r3, #0
    push    {r3-r5} @ vector's (X, Y, Z)
    mov     r0, sp
    ldr     r3, vec_length_func
    blx     r3
    add     sp, #0xC

    @@ Set Move Speed: 0 = DPad run, 1 = Touchscreen Walking, 2 = Touchscreen Running
    cmp     r0, #(cpad_maxradius * 3) / 5
    movlt   r0, #1 @ walk
    movge   r0, #2 @ run
    str     r0, [r6, #0x6c] 

    cmp     r0, #0x0
    pop     {r1-r6, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_maxradius = 0x69
rtcom_output:               .long 0x027ffdf0
vec_length_func:            .long VECTOR_LENGTH_FUNC
