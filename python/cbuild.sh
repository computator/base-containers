#!/bin/sh
set -e

. ${UTILSDIR:=../cbutils/src}/umoci.lib.sh
. ${UTILSDIR:=../cbutils/src}/runc.lib.sh

u_set_loglevel $U_LOG_INFO
u_set_autoclean

# create image
img=$(u_clone_image "ubuntu")
base=$(u_clone_ref "$img" latest)
u_remove_refs_except "$img" "$base"

# python 2
py2=$(u_clone_ref "$base")

layer=$(u_open_layer "$py2")
u_run "$layer" -- sh -c 'apt-get update && apt-get -y install python'
py2_ver=$(u_run "$layer" -- python -V 2>&1 | cut -f 2 -d ' ')
u_close_layer "$layer" "$py2" --mask-path /var/lib/apt/lists/

u_config "$py2" --config.cmd /usr/bin/python

u_write_ref "$py2" "$py2_ver"
# gets version in x.y form
u_write_ref "$py2" "${py2_ver%.${py2_ver#*.*.}}"
u_write_ref "$py2" 2
u_remove_ref "$py2"

# python 3
py3=$(u_clone_ref "$base")

layer=$(u_open_layer "$py3")
u_run "$layer" -- sh -c 'apt-get update && apt-get -y install python3'
py3_ver=$(u_run "$layer" -- python3 -V 2>&1 | cut -f 2 -d ' ')
u_close_layer "$layer" "$py3" --mask-path /var/lib/apt/lists/

u_config "$py3" --config.cmd /usr/bin/python3

u_write_ref "$py3" "$py3_ver"
# gets version in x.y form
u_write_ref "$py3" "${py3_ver%.${py3_ver#*.*.}}"
u_write_ref "$py3" 3
u_write_ref "$py3" latest
u_remove_ref "$py3"

# cleanup
u_remove_ref "$base"

# save iamge
img=$(u_set_image_name "$img" "python")
u_clean_image "$img"
u_serialize_image "$img" "python-all" > /dev/null