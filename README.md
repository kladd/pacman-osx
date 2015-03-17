# Compiling Pacman on OS X 10.10 Yosemite

### About Pacman

Pacman is the default package manager for the Arch Linux distribution of Linux.
For more information and tips about using Pacman, visit the
[Arch wiki](https://wiki.archlinux.org/index.php/pacman).

### About Pacman on OS X

This could be a much easier process if you use Homebrew to install the build
dependencies for Pacman. I don't recommend keeping both for long, though.
Having two package managers in use at once is a headache in wait, and it won't
wait long.

Here I take the long way by compiling each dependency from source. I keep the
dependencies installed to a directory called "pacman-deps" in my home directory.
This way, nothing I install will interfere with the OS X default installations.

I've elected to install Pacman to to `/usr/local`. This is also the
directory I'll be using for packages installed by Pacman.

An automated install script is available here:
[install.sh](https://github.com/kladd/pacman-osx/blob/master/install.sh)

PKGBUILDs for Pacman on OS X are located in
[this repo](https://github.com/kladd/pacman-osx-pkgs).

##### 1. gettext

OS X comes with gettext by default but this installation doesn't include `autopoint`.

```bash
# download the source
curl -O https://ftp.gnu.org/gnu/gettext/gettext-0.19.2.tar.xz

# extract the sources and enter the extracted directory
tar -xJvf gettext-0.19.2.tar.xz
cd gettext-0.19.2

# compile and install gettext to a safe location, I used '$HOME/pacman-deps'
./configure --prefix=$HOME/pacman-deps
make
make install
```

##### 2. automake

Again, included in OS X but without something we need, `aclocal`.

```bash
# download the source code
curl -O http://ftp.gnu.org/gnu/automake/automake-1.14.1.tar.gz

# extract the sources and enter the extracted directory
tar -xzvf automake-1.14.1.tar.gz
cd automake-1.14.1

# Compile automake into the pacman-deps directory
./configure --prefix=$HOME/pacman-deps
make
make install
```

##### 3. autoconf

Same story as the other two dependencies so far.

```bash
# download source
curl -O http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz

# extract
tar -xzvf autoconf-2.69.tar.gz
cd autoconf-2.69

# compile
./configure --prefix=$HOME/pacman-deps
make
make install
```

##### 4. pkg-config

```bash
curl -O http://pkgconfig.freedesktop.org/releases/pkg-config-0.28.tar.gz

tar -xzvf pkg-config-0.28.tar.gz
cd pkg-config-0.28

./configure --prefix=$HOME/pacman-deps
make
make install
```

##### 5. libtool

```bash
curl -O http://ftp.gnu.org/gnu/libtool/libtool-2.4.2.tar.gz

tar -xzvf libtool-2.4.2.tar.gz
cd libtool-2.4.2

./configure --prefix=$HOME/pacman-deps
make
make install
```

##### 6. bash >= 4.1.0

Yosemite still ships with a 3.x version of bash which is not compatible with Pacman.
We'll need to compile a newer version.

```bash
curl -O http://ftp.gnu.org/gnu/bash/bash-4.3.tar.gz

tar -xzvf bash-4.3.tar.gz
cd bash-4.3

./configure --prefix=$HOME/pacman-deps
make
make install
```

##### 7. libarchive >= 2.8.0

Yosemite comes with libarchive 2.8.3 but doesn't include the header files we need,
so we'll have to download the source code for the version of libarchive already
installed to get them.

```bash
curl -LO https://github.com/libarchive/libarchive/archive/v2.8.3.tar.gz
tar -xzvf v2.8.3.tar.gz
cd libarchive-2.8.3

# One extra step here, autogen requires some of the packages we've compiled so far
PATH=$HOME/pacman-deps/bin:$PATH ./build/autogen.sh
./configure --prefix=$HOME/pacman-deps
make
make install
```

##### 8. asciidoc
```bash
curl -LO http://downloads.sourceforge.net/project/asciidoc/asciidoc/8.6.9/asciidoc-8.6.9.tar.gz

tar -xzvf asciidoc-8.6.9.tar.gz
cd asciidoc-8.6.8

./configure --prefix=$HOME/pacman-deps
make
make install
```

##### 9. fakeroot

Every available version of fakeroot for OS X seems not to compile on Yosemite,
or at least not for me. [Darwin fakeroot](https://github.com/duskwuff/darwin-fakeroot),
however, required the least patching.
So these instructions as well as any packages I create will assume this
implementation of fakeroot.

This is not actually necessary to compile Pacman. But, it is necessary
to build packages once Pacman has been installed. So, it's recommended that you
install this either before or after compiling Pacman for the first time, then
again with the darwin-fakeroot package in the
[pacman-osx-pkgs repo](http://github.com/kladd/pacman-osx-pkgs).


```bash
curl -O https://github.com/duskwuff/darwin-fakeroot/archive/v1.1.tar.gz
curl -O https://raw.githubusercontent.com/kladd/pacman-osx-pkgs/osx-10.10/core/darwin-fakeroot/darwin-fakeroot.patch

patch -Np0 < $srcdir/darwin-fakeroot.patch

# Defaults to /usr/local
make PREFIX=$HOME/pacman-deps install
```

### Downloading the Pacman source

```bash
git clone git://projects.archlinux.org/pacman.git
cd pacman
```

### Finally, compiling Pacman

```bash
export LIBARCHIVE_CFLAGS="-I${HOME}/pacman-deps/include"
export LIBARCHIVE_LIBS="-larchive"
export LIBCURL_CFLAGS="-I/usr/include/curl"
export LIBCURL_LIBS="-lcurl"

./configure --prefix=/usr/local \
            --enable-doc \
            --with-scriptlet-shell=$HOME/pacamn-deps/bin/bash \
            --with-curl
make
make -C contrib
make install
make -C contrib install
```

### Fallacies & Pitfalls

- Once you've started using pacman to install packages, some of the software
  we built just now will need to be overridden by using the `--force` option
  with pacman.

