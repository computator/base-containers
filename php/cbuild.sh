#!/bin/sh
set -e

. ${UTILSDIR:=../cbutils/src}/umoci.lib.sh
. ${UTILSDIR:=../cbutils/src}/runc.lib.sh

u_set_loglevel $U_LOG_INFO
u_set_autoclean

# create image
img=$(u_clone_image "ubuntu")
work=$(u_clone_ref "$img" latest)
u_remove_refs_except "$img" "$work"

layer=$(u_open_layer "$work")

u_run "$layer" -- sh -c 'apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install php-fpm'

php_ver=$(u_run "$layer" -- php -v 2>&1 head -n 1 | cut -f 2 -d ' ')
# strip suffix
php_ver="${php_ver%-*}"
# gets version in x.y form
php_ver_s="${php_ver%.${php_ver#*.*.}}"

u_log_eval "$(cat <<E_LOG_EXEC
cat > $(u_layer_path "$layer" "/etc/php/${php_ver_s}/fpm/php-fpm.conf") <<-EOF
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

u_close_layer "$layer" "$work" --mask-path /var/lib/apt/lists/

u_config "$work" --clear config.cmd --config.entrypoint /usr/bin/php

u_write_ref "$work" "$php_ver"
u_write_ref "$work" "$php_ver_s"
u_write_ref "$work" 7
u_write_ref "$work" latest

# fpm
u_config "$work" \
	--config.entrypoint "/usr/sbin/php-fpm${php_ver_s}" --config.entrypoint --nodaemonize \
	--config.exposedports 9000
u_write_ref "$work" "fpm-$php_ver"
u_write_ref "$work" "fpm-$php_ver_s"
u_write_ref "$work" fpm-7
u_write_ref "$work" fpm

u_remove_ref "$work"

# save iamge
img=$(u_set_image_name "$img" "php")
u_clean_image "$img"
u_serialize_image "$img" "php-${php_ver}" > /dev/null