#include <nds.h>

#include "arm7_rtcom_patch_uc11.h"
#include "rtcom.h"

// Delay (in swiDelay units) for each bit transfer
#define RTC_DELAY 48

// Pin defines on RTC_CR
#define CS_0 (1 << 6)
#define CS_1 ((1 << 6) | (1 << 2))
#define SCK_0 (1 << 5)
#define SCK_1 ((1 << 5) | (1 << 1))
#define SIO_0 (1 << 4)
#define SIO_1 ((1 << 4) | (1 << 0))
#define SIO_out (1 << 4)
#define SIO_in (1)

#define RTC_READ_112 0x6D
#define RTC_WRITE_112 0x6C

#define RTC_READ_113 0x6F
#define RTC_WRITE_113 0x6E

__attribute__((section(".text"))) static int RTCOM_STATE = 0;
__attribute__((section(".text"))) static int FRAME_COUNTER = 0;

static void waitByLoop(volatile int count) {
    while (--count) {
    }
}

static void rtcTransferReversed(u8 *cmd, u32 cmdLen, u8 *result, u32 resultLen) {
    // Raise CS
    RTC_CR8 = CS_0 | SCK_1 | SIO_1;
    waitByLoop(2);
    RTC_CR8 = CS_1 | SCK_1 | SIO_1;
    waitByLoop(2);

    // Write command byte (high bit first)
    u8 data = *cmd++;

    for (u32 bit = 0; bit < 8; bit++) {
        RTC_CR8 = CS_1 | SCK_0 | SIO_out | (data >> 7);
        waitByLoop(9);

        RTC_CR8 = CS_1 | SCK_1 | SIO_out | (data >> 7);
        waitByLoop(9);

        data <<= 1;
    }
    // Write parameter bytes (high bit first)
    for (; cmdLen > 1; cmdLen--) {
        data = *cmd++;
        for (u32 bit = 0; bit < 8; bit++) {
            RTC_CR8 = CS_1 | SCK_0 | SIO_out | (data >> 7);
            waitByLoop(9);

            RTC_CR8 = CS_1 | SCK_1 | SIO_out | (data >> 7);
            waitByLoop(9);

            data <<= 1;
        }
    }

    // Read result bytes (high bit first)
    for (; resultLen > 0; resultLen--) {
        data = 0;
        for (u32 bit = 0; bit < 8; bit++) {
            RTC_CR8 = CS_1 | SCK_0;
            waitByLoop(9);

            RTC_CR8 = CS_1 | SCK_1;
            waitByLoop(9);

            data <<= 1;
            if (RTC_CR8 & SIO_in)
                data |= 1;
        }
        *result++ = data;
    }

    // Finish up by dropping CS low
    waitByLoop(2);
    RTC_CR8 = CS_0 | SCK_1;
    waitByLoop(2);
}

static u8 readReg112() {
    u8 readCmd = RTC_READ_112;
    u8 readVal = 0;
    rtcTransferReversed(&readCmd, 1, &readVal, 1);
    return readVal;
}

static void writeReg112(u8 val) {
    u8 command[2] = {RTC_WRITE_112, val};
    rtcTransferReversed(command, 2, 0, 0);
}

static u8 readReg113() {
    u8 readCmd = RTC_READ_113;
    u8 readVal = 0;
    rtcTransferReversed(&readCmd, 1, &readVal, 1);
    return readVal;
}

static void writeReg113(u8 val) {
    u8 command[2] = {RTC_WRITE_113, val};
    rtcTransferReversed(command, 2, 0, 0);
}

u16 rtcom_beginComm() {
    u16 old_reg_rcnt = REG_RCNT;
    REG_IF = IRQ_NETWORK;
    REG_RCNT = 0x8100; // enable irq
    REG_IF = IRQ_NETWORK;
    return old_reg_rcnt;
}

void rtcom_endComm(u16 old_reg_rcnt) {
    REG_IF = IRQ_NETWORK;
    REG_RCNT = old_reg_rcnt;
}

u8 rtcom_getData() { return readReg112(); }

bool rtcom_waitStatus(u8 status) {
    int timeout = 50000;
    // int timeout = 2062500;
    do {
        if (!(REG_IF & IRQ_NETWORK))
            continue;

        REG_IF = IRQ_NETWORK;
        return status == readReg113();
    } while (--timeout);

    REG_IF = IRQ_NETWORK;
    return false;
}

void rtcom_requestAsync(u8 request) { writeReg113(request); }

