#include "sprite.h"
#include "../math/mat3.h"

int spriteInit(Sprite *s, Texture f, Mat4 t)
{
    if (f.frameBuffer == 0)
        return 1;

    s->frame = f;
    s->t = t;

    return 0;
}

Renderable spriteAsRenderable(Sprite * s) {
    return (Renderable){ .renderableType = RENDERABLE_SPRITE, .impl = s};
}

int spriteRandomize(Sprite * s)
{

    for (int x = 0; x < s->frame.size.x; x++ ) {
        for (int y = 0; y < s->frame.size.y; y++ ) {

            texture_draw(&s->frame,(Vec2i){x,y},pixelRandom());
        }
    }

    return 0;
}
