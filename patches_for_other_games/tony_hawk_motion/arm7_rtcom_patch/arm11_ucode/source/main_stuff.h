#pragma once
#include "a11ucode.h"

void *pat_memesearch(const void *patptr, const void *bitptr, const void *searchptr, u32 searchlen,
                     u32 patsize, u32 alignment);

void patch_twlbg(u8 stage);
int process_command(int cmd);


