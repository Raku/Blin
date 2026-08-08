#!/usr/bin/sh

# Intended to wrap bin/blin.p6 for standard pre-release runs.
#
# Runs under systemd-run to avoid individual tests taking down the entire machine.

# A large store directory causes the initial zef update run to take *10 minutes* to complete
# Remove it each time. (This probably impacts individual calls later during the blin run).
rm -rf data/zef-data/store 

# failed jobs might leave the rakudo copies in a locked state.
rm -rf /tmp/whateverable/rakudo-moar/

# Test last released version against HEAD
export OLD=`curl --silent -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/rakudo/rakudo/releases?per_page=1" | grep 'tag_name' | awk -F: '{print $2}' | awk -F\" '{print $2}'`
export NEW=HEAD

# How often to emit diagnostics
export HEARTBEAT=30

# How many processors to use? Most
export NPROC=31

# Cap for memory usage
export MAX_MEMORY=60G

# Warning in case last run crashed
echo "If system-d complains, you might need to run 'systemctl --user reset-failed'"

systemd-run -E RAKULIB=. --user --tty --wait --working-directory=/blin --unit=blin --slice=user.slice --property="CPUWeight=100" --property="MemoryMax=$MAX_MEMORY" raku --ll-exception bin/blin.p6 --old=$OLD --new=$NEW --nproc=$NPROC --heartbeat=$HEARTBEAT
