#include "rasterizer.h"
#include "renderer.h"
#include "../math/mat3.h"
#include "../math/mat4.h"

#define MIN(a,b) (((a)<(b))?(a):(b))
#define MAX(a,b) (((a)>(b))?(a):(b))

Vec2i vec2iClamp(Vec2i in, Vec2i min, Vec2i max) {
    in.x = (in.x > max.x-1)? max.x-1 : (in.x < min.x)? min.x : in.x;
    in.y = (in.y > max.y-1)? max.y-1 : (in.y < min.y)? min.y : in.y;
    return in;
}

int rasterizer_draw_pixel_perfect(Vec2i off, Renderer *r, Texture * src) {
    Texture des = r->frameBuffer;

    //Transform coords on destination (it is only translation so it is easy)
    Vec2f a = (Vec2f){off.x,off.y};
    Vec2f b = (Vec2f){off.x+src->size.x,off.y};
    Vec2f c = (Vec2f){off.x,off.y+src->size.y};
    Vec2f d = (Vec2f){off.x+src->size.x,off.y+src->size.y};

    // .. To find the axis aligned boundig box
    int minX = MIN(MIN(a.x,b.x),MIN(c.x,d.x));
    int minY = MIN(MIN(a.y,b.y),MIN(c.y,d.y));
    int maxX = MAX(MAX(a.x,b.x),MAX(c.x,d.x));
    int maxY = MAX(MAX(a.y,b.y),MAX(c.y,d.y));

    //Then clamp max/min values to destination buffer
    maxX = MIN(des.size.x, MAX(maxX, 0));
    maxY = MIN(des.size.y, MAX(maxY, 0));
    minX = MIN(des.size.x, MAX(minX, 0));
    minY = MIN(des.size.y, MAX(minY, 0));

    for (int y = minY; y < maxY; y++) {
        for (int x = minX; x < maxX; x++) {
            //Transform the coordinate back to sprite space
            Vec2i desPos = {x,y};
            Vec2i srcPosI = {x-off.x,y-off.y};
            Pixel color = texture_read(src, srcPosI);
            texture_draw(&des, desPos, color);
        }
    }

    return 0;
}

int rasterizer_draw_pixel_perfect_doubled(Vec2i off, Renderer *r, Texture * src) {
    Texture des = r->frameBuffer;

    //Transform coords on destination (double the size of the frame)
    Vec2f a = (Vec2f){off.x,off.y};
    Vec2f b = (Vec2f){off.x+src->size.x*2,off.y};
    Vec2f c = (Vec2f){off.x,off.y+src->size.y*2};
    Vec2f d = (Vec2f){off.x+src->size.x*2,off.y+src->size.y*2};

    // .. To find the axis aligned boundig box
    int minX = MIN(MIN(a.x,b.x),MIN(c.x,d.x));
    int minY = MIN(MIN(a.y,b.y),MIN(c.y,d.y));
    int maxX = MAX(MAX(a.x,b.x),MAX(c.x,d.x));
    int maxY = MAX(MAX(a.y,b.y),MAX(c.y,d.y));

    //Then clamp max/min values to destination buffer
    maxX = MIN(des.size.x, MAX(maxX, 0));
    maxY = MIN(des.size.y, MAX(maxY, 0));
    minX = MIN(des.size.x, MAX(minX, 0));
    minY = MIN(des.size.y, MAX(minY, 0));

    for (int y = minY; y < maxY; y+=2) {
        for (int x = minX; x < maxX; x=x+2) {
            //Transform the coordinate back to sprite space
            Vec2i srcPosI = {(x-off.x)/2,(y-off.y)/2};
            Pixel color = texture_read(src, srcPosI);
            texture_draw(&des, (Vec2i){x,y}, color);
            texture_draw(&des, (Vec2i){x+1,y}, color);
        }
        for (int x = minX; x < maxX; x=x+2) {
            //Transform the coordinate back to sprite space
            Vec2i srcPosI = {(x-off.x)/2,(y-off.y)/2};
            Pixel color = texture_read(src, srcPosI);
            texture_draw(&des, (Vec2i){x,y+1}, color);
            texture_draw(&des, (Vec2i){x+1,y+1}, color);
        }
    }

    return 0;
}

