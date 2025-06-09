unit class Blin::Debug is rw is export;

our sub debug(Str $note, Int $level=1) is export {
    note "[{DateTime.now.truncated-to('second')} ] " ~ "🥞" x $level ~ ' ' ~ $note;
}
