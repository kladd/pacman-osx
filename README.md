# Compiling Pacman on macOS 12.3 Monterey

*DISCLAIMER*: This is hardly the shortest path to success. This is just exactly what I did for my first build on Monterey. I plan to clean it up later.

### About Pacman

Pacman is the default package manager for the Arch Linux distribution of Linux.
For more information about using Pacman, visit the
[Arch Linux wiki](https://wiki.archlinux.org/index.php/pacman).

### Dependencies

I've installed everything to `$HOME/.bootstrap-pacman`.
```sh
export BOOTSTRAP=$HOME/.bootstrap-pacman
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

cd bash-5.1

./configure --prefix=$BOOTSTRAP
make install

```

#### 3. pkg-config
```sh
curl -O https://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
tar -xzvf pkg-config-0.29.2.tar.gz

cd pkg-config-0.29.2

./configure --disable-debug --prefix=$BOOTSTRAP --with-internal-glib
make
make install

```


#### 4. libarchive

libarchive is included in macOS but I haven't looked into using it. Here it's compiled from source.

```sh
curl -O https://www.libarchive.org/downloads/libarchive-3.6.0.tar.xz
tar -xvf libarchive-3.6.0.tar.xz

cd libarchive-3.6.0

./configure --prefix=$BOOTSTRAP
make && make install

```

#### 5. openssl
```sh
curl -O https://www.openssl.org/source/openssl-1.1.1n.tar.gz
tar xzvf openssl-1.1.1n.tar.gz

cd openssl-1.1.1n

perl ./Configure --prefix=$BOOTSTRAP darwin64-arm64-cc
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
patch -p1 <<'EOF'
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

```

patch scripts to use the BSD checksums

```sh
patch -p1 <<'EOF'
diff --git a/scripts/makepkg.sh.in b/scripts/makepkg.sh.in
index e58edfa1..fe1a0ed8 100644
--- a/scripts/makepkg.sh.in
+++ b/scripts/makepkg.sh.in
@@ -643,7 +643,7 @@ write_buildinfo() {
 
 	write_kv_pair "pkgarch" "$pkgarch"
 
-	local sum="$(sha256sum "${BUILDFILE}")"
+	local sum="$(shasum -a 256 "${BUILDFILE}")"
 	sum=${sum%% *}
 	write_kv_pair "pkgbuild_sha256sum" $sum
 
diff --git a/scripts/repo-add.sh.in b/scripts/repo-add.sh.in
index d3938396..a8683be7 100644
--- a/scripts/repo-add.sh.in
+++ b/scripts/repo-add.sh.in
@@ -278,9 +278,9 @@ db_write_entry() {
 
 	# compute checksums
 	msg2 "$(gettext "Computing checksums...")"
-	md5sum=$(md5sum "$pkgfile")
+	md5sum=$(md5 -r "$pkgfile")
 	md5sum=${md5sum%% *}
-	sha256sum=$(sha256sum "$pkgfile")
+	sha256sum=$(shasum -a 256 "$pkgfile")
 	sha256sum=${sha256sum%% *}
 
 	# remove an existing entry if it exists, ignore failures


EOF

```

patch makepkg to use the BSD touch date format

```sh
patch -p1 <<'EOF'
index fe1a0ed8..9870129a 100644
--- a/scripts/makepkg.sh.in
+++ b/scripts/makepkg.sh.in
@@ -83,7 +83,7 @@ VERIFYSOURCE=0
 if [[ -n $SOURCE_DATE_EPOCH ]]; then
 	REPRODUCIBLE=1
 else
-	SOURCE_DATE_EPOCH=$(date +%s)
+	SOURCE_DATE_EPOCH=$(date +%Y-%m-%dT%H:%M:%S)
 fi
 export SOURCE_DATE_EPOCH


EOF

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

### makepkg dependencies

#### 1. libtool (for fakeroot)

```
curl -LO https://ftpmirror.gnu.org/libtool/libtool-2.4.6.tar.gz
tar -xzvf libtool-2.4.6.tar.gz

cd libtool-2.4.6

./configure --prefix=$BOOTSTRAP
make
make install

```

#### 2. autoconf

```
curl -LO https://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz
tar -xzvf autoconf-2.69.tar.gz

cd autoconf-2.69

./configure --prefix=$BOOTSTRAP
make install

```

#### 3. automake

```
curl -LO https://ftp.gnu.org/gnu/automake/automake-1.16.tar.gz
tar -xzvf automake-1.16.tar.gz
cd automake-1.16

./configure --prefix=$BOOTSTRAP
make install

```

#### 4. update autoconf

`automake` 1.16 doesn't build with `autoconf` 2.71, but 2.71 is required to build fakeroot.

```
curl -LO https://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.gz
tar -xzvf autoconf-2.71.tar.gz

cd autoconf-2.71

./configure --prefix=$BOOTSTRAP
make install

```

#### 5. fakeroot

```
git clone https://salsa.debian.org/clint/fakeroot.git

cd fakeroot

```

Apply another patch
```
patch -p1 <<'EOF'
diff --git a/Makefile.am b/Makefile.am
index 76210b5..958205b 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -1,6 +1,6 @@
 AUTOMAKE_OPTIONS=foreign
 ACLOCAL_AMFLAGS = -I build-aux
-SUBDIRS=doc scripts test
+SUBDIRS=scripts test
 
 noinst_LTLIBRARIES = libcommunicate.la libmacosx.la
 libcommunicate_la_SOURCES = communicate.c
diff --git a/configure.ac b/configure.ac
index f5bfafe..57629f1 100644
--- a/configure.ac
+++ b/configure.ac
@@ -606,8 +606,6 @@ AM_CONDITIONAL([MACOSX], [test x$macosx = xtrue])
 AC_CONFIG_FILES([
    Makefile
    scripts/Makefile
-   doc/Makefile
-   doc/de/Makefile doc/es/Makefile doc/fr/Makefile doc/nl/Makefile doc/pt/Makefile doc/sv/Makefile
    test/Makefile test/defs])
 AC_OUTPUT
 
EOF

```

Compile and install fakeroot

```
test -d build-aux || mkdir build-aux
test -f ltmain.sh || libtoolize --install --force
autoreconf --force --verbose --install

./configure --prefix=$BOOTSTRAP
make install

```
