@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02039bf8 | 01 0c 80 e1 | orr r0,r0,r1, lsl #0x18
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
tony_hawk_read_accelerometer:
    push    {r1-r6, lr}

    ldr     r5, rtcom_output
    ldrsh   r0, [r5, #10]
    bl      __normalize_axis
    mov     r4, r0

    ldrsh   r0, [r5, #12]
    bl      __normalize_axis
    orr     r4, r0, lsl #8

    ldrsh   r0, [r5, #14]
    bl      __normalize_axis
    orr     r4, r0, lsl #16

    orr     r0, r4, #0x01000000
    pop     {r1-r6, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 02069e4a | ff f7 dd ff | bl Start_Accel_Communication_Hue
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
hue_pixel_painter_read_accelerometer:
    ldr     r2, [lr, #0x35]

    ldr     r3, rtcom_output
    ldrsh   r0, [r3, #6]
    bl      __normalize_axis
    lsl     r0, #4
    str     r0, [r2, #4]

    ldrsh   r0, [r3, #8]
    rsb     r0, #0
    bl      __normalize_axis
    lsl     r0, #4
    str     r0, [r2, #0]

    ldrsh   r0, [r3, #14]
    bl      __normalize_axis
    lsl     r0, #4
    str     r0, [r2, #0x10]

    mov     r0, #1
    pop     {r3, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
__normalize_axis:
    rsb     r0, #0
    add     r0, #128
    asr     r0, #8

    cmp     r0, #2
    bgt     __normalize_axis__clamp
    cmp     r0, #-2
    movge   r0, #0

__normalize_axis__clamp:
    add     r0, #128
    cmp     r0, #256
    movgt   r0, #256
    cmp     r0, #0
    movlt   r0, #0
    bx      lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

rtcom_output:        .long 0x027ffdf0
