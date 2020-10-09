use File::Temp;


unit class Blin::Tester::Pakku;

has $.path;
has $.binary;
has $.output-failed;
has @.sources;


submethod BUILD ( ) {

    #| Where to install pakku
    my $pakku-path = ‘data/pakku’.IO;

    note ‘🥞 Ensuring Pakku ’;
    unless $pakku-path.d {

        my $pakku-src  = tempdir;

        run "git", "clone", "https://github.com/hythm7/Pakku", $pakku-src; 
        run "$pakku-src/tools/install-pakku.raku", "--dest=$pakku-path"; 
    } 

    # using recman meta source here
    # can be replaced with zef sources
    @!sources       = <http://recman.pakku.org/meta/42>;


    $!path = $pakku-path;

    $!binary = $!path.add: 'bin/pakku';

    $!output-failed = '💀';

}

method test-command( ::?CLASS:D: :$testable!, :$install-path!, :$module-name! ) {
    $!binary,
    "verbose trace",
    "yolo",
    "add",
    "force",
    ( $testable ?? "test" !! "notest" ),
    "nodeps",
    "to $install-path",
    $module-name,
}

