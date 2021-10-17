#pragma once

#include "texture.h"
#include "renderable.h"
#include "pixel.h"
#include "../math/vec4.h"

typedef struct Scene Scene;
typedef struct BackEnd BackEnd;

typedef struct Renderer{
    Vec4i camera;
    Scene * scene;

    Texture frameBuffer;
    Pixel clearColor;
    int clear;

    Mat4 camera_projection;
    Mat4 camera_view;

    BackEnd * backEnd;

} Renderer;

extern int rendererRender(Renderer *);

extern int rendererInit(Renderer *, Vec2i size, struct BackEnd * backEnd);

extern int rendererSetScene(Renderer *r, Scene *s);

extern int rendererSetCamera(Renderer *r, Vec4i camera);
