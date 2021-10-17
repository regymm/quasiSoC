#pragma once

#include "types.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct Vec4i {
    I_TYPE x;
    I_TYPE y;
    I_TYPE z;
    I_TYPE w;
} Vec4i;

typedef struct Vec4f {
    F_TYPE x;
    F_TYPE y;
    F_TYPE z;
    F_TYPE w;
} Vec4f;

#ifdef __cplusplus
}
#endif
