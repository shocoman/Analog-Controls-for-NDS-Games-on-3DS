@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020af280 | 40 03 86 e5 | str r0,[r6,#0x340]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
move_with_cpad:
    str     r0,[r6,#0x340]  @ overwritten instruction
    push    {r0-r3, r5, r6, r8, lr}

    @ Get the stick values
    ldr     r5, rtcom_output
    ldrh    r5, [r5, #0]
    cmp     r5, #0
    popeq   {r0-r3,r5,r6,r8, pc} @ don't use the CPad if it's not touched

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
    bl      arctan2_function
    mov     r1, #MoveDirMultiplier
    mul     r9, r1, r0  @ r9 should contain the move direction
    asr     r9, #4

    @@ Speed
    mov     r0, #0
    push    {r0,r4,r5}
    mov     r0, sp
    ldr     r1, vec3d_length_func
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

vec3d_length_func:  .long VEC3D_LENGTH_FUNC


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020aee68 | 04 50 a0 e1 | cpy r5,r4
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
run_with_zr:
    mov     r5, r4 @ overwritten instruction

    @@ run if ZR is pressed
    ldr     r2, rtcom_output
    ldrb    r1, [r2, #4]
    tst     r1, #0x2

    addne   lr, #0x20
    bx      lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020c0364 | 00 00 98 e5 | ldr r0,[r8,#0x0]
@ r7 <- Cam Y; r8 <- Cam X
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
turn_camera_with_keys:
    push    {r1-r5, lr}

    @@ read CStick X
    mov     r0, #0
    mov     r1, r9
    bl      __read_cstick_func
    mov     r4, r0, asr #9
    @@ read CStick Y
    mov     r0, #1
    mov     r1, r9
    bl      __read_cstick_func
    mov     r5, r0, asr #9

    ldr     r0, [r8]
    ldr     r1, [r7]
    add     r0, r4
    add     r1, r5
    str     r0, [r8]
    str     r1, [r7]

    pop     {r1-r5, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020b8468 | 00 00 51 e3 | cmp r1,#0x0
@ r5 <- Y; r6 <- X
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
turn_camera_with_touchscreen:
    push    {r0-r4, lr}
    push    {r1}
    
    @@ read CStick X
    mov     r0, #0
    ldr     r1, [r7, #0x1CC]
    bl      __read_cstick_func
    mov     r4, r0
    @@ read CStick Y
    mov     r0, #1
    ldr     r1, [r7, #0x1CC]
    bl      __read_cstick_func
    mov     r3, r0

    add     r6, r4 @ X
    add     r5, r3 @ Y

    @ otherwise the camera will get stuck after shooting
    ldr     r1, camera_settings
    ldr     r1, [r1, #0x4]
    ldr     r0, [r1, #0x2b0]
    bic     r0, r0, #0x800
    str     r0, [r1, #0x2b0]

    pop     {r1}
    cmp     r1, #0
    pop     {r0-r4, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ r0 = 0 => return X; 
@ r0 = 1 => return Y; 
__read_cstick_func:
    cmp     r0, #0

    ldr     r0, rtcom_output
    ldreqsh r0, [r0, #6]
    ldrnesh r0, [r0, #8]
    rsb     r0, #0

    ldr     r3, sensitivity
    mul     r0, r3, r0

    @ while aiming, slow down the camera movement
    ldr     r1, [r1, #0xC8]
    tst     r1, #0x10
    asrne   r0, #1

    bx lr

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
    ldr r3, div32_func
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
    ldr r3, div32_func
    blx r3
	lsl	r3, r0, #5
	asr	r3, r3, #12
	rsb	r3, r3, #96
	b	.L4


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
rtcom_output:       .long 0x02fffdf0
div32_func:         .long DIV32_FUNC
camera_settings:    .long 0x021B20BC @ CAMERA_SETTINGS

sensitivity:        .long (1 << 8) + 0x52

