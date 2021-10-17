#pragma once

#include "../math/mat4.h"

typedef struct Renderer Renderer;

typedef enum  {
    RENDERABLE_SCENE  =0,
    RENDERABLE_SPRITE,
    RENDERABLE_OBJECT,
    RENDERABLE_COUNT,
} RenderableType;

typedef struct {
    RenderableType renderableType;
    void * impl;
} Renderable;

extern int (*renderingFunctions[RENDERABLE_COUNT])(Mat4 transform, Renderer *, Renderable);


