@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020d6674 | 30 00 83 e2 | add r0,r3,#0x30
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ r4 - should return the movement direction
@ r5 - should return the speed
move_with_cpad:
    add     r0, r3, #0x30 @ overwritten opcode
    push    {r0-r3, r6, r8, lr}

    @ Get the stick values
    ldr     r3, rtcom_output
    ldrh    r3, [r3, #0]
    cmp     r3, #0

    popeq   {r0-r3, r6, r8, pc} @ don't use the CPad if it's not touched

read_cpad:
    mov     r6, r5 @ backup the original speed

    @ Split stick Y and X components
    @ Sign extend X & negate
    mov     r4, r3, lsl #24
    asr     r4, #24
    rsb     r4, #0
    @ Sign extend Y    
    lsl     r5, r3, #16
    asr     r5, #24

    @@ Angle
    mov     r0, r4
    mov     r1, r5
    ldr     r3, get_angle_func
    blx     r3
    mov     r1, #move_dir_multiplier
    mul     r8, r1, r0
    asr     r8, #12

    @@ Speed (rescale the CPad X&Y to the current speed)
    mov     r0, #0
    push    {r0,r4,r5}
    mov     r0, sp
    ldr     r1, vec_length_func
    blx     r1
    mov     r2, #speed_multiplier
    mul     r2, r0, r2
    mul     r5, r2, r6 @ return speed in R5
    asr     r5, #12
    add     sp, #12

    mov     r4, r8 @ return direction in R4

    pop     {r0-r3, r6, r8, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_max_radius     = 0x69
move_dir_multiplier = ((360 << 12) / 0xffff) @ [0;0xFFFF] => [0; 360]
speed_multiplier    = ((1 << 12) / cpad_max_radius)

vec_length_func:    .long VEC_LENGTH_FUNC
get_angle_func:     .long GET_ANGLE_FUNC


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020d64b8 | 05 60 a0 e1 | mov r6,r5
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
run_with_zr:
    mov     r6, r5  @ overwritten opcode

    @@ check if ZR is pressed
    ldr     r2, rtcom_output
    ldrb    r1, [r2, #4]
    tst     r1, #0x2

    addne   lr, #8 @ pretend we're actually running
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020d5ec4 | 00 50 a0 e1 | mov r5,r0
@ R5 - is pen down
@ *(sp + 0x24) - touch delta X
@ *(sp + 0x20) - touch delta Y
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
control_camera_with_cstick:
    mov     r5, r0  @ replaced opcode
    push    {r0-r4, r6, lr}
    
    @@ read CStick X
    mov     r0, #0
    bl      read_cstick_func
    mov     r6, r0
    
    @@ read CStick Y
    mov     r0, #1
    bl      read_cstick_func
    mov     r4, r0
   
    @ Check if the CStick is actually being used
    cmp     r4, #0
    cmpeq   r6, #0
    beq     skip_cstick

    @ Add the CStick values to the current Touchscreen Delta variables
    mov     r5, #1
    ldr     r0, [sp, #0x20 + 7*4] @ get delta_touch.Y
    ldr     r1, [sp, #0x24 + 7*4] @ get delta_touch.X
    add     r0, r4                @ add CStick.Y
    add     r1, r6                @ add CStick.X
    str     r0, [sp, #0x20 + 7*4] @ set new delta_touch.Y
    str     r1, [sp, #0x24 + 7*4] @ set new delta_touch.X

skip_cstick:
    pop     {r0-r4, r6, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ r0 = 0 => return X; 
@ r0 = 1 => return Y; 
read_cstick_func:
    cmp     r0, #0

    ldr     r0, rtcom_output
    ldreqsh r0, [r0, #6] 
    ldrnesh r0, [r0, #8] 
    rsb     r0, #0

    ldr     r3, sensitivity
    mul     r0, r3, r0

    bx lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
rtcom_output:       .long 0x027ffdf0

sensitivity:        .long 0x20
