
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020a93dc | 00 20 a0 e1 | cpy  r2,r0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
@ 0209f54c | 02 05 80 03 | orreq    r10,r10,#0x800000   <- activate running

MovePlayerWithCPad:
    @ put back the replaced instruction
    mov     r2, r0

    push    {r4-r6, lr}
    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4, #0]
    cmp     r4, #0

    popeq   {r4-r6, pc} @ don't use the CPad if it's not touched

Read_CPAD:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    lsl     r4, #24
    asr     r4, #24
    @ Sign extend Y & negate
    asr     r5, #24

    @@ Angle
    mov     r1, r4
    mov     r0, r5
    ldr     r3, GetAngle_Func
    blx     r3
    add     r6, r0, #0x4000 @ angle

    @ cmp     r10, #0x2000000
    ldr     r3, GameStateStruct
    cmp     r10, r3
    bne     End

        @ Length
        mov     r0, r4
        mov     r1, r5
        ldr     r2, Vec2D_Length_Func
        blx     r2

        @ activate running
        cmp     r0, #(CPAD_MaxRadius * 2) / 3
        ldrlt   r0, [r10, #0xc]
        biclt   r0, #0x800000
        strlt   r0, [r10, #0xc]


End:
    mov     r0, r6
    pop     {r4-r6, lr}
    pop     {r3, pc}    @ skip & return to the second function right away


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
CPAD_MaxRadius      = 0x69
RTCom_Output:       .long 0x027ffdf0
GetAngle_Func:      .long GET_ANGLE_FUNC
Vec2D_Length_Func:  .long VEC2D_LENGTH_FUNC

GameStateStruct:    .long GAME_STATE_STRUCT
