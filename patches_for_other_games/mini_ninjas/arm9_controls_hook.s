@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02026d18 | 0a 07 | lsls   r2,r1,#0x1c
@ 02026d1a | d2 0f | lsrs   r2,r2,#0x1f
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
MovePlayerWithCPad:
    @ put back the replaced instructions
    lsls    r2, r1, #0x1c
    lsrs    r2, r2, #0x1f

    push    {r1-r5, lr}

    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4, #0]
    cmp     r4, #0

    popeq   {r1-r5, pc} @ don't use the CPad if it's not touched

Read_CPAD:
    @ unstick the camera (after L is released)
    ldr     r0, CameraState
    ldrb    r1, [r0]
    and     r1, #0x7F
    strb    r1, [r0]

    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    mov     r4, r4, lsl #24
    mov     r4, r4, asr #24
    @ Sign extend Y & negate
    mov     r5, r5, asr #24

    @@ Angle
    mov     r0, r4
    mov     r1, r5
    bl      ArcTan2_Function
    @ return the angle in R0
    
    pop     {r1-r5, lr}
    add     lr, #0x44
    bx      lr

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
CPAD_MaxRadius = 0x69
RTCom_Output:   .long 0x027ffdf0
Div32_Func:     .long DIV_FUNC
CameraState:    .long CAMERA_STATE
