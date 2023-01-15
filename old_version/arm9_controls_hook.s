@ Rom version is one of "ASMP-477C", "ASMJ-B74D", "ASMJ-3875", "ASMK-53AF", "ASME-FD28", "ASME-16A0"
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
    push {r0-r5, r7, lr}

    @ Get ZL & ZR button values
    ldr r7, RTC_Date
    ldr r0, [r7, #4]    @ ZLZR (ZL=3rd bit, ZR=2nd bit), _, _, _

    @ Get ZLZR
    mov r3, r0, lsl #29
    mov r3, r3, lsr #30

    @@@ Done on Arm11's side
    @@ Apply nub to turn the camera
    @ mov r1, r0, lsl #8
    @ mov r1, r1, asr #24 @ Sign extend X
    @ cmp r1, #0x18
    @ orrgt r3, #1
    @ cmp r1, #-0x18
    @ orrlt r3, #2

    @ Save the camera turning buttons 
    mov r3, r3, lsl #8
    ldr r7, ControlsStruct
    ldrh r0, [r7, #+0x4] @ "buttons held" offset
    orr r0, r3
    strh r0, [r7, #+0x4]


    @ Get the stick value
    ldr r7, RTC_Date
    ldrh r4, [r7, #0] @ [_, _, CPadY, CPadX]
    cmp r4, #0

    @ bail out if the stick isn't moving
    popeq {r0-r5,r7,lr}
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
    ldr r7, Sqrt64_Func
    blx r7
    @ Normalize the speed to the range [0;0x1000] (i.e. [0.0; 1.0])
    movs r0, r0, lsl #12
    ldr r1, CPAD_MaxRadius
    ldr r7, Div32_Func
    blx r7
    @ Clamp
    cmp r0, #0x1000
    movgt r0, #0x1000
    @ Write
    ldr r7, ControlsStruct
    strh r0, [r7, #+0x8] @ speed offset

    @@ 2) Angle
    movs r0, r4
    movs r1, r5
    ldr r7, GetAngle_Func
    blx r7
    @ Write
    ldr r7, ControlsStruct
    strh r0, [r7, #+0xE] @ angle offset

    @@ 3) Sin
    mov r0, r4, lsl #12
    ldr r1, CPAD_MaxRadius
    ldr r7, Div32_Func
    blx r7
    @ Write
    ldr r7, ControlsStruct
    strh r0, [r7, #+0xA] @ sin offset

    @@ 4) Cos
    mov r0, r5, lsl #12
    ldr r1, CPAD_MaxRadius
    ldr r7, Div32_Func
    blx r7
    @ Write
    ldr r7, ControlsStruct
    strh r0, [r7, #+0xC] @ cos offset

    @ Activate the joystick on the touchscreen
    mov r0, #1
    strb r0, [r7, #+0x14] @ "stick is active" offset

    pop {r0-r5,r7,lr}
    ldr r0, SkipTouchscreenUpdate_ReturnAddress
    bx r0


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

CPAD_MaxRadius: .long 0x69

RTC_Date: .long 0x027ffde8 @ date & time address: year,month,day,day_of_week, hh,mm,ss
Div32_Func: .long 0x01ffabe4

Sqrt64_Func:            .long SQRT_FUNC_ADDRESS
GetAngle_Func:          .long GET_ANGLE_FUNC_ADDRESS
ControlsStruct:         .long CONTROLS_STRUCT_ADDRESS
InputUpdateHookAddress: .long INPUT_UPDATE_INJECT_ADDRESS

UpdateTouchscreen_ReturnAddress: .long (INPUT_UPDATE_INJECT_ADDRESS + 4)
SkipTouchscreenUpdate_ReturnAddress: .long (INPUT_UPDATE_INJECT_ADDRESS + 0x310)

InstructionToJumpHere: .long 0xEA000000 | (((BASE_PATCH_ADDR + (LoadValueFromStick-InitialHook) - INPUT_UPDATE_INJECT_ADDRESS - 8) >> 2 ) & 0x00FFFFFF )
