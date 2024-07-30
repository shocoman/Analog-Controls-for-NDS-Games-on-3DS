.thumb

Main:
    @ execute overwritten instructions
    mov     r5, #0x0
    add     r0, r0, #0x7
    ldrsb   r5, [r0, r5]

    push {r0-r7, lr}
    mov r6, sp @ backup SP

WriteDataIntoRtcRegs:
    ldr r4, LegacyRtcRegs_Address

    ldr r2, CPAD_Address
    ldrb r0, [r2, #0x0] @ CPad X
    ldrb r1, [r2, #0x2] @ CPad Y
    lsl r1, #8
    orr r0, r1
    lsl r0, #8
    str r0, [r4, #0x34] @ RTC ALRMTIM2 (CPadX => Hour, CPadY => DoW)

    @@@ START: Getting Accelerometer
I2C_ReadAccel:
    @ I2C_Read(_, output, device_id, address, read_length)

    @ Align the stack pointer and save the result there
    mov r1, sp
    sub r1, #0xC
    mov r2, #0x7
    bic r1, r2
    mov sp, r1
    mov r5, sp

    mov r2, #0x6
    push {r2}
    
    mov r2, #3      @ device id (MCU)
    mov r3, #0x45   @ output register
    ldr r0, I2cRead_FuncAddress
    blx r0
    @@@ END: Getting Accelerometer

    @@ Save Accelerometer data into RTC
    ldr r0, [r5]
    str r0, [r4, #0x60] @ RTC ALRMDAT1
    lsr r0, #24
    ldrh r1, [r5, #4]
    lsl r1, #8
    orr r0, r1
    mov r2, #0x64
    str r0, [r4, r2] @ RTC ALRMDAT2

    @@ Update Rtc on the NDS side
    movs r0, #0x33 @ ALRMDAT2, ALRMDAT1, COUNT, ALRMTIM2
    lsl r0, #6
    ldrh r1, [r4]
    orr r1, r0
    strh r1, [r4] @ rtc control reg; 

Finish:
    mov sp, r6
    pop {r0-r7, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
LegacyRtcRegs_Address:  .long 0x1EC47100

CPAD_Address:           .long 0x0 @ filled at runtime
I2cRead_FuncAddress:    .long 0x0 @ filled at runtime
