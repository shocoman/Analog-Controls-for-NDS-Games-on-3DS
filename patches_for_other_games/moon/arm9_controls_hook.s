@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02073aac | 07 00 90 e8 | ldmia r0,{r0,r1,r2}
@ r6 - game state ptr
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
move_with_cpad:
    ldmia   r0,{r0,r1,r2}  @ overwritten opcode
    push    {r0-r6, lr}

    @ Get the stick values
    ldr     r3, rtcom_output
    ldrh    r4, [r3, #0]
    cmp     r4, #0

    popeq   {r0-r6, pc} @ don't use the CPad if it's not touched

read_cpad:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X & negate
    lsl     r4, #24
    asr     r4, #24
    rsb     r4, #0
    @ Sign extend Y
    asr     r5, #24

    ldrh    r0, run_speed_multiplier
    @ set Velocity X
    mul     r4, r0, r4
    add     r4, #800
    asr     r4, #12
    str     r4, [r6, #0x120]

    @ set Velocity Z
    mul     r5, r0, r5
    add     r5, #800
    asr     r5, #12
    str     r5, [r6, #0x128] 
    
    pop     {r0-r6, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
.align 2
cpad_max_radius      = 0x69
run_speed_multiplier:   .long ((0x150 << 12) / cpad_max_radius)

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020731c8 | 00 00 55 e3 | cmp r5,#0x0
@ r0 - Camera Y
@ r5 - Camera X
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
turn_camera_with_cstick:
    push    {r1-r4, lr}

    @@ read CStick
    ldr     r1, rtcom_output
    ldrsh   r2, [r1, #8] @ CStick Y
    ldrsh   r1, [r1, #6] @ CStick X
    rsb     r2, #0

    ldr     r3, sensitivity
    mul     r1, r3, r1
    mul     r2, r3, r2

    add     r5, r1, asr #6 @ update Camera X
    add     r0, r2, asr #6 @ update Camera Y 

    cmp     r5, #0x0 @ overwritten instruction
    pop     {r1-r4, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
rtcom_output:       .long 0x027ffdf0
sensitivity:        .long 0x11
