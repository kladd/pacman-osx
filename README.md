# Compiling Pacman on macOS 13.0 Ventura

*DISCLAIMER*: This is hardly the shortest path to success. This is just what I did to use pacman on Ventura.

### About Pacman

Pacman is the default package manager for the Arch Linux distribution of Linux.
For more information about using Pacman, visit the
[Arch Linux wiki](https://wiki.archlinux.org/index.php/pacman).

### Dependencies

I've installed everything to `/opt/pacman`.

```sh
sudo mkdir /opt/pacman && sudo chown $USER:staff /opt/pacman

```

```sh
export BOOTSTRAP=/opt/pacman
export PATH=$BOOTSTRAP/bin:$PATH

```

#### 1. Command line tools
```sh
xcode-select --install

```

#### 2. bash >= 4.4

macOS 12 appears to ship with bash 3.2—pacman requests at least 4.4. I'm installing 5.1 because it compiled with these flags, and 4.4 didn't.
```sh
curl -O https://ftp.gnu.org/gnu/bash/bash-5.1.tar.gz
tar -xzvf bash-5.1.tar.gz

pushd bash-5.1

./configure --prefix=$BOOTSTRAP
make install

popd

```

#### 3. pkg-config
```sh
curl -O https://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
tar -xzvf pkg-config-0.29.2.tar.gz

pushd pkg-config-0.29.2

./configure --disable-debug --prefix=$BOOTSTRAP --with-internal-glib
make
make install

popd

```


#### 4. libarchive

libarchive is included in macOS but I haven't looked into using it. Here it's compiled from source.

```sh
curl -O https://www.libarchive.org/downloads/libarchive-3.6.0.tar.xz
tar -xvf libarchive-3.6.0.tar.xz

pushd libarchive-3.6.0

./configure --prefix=$BOOTSTRAP
make && make install

popd

```

#### 5. openssl
```sh
curl -O https://www.openssl.org/source/openssl-1.1.1n.tar.gz
tar xzvf openssl-1.1.1n.tar.gz

pushd openssl-1.1.1n

perl ./Configure --prefix=$BOOTSTRAP darwin64-arm64-cc
make
make install

popd

```

#### 6. meson and ninja

Pacman uses meson and ninja build systems now...ok. Install them.

```sh
python3 -m pip install meson
python3 -m pip install ninja

```

The pip install bin directory is not on the `PATH` by default, but the location is python version dependant. `python3 --version` will give you a semver number, but the path uses only the major and minor versi...anyway, this path might not exist if your python version is different, but add `meson` to your `PATH`, or otherwise find out where it is.

```sh
export PATH=$HOME/Library/Python/3.9/bin:$PATH

```

### Building pacman

```sh
git clone https://gitlab.archlinux.org/pacman/pacman.git
pushd pacman
git checkout v6.0.1

```


#### HACKS

This patch does a few things:
* replaces some GNU util arguments with BSD equivalents e.g. touch, date, etc.
* disables pacman sudo requirement
* does not build in fakeroot

```sh
curl -LO https://raw.githubusercontent.com/kladd/pacman-osx/macOS-13.0/pacman.patch
git apply pacman.patch

```

Build and install.
```sh
export PKG_CONFIG_PATH=$BOOTSTRAP/lib/pkgconfig:$PKG_CONFIG_PATH

# TODO: Disabled i18n to avoid library dependency,
meson build \
	--prefix=$BOOTSTRAP \
	--sysconfdir=$BOOTSTRAP/etc \
	--localstatedir=$BOOTSTRAP/var \
	--buildtype=plain \
	-Di18n=false -Dscriptlet-shell=$BOOTSTRAP/bin/bash
meson compile -C build
meson install -C build

```

```
kladd@kvm pacman % $BOOTSTRAP/usr/bin/pacman --version

 .--.                  Pacman v6.0.1 - libalpm v13.0.1
/ _.-' .-.  .-.  .-.   Copyright (C) 2006-2021 Pacman Development Team
\  '-. '-'  '-'  '-'   Copyright (C) 2002-2006 Judd Vinet
 '--'
                       This program may be freely redistributed under
                       the terms of the GNU General Public License.
```


