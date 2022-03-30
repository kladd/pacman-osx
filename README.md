# Compiling Pacman on macOS 12.3 Monterey

*DISCLAIMER*: This is hardly the shortest path to success. This is just exactly what I did for my first build on Monterey. I plan to clean it up later.

### About Pacman

Pacman is the default package manager for the Arch Linux distribution of Linux.
For more information about using Pacman, visit the
[Arch Linux wiki](https://wiki.archlinux.org/index.php/pacman).

### Dependencies

I've installed everything to `$HOME/pacman-deps`.
```
export PATH=$HOME/pacman-deps/bin:$PATH
```

#### 1. Command line tools
```
xcode-select --install
```

#### 2. bash >= 4.4

macOS 12 appears to ship with bash 3.2---we need at least 4.4. I'm installing 5.1 because it compiled with these flags, and 4.4 didn't.
```
curl -O https://ftp.gnu.org/gnu/bash/bash-5.1.tar.gz
tar -xzvf bash-5.1.tar.gz
cd bash-5.1

./configure --prefix=$HOME/pacman-deps
make install
```

#### 3. pkg-config
```
curl -O https://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz

tar -xzvf pkg-config-0.29.2.tar.gz
cd pkg-config-0.29.2

./configure \
	--disable-debug \
	--prefix=$HOME/env \
	--disable-host-tool \
	--with-internal-glib \
	--with-pc-path=$HOME/env/lib/pkgconfig \
	--with-system-include-path=$HOME/env/usr/include

make
make install
```

#### 4. cmake
```
https://github.com/Kitware/CMake/releases/download/v3.23.0/cmake-3.23.0.tar.gz
tar -xzvf cmake-3.23.0.tar.gz
cd cmake-3.23.0

./bootstrap \
	--prefix=$HOME/env \
	--no-system-libs \
	--parallel=$(sysctl -n hw.physicalcpu) \
	--system-zlib \
	--system-bzip2 \
	--system-curl

make
make install
```

#### 5. libarchive
```
curl -O https://www.libarchive.org/downloads/libarchive-3.6.0.tar.xz
tar -xvf libarchive-3.6.0.tar.xz
./configure --prefix=$HOME/pacman-deps
make && make install
```

#### 6. libcurl
curl exists on mac, but I haven't investigated using it, so I've reinstalled it to the deps path.

For an SSL backend, macOS ships with libressl, I think. That could work, but again I haven't looked into it, so I'm installing openssl. Beware the architecture argument if you are not on an M1 mac. Run configure without the argument and it will spit out the choices. Pick the darwin for your architecture.
```
curl -O https://www.openssl.org/source/openssl-1.1.1n.tar.gz
perl ./Configure --prefix=$HOME/pacman-deps --prefix=$HOME/pacman-deps/etc/openssl darwin64-arm64-cc
make
make install
```

Then install curl.
```
# meta metamates me
curl -O https://curl.se/download/curl-7.82.0.tar.bz2
./configure --prefix=$HOME/pacman-deps --with-openssl=$HOME/pacman-deps/etc/openssl
make
make install

# I accidentally made openssl prefix as /etc/openssl, TODO. workaround:
export PKG_CONFIG_PATH=$HOME/pacman-deps/etc/openssl/lib/pkgconfig:$PKG_CONFIG_PATH
```

### Building pacman

```
git clone https://gitlab.archlinux.org/pacman/pacman.git
cd pacman
git checkout v6.0.1
```

macOS has `sys/statvfs.h`, but `mount.h` expects a `statfs` struct or something. I don't know, I'm not thinking about it right now (TODO). Apply this patch:
```
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
```
meson build \
	--prefix=$HOME/pacman-deps/usr \
	--sysconfdir=$HOME/pacman-deps/etc \
	--localstatedir=$HOME/pacman-deps/var \
	--buildtype=plain \
	-Dscriptlet-shell=$HOME/pacman-deps/bin/bash
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
