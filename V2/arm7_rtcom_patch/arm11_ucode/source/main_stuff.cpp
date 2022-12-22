#include <stddef.h>

#include "a11ucode.h"
#include "main_stuff.h"

#define RELOC_ADDR ((void *)0x100000)
#define RELOC_SIZE (0x28000)

#ifdef INCLUDE_NEW_3DS_STUFF
static I2C_Read_Func i2c_read = nullptr;
static I2C_Write_Func i2c_write = nullptr;

static int is_initialized = 0;

I2C_Read_Func nub_init() {
    if (is_initialized) {
        return nullptr;
    }

    const uint8_t i2c_senddata_pattern[] = {0x70, 0xb5, 0x06, 0x46, 0x0b, 0x4c, 0x88,
                                            0x00, 0x0d, 0x18, 0x30, 0x46, 0x61, 0x5d};
    size_t ptr = (size_t)pat_memesearch(i2c_senddata_pattern, nullptr, RELOC_ADDR, RELOC_SIZE,
                                        sizeof(i2c_senddata_pattern), 2);
    if (!ptr) {
        return nullptr;
    }
    // add the nub device to the table as the last entry
    vu8 *i2c_device_table = *(vu8 **)(ptr + 0x34);
    i2c_device_table[0x46] = 0x2;
    i2c_device_table[0x47] = 0x54;

    const uint8_t i2c_read_pattern[] = {0xff, 0xb5, 0x81, 0xb0, 0x14, 0x46, 0x0d, 0x46,
                                        0x1e, 0x46, 0x0a, 0x9f, 0x01, 0x98, 0x11, 0x46};
    ptr = (size_t)pat_memesearch(i2c_read_pattern, nullptr, RELOC_ADDR, RELOC_SIZE,
                                 sizeof(i2c_read_pattern), 2);
    if (!ptr) {
        return nullptr;
    }
    i2c_read = (I2C_Read_Func)(ptr | 1);

    const uint8_t i2c_write_pattern[] = {0xff, 0xb5, 0x81, 0xb0, 0x14, 0x46, 0x05,
                                         0x46, 0x1e, 0x46, 0x0a, 0x9f, 0x02, 0x99};
    ptr = (size_t)pat_memesearch(i2c_write_pattern, nullptr, RELOC_ADDR, RELOC_SIZE,
                                 sizeof(i2c_write_pattern), 2);
    if (!ptr) {
        return nullptr;
    }
    i2c_write = (I2C_Write_Func)(ptr | 1);

    // enable zl-zr buttons
    u8 mode = 0xFC;
    i2c_write(0, 0xE, 0, &mode, 1);

    is_initialized = 1;
    return i2c_read;
}

int nub_read(u8 *dst, int count) {
    if (!is_initialized) {
        nub_init();
        return 0;
    }
    return i2c_read(0, dst, 0xE, 0, count);
}
#endif

