@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020951dc | 41 58 | ldr    r1,[r0,r1]
@ 020951de | 00 29 | cmp    r1,#0x0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
MovePlayerWithCPad:

    push    {r0, r2-r5, lr}
    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4]
    cmp     r4, #0
    bne     Read_CPAD

    @ replace instructions
    ldr     r1,[r0,r1]
    cmp     r1,#0x0
    pop     {r0, r2-r5, pc}

Read_CPAD:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X & negate
    lsl     r4, #24
    asr     r4, #24
    @ Sign extend Y
    asr     r5, #24
    rsb     r5, #0

    @@ Move Dir
    mov     r0, r4
    mov     r1, r5
    ldr     r5, GetAngle_Func
    blx     r5
    add     r0, #0x8000

    mov     r1, r0
    cmp     r1, #0x0
    pop     {r0, r2-r5, pc}
    

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
CPAD_MaxRadius      = 0x69
RTCom_Output:       .long 0x027ffdf0
GetAngle_Func:      .long GET_ANGLE_FUNC
