#include "renderable.h"
#include "renderer.h"

int (*renderingFunctions[RENDERABLE_COUNT])(Mat4 transform, Renderer *, Renderable);

