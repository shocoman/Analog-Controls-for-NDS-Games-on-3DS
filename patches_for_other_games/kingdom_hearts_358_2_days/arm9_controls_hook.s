@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020a084c | 1e ff 2f e1 | bx lr
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
MoveWithCPad:

    push    {r1, r2-r5, lr}
    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4]
    cmp     r4, #0
    bne     Read_CPAD

    @ add     r1, r11, r1
    pop     {r1, r2-r5, pc}

Read_CPAD:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X & negate
    lsl     r4, #24
    asr     r4, #24
    @ Sign extend Y
    asr     r5, #24
    rsb     r5, #0

    @ push    {r1}
    @@ 1) Get movement direction
    mov     r0, r4
    mov     r1, r5
    ldr     r5, GetAngle_Func
    blx     r5

    add     r0, #0x8000

    @ pop     {r1}
    @ add     r1, r0, r1 @ return final angle in R1
    pop     {r1, r2-r5, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0204dd60 | 04 50 17 e2 | ands r5,r7,#0x4
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TurnCamera_X:
    push    {r0-r2}

    ldr     r0, RTCom_Output
    ldrsh   r2, [r0, #6] @ CStick X
    lsls    r2, #5

@ camera_left:
    addgt   lr, #0x78
@ camera_right:
    addlt   lr, #0x24
    rsblt   r2, #0
@ camera_updated:
    strne   r2, [r6, #0xa8] @ set camera speed X
    movne   r7, #0x10
@ turn_camera_X_end:
    pop     {r0-r2}
    ands    r5,r7,#0x4 @ replaced opcodes
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0204de40 | 01 20 17 e2 | ands r2,r7,#0x1
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TurnCamera_Y:
    push    {r0-r2}

    ldr     r0, RTCom_Output
    ldrsh   r2, [r0, #8] @ CStick Y
    lsl     r2, #4

@ camera_up:
    addgt   lr, #0x24
@ camera_down:
    addlt   lr, #0x88
    rsblt   r2, #0
@ camera_updated:
    strne   r2, [r6, #0xac] @ set camera speed Y
    movne   r7, #0x10
    movne   r0, #0
@ turn_camera_X_end:
    pop     {r0-r2}
    ands    r2, r7, #0x1
    bx      lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
CPAD_MaxRadius      = 0x69
RTCom_Output:       .long 0x027ffdf0
GetAngle_Func:      .long GET_ANGLE_FUNC
