#include "a11ucode.h"
#include "main_stuff.h"

extern "C" __attribute__((target("arm"))) int handleCommand1(u8 param, u32 stage) {
    if (param >= 1 && param <= 3) {
        patch_twlbg(param);
    }
    return 0;
}
