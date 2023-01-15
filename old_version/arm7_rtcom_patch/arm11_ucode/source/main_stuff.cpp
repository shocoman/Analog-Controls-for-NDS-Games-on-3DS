#include <stddef.h>

#include "a11ucode.h"
#include "main_stuff.h"

#define RELOC_ADDR ((void *)0x100000)
#define RELOC_SIZE (0x28000)

#ifdef INCLUDE_NEW_3DS_STUFF
typedef int (*I2C_Read)(void *x, u8 *dst, int dev, int src_addr, int count);
typedef int (*I2C_Write)(void *x, int dev, int dst_addr, const u8 *dst, int count);

static I2C_Read i2c_read = NULL;
static I2C_Write i2c_write = NULL;

static int is_initialized = 0;

int nub_init() {
    if (is_initialized) {
        return 0;
    }

    const uint8_t i2c_senddata_pattern[] = {0x70, 0xb5, 0x06, 0x46, 0x0b, 0x4c, 0x88,
                                            0x00, 0x0d, 0x18, 0x30, 0x46, 0x61, 0x5d};
    size_t ptr = (size_t)pat_memesearch(i2c_senddata_pattern, nullptr, RELOC_ADDR, RELOC_SIZE,
                                        sizeof(i2c_senddata_pattern));
    if (!ptr) {
        return 1;
    }
    // add the nub device to the table as the last entry
    vu8 *i2c_device_table = *(vu8 **)(ptr + 0x34);
    i2c_device_table[0x46] = 0x2;
    i2c_device_table[0x47] = 0x54;

    const uint8_t i2c_read_pattern[] = {0xff, 0xb5, 0x81, 0xb0, 0x14, 0x46, 0x0d, 0x46,
                                        0x1e, 0x46, 0x0a, 0x9f, 0x01, 0x98, 0x11, 0x46};
    ptr = (size_t)pat_memesearch(i2c_read_pattern, nullptr, RELOC_ADDR, RELOC_SIZE,
                                 sizeof(i2c_read_pattern));
    if (!ptr) {
        return 2;
    }
    i2c_read = (I2C_Read)(ptr | 1);

    const uint8_t i2c_write_pattern[] = {0xff, 0xb5, 0x81, 0xb0, 0x14, 0x46, 0x05,
                                         0x46, 0x1e, 0x46, 0x0a, 0x9f, 0x02, 0x99};
    ptr = (size_t)pat_memesearch(i2c_write_pattern, nullptr, RELOC_ADDR, RELOC_SIZE,
                                 sizeof(i2c_write_pattern));
    if (!ptr) {
        return 3;
    }
    i2c_write = (I2C_Write)(ptr | 1);

    // enable zl-zr buttons
    u8 mode = 0xFC;
    i2c_write(0, 0xE, 0, &mode, 1);

    is_initialized = 1;
    return 0;
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
                                        sizeof(hid_update_func_pattern));
    if (!ptr) {
        return nullptr;
    }

    // u8 *cpad_max_threshold = (u8 *)(ptr - 0x54);
    // u8 *cpad_min_threshold = (u8 *)(ptr - 0x52);

    return *(u8 **)(ptr + 0x60) + 0xC;
}

__attribute__((optimize("Ofast"))) void *pat_memesearch(const void *patptr, const void *bitptr,
                                                        const void *searchptr, u32 searchlen,
                                                        u32 patsize) {
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
                return (void *)(src + i);
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
                return (void *)(src + i);
            }
            ++i;
            j = 0;
        } while (i != searchlen);
    }

    return 0;
}