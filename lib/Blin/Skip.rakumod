unit module Blin::Fails;

use JSON::Fast;

=begin overview

Provide a list of modules in the ecosystem that are known to fail.

For any modules on this list, do not bother testing the old version,
saving time on the full blin run.

=end overview

our @fails = from-json %?RESOURCES<fails.json>.slurp;
