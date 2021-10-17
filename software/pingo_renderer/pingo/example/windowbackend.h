/**
 * @file: windowbackend.h
 * @author Federico Devigili - Alpitronic
 *
 * @section LICENSE
 * <LICENSE_REPLACE>
 *
 * @section DESCRIPTION
 * A backend for the renderer which creates a Window windows and renders in it
 *
 */
#ifdef WIN32
#pragma once

struct Renderer;

#include "../render/backend.h"
#include "../math/vec2.h"

typedef struct Pixel Pixel;

/**
 * @brief Struct extending BackEnd interface for rendering on Win32
 */
typedef  struct {
    BackEnd backend;
    Vec2i size;
} WindowBackEnd;

/**
 * @brief Initialize a debug overlay over a Windows window, used as emulator of the hardware.
 * @param Pointer to the WindowBackEnd structure to initialize
 * @param Position of the overlay
 * @param Size of the overlay
 */
void windowBackEndInit(WindowBackEnd * thiss, Vec2i size);

#endif
