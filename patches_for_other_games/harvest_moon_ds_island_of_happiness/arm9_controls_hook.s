@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02078794 | d8 03 d0 e1 | ldrsb r0,[r0,#0x38]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
fake_touchscreen:
    ldrsb   r0,[r0,#0x38] @ replaced opcode (checking if touchscreen was pressed long enough)

    push    {r1, lr}
    ldr     r1, rtcom_output
    ldrh    r1, [r1, #0]
    cmp     r1, #0
    movne   r0, #5  @ pretend touchscreen is being used
    pop     {r1, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02078828 | 00 10 a0 e1 | mov r1,r0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
move_with_cpad:
    mov     r1, r0 @ replaced opcode
    push    {r0, r2-r3, r6, lr}

    @ Get the stick values
    ldr     r3, rtcom_output
    ldrh    r3, [r3, #0]
    cmp     r3, #0
    
    popeq   {r0, r2-r3, r6, pc} @ don't use the CPad if it's not touched

read_cpad:
    @ Split stick Y and X components
    mov     r5, r3, lsl #16
    @ Sign extend X
    lsl     r4, r3, #24
    asr     r4, #24
    @ Sign extend Y & negate
    asr     r5, #24
    neg     r5, r5

    @ don't yawn while moving
    mov     r0, #0
    add     r1, r6, #0x600
    strh    r0, [r1, #0x3a]

    @ set direction
    mov     r0, r4
    mov     r1, r5
    ldr     r2, get_angle_func
    blx     r2
    mov     r1, r0

    @ set X and Y distance from the center (otherwise the character will run by default) 
    mov     r4, #0
    mov     r5, #0

    pop     {r0, r2-r3, r6, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_maxradius      = 0x69

rtcom_output:       .long 0x027ffdf0
get_angle_func:     .long GET_ANGLE_FUNC


