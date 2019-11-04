## Project Blin – Toasting Reinvented

Blin is a quality assurance tool for
[Rakudo](https://github.com/rakudo/rakudo/) releases. Blin is based on
[Whateverable](https://github.com/perl6/whateverable/).

Blin was inspired by
[Toaster](https://github.com/perl6-community-modules/perl6-Toaster). Here
are some advantages:
* Fetches archives from
  [whateverable](https://github.com/perl6/whateverable/wiki/Shareable#bot-usage-examples)
  instead of spending time to build rakudo
* Installs modules in proper order to avoid testing the same module more than once
* Deflaps modules that fail intermittently
* Automatically bisects regressed modules
* Avoids segfaults by producing no useful output instead of using DBIish


### Installation

Install required packages:
```bash
sudo apt install zstd lrzip graphviz
```

Install dependencies:

```bash
zef install --deps-only .
```

Many modules require native dependencies. See
[this page](https://github.com/perl6-community-modules/perl6-Toaster/wiki)
for the list of packages to install.


### Running

Currently it is supposed to run only on 64-bit linux systems.

If you want to test one or more modules:

```bash
PERL6LIB=lib bin/blin.p6 SomeModuleHere AnotherModuleHere
```

Here is a more practical example:

```bash
time PERL6LIB=lib bin/blin.p6 --old=2018.06 --new=2018.09 Foo::Regressed Foo::Regressed::Very Foo::Dependencies::B-on-A
```

You can also test arbitrary scripts. The code can depend on modules,
in which case they have to be listed on the command line (e.g. for a
script depending on WWW you should list WWW module, dependencies of
WWW will be resolved automatically).

Using this ticket as an example: https://github.com/rakudo/rakudo/issues/2779

Create file `foo.p6` with this content:

```perl6
use WWW;
my @stations;
@stations = | jpost "https://www.perl6.org", :limit(42);
```


Then run Blin:
```bash
./bin/blin.p6 --old=2018.12 --new=HEAD --custom-script=foo.p6 WWW
```

Then check out the output folder to see the results. Essentially, it
is a local Bisectable.


If you want to test the whole ecosystem:

```bash
time PERL6LIB=lib bin/blin.p6
```

Estimated time to test the whole ecosystem with 24 cores is ≈60 minutes.

**⚠☠ SECURITY NOTE: [issues mentioned in Toaster still
apply.](https://github.com/perl6-community-modules/perl6-Toaster#warning-dangerus-stuf-ahed)
Do not run this for the whole ecosystem on non-throwaway
installs. ☠⚠**


### Viewing

See `output/overview` file for a basic overview of results. More
details for specific modules can be found in `installed/`
directory. Betters ways to view the data should come soon (hopefully).

### Docker

For info about the Docker image, have a look at the
[Readme file ](docker/README.md) in the docker directory.

