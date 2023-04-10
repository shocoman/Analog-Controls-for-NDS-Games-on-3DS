@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0207a948 | 68 01 95 e5 | ldr r0,[r5,#0x168]
@ r5 - game state ptr
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
MoveWithCPad:
    ldr     r0,[r5,#0x168] @ overwritten instruction
    push    {r0-r6, lr}
    mov     r6, r5

    @ Get the stick values
    ldr     r3, RTCom_Output
    ldrh    r4, [r3, #0]
    cmp     r4, #0

    popeq   {r0-r6, pc} @ don't use the CPad if it's not touched

Read_CPAD:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X & negate
    lsl     r4, #24
    asr     r4, #24
    rsb     r4, #0
    @ Sign extend Y
    asr     r5, #24

    @ check if ZR is pressed
    ldrb    r0, [r3, #4]
    tst     r0, #0x2

    @ start running if ZR is pressed
    movne   r0, #1
    strne   r0, [r6, #0x60] @ is running

    ldrneh  r0, Run_SpeedMultiplier
    ldreqh  r0, Walk_SpeedMultiplier

    @ set Velocity X
    mul     r4, r0, r4
    add     r4, #800
    asr     r4, #12
    str     r4, [r6, #0x164]

    @ set Velocity Z
    mul     r5, r0, r5
    add     r5, #800
    asr     r5, #12
    str     r5, [r6, #0x16c] 
    
    pop     {r0-r6, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
CPAD_MaxRadius      = 0x69
Walk_SpeedMultiplier:   .short ((0x96 << 12) / CPAD_MaxRadius)
Run_SpeedMultiplier:    .short ((0x12C << 12) / CPAD_MaxRadius)

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0207a084 | 00 00 56 e3 | cmp r6,#0x0
@ r0 - Camera Y
@ r6 - Camera X
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
TurnCameraWithCStick:
    push    {r1-r5, lr}

    @@ read CStick
    ldr     r1, RTCom_Output
    ldrsh   r2, [r1, #8] @ CStick Y
    ldrsh   r1, [r1, #6] @ CStick X
    rsb     r2, #0

    ldr     r3, Sensitivity
    mul     r1, r3, r1
    mul     r2, r3, r2

    add     r6, r1, asr #6 @ update Camera X
    add     r0, r2, asr #6 @ update Camera Y 

    cmp     r6, #0x0 @ overwritten instruction
    pop     {r1-r5, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
RTCom_Output:       .long 0x027ffdf0
Sensitivity:        .long 0x11
