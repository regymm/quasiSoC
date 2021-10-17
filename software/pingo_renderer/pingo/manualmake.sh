CC_CFLAGS="riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32"
#CXX_CXXFLAGS=riscv32-unknown-elf-g++ -march=rv32i -mabi=ilp32 

$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o consolebackend.o example/consolebackend.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o cube.o example/cube.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o main.o example/main.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o pingo_mesh.o example/pingo_mesh.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o teapot.o example/teapot.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o viking.o example/viking.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o windowbackend.o example/windowbackend.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o mat3.o math/mat3.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o mat4.o math/mat4.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o vec2.o math/vec2.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o vec3.o math/vec3.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o vec4.o math/vec4.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o depth.o render/depth.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o material.o render/material.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o mesh.o render/mesh.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o object.o render/object.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o pixel.o render/pixel.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o rasterizer.o render/rasterizer.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o renderable.o render/renderable.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o renderer.o render/renderer.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o scene.o render/scene.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o sprite.o render/sprite.c
$CC_CFLAGS -c -pipe -O2 -Wall -Wextra -D_REENTRANT -fPIC -g -I. -o texture.o render/texture.c
#g++ -Wl,-O1 -o Pingo consolebackend.o cube.o main.o pingo_mesh.o teapot.o viking.o windowbackend.o mat3.o mat4.o vec2.o vec3.o vec4.o depth.o material.o mesh.o object.o pixel.o rasterizer.o renderable.o renderer.o scene.o sprite.o texture.o
#g++ -Wl,-O1 -o Pingo consolebackend.o main.o pingo_mesh.o viking.o mat3.o mat4.o vec2.o vec3.o vec4.o depth.o material.o mesh.o object.o pixel.o rasterizer.o renderable.o renderer.o scene.o sprite.o texture.o
