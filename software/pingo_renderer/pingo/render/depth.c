#include "depth.h"

#ifdef ZBUFFER32
void depth_write (Depth * d, int idx, float value) {
    d[idx].d = (uint32_t)(value * (float)UINT32_MAX);
}

bool depth_check(Depth * d, int idx, float value){
    return (uint32_t)(value * (float)UINT32_MAX) < d[idx].d;
}
#endif

#ifdef ZBUFFER16
void depth_write (Depth * d, int idx, float value) {
    d[idx].d = (uint16_t)(value * UINT16_MAX);
}

bool depth_check(Depth * d, int idx, float value){
    return (uint16_t)(value * UINT16_MAX) < d[idx].d;
}
#endif

#ifdef ZBUFFER8
void depth_write (Depth * d, int idx, float value) {
    d[idx].d = (uint8_t)(value * UINT8_MAX);
}

bool depth_check(Depth * d, int idx, float value){
    return (uint8_t)(value * UINT8_MAX) > d[idx].d;
}
#endif

