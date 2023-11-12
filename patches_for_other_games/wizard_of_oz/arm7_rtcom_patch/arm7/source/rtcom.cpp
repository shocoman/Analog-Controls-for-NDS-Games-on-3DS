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
#define RTC_READ_ALARM_TIME_1 0x69
#define RTC_READ_ALARM_TIME_2 0x6B

#define RTC_READ_COUNTER_EXT 0x71
#define RTC_READ_FOUT1_EXT 0x73
#define RTC_READ_FOUT2_EXT 0x75
#define RTC_READ_ALARM_DATE_1_EXT 0x79
#define RTC_READ_ALARM_DATE_2_EXT 0x7B

// sm64ds's arm7 usually stores RTC date&time near this place
#define RTCOM_DATA_OUTPUT 0x027FFDF0

// These functions are from Arm7's part of the game (maybe any NDS game).
// register a callback for an IPC channel (called when Arm9 wants Arm7 to update RTC's time&date)
typedef void (*Set_IPC_Channel_Handler)(int n_channel, void *handler);
// normally sends msg to Arm9 to tell that the Time data is ready at 0x027FFDE8
typedef void (*IPC_Send_Msg)(int n_service, int arg, int no_handle);

// an attempt to put global variables next to the code for easier memory control;
// be aware of the compiler error "unaligned opcodes detected in executable segment"
__attribute__((section(".text"))) static int RTCOM_STATE_TIMER = 0;

static void waitByLoop(volatile int count) {
    // 1 loop = 4 cycles = ~0.3us ???
    while (--count > 0) {
    }
}

static void rtcTransferReversed(u8 *cmd, u32 cmdLen, u8 *result, u32 resultLen, bool fastMode = false) {
    int initDelay = 2;
    int bitTransferDelay = fastMode ? 1 : 9;

    // Raise CS
    RTC_CR8 = CS_0 | SCK_1 | SIO_1;
    waitByLoop(initDelay);
    RTC_CR8 = CS_1 | SCK_1 | SIO_1;
    waitByLoop(initDelay);

    // Write command byte (high bit first)
    u8 data = *cmd++;

    for (u32 bit = 0; bit < 8; bit++) {
        RTC_CR8 = CS_1 | SCK_0 | SIO_out | (data >> 7);
        waitByLoop(bitTransferDelay);

        RTC_CR8 = CS_1 | SCK_1 | SIO_out | (data >> 7);
        waitByLoop(bitTransferDelay);

        data <<= 1;
    }
    // Write parameter bytes (high bit first)
    for (; cmdLen > 1; cmdLen--) {
        data = *cmd++;
        for (u32 bit = 0; bit < 8; bit++) {
            RTC_CR8 = CS_1 | SCK_0 | SIO_out | (data >> 7);
            waitByLoop(bitTransferDelay);

            RTC_CR8 = CS_1 | SCK_1 | SIO_out | (data >> 7);
            waitByLoop(bitTransferDelay);

            data <<= 1;
        }
    }

    // Read result bytes (high bit first)
    for (; resultLen > 0; resultLen--) {
        data = 0;
        for (u32 bit = 0; bit < 8; bit++) {
            RTC_CR8 = CS_1 | SCK_0;
            waitByLoop(bitTransferDelay);

            RTC_CR8 = CS_1 | SCK_1;
            waitByLoop(bitTransferDelay);

            data <<= 1;
            if (RTC_CR8 & SIO_in)
                data |= 1;
        }
        *result++ = data;
    }

    // Finish up by dropping CS low
    waitByLoop(initDelay);
    RTC_CR8 = CS_0 | SCK_1;
    waitByLoop(initDelay);
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
    // int timeout = 50000;
    int timeout = 2062500;
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
    if (!rtcom_waitDone())
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
    while (true) {
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

        if (trycount > 0)
            break; // success

        // there is no point returning without success
    }
    leaveCriticalSection(savedIrq);
}

