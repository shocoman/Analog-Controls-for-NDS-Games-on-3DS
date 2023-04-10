
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020d32b0 | 1e ff 2f 01 | bxeq lr
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
MovePlayerWithCPad:
    push    {r4-r6, lr}
    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4, #0]
    cmp     r4, #0

    popeq   {r4-r6, pc} @ don't use the CPad if it's not touched

Read_CPAD:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    lsl     r4, #24
    asr     r4, #24
    @ Sign extend Y & negate
    asr     r5, #24

    @@ Angle
    mov     r1, r4
    mov     r0, r5
    ldr     r3, GetAngle_Func
    blx     r3
    add     r0, #0x4000 @ angle

    pop     {r4-r6, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
CPAD_MaxRadius      = 0x69
RTCom_Output:       .long 0x027ffdf0
GetAngle_Func:      .long GET_ANGLE_FUNC
