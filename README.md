dlang - overlay for Gentoo Linux
================================

[![Build Status](https://travis-ci.org/gentoo/dlang.png?branch=master)](https://travis-ci.org/gentoo/dlang)

## Overview
This overlay aims to make parallel installation of Dlang compilers easy and offers some of the most popular D libraries. Features it offers:

* Installation of DMD, GDC and LDC in parallel
* Custom »CFLAGS« for each Dlang compiler
* GDC is integrated with GCC for the best compatibility
* Slotted installation of previous Dlang compiler versions
* Shared library support when using DMD
* Easily compile debug builds with DMD and release builds with LDC/GDC even when they depend on libraries like GtkD. (This depends on availability of libraries in this repository.)

The overlay supports linker and compiler flags, though some package build scripts may not be patched to use them (e.g. DMD). For Dlang packages, the LDFLAGS variable is rewritten to match the Dlang compilers linker prefix. For DMD this is `-L` and for LDC this is `-L=`. If you have not set up LDFLAGS in make.conf, the Gentoo default will be used, which is currently `-Wl,--as-needed -Wl,-O1`. Taking this example, in a compilation using DMD this would be rewritten to `LDFLAGS=-L--as-needed -L-O1`. Compiler flags are passed into build scripts as `DCFLAGS`, but since there is no common command-line syntax between Dlang compilers they are split up into DMDFLAGS, GDCFLAGS and LDCFLAGS in `make.conf`. An example configuration could be: 
```sh
DMDFLAGS="-O"
GDCFLAGS="-march=native -O3 -pipe -frelease"
LDCFLAGS="-O4 -release"
```
You may experiment with `-ffunction-sections`, `-fdata-sections` and the corresponding linker flag `--gc-sections`, but this caused broken exception handling in the past.

## Compilers
There are three production ready Dlang compilers available, that all share the same front-end, but use different back-ends. The front-end version determines the available language features, while the back-end provides the optimizing code generator.

Starting with version 2.068, the front-end became self-hosting, which means that you need an existing installed D compiler to build it. Where the ebuild allows you to pick a specific host compiler, they offer compiler USE flags named after the compiler executable and version, e.g.: `ldc2-0_17`, `dmd-2_074`, `gdc-4_9_4`.

Since the Dlang compilers generate binaries which are incompatible with each other and often with earlier versions of the same compiler, this overlay mimics what has been done for Python or Ruby: A Dlang library can be installed for any number of compilers versions. This is done by selecting multiple compiler USE flags at once. Effectively each compiler version will have its own set of installed libraries.

### DMD
This is the Dlang reference compiler. It always offers the latest language features and is know for being fast at the cost of less optimized generated code compared to GDC and LDC, which makes it a good choice for edit and build cycles. It can target only x86 and amd64.

In addition to the common compiler USE flags, the DMD ebuilds offer a special USE flag named `selfhost` (which is default enabled). It bootstraps the compiler on Linux and FreeBSD with a DMD binary of the same version provided by its developers. This allows you to install DMD without first installing another Dlang compiler. Be aware though that using GDC or LDC as the host compiler will result in a more optimized and thus faster DMD.

#### Configuration
Benefiting from `CONFIG_PROTECT` and allowing multiple DMD versions to have different configuration was a goal for this overlay. This is accomplished by storing a symlink in `/opt/dmd-${SLOT}/bin/dmd.conf` that links to `/etc/dmd/${SLOT}.conf`. In addition, the "traditional" `/etc/dmd.conf` links to the currently active version selected through `eselect dlang set dmd …`.

Deviating from upstream, this overlay links programs against a shared Phobos2 library by default and instructs the linker to look for libraries in DMD's library path (using `-rpath`), to allow libraries to be installed for multiple compilers under the same name.

#### Paths
* Executable: `/opt/dmd-${SLOT}/bin/dmd`, short: `dmd-${SLOT}`/`dmd`
* Libraries: `/opt/dmd-${SLOT}/lib{,32,64}/`
* Imports: `/opt/dmd-${SLOT}/import/`

### GDC
GDC extends the GNU Compiler Collection (GCC) and benefits from its optimizer. In this overlay you find patched `sys-devel/gcc` ebuilds that integrate GDC into the system's GCC.

While GDC developers support many combinations of GCC versions and Dlang front-end versions, this overlay ties a front-end version to a specific GCC version in order to facilitate dependency management that ultimately cares only about front-end features. You may often find that there is no matching GDC version for the latest stable GCC on Gentoo, yet. In that case you can keep an older GDC enabled GCC around in parallel to your system compiler. Use `gcc-config` to select the currently active GCC (and GDC). This may be useful if something requires the `gdc` command to be available.

As mentioned above, up to version 2.068 the front-end can be built with existing C++ compilers and GDC offers a "stable" branch for each major GCC release with exactly that front-end. This allows you to bootstrap a 2.068 D compiler that can then compile the more recent front-ends. In the patched ebuilds you would first need to enable the `d-bootstrap` USE-flag in addition to the `d` USE-flag to build the temporary 2.086 compiler and then drop `d-bootstrap` again to build the final compiler. Whenever you build without `d-bootstrap`, the build process will test for the availability of the `gdc` command, so make sure your existing GDC is the active compiler with `gcc-config`.

If you are interested in a particular Dlang front-end version, refer to [dlang-compilers.eclass](https://github.com/gentoo/dlang/blob/master/eclass/dlang-compilers.eclass) to find out which GCC slot we have currently associated with which front-end version.

#### Paths
* Executable: `/usr/${CHOST}/gcc-bin/${SLOT}/gdc`, short: `gdc`
* Libraries: `/usr/lib/gcc/${CHOST}/${SLOT}/`
* Imports: `/usr/lib/gcc/${CHOST}/${SLOT}/include/d/`

### LDC
LDC uses LLVM as the back-end. The separation between back-end libraries and front-ends allows multiple front-end versions to be used with the same LLVM installation. LLVM's optimizer is of a similar quality as GCC's and LDC provides a up-to-date and independent alternative to DMD and GDC.

Versions starting with 1.0.0 require a host Dlang compiler and can be compiled with 0.17 series which is still maintained for that purpose (USE-flag `ldc2-0_17`). Older versions may cause hick-ups in Portage's dependency resolution. For 0.16 you can mask recent LLVM versions, so they don't get pulled in. 0.14 and 0.15 use LLVM 3.5 which is statically linked. As such you can upgrade LLVM after installation without breaking LDC2 0.15/0.14. Be aware though that `emerge --with-bdeps` can't be used in that setup as it would pull in LLVM 3.5 again.

#### Paths
* Executable: `/opt/ldc2-${SLOT}/bin/ldc2`
* Libraries: `/opt/ldc2-${SLOT}/lib{,32,64}/`
* Imports: `/opt/ldc2-${SLOT}/include/d/`

### Active version
The active version of DMD and LDC is controlled by the `eselect dlang` module. GDC's active version is selected via `gcc-config` as usual. The active compilers from each developer can be invoked through short names such as `dmd`, `gdc`, `gdmd`, `ldc2` or `ldmd2`.

## Libraries
When you install libraries, no compilers will be selected to work with. Please run `emerge -pv <lib>` to list available compiler use flags for a library and use `/etc/portage/package.use` to activate them. A note about compilation times: Most build tools compile one module at a time, which causes a considerable overhead in compile times compared to passing multiple modules to the compiler at once. The use of several compilers in several versions and multilib installs all multiply the compile times. GtkD with no optional features compiled for *one* version of DMD, GDC and LDC took me 1 hour 10 minutes on a dual core 2 GHz notebook.

Import files from libraries are placed in `/usr/include/dlang/<library>/` matching the result of an [online survey](http://www.easypolls.net/poll.html?p=52828149e4b06cfb69b97527) created in 2013.

## Contributing
If you want to maintain a package or generally help update the repository or have a suggestion, just drop me a [note](mailto:marco.leise@gmx.de). If things move too slowly, I can add you to the team with commit rights. That's better than maintaining your own fork and having people search for updates in multiple places. Should this repository appear abandoned at some point and no one can be reached, please contact the [Gentoo GitHub org](https://github.com/gentoo) that has ownership of it.
### When adding new compiler versions
At first there is not much to be done, but once the first arch is stable, it should be added as a compiler option for Dlang packages, by providing a description for its USE-flag in `profile/use.desc` and tying it into `eclass/dlang-compilers.eclass`. This way it knows which compiler release is based on which version of the D language specification, which is crucial for dependency management.
### When changing paths in compiler ebuilds
Make sure that `dlang.eselect` knows about it. `eclass/dlang.eclass` also has a function that needs to be changed: `dlang_foreach_config()`. It advertizes compiler specific variables and paths to D ebuilds.

## Q & A
* **Why does DMD have a circular dependency upon itself?**

  Starting with version 2.068 parts of DMD became self-hosting and require an installed D compiler. You can temporarily pick a compatible GDC or LDC version or DMD 2.067, the last C++ based version through the respective USE-flag to bootstrap DMD 2.068 and later.

* **GDC tells me it needs GDC to build the D language.**

  Try to build with `d` and `d-bootstrap`. That will generate a GDC based on an old version of Dlang that required only a C++ compiler. Afterwards you can make that compiler active via `gcc-config` and use it to build GCC once more with only the `d` USE-flag. When you upgrade your GCC make sure you keep one version with GDC around to avoid going through the bootstrap process again.

* **Why are D libraries not installed in their default locations?**

  D compilers have ABIs that are incompatible with each other. This means either sticking to one compiler for anything D, or to change the default location and allow for one installation per compiler. Since my motivation was to use dmd for debug builds and one of the others for releases, I chose the second option. I could have just added prefixes or suffixes to the library names, but that means build scripts need to be aware of this change. Giving each compiler eco system its own library directory and setting up the path in the compiler should ideally allow us to build a D program with any compiler and link to libraries with no further configuration change.

* **So why is there a library directory for each version of each D compiler?**

  It might seem overkill at first, but we have no guarantee about D ABI stability at this point. Libraries compiled with 2.064 might not work with libraries compiled with 2.065. To be on the safe side, I decided to separate D specifications the same way as compilers.

## TODO
* Optional: For GtkD, make HTML DDOC generation work with any compiler and
            install them if the doc use flag is set.
* Optional: Make dmd respect CFLAGS etc.
* For GtkD, fix the pkg-config (.pc) script to point to the correct library dir
  or none (since it should be found in the default paths).
  Big question: What to do with the dmd specific "-L" prefixes?
* What to do about rdmd and co.? Their man pages are in the 'dmd' repository,
  but the source code is in 'tools'.
