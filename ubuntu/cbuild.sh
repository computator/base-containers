#!/bin/sh
set -e

ctr=$(buildah from scratch)

tmpfile=$(mktemp -u).tar.gz
wget -nv --show-progress -O "$tmpfile" "https://partner-images.canonical.com/core/bionic/current/ubuntu-bionic-core-cloudimg-amd64-root.tar.gz"
buildah add --quiet $ctr "$tmpfile"
rm -f "$tmpfile"
tmpfile=

# https://github.com/docker/docker/blob/9a9fc01af8fb5d98b8eec0740716226fadb3735c/contrib/mkimage/debootstrap#L40-L48
buildah run $ctr sh -c "$(cat <<E_LOG_EXEC
cat > /usr/sbin/policy-rc.d <<-EOF
	#!/bin/sh
	exit 101
EOF
chmod +x /usr/sbin/policy-rc.d
E_LOG_EXEC
)"

# https://github.com/docker/docker/blob/9a9fc01af8fb5d98b8eec0740716226fadb3735c/contrib/mkimage/debootstrap#L54-L56
buildah run $ctr sh -c "$(cat <<E_LOG_EXEC
dpkg-divert --local --rename --add /sbin/initctl
cat > /sbin/initctl <<-EOF
	#!/bin/sh
	exit 0
EOF
chmod +x /sbin/initctl
E_LOG_EXEC
)"

# https://github.com/docker/docker/blob/9a9fc01af8fb5d98b8eec0740716226fadb3735c/contrib/mkimage/debootstrap#L71-L78
buildah run $ctr sh -c "echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/container-apt-speedup"

# https://github.com/docker/docker/blob/9a9fc01af8fb5d98b8eec0740716226fadb3735c/contrib/mkimage/debootstrap#L85-L105
buildah run $ctr sh -c "$(cat <<E_LOG_EXEC
cat > /etc/apt/apt.conf.d/container-clean <<-EOF
	DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };
	APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };
	Dir::Cache::pkgcache "";
	Dir::Cache::srcpkgcache "";
EOF
E_LOG_EXEC
)"

# https://github.com/docker/docker/blob/9a9fc01af8fb5d98b8eec0740716226fadb3735c/contrib/mkimage/debootstrap#L109-L115
buildah run $ctr sh -c "echo 'Acquire::Languages \"none\";' > /etc/apt/apt.conf.d/container-no-languages"

# https://github.com/docker/docker/blob/9a9fc01af8fb5d98b8eec0740716226fadb3735c/contrib/mkimage/debootstrap#L118-L130
buildah run $ctr sh -c "echo 'Acquire::GzipIndexes \"true\"; Acquire::CompressionTypes::Order:: \"gz\";' > /etc/apt/apt.conf.d/container-gzip-indexes"

# https://github.com/docker/docker/blob/9a9fc01af8fb5d98b8eec0740716226fadb3735c/contrib/mkimage/debootstrap#L134-L151
buildah run $ctr sh -c "echo 'Apt::AutoRemove::SuggestsImportant \"false\";' > /etc/apt/apt.conf.d/container-autoremove-suggests"

buildah run $ctr sh -c "[ -d /var/lib/apt/lists ] && rm -rf /var/lib/apt/lists/*"

buildah run $ctr sh -c "sed -i 's/^#\s*\(deb.*universe\)$/\1/g' /etc/apt/sources.list"

buildah config --cmd /bin/bash $ctr

img=$(buildah commit --rm $ctr ubuntu)
buildah tag $img ubuntu:bionic
buildah tag $img ubuntu:18.04