#include "mat4.h"
#include "vec2.h"
#include "vec3.h"
#include "vec4.h"

#include <math.h>
#include <stdint.h>

Mat4 mat4Identity() {
    return (Mat4){{
            1,  0,  0, 0,
            0,  1,  0, 0,
            0,  0,  1, 0,
            0,  0,  0, 1,
        }};
}

Mat4 mat4Translate(Vec3f l) {
    F_TYPE x = l.x;
    F_TYPE y = l.y;
    F_TYPE z = l.z;
    return (Mat4){{
            1,  0,  0, x,
                    0,  1,  0, y,
                    0,  0,  1, z,
                    0,  0,  0, 1,
        }};
}

Mat4 mat4RotateX(F_TYPE phi) {
    F_TYPE s = sin(phi);
    F_TYPE c = cos(phi);
    return (Mat4){{
            1,  0,  0, 0,
            0,  c, -s, 0,
                    0,  s,  c, 0,
                    0,  0,  0, 1,
        }};
}
Mat4 mat4RotateY(F_TYPE phi) {
    F_TYPE s = sin(phi);
    F_TYPE c = cos(phi);
    return (Mat4){{
            c,  0,  s, 0,
                    0,  1,  0, 0,
                    -s,  0,  c, 0,
                    0,  0,  0, 1,
        }};
}
Mat4 mat4RotateZ(F_TYPE phi) {
    F_TYPE s = sin(phi);
    F_TYPE c = cos(phi);
    return (Mat4){{
            c, -s,  0, 0,
                    s,  c,  0, 0,
                    0,  0,  1, 0,
                    0,  0,  0, 1,
        }};
}

extern Mat4 mat4Scale(Vec3f s) {
    F_TYPE p = s.x;
    F_TYPE q = s.y;
    F_TYPE r = s.z;
    return (Mat4){{
            p,  0,  0, 0,
                    0,  q,  0, 0,
                    0,  0,  r, 0,
                    0,  0,  0, 1,
        }};
}

Vec2f mat4MultiplyVec2(Vec2f *v, Mat4 *t) {
    F_TYPE a = v->x * t->elements[0] + v->y * t->elements[1] + 1.0 * t->elements[2] + 1.0 * t->elements[3];
    F_TYPE b = v->x * t->elements[4] + v->y * t->elements[5] + 1.0 * t->elements[6] + 1.0 * t->elements[7];
    return (Vec2f){a,b};
}

Vec3f mat4MultiplyVec3(Vec3f *v, Mat4 *t) {
    F_TYPE a = v->x * t->elements[0] + v->y * t->elements[1] + v->z * t->elements[2] + 1.0 * t->elements[3];
    F_TYPE b = v->x * t->elements[4] + v->y * t->elements[5] + v->z * t->elements[6] + 1.0 * t->elements[7];
    F_TYPE c = v->x * t->elements[8] + v->y * t->elements[9] + v->z * t->elements[10] + 1.0 * t->elements[11];
    return (Vec3f){a,b,c};
}

Vec4f mat4MultiplyVec4(Vec4f *v, Mat4 *t) {
    F_TYPE a = v->x * t->elements[0] + v->y * t->elements[1] + v->z * t->elements[2] + 1.0 * t->elements[3];
    F_TYPE b = v->x * t->elements[4] + v->y * t->elements[5] + v->z * t->elements[6] + 1.0 * t->elements[7];
    F_TYPE c = v->x * t->elements[8] + v->y * t->elements[9] + v->z * t->elements[10] + 1.0 * t->elements[11];
    F_TYPE d = v->x * t->elements[12] + v->y * t->elements[13] + v->z * t->elements[14] + 1.0 * t->elements[15];
    return (Vec4f){a,b,c,d};
}

Vec4f mat4MultiplyVec4in( Vec4f *v, Mat4 *t ) {
    F_TYPE a = v->x * t->elements[0] + v->y * t->elements[4] + v->z * t->elements[8] + 1.0 * t->elements[12];
    F_TYPE b = v->x * t->elements[1] + v->y * t->elements[5] + v->z * t->elements[9] + 1.0 * t->elements[13];
    F_TYPE c = v->x * t->elements[2] + v->y * t->elements[6] + v->z * t->elements[10] + 1.0 * t->elements[14];
    F_TYPE d = v->x * t->elements[3] + v->y * t->elements[7] + v->z * t->elements[1] + 1.0 * t->elements[15];
    return (Vec4f){a,b,c,d};
}

