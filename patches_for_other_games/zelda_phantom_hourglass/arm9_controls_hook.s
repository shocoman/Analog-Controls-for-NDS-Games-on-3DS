.thumb

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020b78ec 14 10 94 e5      ldr        r1,[r4,#0x14]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
SaveCameraAngle:
    mov     r2, #0x20
    lsl     r2, #4
    add     r2, #0x26
    ldrh    r1, [r0, r2] @ offset: 0x226
    mov     r2, #(CameraAngle - (. + 6))
    add     r2, pc
    strh    r1, [r2]

    ldr     r1, [r4, #0x14] @ the replaced instruction
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 021306b4 0c 20 94 e5      ldr        r2,[r4,#0xc]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
MovePlayerWithCPad:
    @ put back the replaced instructions
    ldr     r0, [r0, #0x0] @ contains input, Link's speed, angle, etc

    push    {r4-r7}
    mov     r6, r0
    mov     r7, lr

    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    bne     Read_CPAD

    pop     {r4-r7} @ don't use the CPad if it's not touched
    bx      lr

Read_CPAD:
    @ Split stick Y and X components
    mov     r5, r4
    @ Sign extend X
    lsl     r4, #24
    asr     r4, #24
    @ Sign extend Y & negate
    lsl     r5, #16
    asr     r5, #24
    neg     r5, r5

    @@ 1) CPad's angle
    mov     r0, r4
    mov     r1, r5
    ldr     r3, GetAngle_Func
    blx     r3
    @ Add the camera's angle
    ldr     r1, CameraAngle
    lsl     r1, #16 @ sign extend
    asr     r1, #16
    add     r0, r1
    @ Write
    add     r6, #0x60
    strh    r0, [r6, #0xa] @ angle offset
    @@ "pen is down" time offset (pretend to actually touch the screen)
    mov     r0, #0
    str     r0, [r6, #0] 

    @@ 1) Speed
    @ Find vector length
    mul     r4, r4, r4
    mul     r5, r5, r5
    add     r0, r4, r5
    lsl     r0, #12 @ convert to fixed-point
    ldr     r3, Sqrt_Func
    blx     r3
    @ Normalize the speed to the range [0;0x1000] (i.e. [0.0; 1.0])
    mov     r1, #CPAD_MaxRadius
    ldr     r3, Div32_Func
    blx     r3
    @ Clamp
    mov     r2, #0x10 
    lsl     r2, #8      @ 0x1000
    cmp     r0, r2
    ble     SkipClamp
    mov     r0, r2
SkipClamp:
    
    add     r7, #4  @ skip the usual speed reading routine
    mov     lr, r7
    pop     {r4-r7}
    bx      lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0214dde0 b4 03 d3 e1      ldrh       r0,[r3,#0x34]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TurnShipCameraWithCPad:
    ldrh    r0, [r3, #0x34]
    push    {r0-r5}

    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    bne     Read_CPAD_For_Ship

    pop     {r0-r5} @ don't use the CPad if it's not touched
    bx      lr

Read_CPAD_For_Ship:
    @ Split stick Y and X components
    mov     r5, r4
    @ Sign extend Y & negate
    lsl     r5, #16
    asr     r5, #24
    neg     r5, r5
    @ Sign extend X
    lsl     r4, #24
    asr     r4, #24
    @@ extend X to [-FE; FE]
    bge cpadx_positive
cpadx_negative:
    sub     r4, #22
    b cpadx_extend_done
cpadx_positive:
    add     r4, #22
cpadx_extend_done:

    @@ X pos (0; 0xFE)
    add     r4, #0xFE/2
    strh    r4, [r3, #0x24] @ touch X

    @@ Y pos (0; 0xBE)
    add     r5, #0xBE/2
    strh    r5, [r3, #0x28] @ touch Y

    mov     r0, lr
    add     r0, #0x4C
    mov     lr, r0
    pop     {r0-r5}
    bx      lr
 

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2

CPAD_MaxRadius = 0x69
RTCom_Output:       .long 0x027ffdf0

Div32_Func:         .long DIV_FUNC
GetAngle_Func:      .long GET_ANGLE_FUNC
Sqrt_Func:          .long SQRT_FUNC

CameraAngle:        .short 0
