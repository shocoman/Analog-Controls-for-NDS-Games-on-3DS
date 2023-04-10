
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020383c0 | 02 61 91 e7 | ldr r6, [r1, r2, lsl #0x2]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
MovePlayerWithCPad:
    @ put back the replaced instruction
    ldr     r6, [r1, r2, lsl #0x2]

    push    {r0-r5, lr}
    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4, #0]
    cmp     r4, #0

    popeq   {r0-r5, pc} @ don't use the CPad if it's not touched

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
    add     r0, #0x4000 @ shift to set the bottom as angle 0 (and top as 0x8000)

    @@ convert the angle from the range [0; 0x10000] to [0; 0x6488]
    ldr     r1, AngleRatio
    mul     r0, r1, r0

    mov     r6, r0, asr #12  @ return the result in R6
    pop     {r0-r5, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
RTCom_Output:       .long 0x027ffdf0
AngleRatio:         .long ((0x6488 << 12) / 0x10000)
GetAngle_Func:      .long GET_ANGLE_FUNC

