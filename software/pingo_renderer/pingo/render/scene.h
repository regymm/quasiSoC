#pragma once

#include <stdint.h>
#include "renderable.h"
#include "../math/mat3.h"
#include "../math/mat4.h"

#ifdef __cplusplus
    extern "C" {
#endif

#define MAX_SCENE_RENDERABLES 32

typedef struct Scene {
    uint8_t numberOfRenderables;
    Renderable renderables[MAX_SCENE_RENDERABLES];
    Mat4 transform;
    uint8_t visible;
} Scene;

extern int sceneInit(Scene * s);
extern int sceneAddRenderable(Scene * scene, Renderable renderable);

extern Renderable sceneAsRenderable(Scene * scene);

#ifdef __cplusplus
    }
#endif
