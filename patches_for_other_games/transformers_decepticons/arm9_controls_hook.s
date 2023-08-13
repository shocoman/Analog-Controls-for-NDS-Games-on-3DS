@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020e0f58 | 01 16 a0 e1 | mov r1, r1, lsl #0xc
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
control_vehicle:
    push    {r0, r2-r6, lr}

    @ Get & sign-extend CPad.X
    ldr     r4, rtcom_output
    ldrsb   r4, [r4, #0]
    cmp     r4, #0

    moveq   r1, r1, lsl #0xc    @ replaced opcode
    popeq   {r0, r2-r6, pc}     @ don't use the CPad if it's not touched

    @@ Rescale Cpad.X: (-0x69;0x69) => (-0x3000;0x3000) (approximately)
    lsl     r4, #7 

    @@ choose the right sign for the direction depending on whether Dpad Left or Dpad Right is pressed
    @ (directions are inverted when moving backwards)
    muls    r2, r1, r4
    neglt   r4, r4

    mov     r1, r4
    pop     {r0, r2-r6, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020d23c0 | b0 11 84 e5 | str r1,[r4,#0x1b0]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
@ r4 - Controls State
move_with_cpad:
    push    {r0-r6, lr}
    mov     r6, r4
    mov     r2, r1

    @ Get the stick values
    ldr     r4, rtcom_output
    ldrh    r4, [r4, #0]
    cmp     r4, #0
    beq     exit @ cpad isn't used

read_cpad:
    @ Split stick Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X
    lsl     r4, #24
    asr     r4, #24
    @ Sign extend Y
    asr     r5, #24

    @@ check if scanner is active
    ldrb    r2, [r6, #0x1a0]
    cmp     r2, #0x11
    @ Scanner is active
    lsleq   r1, r4, #0x7  @ Cpad.X: (-0x69;0x69) => (-0x3000;0x3000)
    negeq   r1, r1
    beq     exit

    @@ punching or throwing a car; don't do anything
    ldr     r0, [r6, #0x1b8] @ mode
    cmp     r0, #3
    bne     exit

    @@ bail out when strafing (shooting with a blaster); it won't work properly anyway (angle must be 0)
    ldrb    r0, [r6, #0x214]
    and     r0, #0xE
    cmp     r0, #0xE
    beq     exit

    @@ Otherwise, do as usual
    @ calculate the direction based on the CPad
    mov     r1, r4
    mov     r0, r5
    ldr     r3, get_angle_func  @ arctan2
    blx     r3
    sub     r0, #0x4000
    @ convert the angle from [0; 0xFFFF] to degrees [0; 0x168000] (degrees 0-360 in fixed-point)
    mov     r1, #0x168
    mul     r0, r1, r0
    asr     r1, r0, #4

exit:
    str     r1, [r6, #0x1b0] @ finally set the direction
    pop     {r0-r6, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
CPAD_MAXRADIUS      = 0x69
rtcom_output:       .long 0x027ffdf0
get_angle_func:     .long GET_ANGLE_FUNC

