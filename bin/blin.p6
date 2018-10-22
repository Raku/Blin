#!/usr/bin/env perl6

use v6.d.PREVIEW;

use Blin::Module;
use Blin::Processing;

use Whateverable;
use Whateverable::Builds;
use Whateverable::Config;
use Whateverable::Running;

unit sub MAIN(
    #| Old revision (initialized to the last release if unset)
    Str :old($start-point) is copy,
    #| New revision (default: HEAD)
    Str :new($end-point) = ‘HEAD’,
    #| Number of threads to use (initialized to the output of `nproc` if unset)
    Int :$nproc is copy,
    #| Thread number multiplier (default: 1.0)
    Rat :$nproc-multiplier = 1.0,
    #| Number of extra runs for regressed modules (default: 4)
    Int :$deflap = 4, # Can be really high because generally we are
                      # not expecting a large fallout with many
                      # now-failing modules.
    #| Number of seconds between printing the current status (default: 60.0)
    Rat :$heartbeat = 60.0,
    #| Use this to test some specific modules (empty = whole ecosystem)
    *@specified-modules,
);

#| Where to pull source info from
my @sources       = <
    https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/cpan.json
    http://ecosystem-api.p6c.org/projects.json
>; # TODO steal that from zef automatically

#| Core modules that are ignored as dependencies
my $ignored-deps  = <Test NativeCall Pod::To::Text Telemetry snapper>.Set;

#| Modules that should not be installed at all
my $havoc-modules = ∅;

#| Modules with tests that we don't want to run
my $skip-tests = (
   ‘MoarVM::Remote’, # possibly harmless, but scary anyway
   ‘November’, # eats memory
   # These seem to hang and leave some processes behind:
   ‘IO::Socket::Async::SSL’,
   ‘IRC::Client’,
   # These were ignored by Toaster, but reasons are unknown:
   ‘HTTP::Server::Async’,
   ‘HTTP::Server::Threaded’,
   ‘Log::Minimal’,
   ‘MeCab’,
   ‘Time::Duration’,
   ‘Toaster’,
   ‘Uzu’,
).Set;


#| Where to install zef
my $zef-path      = ‘data/zef’.IO;
#| Some kind of a timeout 😂
my $timeout       = 60 × 10;

my $semaphore;

my $output-path   = ‘output’.IO;
my $overview-path = $output-path.add: ‘overview’;
my $dot-path      = $output-path.add: ‘overview.dot’;
my $svg-path      = $output-path.add: ‘overview.svg’;

mkdir $output-path;
unlink $overview-path;
unlink $dot-path;
unlink $svg-path;

# Initialized later
my $start-point-full;
my   $end-point-full;

my $save-lock = Lock.new; # to eliminate miniscule chance of racing when saving


#✁-----------------------------cut-here------------------------------


# Hey reader, are you expecting some fancy pancy algorithms here?
# Well, let me disappoint you! Hundreds of `whenever`s are set up to
# start testing modules once their dependencies are processed. There's
# a little bit of depth-first search to find required dependencies
# (with marking of visited modules to spot cycles), but otherwise the
# code is dumb as bricks. It should scale up to the amount of modules
# in CPAN, at least as long as Rakudo is able to keep itself together
# with thousands of whenevers. In any case, don't quote me on that. At
# CPAN scale you'd have other problems to deal with anyway.


note ‘🥞 Prep’;

$nproc //= ($nproc-multiplier × +run(:out, ‘nproc’).out.slurp).Int;
$semaphore = Semaphore.new: $nproc.Int;

note “🥞 Will use up to $nproc threads for testing modules”;

ensure-config ‘./config-default.json’;
pull-cloned-repos; # pull rakudo and other stuff

$start-point //= get-tags(‘2015-12-24’, :default()).tail;

note “🥞 Will compare between $start-point and $end-point”;

if $zef-path.d {
    run :cwd($zef-path), <git pull>
} else {
    run <git clone https://github.com/ugexe/zef>, $zef-path
}

