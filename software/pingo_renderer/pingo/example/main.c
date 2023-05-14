/*#include "windowbackend.h"*/
#include "consolebackend.h"
#include "teapot.h"
#include "cube.h"
#include "pingo_mesh.h"
#include "viking.h"
#include "../render/renderer.h"
#include "../render/texture.h"
#include "../render/sprite.h"
#include "../render/scene.h"
#include "../render/object.h"
#include "../render/mesh.h"
#include "../math/mat3.h"

#include "../render/pixel.h"
#include "../render/depth.h"

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

void* MemChunk;

Pixel * loadTexture(char * filename, Vec2i size) {
    //Load from filesystem from a RAW RGBA file
    /*Pixel * image = malloc(size.x*size.y*100);*/
	Pixel* image = (Pixel*)(MemChunk + size.x*size.y*(sizeof(Depth)+sizeof(Pixel) + 2));
    /*FILE * file   = fopen(filename, "rb");*/
    for (int i = size.y-1; i > 0; i--) {
    for (int j = 0; j < size.x; j++) {
            /*fread(&image[i*1024 + j].r, 1, 1, file);*/
            /*fread(&image[i*1024 + j].g, 1, 1, file);*/
            /*fread(&image[i*1024 + j].b, 1, 1, file);*/
            /*fread(&image[i*1024 + j].a, 1, 1, file);*/
			/*image[i*1024 + j].r = 255;*/
			image[i*size.x + j].g = 255;
			/*image[i*1024 + j].b = 255;*/
			/*image[i*1024 + j].a = 255;*/
        }
    }
    /*fclose(file);*/
    return image;
}

int sftrdr_main(int id){
    /*Vec2i size = {1280, 800};*/
    Vec2i size = {160, 120};

	/*MemChunk = malloc(256*256 * (sizeof(Depth) + sizeof(Pixel) + 1));*/
	MemChunk = (void *)0x20200000;
	int i;
	for(i = 0; i < 0x200000 / 4; i++)
		*(int *)(MemChunk + i) = 0xffffffff;


    /*WindowBackEnd backend;*/
    /*windowBackEndInit(&backend, size);*/
	ConsoleBackend backend;
	console_backend_init(&backend, size, MemChunk);

    Renderer renderer;
    rendererInit(&renderer, size,(BackEnd*) &backend );

    Scene s;
    sceneInit(&s);
    rendererSetScene(&renderer, &s);

    Object viking_room;

	// a basic selection
	viking_room.mesh = id == 0 ? &viking_mesh : id == 1 ? &mesh_teapot : &mesh_cube;

    sceneAddRenderable(&s, object_as_renderable(&viking_room));
    viking_room.material = 0;

    Pixel * image = loadTexture("dummy", (Vec2i){128, 128});

    Texture tex;
    texture_init(&tex, (Vec2i){128, 128},image);

    Material m;
    m.texture = &tex;
    viking_room.material = &m;

    float phi = 0;
    Mat4 t;

	printf("\033[?25l");
    while (1) {
		/*printf("frame\n");*/
        // PROJECTION MATRIX - Defines the type of projection used
        renderer.camera_projection = mat4Perspective( 1, 250.0,(float)size.x / (float)size.y, 70.0);

        //VIEW MATRIX - Defines position and orientation of the "camera"
        Mat4 v = mat4Translate((Vec3f) { 0,0.7,-7});
        Mat4 rotateDown = mat4RotateX(-0.40); //Rotate around origin/orbit
        renderer.camera_view = mat4MultiplyM(&rotateDown, &v );

        //TEA TRANSFORM - Defines position and orientation of the object
        viking_room.transform = mat4RotateZ(3.142128);
        t = mat4Scale(id == 0 ? (Vec3f){0.2,0.2,0.2} : (Vec3f){1.2, 1.2, 1.2});
        viking_room.transform = mat4MultiplyM(&viking_room.transform, &t );
        t = mat4Translate((Vec3f){0,0,0});
        viking_room.transform = mat4MultiplyM(&viking_room.transform, &t );
        t = mat4RotateZ(0);
        viking_room.transform = mat4MultiplyM(&viking_room.transform, &t );

        //SCENE
        /*s.transform = mat4RotateY(cos(phi -= 0.05)+0.64);*/
		s.transform = mat4RotateY(cos(phi -= (id == 0 ? 0.5 : 0.2))+0.64);

        rendererSetCamera(&renderer,(Vec4i){0,0,size.x,size.y});
		rendererRender(&renderer);
		/*usleep(50000);*/

    }

    return 0;
}

