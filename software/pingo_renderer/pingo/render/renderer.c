#include <string.h>
#include <stdio.h>
#include "renderer.h"
#include "sprite.h"
#include "pixel.h"
#include "depth.h"
#include "backend.h"
#include "scene.h"
#include "rasterizer.h"
#include "object.h"
/*#include "../backend/ttgobackend.h"*/


int renderFrame(Renderer * r, Renderable ren) {
    Texture * f = ren.impl;
    return rasterizer_draw_pixel_perfect((Vec2i) { 0, 0 }, r, f);
};

int renderSprite(Mat4 transform, Renderer * r, Renderable ren) {
    Sprite * s = ren.impl;
    Mat4 backUp = s->t;

    //Apply parent transform to the local transform
    s->t = mat4MultiplyM( & s->t, & transform);

    //Apply camera translation
    Mat4 newMat = mat4Translate((Vec3f) { -r->camera.x, -r->camera.y, 0 });
    s->t = mat4MultiplyM( & s->t, & newMat);

    /*
  if (mat4IsOnlyTranslation(&s->t)) {
      Vec2i off = {s->t.elements[2], s->t.elements[5]};
      rasterizer_draw_pixel_perfect(off,r, &s->frame);
      s->t = backUp;
      return 0;
  }

  if (mat4IsOnlyTranslationDoubled(&s->t)) {
      Vec2i off = {s->t.elements[2], s->t.elements[5]};
      rasterizer_draw_pixel_perfect_doubled(off,r, &s->frame);
      s->t = backUp;
      return 0;
  }*/

    rasterizer_draw_transformed(s->t, r, & s->frame);
    s->t = backUp;
    return 0;
};

void renderRenderable(Mat4 transform, Renderer * r, Renderable ren) {
    renderingFunctions[ren.renderableType](transform, r, ren);
};

int renderScene(Mat4 transform, Renderer * r, Renderable ren) {
    Scene * s = ren.impl;
    if (!s->visible)
        return 0;

    //Apply hierarchy transfom
    Mat4 newTransform = mat4MultiplyM( & s->transform, & transform);
    for (int i = 0; i < s->numberOfRenderables; i++) {
        renderRenderable(newTransform, r, s->renderables[i]);
    }
    return 0;
};

#define MIN(a, b)(((a) < (b)) ? (a) : (b))
#define MAX(a, b)(((a) > (b)) ? (a) : (b))

int edgeFunction(const Vec2f * a, const Vec2f * b, const Vec2f * c) {
    return (c->x - a->x) * (b->y - a->y) - (c->y - a->y) * (b->x - a->x);
}

float isClockWise(float x1, float y1, float x2, float y2, float x3, float y3) {
    return (y2 - y1) * (x3 - x2) - (y3 - y2) * (x2 - x1);
}

int orient2d( Vec2i a,  Vec2i b,  Vec2i c)
{
    return (b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x);
}

void backendDrawPixel (Renderer * r, Texture * f, Vec2i pos, Pixel color, float illumination) {
    //If backend spcifies something..
    if (r->backEnd->drawPixel != 0)
        r->backEnd->drawPixel(f, pos, color, illumination);

    //By default call this
    texture_draw(f, pos, pixelMul(color,illumination));
}

