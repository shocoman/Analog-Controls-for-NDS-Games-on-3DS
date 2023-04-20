.thumb

Main:
    @ execute overwritten instructions
    mov     r5, #0x0
    add     r0, r0, #0x7
    ldrsb   r5, [r0, r5]

    push {r0-r7, lr}


WriteDataIntoRtcRegs:
    ldr r4, LegacyRtcRegs_Address

    ldr r2, CPAD_Address
    ldrb r0, [r2, #0x0] @ CPad X
    ldrb r1, [r2, #0x2] @ CPad Y
    lsl r1, #8
    orr r0, r1
    lsl r0, #8
    str r0, [r4, #0x40] @ RTC ALRMTIM2 (CPadX => LSB, CPadY => MID)

    @@ Update Rtc on the NDS side
    movs r0, #0x32 @ ALRMDAT2, ALRMDAT1, _COUNT_, ALRMTIM2
    lsl r0, #6
    ldrh r1, [r4]
    orr r1, r0
    strh r1, [r4] @ rtc control reg; 

Finish:
    pop {r0-r7, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.align 2
LegacyRtcRegs_Address:  .long 0x1EC47100

CPAD_Address:           .long 0x0 @ filled at runtime