void Execute_Code_Async_via_RTCom(int param) {
    int savedIrq = enterCriticalSection();
    {
        // It may take relatively a long time to execute for Arm11
        // Don't wait for the answer, otherwise sound glitches might come up
        //  (if the Surround or Headphones audio modes are turned on).
        // Arm11 should release/kill the connection automatically
        u16 old_rcnt = rtcom_beginComm();
        rtcom_requestAsync(RTCOM_REQ_EXECUTE_UCODE, param);
        rtcom_endComm(old_rcnt);
    }
    leaveCriticalSection(savedIrq);
}

static void Update_CPad_etc() {
    // Read CPadX, CPadY
    u8 readVal[2] = {0};
    u8 readCmd = RTC_READ_COUNTER_EXT;
    rtcTransferReversed(&readCmd, 1, readVal, 2, true);

    u8 cpad_x = readVal[1];
    u8 cpad_y = readVal[0];
    *(vu16 *)RTCOM_DATA_OUTPUT = cpad_x | (cpad_y << 8);
}

__attribute__((target("arm"))) void RtcChannelHandler(int n_service, int arg, int no_handle) {
    auto reverseBits = [](u8 b) {
        b = (b & 0xF0) >> 4 | (b & 0x0F) << 4;
        b = (b & 0xCC) >> 2 | (b & 0x33) << 2;
        b = (b & 0xAA) >> 1 | (b & 0x55) << 1;
        return b;
    };

    // Read Date&Time
    u8 readCmd = RTC_READ_DATE_AND_TIME;
    u8 *date_time_addr = (u8 *)(RTCOM_DATA_OUTPUT - 8);
    rtcTransferReversed(&readCmd, 1, date_time_addr, 7);
    for (int i = 0; i < 7; i++) {
        date_time_addr[i] = reverseBits(date_time_addr[i]);
    }

    // answer arm9 that the time is "ready"
#ifdef ARM7_IPC_SEND_MSG
    ((IPC_Send_Msg)ARM7_IPC_SEND_MSG)(5, 0, 0);
#endif
}

__attribute__((target("arm"))) void Update_RTCom() {
    // Steps: Wait; Upload the code to Arm11;
    //        Wait; Tell Arm11 to patch TwlBg and insert a skip branch
    //        Wait; Tell Arm11 to insert a branch into the patched TwlBg area
    //        Wait; Tell Arm11 to remove the skip branch (and allow the patched-in code to run)
    //        Wait; Read the CPad and Nub data from the RTC regs
    enum RtcomStateTime {
        Start = 0,
        UploadCode = 10,
        MainTwlPatch = UploadCode + 200,
        InsertBranchIntoPatch = MainTwlPatch + 50,
        RemoveSkipBranch = InsertBranchIntoPatch + 50,
        ReadyToRead = RemoveSkipBranch + 10,
    };

    // execute certain rtcom state depending on the timer value
    switch (RTCOM_STATE_TIMER) {
    case Start:
#ifdef ARM7_IPC_CHANNEL_HANDLER
        ((Set_IPC_Channel_Handler)ARM7_IPC_CHANNEL_HANDLER)(5, (void *)RtcChannelHandler);
#endif
        RTCOM_STATE_TIMER += 1;
        break;
    case UploadCode:
        Init_RTCom();
        RTCOM_STATE_TIMER += 1;
        break;
    case MainTwlPatch: {
        Execute_Code_Async_via_RTCom(1);
        RTCOM_STATE_TIMER += 1;
        break;
    }
    case InsertBranchIntoPatch: {
        Execute_Code_Async_via_RTCom(2);
        RTCOM_STATE_TIMER += 1;
        break;
    }
    case RemoveSkipBranch: {
        Execute_Code_Async_via_RTCom(3);
        RTCOM_STATE_TIMER += 1;
        break;
    }
    case ReadyToRead: {
        // pretend that RTCom has been successfully initialized by this moment and everything's fine
        Update_CPad_etc();
        break;
    }
    default:
        RTCOM_STATE_TIMER += 1;
        break;
    }
}
