@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02040b8c | b0 30 c2 e1 | strh r3,[r2,#0x0]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
move_with_cpad:

    strh    r3, [r2] @ replaced opcode
    mov     r2, sp   @ pointer to turning a wheel angle

    push    {r0-r7, lr}
    mov     r7, r2  @ angle

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

    @ limit the minimum angle (for responsiveness)
    cmp     r4, #min_rot_speed
    movls   r4, #min_rot_speed
    cmp     r4, #-min_rot_speed
    movcs   r4, #-min_rot_speed

    @ set car turning speed
    strb    r4, [r7]

    @ set the angle for the wheel image on the bottom screen
    ldr     r0, =0x020b9f74 
    strh    r4, [r0]
    strh    r4, [r0, #0x10]

    @ unpress DPad (if CPad is still emulating it)
    ldrb    r4, [r7, #2]
    bic     r4, #0xF0   
    strb    r4, [r7, #2]

    pop     {r0-r7, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_maxradius      = 0x69
min_rot_speed       = 0x10

rtcom_output:       .long 0x027ffdf0


