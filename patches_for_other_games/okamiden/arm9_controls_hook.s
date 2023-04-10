UnknownPlayMode_Entry:
    add     r0, sp, #0xc @ put back the replaced instructions
    b       Main
FightingAndFreeroamMode_Entry:
    add     r0, sp, #0x18 @ R0 points to the result vector for direction
Main:
    add     r1,r5,r1

    push    {r0-r8, lr}
    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4, #0]
    cmp     r4, #0

    popeq   {r0-r8, pc} @ don't use the CPad if it's not touched

Read_CPAD:
    mov     r8, r0
    @ 0x3c4 - CameraZ's unit vector, 0x3d0 - CameraX's unit vector

    @@ Calculate the camera's angle
    ldr     r0, [r5, #0x3c4] @ Camera Z's x
    ldr     r1, [r5, #0x3cc] @ Camera Z's z
    ldr     r3, GetAngle_Func
    blx     r3
    mov     r6, r0  @ camera view's angle

    @@ Extract the CPad's values
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    mov     r4, r4, lsl #24
    mov     r4, r4, asr #24
    @ Sign extend Y & negate
    mov     r5, r5, asr #24
    @ rsb     r5, #0
    rsb     r4, #0

    @@ Calculate the cpad's angle
    mov     r0, r4
    mov     r1, r5
    ldr     r3, GetAngle_Func
    blx     r3

    @@ Sum the angles and calculate the offsets for sine and cosine to get the final direction
    add     r0, r6  @ final angle = camera's angle + cpad's angle
    lsl     r0, #16 @ angle & 0xFFFF
    lsr     r0, #16
    
    asr     r0, #4
    lsl     r2, r0, #1
    lsl     r1, r2, #1  @ sin offset
    add     r2, #1
    lsl     r0, r2, #1  @ cos offset

    @@ Use the lookup table
    ldr     r3, SinCos_LookupTable
    ldrsh   r0, [r3, r0] @ cos
    ldrsh   r1, [r3, r1] @ sin

    @@ Write the values (X and Y are flipped)
    str     r1, [r8, #0] @ X offset
    str     r0, [r8, #8] @ Z offset

    pop     {r0-r8, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2

RTCom_Output:       .long 0x02fffdf8

GetAngle_Func:      .long GET_ANGLE_FUNC
SinCos_LookupTable: .long SINCOS_LOOKUP_TABLE












@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ @ 0208a8c2 | 06 a8 | add    r0,sp,#0x18
@ @ 0208a8c4 | 69 18 | adds   r1,r5,r1
@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
@ MovePlayerWithCPad:
@     @ put back the replaced instructions
@     add     r0,sp,#0x18 @ R0 points to the result vector for direction
@     add     r1,r5,r1

@     push    {r0-r8, lr}

@     @ Get the stick values
@     ldr     r4, RTCom_Output
@     ldrh    r4, [r4, #0]
@     cmp     r4, #0

@     popeq   {r0-r8, pc} @ don't use the CPad if it's not touched

@ Read_CPAD:
@     mov     r8, r0
@     @ 0x3c4 - Z, 0x3d0 - X
@     ldr     r6, [r5, #0x3cc] @ Camera Z's z

@     @ Split stick Y and X components
@     mov     r5, r4, lsl #16
@     @ Sign extend X
@     mov     r4, r4, lsl #24
@     mov     r4, r4, asr #24
@     @ Sign extend Y & negate
@     mov     r5, r5, asr #24
@     @ rsb     r5, #0
@     rsb     r4, #0


@     @ cos2 = (cos * cos) >> 12
@     mul     r0, r6, r6
@     asr     r0, r0, #12
@     @ sin_sq = 0x1000 - cos2 
@     rsb     r0, #0x1000
@     @ sin = Sqrt(sin_sq)
@     ldr     r3, Sqrt_FixedPoint
@     blx     r3
@     mov     r7, r0
@     @ x = cpad.x * cos - cpad.y * sin
@     mul     r0, r4, r6
@     mul     r1, r5, r7
@     sub     r0, r1
@     str     r0, [r8, #0] @ X offset
@     @ y = cpad.x * sin + cpad.y * cos
@     mul     r1, r4, r7
@     mla     r0, r5, r6, r1
@     str     r0, [r8, #8] @ Z offset


@     pop     {r0-r8, pc}


@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@ .align 2

@ RTCom_Output:       .long 0x02fffdf8

@ Div32_Func:         .long DIV32_FUNC
@ GetAngle_Func:      .long GET_ANGLE_FUNC
@ Sqrt_FixedPoint:    .long 0x0200290c










@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ @ 0208a8c2 | 06 a8 | add    r0,sp,#0x18
@ @ 0208a8c4 | 69 18 | adds   r1,r5,r1
@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
@ MovePlayerWithCPad:
@     @ put back the replaced instructions
@     add     r0,sp,#0x18 @ R0 points to the result vector for direction
@     add     r1,r5,r1

@     push    {r0-r6, lr}

@     @ Get the stick values
@     ldr     r4, RTCom_Output
@     ldrh    r4, [r4, #0]
@     cmp     r4, #0

@     popeq   {r0-r6, pc} @ don't use the CPad if it's not touched

@ Read_CPAD:
@     @ Split stick Y and X components
@     mov     r5, r4, lsl #16
@     @ Sign extend X
@     mov     r4, r4, lsl #24
@     mov     r4, r4, asr #24
@     @ Sign extend Y & negate
@     mov     r5, r5, asr #24
@     rsb     r5, #0

@     mov     r6, r5
@     mov     r5, #0
@     stmia   r0, {r4-r6} @ r4 - X, r5 - Y (0), r6 - Z

@     @ @@ Get Angle
@     @ movs    r0, r4
@     @ movs    r1, r5
@     @ ldr     r3, GetAngle_Func
@     @ blx     r3
@     @ @ Write
@     @ strh    r0, [r10, #0x58] @ angle offset

@     pop     {r0-r6, pc}


@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@ .align 2

@ CPAD_MaxRadius = 0x69
@ RTCom_Output:       .long 0x02fffdf8

@ Div32_Func:         .long DIV32_FUNC
@ GetAngle_Func:      .long GET_ANGLE_FUNC

@ @ Div32_Func:         .long 0x0203a194
@ @ GetAngle_Func:      .long 0x01ffbbe0
@ @ Vec2D_Length_Func:  .long 0x01ff9258


@@@ V1
@ cos = dot(Vec3(0,0,1), CameraUnitV) = 1 * CameraUnitV.z = CameraUnitV.z
@ sin = sqrt(1 - cos**2)

@ x = cpad.x * cos - cpad.y * sin
@ y = cpad.x * sin + cpad.y * cos


@@@ V2
@ cos = CameraUnitV.z
@ cos2 = (cos * cos) >> 12
@ sin_sq = 0x1000 - cos2
@ sin = Sqrt(sin_sq)

@ x = cpad.x * cos - cpad.y * sin
@ y = cpad.x * sin + cpad.y * cos


@ @@@ V3
@ @ cos = CameraUnitV.z
@ ldr     r6, [r5, #0x3cc]
@ @ cos2 = (cos * cos) >> 12
@ mul     r0, r6, r6
@ asr     r0, r0, #12
@ @ sin_sq = 0x1000 - cos2 
@ rsb     r0, #0x1000
@ @ sin = Sqrt(sin_sq)
@ ldr     r3, Sqrt_FixedPoint
@ blx     r3
@ bl      0x0200290c @ Sqrt_FixedPoint
@ mov     r7, r0
@ @ x = cpad.x * cos - cpad.y * sin
@ mul     r0, r4, r6
@ mul     r1, r5, r7
@ sub     r0, r1
@ str     r0, [r8, #0] @ X offset
@ @ y = cpad.x * sin + cpad.y * cos
@ mul     r1, r4, r7
@ mla     r0, r5, r6, r1
@ str     r0, [r8, #8] @ Z offset


@ Sqrt_FixedPoint:    .long 0x0200290c
