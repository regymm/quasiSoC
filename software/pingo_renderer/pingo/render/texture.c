#include "texture.h"
#include "math.h"

int texture_init( Texture *f, Vec2i size, Pixel *buf )
{
    if(size.x * size.y == 0)
        return 1; // 0 sized rect

    if(buf == 0)
        return 2; // null ptr buffer

    f->frameBuffer = (Pixel *)buf;
    f->size = size;

    return 0;
}

/*#ifdef WIN32*/
/*void texture_draw(Texture *f, Vec2i pos, Pixel color)*/
/*{*/
	/*f->frameBuffer[pos.x + pos.y * f->size.x] = color;*/
/*}*/
/*#endif*/
void texture_draw(Texture *f, Vec2i pos, Pixel color)
{
	f->frameBuffer[pos.x + pos.y * f->size.x] = color;
}

Pixel texture_read(Texture *f, Vec2i pos)
{
    return f->frameBuffer[pos.x + pos.y * f->size.x];
}

Pixel texture_readF(Texture *f, Vec2f pos)
{
    uint16_t x = (uint16_t)(pos.x * f->size.x) % f->size.x;
    uint16_t y = (uint16_t)(pos.y * f->size.y) % f->size.x;
    uint32_t index = x + y * f->size.x;
    Pixel value = f->frameBuffer[index];
    return value;
}

Pixel texture_read_bilinear(Texture *f, Vec2f pos)
{
    float kX = fmodf(pos.x, 1.0f);
    int lowX = floorf(pos.x);
    int higX = lowX + 1;

    float kY = fmodf(pos.y, 1.0f);
    int lowY = floorf(pos.y);
    int higY = lowY + 1;

    float p1 = f->frameBuffer[lowX + lowY * f->size.x].g;
    float p2 = f->frameBuffer[higX + lowY * f->size.x].g;
    float p3 = f->frameBuffer[lowX + higY * f->size.x].g;
    float p4 = f->frameBuffer[higX + higY * f->size.x].g;

    Pixel out ={
        ((p1 * (1.0f - kX) + p2 * (kX)) * (1.0 - kY))
        +
        ((p3 * (1.0f - kX) + p4 * (kX)) * (kY))
    };
    return out;
}





