#!/usr/bin/env bash
#
# Compiling Pacman on OS X 10.10 Yosemite
#
# Kyle Ladd <kyle@laddk.com>
# 2014-08-01 02:06:22
#
# install.sh
#

PACMANPREFIX=/usr/local

function in_parallel()
{
	declare -a args=("${!1}")

	for ((i = 0; i < ${#args[@]}; i++)); do
		eval "${args[$i]}" &
	done

	wait
}

function main()
{
	local tmpdir=$(mktemp -d /tmp/tmp.XXXXXX)
	pushd $tmpdir

	local gettext=$(cat <<EOF
PATH=$tmpdir/bin:$PATH
curl -O https://ftp.gnu.org/gnu/gettext/gettext-0.19.2.tar.xz

tar -xJvf gettext-0.19.2.tar.xz
cd gettext-0.19.2

./configure --prefix=$tmpdir
make
make install
EOF
	)

	local automake=$(cat <<EOF
PATH=$tmpdir/bin:$PATH
curl -O http://ftp.gnu.org/gnu/automake/automake-1.14.1.tar.gz

tar -xzvf automake-1.14.1.tar.gz
cd automake-1.14.1

./configure --prefix=$tmpdir
make
make install
EOF
	)

	local autoconf=$(cat <<EOF
PATH=$tmpdir/bin:$PATH
curl -O http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz

tar -xzvf autoconf-2.69.tar.gz
cd autoconf-2.69

./configure --prefix=$tmpdir
make
make install
EOF
	)

	local pkg_config=$(cat <<EOF
PATH=$tmpdir/bin:$PATH
http://pkgconfig.freedesktop.org/releases/pkg-config-0.28.tar.gz

tar -xzvf pkg-config-0.28.tar.gz
cd pkg-config-0.28

./configure --prefix=$tmpdir
make
make install
EOF
	)

	local libtool=$(cat <<EOF
PATH=$tmpdir/bin:$PATH
curl -O http://ftp.gnu.org/gnu/libtool/libtool-2.4.2.tar.gz

tar -xzvf libtool-2.4.2.tar.gz
cd libtool-2.4.2

./configure --prefix=$tmpdir
make
make install
EOF
	)

	local bash=$(cat <<EOF
PATH=$tmpdir/bin:$PATH
curl -O http://ftp.gnu.org/gnu/bash/bash-4.3.tar.gz

tar -xzvf bash-4.3.tar.gz
cd bash-4.3

./configure --prefix=$tmpdir
make
make install
EOF
	)

	local libarchive=$(cat <<EOF
PATH=$tmpdir/bin:$PATH
curl -LO https://github.com/libarchive/libarchive/archive/v2.8.3.tar.gz
tar -xzvf v2.8.3.tar.gz
cd libarchive-2.8.3

./build/autogen.sh
./configure --prefix=$tmpdir
make
make install
EOF
	)

	local asciidoc=$(cat <<EOF
PATH=$tmpdir/bin:$PATH
curl -LO http://downloads.sourceforge.net/project/asciidoc/asciidoc/8.6.9/asciidoc-8.6.9.tar.gz

tar -xzvf asciidoc-8.6.9.tar.gz
cd asciidoc-8.6.8

./configure --prefix=$tmpdir
make
make install
EOF
	)

	local fetch_pacman=$(cat <<EOF
git clone git://projects.archlinux.org/pacman.git
EOF
	)

	install_round_1=(
		"$gettext"
		"$automake"
		"$autoconf"
		"$fetch_pacman"
	)
	install_round_2=(
		"$pkg_config"
		"$libtool"
		"$bash"
		"$libarchive"
		"$asciidoc"
	)
	
	# These hopefully are all independent of each other and everything in round 2
	in_parallel install_round_1[@]

	# These may or may not depend on something in round 1
	in_parallel install_round_2[@]

	# compile Pacman
	cd pacman
	PATH=$tmpdir/bin:$PATH
	LIBARCHIVE_CFLAGS="-I$tmpdir/include"
	LIBARCHIVE_LIBS="-larchive"
	LIBCURL_CFLAGS="-I/usr/include/curl"
	LIBCURL_LIBS="-lcurl"

	./autogen.sh
	./configure --prefix=$PACMANPREFIX \
		--enable-doc \
		--with-scriptlet-shell=$tmpdir/bin/bash \
		--with-curl
	make
	make -C contrib
	make install
	make -C contrib install

	popd
}

echo "This is going to look really ugly..."
main
PATH=$PACMANPREFIX/bin:$PATH pacman --version

