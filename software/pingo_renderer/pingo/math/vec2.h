#pragma once

#include "types.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct Vec2i {
    I_TYPE x;
    I_TYPE y;
} Vec2i;

typedef struct {
    F_TYPE x;
    F_TYPE y;
} Vec2f;

extern Vec2i vector2ISum(Vec2i l, Vec2i r);

extern Vec2f vecItoF(Vec2i v);

extern Vec2i vecFtoI(Vec2f v);

#ifdef __cplusplus
}
#endif
