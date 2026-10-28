# Installing specman

## Requirements

- Perl 5.36 or later
- [YAML::PP](https://metacpan.org/pod/YAML::PP)

Everything else specman uses is part of Perl itself.

On Arch Linux:

```sh
sudo pacman -S perl perl-yaml-pp
```

## Running from the source tree

specman can be run without installing it, by telling Perl where its modules
are:

```sh
perl -Ilib bin/specman --help
```

## Building and testing

```sh
perl Makefile.PL
make
make test
```

To run the tests without building, or to run a single test file:

```sh
prove -l t
prove -l t/repository.t
```

## Installing

System-wide:

```sh
perl Makefile.PL
make
make test
sudo make install
```

This installs the `specman` command, its modules, and the manual pages:
`man specman` for the command, and `man Specman::Manual::Format` for the file
format.

For the current user only, without root access:

```sh
perl Makefile.PL INSTALL_BASE=~/perl5
make
make test
make install
```

Then make sure `~/perl5/bin` is in `PATH`, and `~/perl5/lib/perl5` is in
`PERL5LIB`:

```sh
export PATH="$HOME/perl5/bin:$PATH"
export PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:$PERL5LIB}"
```

## Packaging

Distribution packages should install into the vendor directories:

```sh
perl Makefile.PL INSTALLDIRS=vendor
make
make test
make install DESTDIR="$pkgdir"
```

## Cleaning up

```sh
make distclean
```

removes everything the build created.

## Documentation

The Markdown documents in `doc/` are generated from the POD that is installed
as manual pages:

| Document | Generated from |
|---|---|
| `doc/commands.md` | `bin/specman` |
| `doc/format.md` | `lib/Specman/Manual/Format.pod` |

After changing the POD, regenerate them with:

```sh
perl Makefile.PL
make docs
```

This needs [Pod::Markdown](https://metacpan.org/pod/Pod::Markdown), which is
only needed for working on specman, not for using it:

```sh
yay -S perl-pod-markdown
```

`make test` fails when a document in `doc/` is out of date with its POD.
Without Pod::Markdown, that check is skipped.
