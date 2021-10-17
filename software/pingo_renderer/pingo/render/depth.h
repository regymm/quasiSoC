#pragma once

#include <stdint.h>
#include <stdbool.h>

#define ZBUFFER16 // [ZBUFFER32 | ZBUFFER16 | ZBUFFER8]

#ifdef ZBUFFER32
typedef struct Depth {
    uint32_t d;
} Depth;
#endif

#ifdef ZBUFFER16
typedef struct Depth {
    uint16_t d;
} Depth;
#endif

#ifdef ZBUFFER8
typedef struct Depth {
    uint8_t d;
} Depth;
#endif

void depth_write(Depth * d, int idx, float value);
bool depth_check(Depth * d, int idx, float value);

