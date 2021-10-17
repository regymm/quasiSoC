#pragma once

#include "types.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct Vec3i {
    I_TYPE x;
    I_TYPE y;
    I_TYPE z;
} Vec3i;

typedef struct Vec3f {
    F_TYPE x;
    F_TYPE y;
    F_TYPE z;
} Vec3f;

Vec3f vec3f(float,float,float);
Vec3f vec3fmul(Vec3f,float);
Vec3f vec3fsumV(Vec3f,Vec3f);
Vec3f vec3fsubV(Vec3f,Vec3f);
Vec3f vec3fsum(Vec3f,float);
float vec3Dot(Vec3f,Vec3f);
Vec3f vec3Cross(Vec3f,Vec3f);
Vec3f vec3Normalize(Vec3f);

#ifdef __cplusplus
}
#endif
