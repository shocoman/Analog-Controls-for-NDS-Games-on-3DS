.thumb

Main:
    @ execute overwritten instructions
    mov     r5, #0x0
    add     r0, r0, #0x7
    ldrsb   r5, [r0, r5]

    push {r0-r7, lr}
    mov r6, sp @ backup SP

    @@@ START: Getting ZL&ZR&Nub data
I2C_Read_ZL_ZR_and_Nub:
    @ I2C_Read(_, output, device_id, address, read_length)
    mov r4, #0x7
    mov r3, #0x0
    mov r2, #0xe

    @ Align the stack pointer and save the result there
    mov r1, sp
    sub r1, #0xC
    bic r1, r4
    mov sp, r1
    
    push {r4}
    ldr r0, I2cRead_FuncAddress
    blx r0
    @@@ END: Getting ZL&ZR&Nub data


WriteDataIntoRtcRegs:
    ldr r4, LegacyRtcRegs_Address

    ldr r2, CPAD_Address
    ldrb r0, [r2, #0x0] @ CPad X
    ldrb r1, [r2, #0x2] @ CPad Y
    lsl r1, #8
    orr r0, r1
    lsl r0, #8
    str r0, [r4, #0x34] @ RTC ALRMTIM2 (CPadX => Hour, CPadY => DoW)

    @@@ START: Saving ZL&ZR&Nub data
    mov r2, sp
    ldrb r1, [r2, #0x5] @ Nub "mode" and ZL/ZR buttons: [_, _, _, ZL&ZR (ZL=3rd bit, ZR=2nd bit)]
    ldr r0, [r2, #0x8]  @ Load Nub positions: [?, NubY, NubX, ?]
    lsr r0, #8          @ [_, ?, NubY, NubX]
    lsl r0, #8          @ [?, NubY, NubX, _]
    orr r0, r1          @ [?, NubY, NubX, ZL&ZR]
    str r0, [r4, #0x40] @ RTC COUNTER (ZLZR => LSB, NubX => MID, NubY => MSB)
    @@@ END: Saving ZL&ZR & Nub data


    @@ Update Rtc on the NDS side
    movs    r0, #0x33 @ ALRMDAT2, ALRMDAT1, COUNT, ALRMTIM2
    lsl     r0, #6
    ldrh    r1, [r4]
    orr     r1, r0
    strh    r1, [r4] @ rtc control reg; 

Finish:
    mov sp, r6
    pop {r0-r7, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
LegacyRtcRegs_Address:  .long 0x1EC47100

CPAD_Address:           .long 0x0 @ filled at runtime
I2cRead_FuncAddress:    .long 0x0 @ filled at runtime
