#pragma once
#include "a11ucode.h"

int nub_init();
int nub_read(u8 *dst, int count);
u8 *cpad_init();
void* pat_memesearch(const void* patptr, const void* bitptr, const void* searchptr, u32 searchlen, u32 patsize);
