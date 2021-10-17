#include "object.h"


Renderable object_as_renderable(Object * object)
{
    return (Renderable){.renderableType = RENDERABLE_OBJECT, .impl = object};
}

