#include "scene.h"
#include "renderable.h"

int sceneAddRenderable(Scene * scene, Renderable renderable)
{
    if (scene->numberOfRenderables >= MAX_SCENE_RENDERABLES) {
        return 1; //Too many renderables in this scene
    }

    scene->renderables[scene->numberOfRenderables++] = renderable;
    return 0;
}

int sceneInit(Scene * s)
{
    s->transform = mat4Identity();
    s->numberOfRenderables = 0;
    s->visible = 1;

    return 0;
}


extern Renderable sceneAsRenderable(Scene * scene) {
    return (Renderable){.renderableType = RENDERABLE_SCENE, .impl = scene};
}
