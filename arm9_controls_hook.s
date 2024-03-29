@ Rom version is one of "ASMP-477C", "ASMJ-B74D", "ASMJ-3875", "ASMK-53AF", "ASME-FD28", "ASME-16A0", "ASMC-4F664FC5"
@ Required symbol names: BASE_PATCH_ADDR, INIT_HOOK_ADDR, INPUT_UPDATE_INJECT_ADDRESS, 
@                        SQRT_FUNC_ADDRESS, GET_ANGLE_FUNC_ADDRESS, CONTROLS_STRUCT_ADDRESS

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Jumped here after the first decompression routine (used only when physically patching the rom)
@ To Be Jumped here From INIT_HOOK_ADDR
InitialHook:
    push {r0-r3,lr}

    ldr r1, InputUpdateHookAddress
    ldr r0, InstructionToJumpHere
    str r0, [r1]

    pop {r0-r3, lr}
    bx lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ To Be Jumped here From INPUT_UPDATE_INJECT_ADDRESS
LoadValueFromStick:
    push {r0-r5, r9, lr}

    @ Get ZL & ZR button values
    ldr r9, RTCom_Output
    ldr r0, [r9, #4]    @ [_, NubY, NubX, ZLZR (ZL=3rd bit, ZR=2nd bit)]

    @ Get ZLZR
    mov r3, r0, lsl #29
    mov r3, r3, lsr #30

    @ Compare old ZLZR with the new one to see if it was pressed this exact frame, or just held
    ldr r0, ZlZr_InPreviousFrame
    str r3, ZlZr_InPreviousFrame
    eor r2, r3, r0
    and r2, r3
    orr r6, r2, lsl #12 @ r6 - Keys pressed this frame
    orr r7, r3, lsl #12 @ r7 - Keys held this frame

    @@ Apply nub to turn the camera
    mov r3, #0
    ldr r0, [r9, #4]
    mov r1, r0, lsl #16
    mov r1, r1, asr #24 @ Sign extend X
    cmp r1, #0xC
    orrgt r3, #2
    cmp r1, #-0xC
    orrlt r3, #1

    @ Save the camera turning buttons
    mov r3, r3, lsl #8
    ldr r9, ControlsStruct
    ldrh r0, [r9, #+0x4] @ "buttons held" offset
    orr r0, r3
    strh r0, [r9, #+0x4]


    @ Get the CPad value
    ldr r9, RTCom_Output
    ldrh r4, [r9, #0] @ [_, _, CPadY, CPadX]

    @ hide the virtual joystick on the bottom screen if we're using the CPad
    mov r0, r4
    bl ToggleVirtualJoystickVisibility

    cmp r4, #0
    @ bail out if the stick isn't moving
    popeq {r0-r5,r9,lr}
    ldreqb r1,[r0,r8,lsl #0x2] @ put back the replaced instruction
    ldreq r0, UpdateTouchscreen_ReturnAddress
    bxeq r0

    @ Split stick Y and X components
    mov r5, r4, lsl #16
    @ Sign extend X
    mov r4, r4, lsl #24
    mov r4, r4, asr #24
    @ Sign extend Y & negate
    mov r5, r5, asr #24
    rsb r5, #0


    @@ 1) Speed
    @ Find vector length
    smull r0, r1, r4, r4
    smlal r0, r1, r5, r5
    ldr r9, Sqrt64_Func
    blx r9
    @ Normalize the speed to the range [0;0x1000] (i.e. [0.0; 1.0])
    movs r0, r0, lsl #12
    ldr r1, CPAD_MaxRadius
    ldr r9, Div32_Func
    blx r9
    @ Clamp
    cmp r0, #0x1000
    movgt r0, #0x1000
    @ Write
    ldr r9, ControlsStruct
    strh r0, [r9, #+0x8] @ speed offset

    @@ 2) Angle
    movs r0, r4
    movs r1, r5
    ldr r9, GetAngle_Func
    blx r9
    @ Write
    ldr r9, ControlsStruct
    strh r0, [r9, #+0xE] @ angle offset

    @@ 3) Sin
    mov r0, r4, lsl #12
    ldr r1, CPAD_MaxRadius
    ldr r9, Div32_Func
    blx r9
    @ Write
    ldr r9, ControlsStruct
    strh r0, [r9, #+0xA] @ sin offset

    @@ 4) Cos
    mov r0, r5, lsl #12
    ldr r1, CPAD_MaxRadius
    ldr r9, Div32_Func
    blx r9
    @ Write
    ldr r9, ControlsStruct
    strh r0, [r9, #+0xC] @ cos offset

    @ Activate the joystick on the touchscreen
    mov r0, #1
    strb r0, [r9, #+0x14] @ "stick is active" offset

    pop {r0-r5,r9,lr}
    ldr r0, SkipTouchscreenUpdate_ReturnAddress
    bx r0


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ r0 == 0 => show the joystick sprite (a target) on the bottom screen (if it's hidden)
@ r0 != 0 => hide it
ToggleVirtualJoystickVisibility:
    push    {r0-r7, lr}
    ldr     r5, noop_opcode
    ldr     r6, show_joystick_opcode 
    ldr     r4, show_joystick_opcode_addr
    ldr     r2, [r4]

    cmp     r0, #0
    bne     hide_joystick

show_joystick:
    cmp     r2, r5 @ only if the joystick was hidden
    bne     toggle_joystick_end
        @ wait for some time (otherwise right after we release the CPad the joystick will temporarily pop up on the screen)
        ldr     r2, timer_to_unblock_joystick
        subs    r2, #1
        str     r2, timer_to_unblock_joystick
        strle   r6, [r4] @ put the previously "noped" instruction back
    b   toggle_joystick_end

hide_joystick:
    mov     r7, #20
    str     r7, timer_to_unblock_joystick

    cmp     r2, r6
    bne     toggle_joystick_end
        @ exclude the joystick texture from the list of BG objects to draw for the Engine B
        ldrh    r0, [r4, #-12]
        sub     r0, #4
        ldr     r3, [r4, r0] @ EngineB_Display_BGs
        ldrb    r1, [r3]
        bic     r1, #4
        strb    r1, [r3]
        @ prevent writing into "EngineB_Display_BGs"
        str     r5, [r4]    @ "nop" the instruction

toggle_joystick_end:
    pop     {r0-r7, pc}

show_joystick_opcode_addr:  .long HIDE_VIRTUAL_JOYSTICK_ADDR
show_joystick_opcode:       .long 0xe3811004 @ orr r1, r1, #0x4
noop_opcode:                .long 0xe1a08008 @ mov r8, r8

timer_to_unblock_joystick:  .long 0x0

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


ZlZr_InPreviousFrame: .long 0
CPAD_MaxRadius: .long 0x69

RTCom_Output: .long 0x027ffdf0
Div32_Func: .long 0x01ffabe4

Sqrt64_Func:            .long SQRT_FUNC_ADDRESS
GetAngle_Func:          .long GET_ANGLE_FUNC_ADDRESS    @ aka arctan2
ControlsStruct:         .long CONTROLS_STRUCT_ADDRESS
InputUpdateHookAddress: .long INPUT_UPDATE_INJECT_ADDRESS

UpdateTouchscreen_ReturnAddress: .long (INPUT_UPDATE_INJECT_ADDRESS + 4)
SkipTouchscreenUpdate_ReturnAddress: .long (INPUT_UPDATE_INJECT_ADDRESS + 0x310)

InstructionToJumpHere: .long 0xEA000000 | (((BASE_PATCH_ADDR + (LoadValueFromStick-InitialHook) - INPUT_UPDATE_INJECT_ADDRESS - 8) >> 2 ) & 0x00FFFFFF )
