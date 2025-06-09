unit class Blin::Tester::Pakku;

use Blin::Debug;

has $.path;
has $.binary;
has $.output-failed;
has @.sources;


submethod TWEAK ( ) {

    debug ‘Installing Pakku’;
    my $pakku-src  = ‘data/pakku-src’.IO;

    if $pakku-src.d {
        run :cwd($pakku-src), <git pull>
    } else {
        run <git clone https://github.com/hythm7/Pakku.git>, $pakku-src
    }

    #| Where to install pakku
    my $pakku-path = ‘data/pakku’.IO;

    run "$pakku-src/tools/install-pakku.raku", "--dest=$pakku-path"; 

    # using recman meta source here
    # can be replaced with zef sources
    @!sources       = <http://recman.pakku.org/meta/42>;

    $!path = $pakku-path;

    $!binary = $!path.add: 'bin/pakku';

    $!output-failed = '💀';

}

method test-command( ::?CLASS:D: :$testable!, :$install-path!, :$module-name! ) {
    $!binary,
    "verbose info",
    "yolo",
    "add",
    "force",
    ( $testable ?? "test" !! "notest" ),
    "nodeps",
    "to $install-path",
    $module-name,
}