int renderObject(Mat4 object_transform, Renderer * r, Renderable ren) {

    const Vec2i scrSize = r->frameBuffer.size;
    Object * o = ren.impl;

    // MODEL MATRIX
    Mat4 m = mat4MultiplyM( &o->transform, &object_transform  );

    // VIEW MATRIX
    Mat4 v = r->camera_view;
    Mat4 p = r->camera_projection;

    for (int i = 0; i < o->mesh->indexes_count; i += 3) {
        Vec3f * ver1 = &o->mesh->positions[o->mesh->pos_indices[i+0]];
        Vec3f * ver2 = &o->mesh->positions[o->mesh->pos_indices[i+1]];
        Vec3f * ver3 = &o->mesh->positions[o->mesh->pos_indices[i+2]];

        Vec2f tca = {0,0};
        Vec2f tcb = {0,0};
        Vec2f tcc = {0,0};

        if (o->material != 0) {
            tca = o->mesh->textCoord[o->mesh->tex_indices[i+0]];
            tcb = o->mesh->textCoord[o->mesh->tex_indices[i+1]];
            tcc = o->mesh->textCoord[o->mesh->tex_indices[i+2]];
        }

        Vec4f a =  { ver1->x, ver1->y, ver1->z, 1 };
        Vec4f b =  { ver2->x, ver2->y, ver2->z, 1 };
        Vec4f c =  { ver3->x, ver3->y, ver3->z, 1 };

        a = mat4MultiplyVec4( &a, &m);
        b = mat4MultiplyVec4( &b, &m);
        c = mat4MultiplyVec4( &c, &m);

        //Calc Face Normal
        Vec3f na = vec3fsubV(*((Vec3f*)(&a)), *((Vec3f*)(&b)));
        Vec3f nb = vec3fsubV(*((Vec3f*)(&a)), *((Vec3f*)(&c)));
        Vec3f normal = vec3Normalize(vec3Cross(na, nb));
        Vec3f light = vec3Normalize((Vec3f){-8,5,5});
        float diffuseLight = (1.0 + vec3Dot(normal, light)) *0.5;
        diffuseLight = MIN(1.0, MAX(diffuseLight, 0));

        a = mat4MultiplyVec4( &a, &v);
        b = mat4MultiplyVec4( &b, &v);
        c = mat4MultiplyVec4( &c, &v);

        a = mat4MultiplyVec4( &a, &p);
        b = mat4MultiplyVec4( &b, &p);
        c = mat4MultiplyVec4( &c, &p);


        //Triangle is completely behind camera
        if (a.z > 0 && b.z > 0 && c.z > 0)
           continue;

        // convert to device coordinates by perspective division
        a.w = 1.0 / a.w;
        b.w = 1.0 / b.w;
        c.w = 1.0 / c.w;
        a.x *= a.w; a.y *= a.w; a.z *= a.w;
        b.x *= b.w; b.y *= b.w; b.z *= b.w;
        c.x *= c.w; c.y *= c.w; c.z *= c.w;

        float clocking = isClockWise(a.x, a.y, b.x, b.y, c.x, c.y);
        if (clocking >= 0)
            continue;

        //Compute Screen coordinates
        float halfX = scrSize.x/2;
        float halfY = scrSize.y/2;
        Vec2i a_s = {a.x * halfX + halfX,  a.y * halfY + halfY};
        Vec2i b_s = {b.x * halfX + halfX,  b.y * halfY + halfY};
        Vec2i c_s = {c.x * halfX + halfX,  c.y * halfY + halfY};

        int32_t minX = MIN(MIN(a_s.x, b_s.x), c_s.x);
        int32_t minY = MIN(MIN(a_s.y, b_s.y), c_s.y);
        int32_t maxX = MAX(MAX(a_s.x, b_s.x), c_s.x);
        int32_t maxY = MAX(MAX(a_s.y, b_s.y), c_s.y);

        minX = MIN(MAX(minX, 0), r->frameBuffer.size.x);
        minY = MIN(MAX(minY, 0), r->frameBuffer.size.y);
        maxX = MIN(MAX(maxX, 0), r->frameBuffer.size.x);
        maxY = MIN(MAX(maxY, 0), r->frameBuffer.size.y);

        // Barycentric coordinates at minX/minY corner
        Vec2i minTriangle = { minX, minY };

        int32_t area =  orient2d( a_s, b_s, c_s);
        if (area == 0)
            continue;
        float areaInverse = 1.0/area;

        int32_t A01 = ( a_s.y - b_s.y); //Barycentric coordinates steps
        int32_t B01 = ( b_s.x - a_s.x); //Barycentric coordinates steps
        int32_t A12 = ( b_s.y - c_s.y); //Barycentric coordinates steps
        int32_t B12 = ( c_s.x - b_s.x); //Barycentric coordinates steps
        int32_t A20 = ( c_s.y - a_s.y); //Barycentric coordinates steps
        int32_t B20 = ( a_s.x - c_s.x); //Barycentric coordinates steps

        int32_t w0_row = orient2d( b_s, c_s, minTriangle);
        int32_t w1_row = orient2d( c_s, a_s, minTriangle);
        int32_t w2_row = orient2d( a_s, b_s, minTriangle);

        if (o->material != 0) {
            tca.x /= a.z;
            tca.y /= a.z;
            tcb.x /= b.z;
            tcb.y /= b.z;
            tcc.x /= c.z;
            tcc.y /= c.z;
        }

        for (int16_t y = minY; y < maxY; y++, w0_row += B12,w1_row += B20,w2_row += B01) {
            int32_t w0 = w0_row;
            int32_t w1 = w1_row;
            int32_t w2 = w2_row;

            for (int32_t x = minX; x < maxX; x++, w0 += A12, w1 += A20, w2 += A01) {

                if ((w0 | w1 | w2) < 0)
                    continue;

                float depth =  -( w0 * a.z + w1 * b.z + w2 * c.z ) * areaInverse;
                if (depth < 0.0 || depth > 1.0)
                    continue;

                if (depth_check(r->backEnd->getZetaBuffer(r,r->backEnd), x + y * scrSize.x, 1-depth ))
                    continue;

                depth_write(r->backEnd->getZetaBuffer(r,r->backEnd), x + y * scrSize.x, 1- depth );

                if (o->material != 0) {
                    //Texture lookup

                    float textCoordx = -(w0 * tca.x + w1 * tcb.x + w2 * tcc.x)* areaInverse * depth;
                    float textCoordy = -(w0 * tca.y + w1 * tcb.y + w2 * tcc.y)* areaInverse * depth;

                    Pixel text = texture_readF(o->material->texture, (Vec2f){textCoordx,textCoordy});
                    backendDrawPixel(r, &r->frameBuffer, (Vec2i){x,y}, text, diffuseLight);
                } else {
                    backendDrawPixel(r, &r->frameBuffer, (Vec2i){x,y}, pixelFromUInt8(255), diffuseLight);
                }

            }

        }
    }

    return 0;
};

