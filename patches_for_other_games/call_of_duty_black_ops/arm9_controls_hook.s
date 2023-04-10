@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020b1190 | 1c 03 86 e5 | str r0,[r6,#0x31c]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
MoveWithCPad:
    str     r0, [r6,#0x31c] @ overwritten instruction
    push    {r0-r3,r5,r6,r8, lr}

    @ Get the stick values
    ldr     r5, RTCom_Output
    ldrh    r5, [r5, #0]
    cmp     r5, #0

    popeq   {r0-r3,r5,r6,r8, pc} @ don't use the CPad if it's not touched

Read_CPAD:
    mov     r8, r6 @ ptr to game state, etc
    mov     r6, r4

    @ Split stick Y and X components
    @ Sign extend X & negate
    mov     r4, r5, lsl #24
    asr     r4, #24
    rsb     r4, #0
    @ Sign extend Y    
    lsl     r5, #16
    asr     r5, #24

    @@ Angle
    mov     r0, r4
    mov     r1, r5
    bl      ArcTan2_Function
    mov     r1, #MoveDirMultiplier
    mul     r9, r1, r0  @ r9 should contain the move direction
    asr     r9, #4

    @@ Speed
    mov     r0, #0
    push    {r0,r4,r5}
    mov     r0, sp
    ldr     r1, Vec3D_Length_Func
    blx     r1
    mov     r2, #SpeedMultiplier
    mul     r2, r0, r2
    mul     r4, r2, r6 @ r4 should contain the speed
    asr     r4, #12
    add     sp, #12

    pop     {r0-r3,r5,r6,r8, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
CPAD_MaxRadius      = 0x69
MoveDirMultiplier   = ((360 << 12) / 0xffff) @ [0;0xFFFF] => [0; 360]
SpeedMultiplier     = ((1 << 12) / CPAD_MaxRadius)

Vec3D_Length_Func:  .long VEC3D_LENGTH_FUNC


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020b0d78 | 04 50 a0 e1 | mov r5, r4
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
RunWithZR:
    mov     r5, r4 @ overwritten instruction

    @@ run if ZR is pressed
    ldr     r2, RTCom_Output
    ldrb    r1, [r2, #4]
    tst     r1, #0x2

    addne   lr, #0x20
    bx      lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020c0c14 | 00 00 99 e5 | ldr r0,[r9,#0x0]
@ r8 <- Cam Y; r9 <- Cam X
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
TurnCameraWithKeys:
    push    {r1-r5, lr}

    @@ read CStick X
    mov     r0, #0
    mov     r1, r10
    bl      Read_CStick_Func
    mov     r4, r0, asr #9
    @@ read CStick Y
    mov     r0, #1
    mov     r1, r10
    bl      Read_CStick_Func
    mov     r5, r0, asr #9

    ldr     r0, [r9]
    ldr     r1, [r8]
    add     r0, r4
    add     r1, r5
    str     r0, [r9]
    str     r1, [r8]

    pop     {r1-r5, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020ba0f8 | 00 00 51 e3 | cmp r1,#0x0
@ r5 <- Y; r6 <- X
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
TurnCameraWithTouchscreen:
    push    {r0-r4, lr}
    push    {r1}
    
    @@ read CStick X
    mov     r0, #0
    ldr     r1, [r7, #0x194]
    bl      Read_CStick_Func
    mov     r4, r0
    @@ read CStick Y
    mov     r0, #1
    ldr     r1, [r7, #0x194]
    bl      Read_CStick_Func
    mov     r3, r0

    add     r6, r4 @ X
    add     r5, r3 @ Y

    @ otherwise the camera will get stuck after shooting
    ldr     r4, CameraSettings
    ldr     r1, [r4, #0x4]
    ldr     r0, [r1, #0x268]
    bic     r0, r0, #0x1
    str     r0, [r1, #0x268]

    pop     {r1}
    cmp     r1, #0
    pop     {r0-r4, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ r0 = 0 => return X; 
@ r0 = 1 => return Y; 
Read_CStick_Func:
    cmp     r0, #0

    ldr     r0, RTCom_Output
    ldreqsh r0, [r0, #6] 
    ldrnesh r0, [r0, #8] 
    rsb     r0, #0

    ldr     r3, Sensitivity
    mul     r0, r3, r0

    @ while aiming, slow down the camera movement
    ldr     r1, [r1, #0xAC]
    tst     r1, #0x10
    asrne   r0, #1

    bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

ArcTan2_Function:
	push	{r4, lr}
	mov	r4, r0
	orrs	r0, r1, r0
	popeq	{r4, pc}
	eor	r0, r4, r4, asr #31
	sub	r0, r0, r4, asr #31
	cmp	r1, #0
	add	r2, r1, r0
	blt	.L3
	sub	r0, r1, r0
	lsl	r0, r0, #12
	mov	r1, r2
    ldr r3, Div32_Func
    blx r3
	lsl	r3, r0, #5
	asr	r3, r3, #12
	rsb	r3, r3, #32
.L4:
	cmp	r4, #0
	rsblt	r0, r3, #0
	andlt	r0, r0, #255
	andge	r0, r3, #255
	pop	{r4, pc}
.L3:
	sub	r1, r0, r1
	lsl	r0, r2, #12
    ldr r3, Div32_Func
    blx r3
	lsl	r3, r0, #5
	asr	r3, r3, #12
	rsb	r3, r3, #96
	b	.L4


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
RTCom_Output:       .long 0x02fffdf0
Div32_Func:         .long DIV32_FUNC
CameraSettings:     .long CAMERA_SETTINGS

Sensitivity:        .long (1 << 8) + 0x42

