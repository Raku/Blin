unit module Blin::Essential;

use JSON::Fast;

=begin Overview

Provide a list of modules in the ecosystem that are considered "Essential".

Goal is to provide a subset of the ecosytem that can easily be tested more often
than once per release, and with stricter criteria. These should B<always> pass
and any failures in testing are considered bad, even if the previous version
also failed.

B<High use> or B<critical> modules should be added to this list as noted.
Ideally, an automated selection could be generated based on criteria from
L<raku.land|https://raku.land>.

Currently all modules are specified in C<name:ver<>:auth<>:api<>> format, but with
only names specified.

=end Overview

our @essentials = from-json %?RESOURCES<essential.json>.slurp;