int rendererInit(Renderer * r, Vec2i size, BackEnd * backEnd) {
    renderingFunctions[RENDERABLE_SPRITE] = & renderSprite;
    renderingFunctions[RENDERABLE_SCENE] = & renderScene;
    renderingFunctions[RENDERABLE_OBJECT] = & renderObject;

    r->scene = 0;
    r->clear = 1;
    r->clearColor = PIXELBLACK;
    r->backEnd = backEnd;

    r->backEnd->init(r, r->backEnd, (Vec4i) { 0, 0, 0, 0 });

    int e = 0;
    e = texture_init( & (r->frameBuffer), size, backEnd->getFrameBuffer(r, backEnd));
    if (e) return e;

    return 0;
}



int rendererRender(Renderer * r) {

    int pixels = r->frameBuffer.size.x * r->frameBuffer.size.y;
    memset(r->backEnd->getZetaBuffer(r,r->backEnd), 0, pixels * sizeof (Depth));

    r->backEnd->beforeRender(r, r->backEnd);

    //get current framebuffe from backend
    r->frameBuffer.frameBuffer = r->backEnd->getFrameBuffer(r, r->backEnd);

    //Clear draw buffer before rendering
    if (r->clear) {
        memset(r->backEnd->getFrameBuffer(r,r->backEnd), 0, pixels * sizeof (Pixel));
    }

    renderScene(mat4Identity(), r, sceneAsRenderable(r->scene));

    r->backEnd->afterRender(r, r->backEnd);

    return 0;
}

int rendererSetScene(Renderer * r, Scene * s) {
    if (s == 0)
        return 1; //nullptr scene

    r->scene = s;
    return 0;
}

int rendererSetCamera(Renderer * r, Vec4i rect) {
    r->camera = rect;
    r->backEnd->init(r, r->backEnd, rect);
    r->frameBuffer.size = (Vec2i) {
            rect.z, rect.w
};
    return 0;
}
