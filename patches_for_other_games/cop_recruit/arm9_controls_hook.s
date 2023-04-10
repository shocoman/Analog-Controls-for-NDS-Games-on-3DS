@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02052f90 | 00 40 c3 e5 | strb r4,[r3,#0x0]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
MoveWithCpad_X:
    push    {r0-r3,r5-r6, lr}

    @ Get the stick values
    ldr     r5, RTCom_Output
    ldrh    r5, [r5, #0]
    cmp     r5, #0

    moveq   r0, #0
    streq   r0, Current_CPad_Y
    streqb  r4, [r3,#0x0] @ overwritten instruction
    popeq   {r0-r3,r5-r6, pc} @ don't use the CPad if it's not touched

    @ Split cpad Y and X components
    @ Sign extend X & negate
    mov     r4, r5, lsl #24
    asr     r4, #24
    rsb     r4, #0
    @ Sign extend Y    
    lsl     r5, #16
    asr     r5, #24
    strh    r5, Current_CPad_Y

    @@ Angle
    push    {r3}
    mov     r0, r4
    mov     r1, r5
    ldr     r3, GetAngle_Func
    blx     r3
    strh    r0, DudeDirection
    pop     {r3}

    @ Set Move_DX; [-cpad.x; +cpad.x] => [-9, 9]
    ldr     r2, MoveMultiplier
    mul     r4, r2, r4
    add     r4, #0x800
    asr     r4, #12

    bl      Double_Speed_if_Running

    strb    r4, [r3,#0x0] @ overwritten instruction

    pop     {r0-r3,r5-r6, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02053034 | 00 40 c3 e5 | strb r4,[r3,#0x0]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
MoveWithCpad_Y:
    push    {r0-r3,r5-r6, lr}

    ldrsh   r5, Current_CPad_Y
    cmp     r5, #0
    
    streqb  r4, [r3,#0x0] @ overwritten instruction
    popeq   {r0-r3,r5-r6, pc} @ don't use the CPad if it's not touched

    @ Set Move_DY; [-cpad.y; +cpad.y] => [-9, 9]
    ldr     r2, MoveMultiplier
    mul     r4, r2, r5
    add     r4, #0x800
    asr     r4, #12

    bl      Double_Speed_if_Running

Cpad_Y_SkipCheck:
    strb    r4, [r3,#0x0] @ overwritten instruction

    pop     {r0-r3,r5-r6, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Double_Speed_if_Running:
    ldr     r0, IS_RUNNING_ADDR
    ldrb    r0, [r0]
    cmp     r0, #0
    beq     Cpad_Y_SkipCheck

    lsl     r4, #1 @ double the speed
    cmp     r4, #9
     movgt   r4, #9
    cmp     r4, #-9
     movlt   r4, #-9
    
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02053110 | 00 10 80 e5 | str r1,[r0,#0x0]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
MoveWithCpad_SetDudeDirection:
    push    {r0-r6, lr}

    ldrh    r5, DudeDirection
    cmp     r5, #0
    movne   r1, r5, lsl #16
    
    str     r1, [r0,#0x0] @ overwritten instruction
    pop     {r0-r6, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Camera Turning Left/Right
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02052e38 | 00 00 1a e1 | tst r10,r0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TurnCameraWithCStick_Part_1:
    ldr     r1, RTCom_Output
    ldrsh   r1, [r1, #6] @ CStick X
    cmp     r1, #0
    tsteq   r10, r0

    moveq   r1, #0
    strh    r1, CStickX_for_Camera_Turning

    bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02052e7c | 3a 03 a0 13 | movne r0,#0xe8000000
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TurnCameraWithCStick_Part_2:
    movne   r0, #0xe8000000

    ldrsh   r2, CStickX_for_Camera_Turning
    rsb     r2, #0
    cmp     r2, #0
    movne   r0, r2, lsl #23

    bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
Current_CPad_Y:             .short 0
DudeDirection:              .short 0
CStickX_for_Camera_Turning: .short 0
.align 2

CPAD_MaxRadius      = 0x69
RTCom_Output:       .long 0x027ffdf0
GetAngle_Func:      .long GET_ANGLE_FUNC

IS_RUNNING_ADDR:    .long 0x0221eca9

MoveMultiplier:     .long ((9 << 12) / CPAD_MaxRadius)

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Aiming
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02052c58 | 05 20 82 e0 | add r2,r2,r5
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
WalkDuringAimingWithCPad:
    push    {r0,r1,r3-r6, lr}

    @ Get the stick values
    ldr     r6, RTCom_Output
    ldrh    r6, [r6, #0]
    cmp     r6, #0

    addeq   r2,r2,r5 @ overwritten instruction
    popeq   {r0,r1,r3-r6, pc} @ don't use the CPad if it's not touched

    @ Split cpad Y and X components
    @ Sign extend X & negate
    mov     r4, r6, lsl #24
    asr     r4, #24
    rsb     r4, #0
    @ Sign extend Y    
    lsl     r6, #16
    asr     r6, #24

    @@ Angle
    push    {r2}
    mov     r0, r4
    mov     r1, r6
    ldr     r3, GetAngle_Func
    blx     r3
    pop     {r2}

    add     r2,r0, lsl #16

    pop     {r0,r1,r3-r6, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0205283c | d0 30 d3 e1 | ldrsb r3,[r3,#0x0]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
AimingWithCStick:
    push    {r0-r2,r4-r6, lr}
    ldr     r1, RTCom_Output
    ldrsh   r2, [r1, #8] @ CStick Y
    ldrsh   r1, [r1, #6] @ CStick X

    ldrsb   r3, [r3]
    add     r3, r1, asr #3

    ldr     r0, Aim_DY_Addr
    ldr     r1, [r0]
    add     r1, r2, lsl #19
    str     r1, [r0]

    pop     {r0-r2,r4-r6, pc}

Aim_DY_Addr: .long 0x022147b0


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Car Steering Left/Right
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0222dea4 | 00 10 91 e5 | ldr r1,[r1,#0x0]
@ 0222deec | 00 10 91 e5 | ldr r1,[r1,#0x0]
@ r1 - ptr to Max_Steering_Angle
@ r2 - ptr to the current car steering angle
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ load Cpad.x
@ Cpad.x = (float) Cpad.x
@ Cpad.x /= 0x69
@ Cpad.x *= Max_Steering_Angle
@ if (current_steering_value > Cpad.x) current_steering_value = Cpad.x
CarSteering:
    push    {r2-r6, lr}

    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    ldreq   r1,[r1,#0x0] @ overwritten instruction
    popeq   {r2-r6, pc}

    mov     r5, r1 @ save the pointer to Max_Steering_Angle
    mov     r6, r2 @ save the pointer to current car steering angle

    @ Sign extend X & negate
    mov     r0, r4, lsl #24
    asr     r0, #24
    rsb     r0, #0

    @ convert to float
    ldr     r3, Int_to_Float_Func
    blx     r3

    @ divide by 0x69 (to normalize into the range [-1.0; 1.0])
    ldr     r1, Float_Const_0x69
    ldr     r3, FloatDiv_Func
    blx     r3 

    @ multiply by the maximum steering level for the current vehicle to get the actual number
    ldr     r1, [r5] @ maximum angle
    ldr     r3, FloatMul_Func
    blx     r3   

    @ return new steering angle in R0

    ldr     r1, [r5,#0x0] @ overwritten instruction
    pop     {r2-r6, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

Float_Const_0x69:   .long 0x42d20000 @ 105 as float

Int_to_Float_Func:  .long 0x02229f38
FloatDiv_Func:      .long 0x02229b0c
FloatMul_Func:      .long 0x02229fc8
