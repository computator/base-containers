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

u_run "$layer" -- sh -c 'apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install nginx'
nginx_ver=$(expr match "$(u_run "$layer" -- nginx -v 2>&1)" '.*nginx/\([^ ]\+\)')
u_log_eval ln -sf /dev/stdout $(u_layer_path "$layer" "/var/log/nginx/access.log")
u_log_eval ln -sf /dev/stderr $(u_layer_path "$layer" "/var/log/nginx/error.log")

u_close_layer "$layer" "$work" --mask-path /var/lib/apt/lists/

u_config "$work" \
	--config.cmd /usr/sbin/nginx --config.cmd -g --config.cmd 'daemon off;' \
	--config.exposedports 80

u_write_ref "$work" "$nginx_ver"
u_write_ref "$work" latest

u_remove_ref "$work"

# save iamge
img=$(u_set_image_name "$img" "nginx")
u_clean_image "$img"
u_serialize_image "$img" "nginx-${nginx_ver}" > /dev/null