unit class Blin::Tester::Zef;

has $.path;
has $.binary;
has $.output-failed;
has $!zef-config-path;
has @.sources;


submethod TWEAK ( ) {

    #| Where to install zef
    my $zef-path          = ‘data/zef’.IO;
    my $zef-config-path   = ‘data/zef-config.json’.IO;
    my $zef-dumpster-path = ‘data/zef-data’.IO;
    #↑ XXX Trash pickup services are not working, delete the directory
    note ‘🥞 Ensuring zef checkout’;
    if $zef-path.d {
        run :cwd($zef-path), <git pull>
    } else {
        run <git clone https://github.com/ugexe/zef>, $zef-path
    }

    note ‘🥞 Creating a config file for zef’;
    {
        run(:err, $zef-path.add(‘/bin/zef’), ‘--help’).err.slurp
          .match: /^^CONFIGURATION \s* (.*?)$$/;

        use JSON::Fast;
        my $zef-config = from-json $0.Str.IO.slurp;

        # Turn auto-update off
        for $zef-config<Repository>.list {
            next unless .<module> eq ‘Zef::Repository::Ecosystems’;
            .<options><auto-update> = 0; # XXX why is this not a boolean?
        }

        $zef-config<RootDir>  = $zef-dumpster-path.absolute;
        $zef-config<TempDir>  = $zef-dumpster-path.add(‘tmp’).absolute;
        $zef-config<StoreDir> = $zef-dumpster-path.add(‘store’).absolute;

        spurt $zef-config-path, to-json $zef-config;

        run $zef-path.add(‘/bin/zef’), “--config-path=$zef-config-path”, ‘update’;

    }

    @!sources       = <
      https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/p6c.json
      https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/cpan.json
>;   # TODO steal that from zef automatically


    $!zef-config-path = $zef-config-path;
    $!path = $zef-path;
    $!binary = $!path.add: 'bin/zef';
    $!output-failed = '[FAIL]:';

}

method test-command( ::?CLASS:D: :$testable!, :$install-path!, :$module-name! ) {
    $!binary,
    “--config-path=$!zef-config-path”,
    <--verbose --force-build --force-install>,
    ($testable ?? ‘--force-test’ !! ‘--/test’),
    <--/depends --/test-depends --/build-depends>,
    ‘install’,
    “--to=inst#$install-path”,
    $module-name,
}

