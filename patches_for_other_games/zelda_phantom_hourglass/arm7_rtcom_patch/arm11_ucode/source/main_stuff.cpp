#include <stddef.h>

#include "a11ucode.h"
#include "main_stuff.h"

#define RELOC_ADDR ((void *)0x100000)
#define RELOC_SIZE (0x28000)

u8 *g_cpad_pattern_address = nullptr;

u8 *cpad_init() {
    const static uint8_t dpad_emul_sensitivity_pattern[] = {0x01, 0x91, 0x02, 0x23, 0x00, 0x92,
                                                            0xc3, 0x5e, 0x42, 0x5f, 0x02, 0xa9,
                                                            0x02, 0x31, 0x02, 0xa8};
    const static uint8_t hid_update_func_pattern[] = {0x01, 0x0e, 0x08, 0x43, 0xb0, 0x43,
                                                      0x34, 0x40, 0x20, 0x43, 0x84, 0xb2};
    size_t ptr = (size_t)pat_memesearch(hid_update_func_pattern, nullptr, RELOC_ADDR, RELOC_SIZE,
                                        sizeof(hid_update_func_pattern), 2);
    if (!ptr) {
        return nullptr;
    }

    g_cpad_pattern_address = (u8 *)ptr;

    // // decrease dpad sensitivity so that the cpad would be detected before the emulated dpad
    // // (fixes small animation glitch when Link starts walking slowly)
    // size_t dpad_emul_sens_min_threshold =
    //     (size_t)pat_memesearch(dpad_emul_sensitivity_pattern, nullptr, RELOC_ADDR, RELOC_SIZE,
    //                            sizeof(dpad_emul_sensitivity_pattern), 2);
    // if (dpad_emul_sens_min_threshold != 0) {
    //     *(vu16 *)(dpad_emul_sens_min_threshold - 2) = 0x2232; // movs r2, #0x32 (default is 0x28?)
    // }

    // u8 *cpad_max_threshold = (u8 *)(ptr - 0x54);
    // u8 *cpad_min_threshold = (u8 *)(ptr - 0x52);

    // toggle_dpad_emulation(); // unmap cpad from dpad

    return *(u8 **)(ptr + 0x60) + 0xC;
}

void toggle_dpad_emulation() {
    if (g_cpad_pattern_address == nullptr) {
        cpad_init();
    }

    vu8 *dpad_emul_addr = (vu8 *)(g_cpad_pattern_address + 0xD);

    if (*dpad_emul_addr == 0) {
        *dpad_emul_addr = 0xf0;
    } else {
        *dpad_emul_addr = 0x0;
    }
}

__attribute__((optimize("Ofast"))) void *pat_memesearch(const void *patptr, const void *bitptr,
                                                        const void *searchptr, u32 searchlen,
                                                        u32 patsize, u32 alignment) {
    const u8 *pat = (const u8 *)patptr;
    const u8 *bit = (const u8 *)bitptr;
    const u8 *src = (const u8 *)searchptr;

    u32 i = 0;
    u32 j = 0;

    searchlen -= patsize;

    if (bit) {
        do {
            if ((src[i + j] & ~bit[j]) == (pat[j] & ~bit[j])) {
                if (++j != patsize) {
                    continue;
                }
                // check alignment
                if (((u32)src & (alignment - 1)) == 0) {
                    return (void *)(src + i);
                }
            }
            ++i;
            j = 0;
        } while (i != searchlen);
    } else {
        do {
            if (src[i + j] == pat[j]) {
                if (++j != patsize) {
                    continue;
                }
                // check alignment
                if (((u32)src & (alignment - 1)) == 0) {
                    return (void *)(src + i);
                }
            }
            ++i;
            j = 0;
        } while (i != searchlen);
    }

    return 0;
}

// ------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------
// TwlBg runtime patch

u8 *g_pxi_log_func_addr = nullptr;
u8 *g_rtc_func_addr = nullptr;
u8 *g_cpad_addr = nullptr;
bool g_memory_addresses_found = true;

