#include "mat3.h"
#include "vec2.h"

#include <math.h>
#include <stdint.h>

Mat3 mat3Identity() {
    return (Mat3){{
        1,  0,  0,
        0,  1,  0,
        0,  0,  1
    }};
}

Mat3 mat3Translate(Vec2f l) {
    F_TYPE x = l.x;
    F_TYPE y = l.y;
    return (Mat3){{
        1,  0,  x,
        0,  1,  y,
        0,  0,  1
    }};
}

Mat3 mat3Rotate(F_TYPE theta) {
    F_TYPE s = sin(theta);
    F_TYPE c = cos(theta);
    return (Mat3){{
        c, -s,  0,
        s,  c,  0,
        0,  0,  1
    }};
}

extern Mat3 mat3Scale(Vec2f s) {
    F_TYPE p = s.x;
    F_TYPE q = s.y;
    return (Mat3){{
        p,  0,  0,
        0,  q,  0,
        0,  0,  1
    }};
}

Vec2f mat3Multiply(Vec2f *v, Mat3 *t) {
    F_TYPE a = v->x * t->elements[0] + v->y * t->elements[1] + 1.0 * t->elements[2];
    F_TYPE b = v->x * t->elements[3] + v->y * t->elements[4] + 1.0 * t->elements[5];
    //F_TYPE c = v->x * t->elements[6] + v->y * t->elements[7] + 1.0 * t->elements[8];
    return (Vec2f){a,b};
}

Mat3 mat3MultiplyM( Mat3 * m1, Mat3 * m2) {
    Mat3 out;
    F_TYPE * a = m2->elements;
    F_TYPE * b = m1->elements;
    out.elements[0] = a[0] * b[0] + a[1] * b[3] + a[2] * b[6];
    out.elements[1] = a[0] * b[1] + a[1] * b[4] + a[2] * b[7];
    out.elements[2] = a[0] * b[2] + a[1] * b[5] + a[2] * b[8];
    out.elements[3] = a[3] * b[0] + a[4] * b[3] + a[5] * b[6];
    out.elements[4] = a[3] * b[1] + a[4] * b[4] + a[5] * b[7];
    out.elements[5] = a[3] * b[2] + a[4] * b[5] + a[5] * b[8];
    out.elements[6] = a[6] * b[0] + a[7] * b[3] + a[8] * b[6];
    out.elements[7] = a[6] * b[1] + a[7] * b[4] + a[8] * b[7];
    out.elements[8] = a[6] * b[2] + a[7] * b[5] + a[8] * b[8];
    return out;
}

F_TYPE mat3Determinant(Mat3 * mat)
{
    F_TYPE * m = mat->elements;
    return m[0] * (m[4] * m[8] - m[5] * m[7]) -
            m[3] * (m[3] * m[8] - m[5] * m[6]) +
            m[6] * (m[3] * m[7] - m[4] * m[6]);
}

Mat3 mat3Inverse(Mat3 *v)
{
    F_TYPE * b = v->elements;
    F_TYPE s = 1.0 / mat3Determinant(v);

    Mat3 out;
    F_TYPE * a = out.elements;

    //calculate inverse
    a[0] = (s) * (b[4] * b[8] - b[5] * b[7]);
    a[1] = (s) * (b[2] * b[7] - b[1] * b[8]);
    a[2] = (s) * (b[1] * b[5] - b[2] * b[4]);
    a[3] = (s) * (b[5] * b[6] - b[3] * b[8]);
    a[4] = (s) * (b[0] * b[8] - b[2] * b[6]);
    a[5] = (s) * (b[2] * b[3] - b[0] * b[5]);
    a[6] = (s) * (b[3] * b[7] - b[4] * b[6]);
    a[7] = (s) * (b[1] * b[6] - b[0] * b[7]);
    a[8] = (s) * (b[0] * b[4] - b[1] * b[3]);

    //homongenize the matrix so that homo coord is 1.0
    a[0] = a[0] / a[8];
    a[1] = a[1] / a[8];
    a[2] = a[2] / a[8];
    a[3] = a[3] / a[8];
    a[4] = a[4] / a[8];
    a[5] = a[5] / a[8];
    a[6] = a[6] / a[8];
    a[7] = a[7] / a[8];
    a[8] = a[8] / a[8];

    return out;
}

extern Mat3 mat3Complete( Vec2f origin, Vec2f translation, Vec2f scale, F_TYPE rotation ){
    int isRotated = rotation != 0;
    int isScaled = scale.x != 1.0 || scale.y != 1.0;

    //This is just a translation
    if (!isRotated && !isScaled) {
        return mat3Translate(translation);
    }

    //Transform is more complex, translate first in the origin
    Mat3 m = mat3Translate((Vec2f){-origin.x,-origin.y});

    //Apply rotation
    if (isRotated) {
        Mat3 r = mat3Rotate(rotation);
        m = mat3MultiplyM(&m, &r);
    }

    //Apply scale
    if (isScaled) {
        Mat3 s = mat3Scale(scale);
        m = mat3MultiplyM(&m, &s);
    }

    //Translate it to supposed location
    Vec2f finalTranslation = {origin.x + translation.x, origin.y + translation.y};
    Mat3 t = mat3Translate(finalTranslation);
    m = mat3MultiplyM(&m, &t);

    return m;
}

int mat3IsOnlyTranslation(Mat3 *m )
{
    if (m->elements[0] != 1.0) return 0;
    if (m->elements[1] != 0.0) return 0;
    //if (m->elements[2] != 0.0) return 0; This is a translation component
    if (m->elements[3] != 0.0) return 0;
    if (m->elements[4] != 1.0) return 0;
    //if (m->elements[5] != 1.0) return 0; This is a translation component
    if (m->elements[6] != 0.0) return 0;
    if (m->elements[7] != 0.0) return 0;
    if (m->elements[8] != 1.0) return 0;
    return 1;
}

int mat3IsOnlyTranslationDoubled(Mat3 *m)
{
    if (m->elements[0] != 2.0) return 0;
    if (m->elements[1] != 0.0) return 0;
    //if (m->elements[2] != 0.0) return 0; This is a translation component
    if (m->elements[3] != 0.0) return 0;
    if (m->elements[4] != 2.0) return 0;
    //if (m->elements[5] != 1.0) return 0; This is a translation component
    if (m->elements[6] != 0.0) return 0;
    if (m->elements[7] != 0.0) return 0;
    if (m->elements[8] != 1.0) return 0;
    return 1;
}
