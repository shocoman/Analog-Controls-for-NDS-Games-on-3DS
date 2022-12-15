#include "a11ucode.h"
#include "main_stuff.h"

// static int readCPad(int offset) {
//     // return ((u8*)0x127384)[offset];
//     return ((u8 *)0x12ac10)[offset];
// }

static u8 *cpad_xy_addr = nullptr;

#ifdef INCLUDE_NEW_3DS_STUFF
static u8 nub_buffer[8] = {0};
static int is_nub_initialized = 0;
#endif

extern "C" int handleCommand1(u8 param, u32 stage) {
    switch (param) {
    case 0: {
        cpad_xy_addr = cpad_init();

#ifdef INCLUDE_NEW_3DS_STUFF
        is_nub_initialized = !nub_init();
#endif

        return 0;
    }
    case 1: {
        if (cpad_xy_addr != nullptr) {
            return cpad_xy_addr[0]; // cpad x
        }
        break;
    }
    case 2: {
        if (cpad_xy_addr != nullptr) {
            return cpad_xy_addr[2]; // cpad y
        }
        break;
    }

#ifdef INCLUDE_NEW_3DS_STUFF
    case 3: {
        nub_read(nub_buffer, 8);
        return nub_buffer[1]; // zl-zr (2nd,3rd bits)
    }
    case 4:
        return nub_buffer[5]; // nub x?
    case 5:
        return nub_buffer[6]; // nub y?
#endif
    }

    return 0;
}
