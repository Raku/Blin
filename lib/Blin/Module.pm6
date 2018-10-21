unit class Blin::Module is rw is export;

has Str     $.name;
has Version $.version;
has Set     $.depends;
has Set     $.rdepends;
has Bool    $.needed = False;
has         $.bisected; #← to store the offending commit/commits
has Str     @.errors;
has Bool    $.visited;
has Promise $.done = Promise.new;

method install-path {
    # TODO surely we can do better to ensure it won't clash
    ‘installed/’ ~ $.name ~ ‘_’ ~ $.version
}

method deps($leaf = False) {
    take self unless $leaf;
    .deps for $!depends.keys;
}

method rdeps($leaf = False) {
    take self unless $leaf;
    .deps for $!rdepends.keys;
}

#| Same as `deps` but dies if a cycle is detected
method safe-deps($leaf = False) {
    if $!visited {
        die ‘Cycle detected’ # TODO add proper exception
    }
    $!visited = True;
    LEAVE $!visited = False;
    take self unless $leaf;
    .safe-deps for $!depends.keys;
}

method needify() {
    return if $!needed; # tree section is already marked
    $!needed = True;
    .needify for $!depends.keys;
}

# Please slap me next time I decide to use Sets for everything. Having
# to use .keys everywhere is simply annoying.
