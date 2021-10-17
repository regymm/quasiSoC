#pragma once

#include "../math/vec2.h"
#include "../math/vec4.h"

/**
  * Privdes a common interface to multiple graphical backends
  */

typedef struct Renderer Renderer;
typedef struct Pixel Pixel;
typedef struct Depth Depth;
typedef struct Texture Texture;

typedef struct BackEnd {
    //Called on initialization and re-initialization
    void (*init)(Renderer *, struct BackEnd *, Vec4i rect);

    //Called before starting rendering
    void (*beforeRender)(Renderer *, struct BackEnd * );

    //Called after having finished a render
    void (*afterRender)(Renderer *, struct BackEnd * );

    //Should return the address of the buffer (height*width*sizeof(Pixel))
    Pixel * (*getFrameBuffer)(Renderer *, struct BackEnd * );

    //Handle backend specific final framebuffer draw (can apply lighting in a different way if needed)
    void (*drawPixel)(Texture * f, Vec2i pos, Pixel color, float illumination);

    //Should return the address of the buffer (height*width*sizeof(Pixel))
    Depth * (*getZetaBuffer)(Renderer *, struct BackEnd * );
} BackEnd;