Mat4 mat4MultiplyM( Mat4 * m1, Mat4 * m2) {
    Mat4 out;
    F_TYPE * a = m2->elements;
    F_TYPE * b = m1->elements;

    out.elements[0x0] = a[0x0] * b[0x0] + a[0x1] * b[0x4] + a[0x2] * b[0x8] + a[0x3] * b[0xc];
    out.elements[0x1] = a[0x0] * b[0x1] + a[0x1] * b[0x5] + a[0x2] * b[0x9] + a[0x3] * b[0xd];
    out.elements[0x2] = a[0x0] * b[0x2] + a[0x1] * b[0x6] + a[0x2] * b[0xa] + a[0x3] * b[0xe];
    out.elements[0x3] = a[0x0] * b[0x3] + a[0x1] * b[0x7] + a[0x2] * b[0xb] + a[0x3] * b[0xf];

    out.elements[0x4] = a[0x4] * b[0x0] + a[0x5] * b[0x4] + a[0x6] * b[0x8] + a[0x7] * b[0xc];
    out.elements[0x5] = a[0x4] * b[0x1] + a[0x5] * b[0x5] + a[0x6] * b[0x9] + a[0x7] * b[0xd];
    out.elements[0x6] = a[0x4] * b[0x2] + a[0x5] * b[0x6] + a[0x6] * b[0xa] + a[0x7] * b[0xe];
    out.elements[0x7] = a[0x4] * b[0x3] + a[0x5] * b[0x7] + a[0x6] * b[0xb] + a[0x7] * b[0xf];

    out.elements[0x8] = a[0x8] * b[0x0] + a[0x9] * b[0x4] + a[0xa] * b[0x8] + a[0xb] * b[0xc];
    out.elements[0x9] = a[0x8] * b[0x1] + a[0x9] * b[0x5] + a[0xa] * b[0x9] + a[0xb] * b[0xd];
    out.elements[0xA] = a[0x8] * b[0x2] + a[0x9] * b[0x6] + a[0xa] * b[0xa] + a[0xb] * b[0xe];
    out.elements[0xB] = a[0x8] * b[0x3] + a[0x9] * b[0x7] + a[0xa] * b[0xb] + a[0xb] * b[0xf];

    out.elements[0xC] = a[0xc] * b[0x0] + a[0xd] * b[0x4] + a[0xe] * b[0x8] + a[0xf] * b[0xc];
    out.elements[0xD] = a[0xc] * b[0x1] + a[0xd] * b[0x5] + a[0xe] * b[0x9] + a[0xf] * b[0xd];
    out.elements[0xE] = a[0xc] * b[0x2] + a[0xd] * b[0x6] + a[0xe] * b[0xa] + a[0xf] * b[0xe];
    out.elements[0xF] = a[0xc] * b[0x3] + a[0xd] * b[0x7] + a[0xe] * b[0xb] + a[0xf] * b[0xf];

    return out;
}

F_TYPE mat4Determinant(Mat4 * mat)
{
    F_TYPE * a = mat->elements;
    float a00 = a[0],  a01 = a[1],  a02 = a[2],  a03 = a[3],
            a10 = a[4],  a11 = a[5],  a12 = a[6],  a13 = a[7],
            a20 = a[8],  a21 = a[9],  a22 = a[10], a23 = a[11],
            a30 = a[12], a31 = a[13], a32 = a[14], a33 = a[15];

    F_TYPE b00 = a00 * a11 - a01 * a10;
    F_TYPE b01 = a00 * a12 - a02 * a10;
    F_TYPE b02 = a00 * a13 - a03 * a10;
    F_TYPE b03 = a01 * a12 - a02 * a11;
    F_TYPE b04 = a01 * a13 - a03 * a11;
    F_TYPE b05 = a02 * a13 - a03 * a12;
    F_TYPE b06 = a20 * a31 - a21 * a30;
    F_TYPE b07 = a20 * a32 - a22 * a30;
    F_TYPE b08 = a20 * a33 - a23 * a30;
    F_TYPE b09 = a21 * a32 - a22 * a31;
    F_TYPE b10 = a21 * a33 - a23 * a31;
    F_TYPE b11 = a22 * a33 - a23 * a32;

    // Calculate the determinant
    return b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
}

