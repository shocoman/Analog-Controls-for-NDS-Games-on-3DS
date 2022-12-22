#pragma once
#include "a11ucode.h"

typedef int (*I2C_Read_Func)(void *x, u8 *dst, int dev, int src_addr, int count);
typedef int (*I2C_Write_Func)(void *x, int dev, int dst_addr, const u8 *dst, int count);

I2C_Read_Func nub_init();
int nub_read(u8 *dst, int count);
u8 *cpad_init();

void* pat_memesearch(const void* patptr, const void* bitptr, const void* searchptr, u32 searchlen, u32 patsize, u32 alignment);

void patch_twlbg_1_write_patch_body(u8 *cpad_xy_addr, I2C_Read_Func i2c_read);
void patch_twlbg_2_insert_branch_instruction();
void patch_twlbg_3_remove_skip_branch();
