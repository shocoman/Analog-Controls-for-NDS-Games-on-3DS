@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02024f3c | 88 15 97 e5 | ldr r1,[r7,#0x588]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
@ r7 - game state
@ *(r7 + 0x584) - Velocity.X
@ *(r7 + 0x58C) - Velocity.Z
move_with_cpad:
    ldr     r1,[r7,#0x588] @ replaced opcode
    push    {r0-r6, lr}

    @ Rotate camera if L or R are pressed
    ldr     r4, keys_held_address @ dpad addr
    ldrh    r4, [r4] @ keyinput
    tst     r4, #1 << 8     @ key R
    ldrne   r3, turn_camera_right_func
    blxne   r3
    tst     r4, #1 << 9     @ key L
    ldrne   r3, turn_camera_left_func
    blxne   r3

    ldr     r3, is_allowed_to_move_ptr
    ldrb    r3, [r3]
    cmp     r3, #1
    popne   {r0-r6, pc}

    @ Get the stick values
    ldr     r3, rtcom_output
    ldrh    r3, [r3, #0]
    cmp     r3, #0
    
    @ popeq   {r0-r6, pc} @ don't use the CPad if it's not touched
    beq     __reduce_speed_and_exit

read_cpad:
    @ Split stick Y and X components
    mov     r5, r3, lsl #16
    @ Sign extend X
    lsl     r4, r3, #24
    asr     r4, #24
    @ Sign extend Y
    asr     r5, #24

    @ rescale (-0x69;0x69) => (-0xffff;0xffff)
    ldr     r3, speed_ratio
    mul     r4, r3, r4
    asr     r4, #12
    mul     r5, r3, r5
    asr     r5, #12

    @ set direction (swap X and Y)
    str     r5, [r7, #0x584] @ set Y
    str     r4, [r7, #0x58C] @ set X

    @ schedule speed decrease right after we release the CPad
    mov     r3, #1
    str     r3, is_speed_decrease_needed

    pop     {r0-r6, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Gradually reduce Dude's speed, when the CPad has been released (and the touchscreen isn't being used)
__reduce_speed_and_exit:
    ldr     r3, is_speed_decrease_needed
    cmp     r3, #0
    beq     __reduce_speed_and_exit_end

    @ check if the touchscreen is used
    ldr     r2, [r7, #0x5C0]
    cmp     r2, #0
    @ if the touchscreen is being used, we don't interfere and delegate it the full control over the speed
    bne     __reduce_speed_and_exit__stop_decrease
    @ same; if the speed is down at zero, we shouldn't control it anymore
    ldr     r2, [r7, #0x584]
    ldr     r3, [r7, #0x58C]
    cmp     r2, #0
    cmpeq   r3, #0
    bne     __reduce_speed_and_exit__main

__reduce_speed_and_exit__stop_decrease:
    mov     r3, #0
    str     r3, is_speed_decrease_needed
    b       __reduce_speed_and_exit_end

__reduce_speed_and_exit__main:
    @ decelerate depending on the current speed (faster movement => stronger deceleration)
    ldr     r0, =0x584
    add     r0, r7
    ldr     r3, vector_length_func
    blx     r3
    mov     r1, r0

    ldr     r3, deceleration_ratio
    mul     r0, r3, r1
    asr     r2, r0, #12 - 2

    cmp     r2, #0x800
    movlt   r2, #0x800
    cmp     r1, #0x300 @ when speed is low, just stop quickly
    movlt   r2, #0x2000

    str     r2, [r7, #0x580] @ set deceleration speed

__reduce_speed_and_exit_end:
    pop     {r0-r6, pc}

is_speed_decrease_needed: .long 0

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
cpad_maxradius      = 0x69
max_speed           = 0xFFFF
max_deceleration    = 0x3C00

speed_ratio:                .long (max_speed << 12) / cpad_maxradius
deceleration_ratio:         .long (max_deceleration << 12) / max_speed

rtcom_output:               .long 0x027ffdf0
is_allowed_to_move_ptr:     .long IS_ALLOWED_TO_MOVE_PTR
keys_held_address:          .long KEYS_HELD_ADDRESS
turn_camera_left_func:      .long TURN_CAMERA_LEFT_FUNC
turn_camera_right_func:     .long TURN_CAMERA_LEFT_FUNC + 0x58
vector_length_func:         .long VECTOR_LENGTH_FUNC

