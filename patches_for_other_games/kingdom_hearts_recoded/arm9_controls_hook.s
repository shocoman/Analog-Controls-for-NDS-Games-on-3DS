@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020a6f8e | 01 2c | cmp    r4,#0x1
@ 020a6f90 | 68 80 | strh   r0,[r5,#0x2]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
MoveWithCPad:
    push    {r0-r5, lr}
    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4]
    cmp     r4, #0
    bne     Read_CPAD

    pop     {r0-r5, lr}
    @ replace instructions
    cmp    r4, #0x1
    strh   r0, [r5, #0x2]
    bx lr

Read_CPAD:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X & negate
    lsl     r4, #24
    asr     r4, #24
    @ Sign extend Y
    asr     r5, #24
    rsb     r5, #0

    @@ 1) Get movement direction
    mov     r0, r4
    mov     r1, r5
    ldr     r5, GetAngle_Func
    blx     r5

    add     r0, #0x8000
    mov     r6, r0

    pop     {r0-r5, lr}
    strh    r6, [r5, #0x0]
    add     lr, #4
    bx      lr
    

@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ @ 020c4236 | 04 20 | movs r0,#0x4
@ @ 020c4238 | 30 40 | ands r0,r6
@ @ (r4 + 0x1d4) <= Camera X
@ @ (r4 + 0x1d8) <= Camera Y
@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ TurnCamera:
@     push    {r1-r2, lr}

@     ldr     r0, RTCom_Output
@     ldrsh   r1, [r0, #6] @ CStick X
@     @ ldrsh   r2, [r0, #8] @ CStick Y

@     ldr     r0, [r4, #0x98]
@     add     r0, r1, lsl #5
@     str     r0, [r4, #0x98]

@     @ ldr     r0, [r4, #0x9c]
@     @ add     r0, r2, lsl #5
@     @ str     r0, [r4, #0x9c]

@     ands    r0, r6, #0x4 @ replaced opcode
@     pop     {r1-r2, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020c4236 | 04 20 | movs r0,#0x4
@ 020c4238 | 30 40 | ands r0,r6
@ (r4 + 0x98) <= Camera X
@ (r4 + 0x9C) <= Camera Y
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TurnCamera_X:
    push    {r1-r2, lr}

    ldr     r0, RTCom_Output
    ldrsh   r1, [r0, #6] @ CStick X

    ldr     r0, [r4, #0x98]
    add     r0, r1, lsl #5
    lsl     r0, #0x10
    lsr     r0, #0x10
    str     r0, [r4, #0x98]

    ands    r0, r6, #0x4 @ replaced opcode
    pop     {r1-r2, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020c4368 | 30 40 | ands   r0,r6
@ 020c436a | 04 90 | str    r0,[sp,#0x10]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TurnCamera_Y:
    ands    r0, r6 @ @ replaced opcodes
    str     r0, [sp,#0x10]

    push    {r0-r2}

    ldr     r0, RTCom_Output
    ldrsh   r2, [r0, #8] @ CStick Y
    lsl     r2, #4
    adds    r2, r2, asr #1

    @ cmp     r2, #0
    @ beq     turn_camera_Y_end
    @ blt     camera_down

@ camera_up:
    addgt   lr, #0x20
    @ bgt     camera_updated
@ camera_down:
    addlt   lr, #0x84
    rsblt   r2, #0
@ camera_updated:
    strne   r2, [r4, #0xc8] @ set camera speed
    movne   r7, #0

turn_camera_Y_end:
    pop     {r0-r2}
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
CPAD_MaxRadius      = 0x69
RTCom_Output:       .long 0x02fffdf0
GetAngle_Func:      .long GET_ANGLE_FUNC
