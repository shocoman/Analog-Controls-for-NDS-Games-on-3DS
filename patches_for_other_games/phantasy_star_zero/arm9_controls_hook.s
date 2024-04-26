@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 0203d3a6 | 04 1c | adds r4,r0,#0x0
@ 0203d3a8 | 20 2d | cmp r5,#0x20
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
move_with_cpad:
    push    {r1-r3, r5-r6, lr}
    mov     r6, r0 @ save camera angle

    @ Get the stick values
    ldr     r3, rtcom_output
    ldrh    r3, [r3]
    cmp     r3, #0
    bne     read_cpad

    @ overwritten opcodes
    mov     r4, r0
    cmp     r5, #0x20
    pop     {r1-r3, r5-r6, pc}

read_cpad:
    @ Split stick Y and X components
    mov     r5, r3, lsl #16
    @ Sign extend X & negate
    lsl     r3, #24
    asr     r3, #24
    @ Sign extend Y
    asr     r5, #24
    rsb     r5, #0

    @@ Get direction to move
    mov     r0, r3
    mov     r1, r5
    ldr     r5, get_angle_func
    blx     r5
    
    add     r0, r6  @ add camera angle
    lsl     r0, #0x10
    lsr     r0, #0x10

    @ return result in R0
    pop     {r1} @ consume last LR
    pop     {r1-r3, r5-r6}
    pop     {r3-r5, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ + 020bbf72 | push  {lr}
@ 020bbf74 | 01 20 | movs r0,#0x1
@ 020bbf76 | 70 47 | bx lr
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
skip_is_just_pressed:
    @ is the key even pressed
    beq     skip_is_just_pressed__no

    @ is DPad key
    tst     r0, #0xF0
    beq     skip_is_just_pressed__yes

    @ is CPad used
    ldr     r3, rtcom_output
    ldrh    r3, [r3]
    cmp     r3, #0
    bne     skip_is_just_pressed__no

skip_is_just_pressed__yes:
    mov     r0, #1
    pop     {pc}

skip_is_just_pressed__no:
    mov     r0, #0
    pop     {pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02071384 | 20 1c | adds r0,r4,#0x0
@ 02071386 | 88 30 | adds r0,#0x88
@ r4 - camera state
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
manual_camera_control:
    add     r0, r4, #0x88 @ replaced opcode
    push    {r0-r3, r5-r6, lr}

    ldr     r0, rtcom_output
    ldrsh   r2, [r0, #6] @ CStick.X
    ldrsh   r3, [r0, #8] @ CStick.Y

    @ Update Camera.X
    ldrsh   r6, [r4, #0x82]
    add     r6, r2, lsl #4
    strh    r6, [r4, #0x82]
    @ stop camera centering (on L)
    mov     r0, #0
    cmp     r2, #0
    strneh  r0, [r4, #0x88]
    @ Update Camera.Y
    ldrsh   r5, [r4, #0x80]
    add     r5, r3, lsl #4
    cmp     r5, #0
    movlt   r5, #0
    cmp     r5, #0x3000
    movgt   r5, #0x3000
    strh    r5, [r4, #0x80]

    pop    {r0-r3, r5-r6, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020714ce | 80 03 | lsls r0,r0,#0xe
@ 020714d0 | 83 42 | cmp r3,r0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
fix_auto_camera_rotation:
    lsl     r0, #0xe @ replaced opcode
    
    cmp     r3, #0xe000
    bgt     fix_auto_camera_rotation__dont_rotate
    cmp     r3, #0xa000
    bge     fix_auto_camera_rotation__rotate
    cmp     r3, #0x6000
    bgt     fix_auto_camera_rotation__dont_rotate
    cmp     r3, #0x2000
    bge     fix_auto_camera_rotation__rotate

fix_auto_camera_rotation__dont_rotate:
    mov     r0, #0
    cmp     r0, #0
    bx      lr
fix_auto_camera_rotation__rotate:
    mov     r0, #0
    cmp     r0, #1
    bx      lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020bbeda | 08 80 | strh r0,[r1,#0x0]
@ 020bbedc | 0c 88 | ldrh r4,[r1,#0x0]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
update_zlzr_buttons_state:
    @ replaced opcodes
    strh    r0, [r1,#0x0]
    ldrh    r4, [r1,#0x0]

    push    {r0-r3, lr}
    ldr     r3, rtcom_output
    ldrb    r0, [r3, #4]
    ldrb    r1, zlzr_state_last_frame

    eor     r2, r0, r1
    and     r3, r1, r2 @ released (OLD & (NEW ^ OLD))
    and     r2, r0, r2 @ pressed (NEW & (NEW ^ OLD))
    strb    r0, zlzr_state_last_frame
    strb    r2, zl_zr_just_pressed
    strb    r3, zl_zr_just_released
    pop     {r0-r3, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020adb0e | f8 30 | adds r0,#0xf8
@ 020adb10 | 01 68 | ldr r1,[r0,#0x0]
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
activate_secondary_action_panel:
    ldr     r1, [r0, #0xf8] @ replaced opcode
    ldrb    r0, zlzr_state_last_frame
    cmp     r0, #0
    bxeq    lr

    push    {r0-r3, lr}
    ldr     r1, get_action_state_func
    blx     r1
    mov     r1, #1
    str     r1, [r0, #0xd4]
    pop     {r0-r3, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 020acfc6 / 020acf30 / 020acfe4 / 020acf4a | 0f f0 1c f8 | bl isKeyJustPressed
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
use_zlzr_buttons_for_actions__held_keys:
    ldrb    r1, zlzr_state_last_frame
    ldr     r3, is_key_held_func
    b       use_zlzr_buttons_for_actions__main
use_zlzr_buttons_for_actions__released_keys:
    ldrb    r1, zl_zr_just_released
    ldr     r3, is_key_just_released_func
    b       use_zlzr_buttons_for_actions__main
use_zlzr_buttons_for_actions__pressed_keys:
    ldrb    r1, zl_zr_just_pressed
    ldr     r3, is_key_just_pressed_func

use_zlzr_buttons_for_actions__main:
    @ check if ZL/ZR was pressed / pressed
    @ if not, call the default "is_key_pressed/released" and exit
    cmp     r0, #1
    beq     use_zlzr_buttons_for_actions__zr
use_zlzr_buttons_for_actions__zl:
    tst     r1, #0x4
    bxeq    r3
    b       use_zlzr_buttons_for_actions__activate
use_zlzr_buttons_for_actions__zr:
    tst     r1, #0x2
    bxeq    r3

use_zlzr_buttons_for_actions__activate:
    push    {r1-r3, lr}
    ldr     r1, get_action_state_func
    blx     r1
    @ fake opening the secondary action panel (pressing "R")
    mov     r1, #1
    str     r1, [r0, #0xd4]
    mov     r0, #1

    pop     {r1-r3, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

rtcom_output:               .long 0x027ffdf0
get_angle_func:             .long GET_ANGLE_FUNC
is_key_just_pressed_func:   .long (IS_KEY_JUST_PRESSED | 1)
is_key_just_released_func:  .long (IS_KEY_JUST_RELEASED | 1)
is_key_held_func:           .long (IS_KEY_HELD | 1)

get_action_state_func:      .long (GET_ACTION_STATE | 1)

zlzr_state_last_frame:      .byte 0
zl_zr_just_pressed:         .byte 0
zl_zr_just_released:        .byte 0
