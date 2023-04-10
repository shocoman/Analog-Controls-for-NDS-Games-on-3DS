@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020d83bc | 94 10 21 e0 | mla  r1,r4,r0,r1
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
LoadValueFromStick:
    push    {r0-r5, lr}

    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    bne     Read_CPAD

    pop     {r0-r5, lr}
    mla     r1,r4,r0,r1
    bx      lr

Read_CPAD:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    mov     r4, r4, lsl #24
    mov     r4, r4, asr #24
    @ Sign extend Y
    mov     r5, r5, asr #24
    rsb     r5, #0

    @@ Remap X and Y components from (0; CPAD_MaxRadius) to (0; Dude's max radius)
    ldr     r3, CPAD_to_DudeStick_Ratio
    mul     r0, r3, r4
    mul     r2, r3, r5
    @ the result is in the FP form

    mov     r1, #0
    str     r0, [sp, #28]
    str     r1, [sp, #32]
    str     r2, [sp, #36]

    pop     {r0-r5,lr}
    mov     r1, sp  @ SP points to the direction vector
    bx      lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

CPAD_MaxRadius            = 0x69
Dude_Stick_MaxRadius      = 0x64
CPAD_to_DudeStick_Ratio:  .long (Dude_Stick_MaxRadius << 12) / CPAD_MaxRadius

RTCom_Output: .long 0x027ffdf0


