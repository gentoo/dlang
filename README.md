dlang - overlay for Gentoo Linux
================================

This overlay aims to make parallel installation of D compilers easy and offer
some of the most popular D libraries. Features it offers:
* Installation of DMD, GDC and LDC in parallel
* Customizable »CFLAGS« for each D compiler
* GDC is integrated with GCC for the best compatibility
* Slotted installation of previous D compiler versions
* Shared library support when using DMD
* Easily compile debug builds with DMD and release builds with LDC/GDC even when they depend on libraries like GtkD.
  (Note: This depends on availability of libraries in this repository.)

### Usage

The overlay supports linker and compiler flags, though some package build
scripts may not be patched to use them (e.g. DMD). For D packages, the LDFLAGS
variable is rewritten to match the D compilers linker prefix. For DMD this is
`-L` and for LDC this is `-L=`. If you have not set up LDFLAGS in make.conf, the
Gentoo default will be used, which is currently `-Wl,--as-needed -Wl,-O1`.
Taking this example, in a compilation using DMD this would be rewritten to
`LDFLAGS=-L--as-needed -L-O1`.
Compiler flags are passed into build scripts as `DCFLAGS`, but since there is no
common command-line syntax between D compilers they are split up into DMDFLAGS,
GDCFLAGS and LDCFLAGS in `make.conf`. An example configuration could be:
```sh
DMDFLAGS="-O"
GDCFLAGS="-march=native -O3 -pipe -frelease"
LDCFLAGS="-O4 -release"
```
You may experiment with `-ffunction-sections`, `-fdata-sections` and the
corresponding linker flag `--gc-sections`, but this caused broken exception
handling in the past.

When you install libraries, no compilers will be selected to work with. Please run
`emerge -pv <lib>` to list available compiler use flags for a library and use
`/etc/portage/package.use` to activate them. A note about compilation times:
Most build tools compile one module at a time, which causes a considerable overhead
in compile times compared to passing multiple modules to the compiler at once.
The use of several compilers in several versions and multilib installs all multiply
the compile times. GtkD with no optional features compiled for *one* version of DMD,
GDC and LDC took me 1 hour 10 minutes on a dual core 2 Ghz notebook.

### Executables paths
* DMD: `/opt/dmd-<version>/bin/dmd`
* GDC: `/usr/<abi>-pc-linux-gnu/gcc-bin/<version>/gdc`
* LDC: `/opt/ldc2-<version>/bin/ldc2`

An eselect script will create symlinks to these executables, so they can be
called by their original names with the exception of GDC which is managed by
gcc-config.

### Configuration files
For DMD the configuration files lie side-by-side with the executable, to allow
different path setups for each installation.

### Imports
* DMD: `/opt/dmd-<version>/import`
* GDC: `/usr/include/d/<version>`
* LDC: `/opt/ldc2-<version>/include/d`

### Libraries
Dynamic and static libraries are installed into:
* DMD: `/opt/dmd-<version>/lib{32,64}`
* GDC: `/usr/lib/gcc/<abi>-pc-linux-gnu/<version>[/32]`
* LDC: `/opt/ldc2-<version>/lib{32,64}`

Include files should be placed in `/usr/include/dlang/<library>`

### Procedures
#### When adding new compiler versions
Add the version to dlang.eclass, too. This is way it knows which compiler
release includes which version of D, which is crucial for dependency
management.
#### When changing paths in compiler ebuilds
Make sure that dlang.eselect knows about it. dlang.eclass also has a
function that needs to be changed: `dlang_foreach_config()`
It advertizes compiler specific variables and paths to D ebuilds.

### Q & A
  Q: Why are D libraries not installed in their default locations?
  A: D compilers have ABIs that are incompatible with each other. This means
     either sticking to one compiler for anything D, or to change the default
     location and allow for one installation per compiler.
     Since my motivation was to use dmd for debug builds and one of the others
     for releases, I chose the second option. I could have just added prefixes
     or suffixes to the library names, but that means build scripts
     need to be aware of this change. Giving each compiler eco system its own
     library directory and seting up the path in the compiler should ideally
     allow us to build a D program with any compiler and link to libraries with
     no further configuration change.

  Q: So why is there a library directory for each version of each D compiler?
  A: It might seem overkill at first, but we have no guarantee about D ABI
     stability at this point. Libraries compiled with 2.064 might not work with
     libraries compiled with 2.065. To be on the safe side, I decided to
     separate D specifications the same way as compilers.

### TODO
* Optional: For GtkD, make HTML DDOC generation work with any compiler and
            install them if the doc use flag is set.
* Optional: Make dmd respect CFLAGS etc.
* For GtkD, fix the pkg-config (.pc) script to point to the correct library dir
  or none (since it should be found in the default paths).
  Big question: What to do with the dmd specific "-L" prefixes?
* What to do about rdmd and co.? Their man pages are in the 'dmd' repository,
  but the source code is in 'tools'.
