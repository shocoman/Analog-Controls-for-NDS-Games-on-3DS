
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020be4e4 00 80 a0 e1      cpy        r8,r0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
.thumb
SaveCameraAngle:
    mov     r8, r0 @ the replaced instruction
    mov     r2, #0x23
    lsl     r2, #4
    ldr     r3, [r0, r2] @ offset 0x230
    ldrh    r3, [r3, #0x6]
    adr     r2, CameraAngle
    strh    r3, [r2]
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02094f8c ba 05 da e1      ldrh       r0,[r10,#0x5a]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
@ .align 2
@ .arm
MovePlayerWithCPad:
    @ put back the replaced instructions
    mov     r0, r10 @ r10 contains address close to where Link's speed and angle are located
    add     r0, #0x5a
    ldrh    r0, [r0]

    push    {r0-r6, lr}
    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    bne     Read_CPAD

    pop     {r0-r6, pc} @ don't use the CPad if it's not touched

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

    @@ 1) Speed
    @ Find vector length
    mov     r0, r4
    mov     r1, r5
    ldr     r3, Vec2D_Length_Func
    blx     r3
    @ Normalize the speed to the range [0;0x1000] (i.e. [0.0; 1.0])
    lsl     r0, #12
    mov     r1, #CPAD_MaxRadius
    ldr     r3, Div32_Func
    blx     r3
    @ Clamp
    mov     r2, #0x10 @ 0x1000
    lsl     r2, #8
    cmp     r0, r2
    ble     SkipClamp
    mov     r0, r2
SkipClamp:

    @ Write
    mov     r6, r10
    add     r6, #0x54
    strh    r0, [r6] @ speed offset

    @@ 2) Angle
    mov     r0, r4
    mov     r1, r5
    ldr     r3, GetAngle_Func
    blx     r3
    @ Write
    ldr     r1, CameraAngle

    @@ sign extend the camera's and cpad's angle and add them together
    lsl     r1, #16
    asr     r1, #16
    lsl     r0, #16
    asr     r0, #16
    add     r0, r1
    strh    r0, [r6, #4] @ angle offset

    sub     r6, #0x30
    ldr     r6, [r6] @ PlayerState

    add     r6, #0x44 @ TSC state + 0x30
    strh    r0, [r6, #0x14] @ fix 8-dir roll on the dpad mod

    pop     {r0-r6, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 021306b4 0c 20 94 e5      ldr        r2,[r4,#0xc]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TurnTrainCameraWithCPad:
    ldr     r2, [r4, #0xc] @ the replaced instruction

    push    {r3-r5}

    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    bne     Read_CPAD_For_Train

    pop     {r3-r5} @ don't use the CPad if it's not touched
    bx      lr

Read_CPAD_For_Train:
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
    mov     r2, r4

    @@ Y pos (0; 0xBE)
    add     r5, #0xBE/2
    mov     r1, r5

    pop     {r3-r5}
    mov     r0, lr
    add     r0, #0x1C
    bx      r0
 

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
@ CPAD_MaxRadius = 0x69
CPAD_MaxRadius = 0x69
@ RadiusRatio: .long 0x5F0 @ / 0x69
RadiusRatio: .long 0x49000 @ / 0x69

RTCom_Output:       .long 0x027ffdf0

Div32_Func:         .long DIV32_FUNC
GetAngle_Func:      .long GET_ANGLE_FUNC
Vec2D_Length_Func:  .long VEC2D_LENGTH_FUNC

CameraAngle:        .short 0
