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
    @ Sign extend X & negate
    mov     r4, r4, lsl #24
    mov     r4, r4, asr #24
    rsb     r4, #0
    @ Sign extend Y
    mov     r5, r5, asr #24

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
