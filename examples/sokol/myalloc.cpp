extern "C" {
#include "myalloc.h"
}

#include <cstdlib>

void *my_aligned_alloc(size_t alignment, size_t size) {
  return std::aligned_alloc(alignment, size);
  // return _aligned_malloc(alignment, size);
}

void my_free(void *block) { 
  std::free(block);
  // _aligned_free(block); 
}
