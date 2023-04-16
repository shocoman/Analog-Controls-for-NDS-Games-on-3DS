@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02003716 | 00 11 | asrs r0,r0,#0x4  <= "push {lr}"
@ 02003718 | 00 07 | lsls r0,r0,#0x1c <= jumped from here
@ 0200371a | 81 0e | lsrs r1,r0,#0x1a
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
MovePlayerWithCPad:

    pop     {r2} @ return address

    push    {r4,r5}
    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4]
    cmp     r4, #0
    bne     Read_CPAD

    @ don't use the CPad if it's not touched and read the dpad as usual
    asr     r0, r0, #0x4 @ put back the replaced instruction
    lsl     r0, r0, #0x1c
    lsr     r1, r0, #0x1a
    pop     {r4,r5}

    mov     r3, lr
    mov     lr, r2 @ restore lr
    bx      r3

Read_CPAD:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    lsl     r4, #24
    asr     r4, #24
    @ Sign extend Y
    asr     r5, #24

    push    {r2}
    @@ Get movement direction
    mov     r0, r4
    mov     r1, r5
    ldr     r3, GetAngle_Func
    blx     r3

    @ round the angle down to zero (the UP direction) if it's close enough already
    @ (due to an annoying camera that would start turning if you're not precisely pushing the cpad Up)
    mov     r1, r0, lsl #16
    movs    r1, r1, asr #16
    rsblt   r1, #0
    cmp     r1, #0x200
    movle   r0, #0

    pop     {r2}
    pop     {r4,r5}
    bx      r2  @ return the result in R0

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

RTCom_Output:       .long 0x027ffdf0
GetAngle_Func:      .long GET_ANGLE_FUNC | 1
