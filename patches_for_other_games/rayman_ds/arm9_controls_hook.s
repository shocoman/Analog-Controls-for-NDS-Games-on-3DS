LoadValueFromStick:
    push {r0-r5, lr}

    @ Get the stick values
    ldr r4, RTCom_Output
    ldrh r4, [r4, #0]
    cmp r4, #0
    bne Read_CPAD

    @ skip & try read the touchscreen's joystick instead
    pop {r0-r5, lr}
    cmp r0, #0x0 @ put back the replaced instruction
    bx lr

Read_CPAD:
    @ Split stick Y and X components
    mov r5, r4, lsl #16
    @ Sign extend X
    mov r4, r4, lsl #24
    mov r4, r4, asr #24
    @ Sign extend Y
    mov r5, r5, asr #24

    @@ Remap X and Y components from (0; CPAD_MaxRadius) to (0; Rayman_Stick_MaxRadius)
    ldr r3, CPAD_to_RaymanStick_Ratio
    mul r0, r3, r4
    mul r2, r3, r5
    @@ Back to integers
    add r0, #0x800
    asr r0, #0xC
    add r2, #0x800
    asr r2, #0xC

    @ Write
    strb r0, [r1, #-1] @ r1 will contain the required address for the player's velocity
    strb r2, [r1, #0]

    pop {r0-r5,lr}
    add lr, #0x24     @ skip the usual routine to read the touchscreen's joystick
    bx lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

CPAD_MaxRadius              = 0x69
Rayman_Stick_MaxRadius      = 0x64
CPAD_to_RaymanStick_Ratio:  .long (Rayman_Stick_MaxRadius << 12) / CPAD_MaxRadius

RTCom_Output: .long 0x027ffdf0


