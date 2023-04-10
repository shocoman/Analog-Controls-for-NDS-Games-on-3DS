@ *0200dd16 01 98            ldr        r0,[sp,#0x4]
@  0200dd18 60 54            strb       r0,[r4,r1]
LoadValueFromStick:

    @ put back the replaced instructions
    ldr     r0, [sp, #0x4]
    strb    r0, [r4, r1]

    push    {r0-r6, lr}
    mov     r6, r4 @ contains address close to where player's speed and angle are located

    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    bne     Read_CPAD

    @ don't use the CPad as it's not touched
    pop     {r0-r6, pc}

Read_CPAD:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    mov     r4, r4, lsl #24
    mov     r4, r4, asr #24
    @ Sign extend Y & negate
    mov     r5, r5, asr #24
    rsb     r5, #0

    @@ 1) Speed
    @ Find vector length
    smull   r0, r1, r4, r4
    smlal   r0, r1, r5, r5
    ldr     r3, Sqrt64_Func
    blx     r3
    @ Normalize the speed to the range [0;0x1000] (i.e. [0.0; 1.0])
    movs    r0, r0, lsl #12
    mov     r1, #CPAD_MaxRadius
    ldr     r3, Div32_Func
    blx     r3
    @ Clamp
    cmp     r0, #RUN_SPEED
    movgt   r0, #RUN_SPEED

    @ Walk if the running button (B) is pressed
    ldrh    r3, Run_Btn_Offset
    ldrb    r1, [r6, r3] @ speed offset
    cmp     r1, #0
    @ if the dude's walking
    ldreqh  r1, Walk_Speed      @ <= Walk by default
    muleq   r0, r1, r0
    asreq   r0, #12
    @ ldrneh  r1, Walk_Speed    @ <= Run by default
    @ mulne   r0, r1, r0
    @ asrne   r0, #12
    @ Write the speed
    mov     r3, #0x130
    strh    r0, [r6, r3] @ speed offset

    @@ 2) Angle
    movs    r0, r4
    movs    r1, r5
    ldr     r3, GetAngle_Func
    blx     r3
    @ Write
    mov     r3, #0x134
    strh    r0, [r6, r3] @ speed offset

    pop     {r0-r6,pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2

CPAD_MaxRadius  = 0x69
WALK_SPEED      = 0xC32
RUN_SPEED       = 0x1000

RTCom_Output:       .long 0x027ffdf0
Walk_Speed:         .short WALK_SPEED
Run_Btn_Offset:     .short 0x136

Sqrt64_Func:        .long SQRT64_FUNC
Div32_Func:         .long DIV32_FUNC
GetAngle_Func:      .long GETANGLE_FUNC


