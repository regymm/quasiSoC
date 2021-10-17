#pragma once

#include "types.h"
#include "vec2.h"
#include "vec3.h"
#include "vec4.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct Mat4 {
    F_TYPE elements[16];
} Mat4;

Mat4 mat4Identity();
Mat4 mat4Translate(Vec3f l);

Mat4 mat4RotateX(F_TYPE phi);
Mat4 mat4RotateY(F_TYPE phi);
Mat4 mat4RotateZ(F_TYPE phi);

Vec2f mat4MultiplyVec2(Vec2f *v, Mat4 *t);
Vec3f mat4MultiplyVec3(Vec3f *v, Mat4 *t);

Vec4f mat4MultiplyVec4(Vec4f *v, Mat4 *t);
Vec4f mat4MultiplyVec4in( Vec4f *v, Mat4 *t );

Mat4 mat4MultiplyM( Mat4 * m1, Mat4 * m2);
Mat4 mat4Inverse(Mat4 * mat);
Mat4 mat4Scale(Vec3f s);

Mat4 mat4Perspective(float near, float far, float aspect, float fov);
Mat4 mat4Perspective(float near,  float far, float aspect, float fov );

float mat4NearFromProjection(Mat4 mat);
float mat4FarFromProjection(Mat4 mat);

#ifdef __cplusplus
}
#endif