void rtcom_requestAsync(u8 request, u8 param) {
    writeReg112(param);
    writeReg113(request);
}

bool rtcom_request(u8 request) {
    rtcom_requestAsync(request);
    return rtcom_waitAck();
}

bool rtcom_request(u8 request, u8 param) {
    rtcom_requestAsync(request, param);
    return rtcom_waitAck();
}

bool rtcom_requestKill() {
    rtcom_requestAsync(0xFE);
    return rtcom_waitReady();
}

void rtcom_signalDone() { writeReg113(RTCOM_STAT_DONE); }

u32 rtcom_getProcAddr(u32 id) {
    // todo
    return 0;
}

bool rtcom_uploadUCode(const void *uCode, u32 length) {
    if (!rtcom_request(RTCOM_REQ_UPLOAD_UCODE, length & 0xFF))
        return false;

    if (!rtcom_requestNext((length >> 8) & 0xFF))
        return false;

    if (!rtcom_requestNext((length >> 16) & 0xFF))
        return false;

    if (!rtcom_requestNext((length >> 24) & 0xFF))
        return false;

    const u8 *pCode = (const u8 *)uCode;
    for (u32 i = 0; i < length; i++)
        if (!rtcom_requestNext(*pCode++))
            return false;

    // make it executable
    return rtcom_request(RTCOM_REQ_FINISH_UCODE);
}

bool rtcom_executeUCode(u8 param) { return rtcom_request(RTCOM_REQ_EXECUTE_UCODE, param); }

// ----------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------

void Init_RTCom() {
    int savedIrq = enterCriticalSection();
    {
        u16 old_crtc = rtcom_beginComm();
        int trycount = 10;

        do {
            rtcom_requestAsync(1);
            if (rtcom_waitStatus(RTCOM_STAT_DONE)) {
                break;
            }
        } while (--trycount);

        if (trycount) {
            trycount = 10;
            do {
                if (rtcom_uploadUCode(arm7_rtcom_patch_uc11, arm7_rtcom_patch_uc11_size)) {
                    break;
                }
            } while (--trycount);
        }

        rtcom_requestAsync(RTCOM_STAT_DONE);
        rtcom_endComm(old_crtc);
    }

    leaveCriticalSection(savedIrq);
}

void Init_CPad_and_Stuff() {

    int savedIrq = enterCriticalSection();
    {
        u16 old_rcnt = rtcom_beginComm();

        rtcom_executeUCode(0);

        rtcom_requestKill();
        rtcom_requestAsync(RTCOM_STAT_DONE);
        rtcom_endComm(old_rcnt);
    }
    leaveCriticalSection(savedIrq);
}

inline void Update_CPad() {
    if (!rtcom_executeUCode(1))
        return;
    u8 cpad_x = rtcom_getData();

    if (!rtcom_requestNext(2))
        return;
    u8 cpad_y = rtcom_getData();
    u16 cpad_xy = cpad_x | (cpad_y << 8);

    *(vu16 *)0x02FFFE70 = cpad_xy;
    *(vu16 *)0x027ffde8 = cpad_xy;
}

inline void Update_NubZLZR() {
    u32 zlzr = 0;

#ifdef INCLUDE_NEW_3DS_STUFF
    if (!rtcom_requestNext(3))
        return;
    zlzr = rtcom_getData();
#endif

    *(vu32 *)0x02FFFE74 = zlzr;
    *(vu32 *)0x027ffdec = zlzr;
}

void Update_RTCom() {
    if (RTCOM_STATE == 0) {
        RTCOM_STATE = -1;
        Init_RTCom();
        RTCOM_STATE = 100;
    } else if (RTCOM_STATE == 5) {
        RTCOM_STATE = -1;
        Init_CPad_and_Stuff();
        RTCOM_STATE = 200;
    } else if (RTCOM_STATE == 105) {
        FRAME_COUNTER += 1;

        if (FRAME_COUNTER % 2 == 0) {
            int savedIrq = enterCriticalSection();
            {
                u16 old_rcnt = rtcom_beginComm();
                Update_CPad(); // once 2 frames

                if (FRAME_COUNTER % 4 == 0) {
                    Update_NubZLZR(); // once 4 frames
                }

                rtcom_requestKill();
                rtcom_requestAsync(RTCOM_STAT_DONE);
                rtcom_endComm(old_rcnt);
            }
            leaveCriticalSection(savedIrq);
        }
    } else if (RTCOM_STATE > 0) {
        RTCOM_STATE -= 1;
    }
}
