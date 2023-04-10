@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02027802 | a2 32 | adds r2,#0xa2
@ 02027804 | 12 78 | ldrb r2,[r2,#0x0]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ R1                                    <= dpad_index
@ SP + 0x18                             <= DIR_LUT address
@ DIR_LUT + (dpad_index * 4 + 2) * 2    <= 8-byte dirs (X, Y, run_X, run_Y)
MovePlayerWithCPad:

    push    {r0-r7, lr}
    @ Get the stick values
    ldr     r4, RTCom_Output
    ldrh    r4, [r4]
    cmp     r4, #0
    bne     Read_CPAD

    pop     {r0-r7, lr}
    @ replace instructions
    adds    r2, #0xa2
    ldrb    r2, [r2]
    bx      lr

Read_CPAD:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X & negate
    lsl     r4, #24
    asr     r4, #24
    @ Sign extend Y
    asr     r5, #24
    rsb     r5, #0

    @@ Calculate the table offset
    add     r6, sp, #0x14 + 0x1c
    add     r6, r1, lsl #3

    mov     r3, #0
    push    {r3-r5}
    mov     r0, sp
    ldr     r1, VecLengthFunc
    blx     r1
    mov     r7, r0
    add     sp, #0xC

    @ Normalize X
    mov     r0, r4
    mov     r1, r7
    ldr     r2, Div_FP_Func
    blx     r2
    mov     r4, r0

    @ Normalize Y
    mov     r0, r5
    mov     r1, r7
    ldr     r2, Div_FP_Func
    blx     r2
    mov     r5, r0

    cmp     r7, # (CPAD_MaxRadius * 2) / 3
    movlt   r2, #Dude_MinSpeed
    movge   r2, #Dude_MaxSpeed

    @ Rescale the normalized CPad vec according to the planned current speed
    mul     r0, r2, r4
    mul     r1, r2, r5
    asr     r0, #0xC
    asr     r1, #0xC

    @ Write
    strh    r0, [r6, #8]
    strh    r1, [r6, #10]
    strh    r0, [r6, #12]
    strh    r1, [r6, #14]


    pop     {r0-r7, lr}
    @ replace instructions
    adds    r2, #0xa2
    ldrb    r2, [r2]
    bx      lr
    

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
CPAD_MaxRadius      = 0x69
Dude_MinSpeed       = 0x380
Dude_MaxSpeed       = 0x640

RTCom_Output:       .long 0x027ffdf0
Div_FP_Func:        .long DIV_FUNC
VecLengthFunc:      .long VEC_LENGTH_FUNC
