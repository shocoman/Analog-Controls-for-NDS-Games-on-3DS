@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0204d170 | 02 a9 | add r1,sp,#0x8
@ 0204d172 | 01 aa | add r2,sp,#0x4
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
fake_touchscreen_press:
    @ overwritten opcodes
    add     r1, sp, #0x8
    add     r2, sp, #0x4

    @ Get the stick values
    ldr     r3, rtcom_output
    ldrh    r3, [r3]
    cmp     r3, #0

    addne   lr, #10
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0204d1d0 | 01 6e | ldr  r1,[r0,#0x60]
@ 0204d1d2 | 49 06 | lsls r1,r1,#0x19
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
fake_touchscreen_press_part2:
    @ overwritten opcodes
    ldr     r1,[r0,#0x60]
    lsls    r1,r1,#0x19

    @ Get the stick values
    ldr     r3, rtcom_output
    ldrh    r3, [r3]
    cmp     r3, #0

    addne   lr, #0x3E
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0204d27e | 09 1d | add r1,r1,#0x4
@ 0204d280 | 03 aa | add r2,sp,#0xc
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ r0 = sp
move_with_cpad:
    @ overwritten opcodes
    add     r1, r1, #0x4 @ dude current position
    add     r2, sp, #0xc @ new destination

    push    {r0-r6, lr}
    @ Get the stick values
    ldr     r3, rtcom_output
    ldrh    r3, [r3]
    cmp     r3, #0
    popeq   {r0-r6, pc}

read_cpad:
    @ Split stick Y and X components
    mov     r5, r3, lsl #16
    @ Sign extend X & negate
    lsl     r3, #24
    asr     r3, #24
    @ Sign extend Y
    asr     r5, #24
    rsb     r5, #0

    ldr     r0, speed_multiplier
    mov     r4, r1
    ldr     r1, [r4, #0]    @ dude_pos.x
    mla     r1, r3, r0, r1
    str     r1, [r2, #0]    @ = new_dest.x

    ldr     r1, [r4, #4]    @ dude_pos.y
    mla     r1, r5, r0, r1
    str     r1, [r2, #4]    @ = new_dest.y

    pop     {r0-r6, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

rtcom_output:       .long 0x027ffdf0

speed_multiplier:   .long 0xC00

