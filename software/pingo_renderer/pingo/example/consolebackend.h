#pragma once

#include "../render/backend.h"
#include "../math/vec2.h"

typedef  struct ConsoleBackend {
    BackEnd backend;
} ConsoleBackend;

void console_backend_init(ConsoleBackend * t, Vec2i size, void* memchunk);
