# Compiling Pacman on macOS 12.3 Monterey

*DISCLAIMER*: This is hardly the shortest path to success. This is just exactly what I did for my first build on Monterey. I plan to clean it up later.

### About Pacman

Pacman is the default package manager for the Arch Linux distribution of Linux.
For more information about using Pacman, visit the
[Arch Linux wiki](https://wiki.archlinux.org/index.php/pacman).

### Dependencies

I've installed everything to `$HOME/pacman-deps`.
```sh
export PATH=$HOME/pacman-deps/bin:$PATH

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

cd bash-5.1

./configure --prefix=$HOME/pacman-deps
make install

```

#### 3. pkg-config
```sh
curl -O https://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
tar -xzvf pkg-config-0.29.2.tar.gz

cd pkg-config-0.29.2

./configure --disable-debug --prefix=$HOME/pacman-deps --with-internal-glib
make
make install

```


#### 4. libarchive

libarchive is included in macOS but I haven't looked into using it. Here it's compiled from source.

```sh
curl -O https://www.libarchive.org/downloads/libarchive-3.6.0.tar.xz
tar -xvf libarchive-3.6.0.tar.xz

cd libarchive-3.6.0

./configure --prefix=$HOME/pacman-deps
make && make install

```

#### 5. openssl
```sh
curl -O https://www.openssl.org/source/openssl-1.1.1n.tar.gz
tar xzvf openssl-1.1.1n.tar.gz

cd openssl-1.1.1n

perl ./Configure --prefix=$HOME/pacman-deps darwin64-arm64-cc
make
make install

```

#### 6. meson and ninja

Pacman uses meson and ninja build systems now...ok. Install them.

```sh
python3 -m pip install meson
python3 -m pip install ninja

```

The pip install bin directory is not on the `PATH` by default, but the location is python version dependant. `python3 --version` will give you a semver number, but the path uses only the major and minor versi...anyway, this path might not exist if your python version is different, but add `meson` to your `PATH`, or otherwise find out where it is.

```sh
export PATH=$HOME/Library/Python/3.8/bin:$PATH

```

### Building pacman

```sh
git clone https://gitlab.archlinux.org/pacman/pacman.git
cd pacman
git checkout v6.0.1

```

macOS has `sys/statvfs.h`, but `mount.h` expects a `statfs` struct or something. I don't know, but I'm not thinking about it right now (TODO). Apply this patch:
```sh
{ cat <<EOF
diff --git a/meson.build b/meson.build
index 76b9d2aa..e85908ea 100644
--- a/meson.build
+++ b/meson.build
@@ -125,7 +125,6 @@ foreach header : [
     'sys/mnttab.h',
     'sys/mount.h',
     'sys/param.h',
-    'sys/statvfs.h',
     'sys/types.h',
     'sys/ucred.h',
     'termios.h',
@@ -152,7 +151,6 @@ endforeach

 foreach member : [
     ['struct stat', 'st_blksize', '''#include <sys/stat.h>'''],
-    ['struct statvfs', 'f_flag', '''#include <sys/statvfs.h>'''],
     ['struct statfs', 'f_flags', '''#include <sys/param.h>
                                     #include <sys/mount.h>'''],
   ]
EOF
} | git apply -

```

Build and install.
```sh
# TODO: Disabled i18n to avoid library dependency,
meson build \
	--prefix=$HOME/pacman-deps \
	--sysconfdir=$HOME/pacman-deps/etc \
	--localstatedir=$HOME/pacman-deps/var \
	--buildtype=plain \
	-Di18n=false -Dscriptlet-shell=$HOME/pacman-deps/bin/bash
meson compile -C build
meson install -C build

```

#### 3. Prosper
```
kladd@kvm pacman % $HOME/pacman-deps/usr/bin/pacman --version

 .--.                  Pacman v6.0.1 - libalpm v13.0.1
/ _.-' .-.  .-.  .-.   Copyright (C) 2006-2021 Pacman Development Team
\  '-. '-'  '-'  '-'   Copyright (C) 2002-2006 Judd Vinet
 '--'
                       This program may be freely redistributed under
                       the terms of the GNU General Public License.
```

I haven't verified that this installation does anything more than print its own version, but it's a start.