int rasterizer_draw_transformed(Mat4 t, Renderer *r, Texture * src) {
    Texture des = r->frameBuffer;

    Mat4 inv = mat4Inverse(&t);

    // Transform 4 points of frame to frame buffer space
    Vec2f a = (Vec2f){0,0};
    Vec2f b = (Vec2f){src->size.x,0};
    Vec2f c = (Vec2f){0,src->size.y};
    Vec2f d = (Vec2f){src->size.x,src->size.y};

    a = mat4MultiplyVec2(&a, &t);
    b = mat4MultiplyVec2(&b, &t);
    c = mat4MultiplyVec2(&c, &t);
    d = mat4MultiplyVec2(&d, &t);

    // .. To find the axis aligned boundig box
    int minX = MIN(MIN(a.x,b.x),MIN(c.x,d.x));
    int minY = MIN(MIN(a.y,b.y),MIN(c.y,d.y));
    int maxX = MAX(MAX(a.x,b.x),MAX(c.x,d.x));
    int maxY = MAX(MAX(a.y,b.y),MAX(c.y,d.y));

    //Then clamp max/min values to destination buffer
    maxX = MIN(des.size.x, MAX(maxX, 0));
    maxY = MIN(des.size.y, MAX(maxY, 0));
    minX = MIN(des.size.x, MAX(minX, 0));
    minY = MIN(des.size.y, MAX(minY, 0));

    //Now we can iterate over the pixels of the axis-alignes-bounding-box (AABB) which contain the source frame
    for (int y = minY; y <= maxY; y++) {
        for (int x = minX; x <= maxX; x++) {


#ifdef FILTERING_NEAREST
            //Transform the coordinate back to sprite space with the inverse tranform
            Vec2i desPos = {x,y};
            Vec2f desPosF = (Vec2f){desPos.x+0.5,desPos.y+0.5};
            Vec2f srcPosF = mat4MultiplyVec2(&desPosF,&inv);
            Vec2i srcPosI = vecFtoI(srcPosF);

            //TODO: Improve this check by precalculating start/end coord in loop with line intersection
            //We need to check if transformed coord are inside the frame
            //Probably there is a faster way of doing this by checking line intersection
            //with the sprite transformed quad but I don't care for now because we
            //do not use rotations as of now.
            if (srcPosF.x < 0) continue;
            if (srcPosF.y < 0) continue;
            if (srcPosF.x >= src->size.x) continue;
            if (srcPosF.y >= src->size.y) continue;
            Pixel color = texture_read(src, srcPosI);
#endif
#ifdef FILTERING_BILINEAR
            Vec2i desPos = {x,y};
            Vec2f desPosF = (Vec2f){desPos.x+0.5f,desPos.y+0.5f};
            Vec2f srcPosF = mat4Multiply(&desPosF,&inv);

            //TODO: Improve this check by precalculating start/end coord in loop with line intersection
            //We need to check if transformed coord are inside the frame
            //Probably there is a faster way of doing this by checking line intersection
            //with the sprite transformed quad but I don't care for now because we
            //do not use rotations as of now.
            if (srcPosF.x < 0) continue;
            if (srcPosF.y < 0) continue;
            if (srcPosF.x >= src->size.x-1) continue;
            if (srcPosF.y >= src->size.y-1) continue;

            Pixel color = frameReadBilinear(src, srcPosF);
#endif
#ifdef FILTERING_ANISOTROPIC //4X
            Vec2i desPos = {x,y};
            Vec2f desPosF1 = (Vec2f){desPos.x+0.25f,desPos.y+0.25f};
            Vec2f desPosF2 = (Vec2f){desPos.x+0.75f,desPos.y+0.75f};
            Vec2f srcPosF1 = mat4Multiply(&desPosF1,&inv);
            Vec2f srcPosF2 = mat4Multiply(&desPosF2,&inv);

            if (srcPosF1.x < 0 && srcPosF2.x < 0) continue;
            if (srcPosF1.y < 0 && srcPosF2.y < 0) continue;
            if (srcPosF1.x > src->size.x && srcPosF2.x > src->size.x) continue;
            if (srcPosF1.y > src->size.y && srcPosF2.y > src->size.y) continue;

            Vec2i srcPosI1 = vec2iClamp((Vec2i) {srcPosF1.x,srcPosF1.y},(Vec2i){0,0},src->size);
            Vec2i srcPosI2 = vec2iClamp((Vec2i) {srcPosF1.x,srcPosF2.y},(Vec2i){0,0},src->size);
            Vec2i srcPosI3 = vec2iClamp((Vec2i) {srcPosF2.x,srcPosF1.y},(Vec2i){0,0},src->size);
            Vec2i srcPosI4 = vec2iClamp((Vec2i) {srcPosF2.x,srcPosF2.y},(Vec2i){0,0},src->size);

            float p1 = src->frameBuffer[(int)(srcPosI1.x + srcPosI1.y * src->size.x)].g;
            float p2 = src->frameBuffer[(int)(srcPosI2.x + srcPosI2.y * src->size.x)].g;
            float p3 = src->frameBuffer[(int)(srcPosI3.x + srcPosI3.y * src->size.x)].g;
            float p4 = src->frameBuffer[(int)(srcPosI4.x + srcPosI4.y * src->size.x)].g;

            Pixel color = {(p1+p2+p3+p4) / 4};
#endif
#ifdef FILTERING_ANISOTROPICX2 //8X
            Vec2i desPos = {x,y};
            Vec2f desPosF1  = (Vec2f){desPos.x+0.125f,desPos.y+0.125f};
            Vec2f desPosF2  = (Vec2f){desPos.x+0.375f,desPos.y+0.375f};
            Vec2f desPosF3  = (Vec2f){desPos.x+0.625f,desPos.y+0.625f};
            Vec2f desPosF4  = (Vec2f){desPos.x+0.875f,desPos.y+0.875f};

            Vec2f srcPosF1  = mat4MultiplyVec2(&desPosF1,&inv);
            Vec2f srcPosF2  = mat4MultiplyVec2(&desPosF2,&inv);
            Vec2f srcPosF3  = mat4MultiplyVec2(&desPosF3,&inv);
            Vec2f srcPosF4  = mat4MultiplyVec2(&desPosF4,&inv);

            if (srcPosF1.x < 0 && srcPosF2.x < 0 && srcPosF3.x < 0 && srcPosF4.x < 0) continue;
            if (srcPosF1.y < 0 && srcPosF2.y < 0 && srcPosF3.y < 0 && srcPosF4.y < 0) continue;
            if (srcPosF1.x > src->size.x && srcPosF2.x > src->size.x &&
                srcPosF3.x > src->size.x && srcPosF4.x > src->size.x) continue;
            if (srcPosF1.y > src->size.y && srcPosF2.y > src->size.y &&
                srcPosF3.y > src->size.y && srcPosF4.y > src->size.y) continue;

            Vec2i srcPosI1  = vec2iClamp((Vec2i) {srcPosF1.x,srcPosF1.y},(Vec2i){0,0},src->size);
            Vec2i srcPosI2  = vec2iClamp((Vec2i) {srcPosF1.x,srcPosF2.y},(Vec2i){0,0},src->size);
            Vec2i srcPosI3  = vec2iClamp((Vec2i) {srcPosF1.x,srcPosF3.y},(Vec2i){0,0},src->size);
            Vec2i srcPosI4  = vec2iClamp((Vec2i) {srcPosF1.x,srcPosF4.y},(Vec2i){0,0},src->size);
            Vec2i srcPosI5  = vec2iClamp((Vec2i) {srcPosF2.x,srcPosF1.y},(Vec2i){0,0},src->size);
            Vec2i srcPosI6  = vec2iClamp((Vec2i) {srcPosF2.x,srcPosF2.y},(Vec2i){0,0},src->size);
            Vec2i srcPosI7  = vec2iClamp((Vec2i) {srcPosF2.x,srcPosF3.y},(Vec2i){0,0},src->size);
            Vec2i srcPosI8  = vec2iClamp((Vec2i) {srcPosF2.x,srcPosF4.y},(Vec2i){0,0},src->size);
            Vec2i srcPosI9  = vec2iClamp((Vec2i) {srcPosF3.x,srcPosF1.y},(Vec2i){0,0},src->size);
            Vec2i srcPosI0  = vec2iClamp((Vec2i) {srcPosF3.x,srcPosF2.y},(Vec2i){0,0},src->size);
            Vec2i srcPosI11 = vec2iClamp((Vec2i) {srcPosF3.x,srcPosF3.y},(Vec2i){0,0},src->size);
            Vec2i srcPosI12 = vec2iClamp((Vec2i) {srcPosF3.x,srcPosF4.y},(Vec2i){0,0},src->size);
            Vec2i srcPosI13 = vec2iClamp((Vec2i) {srcPosF4.x,srcPosF1.y},(Vec2i){0,0},src->size);
            Vec2i srcPosI14 = vec2iClamp((Vec2i) {srcPosF4.x,srcPosF2.y},(Vec2i){0,0},src->size);
            Vec2i srcPosI15 = vec2iClamp((Vec2i) {srcPosF4.x,srcPosF3.y},(Vec2i){0,0},src->size);
            Vec2i srcPosI16 = vec2iClamp((Vec2i) {srcPosF4.x,srcPosF4.y},(Vec2i){0,0},src->size);

            float p1 = src->frameBuffer[(int)(srcPosI1.x + srcPosI1.y * src->size.x)].g;
            float p2 = src->frameBuffer[(int)(srcPosI2.x + srcPosI2.y * src->size.x)].g;
            float p3 = src->frameBuffer[(int)(srcPosI3.x + srcPosI3.y * src->size.x)].g;
            float p4 = src->frameBuffer[(int)(srcPosI4.x + srcPosI4.y * src->size.x)].g;
            float p5 = src->frameBuffer[(int)(srcPosI5.x + srcPosI5.y * src->size.x)].g;
            float p6 = src->frameBuffer[(int)(srcPosI6.x + srcPosI6.y * src->size.x)].g;
            float p7 = src->frameBuffer[(int)(srcPosI7.x + srcPosI7.y * src->size.x)].g;
            float p8 = src->frameBuffer[(int)(srcPosI8.x + srcPosI8.y * src->size.x)].g;
            float p9 = src->frameBuffer[(int)(srcPosI9.x + srcPosI9.y * src->size.x)].g;
            float p0 = src->frameBuffer[(int)(srcPosI0.x + srcPosI0.y * src->size.x)].g;
            float p11 = src->frameBuffer[(int)(srcPosI11.x + srcPosI11.y * src->size.x)].g;
            float p12 = src->frameBuffer[(int)(srcPosI12.x + srcPosI12.y * src->size.x)].g;
            float p13 = src->frameBuffer[(int)(srcPosI13.x + srcPosI13.y * src->size.x)].g;
            float p14 = src->frameBuffer[(int)(srcPosI14.x + srcPosI14.y * src->size.x)].g;
            float p15 = src->frameBuffer[(int)(srcPosI15.x + srcPosI15.y * src->size.x)].g;
            float p16 = src->frameBuffer[(int)(srcPosI16.x + srcPosI16.y * src->size.x)].g;

            Pixel color = pixelFromUInt8((p1+p2+p3+p4+p5+p6+p7+p8+p9+p0+p11+p12+p13+p14+p15+p16) / 16);
#endif
            texture_draw(&des, desPos, color);
        }
    }

    return 0;
}
