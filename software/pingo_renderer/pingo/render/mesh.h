#pragma once

#include <stdint.h>

#include "../math/vec3.h"

#include "material.h"

typedef struct Mesh {
    int indexes_count;
    uint16_t * pos_indices;
    uint16_t * tex_indices;
    Vec3f * positions;
    Vec2f * textCoord;
} Mesh;