u8 *cpad_init() {
    const uint8_t hid_update_func_pattern[] = {0x01, 0x0e, 0x08, 0x43, 0xb0, 0x43, 0x34, 0x40,
                                               0x20, 0x43, 0x84, 0xb2, 0xf0, 0x20, 0x06, 0x43};
    size_t ptr = (size_t)pat_memesearch(hid_update_func_pattern, nullptr, RELOC_ADDR, RELOC_SIZE,
                                        sizeof(hid_update_func_pattern), 2);
    if (!ptr) {
        return nullptr;
    }

    // u8 *cpad_max_threshold = (u8 *)(ptr - 0x54);
    // u8 *cpad_min_threshold = (u8 *)(ptr - 0x52);

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

static u32 rtc_area_start_addr = 0;
static u32 pxi_log_func_addr = 0;

// the asm code for this is here: ../arm11_twlbg_patch/arm11_twlbg_patch.s
#ifdef INCLUDE_NEW_3DS_STUFF
u8 twlbg_patch_code[] = {
    0x00, 0x25, 0x07, 0x30, 0x45, 0x57, 0x7f, 0xb4, 0x07, 0x24, 0x00, 0x23, 0x0e, 0x22, 0x6e,
    0x46, 0x69, 0x46, 0x0c, 0x39, 0xa1, 0x43, 0x8d, 0x46, 0x10, 0xb4, 0x0e, 0x48, 0x75, 0x46,
    0x80, 0x47, 0xae, 0x46, 0x0a, 0x4c, 0x0a, 0x4a, 0x10, 0x78, 0x91, 0x78, 0x09, 0x02, 0x08,
    0x43, 0x00, 0x02, 0x60, 0x62, 0x6a, 0x46, 0xb5, 0x46, 0x91, 0x88, 0x90, 0x68, 0x00, 0x0a,
    0x00, 0x04, 0x08, 0x43, 0x20, 0x62, 0x10, 0x20, 0x20, 0x80, 0x7f, 0xbc, 0x70, 0x47, 0xc0,
    0x46, 0x00, 0x71, 0xc4, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
#else
u8 twlbg_patch_code[] = {0x00, 0x25, 0x07, 0x30, 0x45, 0x57, 0x7f, 0xb4, 0x06, 0x4c, 0x07, 0x4a,
                         0x10, 0x78, 0x91, 0x78, 0x09, 0x02, 0x08, 0x43, 0x00, 0x02, 0x60, 0x62,
                         0x00, 0x20, 0x20, 0x62, 0x10, 0x20, 0x20, 0x80, 0x7f, 0xbc, 0x70, 0x47,
                         0x00, 0x71, 0xc4, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
#endif

void patch_twlbg_1_write_patch_body(u8 *cpad_xy_addr, I2C_Read_Func i2c_read) {
    // function responsible for legacy RTC in TwlBg
    const uint8_t rtc_func_pattern[] = {0x38, 0x49, 0x26, 0x69, 0x63, 0x69, 0x0a, 0x68,
                                        0x49, 0x68, 0x72, 0x40, 0x59, 0x40, 0x0a, 0x43};
    size_t rtc_func_addr = (size_t)pat_memesearch(rtc_func_pattern, nullptr, RELOC_ADDR, RELOC_SIZE,
                                                  sizeof(rtc_func_pattern), 2);
    if (!rtc_func_addr) {
        return;
    }

    // function for logging messages via PXI (not used at the time of this code being executed)
    const uint8_t pxi_log_func_pattern[] = {0xf3, 0xb5, 0x04, 0x1e, 0xad, 0xb0, 0x3c, 0xda};
    pxi_log_func_addr = (u32)pat_memesearch(pxi_log_func_pattern, nullptr, RELOC_ADDR, RELOC_SIZE,
                                            sizeof(pxi_log_func_pattern), 2);
    if (!pxi_log_func_addr) {
        return;
    }

    u8 *main_patch_start = (u8 *)pxi_log_func_addr;

    // 4-byte boundary alignment
    if ((u32)main_patch_start % 4 != 0) {
        *(vu16 *)main_patch_start = 0x0;
        main_patch_start += 2;
    }

    u32 patch_code_size = sizeof(twlbg_patch_code);
    for (int i = 0; i < patch_code_size; i++) {
        *(vu8 *)(main_patch_start + i) = twlbg_patch_code[i];
    }
    *(u32 *)(main_patch_start + patch_code_size - 8) = (u32)cpad_xy_addr;
    *(u32 *)(main_patch_start + patch_code_size - 4) = (u32)i2c_read | 1;

    rtc_area_start_addr = (rtc_func_addr - 10);
    u32 rtc_area_end_addr = rtc_area_start_addr + 0xDC;

    // for now, skip the area we're going to insert the branch into
    *(vu16 *)rtc_area_start_addr = ((rtc_area_end_addr - rtc_area_start_addr - 4) >> 1) | 0xE000;
}

void patch_twlbg_2_insert_branch_instruction() {
    if (rtc_area_start_addr == 0 || pxi_log_func_addr == 0) {
        return;
    }

    // calculate the branch offset
    u32 branch_base_address = (u32)rtc_area_start_addr + 0x2;
    u32 jump_offset = pxi_log_func_addr - (branch_base_address + 4);
    u16 branch_instr_1 = 0xF000 | ((jump_offset >> 12) & 0x7FF);
    u16 branch_instr_2 = 0xF800 | ((jump_offset >> 1) & 0x7FF);

    // insert the branch instruction to jump into the patched code
    *(vu16 *)branch_base_address = branch_instr_1;
    *(vu16 *)(branch_base_address + 2) = branch_instr_2;
}

void patch_twlbg_3_remove_skip_branch() {
    if (rtc_area_start_addr == 0) {
        return;
    }
    // remove previously inserted skip-branch from "patch_twlbg_1_write_patch_body()"
    *(vu16 *)rtc_area_start_addr = 0x00;
}
