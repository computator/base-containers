#!/bin/sh
set -e

ctr=$(buildah from ubuntu)

buildah run $ctr sh -c 'apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install php-fpm'

php_ver=$(buildah run $ctr php -v 2>&1 head -n 1 | cut -f 2 -d ' ')
# strip suffix
php_ver="${php_ver%-*}"
# gets version in x.y form
php_ver_s="${php_ver%.${php_ver#*.*.}}"

buildah run $ctr sh -c "$(cat <<E_LOG_EXEC
cat > /etc/php/${php_ver_s}/fpm/php-fpm.conf <<-EOF
	[global]
	error_log = /proc/self/fd/2

	[www]
	user = www-data
	group = www-data

	listen = 9000

	pm = dynamic
	pm.max_children = 5
	pm.start_servers = 2
	pm.min_spare_servers = 1
	pm.max_spare_servers = 3

	pm.status_path = /status
	ping.path = /ping
EOF
E_LOG_EXEC
)"

buildah run $ctr sh -c "[ -d /var/lib/apt/lists ] && rm -rf /var/lib/apt/lists/*"

buildah config --cmd "" --entrypoint '["/usr/bin/php"]' $ctr

img=$(buildah commit $ctr php)
buildah tag $img php:"$php_ver"
buildah tag $img php:"$php_ver_s"
buildah tag $img php:7

# fpm
buildah config \
	--entrypoint "[\"/usr/sbin/php-fpm${php_ver_s}\", \"--nodaemonize\"]" \
	--port 9000 \
	$ctr

img=$(buildah commit --rm $ctr php:fpm)
buildah tag $img php:"fpm-$php_ver"
buildah tag $img php:"fpm-$php_ver_s"
buildah tag $img php:fpm-7