unit class Blin::Debug is rw is export;

our sub debug(Str $note, Int $level=1, :$icon="🥞") is export {
    note "[{DateTime.now.truncated-to('second')}] " ~ $icon x $level ~ ' ' ~ $note;
}
