#pragma once

#include "pixel.h"
#include "renderable.h"
#include "../math/vec2.h"

#ifdef __cplusplus
    extern "C" {
#endif

typedef struct  Texture {
   Vec2i size;
   Pixel * frameBuffer;
} Texture;

extern int texture_init( Texture * f, Vec2i size, Pixel *);

extern Renderable texture_as_renderable( Texture * s);

extern void  texture_draw(Texture * f, Vec2i pos, Pixel color);

extern Pixel texture_read(Texture * f, Vec2i pos);

extern Pixel texture_readF(Texture * f, Vec2f pos);

extern Pixel texture_read_bilinear(Texture *f, Vec2f pos);

#ifdef __cplusplus
    }
#endif
