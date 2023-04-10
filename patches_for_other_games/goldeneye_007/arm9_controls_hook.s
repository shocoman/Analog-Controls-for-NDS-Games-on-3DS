@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020b69c4 | 07 66 80 e0 | add r6,r0,r7, lsl #0xc
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
MoveWithCPad:
    add     r6,r0,r7, lsl #0xc
    push    {r0-r5, lr}

    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4, #0]
    cmp     r4, #0

    popeq   {r0-r5, pc} @ don't use the CPad if it's not touched

Read_CPAD:
    push    {r0}
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X & negate
    lsl     r4, #24
    asr     r4, #24
    rsb     r4, #0
    @ Sign extend Y
    asr     r5, #24

    @@ Speed
    mov     r0, #0
    push    {r0,r4,r5}
    mov     r0, sp
    ldr     r1, Vec3D_Length_Func
    blx     r1
    mov     r2, #SpeedMultiplier
    mul     r2, r0, r2
    mul     r8, r2, r8
    asr     r8, #12
    add     sp, #12

    @@ Angle
    mov     r0, r4
    mov     r1, r5
    ldr     r3, GetAngle_Func
    blx     r3

    mov     r1, #MoveDirMultiplier
    mul     r2, r1, r0

    pop     {r0}
    add     r6, r0, r2

    @@ run if ZR is pressed
    ldr     r3, RTCom_Output
    ldrb    r0, [r3, #4]
    tst     r0, #0x2

    ldrne   r0, [r10, #0x288]
    orrne   r0, #0x8
    strne   r0, [r10, #0x288]

    pop     {r0-r5, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
CPAD_MaxRadius      = 0x69
MoveDirMultiplier   = ((360 << 12) / 0xffff) @ [0;0xFFFF] => [0; 360]
SpeedMultiplier     = ((1 << 12) / CPAD_MaxRadius)

GetAngle_Func:      .long GET_ANGLE_FUNC
Vec3D_Length_Func:  .long VEC3D_LENGTH_FUNC


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020b9bcc | 00 20 88 e5 | str r2,[r8,#0x0]
@ r9 - ptr to camera velocity X
@ r8 - ptr to camera velocity Y
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
TurnCameraWithKeys:
    mov     r0, #0
    push    {r0-r5, lr}
    
    str     r2,[r8] @ overwritten instruction

    @@ read CStick X 
    @ r0 = 0
    mov     r1, r10
    bl      Read_CStick_Func
    mov     r4, r0, asr #1
    @@ read CStick Y
    mov     r0, #1
    mov     r1, r10
    bl      Read_CStick_Func
    mov     r5, r0, asr #1

    ldr     r0, [r9]
    ldr     r1, [r8]
    add     r0, r4
    add     r1, r5
    str     r0, [r9]
    str     r1, [r8]

    pop     {r0-r5, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ r4 == 0 ? Turn Y : Turn X
@ Turn Y: 020bf7d4 | 00 20 a0 e1 | mov r2, r0 
@ Turn X: 020bf8d0 | 18 27 95 e5 | ldr r2,[r5,#0x718] 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    

TurnCameraWithTouchscreen_Y:
    push    {r1, r3-r5, lr}
    ldr     r1, [r5, #0x5b0]

    mov     r5, r0
    mov     r0, #1
    bl      Read_CStick_Func
    add     r2, r0, r5

    pop     {r1,r3-r5, pc}

TurnCameraWithTouchscreen_X:
    ldr     r2, [r5, #0x718]
    push    {r1, r3-r5, lr}
    ldr     r1, [r5, #0x5b0]

    mov     r5, r0
    mov     r0, #0
    bl      Read_CStick_Func
    add     r0, r5

    pop     {r1,r3-r5, pc}


@ r0 = 0 => return X; 
@ r0 = 1 => return Y; 
@ r1 - used to check if aiming mode is on
Read_CStick_Func:
    cmp     r0, #0

    ldr     r0, RTCom_Output
    ldreqsh r0, [r0, #6] 
    ldrnesh r0, [r0, #8] 
    rsb     r0, #0

    ldr     r3, Sensitivity
    mul     r0, r3, r0

    @ while aiming, slow down the camera movement
    ldr     r1, [r1, #0x144]
    tst     r1, #0x10
    asrne   r0, #1

    bx lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
RTCom_Output:   .long 0x02fffdf0
Sensitivity:    .long (1 << 9) + 0x10