$start-point-full = to-full-commit $start-point;
  $end-point-full = to-full-commit   $end-point;

die ‘Start point not found’ unless $start-point-full;
die   ‘End point not found’ unless   $end-point-full;


my $quick-test = ‘/tmp/quick-test.p6’;
spurt $quick-test, “say 42\n”;

die ‘No build for start point’ unless build-exists $start-point-full;
die ‘No build for end point’   unless build-exists   $end-point-full;
die ‘Dead start point’ if run-snippet($start-point-full, $quick-test)<output>.chomp ne 42;
die ‘Dead end point’   if run-snippet(  $end-point-full, $quick-test)<output>.chomp ne 42;


# Leave some builds unpacked
my @always-unpacked = $start-point-full, $end-point-full;
run-smth $_, {;}, :!wipe for @always-unpacked;

note ‘🥞  Modules and stuff’;

my @modules;
my %lookup; # e.g. %(foo => [Module foo:v1, …], …)


note ‘🥞🥞 Populating the module list and the lookup hash’;
for @sources {
    use JSON::Fast;
    # XXX curl because it works
    my $json-data = run(:out, <curl -->, $_).out.slurp;
    my $json = from-json $json-data;
    for @$json {
        my Module $module .= new:
            name    => .<name>,
            version => Version.new(.<version>) // v0,
            depends => ([∪]
                        (.<      depends> // ∅).Set,
                        (.< test-depends> // ∅).Set,
                        (.<build-depends> // ∅).Set,
                       ) ∖ $ignored-deps,
        ;
        if $module.name ∈ $havoc-modules {
            note “🥞🥞 Module {$module.name} is ignored because it causes havoc”;
            next
        }

        @modules.push: $module;
        %lookup{$module.name}.push: $module;
        %lookup{.key}.push: $module for .<provides>.pairs; # practically aliases
    }
}


note ‘🥞🥞 Sorting modules’;
.value = .value.sort(*.version).eager for %lookup;


note ‘🥞🥞 Resolving dependencies’;
for @modules -> $module {
    sub resolve-dep($depstr) {
        return Empty if $depstr !~~ Str; # weird stuff, only in Inline::Python
        use Zef::Distribution::DependencySpecification;
        my $depspec = Zef::Distribution::DependencySpecification.new: $depstr;
        if ($depspec.spec-parts<from> // ‘’) eq <native bin>.any {
            # TODO do something with native deps?
            return Empty
        }
        my $depmodule = %lookup{$depspec.name // Empty}.tail;
        without $depmodule {
            $module.done.keep: MissingDependency if not $module.done;
            $module.errors.push: “Dependency “$depstr” was not resolved”;
            return Empty
        }
        $depmodule
    }
    $module.depends = $module.depends.keys.map(&resolve-dep).Set;
    .rdepends ∪= $module for $module.depends.keys;
}


note ‘🥞🥞 Marking latest versions and their deps’;
for %lookup {
    next unless .key eq .value».name.any; # proceed only if not an alias
    next if @specified-modules and not .key eq @specified-modules.any;
    .value.tail.needify
}


note ‘🥞🥞 Filtering out uninteresting modules’;
@modules .= grep: *.needed;


note ‘🥞🥞 Detecting cyclic dependencies’;
for @modules -> $module {
    eager gather $module.safe-deps: True;
    CATCH {
        when X::AdHoc { # TODO proper exception
            $module.done.keep: CyclicDependency if not $module.done;
            $module.errors.push: ‘Cyclic dependency detected’;
        }
    }
}


note ‘🥞🥞 Listing some early errors’;
for @modules {
    next unless .done;
    put “{.name} – {.done.result} – {.errors}”;
}


note ‘🥞 Processing’;
my $processing-done = Promise.new;
start { # This is just to print something to the terminal regularly
    react {
        whenever Supply.interval: $heartbeat { # just something we print from time to time
            save-overview; # make sure we save something if it hangs
            my $total  = +@modules;
            my @undone = eager @modules.grep: *.done.not;
            my $str    = “⏳ {$total - @undone} out of $total modules processed”;
            $str      ~= ‘ (left: ’ ~ @undone».name ~ ‘)’ if @undone ≤ 5;
            note $str;
            done unless @undone;
        }
        whenever $processing-done {
            done
        }
    }
    CATCH {
        default {
            note ‘uh oh in heartbeat’; note .gist;
        }
    }
}

react { # actual business here
    for @modules -> $module {
        next if $module.done;
        whenever Promise.allof($module.depends.keys».done) {
            # Important: the `acquire` below has to be outside of the
            # start block. Otherwise we can cause thread starvation by
            # kicking off too many start blocks at the same time
            # (because there are many modules that don't depend on
            # anything). Basically, all of the `start` blocks will
            # cause Proc::Async's not to start, meaning that start
            # blocks will never finish either. Another (better) option
            # to resolve this (maybe) is to use another
            # ThreadPoolScheduler. Note that as of today machines with
            # a gazzilion of cores (where the number of cores gets
            # close to the default value of 64) will need to use
            # RAKUDO_MAX_THREADS env variable.
            $semaphore.acquire;
            start {
                LEAVE $semaphore.release;

                process-module $module,
                               :$deflap,
                               :$start-point-full, :$end-point-full,
                               :$zef-path, :$timeout,
                               :@always-unpacked,
                               testable => $module.name ∉ $skip-tests,
                ;

                CATCH {
                    default {
                        note ‘uh oh in processing’; note .gist;
                        $module.done.keep: UnhandledException;
                    }
                }
            }
        }
    }
}

note ‘🥞🥞 Almost done, waiting for all modules to finish’;
await @modules».done;


$processing-done.keep;
note ‘🥞 Saving results’;

note ‘🥞🥞 Saving the overview’;

sub save-overview {
    $save-lock.protect: {
        spurt $overview-path, @modules.sort(*.name).map({
            my $result = .done ?? .done.result !! Unknown;
            my $line = “{.name} – $result”;
            $line ~= “, Bisected: {.bisected}” if $result == Fail;
            $line
        }).join: “\n”
    }
}

save-overview;

note ‘🥞🥞 Saving the dot file’;
my @bisected = @modules.grep(*.done.result == Fail);
# Not algorithmicaly awesome, but will work just fine in practice
my Set $to-visualize = @bisected.Set;
$to-visualize ∪= (gather  .deps: True).Set for @bisected;
$to-visualize ∪= (gather .rdeps: True).Set for @bisected;

my $dot = ‘’;

for $to-visualize.keys -> $module {
    my $color = do given $module.needed ?? $module.done.result !! Unknown {
        when Unknown                { ‘gray’        }
        when OK                     { ‘green’       }
        when Fail                   { ‘red’         }
        when Flapper                { ‘yellow’      }
        when AlwaysFail             { ‘violet’      }
        when InstallableButUntested { ‘yellowgreen’ }
        when MissingDependency      { ‘orange’      }
        when CyclicDependency       { ‘blue’        }
        when BisectFailure          { ‘brown’       }
        when ZefFailure             { ‘crimson’     }
        when UnhandledException     { ‘hotpink’     }
    }
    $dot ~= “    "{$module.name}" [color=$color];\n”;
    for $module.depends.keys {
        next unless $_ ∈ $to-visualize;
        $dot ~= “    "{$module.name}" -> "{.name}";\n”;
    }
    $dot ~= “\n”;
}

if $dot {
    spurt $dot-path, “digraph \{\n    rankdir = BT;\n” ~ $dot ~ “\n}”;
    note ‘🥞🥞 Creating an SVG image from the dot file’;
    run <dot -T svg -o>, $svg-path, $dot-path # TODO -- ?
} else {
    note ‘🥞🥞 No regressions found, dot file not saved’;
}

note ‘🥞 Cleaning up’;
for @always-unpacked {
    my $path = run-smth-build-path $_;
    run <rm -rf -->, $path; # TODO use File::Directory::Tree ?
}
