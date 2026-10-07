#!/usr/bin/env raku

use Terminal::ANSIColor;
use Blin::Processing;

constant @states    = Status.pairs.sort(*.value)>>.key;
constant $state-len = 40 max @states.map(*.chars).max;
constant $CLEAR     = "\e[H\e[2J";

my sub parse-overview(IO() $file) {
    my (%counts, %bisects);

    for $file.lines {
        my ($module, $info)   = .split(' – ');
        my ($status, $bisect) = ($info // '').split(', Bisected: ');
        %counts{$status // ''}++;
        %bisects{$_}++ with $bisect;
    }

    :%counts, :%bisects
}

sub MAIN(
    Str :$overview-file = 'output/overview',  # Location of overview file
    Int :$fade-time = 24,                     # Seconds to fade out highlight
    ) {
    my %prev    = flat @states Z, 0 xx *;
    my %updated = flat @states Z, 0 xx *;

    my sub update-from-results(%results) {
        for @states {
            my $count = %results<counts>{$_} // 0;
            if %prev{$_} != $count {
               %prev{$_}  = $count;
               %updated{$_} = now;
            }
        }

        for %results<bisects>.keys {
            my $count = %results<bisects>{$_} // 0;
            if (%prev{$_} // 0) != $count {
                %prev{$_}    = $count;
                %updated{$_} = now;
            }
        }
    }

    my sub show-current(%results, %updated) {
        my sub color-for($key) {
            my $time = 0 max (now - %updated{$key} // 0);
            my $fade = 0 max (1 - $time / $fade-time);
            my $bg   = 255 min 232 + floor(24 * $fade);
            my $fg   = $bg >= 244 ?? 0 !! 15;
            "$fg on_$bg"
        }

        # Write output all at once to reduce screen flashing
        my @output = colored('States', 'bold yellow');
        for @states {
            my $line = sprintf('    %-*s %5d', $state-len, $_, %results<counts>{$_} // 0);
            @output.push: colored($line, color-for($_));
        }
        @output.push('');

        @output.push(colored('Bisects', 'bold yellow'));
        for %results<bisects>.sort({-.value, .key}) {
            my $sha1 = .key;
            my $line = sprintf('    %-*s %5d', $state-len, $sha1, %results<bisects>{$sha1} // 0);
            @output.push: colored($line, color-for($sha1));
        }

        print $CLEAR ~ @output.map(* ~ "\n").join;
    }

    react {
        whenever signal(SIGINT) {
            done;
        }
        whenever Supply.interval(1) {
            my %results = parse-overview($overview-file);
            update-from-results(%results);
            show-current(%results, %updated);
        }
    }
}
