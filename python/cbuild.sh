#!/bin/sh
set -e

# python 2
py2=$(buildah from ubuntu)

buildah run $py2 sh -c 'apt-get update && apt-get -y install python'
py2_ver=$(buildah run $py2 python -V 2>&1 | cut -f 2 -d ' ')

buildah run $py2 sh -c "[ -d /var/lib/apt/lists ] && rm -rf /var/lib/apt/lists/*"

buildah config --cmd /usr/bin/python $py2

img=$(buildah commit --rm $py2 python:"$py2_ver")
# gets version in x.y form
buildah tag $img python:"${py2_ver%.${py2_ver#*.*.}}"
buildah tag $img python:2

# python 3
py3=$(buildah from ubuntu)

buildah run $py3 sh -c 'apt-get update && apt-get -y install python3'
py3_ver=$(buildah run $py3 python3 -V 2>&1 | cut -f 2 -d ' ')

buildah run $py3 sh -c "[ -d /var/lib/apt/lists ] && rm -rf /var/lib/apt/lists/*"

buildah config --cmd /usr/bin/python3 $py3

img=$(buildah commit --rm $py3 python)
buildah tag $img python:"$py3_ver"
# gets version in x.y form
buildah tag $img python:"${py3_ver%.${py3_ver#*.*.}}"
buildah tag $img python:3