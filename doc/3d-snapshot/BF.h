

#ifndef __BF_H
#define __BF_H

#if defined(__cplusplus)
extern "C" {
#endif

#include "EverParse.h"




uint64_t BfValidateDummy(uint32_t InputLength, uint8_t *Input, uint64_t StartPosition);

void BfReadDummy(uint32_t InputLength, uint8_t *Input, uint32_t StartPosition);

#if defined(__cplusplus)
}
#endif

#define __BF_H_DEFINED
#endif
