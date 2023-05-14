#include "consolebackend.h"
/*#include "windows.h"*/

#include "../render/renderer.h"
#include "../render/texture.h"
#include "../render/pixel.h"
#include "../render/depth.h"


Vec2i totalSize;
Depth * zetaBuffer;
Pixel * frameBuffer;

void console_backend_init_backend( Renderer * ren, BackEnd * backEnd, Vec4i _rect) {
    //Save the rect so the windows drawing code knows whhere and how to copy the rendered buffer on the window
}

void console_backend_beforeRender( Renderer * ren, BackEnd * backEnd) {
	printf("\033[2J");
}
//HANDLE hConsole_c;

extern volatile int* video_base;

void console_backend_afterRender( Renderer * ren,  BackEnd * backEnd) {
    /*#define charSize 13*/
    /*const char scale[charSize] = " .:-i|=+*%#O@";*/
    /*for (int y = 0; y < totalSize.y; y++ ) {*/
        /*char chars[totalSize.x];*/
        /*for (int x = 0; x < totalSize.x; x++ ) {*/
			/*int index = charSize * (pixelToUInt8(&frameBuffer[x + y * totalSize.x]) / 256.0);*/
			/*chars[x] = scale[index];*/
			/*printf("%c", chars[x]);*/
        /*}*/
		/*printf("\n\r");*/
    /*}*/
	for (int y = 0; y < totalSize.y; y++) {
		for (int x = 0; x < totalSize.x; x+=4) {
			Pixel* pix1 = &frameBuffer[x + y * totalSize.x];
			Pixel* pix2 = &frameBuffer[x+1 + y * totalSize.x];
			Pixel* pix3 = &frameBuffer[x+2 + y * totalSize.x];
			Pixel* pix4 = &frameBuffer[x+3 + y * totalSize.x];
			if (y < 240 && x < 320) {
				video_base[(y+60)*80 + (x+80)/4] = (pix1->g) + (pix2->g<<8) + (pix3->g<<16) + (pix4->g<<24);
				/*video_base[y*80 + x/4] = (pix2->g<<8) + (pix3->g<<16) + (pix4->g<<24);*/
				/*video_base[y*80 + x/4] = (pix1->g);*/
			}

		}
	}
}

Pixel * console_backend_getFrameBuffer( Renderer * ren,  BackEnd * backEnd) {
    return frameBuffer;
}

Depth * console_backend_getZetaBuffer( Renderer * ren,  BackEnd * backEnd) {
    return zetaBuffer;
}

void console_backend_init(ConsoleBackend *this, Vec2i size, void* memchunk)
{
    totalSize = size;
    this->backend.init = &console_backend_init_backend;
    this->backend.beforeRender = &console_backend_beforeRender;
    this->backend.afterRender = &console_backend_afterRender;
    this->backend.getFrameBuffer = &console_backend_getFrameBuffer;
    this->backend.getZetaBuffer = &console_backend_getZetaBuffer;
    this->backend.drawPixel = 0;

	/*zetaBuffer = malloc(size.x*size.y*sizeof (Depth));*/
	/*frameBuffer = malloc(size.x*size.y*sizeof (Pixel));*/
	zetaBuffer = (Depth*)(memchunk);
	frameBuffer = (Pixel*)(memchunk + size.x*size.y*(sizeof(Depth) + 1));
	printf("%d, %d\n", sizeof(Depth), sizeof(Pixel));
}
