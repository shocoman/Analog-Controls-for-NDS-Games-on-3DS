@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Ball rolling
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Jumped here from (in USA v1.1): "02021de4 | 81 1f a0 e1 | mov r1, r1, lsl #0x1f" (USA v1.1)
@ r4 - points to the controls
BallRolling_Function:
    push    {r0-r6}
    mov     r6, r4

    @ Get the stick value
    ldr     r5, RTComDataOutput
    ldrh    r4, [r5, #0]

    @ if both are zero, exit
    cmp     r4, #0
    popeq   {r0-r6}
    moveq   r1, r1, lsl #0x1f @ execute the replaced instruction
    bxeq    lr

ProcessCPad:
    @ Split CPad Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    mov     r4, r4, lsl #24
    mov     r4, r4, asr #24
    @ Sign extend Y & negate
    mov     r5, r5, asr #24
    rsb     r5, #0

    @@ Remap vector components from (0; CPAD_MaxRadius) to (0; MaxSpeed)
    ldr     r3, BallRollSpeedModifer
    mul     r0, r3, r4
    mul     r1, r3, r5
    @@ Back to integers
    asr     r0, #0xC
    asr     r1, #0xC
    @@ Write values
    strh    r0, [r6, #0x2A] @ "touch dx" offset
    strh    r1, [r6, #0x2C] @ "touch dy" offset
    
    @ fake a touch to correctly set the player's direction after exiting from the ball form
    mov     r1, #1
    strb    r1, [r6, #0x34]

    pop     {r0-r6}
    add     lr, #8
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

CPAD_MaxRadius  = 0x1c2
MaxSpeed        = 0x8B
BallRollSpeedModifer: .long (MaxSpeed << 12) / CPAD_MaxRadius


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Camera rotation
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Jumped here from (in USA v1.1):  "0x02024314 | b4 0e d1 e1 | ldrh r0,[r1,#0xe4]" (USA v1.1)
@ r0 - points to the controls
GyroBias_X:     .short 0
GyroBias_Y:     .short 0
GyroBias_Z:     .short 0

.align 2
CameraRotation_Function:
    mov     r8, r0

    ldrh    r0, [r1, #0xe4] @ execute the replaced instruction
    push    {r0-r7, lr}

    @ Get the gyroscope values
    ldr     r7, RTComDataOutput
    ldrsh   r4, [r7, #10]   @ X-axis
    ldr     r5, [r7, #12]
    mov     r6, r5, asr #16 @ Z-axis
    lsl     r5, #16
    asr     r5, #16         @ Y-axis

    @@ Read ZL&ZR
    ldrb    r7, [r7, #4]
    @ If ZR's been pressed, toggle the visor
    ldrb    r1, ZlZr_LastFrame
    strb    r7, ZlZr_LastFrame
    eor     r1, r7
    and     r7, r1
    tst     r7, #0x2 @ ZR is pressed
    movne   r0, #0
    ldrne   r1, ToggleVisor_Func
    blxne   r1

    ldrh    r7, [r8, #4] @ pressed keys
    ldrb    r0, ZlZr_LastFrame

    @@ Save the gyro bias when ZL + UP is pressed
    tst     r7, #0x40   @ UP is pressed
    tstne   r0, #0x4    @ and ZL is held
    strneh  r4, GyroBias_X
    strneh  r5, GyroBias_Y
    strneh  r6, GyroBias_Z

    @@ Toggle gyro's axis for X when ZL + LEFT is pressed
    tst     r7, #0x20   @ LEFT is pressed
    tstne   r0, #0x4    @ and ZL is held
    ldrb    r2, GyroAxisForX
    addne   r2, #1
    andne   r2, #1
    strneb  r2, GyroAxisForX

    @@ Toggle gyro when ZL + DOWN is pressed
    ldrb    r2, isGyroEnabled
    tst     r7, #0x80   @ DOWN is pressed
    tstne   r0, #0x4    @ and ZL is held
    mvnne   r2, r2
    strneb  r2, isGyroEnabled
    @@ Skip gyro if it's disabled
    cmp     r2, #0
    moveq   r4, #0
    moveq   r6, #0
    beq     SkipGyro

    PreprocessGyro:
        @ Subtract the bias to calibrate the gyro
        ldrsh   r0, GyroBias_X
        sub     r4, r0
        asrs    r4, #9
        addlt   r4, #1

        ldrsh   r0, GyroBias_Y
        sub     r5, r0
        asrs    r5, #9
        addlt   r5, #1
        rsb     r5, #0

        ldrsh   r0, GyroBias_Z
        sub     r6, r0
        asrs    r6, #9
        addlt   r6, #1

    @ choose the selected axis for X
    @ 0 - Z; 1 - Y
    ldrb    r2, GyroAxisForX
    cmp     r2, #1
    moveq   r6, r5

SkipGyro:
    @ Add nub values
    bl      ReadNub_Function
    add     r4, r1  @ scroll Y
    add     r6, r0  @ scroll X

    @@ account for the X's higher sensitivity by default
    ldr     r3, CameraYSensitivityModifier
    mul     r4, r3, r4
    asrs    r4, #0xC
    addlt   r4, #1

    @@ Apply values to simulate touching and to turn the camera
    ldrh    r0, [r8, #0x2A] @ "touch dx" offset
    ldrh    r1, [r8, #0x2C] @ "touch dy" offset
    add     r0, r6
    add     r1, r4
    strh    r0, [r8, #0x2A]
    strh    r1, [r8, #0x2C]
    
    cmp     r6, #0
    cmpeq   r4, #0
    beq     CameraRotationExit

    @ Simulate any button press if no actual buttons are pressed (will glitch otherwise)
    ldrh    r1, [r8, #0]
    cmp     r1, #0
    moveq   r1, #0x1000
    streqh  r1, [r8, #0]

CameraRotationExit:
    pop     {r0-r7, lr}
    add     lr, #8 @ Skip the usual "only if touchscreen is pressed" check
    bx      lr

ReadNub_Function:
    ldr     r2, RTComDataOutput
    ldrsh   r0, [r2, #6] @ get X
    ldrsh   r1, [r2, #8] @ get Y & negate it
    rsb     r1, #0

    @@ Remap vector components from (0; CPAD_MaxRadius) to (0; MaxSpeed) ???
    ldr     r3, CameraRotationSpeedModifier
    mul     r0, r3, r0
    mul     r1, r3, r1
    @@ Back to integers
    asrs    r0, #0xC
    addlt   r0, #1
    asrs    r1, #0xC
    addlt   r1, #1

    bx      lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

ZlZr_LastFrame: .byte  0
isGyroEnabled:  .byte  0
GyroAxisForX:   .byte  0

.align 2
CameraRotationSpeedModifier:    .long 0x400
CameraYSensitivityModifier:     .long (0x8A3 << 12) / 0x472

ToggleVisor_Func: .long TOGGLE_VISOR_FUNC

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Player walking
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Jumped here from 0x02024b24 and 0x02024f14 (in USA v1.1)
@  02024b20 | 6c 13 9a e5 | ldr r1, [r10, #0x36c]
@ *02024b24 | 00 00 9d e5 | ldr r0, [sp,]
@ ...
@  02024f10 | 70 13 9a e5 | ldr r1, [r10, #0x370]
@ *02024f14 | 00 00 9d e5 | ldr r0, [sp]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Function argument: r0 = 0 (left/right) or 1 (forward/backward)
PlayerWalk_Function:
    push    {r1-r5}

    @ Get the CPad values
    ldr     r5, RTComDataOutput
    ldrh    r4, [r5, #0]
    cmp     r4, #0
    beq     PlayerWalk_Exit

    cmp     r0, #0
    bne     MoveVertically

MoveHorizontally:
    @ turn on the horizontal move state (whatever it is)
    ldr     r0, [r10, #0x4c4]
    orr     r0, r0, #0x2000
    str     r0, [r10, #0x4c4]

    @ Split CPad Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    mov     r4, r4, lsl #24
    mov     r4, r4, asr #24
    @ Sign extend Y
    mov     r5, r5, asr #24

    @@ Remap vector components from (0; CPAD_MaxRadius) to (0; MaxSpeed)
    ldr     r3, WalkSpeedModifier
    mul     r0, r3, r4
    mul     r1, r3, r5
    @@ Back to integers
    asr     r0, #0xC
    asr     r1, #0xC
    @@ Save Y for the next round
    str     r1, Cached_CPad_Y

    cmp     r0, #0
    rsblt   r0, #0      @ take "Abs" of the resultant speed
    addlt   lr, #0x210  @ Move left
    addge   lr, #0x7C   @ Move right
    pop     {r1-r5}
    bx      lr

MoveVertically:
    ldr     r0, Cached_CPad_Y
    cmp     r0, #0
    rsblt   r0, #0      @ take "Abs" of the resultant speed
    addlt   lr, #0x1DC  @ Move backward
    addge   lr, #0x70   @ Move forward
    pop     {r1-r5}
    bx      lr

PlayerWalk_Exit:
    pop     {r1-r5}
    @ execute the replaced instructions
    cmp     r0, #0
    ldreq   r1, [r10, #0x36c]
    ldrne   r1, [r10, #0x370]
    ldr     r0, [sp, #0x0]
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

Cached_CPad_Y:  .long 0

CPAD_MaxRadius  = 0x69
MaxSpeed        = 0x1c2
WalkSpeedModifier: .long (MaxSpeed << 12) / CPAD_MaxRadius

RTComDataOutput:        .long 0x027ffdf0

@ MoveRight_ExitAddr:     .long 0x02024ba4    @ + 0x80 
@ MoveLeft_ExitAddr:      .long 0x02024d38    @ + 0x214
@ MoveForward_ExitAddr:   .long 0x02024f88    @ + 0x464 ; + 0x74
@ MoveBackward_ExitAddr:  .long 0x020250f4    @ + 0x5D0 ; + 0x1E0



