@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0202ce7c | 05 10 d0 e7 | ldrb r1,[r0,r5]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
move_with_cpad:
    @ put back the replaced instructions
    ldrb    r1, [r0, r5]
    push    {r0, r2-r5, lr}

    @ Get the stick values
    ldr     r4, rtcom_output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    popeq   {r0, r2-r5, pc} @ don't use the CPad if it's not touched

    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    mov     r4, r4, lsl #24
    mov     r4, r4, asr #24
    @ Sign extend Y
    mov     r5, r5, asr #24

    @@ Angle
    mov     r0, r4
    mov     r1, r5
    bl      arctan2_function
    mov     r1, r0
    @ return the angle in R1

    pop     {r0, r2-r5, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    

arctan2_function:
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
rtcom_output:       .long 0x027ffdf0
Div32_Func:         .long DIV_FUNC
