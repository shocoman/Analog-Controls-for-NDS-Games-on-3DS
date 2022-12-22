#include <nds.h>
#include <nds/arm7/serial.h>

#include "arm7_rtcom_patch_uc11.h"
#include "rtcom.h"
#include "sys/_stdint.h"

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

#define RTC_READ_DATE_AND_TIME 0x65
#define RTC_READ_HOUR_MINUTE_SECOND 0x67

// sm64ds's arm7 usually stores RTC date&time here, should be a safe place as it's not used
#define RTCOM_DATA_OUTPUT 0x027FFDE8

// an attempt to put global variables next to the code for easier memory control;
// be aware of the compiler error "unaligned opcodes detected in executable segment"
__attribute__((section(".text"))) static int RTCOM_STATE_TIMER = 0;

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
    rtcom_requestAsync(RTCOM_REQ_SYNC_KIL);
    return rtcom_waitReady();
}

void rtcom_signalDone() { writeReg113(RTCOM_STAT_DONE); }

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

    // finish uploading
    rtcom_requestAsync(RTCOM_REQ_KEEPALIVE);
    rtcom_waitDone();

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
            rtcom_requestAsync(1); // request communication from rtcom
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

        rtcom_endComm(old_crtc);
    }
    leaveCriticalSection(savedIrq);
}

void Execute_Code_via_RTCom(int param) {
    int savedIrq = enterCriticalSection();
    {
        u16 old_rcnt = rtcom_beginComm();
        rtcom_executeUCode(param);
        rtcom_requestKill();
        rtcom_endComm(old_rcnt);
    }
    leaveCriticalSection(savedIrq);
}

static void Update_CPad_and_Nub() {
    // u8 readCmd = RTC_READ_HOUR_MINUTE_SECOND;
    u8 readCmd = RTC_READ_DATE_AND_TIME;
    u8 readVal[7] = {0};
    rtcTransferReversed(&readCmd, 1, readVal, sizeof(readVal));

    u8 cpad_x = readVal[1];
    u8 cpad_y = readVal[0];

    u8 zlzr = (readVal[5] & 0b110); // zl-zr (2nd,3rd bits)
    u8 nub_x = readVal[4];
    u8 nub_y = readVal[3];
    // u8 nub_x = (uint8_t)readVal[3] - (uint8_t)readVal[4];
    // u8 nub_y = (uint8_t)readVal[4] + (uint8_t)readVal[3];

    *(vu16 *)RTCOM_DATA_OUTPUT = cpad_x | (cpad_y << 8);
    *(vu32 *)(RTCOM_DATA_OUTPUT + 4) = zlzr | (nub_x << 8) | (nub_y << 16);
}

void Update_RTCom() {
    // Steps: Wait; Upload the code to Arm11;
    //        Wait; Tell Arm11 to patch TwlBg and insert a skip branch
    //        Wait; Tell Arm11 to insert a branch into the patched TwlBg area
    //        Wait; Tell Arm11 to remove the skip branch (and allow the patched in code to run)
    //        Wait; Read the CPad and Nub data from the RTC regs
    enum RtcomStateTime {
        Start = 0,
        UploadCode = 5,
        MainTwlPatch = UploadCode + 200,
        InsertBranchIntoPatch = MainTwlPatch + 200,
        RemoveSkipBranch = InsertBranchIntoPatch + 200,
        ReadyToRead = RemoveSkipBranch + 200,
    };

    bool is_lid_closed_now = (REG_KEYXY >> 7) & 1; // 7th bit - lid is opened/closed
    if (is_lid_closed_now) {
        return;
    }

    // execute certain rtcom state depending on the timer value
    switch (RTCOM_STATE_TIMER) {
    case UploadCode:
        Init_RTCom();
        RTCOM_STATE_TIMER += 1;
        break;
    case MainTwlPatch:
        Execute_Code_via_RTCom(0);
        RTCOM_STATE_TIMER += 1;
        break;
    case InsertBranchIntoPatch: {
        Execute_Code_via_RTCom(1);
        RTCOM_STATE_TIMER += 1;
        break;
    }
    case RemoveSkipBranch: {
        Execute_Code_via_RTCom(2);
        RTCOM_STATE_TIMER += 1;
        break;
    }
    case ReadyToRead: {
        // pretend that RTCom has been successfully initialized by this moment and everything's fine
        Update_CPad_and_Nub();
        break;
    }
    default:
        RTCOM_STATE_TIMER += 1;
        break;
    }
}
