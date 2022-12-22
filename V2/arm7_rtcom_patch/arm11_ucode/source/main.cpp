#include "a11ucode.h"
#include "main_stuff.h"

// static int readCPad(int offset) {
//     // return ((u8*)0x127384)[offset];
//     return ((u8 *)0x12ac10)[offset];
// }

extern "C" int handleCommand1(u8 param, u32 stage) {
    switch (param) {
    case 0: {
        u8 *cpad_xy_addr = cpad_init();

        I2C_Read_Func i2c_read_func = nullptr;

#ifdef INCLUDE_NEW_3DS_STUFF
        i2c_read_func = nub_init();
#endif

        patch_twlbg_1_write_patch_body(cpad_xy_addr, i2c_read_func);

        return 0;
    }
    case 1: {
        patch_twlbg_2_insert_branch_instruction();
        return 0;
    }
    case 2: {
        patch_twlbg_3_remove_skip_branch();
        return 0;
    }
    }

    return 0;
}
