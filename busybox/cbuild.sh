#!/bin/sh
set -e

. ${UTILSDIR:=../cbutils/src}/umoci.lib.sh

u_set_loglevel $U_LOG_INFO
u_set_autoclean

img=$(u_create_image)
work=$(u_create_ref "$img")

layer=$(u_open_layer "$work")

u_log_eval mkdir -p $(u_layer_path "$layer" "/bin")
u_log_eval cp $(which busybox) $(u_layer_path "$layer" "/bin/busybox")
u_log_eval ln -s busybox $(u_layer_path "$layer" "/bin/sh")
bb_ver=$($(u_layer_path "$layer" "/bin/busybox") | head -n 1 | cut -f 2 -d ' ')

u_close_layer "$layer" "$work"

u_config "$work" --config.cmd /bin/sh

u_write_ref "$work" "$bb_ver"
u_write_ref "$work" latest
u_remove_ref "$work"

img=$(u_set_image_name "$img" "busybox")
u_clean_image "$img"
u_serialize_image "$img" "busybox-${bb_ver}" > /dev/null