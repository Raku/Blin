unit module Blin::Skips;

use JSON::Fast;

=begin overview

Provide a list of modules in the ecosystem that are known to have issues.

Each skip will contain a name, a reason, and an action.

Reason may be a text description, but if possible should be a URL to a ticket in
that module's bug tracker.

If action is set to "skip", this module is not tested at all.

If action is blank, and the "new" revision fails, do not bother testing the "old"
revision, instead marking it as AlwaysFail.

=end overview

our @skips = from-json %?RESOURCES<skips.json>.slurp;
