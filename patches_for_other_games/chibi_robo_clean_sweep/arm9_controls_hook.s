.arch armv5t
.arm

pull_out_plug_cord__key = 0x40 @ "DPad Up" key
open_and_close_menu__ui_button__key = 0x20 @ "DPad Left" key
pickup_and_drop_plug__key = 0x40 @ "DPad Up" key
start_vacuum_cleaner__key = 0x80 @ "DPad Down" key
interact_with_objects__key = 0x4 @ "Select" key

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Interact with objects
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02059e2c | 14 00 d0 e5 | ldrb r0,[r0,#0x14]
@ r0 - Input
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
interaction_part1__fake_touch:
    ldr     r3, [r0, #0x38] @ keys pressed in the current frame
    tst     r3, #interact_with_objects__key @ if certain key is pressed
    
    movne   r3, #2
    strneh  r3, touch_was_faked
    movne   r0, #1 @ the touchscreen is "touched"
    addne   lr, #0x1C

    ldreqb  r0, [r0, #0x14] @ overwritten opcode
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02059fb8 | 00 00 55 e3 | cmp r5,#0x0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
interaction_part2__tap_on_object:
    ldrh    r0, touch_was_faked
    cmp     r0, #0

    movne   r5, #1 @ pretend that we really tapped on the highlighted object and not somewhere else
    cmp     r5, #0x0 @ overwritten opcode
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02059060 | 14 00 d0 e5 | ldrb r0,[r0,#0x14] @ Touch Type
@ r0 - Input
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
interaction_part3__process_and_release_touchscreen:
    ldrh    r3, touch_was_faked
    cmp     r3, #1

    @ r3 = 2: fake long tap?
    movgt   r0, #0x10
    @ r3 = 1: fake "released touchscreen"
    moveq   r0, #0
    @ r3 = 0: go the usual route
    ldrltb  r0, [r0,#0x14] @ overwritten opcode

    @@ go to the next state, if any
    subge   r3, #1
    strgeh  r3, touch_was_faked
    bx      lr

touch_was_faked:    .short 0


.thumb
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02071538 | 80 0f a0 e1 | mov r0,r0, lsl #0x1f
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
pull_or_push_prologue:
    ldr     r3, rtcom_output
    ldrh    r3, [r3]
    cmp     r3, #0
    beq     pull_or_push_prologue__exit
    mov     r0, #0x1
pull_or_push_prologue__exit:
    lsl     r0, #0x1f @ overwritten opcode
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0205ad0c | 91 9a fe eb | bl Read_Touchscreen
@ r1 - ptr to Touch.X, r2 - ptr to Touch.Y
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
use_binoculars:
    ldr     r3, rtcom_output
    ldrh    r3, [r3]
    cmp     r3, #0
    beq     fake_touch_with_cpad__continue_normally

    ldr     r5, [r0, #0x14]
    mov     r4, #1
    orr     r5, r4
    strb    r5, [r0, #0x14]
    b       fake_touch_with_cpad__read_cpad

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0x02072ff0 | 7c 40 fe eb | bl Read_Touchscreen @ climb a pole
@ 0x020744a4 | .. .. .. .. | bl Read_Touchscreen @ climb a wall
@ 0x02071560 | .. .. .. .. | bl Read_Touchscreen @ push a box / pull out a drawer
@ 0x020600d8 | 9e 85 fe eb | bl Read_Touchscreen @ using a squirter
@ ...
@ r1 - ptr to Touch.X, r2 - ptr to Touch.Y
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
fake_touch_with_cpad:
    @ Get the stick values
    ldr     r3, rtcom_output
    ldrh    r3, [r3]
    cmp     r3, #0
    bne     fake_touch_with_cpad__read_cpad

fake_touch_with_cpad__continue_normally:
    ldr     r3, read_touchscreen_func
    bx      r3

fake_touch_with_cpad__read_cpad:
    push    {r3-r5, lr}
    @@ Split CPad Y and X components
    lsl     r5, r3, #16
    @ Sign extend X
    lsl     r3, #24
    asr     r3, #24
    @ Sign extend Y & negate
    asr     r5, #24
    neg     r5, r5

    add     r3, #0xFE / 2
    add     r5, #0xBE / 2

    str     r3, [r1] @ touchscreen.x
    str     r5, [r2] @ touchscreen.y

    mov     r0, #1 @ the touchscreen is "touched"
    pop     {r3-r5, pc}

.align 2
read_touchscreen_func:  .long 0x02001758

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ r5 - Input, r6 - "button" instance
@ r3 - an NDS key to activate the UI button
fake_ui_button_touch:
    mov     r1, r5 @ overwritten opcode
    push    {r0-r3}

    add     r1, #0x38
    ldr     r0, [r1] @ keys pressed in the current frame
    tst     r0, r3
    beq     fake_ui_button_touch__end

    @@ activate the button
    mov     r1, #1
    str     r1, [r6, #0x34] @ button state = 1 (pressed)

    @@ call some button callback function
    push    {lr}
    mov     r0, r6
    ldr     r1, [r0]
    ldr     r1, [r1, #0x48]
    blx     r1

    @@ skip the usual "checkIfButtonWasTouched" routine
    pop     {r0} @ mov     r0, lr
    add     r0, #4
    mov     lr, r0
fake_ui_button_touch__end:
    pop     {r0-r3}
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020260bc | 05 10 a0 e1 | mov r1, r5
@ r6 - button object to open/close menu , r5 - Input
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
open_and_close_menu__ui_button:
    mov     r3, #open_and_close_menu__ui_button__key
    b       fake_ui_button_touch

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0202f334 | 05 10 a0 e1 | mov r1, r5
@ r6 - button object to pull out the cord, r5 - Input
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
pull_out_plug_cord__ui_button:
    mov     r3, #pull_out_plug_cord__key
    b       fake_ui_button_touch

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020262f4 | 10 20 92 e5 | ldr r2,[r2,#0x10]
@ r0 - button object to start the vacuum cleaner, r1 - Input
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
start_vacuum_cleaner__ui_button:
    ldr     r2, [r2, #0x10] @ overwritten opcode

    @@ check if the UI button is enabled and visible
    mov     r3, #0xe0
    ldr     r3, [r0, r3]
    cmp     r3, #1
    bne     start_vacuum_cleaner__ui_button__end

    mov     r6, r0
    mov     r3, #start_vacuum_cleaner__key
    b       fake_ui_button_touch

start_vacuum_cleaner__ui_button__end:
    bx      lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0205bd10 | 14 00 84 e5 | str r0, [r4, #0x14]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
pickup_plug:
    ldr     r1, =0x04000130
    ldrh    r1, [r1]
    mvn     r1, r1
    mov     r2, #pickup_and_drop_plug__key
    tst     r1, r2
    beq     pickup_plug__end

    mov     r0, #1
pickup_plug__end:
    str     r0, [r4, #0x14] @ is_picking_or_dropping = true
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0205bf5c | 80 0f a0 e1 | mov r0,r0, lsl #0x1f
@ r4 - Input
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
drop_plug:
    lsl     r0, #0x1f @ overwritten opcode

    mov     r2, r4
    add     r2, #0x38 @ keys pressed this frame
    ldrb    r1, [r2]
    mov     r2, #pickup_and_drop_plug__key
    tst     r1, r2
    beq     drop_plug__end

    @ pretend that we touched the plug
    mov     r1, lr
    add     r1, #0x20
    mov     lr, r1
    mov     r0, #1          @ is_picking_or_dropping = true
drop_plug__end:
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020a81b0 | d4 10 d0 e5 | ldrb r1,[r0,#0xd4] @ (r0 + 0xC0) - input
@ r9 - answer [0 - Yes, 1 - No, "-1" - no answer (ask again)]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
choose_yes_or_no:
    push    {r0, lr}
    add     r0, #0xC0 @ input
    ldrb    r1, [r0, #0x14] @ touch type

    add     r0, #0x38 @ keys pressed in this frame
    ldrb    r0, [r0] 

    cmp     r0, #1 @ pressed A
    beq     choose_yes_or_no__apply_key
    cmp     r0, #2 @ pressed B
    beq     choose_yes_or_no__apply_key
    b       choose_yes_or_no__end

choose_yes_or_no__apply_key:
    sub     r0, #1
    mov     r9, r0
    mov     r1, #0 @ ignore actual touchscreen input

choose_yes_or_no__end:
    pop     {r0, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0206b9d8 | 00 00 50 e3 | cmp r0,#0x0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
hide_green_marker_when_using_cpad:
    push    {r4, lr}
    bl      load_CPad_into_R4_and_cmp_with_0
    beq     hide_green_marker_when_using_cpad_exit
    mov     r0, #1
hide_green_marker_when_using_cpad_exit:
    cmp     r0, #0x0
    pop     {r4, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
load_CPad_into_R4_and_cmp_with_0:
    ldr     r4, rtcom_output
    ldrh    r4, [r4]
    cmp     r4, #0
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
@ 0206c024 | 30 00 8a e5 | str r0,[r10,#0x30]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
running_fake_touch:
    push    {r0-r4, lr}
    bl      load_CPad_into_R4_and_cmp_with_0
    beq     running_fake_touch__end
    mov     r0, #1
running_fake_touch__end:
    mov     r1, r10
    str     r0, [r1,#0x30] @ "is pen down"
    pop     {r0-r4, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0206c2a8 | 18 00 8a e2 | add r0,r10,#0x18 
@ r0 - ptr to velocity vector
@ r5 - dude position
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
running_with_cpad:
    mov     r0, r10  @ overwritten opcode
    add     r0, #0x18
    push    {r0-r6, lr}
    mov     r6, r10

    @ Get the stick values
    bl      load_CPad_into_R4_and_cmp_with_0
    beq     running_with_cpad__exit

    @@ Calculate new velocity according to the current CPad value
    mov     r0, r4 @ cpad
    mov     r1, r5 @ position
    ldr     r2, [r6, #0x3c]
    ldr     r2, [r2, #0xc] @ <= max speed
    blx     calculate_dude_velocity_from_cpad
    @@ Apply new velocity
    str     r1, [r6, #0x18] @ X
    str     r0, [r6, #0x20] @ Z

running_with_cpad__exit:
    pop     {r0-r6, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0207556c | 34 00 8a e5 | str r0,[r10,#0x34]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
fake_touch_for_vacuuming:
    push    {r0-r4, lr}
    bl      load_CPad_into_R4_and_cmp_with_0
    beq     fake_touch_for_vacuuming__end
    mov     r0, #1
fake_touch_for_vacuuming__end:
    mov     r1, r10
    str     r0, [r1,#0x34] @ "is pen down"
    pop     {r0-r4, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02075814 | 70 00 8d e2 | add r0,sp,#0x70
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
vacuuming_with_cpad:
    add     r0, sp, #0x70 @ overwritten opcode

    push    {r0-r7, lr}
    mov     r7, r0 @ <= velocity

    @ Get the stick values
    bl      load_CPad_into_R4_and_cmp_with_0
    beq     vacuuming_with_cpad__exit

    @@ Calculate new velocity according to the current CPad value
    mov     r0, r4 @ cpad
    add     r1, sp, #0x58 + 9 * 4 @ vacuum cleaner position
    @ mov     r1, r5 @ dude's position
    mov     r2, r10
    ldr     r2, [r2, #0x48]
    ldr     r2, [r2, #0xc] @ max speed
    blx     calculate_dude_velocity_from_cpad
    @@ Apply new velocity
    str     r1, [r7, #0] @ X
    str     r0, [r7, #8] @ Z

vacuuming_with_cpad__exit:
    pop     {r0-r7, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02076620 | 30 00 8a e5 | str r0,[r10,#0x30]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
fake_touch_for_unknown_game_mode:
    push    {r0-r4, lr}
    bl      load_CPad_into_R4_and_cmp_with_0
    beq     fake_touch_for_unknown_game_mode__end
    mov     r0, #1
fake_touch_for_unknown_game_mode__end:
    mov     r1, r10
    str     r0, [r1,#0x30] @ "is pen down"
    pop     {r0-r4, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020768a8 | 14 00 8d e2 | add r0,sp,#0x14
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
unknown_game_mode_with_cpad:
    add     r0, sp, #0x14 @ overwritten opcode

    push    {r0-r7, lr}
    mov     r7, r0 @ <= velocity

    @ Get the stick values
    bl      load_CPad_into_R4_and_cmp_with_0
    beq     unknown_game_mode_with_cpad__exit

    @@ Calculate new velocity according to the current CPad value
    mov     r0, r4 @ cpad
    mov     r1, r5 @ position
    mov     r2, r10
    ldr     r2, [r2, #0x54]
    ldr     r2, [r2, #0x8] @ max speed
    blx     calculate_dude_velocity_from_cpad
    @@ Apply new velocity
    str     r1, [r7, #0] @ X
    str     r0, [r7, #8] @ Z

unknown_game_mode_with_cpad__exit:
    pop     {r0-r7, pc}

.arm
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ r0 - CPad values
@ r1 - dude position vector
@ r2 - max dude's speed
@@@ Returns Velocity X & Y in R0 & R1
calculate_dude_velocity_from_cpad:
    push    {r4-r9, lr}

    mov     r4, r0 @ CPad's X & Y
    mov     r8, r1 @ Dude's position
    mov     r9, r2 @ Max Dude's speed at the moment

    @@ Split CPad Y and X components
    mov     r5, r4, lsl #16
    @ Sign extend X & negate
    lsl     r4, #24
    asr     r4, #24
    rsb     r4, #0
    @ Sign extend Y
    asr     r5, #24

    @@ Get CPad vector length
    mul     r0, r4, r4
    mla     r0, r5, r5, r0
    ldr     r3, sqrt_fp_func
    blx     r3
    ldr     r1, cpad_length_ratio
    mul     r0, r1, r0 @ shifted 12 (as fixed-point) + 6 (from sqrt)
    lsr     r7, r0, #6 @ fixed-point (still shifted 12)

    @@ Get CPad Angle
    mov     r0, r4
    mov     r1, r5
    ldr     r3, get_angle_func
    blx     r3
    mov     r5, r0 @ <= cpad angle

    @@ Get Camera Position
    ldr     r1, global_game_state_addr
    mov     r0, #0x10c
    ldr     r2, [r1]
    ldr     r1, [r2,#0x328]
    add     r2, #0x110
    mla     r0, r1, r0, r2
    ldr     r1, [r0]
    ldr     r1, [r1,#0x14]
    blx     r1
    mov     r6, r0  @ <= camera position vector

    @@ Get Vector (CameraPos => DudePos)
    ldmia   r8, {r0, r1, r2} @ load dude pos
    mov     r1, r2
    ldmia   r6, {r2, r3, r4} @ load camera pos
    sub     r0, r2 @ (Camera => Dude).X
    sub     r1, r4 @ (Camera => Dude).Z
    ldr     r3, get_angle_func
    blx     r3

    @@ Sum the angles and calculate the offsets for sine and cosine to get the final direction to move
    add     r0, r5  @ final angle = camera's angle + cpad's angle
    lsl     r0, #16 @ angle & 0xFFFF
    lsr     r0, #16 + 4

    lsl     r2, r0, #1
    lsl     r1, r2, #1  @ sin offset
    add     r2, #1
    lsl     r0, r2, #1  @ cos offset

    @@ Use the trigonometriclookup table
    ldr     r3, sincos_lookuptable
    ldrsh   r0, [r3, r0] @ cos (-1.0;1.0)
    ldrsh   r1, [r3, r1] @ sin (-1.0;1.0)

    @@ Scale appropriately with the max speed and the current CPad displacement
    mul     r2, r7, r9 @ rescale according to the CPad's displacement
    add     r2, #800
    lsr     r2, #12
    mul     r0, r2, r0  @ multiply by COS
    add     r0, #800
    asr     r0, #12
    mul     r1, r2, r1  @ multiply by SIN
    add     r1, #800
    asr     r1, #12

    @@ return new velocity in R0 & R1
    pop     {r4-r9, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
CPAD_MAX_RADIUS         = 0x69

rtcom_output:           .long 0x027ffdf0
sqrt_fp_func:           .long SQRT_FP_FUNC
cpad_length_ratio:      .long (1 << 12) / 0x65 @ CPAD_MAX_RADIUS
get_angle_func:         .long GET_ANGLE_FUNC

global_game_state_addr: .long 0x02230f30
sincos_lookuptable:     .long SIN_COS_LOOKUP_TABLE
