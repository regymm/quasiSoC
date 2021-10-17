
#include "memorybackend.h"

#include "../render/renderer.h"
#include "../render/texture.h"
#include "../render/pixel.h"
#include "../render/depth.h"


void memoryBackendinit( Renderer * ren, BackEnd * backEnd, Vec4i _rect) {

}

void memoryBackendbeforeRender( Renderer * ren, BackEnd * backEnd) {
}

void memoryBackendafterRender( Renderer * ren,  BackEnd * backEnd) {

}

Pixel * memoryBackendgetFrameBuffer( Renderer * ren,  BackEnd * backEnd) {
    return ((MemoryBackend *) backEnd) -> frameBuffer;
}

Depth * memoryBackendgetZetaBuffer( Renderer * ren,  BackEnd * backEnd) {
    return ((MemoryBackend *) backEnd) -> zetaBuffer;
}

void memoryBackendInit( MemoryBackend * this, Pixel * buf, Vec2i size) {

    this->backend.init = &memoryBackendinit;
    this->backend.beforeRender = &memoryBackendbeforeRender;
    this->backend.afterRender = &memoryBackendafterRender;
    this->backend.getFrameBuffer = &memoryBackendgetFrameBuffer;
    this->backend.getZetaBuffer = &memoryBackendgetZetaBuffer;

    this -> zetaBuffer = malloc(size.x*size.y*sizeof (Depth));
    this -> frameBuffer = buf;
}
