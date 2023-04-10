@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0218ddb8 | 00 20 85 e0 | add r2,r5,r0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
MovePlayerWithCPad:

    push    {r4, r5, lr}
    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4]
    cmp     r4, #0
    bne     Read_CPAD

    add     r2, r5, r0
    pop     {r4, r5, pc}

Read_CPAD:
    @ Split stick Y and X components
    mov     r3, r4, lsl #16
    @ Sign extend X & negate
    lsl     r4, #24
    asr     r4, #24
    rsb     r4, #0
    @ Sign extend Y
    asr     r3, #24

    mov     r2, #0
    push    {r2-r4} @ put cpad on the stack

    @@ 1) Get movement direction
    mov     r0, r4
    mov     r1, r3
    ldr     r3, GetAngle_Func
    blx     r3
    add     r2, r5, r0
    push    {r2}

    @@ 2) Speed
    @ Find vector length
    mov     r0, sp
    add     r0, #4
    ldr     r3, VecLength_Func
    blx     r3
    @ Normalize the speed to the range [0;0x1000] (i.e. [0.0; 1.0])
    movs    r0, r0, lsl #12
    mov     r1, #CPAD_MaxRadius
    ldr     r3, Div32_Func
    blx     r3
    @ Clamp
    cmp     r0, #0x1000
    movgt   r0, #0x1000
    @ Write
    str     r0, [r6, #0xa4] @ speed offset

    pop     {r2} @ return angle
    add     sp, #0xC

    pop     {r4, r5, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
CPAD_MaxRadius      = 0x69
RTCom_Output:       .long 0x02fffdf0
GetAngle_Func:      .long GET_ANGLE_FUNC
VecLength_Func:     .long VEC_LENGTH_FUNC @ 0x02012d18
Div32_Func:         .long DIV32_FUNC @ 0x0200b184
