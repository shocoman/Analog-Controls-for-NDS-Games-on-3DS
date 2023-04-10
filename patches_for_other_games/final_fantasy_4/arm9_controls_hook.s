@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02116c88 | 00 04 | lsls   r0,r0,#0x10
@ 02116c8a | 03 0c | lsrs   r3,r0,#0x10
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
LoadValueFromStick:
    push    {r0-r2,r4-r5, lr}

    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    bne     Read_CPAD

    lsl     r0, r0, #0x10
    lsr     r3, r0, #0x10
    pop     {r0-r2,r4-r5, pc}

Read_CPAD:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    mov     r4, r4, lsl #24
    mov     r4, r4, asr #24
    @ Sign extend Y
    mov     r5, r5, asr #24
    rsb     r5, #0

    @@ 1) Get direction
    mov     r0, r4
    mov     r1, r5
    ldr     r5, GetAngle_Func
    blx     r5

    mov     r3, r0 @ result in R3

    pop     {r0-r2,r4-r5,pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

RTCom_Output:       .long 0x027ffdf0
GetAngle_Func:      .long GET_ANGLE_FUNC

