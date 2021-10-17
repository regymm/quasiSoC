#pragma once

#include "../math/mat4.h"

#include "mesh.h"
#include "renderable.h"
#include "scene.h"

typedef struct Object {
    Mesh * mesh;
    Mat4 transform;
    Material * material;
} Object;

Renderable object_as_renderable(Object * object);

