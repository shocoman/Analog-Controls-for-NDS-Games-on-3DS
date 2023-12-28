#include <stddef.h>

#include "a11ucode.h"
#include "main_stuff.h"

#define RELOC_ADDR ((void *)0x100000)
#define RELOC_SIZE (0x28000)

typedef int (*I2C_Read_Func)(void *x, u8 *dst, int dev, int src_addr, int count);
typedef int (*I2C_Write_Func)(void *x, int dev, int dst_addr, const u8 *dst, int count);

static I2C_Read_Func g_i2c_read_func = nullptr;
static I2C_Write_Func g_i2c_write_func = nullptr;

void i2c_init() {
    static const uint8_t i2c_read_pattern[] = {0xff, 0xb5, 0x81, 0xb0, 0x14, 0x46, 0x0d, 0x46,
                                               0x1e, 0x46, 0x0a, 0x9f, 0x01, 0x98, 0x11, 0x46};
    size_t ptr = (size_t)pat_memesearch(i2c_read_pattern, nullptr, RELOC_ADDR, RELOC_SIZE,
                                        sizeof(i2c_read_pattern), 2);
    if (!ptr) {
        return;
    }
    g_i2c_read_func = (I2C_Read_Func)(ptr | 1);

    static const uint8_t i2c_write_pattern[] = {0xff, 0xb5, 0x81, 0xb0, 0x14, 0x46, 0x05,
                                                0x46, 0x1e, 0x46, 0x0a, 0x9f, 0x02, 0x99};
    ptr = (size_t)pat_memesearch(i2c_write_pattern, nullptr, RELOC_ADDR, RELOC_SIZE,
                                 sizeof(i2c_write_pattern), 2);
    if (!ptr) {
        return;
    }
    g_i2c_write_func = (I2C_Write_Func)(ptr | 1);
}

void nub_init() {
    if (g_i2c_read_func == nullptr) {
        return;
    }

    static const uint8_t i2c_senddata_pattern[] = {0x70, 0xb5, 0x06, 0x46, 0x0b, 0x4c, 0x88,
                                                   0x00, 0x0d, 0x18, 0x30, 0x46, 0x61, 0x5d};
    size_t ptr = (size_t)pat_memesearch(i2c_senddata_pattern, nullptr, RELOC_ADDR, RELOC_SIZE,
                                        sizeof(i2c_senddata_pattern), 2);
    if (!ptr) {
        return;
    }

    // add the nub device to the table as the last entry
    vu8 *i2c_device_table = *(vu8 **)(ptr + 0x34);
    i2c_device_table[0x46] = 0x2;
    i2c_device_table[0x47] = 0x54;

    // enable zl-zr buttons
    u8 mode = 0xFC;
    g_i2c_write_func(0, 0xE, 0, &mode, 1);
}

int nub_read(u8 *dst, int count) { return g_i2c_read_func(0, dst, 0xE, 0, count); }

u8 *cpad_init() {
    const static uint8_t hid_update_func_pattern[] = {0x01, 0x0e, 0x08, 0x43, 0xb0, 0x43,
                                                      0x34, 0x40, 0x20, 0x43, 0x84, 0xb2};
    size_t ptr = (size_t)pat_memesearch(hid_update_func_pattern, nullptr, RELOC_ADDR, RELOC_SIZE,
                                        sizeof(hid_update_func_pattern), 2);
    if (!ptr) {
        return nullptr;
    }

    // u8 *cpad_max_threshold = (u8 *)(ptr - 0x54);
    // u8 *cpad_min_threshold = (u8 *)(ptr - 0x52);

    *(vu16 *)(ptr + 0xD) = 0; // unmap cpad from dpad

    return *(u8 **)(ptr + 0x60) + 0xC;
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

    // function for logging messages via PXI (not used at the time of this code being executed) (0x001138c0)
    g_pxi_log_func_addr = (u8 *)pat_memesearch(pxi_log_func_pattern, nullptr, RELOC_ADDR,
                                               RELOC_SIZE, sizeof(pxi_log_func_pattern), 2);
    if (!g_pxi_log_func_addr) {
        return false;
    }

    g_cpad_addr = cpad_init(); // 0x0012ac10
    if (!g_cpad_addr) {
        return false;
    }


    g_i2c_read_func = 0;
#ifdef INCLUDE_CSTICK_SUPPORT
    i2c_init();
    nub_init();
#endif

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
        *(u32 *)(main_patch_start + patch_code_size - 8) = (u32)g_cpad_addr;
        *(u32 *)(main_patch_start + patch_code_size - 4) = (u32)g_i2c_read_func | 1;
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