// include the variable "twlbg_patch_code" with the asm code for the TwlBg patch
#include "../arm11_twlbg_patch/twl_bg_patch_bytes.h"

static inline void flush_cache(u8 *addr, u32 size) {
    // this is a system call "AddCodeSegment" (according to 3dbrew)
    // flushes the data cache and invalidates the instruction cache
    asm volatile("MOV r0, %[addr]\n\t"
                 "MOV r1, %[size]\n\t"
                 "SVC 0x7A"
                 :
                 : [addr] "r"(addr), [size] "r"(size)
                 : "r0", "r1", "r2", "r3");
}

bool find_memory_addresses() {
    const static uint8_t rtc_func_pattern[] = {0x00, 0x25, 0xc0, 0x1d, 0x45, 0x57, 0x00,
                                               0x2d, 0x08, 0xd0, 0x38, 0x49, 0x26, 0x69};
    const static uint8_t pxi_log_func_pattern[] = {0xf3, 0xb5, 0x04, 0x1e, 0xad, 0xb0, 0x3c, 0xda};

    // function responsible for legacy RTC in TwlBg (0x00100d10)
    g_rtc_func_addr = (u8 *)pat_memesearch(rtc_func_pattern, nullptr, RELOC_ADDR, RELOC_SIZE,
                                           sizeof(rtc_func_pattern), 2);
    if (!g_rtc_func_addr) {
        return false;
    }

    // function for logging messages via PXI (not used at the time of this code being executed)
    // (0x001138c0)
    g_pxi_log_func_addr = (u8 *)pat_memesearch(pxi_log_func_pattern, nullptr, RELOC_ADDR,
                                               RELOC_SIZE, sizeof(pxi_log_func_pattern), 2);
    if (!g_pxi_log_func_addr) {
        return false;
    }

    g_cpad_addr = cpad_init(); // 0x0012ac10
    if (!g_cpad_addr) {
        return false;
    }

    return true;
}

void patch_twlbg(vu8 stage) {
    if (!g_memory_addresses_found) {
        return;
    }

    if (stage == 1) {
        g_memory_addresses_found = find_memory_addresses();
        if (!g_memory_addresses_found) {
            return;
        }

        // upload the patch
        u8 *main_patch_start = (u8 *)g_pxi_log_func_addr;
        // 4-byte boundary alignment
        if ((u32)main_patch_start % 4 != 0) {
            *(vu16 *)main_patch_start = 0x0;
            main_patch_start += 2;
        }
        u32 patch_code_size = sizeof(twlbg_patch_code);
        for (u32 i = 0; i < patch_code_size; i++) {
            *(vu8 *)(main_patch_start + i) = twlbg_patch_code[i];
        }
        *(u32 *)(main_patch_start + patch_code_size - 4) = (u32)g_cpad_addr;
        flush_cache(main_patch_start - 2, patch_code_size + 4);

        // for now, skip the area we're going to insert the branch into
        *(vu16 *)g_rtc_func_addr = (((g_rtc_func_addr + 0xDC) - g_rtc_func_addr - 4) >> 1) | 0xE000;
        flush_cache((u8 *)g_rtc_func_addr, 2);
    } else if (stage == 2) {
        // insert the branch into the uploaded above code
        u32 branch_base_address = (u32)g_rtc_func_addr + 2;
        u32 jump_offset = (u32)g_pxi_log_func_addr - (branch_base_address + 4);
        u16 branch_instr_1 = 0xF000 | ((jump_offset >> 12) & 0x7FF);
        u16 branch_instr_2 = 0xF800 | ((jump_offset >> 1) & 0x7FF);

        *(vu16 *)branch_base_address = branch_instr_1;
        *(vu16 *)(branch_base_address + 2) = branch_instr_2;
        flush_cache((u8 *)branch_base_address, 4);
    } else if (stage == 3) {
        // remove previously inserted skip-branch
        *(vu16 *)g_rtc_func_addr = 0x2500; // movs r5,#0x0
        flush_cache((u8 *)g_rtc_func_addr, 2);
    }
}
