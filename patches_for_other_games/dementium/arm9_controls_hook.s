@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0205103c | 20 01 88 e5 | str r0,[r8,#0x120]
@ r8 - game state ptr
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
move_with_cpad:
    str     r0,[r8,#0x120]  @ overwritten opcode
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

    @@ run if ZR is pressed, don't if it isn't
    ldrb    r0, [r3, #4]
    and     r0, #0x2
    lsr     r0, #1
    @ just in case, apply only if "is_running" is 0 or 1 (if it breaks some important functionality)
    ldr     r1, [r8, #0x60]
    cmp     r1, #1
    strlsh  r0, [r8, #0x60] @ is_running variable

    ldrneh  r0, run_speed_multiplier
    ldreqh  r0, walk_speed_multiplier

    @ set Velocity X
    mul     r4, r0, r4
    add     r4, #800
    asr     r4, #12
    str     r4, [r8, #0x118]

    @ set Velocity Z
    mul     r5, r0, r5
    add     r5, #800
    asr     r5, #12
    str     r5, [r8, #0x120] 
    
    pop     {r0-r6, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_max_radius      = 0x69
walk_speed_multiplier:   .short ((0x118 << 12) / cpad_max_radius)
run_speed_multiplier:    .short ((0x160 << 12) / cpad_max_radius)

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02050520 | 00 00 56 e3 | cmp r6,#0x0
@ r0 - Camera Y
@ r6 - Camera X
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
turn_camera_with_cstick:
    push    {r1-r5, lr}

    @@ read CStick
    ldr     r1, rtcom_output
    ldrsh   r2, [r1, #8] @ CStick Y
    ldrsh   r1, [r1, #6] @ CStick X
    rsb     r2, #0

    ldr     r3, sensitivity
    mul     r1, r3, r1
    mul     r2, r3, r2

    add     r6, r1, asr #6 @ update Camera X
    add     r0, r2, asr #6 @ update Camera Y 

    cmp     r6, #0x0 @ overwritten instruction
    pop     {r1-r5, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
rtcom_output:       .long 0x027ffdf0
sensitivity:        .long 0x11
