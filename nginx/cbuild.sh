#!/bin/sh
set -e

ctr=$(buildah from ubuntu)

buildah run $ctr sh -c 'apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install nginx'

nginx_ver=$(expr match "$(buildah run $ctr nginx -v 2>&1)" '.*nginx/\([^ ]\+\)')

buildah run $ctr ln -sf /dev/stdout /var/log/nginx/access.log
buildah run $ctr ln -sf /dev/stderr /var/log/nginx/error.log

buildah run $ctr sh -c "[ -d /var/lib/apt/lists ] && rm -rf /var/lib/apt/lists/*"

buildah config \
	--cmd "/usr/sbin/nginx -g 'daemon off;'" \
	--port 80 \
	$ctr

img=$(buildah commit --rm $ctr nginx)
buildah tag $img nginx:"$nginx_ver"