Mat4 mat4Inverse(Mat4 * mat)
{
    F_TYPE * m = mat->elements;
    float inv[16], det;

    inv[0] = m[5]  * m[10] * m[15] -
            m[5]  * m[11] * m[14] -
            m[9]  * m[6]  * m[15] +
            m[9]  * m[7]  * m[14] +
            m[13] * m[6]  * m[11] -
            m[13] * m[7]  * m[10];

    inv[4] = -m[4]  * m[10] * m[15] +
            m[4]  * m[11] * m[14] +
            m[8]  * m[6]  * m[15] -
            m[8]  * m[7]  * m[14] -
            m[12] * m[6]  * m[11] +
            m[12] * m[7]  * m[10];

    inv[8] = m[4]  * m[9] * m[15] -
            m[4]  * m[11] * m[13] -
            m[8]  * m[5] * m[15] +
            m[8]  * m[7] * m[13] +
            m[12] * m[5] * m[11] -
            m[12] * m[7] * m[9];

    inv[12] = -m[4]  * m[9] * m[14] +
            m[4]  * m[10] * m[13] +
            m[8]  * m[5] * m[14] -
            m[8]  * m[6] * m[13] -
            m[12] * m[5] * m[10] +
            m[12] * m[6] * m[9];

    inv[1] = -m[1]  * m[10] * m[15] +
            m[1]  * m[11] * m[14] +
            m[9]  * m[2] * m[15] -
            m[9]  * m[3] * m[14] -
            m[13] * m[2] * m[11] +
            m[13] * m[3] * m[10];

    inv[5] = m[0]  * m[10] * m[15] -
            m[0]  * m[11] * m[14] -
            m[8]  * m[2] * m[15] +
            m[8]  * m[3] * m[14] +
            m[12] * m[2] * m[11] -
            m[12] * m[3] * m[10];

    inv[9] = -m[0]  * m[9] * m[15] +
            m[0]  * m[11] * m[13] +
            m[8]  * m[1] * m[15] -
            m[8]  * m[3] * m[13] -
            m[12] * m[1] * m[11] +
            m[12] * m[3] * m[9];

    inv[13] = m[0]  * m[9] * m[14] -
            m[0]  * m[10] * m[13] -
            m[8]  * m[1] * m[14] +
            m[8]  * m[2] * m[13] +
            m[12] * m[1] * m[10] -
            m[12] * m[2] * m[9];

    inv[2] = m[1]  * m[6] * m[15] -
            m[1]  * m[7] * m[14] -
            m[5]  * m[2] * m[15] +
            m[5]  * m[3] * m[14] +
            m[13] * m[2] * m[7] -
            m[13] * m[3] * m[6];

    inv[6] = -m[0]  * m[6] * m[15] +
            m[0]  * m[7] * m[14] +
            m[4]  * m[2] * m[15] -
            m[4]  * m[3] * m[14] -
            m[12] * m[2] * m[7] +
            m[12] * m[3] * m[6];

    inv[10] = m[0]  * m[5] * m[15] -
            m[0]  * m[7] * m[13] -
            m[4]  * m[1] * m[15] +
            m[4]  * m[3] * m[13] +
            m[12] * m[1] * m[7] -
            m[12] * m[3] * m[5];

    inv[14] = -m[0]  * m[5] * m[14] +
            m[0]  * m[6] * m[13] +
            m[4]  * m[1] * m[14] -
            m[4]  * m[2] * m[13] -
            m[12] * m[1] * m[6] +
            m[12] * m[2] * m[5];

    inv[3] = -m[1] * m[6] * m[11] +
            m[1] * m[7] * m[10] +
            m[5] * m[2] * m[11] -
            m[5] * m[3] * m[10] -
            m[9] * m[2] * m[7] +
            m[9] * m[3] * m[6];

    inv[7] = m[0] * m[6] * m[11] -
            m[0] * m[7] * m[10] -
            m[4] * m[2] * m[11] +
            m[4] * m[3] * m[10] +
            m[8] * m[2] * m[7] -
            m[8] * m[3] * m[6];

    inv[11] = -m[0] * m[5] * m[11] +
            m[0] * m[7] * m[9] +
            m[4] * m[1] * m[11] -
            m[4] * m[3] * m[9] -
            m[8] * m[1] * m[7] +
            m[8] * m[3] * m[5];

    inv[15] = m[0] * m[5] * m[10] -
            m[0] * m[6] * m[9] -
            m[4] * m[1] * m[10] +
            m[4] * m[2] * m[9] +
            m[8] * m[1] * m[6] -
            m[8] * m[2] * m[5];

    det = m[0] * inv[0] + m[1] * inv[4] + m[2] * inv[8] + m[3] * inv[12];
    //assert(det != 0);

    Mat4 out;
    det = 1.0 / det;

    for (int i = 0; i < 16; i++)
        out.elements[i] = inv[i] * det;

    return out;
}

Mat4 mat4Perspective(float near, float far, float aspect, float fov)
{
    float h = cos(fov/2.0) / sin(fov/2.0);
    float w = h / aspect;
    float nearFar = near * far;
    float farNear = far - near;

    Mat4 m = {{
                  w,          0,          0,                  0,
                  0,          h,          0,                  0,
                  0,          0,          far/(farNear),      1,
                  0,          0,          -nearFar/farNear,   0
              }};

    return m;
}

float mat4NearFromProjection(Mat4 mat)
{
    float C = mat.elements[10]; // 2 2
    float D = mat.elements[11]; // 2 3

    return D / (C - 1.0);
}

float mat4FarFromProjection(Mat4 mat)
{
    float C = mat.elements[10]; // 2 2
    float D = mat.elements[11]; // 2 3

    return D / (C + 1.0);
}



