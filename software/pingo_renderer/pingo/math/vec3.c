#include "vec3.h"
#include <math.h>

Vec3f vec3fmul(Vec3f a, float b)
{
    a.x = a.x * b;
    a.y = a.y * b;
    a.z = a.z * b;

    return a;
}

Vec3f vec3fsumV(Vec3f a, Vec3f b)
{
    a.x = a.x + b.x;
    a.y = a.y + b.y;
    a.z = a.z + b.z;

    return a;
}

Vec3f vec3fsubV(Vec3f a, Vec3f b)
{
    a.x = a.x - b.x;
    a.y = a.y - b.y;
    a.z = a.z - b.z;

    return a;
}

Vec3f vec3fsum(Vec3f a, float b)
{
    a.x = a.x + b;
    a.y = a.y + b;
    a.z = a.z + b;

    return a;
}

float vec3Dot(Vec3f a, Vec3f b)
{
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

Vec3f vec3f(float x, float y, float z)
{
    return (Vec3f){x,y,z};
}

Vec3f vec3Cross(Vec3f a, Vec3f b)
{

    return (Vec3f) {a.y * b.z - b.y * a.z,
                    a.z * b.x - b.z * a.x,
                    a.x * b.y - b.x * a.y};
}

Vec3f vec3Normalize(Vec3f v)
{
    float sqrt = sqrtf(v.x * v.x + v.y * v.y + v.z * v.z);
    return (Vec3f){v.x / sqrt, v.y / sqrt, v.z / sqrt};
}
