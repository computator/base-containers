#!/bin/sh
set -e

ctr=$(buildah from ubuntu)

buildah run $ctr sh -c '
	export DEBIAN_FRONTEND=noninteractive
	dpkg --add-architecture i386 && \
	apt-get update && \
	apt-get -y install wine-stable'

wine_ver=$(expr match "$(buildah run $ctr wine --version)" 'wine-\([^ ]\+\)')

buildah run $ctr sh -c "[ -d /var/lib/apt/lists ] && rm -rf /var/lib/apt/lists/*"

img=$(buildah commit --rm $ctr wine)
buildah tag $img wine:"$wine_ver"