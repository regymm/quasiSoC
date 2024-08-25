#!/bin/bash -ex
if [[ $(uname -m) == "aarch64"  ]]; then
	append="-arm"
else
	append=""
fi

cd ../../..
docker run --pull never -it --rm -m 8G \
	-v `pwd`:/mnt \
	-v /chipdb:/chipdb \
	--tmpfs /tmp \
	regymm/openxc7${append} make -C /mnt/rtl/board-specific/a7-lite-openxc7 -f Makefile.openxc7.caas
