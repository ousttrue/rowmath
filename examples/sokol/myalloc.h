#pragma once
#include <stddef.h>

void *my_aligned_alloc(size_t alignment, size_t size);
void my_free(void *block);
